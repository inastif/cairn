import 'package:cairn/core/money/currency.dart';
import 'package:cairn/core/money/money.dart';
import 'package:cairn/features/manual_entry/data/supabase_rows.dart';
import 'package:cairn/features/manual_entry/domain/portfolio_writer.dart';
import 'package:cairn/features/net_worth/domain/asset_item.dart';
import 'package:cairn/features/net_worth/domain/liability_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ligne SQL -> actif', () {
    final asset = SupabaseRows.assetFromRow({
      'id': 'a1',
      'name': 'Appartement',
      'asset_class': 'realEstate',
      'value_minor': 18500000,
      'currency': 'EUR',
      'subtype': null,
      'institution_name': 'Estimation',
      'source': 'manual',
      'valued_at': '2026-09-28T10:00:00+00:00',
    });
    expect(asset.assetClass, AssetClass.realEstate);
    expect(asset.value, Money(18500000, Currency.eur));
    expect(asset.source, DataSource.manual);
    expect(asset.valuedAt, isNotNull);
  });

  test('valeur inconnue en base : repli prudent', () {
    final asset = SupabaseRows.assetFromRow({
      'id': 'a2',
      'name': 'X',
      'asset_class': 'inconnu',
      'value_minor': 100,
      'currency': 'usd',
    });
    expect(asset.assetClass, AssetClass.other);
    expect(asset.value.currency, Currency.usd);
  });

  test('actif -> ligne SQL : champs vides normalisés', () {
    final row = SupabaseRows.assetToRow(
      AssetDraft(
        name: '  Livret A ',
        assetClass: AssetClass.cash,
        value: Money(2295000, Currency.eur),
        subtype: '   ',
      ),
      now: DateTime.utc(2026, 9, 28),
    );
    expect(row['name'], 'Livret A');
    expect(row['asset_class'], 'cash');
    expect(row['value_minor'], 2295000);
    expect(row['subtype'], isNull);
    expect(row.containsKey('user_id'), isFalse, reason: 'ajouté par le repository');
  });

  test('dettes aller-retour', () {
    final row = SupabaseRows.liabilityToRow(
      LiabilityDraft(
        name: 'Crédit',
        type: LiabilityType.mortgage,
        outstanding: Money(26500000, Currency.eur),
        securedAssetId: 'a1',
      ),
    );
    final liability = SupabaseRows.liabilityFromRow({...row, 'id': 'l1'});
    expect(liability.type, LiabilityType.mortgage);
    expect(liability.outstanding, Money(26500000, Currency.eur));
    expect(liability.securedAssetId, 'a1');
  });

  test('taux : le plus récent par devise, date la plus ancienne utilisée affichée', () {
    final fx = SupabaseRows.fxRatesFromRows(
      [
        {'quote': 'USD', 'rate': 1.17, 'rate_date': '2026-09-25'},
        {'quote': 'GBP', 'rate': 0.87, 'rate_date': '2026-09-24'},
        {'quote': 'USD', 'rate': 1.15, 'rate_date': '2026-09-24'},
      ],
      fallbackDate: DateTime(2026, 9, 28),
    );
    expect(fx.tryConvert(Money.fromMajor(117, Currency.usd), Currency.eur), Money.fromMajor(100, Currency.eur));
    expect(fx.asOf, DateTime(2026, 9, 24));
    expect(fx.source, 'BCE');
  });

  test('aucun taux : seules les conversions identiques fonctionnent', () {
    final fx = SupabaseRows.fxRatesFromRows(const [], fallbackDate: DateTime(2026, 9, 28));
    expect(fx.tryConvert(Money.fromMajor(1, Currency.usd), Currency.eur), isNull);
    expect(fx.tryConvert(Money.fromMajor(1, Currency.eur), Currency.eur), isNotNull);
  });

  test('snapshots : date ISO', () {
    expect(SupabaseRows.isoDate(DateTime(2026, 3, 7)), '2026-03-07');
    final snapshot = SupabaseRows.snapshotFromRow({
      'snapshot_date': '2026-09-27',
      'gross_minor': 1000,
      'liabilities_minor': 400,
      'currency': 'EUR',
    });
    expect(snapshot.netWorth, Money(600, Currency.eur));
    expect(snapshot.date.day, 27);
  });
}
