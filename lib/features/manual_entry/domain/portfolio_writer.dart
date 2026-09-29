import 'package:cairn/core/money/currency.dart';
import 'package:cairn/core/money/money.dart';
import 'package:cairn/features/net_worth/domain/asset_item.dart';
import 'package:cairn/features/net_worth/domain/liability_item.dart';
import 'package:meta/meta.dart';

/// Actif saisi à la main. `id` nul = création.
@immutable
final class AssetDraft {
  const AssetDraft({
    required this.name,
    required this.assetClass,
    required this.value,
    this.id,
    this.subtype,
    this.institutionName,
  });

  final String? id;
  final String name;
  final AssetClass assetClass;
  final Money value;
  final String? subtype;
  final String? institutionName;
}

@immutable
final class LiabilityDraft {
  const LiabilityDraft({
    required this.name,
    required this.type,
    required this.outstanding,
    this.id,
    this.institutionName,
    this.securedAssetId,
  });

  final String? id;
  final String name;
  final LiabilityType type;
  final Money outstanding;
  final String? institutionName;
  final String? securedAssetId;
}

/// Écriture des données saisies par l'utilisateur.
abstract interface class PortfolioWriter {
  Future<void> saveAsset(AssetDraft draft);
  Future<void> deleteAsset(String id);
  Future<void> saveLiability(LiabilityDraft draft);
  Future<void> deleteLiability(String id);

  /// Devise de reporting ; la cible reste 1 000 000 dans cette devise.
  Future<void> updateReportingCurrency(Currency currency);
}

/// Erreur d'écriture présentée à l'utilisateur.
final class PortfolioWriteException implements Exception {
  const PortfolioWriteException(this.message);

  final String message;

  @override
  String toString() => 'PortfolioWriteException: $message';
}
