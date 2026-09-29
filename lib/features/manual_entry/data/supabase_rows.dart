import 'package:cairn/core/money/currency.dart';
import 'package:cairn/core/money/fx_rates.dart';
import 'package:cairn/core/money/money.dart';
import 'package:cairn/features/manual_entry/domain/portfolio_writer.dart';
import 'package:cairn/features/net_worth/domain/asset_item.dart';
import 'package:cairn/features/net_worth/domain/liability_item.dart';
import 'package:cairn/features/net_worth/domain/net_worth_snapshot.dart';

/// Conversion entre lignes de la base (JSON) et objets du domaine.
/// Les noms d'énumérations sont stockés tels quels (`realEstate`, …) et
/// contraints par des CHECK dans la migration SQL.
abstract final class SupabaseRows {
  static int _int(Object? value) => (value as num).toInt();

  static T _enum<T extends Enum>(List<T> values, Object? name, T fallback) {
    for (final value in values) {
      if (value.name == name) {
        return value;
      }
    }
    return fallback;
  }

  static DataSource _source(Object? name) => _enum(DataSource.values, name, DataSource.manual);

  static AssetItem assetFromRow(Map<String, dynamic> row) {
    final currency = Currency.of(row['currency'] as String);
    return AssetItem(
      id: row['id'] as String,
      name: row['name'] as String,
      assetClass: _enum(AssetClass.values, row['asset_class'], AssetClass.other),
      value: Money(_int(row['value_minor']), currency),
      source: _source(row['source']),
      subtype: row['subtype'] as String?,
      institutionName: row['institution_name'] as String?,
      valuedAt: row['valued_at'] == null ? null : DateTime.parse(row['valued_at'] as String),
    );
  }

  static Map<String, Object?> assetToRow(AssetDraft draft, {required DateTime now}) => {
        'name': draft.name.trim(),
        'asset_class': draft.assetClass.name,
        'value_minor': draft.value.minorUnits,
        'currency': draft.value.currency.code,
        'subtype': _blankToNull(draft.subtype),
        'institution_name': _blankToNull(draft.institutionName),
        'source': DataSource.manual.name,
        'valued_at': now.toUtc().toIso8601String(),
      };

  static LiabilityItem liabilityFromRow(Map<String, dynamic> row) {
    final currency = Currency.of(row['currency'] as String);
    return LiabilityItem(
      id: row['id'] as String,
      name: row['name'] as String,
      type: _enum(LiabilityType.values, row['liability_type'], LiabilityType.other),
      outstanding: Money(_int(row['outstanding_minor']), currency),
      source: _source(row['source']),
      institutionName: row['institution_name'] as String?,
      securedAssetId: row['secured_asset_id'] as String?,
    );
  }

  static Map<String, Object?> liabilityToRow(LiabilityDraft draft) => {
        'name': draft.name.trim(),
        'liability_type': draft.type.name,
        'outstanding_minor': draft.outstanding.minorUnits,
        'currency': draft.outstanding.currency.code,
        'institution_name': _blankToNull(draft.institutionName),
        'secured_asset_id': draft.securedAssetId,
        'source': DataSource.manual.name,
      };

  static NetWorthSnapshot snapshotFromRow(Map<String, dynamic> row) {
    final currency = Currency.of(row['currency'] as String);
    return NetWorthSnapshot(
      // Une date de snapshot représente la fin de journée.
      date: DateTime.parse(row['snapshot_date'] as String).add(const Duration(hours: 23, minutes: 59)),
      grossAssets: Money(_int(row['gross_minor']), currency),
      liabilities: Money(_int(row['liabilities_minor']), currency),
    );
  }

  static Map<String, Object?> snapshotToRow({
    required String userId,
    required DateTime date,
    required Money gross,
    required Money liabilities,
  }) =>
      {
        'user_id': userId,
        'snapshot_date': isoDate(date),
        'gross_minor': gross.minorUnits,
        'liabilities_minor': liabilities.minorUnits,
        'currency': gross.currency.code,
      };

  /// Garde, pour chaque devise, le taux le plus récent. Base EUR (BCE).
  static FxRates fxRatesFromRows(List<Map<String, dynamic>> rows, {required DateTime fallbackDate}) {
    final rates = <String, double>{};
    DateTime? oldestUsed;
    for (final row in rows) {
      final quote = row['quote'] as String;
      final date = DateTime.parse(row['rate_date'] as String);
      final existing = rates[quote];
      if (existing == null) {
        rates[quote] = (row['rate'] as num).toDouble();
        if (oldestUsed == null || date.isBefore(oldestUsed)) oldestUsed = date;
      }
    }
    return FxRates(
      base: Currency.eur,
      rates: rates,
      // On affiche la date la plus ancienne réellement utilisée : c'est
      // la plus honnête pour l'utilisateur.
      asOf: oldestUsed ?? fallbackDate,
      source: rates.isEmpty ? 'aucun taux' : 'BCE',
    );
  }

  static String isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
