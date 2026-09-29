import 'dart:math' as math;

import 'package:cairn/core/money/money.dart';
import 'package:meta/meta.dart';

/// Progression du patrimoine net vers la cible (1 000 000 par défaut).
///
/// [percent] est la valeur BRUTE : négative si le patrimoine net est
/// négatif, supérieure à 100 au-delà du million (« 127 % millionnaire »).
/// Seules les jauges visuelles sont bornées, via [progressFraction].
@immutable
final class MillionaireProgress {
  const MillionaireProgress({
    required this.netWorth,
    required this.target,
    required this.percent,
  });

  /// Paliers discrets affichés dans l'application.
  static const List<double> milestones = [1, 5, 10, 25, 50, 75, 100];

  final Money netWorth;
  final Money target;
  final double percent;

  bool get isMillionaire => netWorth >= target;

  double get progressFraction => math.min(1, math.max(0, percent / 100)).toDouble();

  Money get remaining => isMillionaire ? Money.zero(target.currency) : target - netWorth;

  /// Dernier palier franchi, `null` s'il n'y en a aucun.
  double? get lastReachedMilestone {
    double? reached;
    for (final milestone in milestones) {
      if (percent >= milestone) {
        reached = milestone;
      }
    }
    return reached;
  }

  /// Prochain palier, `null` une fois 100 % atteint.
  double? get nextMilestone {
    for (final milestone in milestones) {
      if (percent < milestone) {
        return milestone;
      }
    }
    return null;
  }

  /// Montant restant avant le prochain palier.
  Money? get amountToNextMilestone {
    final next = nextMilestone;
    if (next == null) {
      return null;
    }
    return Money((target.minorUnits * next / 100).round(), target.currency) - netWorth;
  }
}

final class MillionaireCalculator {
  const MillionaireCalculator();

  static const int defaultTargetMajor = 1000000;

  MillionaireProgress compute({required Money netWorth, required Money target}) {
    if (!target.isPositive) {
      throw ArgumentError.value(target, 'target', 'La cible doit être positive');
    }
    if (netWorth.currency != target.currency) {
      throw ArgumentError('Patrimoine et cible doivent être dans la même devise');
    }
    return MillionaireProgress(
      netWorth: netWorth,
      target: target,
      // Multiplication avant division : valeurs exactes aux paliers.
      percent: netWorth.minorUnits * 100 / target.minorUnits,
    );
  }
}
