import 'package:cairn/core/clock/clock_provider.dart';
import 'package:cairn/features/security/application/app_lock_controller.dart';
import 'package:cairn/features/security/data/biometric_authenticator.dart';
import 'package:cairn/features/security/data/secure_store.dart';
import 'package:cairn/features/security/domain/pin_hasher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final class FakeBiometrics implements BiometricAuthenticator {
  FakeBiometrics({required this.available, this.succeeds = true});

  final bool available;
  bool succeeds;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate(String reason) async => succeeds;
}

void main() {
  const pin = '482915';
  late MemorySecureStore store;
  late DateTime now;

  ProviderContainer makeContainer({bool biometrics = false}) {
    final container = ProviderContainer(
      overrides: [
        secureStoreProvider.overrideWithValue(store),
        biometricAuthenticatorProvider.overrideWithValue(FakeBiometrics(available: biometrics)),
        pinHasherProvider.overrideWithValue(const PinHasher(iterations: 500)),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    store = MemorySecureStore();
    now = DateTime(2026, 9, 28, 12);
  });

  test('sans code configuré : pas de verrou', () async {
    final container = makeContainer();
    final state = await container.read(appLockProvider.future);
    expect(state.pinConfigured, isFalse);
    expect(state.locked, isFalse);
  });

  test('création du code : seule une empreinte est stockée', () async {
    final container = makeContainer();
    await container.read(appLockProvider.future);
    await container.read(appLockProvider.notifier).setupPin(pin, enableBiometrics: false);

    final state = container.read(appLockProvider).value!;
    expect(state.pinConfigured, isTrue);
    expect(state.locked, isFalse);
    expect(store.values.values.any((v) => v.contains(pin)), isFalse);
  });

  test('refuse un code trop simple', () async {
    final container = makeContainer();
    await container.read(appLockProvider.future);
    expect(
      () => container.read(appLockProvider.notifier).setupPin('123456', enableBiometrics: false),
      throwsArgumentError,
    );
  });

  test('au redémarrage, l’application est verrouillée', () async {
    final first = makeContainer();
    await first.read(appLockProvider.future);
    await first.read(appLockProvider.notifier).setupPin(pin, enableBiometrics: false);

    final restarted = makeContainer();
    final state = await restarted.read(appLockProvider.future);
    expect(state.locked, isTrue);
  });

  test('mauvais code, puis bon code', () async {
    final container = makeContainer();
    await container.read(appLockProvider.future);
    final controller = container.read(appLockProvider.notifier);
    await controller.setupPin(pin, enableBiometrics: false);
    controller.lock();

    final wrong = await controller.checkPin('000001');
    expect(wrong, isA<PinRejected>());
    expect((wrong as PinRejected).attemptsBeforeLockout, 4);

    expect(await controller.checkPin(pin), isA<PinAccepted>());
    expect(container.read(appLockProvider).value!.locked, isFalse);
    expect(container.read(appLockProvider).value!.failedAttempts, 0);
  });

  test('blocage temporaire, même avec le bon code, puis levée', () async {
    final container = makeContainer();
    await container.read(appLockProvider.future);
    final controller = container.read(appLockProvider.notifier);
    await controller.setupPin(pin, enableBiometrics: false);
    controller.lock();

    for (var i = 0; i < 4; i++) {
      expect(await controller.checkPin('000001'), isA<PinRejected>());
    }
    final fifth = await controller.checkPin('000001');
    expect(fifth, isA<PinLockedOut>());
    expect((fifth as PinLockedOut).until, now.add(const Duration(seconds: 30)));

    expect(await controller.checkPin(pin), isA<PinLockedOut>());

    now = now.add(const Duration(seconds: 31));
    expect(await controller.checkPin(pin), isA<PinAccepted>());
  });

  test('effacement après 10 échecs', () async {
    final container = makeContainer();
    await container.read(appLockProvider.future);
    final controller = container.read(appLockProvider.notifier);
    await controller.setupPin(pin, enableBiometrics: false);
    controller.lock();

    PinCheckResult? last;
    for (var i = 0; i < 10; i++) {
      now = now.add(const Duration(hours: 1));
      last = await controller.checkPin('000001');
    }
    expect(last, isA<PinWiped>());
    expect(container.read(appLockProvider).value!.pinConfigured, isFalse);
    expect(store.values, isEmpty);
  });

  test('déverrouillage biométrique si activé', () async {
    final container = makeContainer(biometrics: true);
    await container.read(appLockProvider.future);
    final controller = container.read(appLockProvider.notifier);
    await controller.setupPin(pin, enableBiometrics: true);
    controller.lock();

    expect(await controller.unlockWithBiometrics(), isTrue);
    expect(container.read(appLockProvider).value!.locked, isFalse);
  });

  test('biométrie ignorée si désactivée', () async {
    final container = makeContainer(biometrics: true);
    await container.read(appLockProvider.future);
    final controller = container.read(appLockProvider.notifier);
    await controller.setupPin(pin, enableBiometrics: false);
    controller.lock();

    expect(await controller.unlockWithBiometrics(), isFalse);
    expect(container.read(appLockProvider).value!.locked, isTrue);
  });
}
