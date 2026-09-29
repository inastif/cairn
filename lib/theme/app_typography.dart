import 'package:flutter/material.dart';

/// Une seule famille, Manrope (OFL), utilisée à plusieurs graisses.
/// Tous les montants utilisent des chiffres tabulaires pour que les
/// colonnes s'alignent et que les valeurs ne « sautent » pas.
abstract final class AppTypography {
  static const String family = 'Manrope';
  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  static TextTheme textTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 64,
        height: 1.0,
        fontWeight: FontWeight.w700,
        letterSpacing: -2.4,
        color: primary,
        fontFeatures: tabular,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        height: 1.15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: primary,
        fontFeatures: tabular,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        height: 1.25,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: primary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: primary,
        fontFeatures: tabular,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.45, fontWeight: FontWeight.w400, color: primary),
      bodyMedium: TextStyle(fontSize: 14, height: 1.45, fontWeight: FontWeight.w400, color: secondary),
      bodySmall: TextStyle(fontSize: 12.5, height: 1.4, fontWeight: FontWeight.w500, color: secondary),
      labelLarge: TextStyle(fontSize: 15, height: 1.2, fontWeight: FontWeight.w600, color: primary),
      labelMedium: TextStyle(fontSize: 13, height: 1.2, fontWeight: FontWeight.w600, color: secondary),
    );
  }
}
