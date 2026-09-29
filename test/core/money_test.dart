import 'package:cairn/core/money/currency.dart';
import 'package:cairn/core/money/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Currency', () {
    test('normalise le code et applique les exposants ISO 4217', () {
      expect(Currency.of('eur').code, 'EUR');
      expect(Currency.of('EUR').decimalDigits, 2);
      expect(Currency.of('JPY').decimalDigits, 0);
      expect(Currency.of('KWD').decimalDigits, 3);
    });

    test('refuse un code invalide', () {
      expect(() => Currency.of('EURO'), throwsArgumentError);
      expect(() => Currency.of('E1'), throwsArgumentError);
    });
  });

  group('Money', () {
    test('stocke des unités mineures entières sans dérive flottante', () {
      final a = Money.fromMajor(0.1, Currency.eur);
      final b = Money.fromMajor(0.2, Currency.eur);
      expect((a + b).minorUnits, 30);
      expect(Money.fromMajor(1234.56, Currency.eur).minorUnits, 123456);
      expect(Money.fromMajor(1500, Currency.of('JPY')).minorUnits, 1500);
    });

    test('opérations et comparaisons', () {
      final a = Money.fromMajor(100, Currency.eur);
      final b = Money.fromMajor(40, Currency.eur);
      expect(a - b, Money.fromMajor(60, Currency.eur));
      expect(-a, Money.fromMajor(-100, Currency.eur));
      expect(a > b, isTrue);
      expect((-a).abs(), a);
      expect(a.multiply(0.075), Money.fromMajor(7.5, Currency.eur));
      expect(b.ratioTo(a), closeTo(0.4, 1e-12));
      expect(Money.sum([a, b, b], Currency.eur), Money.fromMajor(180, Currency.eur));
    });

    test('interdit de mélanger deux devises', () {
      final eur = Money.fromMajor(10, Currency.eur);
      final usd = Money.fromMajor(10, Currency.usd);
      expect(() => eur + usd, throwsA(isA<CurrencyMismatchException>()));
      expect(() => eur.compareTo(usd), throwsA(isA<CurrencyMismatchException>()));
    });

    test('refuse les montants non finis et la division par zéro', () {
      expect(() => Money.fromMajor(double.nan, Currency.eur), throwsArgumentError);
      expect(
        () => Money.fromMajor(1, Currency.eur).ratioTo(Money.zero(Currency.eur)),
        throwsStateError,
      );
    });
  });
}
