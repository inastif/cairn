import 'package:cairn/core/money/currency.dart';
import 'package:cairn/core/money/fx_rates.dart';
import 'package:cairn/core/money/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fx = FxRates(
    base: Currency.eur,
    rates: const {'USD': 1.10, 'GBP': 0.85},
    asOf: DateTime(2026, 9, 25),
    source: 'test',
  );

  test('convertit depuis et vers la devise de base', () {
    expect(fx.tryConvert(Money.fromMajor(110, Currency.usd), Currency.eur), Money.fromMajor(100, Currency.eur));
    expect(fx.tryConvert(Money.fromMajor(100, Currency.eur), Currency.gbp), Money.fromMajor(85, Currency.gbp));
  });

  test('convertit entre deux devises cotées via la base', () {
    final result = fx.tryConvert(Money.fromMajor(85, Currency.gbp), Currency.usd);
    expect(result, Money.fromMajor(110, Currency.usd));
  });

  test("retourne null plutôt que d'inventer un taux", () {
    expect(fx.tryConvert(Money.fromMajor(1000, Currency.of('JPY')), Currency.eur), isNull);
    expect(fx.supports(Currency.of('JPY')), isFalse);
    expect(fx.supports(Currency.eur), isTrue);
  });

  test('refuse un taux nul ou négatif', () {
    expect(
      () => FxRates(base: Currency.eur, rates: const {'USD': 0}, asOf: DateTime(2026), source: 't'),
      throwsArgumentError,
    );
  });
}
