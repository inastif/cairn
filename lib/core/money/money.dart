import 'dart:math' as math;

import 'package:cairn/core/money/currency.dart';
import 'package:meta/meta.dart';

/// Levée quand on combine deux montants de devises différentes sans
/// conversion explicite. Les conversions passent toujours par `FxRates`.
final class CurrencyMismatchException implements Exception {
  const CurrencyMismatchException(this.left, this.right);
  final Currency left;
  final Currency right;

  @override
  String toString() => 'CurrencyMismatchException: $left vs $right';
}

/// Montant monétaire immuable, stocké en ENTIER d'unités mineures
/// (centimes pour l'euro) pour éviter toute dérive des sommes en virgule
/// flottante.
@immutable
final class Money implements Comparable<Money> {
  const Money(this.minorUnits, this.currency);

  factory Money.fromMajor(num amount, Currency currency) {
    if (amount.isNaN || amount.isInfinite) {
      throw ArgumentError.value(amount, 'amount', 'Le montant doit être fini');
    }
    return Money((amount * _factor(currency)).round(), currency);
  }

  factory Money.zero(Currency currency) => Money(0, currency);

  /// Somme d'une liste de montants de même devise.
  static Money sum(Iterable<Money> values, Currency currency) =>
      values.fold<Money>(Money.zero(currency), (total, value) => total + value);

  final int minorUnits;
  final Currency currency;

  static int _factor(Currency currency) => math.pow(10, currency.decimalDigits).toInt();

  /// Valeur en unités majeures (euros). À réserver à l'affichage et aux
  /// calculs statistiques, jamais au stockage.
  double get major => minorUnits / _factor(currency);

  bool get isZero => minorUnits == 0;
  bool get isNegative => minorUnits < 0;
  bool get isPositive => minorUnits > 0;

  Money operator +(Money other) {
    _checkSameCurrency(other);
    return Money(minorUnits + other.minorUnits, currency);
  }

  Money operator -(Money other) {
    _checkSameCurrency(other);
    return Money(minorUnits - other.minorUnits, currency);
  }

  Money operator -() => Money(-minorUnits, currency);

  bool operator <(Money other) => compareTo(other) < 0;
  bool operator <=(Money other) => compareTo(other) <= 0;
  bool operator >(Money other) => compareTo(other) > 0;
  bool operator >=(Money other) => compareTo(other) >= 0;

  Money abs() => isNegative ? -this : this;

  /// Multiplie en arrondissant à l'unité mineure la plus proche.
  Money multiply(num factor) => Money((minorUnits * factor).round(), currency);

  /// Rapport `this / other` (même devise, `other` non nul).
  double ratioTo(Money other) {
    _checkSameCurrency(other);
    if (other.isZero) {
      throw StateError('Division par un montant nul');
    }
    return minorUnits / other.minorUnits;
  }

  void _checkSameCurrency(Money other) {
    if (other.currency != currency) {
      throw CurrencyMismatchException(currency, other.currency);
    }
  }

  @override
  int compareTo(Money other) {
    _checkSameCurrency(other);
    return minorUnits.compareTo(other.minorUnits);
  }

  @override
  bool operator ==(Object other) =>
      other is Money && other.minorUnits == minorUnits && other.currency == currency;

  @override
  int get hashCode => Object.hash(minorUnits, currency);

  @override
  String toString() => '${major.toStringAsFixed(currency.decimalDigits)} ${currency.code}';
}
