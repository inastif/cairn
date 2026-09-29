import 'package:cairn/core/backend/backend_providers.dart';
import 'package:cairn/features/auth/data/supabase_auth_repository.dart';
import 'package:cairn/features/auth/domain/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `null` en mode démonstration.
final authRepositoryProvider = Provider<AuthRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseAuthRepository(client);
});

/// État de connexion, mis à jour en temps réel.
final class AuthSessionNotifier extends Notifier<bool> {
  @override
  bool build() {
    final repository = ref.watch(authRepositoryProvider);
    if (repository == null) {
      return false;
    }
    final subscription = repository.signedInChanges().listen((signedIn) => state = signedIn);
    ref.onDispose(subscription.cancel);
    return repository.isSignedIn;
  }
}

final authSessionProvider = NotifierProvider<AuthSessionNotifier, bool>(AuthSessionNotifier.new);
