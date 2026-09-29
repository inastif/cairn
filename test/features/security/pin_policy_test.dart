import 'package:cairn/features/security/domain/pin_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 28, 12);

  PinFailureDecision after(int previous) => PinPolicy.afterFailure(previousFailures: previous, now: now);

  test('4 essais libres, avec le nombre restant', () {
    expect(after(0).outcome, PinFailureOutcome.retry);
    expect(after(0).attemptsBeforeLockout, 4);
    expect(after(3).outcome, PinFailureOutcome.retry);
    expect(after(3).attemptsBeforeLockout, 1);
  });

  test('attente doublée à partir du 5e échec', () {
    expect(after(4).outcome, PinFailureOutcome.temporaryLockout);
    expect(after(4).lockedUntil, now.add(const Duration(seconds: 30)));
    expect(after(5).lockedUntil, now.add(const Duration(minutes: 1)));
    expect(after(8).lockedUntil, now.add(const Duration(minutes: 8)));
  });

  test('effacement au 10e échec', () {
    expect(after(9).outcome, PinFailureOutcome.wipe);
    expect(after(9).failedAttempts, 10);
  });
}
