import 'package:cairn/core/formatting/amount_parser.dart';
import 'package:cairn/core/money/currency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final eur = Currency.eur;
  final jpy = Currency.of('JPY');

  int? minor(String text, [Currency? currency]) => parseAmount(text, currency ?? eur)?.minorUnits;

  test('formats français et anglais', () {
    expect(minor('1 234,56'), 123456);
    expect(minor('1\u202F234,56'), 123456);
    expect(minor('1234.56'), 123456);
    expect(minor('1.234,56'), 123456);
    expect(minor('1,234.56'), 123456);
    expect(minor('1.234.567'), 123456700);
    expect(minor('74200'), 7420000);
    expect(minor(',5'), 50);
  });

  test('signes', () {
    expect(minor('-320'), -32000);
    expect(minor('\u2212 50'), -5000);
    expect(minor('+10'), 1000);
  });

  test('refuse les saisies invalides ou trop précises', () {
    expect(minor(''), isNull);
    expect(minor('abc'), isNull);
    expect(minor('12,345'), isNull, reason: '3 décimales en euros');
    expect(minor('15,5', jpy), isNull, reason: 'le yen n’a pas de décimales');
    expect(minor('1-2'), isNull);
    expect(minor('99999999999999'), isNull, reason: 'montant irréaliste');
  });

  test('devises sans décimales', () {
    expect(minor('1500', jpy), 1500);
  });
}
