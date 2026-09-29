import 'dart:math' as math;

import 'package:cairn/core/money/money.dart';
import 'package:meta/meta.dart';

enum ProjectionOutcome {
  alreadyReached,
  reachable,

  /// Pas d'épargne positive et aucun capital positif à faire fructifier.
  noPositiveGrowth,

  /// Objectif non atteint dans l'horizon maximal simulé (100 ans).
  beyondHorizon,
}

@immutable
final class ProjectionResult {
  const ProjectionResult({required this.outcome, this.months, this.estimatedDate});

  final ProjectionOutcome outcome;
  final int? months;
  final DateTime? estimatedDate;
}

/// Estimation (et non promesse) de la date d'atteinte d'une cible.
///
/// Modèle mensuel, transparent et affiché à l'utilisateur :
///   W(n) = W(n−1) × (1 + r) + C   si W(n−1) > 0
///   W(n) = W(n−1) + C             sinon
/// avec r = (1 + rendement annuel)^(1/12) − 1 et C l'épargne mensuelle
/// moyenne observée. Le rendement n'est pas appliqué à un patrimoine
/// négatif : on ne modélise pas le coût réel de chaque dette.
final class ProjectionCalculator {
  const ProjectionCalculator();

  static const int maxMonths = 1200;

  ProjectionResult estimate({
    required Money current,
    required Money target,
    required Money monthlyContribution,
    required double annualReturn,
    required DateTime from,
  }) {
    if (current.currency != target.currency || monthlyContribution.currency != target.currency) {
      throw ArgumentError('Devises incohérentes dans la projection');
    }
    if (annualReturn <= -1 || annualReturn.isNaN) {
      throw ArgumentError.value(annualReturn, 'annualReturn');
    }
    if (current >= target) {
      return ProjectionResult(outcome: ProjectionOutcome.alreadyReached, months: 0, estimatedDate: from);
    }
    final contribution = monthlyContribution.major;
    if (contribution <= 0 && (!current.isPositive || annualReturn <= 0)) {
      return const ProjectionResult(outcome: ProjectionOutcome.noPositiveGrowth);
    }

    final monthlyRate = math.pow(1 + annualReturn, 1 / 12).toDouble() - 1;
    final goal = target.major;
    var wealth = current.major;
    for (var month = 1; month <= maxMonths; month++) {
      wealth = wealth > 0 ? wealth * (1 + monthlyRate) + contribution : wealth + contribution;
      if (wealth >= goal) {
        return ProjectionResult(
          outcome: ProjectionOutcome.reachable,
          months: month,
          estimatedDate: DateTime(from.year, from.month + month),
        );
      }
    }
    return const ProjectionResult(outcome: ProjectionOutcome.beyondHorizon);
  }
}
