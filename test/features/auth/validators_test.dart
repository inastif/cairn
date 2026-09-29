import 'package:cairn/features/auth/domain/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('adresses e-mail', () {
    expect(isValidEmail('lea@example.com'), isTrue);
    expect(isValidEmail('  lea.martin+cairn@mail.fr '), isTrue);
    expect(isValidEmail('lea@'), isFalse);
    expect(isValidEmail('lea example.com'), isFalse);
    expect(isValidEmail(''), isFalse);
  });

  test('codes à usage unique', () {
    expect(isPlausibleOtp('123456'), isTrue);
    expect(isPlausibleOtp('12345678'), isTrue);
    expect(isPlausibleOtp('12345'), isFalse);
    expect(isPlausibleOtp('12a456'), isFalse);
  });

  test('messages lisibles', () {
    expect(const AuthFailure(AuthFailureKind.rateLimited).message, contains('Trop de demandes'));
  });
}
