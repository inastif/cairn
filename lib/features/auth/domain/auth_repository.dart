/// Raisons d'échec présentées à l'utilisateur.
enum AuthFailureKind { invalidEmail, invalidCode, rateLimited, network, unknown }

final class AuthFailure implements Exception {
  const AuthFailure(this.kind);

  final AuthFailureKind kind;

  String get message => switch (kind) {
        AuthFailureKind.invalidEmail => 'Adresse e-mail invalide.',
        AuthFailureKind.invalidCode => 'Code incorrect ou expiré. Demande un nouveau code.',
        AuthFailureKind.rateLimited => 'Trop de demandes. Réessaie dans quelques minutes.',
        AuthFailureKind.network => 'Connexion impossible. Vérifie ton accès à Internet.',
        AuthFailureKind.unknown => 'Une erreur est survenue. Réessaie.',
      };

  @override
  String toString() => 'AuthFailure($kind)';
}

/// Authentification sans mot de passe : un code à usage unique est envoyé
/// par e-mail. Apple et Google viendront s'ajouter derrière cette interface.
abstract interface class AuthRepository {
  bool get isSignedIn;
  String? get email;
  String? get userId;

  /// Émet `true` / `false` à chaque connexion ou déconnexion.
  Stream<bool> signedInChanges();

  Future<void> sendCode(String email);

  Future<void> verifyCode({required String email, required String code});

  Future<void> signOut();

  /// Supprime définitivement le compte et toutes les données associées.
  Future<void> deleteAccount();
}

final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

bool isValidEmail(String value) => _emailPattern.hasMatch(value.trim());

/// Longueur du code : 6 par défaut chez Supabase, configurable jusqu'à 10.
bool isPlausibleOtp(String value) => RegExp(r'^\d{6,10}$').hasMatch(value.trim());
