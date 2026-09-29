import 'package:cairn/core/money/currency.dart';
import 'package:cairn/core/money/money.dart';

/// Convertit une saisie utilisateur en [Money], sans passer par un double.
///
/// Accepte « 1 234,56 », « 1234.56 », « 1.234,56 », « 1,234.56 », « -320 ».
/// Retourne `null` si la saisie est invalide ou a trop de décimales pour la
/// devise (ex. des centimes en yens).
Money? parseAmount(String input, Currency currency) {
  var text = input
      .replaceAll(RegExp(r'[\s\u00A0\u202F\u2009]'), '')
      .replaceAll('\u2212', '-');
  if (text.isEmpty) {
    return null;
  }
  final negative = text.startsWith('-');
  if (negative || text.startsWith('+')) {
    text = text.substring(1);
  }

  // Un signe ou un separateur seul n'est pas un montant.
  if (!text.contains(RegExp(r'\d'))) {
    return null;
  }

  final lastComma = text.lastIndexOf(',');
  final lastDot = text.lastIndexOf('.');
  String integerPart;
  var fractionPart = '';
  if (lastComma >= 0 && lastDot >= 0) {
    // Le dernier séparateur rencontré est le séparateur décimal.
    final decimalIndex = lastComma > lastDot ? lastComma : lastDot;
    integerPart = text
        .substring(0, decimalIndex)
        .replaceAll(RegExp('[.,]'), '');
    fractionPart = text.substring(decimalIndex + 1);
  } else if (lastComma >= 0 || lastDot >= 0) {
    final separator = lastComma >= 0 ? ',' : '.';
    final parts = text.split(separator);
    if (parts.length > 2) {
      // « 1.234.567 » : séparateurs de milliers.
      integerPart = parts.join();
    } else {
      integerPart = parts[0];
      fractionPart = parts[1];
    }
  } else {
    integerPart = text;
  }

  if (integerPart.isEmpty) {
    integerPart = '0';
  }
  final digitsOnly = RegExp(r'^\d+$');
  if (!digitsOnly.hasMatch(integerPart) ||
      (fractionPart.isNotEmpty && !digitsOnly.hasMatch(fractionPart)) ||
      fractionPart.length > currency.decimalDigits ||
      integerPart.length > 13) {
    return null;
  }

  final paddedFraction = fractionPart.padRight(currency.decimalDigits, '0');
  final minor = int.parse('$integerPart$paddedFraction');
  return Money(negative ? -minor : minor, currency);
}
