import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

abstract interface class BiometricAuthenticator {
  Future<bool> isAvailable();
  Future<bool> authenticate(String reason);
}

/// Face ID, Touch ID, empreinte ou visage Android. Indisponible sur le web.
final class LocalBiometricAuthenticator implements BiometricAuthenticator {
  LocalBiometricAuthenticator();

  final LocalAuthentication _auth = LocalAuthentication();

  @override
  Future<bool> isAvailable() async {
    if (kIsWeb) {
      return false;
    }
    try {
      if (!await _auth.isDeviceSupported()) {
        return false;
      }
      return (await _auth.getAvailableBiometrics()).isNotEmpty;
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    if (kIsWeb) {
      return false;
    }
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on Object {
      return false;
    }
  }
}
