/// Environnements d'exécution. Sélectionné au build via
/// `--dart-define=APP_ENV=development|staging|production`.
enum AppEnvironment {
  development,
  staging,
  production;

  static AppEnvironment fromName(String name) => AppEnvironment.values
      .firstWhere((e) => e.name == name, orElse: () => AppEnvironment.development);
}

/// Configuration publique de l'application.
///
/// Ne contient AUCUN secret : tout secret (clés Open Banking, clés de
/// service Supabase, clés d'API de marché) reste exclusivement côté serveur.
abstract final class AppConfig {
  /// Nom de travail. Centralisé ici pour pouvoir renommer la marque sans
  /// toucher au reste du code (disponibilité juridique à vérifier).
  static const String appName = 'Cairn';

  static final AppEnvironment environment = AppEnvironment.fromName(
    const String.fromEnvironment('APP_ENV', defaultValue: 'development'),
  );

  /// Tant qu'aucun fournisseur Open Banking n'est branché, l'application
  /// fonctionne exclusivement sur des profils de démonstration.
  static const bool demoMode = bool.fromEnvironment('DEMO_MODE', defaultValue: true);

  /// Hypothèse de rendement annuel utilisée pour la projection vers 1 M.
  /// Affichée systématiquement à l'utilisateur à côté de l'estimation.
  static const double defaultAnnualReturnAssumption = 0.03;
}
