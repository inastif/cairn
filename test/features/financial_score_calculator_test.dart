import 'package:cairn/core/money/currency.dart';
import 'package:cairn/core/money/fx_rates.dart';
import 'package:cairn/core/money/money.dart';
import 'package:cairn/features/financial_score/domain/financial_score.dart';
import 'package:cairn/features/financial_score/domain/financial_score_calculator.dart';
import 'package:cairn/features/net_worth/domain/asset_item.dart';
import 'package:cairn/features/net_worth/domain/liability_item.dart';
import 'package:cairn/features/net_worth/domain/net_worth_calculator.dart';
import 'package:cairn/features/net_worth/domain/net_worth_snapshot.dart';
import 'package:cairn/features/transactions/domain/cashflow_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

Money eur(num v) => Money.fromMajor(v, Currency.eur);

MonthlyCashflow month(int year, int m, {required num income, required num expenses}) =>
    MonthlyCashflow(
      month: DateTime(year, m),
      income: eur(income),
      expenses: eur(expenses),
      invested: eur(0),
      expensesByCategory: const {},
    );

void main() {
  const calculator = FinancialScoreCalculator();
  final asOf = DateTime(2026, 9, 15);

  // Liquidités 10 000, placements 30 000, crédit auto 10 000 -> net 30 000.
  final breakdown = const NetWorthCalculator().compute(
    assets: [
      AssetItem(id: 'c', name: 'c', assetClass: AssetClass.cash, value: eur(10000), source: DataSource.manual),
      AssetItem(id: 'i', name: 'i', assetClass: AssetClass.investments, value: eur(30000), source: DataSource.manual),
    ],
    liabilities: [
      LiabilityItem(id: 'l', name: 'l', type: LiabilityType.autoLoan, outstanding: eur(10000), source: DataSource.manual),
    ],
    reportingCurrency: Currency.eur,
    fx: FxRates.identity(Currency.eur),
  );

  test('applique exactement la méthodologie documentée', () {
    final cashflows = [
      for (var m = 3; m <= 8; m++) month(2026, m, income: 3000, expenses: 2400),
      // Mois en cours, partiel : doit être ignoré.
      month(2026, 9, income: 0, expenses: 5000),
    ];
    final history = [
      NetWorthSnapshot(date: DateTime(2025, 9, 15), grossAssets: eur(27000), liabilities: eur(0)),
    ];

    final score = calculator.compute(
      breakdown: breakdown,
      cashflows: cashflows,
      history: history,
      asOf: asOf,
    );

    double pointsOf(ScoreFactor f) => score.components.firstWhere((c) => c.factor == f).points;

    // Taux d'épargne 20 % -> 25/25.
    expect(pointsOf(ScoreFactor.savingsRate), closeTo(25, 1e-9));
    // 10 000 / 2 400 = 4,17 mois sur 6 -> 13,89/20.
    expect(pointsOf(ScoreFactor.emergencyFund), closeTo(13.8889, 1e-3));
    // Dettes / actifs = 25 % -> 15/20.
    expect(pointsOf(ScoreFactor.debtRatio), closeTo(15, 1e-9));
    // 6 mois sur 6 positifs -> 15/15.
    expect(pointsOf(ScoreFactor.savingsRegularity), closeTo(15, 1e-9));
    // +11 % sur 12 mois -> 10/10.
    expect(pointsOf(ScoreFactor.netWorthTrend), closeTo(10, 1e-9));
    // Parts 25/75 : HHI 0,625 -> (1−0,625)/0,8 = 0,469 -> 4,69/10.
    expect(pointsOf(ScoreFactor.diversification), closeTo(4.6875, 1e-9));

    expect(score.value, 84);
    expect(score.availableWeight, 100);
    expect(score.hasEnoughData, isTrue);
    expect(score.band, ScoreBand.excellent);
  });

  test('renormalise et signale le manque de données', () {
    final score = calculator.compute(
      breakdown: breakdown,
      cashflows: const [],
      history: const [],
      asOf: asOf,
    );
    // Seuls endettement (20) et diversification (10) sont calculables :
    // (15 + 4,6875) / 30 × 100 = 65,6 -> 66.
    expect(score.availableWeight, 30);
    expect(score.value, 66);
    expect(score.hasEnoughData, isFalse);
  });

  test('historique trop récent : évolution non comptée', () {
    final score = calculator.compute(
      breakdown: breakdown,
      cashflows: const [],
      history: [
        NetWorthSnapshot(date: DateTime(2026, 8, 1), grossAssets: eur(20000), liabilities: eur(0)),
      ],
      asOf: asOf,
    );
    final trend = score.components.firstWhere((c) => c.factor == ScoreFactor.netWorthTrend);
    expect(trend.isAvailable, isFalse);
  });

  test('bornes des tranches', () {
    expect(ScoreBand.fromValue(100), ScoreBand.excellent);
    expect(ScoreBand.fromValue(80), ScoreBand.excellent);
    expect(ScoreBand.fromValue(79), ScoreBand.good);
    expect(ScoreBand.fromValue(50), ScoreBand.fair);
    expect(ScoreBand.fromValue(35), ScoreBand.building);
    expect(ScoreBand.fromValue(0), ScoreBand.consolidating);
  });

  test('les poids totalisent 100', () {
    expect(ScoreFactor.values.fold<int>(0, (sum, f) => sum + f.weight), 100);
  });
}
