import 'package:cairn/core/money/currency.dart';
import 'package:cairn/core/money/money.dart';
import 'package:meta/meta.dart';

/// Taux de change datés et sourcés.
///
/// Convention : 1 unité de [base] = `rate` unités de la devise cotée
/// (format des taux de référence de la BCE, base EUR).
///
/// Une conversion impossible (taux absent) retourne `null` : l'appelant
/// DOIT signaler l'exclusion plutôt que d'inventer un taux.
@immutable
final class FxRates {
  FxRates({
    required this.base,
    required Map<String, double> rates,
    required this.asOf,
    required this.source,
  }) : _rates = _normalize(base, rates);

  /// Taux neutres : seule la devise de base est convertible.
  factory FxRates.identity(Currency base, {DateTime? asOf}) => FxRates(
        base: base,
        rates: const {},
        asOf: asOf ?? DateTime.fromMillisecondsSinceEpoch(0),
        source: 'identity',
      );

  final Currency base;
  final DateTime asOf;

  /// Origine des taux, affichée à l'utilisateur (ex. « BCE », « démo »).
  final String source;
  final Map<String, double> _rates;

  static Map<String, double> _normalize(Currency base, Map<String, double> rates) {
    final result = <String, double>{};
    for (final entry in rates.entries) {
      final code = Currency.of(entry.key).code;
      final rate = entry.value;
      if (rate.isNaN || rate.isInfinite || rate <= 0) {
        throw ArgumentError.value(rate, 'rates[$code]', 'Taux strictement positif attendu');
      }
      result[code] = rate;
    }
    result[base.code] = 1;
    return Map.unmodifiable(result);
  }

  bool supports(Currency currency) => _rates.containsKey(currency.code);

  /// Convertit [money] vers [target]. `null` si un taux manque.
  Money? tryConvert(Money money, Currency target) {
    if (money.currency == target) {
      return money;
    }
    final fromRate = _rates[money.currency.code];
    final toRate = _rates[target.code];
    if (fromRate == null || toRate == null) {
      return null;
    }
    final amountInBase = money.major / fromRate;
    return Money.fromMajor(amountInBase * toRate, target);
  }
}
