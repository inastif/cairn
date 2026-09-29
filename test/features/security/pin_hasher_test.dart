import 'dart:convert';
import 'dart:math';

import 'package:cairn/features/security/domain/pin_hasher.dart';
import 'package:flutter_test/flutter_test.dart';

String hex(List<int> bytes) => bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

void main() {
  // Vecteurs de référence PBKDF2-HMAC-SHA256 (RFC 7914, section 11),
  // recalculés indépendamment avec Python hashlib.
  test('PBKDF2-HMAC-SHA256 conforme aux vecteurs de référence', () {
    final password = utf8.encode('password');
    final salt = utf8.encode('salt');
    expect(
      hex(PinHasher.pbkdf2(password, salt, 1, 32)),
      '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b',
    );
    expect(
      hex(PinHasher.pbkdf2(password, salt, 2, 32)),
      'ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43',
    );
    expect(
      hex(PinHasher.pbkdf2(password, salt, 4096, 32)),
      'c5e478d59288c841aa530db6845c4c8d962893a001ce4e11a4963873aa98134a',
    );
  });

  test('hachage puis vérification, sans conserver le code en clair', () {
    const hasher = PinHasher(iterations: 1000);
    final stored = hasher.hash('482915', random: Random(1));
    expect(stored.hash, isNot(contains('482915')));
    expect(hasher.verify('482915', stored), isTrue);
    expect(hasher.verify('482916', stored), isFalse);
  });

  test('deux hachages du même code diffèrent (sel aléatoire)', () {
    const hasher = PinHasher(iterations: 10);
    final a = hasher.hash('482915', random: Random(1));
    final b = hasher.hash('482915', random: Random(2));
    expect(a.hash, isNot(b.hash));
    expect(a.salt, isNot(b.salt));
  });

  test('refuse les codes trop simples', () {
    for (final pin in ['000000', '111111', '123456', '654321', '234567', '12345', '12345a']) {
      expect(isWeakPin(pin), isTrue, reason: pin);
    }
    for (final pin in ['482915', '130795', '902113']) {
      expect(isWeakPin(pin), isFalse, reason: pin);
    }
  });

  test('comparaison à temps constant', () {
    expect(PinHasher.constantTimeEquals([1, 2, 3], [1, 2, 3]), isTrue);
    expect(PinHasher.constantTimeEquals([1, 2, 3], [1, 2, 4]), isFalse);
    expect(PinHasher.constantTimeEquals([1, 2], [1, 2, 3]), isFalse);
  });
}
