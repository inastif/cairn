import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';

/// Empreinte d'un code, seule forme sous laquelle il est conservé.
@immutable
final class PinHash {
  const PinHash({required this.salt, required this.iterations, required this.hash});

  final String salt;
  final int iterations;
  final String hash;
}

/// PBKDF2-HMAC-SHA256 (RFC 8018) avec sel aléatoire par appareil.
///
/// Un code à 6 chiffres reste court : la vraie protection vient du stockage
/// matériel (Keychain / Keystore), de la limite d'essais et de l'effacement
/// après trop d'échecs. PBKDF2 rend simplement l'empreinte coûteuse à
/// attaquer si elle était extraite.
final class PinHasher {
  const PinHasher({this.iterations = defaultIterations});

  static const int defaultIterations = 60000;
  static const int keyLength = 32;

  final int iterations;

  PinHash hash(String pin, {Random? random}) {
    final generator = random ?? Random.secure();
    final salt = Uint8List.fromList(List<int>.generate(16, (_) => generator.nextInt(256)));
    final saltText = base64Encode(salt);
    return PinHash(
      salt: saltText,
      iterations: iterations,
      hash: base64Encode(pbkdf2(utf8.encode(pin), salt, iterations, keyLength)),
    );
  }

  bool verify(String pin, PinHash stored) {
    final candidate = pbkdf2(
      utf8.encode(pin),
      base64Decode(stored.salt),
      stored.iterations,
      keyLength,
    );
    return constantTimeEquals(candidate, base64Decode(stored.hash));
  }

  static Uint8List pbkdf2(List<int> password, List<int> salt, int iterations, int length) {
    if (iterations < 1 || length < 1) {
      throw ArgumentError('Paramètres PBKDF2 invalides');
    }
    final hmac = Hmac(sha256, password);
    final output = BytesBuilder();
    var block = 1;
    while (output.length < length) {
      final blockIndex = Uint8List(4)..buffer.asByteData().setUint32(0, block);
      var u = hmac.convert([...salt, ...blockIndex]).bytes;
      final t = Uint8List.fromList(u);
      for (var i = 1; i < iterations; i++) {
        u = hmac.convert(u).bytes;
        for (var j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }
      output.add(t);
      block++;
    }
    return Uint8List.fromList(output.toBytes().sublist(0, length));
  }

  static bool constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

/// Longueur imposée : 6 chiffres.
const int pinLength = 6;

/// Refuse les codes triviaux : chiffres identiques et suites.
bool isWeakPin(String pin) {
  if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
    return true;
  }
  if (pin.split('').toSet().length == 1) {
    return true;
  }
  const ascending = '01234567890';
  const descending = '09876543210';
  return ascending.contains(pin) || descending.contains(pin);
}
