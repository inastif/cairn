import 'package:cairn/core/money/currency.dart';
import 'package:cairn/core/money/money.dart';
import 'package:cairn/features/goals/domain/projection_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

Money eur(num v) => Money.fromMajor(v, Currency.eur);

void main() {
  const calculator = ProjectionCalculator();
  final from = DateTime(2026, 9, 28);
  final target = eur(1000000);

  ProjectionResult run(num current, num contribution, double annualReturn) => calculator.estimate(
        current: eur(current),
        target: target,
        monthlyContribution: eur(contribution),
        annualReturn: annualReturn,
        from: from,
      );

  test('sans rendement : simple division', () {
    final result = run(0, 1000, 0);
    expect(result.outcome, ProjectionOutcome.reachable);
    expect(result.months, 1000);
    expect(result.estimatedDate, DateTime(2110, 1));
  });

  // Valeurs de référence calculées indépendamment (script Python du même modèle).
  test('avec rendement composé mensuel', () {
    expect(run(74200, 995, 0.03).months, 438);
    expect(run(100000, 1000, 0.05).months, 316);
    expect(run(500000, 0, 0.05).months, 171);
  });

  test("le rendement ne s'applique pas à un patrimoine négatif", () {
    expect(run(-5000, 1000, 0.05).months, 405);
  });

  test('cas sans estimation possible', () {
    expect(run(500000, 0, 0).outcome, ProjectionOutcome.noPositiveGrowth);
    expect(run(-1000, -50, 0.05).outcome, ProjectionOutcome.noPositiveGrowth);
    expect(run(-5000, 500, 0).outcome, ProjectionOutcome.beyondHorizon);
  });

  test('objectif déjà atteint', () {
    final result = run(1200000, 0, 0);
    expect(result.outcome, ProjectionOutcome.alreadyReached);
    expect(result.months, 0);
  });
}
