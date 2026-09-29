import 'package:cairn/core/clock/clock_provider.dart';
import 'package:cairn/features/security/data/biometric_authenticator.dart';
import 'package:cairn/features/security/data/secure_store.dart';
import 'package:cairn/features/security/domain/pin_hasher.dart';
import 'package:cairn/features/security/domain/pin_policy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

final secureStoreProvider = Provider<SecureStore>((ref) => const FlutterSecureStore());
final biometricAuthenticatorProvider =
    Provider<BiometricAuthenticator>((ref) => LocalBiometricAuthenticator());
final pinHasherProvider = Provider<PinHasher>((ref) => const PinHasher());

@immutable
final class AppLockState {
  const AppLockState({
    required this.pinConfigured,
    required this.biometricAvailable,
    required this.biometricEnabled,
    required this.locked,
    this.failedAttempts = 0,
    this.lockedUntil,
  });

  final bool pinConfigured;
  final bool biometricAvailable;
  final bool biometricEnabled;
  final bool locked;
  final int failedAttempts;
  final DateTime? lockedUntil;

  bool get canUseBiometrics => biometricAvailable && biometricEnabled;

  AppLockState copyWith({
    bool? pinConfigured,
    bool? biometricEnabled,
    bool? locked,
    int? failedAttempts,
    DateTime? lockedUntil,
    bool clearLockedUntil = false,
  }) {
    return AppLockState(
      pinConfigured: pinConfigured ?? this.pinConfigured,
      biometricAvailable: biometricAvailable,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      locked: locked ?? this.locked,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockedUntil: clearLockedUntil ? null : (lockedUntil ?? this.lockedUntil),
    );
  }
}

sealed class PinCheckResult {
  const PinCheckResult();
}

final class PinAccepted extends PinCheckResult {
  const PinAccepted();
}

final class PinRejected extends PinCheckResult {
  const PinRejected({this.attemptsBeforeLockout});

  final int? attemptsBeforeLockout;
}

final class PinLockedOut extends PinCheckResult {
  const PinLockedOut(this.until);

  final DateTime until;
}

/// Trop d'échecs : le code a été effacé, reconnexion par e-mail exigée.
final class PinWiped extends PinCheckResult {
  const PinWiped();
}

/// Verrou local de l'application (code à 6 chiffres + biométrie).
/// Indépendant du compte : il protège l'accès sur CET appareil.
final class AppLockController extends AsyncNotifier<AppLockState> {
  static const String _hashKey = 'pin_hash';
  static const String _saltKey = 'pin_salt';
  static const String _iterationsKey = 'pin_iterations';
  static const String _biometricKey = 'pin_biometric_enabled';
  static const String _failuresKey = 'pin_failed_attempts';
  static const String _lockedUntilKey = 'pin_locked_until';

  SecureStore get _store => ref.read(secureStoreProvider);
  DateTime _now() => ref.read(clockProvider)();

  @override
  Future<AppLockState> build() async {
    final store = ref.watch(secureStoreProvider);
    final biometricAvailable = await ref.watch(biometricAuthenticatorProvider).isAvailable();
    final pinConfigured = await store.read(_hashKey) != null;
    final lockedUntilText = await store.read(_lockedUntilKey);
    return AppLockState(
      pinConfigured: pinConfigured,
      biometricAvailable: biometricAvailable,
      biometricEnabled: await store.read(_biometricKey) == 'true',
      locked: pinConfigured,
      failedAttempts: int.tryParse(await store.read(_failuresKey) ?? '') ?? 0,
      lockedUntil: lockedUntilText == null ? null : DateTime.tryParse(lockedUntilText),
    );
  }

  Future<AppLockState> _current() async => state.value ?? await future;

  Future<void> setupPin(String pin, {required bool enableBiometrics}) async {
    if (isWeakPin(pin)) {
      throw ArgumentError('Code trop simple');
    }
    final hashed = ref.read(pinHasherProvider).hash(pin);
    await _store.write(_hashKey, hashed.hash);
    await _store.write(_saltKey, hashed.salt);
    await _store.write(_iterationsKey, '${hashed.iterations}');
    await _store.write(_biometricKey, '$enableBiometrics');
    await _resetFailures();
    final current = await _current();
    state = AsyncData(
      current.copyWith(
        pinConfigured: true,
        biometricEnabled: enableBiometrics,
        locked: false,
        failedAttempts: 0,
        clearLockedUntil: true,
      ),
    );
  }

  /// Vérifie le code ; déverrouille si [unlock] et que le code est bon.
  Future<PinCheckResult> checkPin(String pin, {bool unlock = true}) async {
    final current = await _current();
    final now = _now();
    final lockedUntil = current.lockedUntil;
    if (lockedUntil != null && now.isBefore(lockedUntil)) {
      return PinLockedOut(lockedUntil);
    }

    final stored = await _readHash();
    if (stored != null && ref.read(pinHasherProvider).verify(pin, stored)) {
      await _resetFailures();
      state = AsyncData(
        current.copyWith(
          locked: unlock ? false : current.locked,
          failedAttempts: 0,
          clearLockedUntil: true,
        ),
      );
      return const PinAccepted();
    }

    final decision = PinPolicy.afterFailure(previousFailures: current.failedAttempts, now: now);
    switch (decision.outcome) {
      case PinFailureOutcome.wipe:
        await clear();
        return const PinWiped();
      case PinFailureOutcome.retry:
        await _store.write(_failuresKey, '${decision.failedAttempts}');
        state = AsyncData(current.copyWith(failedAttempts: decision.failedAttempts));
        return PinRejected(attemptsBeforeLockout: decision.attemptsBeforeLockout);
      case PinFailureOutcome.temporaryLockout:
        final until = decision.lockedUntil!;
        await _store.write(_failuresKey, '${decision.failedAttempts}');
        await _store.write(_lockedUntilKey, until.toIso8601String());
        state = AsyncData(
          current.copyWith(failedAttempts: decision.failedAttempts, lockedUntil: until),
        );
        return PinLockedOut(until);
    }
  }

  Future<bool> unlockWithBiometrics() async {
    final current = await _current();
    if (!current.canUseBiometrics) {
      return false;
    }
    final ok = await ref
        .read(biometricAuthenticatorProvider)
        .authenticate('Déverrouille ton application');
    if (ok) {
      await _resetFailures();
      state = AsyncData(current.copyWith(locked: false, failedAttempts: 0, clearLockedUntil: true));
    }
    return ok;
  }

  Future<void> setBiometricEnabled({required bool enabled}) async {
    final current = await _current();
    await _store.write(_biometricKey, '$enabled');
    state = AsyncData(current.copyWith(biometricEnabled: enabled));
  }

  /// Reverrouille (retour d'arrière-plan prolongé).
  void lock() {
    final current = state.value;
    if (current != null && current.pinConfigured && !current.locked) {
      state = AsyncData(current.copyWith(locked: true));
    }
  }

  /// Efface le code de cet appareil (déconnexion, suppression, trop d'échecs).
  Future<void> clear() async {
    for (final key in [_hashKey, _saltKey, _iterationsKey, _biometricKey, _failuresKey, _lockedUntilKey]) {
      await _store.delete(key);
    }
    final current = await _current();
    state = AsyncData(
      AppLockState(
        pinConfigured: false,
        biometricAvailable: current.biometricAvailable,
        biometricEnabled: false,
        locked: false,
      ),
    );
  }

  Future<void> _resetFailures() async {
    await _store.delete(_failuresKey);
    await _store.delete(_lockedUntilKey);
  }

  Future<PinHash?> _readHash() async {
    final hash = await _store.read(_hashKey);
    final salt = await _store.read(_saltKey);
    final iterations = int.tryParse(await _store.read(_iterationsKey) ?? '');
    if (hash == null || salt == null || iterations == null) {
      return null;
    }
    return PinHash(salt: salt, iterations: iterations, hash: hash);
  }
}

final appLockProvider =
    AsyncNotifierProvider<AppLockController, AppLockState>(AppLockController.new);
