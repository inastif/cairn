import 'package:cairn/core/money/currency.dart';
import 'package:cairn/core/money/money.dart';
import 'package:cairn/features/millionaire/domain/millionaire_progress.dart';
import 'package:flutter_test/flutter_test.dart';

Money eur(num v) => Money.fromMajor(v, Currency.eur);

void main() {
  const calculator = MillionaireCalculator();
  final target = eur(1000000);

  MillionaireProgress progress(num netWorth) =>
      calculator.compute(netWorth: eur(netWorth), target: target);

  test('exemple du brief : 74 200 € = 7,42 %', () {
    final p = progress(74200);
    expect(p.percent, closeTo(7.42, 1e-9));
    expect(p.lastReachedMilestone, 5);
    expect(p.nextMilestone, 10);
    expect(p.amountToNextMilestone, eur(25800));
    expect(p.remaining, eur(925800));
  });

  test('chaque palier est atteint exactement à sa valeur', () {
    for (final milestone in MillionaireProgress.milestones) {
      final p = progress(milestone * 10000);
      expect(p.percent, closeTo(milestone, 1e-9));
      expect(p.lastReachedMilestone, milestone);
    }
  });

  test('au-delà du million : 127 %, non borné', () {
    final p = progress(1270000);
    expect(p.percent, closeTo(127, 1e-9));
    expect(p.isMillionaire, isTrue);
    expect(p.progressFraction, 1);
    expect(p.nextMilestone, isNull);
    expect(p.remaining, eur(0));
  });

  test('patrimoine négatif : pourcentage négatif, jauge à zéro', () {
    final p = progress(-35840);
    expect(p.percent, closeTo(-3.584, 1e-9));
    expect(p.progressFraction, 0);
    expect(p.lastReachedMilestone, isNull);
    expect(p.nextMilestone, 1);
    expect(p.amountToNextMilestone, eur(45840));
  });

  test("à un centime du million, on n'est pas millionnaire", () {
    final p = calculator.compute(netWorth: Money(99999999, Currency.eur), target: target);
    expect(p.isMillionaire, isFalse);
    expect(p.nextMilestone, 100);
  });

  test('refuse une cible nulle ou dans une autre devise', () {
    expect(() => calculator.compute(netWorth: eur(1), target: eur(0)), throwsArgumentError);
    expect(
      () => calculator.compute(netWorth: eur(1), target: Money.fromMajor(1000000, Currency.usd)),
      throwsArgumentError,
    );
  });
}
