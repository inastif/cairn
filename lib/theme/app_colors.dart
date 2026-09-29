import 'package:flutter/material.dart';

/// Palette « minérale » de Cairn : gris pierre légèrement verdi, texte
/// basalte, accent jade profond, laiton réservé aux paliers du million.
///
/// Contrastes vérifiés (WCAG AA ≥ 4,5:1) pour textPrimary, textSecondary,
/// accent, positive et negative sur surface, en clair comme en sombre.
@immutable
final class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceSunken,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.milestone,
    required this.milestoneSoft,
    required this.positive,
    required this.negative,
    required this.warning,
  });

  static const AppColors light = AppColors(
    background: Color(0xFFF1F3F0),
    surface: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFE6EAE5),
    border: Color(0xFFD9DED8),
    textPrimary: Color(0xFF1A1E1C),
    textSecondary: Color(0xFF515955),
    textTertiary: Color(0xFF7E8681),
    accent: Color(0xFF245E55),
    onAccent: Color(0xFFFFFFFF),
    accentSoft: Color(0xFFDCE9E5),
    milestone: Color(0xFF7A5418),
    milestoneSoft: Color(0xFFEFE4CF),
    positive: Color(0xFF2B7548),
    negative: Color(0xFFA3433A),
    warning: Color(0xFF8F6310),
  );

  static const AppColors dark = AppColors(
    background: Color(0xFF101312),
    surface: Color(0xFF181C1A),
    surfaceSunken: Color(0xFF232826),
    border: Color(0xFF2C3230),
    textPrimary: Color(0xFFEEF0EC),
    textSecondary: Color(0xFFA9B0AB),
    textTertiary: Color(0xFF7A827D),
    accent: Color(0xFF72C2B1),
    onAccent: Color(0xFF0C1F1B),
    accentSoft: Color(0xFF1C302B),
    milestone: Color(0xFFD9B26A),
    milestoneSoft: Color(0xFF3A2F1D),
    positive: Color(0xFF66C28E),
    negative: Color(0xFFE38A7C),
    warning: Color(0xFFE2B15A),
  );

  final Color background;
  final Color surface;
  final Color surfaceSunken;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color accent;
  final Color onAccent;
  final Color accentSoft;
  final Color milestone;
  final Color milestoneSoft;
  final Color positive;
  final Color negative;
  final Color warning;

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceSunken,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? accent,
    Color? onAccent,
    Color? accentSoft,
    Color? milestone,
    Color? milestoneSoft,
    Color? positive,
    Color? negative,
    Color? warning,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      accentSoft: accentSoft ?? this.accentSoft,
      milestone: milestone ?? this.milestone,
      milestoneSoft: milestoneSoft ?? this.milestoneSoft,
      positive: positive ?? this.positive,
      negative: negative ?? this.negative,
      warning: warning ?? this.warning,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) {
      return this;
    }
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      surfaceSunken: mix(surfaceSunken, other.surfaceSunken),
      border: mix(border, other.border),
      textPrimary: mix(textPrimary, other.textPrimary),
      textSecondary: mix(textSecondary, other.textSecondary),
      textTertiary: mix(textTertiary, other.textTertiary),
      accent: mix(accent, other.accent),
      onAccent: mix(onAccent, other.onAccent),
      accentSoft: mix(accentSoft, other.accentSoft),
      milestone: mix(milestone, other.milestone),
      milestoneSoft: mix(milestoneSoft, other.milestoneSoft),
      positive: mix(positive, other.positive),
      negative: mix(negative, other.negative),
      warning: mix(warning, other.warning),
    );
  }
}

/// Couleurs des séries (allocation d'actifs). Toujours accompagnées d'un
/// libellé texte : la couleur ne porte jamais seule l'information.
List<Color> seriesColors(Brightness brightness) => brightness == Brightness.dark
    ? const [Color(0xFF72C2B1), Color(0xFFD9B26A), Color(0xFF8FA3BD), Color(0xFF3F7F72), Color(0xFF7A827D)]
    : const [Color(0xFF245E55), Color(0xFF7A5418), Color(0xFF4B5D73), Color(0xFF6E9F95), Color(0xFFA9B0AB)];

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>() ?? AppColors.light;
}
