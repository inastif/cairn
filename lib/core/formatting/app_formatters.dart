import 'package:cairn/core/money/currency.dart';
import 'package:cairn/core/money/money.dart';
import 'package:intl/intl.dart';

/// Formatage centralisé. Aucun écran ne formate un montant lui-même.
///
/// `DateFormat` avec une locale non anglaise nécessite
/// `initializeDateFormatting` (appelé dans `main`).
final class AppFormatters {
  const AppFormatters({this.locale = 'fr_FR'});

  final String locale;

  static const String maskGlyphs = '•••••';

  /// Espace insécable avant « % » (typographie française).
  static const String _percentSuffix = '\u00A0%';

  String money(Money value, {bool signed = false, int decimals = 0}) {
    final format = NumberFormat.simpleCurrency(
      locale: locale,
      name: value.currency.code,
      decimalDigits: decimals,
    );
    final text = format.format(value.major);
    return signed && value.isPositive ? '+$text' : text;
  }

  String currencySymbol(Currency currency) =>
      NumberFormat.simpleCurrency(locale: locale, name: currency.code).currencySymbol;

  String maskedMoney(Currency currency) => '$maskGlyphs\u00A0${currencySymbol(currency)}';

  /// Pourcentage millionnaire : TRONQUÉ (jamais arrondi à la hausse) pour ne
  /// pas afficher « 100 % » à 99,996 %. 2 décimales sous 10 %, 1 au-delà.
  String millionairePercent(double percent) {
    final decimals = percent.abs() < 10 ? 2 : 1;
    final truncated = truncate(percent, decimals);
    final format = NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: decimals);
    return '${format.format(truncated)}$_percentSuffix';
  }

  /// Variation relative signée : 0.038 -> « +3,8 % ».
  String signedPercentFromRatio(double ratio, {int decimals = 1}) {
    final format = NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: decimals);
    final value = ratio * 100;
    final text = format.format(value);
    return value > 0 ? '+$text$_percentSuffix' : '$text$_percentSuffix';
  }

  /// Ratio non signé : 0.32 -> « 32 % ».
  String percentFromRatio(double ratio, {int decimals = 0}) {
    final format = NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: decimals);
    return '${format.format(ratio * 100)}$_percentSuffix';
  }

  String decimal(double value, {int decimals = 1}) =>
      NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: decimals).format(value);

  String time(DateTime value) => DateFormat.Hm(locale).format(value);

  String monthShort(DateTime value) => DateFormat.MMM(locale).format(value);

  String monthYear(DateTime value) => DateFormat.yMMMM(locale).format(value);

  String dayMonth(DateTime value) => DateFormat.MMMd(locale).format(value);

  /// « aujourd'hui à 09:42 », « hier à 18:05 », « 12 sept. à 08:10 ».
  String relativeDateTime(DateTime value, DateTime now) {
    final day = DateTime(value.year, value.month, value.day);
    final today = DateTime(now.year, now.month, now.day);
    final difference = today.difference(day).inDays;
    final hour = time(value);
    if (difference == 0) {
      return "aujourd'hui à $hour";
    }
    if (difference == 1) {
      return 'hier à $hour';
    }
    return '${dayMonth(value)} à $hour';
  }

  /// Troncature vers zéro, avec une tolérance contre les erreurs binaires
  /// (0,29 × 100 = 28,999999…).
  static double truncate(double value, int decimals) {
    var factor = 1.0;
    for (var i = 0; i < decimals; i++) {
      factor *= 10;
    }
    const epsilon = 1e-9;
    final scaled = value * factor;
    final truncated = value >= 0 ? (scaled + epsilon).floorToDouble() : (scaled - epsilon).ceilToDouble();
    return truncated / factor;
  }
}
