import 'package:meta/meta.dart';

/// Devise ISO 4217 avec son nombre de décimales (unités mineures).
///
/// Les cryptomonnaies ne sont PAS des [Currency] : une position crypto est
/// une quantité valorisée dans une devise fiat.
@immutable
final class Currency {
  const Currency._(this.code, this.decimalDigits);

  factory Currency.of(String code) {
    final normalized = code.trim().toUpperCase();
    if (!_isoPattern.hasMatch(normalized)) {
      throw ArgumentError.value(code, 'code', 'Code ISO 4217 à 3 lettres attendu');
    }
    return Currency._(normalized, _nonStandardDigits[normalized] ?? 2);
  }

  static final RegExp _isoPattern = RegExp(r'^[A-Z]{3}$');

  /// Devises dont l'exposant ISO 4217 diffère de 2.
  static const Map<String, int> _nonStandardDigits = {
    'BIF': 0, 'CLP': 0, 'DJF': 0, 'GNF': 0, 'ISK': 0, 'JPY': 0, 'KMF': 0,
    'KRW': 0, 'PYG': 0, 'RWF': 0, 'UGX': 0, 'VND': 0, 'VUV': 0, 'XAF': 0,
    'XOF': 0, 'XPF': 0,
    'BHD': 3, 'IQD': 3, 'JOD': 3, 'KWD': 3, 'LYD': 3, 'OMR': 3, 'TND': 3,
  };

  static final Currency eur = Currency.of('EUR');
  static final Currency usd = Currency.of('USD');
  static final Currency gbp = Currency.of('GBP');
  static final Currency chf = Currency.of('CHF');

  final String code;
  final int decimalDigits;

  @override
  bool operator ==(Object other) => other is Currency && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => code;
}
