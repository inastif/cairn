import 'package:cairn/core/money/currency.dart';
import 'package:cairn/core/money/fx_rates.dart';
import 'package:cairn/core/money/money.dart';
import 'package:cairn/features/net_worth/domain/asset_item.dart';
import 'package:cairn/features/net_worth/domain/liability_item.dart';
import 'package:cairn/features/net_worth/domain/net_worth_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

Money eur(num v) => Money.fromMajor(v, Currency.eur);

AssetItem asset(String id, AssetClass c, Money v) =>
    AssetItem(id: id, name: id, assetClass: c, value: v, source: DataSource.manual);

LiabilityItem debt(String id, LiabilityType t, num v, {String? secured}) => LiabilityItem(
      id: id,
      name: id,
      type: t,
      outstanding: eur(v),
      source: DataSource.manual,
      securedAssetId: secured,
    );

void main() {
  const calculator = NetWorthCalculator();
  final fx = FxRates(
    base: Currency.eur,
    rates: const {'USD': 1.10},
    asOf: DateTime(2026, 9, 28),
    source: 'test',
  );

  test('patrimoine net = actifs − dettes, avec conversion de devise', () {
    final result = calculator.compute(
      assets: [
        asset('cash', AssetClass.cash, eur(10000)),
        asset('us', AssetClass.investments, Money.fromMajor(11000, Currency.usd)),
      ],
      liabilities: [debt('car', LiabilityType.autoLoan, 5000)],
      reportingCurrency: Currency.eur,
      fx: fx,
    );
    expect(result.grossAssets, eur(20000));
    expect(result.totalLiabilities, eur(5000));
    expect(result.netWorth, eur(15000));
    expect(result.shareOf(AssetClass.investments), closeTo(0.5, 1e-9));
    expect(result.isComplete, isTrue);
  });

  test('un compte à découvert devient une dette', () {
    final result = calculator.compute(
      assets: [
        asset('checking', AssetClass.cash, eur(-320)),
        asset('savings', AssetClass.cash, eur(600)),
      ],
      liabilities: const [],
      reportingCurrency: Currency.eur,
      fx: fx,
    );
    expect(result.grossAssets, eur(600));
    expect(result.liabilitiesByType[LiabilityType.overdraft], eur(320));
    expect(result.netWorth, eur(280));
  });

  test('exclut et signale un élément sans taux de change', () {
    final result = calculator.compute(
      assets: [
        asset('cash', AssetClass.cash, eur(1000)),
        asset('yen', AssetClass.cash, Money.fromMajor(100000, Currency.of('JPY'))),
      ],
      liabilities: const [],
      reportingCurrency: Currency.eur,
      fx: fx,
    );
    expect(result.grossAssets, eur(1000));
    expect(result.excludedItemIds, ['yen']);
    expect(result.isComplete, isFalse);
  });

  test("calcule l'équité immobilière avec les prêts rattachés", () {
    final result = calculator.compute(
      assets: [
        asset('home', AssetClass.realEstate, eur(300000)),
        asset('cash', AssetClass.cash, eur(5000)),
      ],
      liabilities: [
        debt('mortgage', LiabilityType.mortgage, 200000, secured: 'home'),
        debt('card', LiabilityType.creditCard, 1000),
      ],
      reportingCurrency: Currency.eur,
      fx: fx,
    );
    expect(result.realEstateEquity, eur(100000));
    expect(result.netWorth, eur(104000));
  });

  test('refuse une dette de montant négatif', () {
    expect(
      () => calculator.compute(
        assets: const [],
        liabilities: [debt('bad', LiabilityType.other, -1)],
        reportingCurrency: Currency.eur,
        fx: fx,
      ),
      throwsArgumentError,
    );
  });

  test('patrimoine vide', () {
    final result = calculator.compute(
      assets: const [],
      liabilities: const [],
      reportingCurrency: Currency.eur,
      fx: fx,
    );
    expect(result.netWorth, eur(0));
    expect(result.shareOf(AssetClass.cash), 0);
  });
}
