import 'package:cairn/core/money/currency.dart';
import 'package:cairn/core/money/fx_rates.dart';
import 'package:cairn/core/money/money.dart';
import 'package:cairn/features/net_worth/domain/asset_item.dart';
import 'package:cairn/features/net_worth/domain/liability_item.dart';
import 'package:meta/meta.dart';

@immutable
final class NetWorthBreakdown {
  const NetWorthBreakdown({
    required this.currency,
    required this.grossAssets,
    required this.totalLiabilities,
    required this.assetsByClass,
    required this.liabilitiesByType,
    required this.realEstateEquity,
    required this.excludedItemIds,
  });

  final Currency currency;

  /// Patrimoine brut : somme des actifs positifs.
  final Money grossAssets;

  /// Somme des dettes (découverts inclus).
  final Money totalLiabilities;
  final Map<AssetClass, Money> assetsByClass;
  final Map<LiabilityType, Money> liabilitiesByType;

  /// Valeur des biens immobiliers moins les prêts qui leur sont rattachés.
  final Money realEstateEquity;

  /// Éléments ignorés faute de taux de change. Doit être affiché.
  final List<String> excludedItemIds;

  /// Patrimoine net = actifs − dettes.
  Money get netWorth => grossAssets - totalLiabilities;

  bool get isComplete => excludedItemIds.isEmpty;

  Money assetsOf(AssetClass assetClass) => assetsByClass[assetClass] ?? Money.zero(currency);

  /// Part d'une classe dans le patrimoine brut, entre 0 et 1.
  double shareOf(AssetClass assetClass) =>
      grossAssets.isPositive ? assetsOf(assetClass).ratioTo(grossAssets) : 0.0;
}

/// Calcule le patrimoine net dans une devise de reporting.
///
/// Règles :
/// * chaque élément est converti via [FxRates] ; sans taux, il est exclu et
///   listé dans [NetWorthBreakdown.excludedItemIds] (jamais de taux inventé) ;
/// * un actif de valeur négative (compte à découvert) devient une dette
///   [LiabilityType.overdraft] au lieu de réduire les actifs ;
/// * une dette de montant négatif est une donnée invalide : exception.
final class NetWorthCalculator {
  const NetWorthCalculator();

  NetWorthBreakdown compute({
    required List<AssetItem> assets,
    required List<LiabilityItem> liabilities,
    required Currency reportingCurrency,
    required FxRates fx,
  }) {
    final zero = Money.zero(reportingCurrency);
    final byClass = <AssetClass, Money>{};
    final byType = <LiabilityType, Money>{};
    final excluded = <String>[];
    final realEstateIds = <String>{};
    var realEstateValue = zero;

    for (final asset in assets) {
      final converted = fx.tryConvert(asset.value, reportingCurrency);
      if (converted == null) {
        excluded.add(asset.id);
        continue;
      }
      if (converted.isNegative) {
        final debt = converted.abs();
        byType.update(LiabilityType.overdraft, (v) => v + debt, ifAbsent: () => debt);
        continue;
      }
      byClass.update(asset.assetClass, (v) => v + converted, ifAbsent: () => converted);
      if (asset.assetClass == AssetClass.realEstate) {
        realEstateIds.add(asset.id);
        realEstateValue += converted;
      }
    }

    var securedRealEstateDebt = zero;
    for (final liability in liabilities) {
      if (liability.outstanding.isNegative) {
        throw ArgumentError.value(
          liability.outstanding,
          'liabilities',
          'Le capital restant dû doit être positif (${liability.id})',
        );
      }
      final converted = fx.tryConvert(liability.outstanding, reportingCurrency);
      if (converted == null) {
        excluded.add(liability.id);
        continue;
      }
      byType.update(liability.type, (v) => v + converted, ifAbsent: () => converted);
      final securedId = liability.securedAssetId;
      if (securedId != null && realEstateIds.contains(securedId)) {
        securedRealEstateDebt += converted;
      }
    }

    return NetWorthBreakdown(
      currency: reportingCurrency,
      grossAssets: Money.sum(byClass.values, reportingCurrency),
      totalLiabilities: Money.sum(byType.values, reportingCurrency),
      assetsByClass: Map<AssetClass, Money>.unmodifiable(byClass),
      liabilitiesByType: Map<LiabilityType, Money>.unmodifiable(byType),
      realEstateEquity: realEstateValue - securedRealEstateDebt,
      excludedItemIds: List<String>.unmodifiable(excluded),
    );
  }
}
