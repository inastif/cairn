/// Échelle d'espacement (base 4).
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Marge horizontale des écrans.
  static const double screen = 20;
}

/// Rayons : hiérarchisés, pas un rayon unique partout.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 14;
  static const double lg = 22;
  static const double pill = 999;
}

/// Durées d'animation. Toutes passent par [AppMotion.resolve] pour
/// respecter « réduire les animations ».
abstract final class AppMotion {
  static const Duration quick = Duration(milliseconds: 180);
  static const Duration reveal = Duration(milliseconds: 900);

  static Duration resolve(Duration duration, {required bool reduceMotion}) =>
      reduceMotion ? Duration.zero : duration;
}

/// Taille minimale des zones tactiles (recommandations iOS 44 pt / Android 48 dp).
const double kMinTapTarget = 48;
