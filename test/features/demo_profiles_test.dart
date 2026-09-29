import 'package:cairn/core/money/currency.dart';
import 'package:cairn/core/money/money.dart';
import 'package:cairn/features/demo/data/demo_profiles.dart';
import 'package:cairn/features/goals/domain/projection_calculator.dart';
import 'package:cairn/features/net_worth/domain/liability_item.dart';
import 'package:cairn/features/portfolio/domain/financial_overview.dart';
import 'package:cairn/features/transactions/domain/transaction_category.dart';
import 'package:flutter_test/flutter_test.dart';

Money eur(num v) => Money.fromMajor(v, Currency.eur);

void main() {
  final asOf = DateTime(2026, 9, 28, 10);
  const builder = FinancialOverviewBuilder();

  FinancialOverview overviewOf(DemoProfileId id) =>
      builder.build(DemoProfiles.build(id, asOf: asOf), asOf: asOf, annualReturnAssumption: 0.03);

  test('tous les profils se construisent et restent cohérents', () {
    for (final id in DemoProfileId.values) {
      final overview = overviewOf(id);
      expect(overview.data.isDemo, isTrue, reason: id.name);
      expect(overview.breakdown.isComplete, isTrue, reason: id.name);
      expect(overview.cashflows.length, 12, reason: id.name);
      expect(overview.history.length, 25, reason: id.name);
      expect(overview.score.value, inInclusiveRange(0, 100), reason: id.name);
      expect(overview.history.last.netWorth, overview.breakdown.netWorth, reason: id.name);
    }
  });

  test('profil moyen = exemple du brief (74 200 €, 7,42 %)', () {
    final overview = overviewOf(DemoProfileId.midWealth);
    expect(overview.breakdown.netWorth, eur(74200));
    expect(overview.millionaire.percent, closeTo(7.42, 1e-9));
    expect(overview.projection.outcome, ProjectionOutcome.reachable);
    expect(overview.averageMonthlySavings.isPositive, isTrue);
  });

  test('profil investisseur : conversion USD et GBP au taux démo', () {
    final overview = overviewOf(DemoProfileId.investor);
    // 5 200 + 3 400 £/0,85 + 142 000 + 85 000 $/1,10 + 60 000 + 38 000 + 9 500
    expect(overview.breakdown.grossAssets, Money(33597273, Currency.eur));
  });

  test('profil immobilier : équité = biens − crédits rattachés', () {
    final overview = overviewOf(DemoProfileId.realEstate);
    expect(overview.breakdown.realEstateEquity, eur(198000));
    expect(overview.breakdown.netWorth, eur(272050));
  });

  test('profil endetté : découvert compté comme dette, patrimoine négatif', () {
    final overview = overviewOf(DemoProfileId.highDebt);
    expect(overview.breakdown.liabilitiesByType[LiabilityType.overdraft], eur(320));
    expect(overview.breakdown.netWorth, eur(-35520));
    expect(overview.millionaire.percent, lessThan(0));
  });

  test('les opérations démo sont catégorisées sans repli « Autres »', () {
    final transactions = DemoProfiles.build(DemoProfileId.midWealth, asOf: asOf).transactions;
    expect(transactions, isNotEmpty);
    expect(transactions.where((t) => t.category == TransactionCategory.other), isEmpty);
    expect(transactions.any((t) => t.category == TransactionCategory.transfer), isTrue);
    expect(transactions.any((t) => t.category == TransactionCategory.investment), isTrue);
    expect(transactions.every((t) => !t.bookedAt.isAfter(asOf)), isTrue);
  });
}
