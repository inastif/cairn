import 'package:cairn/features/auth/domain/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final class SupabaseAuthRepository implements AuthRepository {
  const SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  @override
  bool get isSignedIn => _auth.currentSession != null;

  @override
  String? get email => _auth.currentUser?.email;

  @override
  String? get userId => _auth.currentUser?.id;

  @override
  Stream<bool> signedInChanges() => _auth.onAuthStateChange.map((state) => state.session != null);

  @override
  Future<void> sendCode(String email) async {
    if (!isValidEmail(email)) {
      throw const AuthFailure(AuthFailureKind.invalidEmail);
    }
    await _guard(() => _auth.signInWithOtp(email: email.trim(), shouldCreateUser: true));
  }

  @override
  Future<void> verifyCode({required String email, required String code}) async {
    if (!isPlausibleOtp(code)) {
      throw const AuthFailure(AuthFailureKind.invalidCode);
    }
    await _guard(
      () => _auth.verifyOTP(email: email.trim(), token: code.trim(), type: OtpType.email),
      onAuthError: AuthFailureKind.invalidCode,
    );
  }

  @override
  Future<void> signOut() => _guard(() => _auth.signOut());

  @override
  Future<void> deleteAccount() async {
    await _guard(() => _client.rpc<dynamic>('delete_my_account'));
    // La session locale n'a plus de compte derrière elle.
    try {
      await _auth.signOut();
    } on Object {
      // Déjà invalide côté serveur : rien d'autre à faire.
    }
  }

  Future<void> _guard(
    Future<void> Function() action, {
    AuthFailureKind onAuthError = AuthFailureKind.unknown,
  }) async {
    try {
      await action();
    } on AuthException catch (error) {
      if (error.statusCode == '429' || (error.code ?? '').contains('rate_limit')) {
        throw const AuthFailure(AuthFailureKind.rateLimited);
      }
      throw AuthFailure(onAuthError);
    } on AuthFailure {
      rethrow;
    } on PostgrestException {
      throw const AuthFailure(AuthFailureKind.unknown);
    } on Object {
      throw const AuthFailure(AuthFailureKind.network);
    }
  }
}
