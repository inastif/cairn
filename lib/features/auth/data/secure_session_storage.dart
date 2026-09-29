import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Stocke la session Supabase dans le Keychain (iOS) / Keystore (Android)
/// au lieu des préférences non chiffrées utilisées par défaut.
final class SecureSessionStorage extends LocalStorage {
  const SecureSessionStorage();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _key = 'supabase_session';

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async => (await _storage.read(key: _key)) != null;

  @override
  Future<String?> accessToken() => _storage.read(key: _key);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: _key, value: persistSessionString);

  @override
  Future<void> removePersistedSession() => _storage.delete(key: _key);
}
