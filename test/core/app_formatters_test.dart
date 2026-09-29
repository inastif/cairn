import 'package:cairn/core/formatting/app_formatters.dart';
import 'package:cairn/core/money/currency.dart';
import 'package:cairn/core/money/money.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Supprime les espaces (y compris insécables) pour comparer sans dépendre
/// de la version des données CLDR.
String compact(String value) => value.replaceAll(RegExp(r'\s'), '');

void main() {
  const format = AppFormatters();

  setUpAll(() async => initializeDateFormatting('fr_FR'));

  group('pourcentage millionnaire', () {
    test('2 décimales sous 10 %, 1 décimale au-delà', () {
      expect(compact(format.millionairePercent(7.42)), '7,42%');
      expect(compact(format.millionairePercent(25)), '25,0%');
      expect(compact(format.millionairePercent(127)), '127,0%');
    });

    test('tronque au lieu d’arrondir, sans erreur binaire', () {
      expect(compact(format.millionairePercent(7.4299)), '7,42%');
      expect(compact(format.millionairePercent(0.29)), '0,29%');
      expect(compact(format.millionairePercent(99.9999)), '99,9%');
    });

    test('affiche honnêtement une valeur négative', () {
      final text = compact(format.millionairePercent(-3.584));
      expect(text, contains('3,58%'));
      expect(text.startsWith('-') || text.startsWith('\u2212'), isTrue);
    });
  });

  test('montants en euros', () {
    final value = Money.fromMajor(74200, Currency.eur);
    expect(compact(format.money(value)), '74200€');
    expect(compact(format.money(value, signed: true)), '+74200€');
    expect(format.maskedMoney(Currency.eur), contains(AppFormatters.maskGlyphs));
  });

  test('variations relatives signées', () {
    expect(compact(format.signedPercentFromRatio(0.038)), '+3,8%');
    expect(compact(format.percentFromRatio(0.32)), '32%');
  });

  test('dates relatives de synchronisation', () {
    final now = DateTime(2026, 9, 28, 10);
    expect(format.relativeDateTime(DateTime(2026, 9, 28, 9, 42), now), "aujourd'hui à 09:42");
    expect(format.relativeDateTime(DateTime(2026, 9, 27, 18, 5), now), 'hier à 18:05');
  });
}
