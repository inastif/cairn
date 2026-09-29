/// Paramètres PUBLICS de connexion à Supabase, fournis au build :
/// `flutter run --dart-define-from-file=env/dev.json`.
///
/// La clé « publishable » (ou « anon » sur les anciens projets) est conçue
/// pour être embarquée dans l'app : la sécurité repose sur les politiques
/// RLS de la base. La clé `service_role` ne doit JAMAIS apparaître ici.
final class SupabaseConfig {
  const SupabaseConfig({required this.url, required this.publishableKey});

  factory SupabaseConfig.fromEnvironment() => const SupabaseConfig(
        url: String.fromEnvironment('SUPABASE_URL'),
        publishableKey: String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
      );

  final String url;
  final String publishableKey;

  /// Sans configuration, l'application tourne en mode démonstration.
  bool get isConfigured =>
      url.startsWith('https://') && !url.contains('VOTRE-PROJET') && publishableKey.isNotEmpty;
}
