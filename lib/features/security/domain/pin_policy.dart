import 'package:meta/meta.dart';

enum PinFailureOutcome {
  /// Mauvais code, d'autres essais restent possibles tout de suite.
  retry,

  /// Mauvais code, attente imposée avant le prochain essai.
  temporaryLockout,

  /// Trop d'échecs : le code est effacé et une nouvelle connexion par
  /// e-mail est exigée.
  wipe,
}

@immutable
final class PinFailureDecision {
  const PinFailureDecision({
    required this.outcome,
    required this.failedAttempts,
    this.lockedUntil,
    this.attemptsBeforeLockout,
  });

  final PinFailureOutcome outcome;
  final int failedAttempts;
  final DateTime? lockedUntil;
  final int? attemptsBeforeLockout;
}

/// Politique d'essais :
/// * essais 1 à 4 : libres ;
/// * à partir du 5e échec : attente de 30 s, doublée à chaque échec
///   (30 s, 1 min, 2 min, 4 min, 8 min) ;
/// * au 10e échec : effacement et reconnexion obligatoire.
abstract final class PinPolicy {
  static const int freeAttempts = 4;
  static const int wipeAfter = 10;
  static const Duration baseLockout = Duration(seconds: 30);

  static PinFailureDecision afterFailure({required int previousFailures, required DateTime now}) {
    final failures = previousFailures + 1;
    if (failures >= wipeAfter) {
      return PinFailureDecision(outcome: PinFailureOutcome.wipe, failedAttempts: failures);
    }
    if (failures <= freeAttempts) {
      return PinFailureDecision(
        outcome: PinFailureOutcome.retry,
        failedAttempts: failures,
        attemptsBeforeLockout: freeAttempts + 1 - failures,
      );
    }
    final multiplier = 1 << (failures - freeAttempts - 1);
    return PinFailureDecision(
      outcome: PinFailureOutcome.temporaryLockout,
      failedAttempts: failures,
      lockedUntil: now.add(baseLockout * multiplier),
    );
  }
}
