import 'dart:math' as math;

import 'package:cairn/features/financial_score/domain/financial_score.dart';
import 'package:cairn/features/net_worth/domain/asset_item.dart';
import 'package:cairn/features/net_worth/domain/net_worth_calculator.dart';
import 'package:cairn/features/net_worth/domain/net_worth_snapshot.dart';
import 'package:cairn/features/transactions/domain/cashflow_calculator.dart';

/// Implémente la méthodologie documentée dans [ScoreFactor].
final class FinancialScoreCalculator {
  const FinancialScoreCalculator();

  /// Fenêtre d'analyse : les N derniers mois COMPLETS (le mois en cours est
  /// exclu car partiel).
  static const int windowMonths = 6;
  static const double targetSavingsRate = 0.20;
  static const double targetEmergencyMonths = 6;
  static const double trendRange = 0.10;

  /// L'historique de référence doit avoir au moins cet âge.
  static const Duration minimumTrendAge = Duration(days: 90);
  static const Duration idealTrendAge = Duration(days: 365);

  FinancialScore compute({
    required NetWorthBreakdown breakdown,
    required List<MonthlyCashflow> cashflows,
    required List<NetWorthSnapshot> history,
    required DateTime asOf,
  }) {
    final currentMonth = DateTime(asOf.year, asOf.month);
    final complete = cashflows.where((c) => c.month.isBefore(currentMonth)).toList()
      ..sort((a, b) => a.month.compareTo(b.month));
    final window = complete.length > windowMonths
        ? complete.sublist(complete.length - windowMonths)
        : complete;

    final components = [
      _savingsRate(window),
      _emergencyFund(breakdown, window),
      _debtRatio(breakdown),
      _regularity(window),
      _trend(breakdown, history, asOf),
      _diversification(breakdown),
    ];

    var availableWeight = 0;
    var points = 0.0;
    for (final component in components) {
      if (component.isAvailable) {
        availableWeight += component.factor.weight;
        points += component.points;
      }
    }
    final value = availableWeight == 0 ? 0 : (points / availableWeight * 100).round();

    return FinancialScore(
      value: math.min(100, math.max(0, value)),
      components: List<ScoreComponent>.unmodifiable(components),
      availableWeight: availableWeight,
    );
  }

  static double _clamp01(double value) => math.min(1, math.max(0, value)).toDouble();

  ScoreComponent _savingsRate(List<MonthlyCashflow> window) {
    final income = window.fold<int>(0, (sum, m) => sum + m.income.minorUnits);
    if (income <= 0) {
      return const ScoreComponent(factor: ScoreFactor.savingsRate, subscore: null);
    }
    final savings = window.fold<int>(0, (sum, m) => sum + m.savings.minorUnits);
    final rate = savings / income;
    return ScoreComponent(
      factor: ScoreFactor.savingsRate,
      subscore: _clamp01(rate / targetSavingsRate),
      measuredValue: rate,
    );
  }

  ScoreComponent _emergencyFund(NetWorthBreakdown breakdown, List<MonthlyCashflow> window) {
    if (window.isEmpty) {
      return const ScoreComponent(factor: ScoreFactor.emergencyFund, subscore: null);
    }
    final totalExpenses = window.fold<int>(0, (sum, m) => sum + m.expenses.minorUnits);
    final averageExpenses = totalExpenses / window.length;
    if (averageExpenses <= 0) {
      return const ScoreComponent(factor: ScoreFactor.emergencyFund, subscore: null);
    }
    final months = breakdown.assetsOf(AssetClass.cash).minorUnits / averageExpenses;
    return ScoreComponent(
      factor: ScoreFactor.emergencyFund,
      subscore: _clamp01(months / targetEmergencyMonths),
      measuredValue: months,
    );
  }

  ScoreComponent _debtRatio(NetWorthBreakdown breakdown) {
    final assets = breakdown.grossAssets;
    final debts = breakdown.totalLiabilities;
    if (assets.isZero && debts.isZero) {
      return const ScoreComponent(factor: ScoreFactor.debtRatio, subscore: null);
    }
    if (assets.isZero) {
      return const ScoreComponent(factor: ScoreFactor.debtRatio, subscore: 0.0);
    }
    final ratio = debts.ratioTo(assets);
    return ScoreComponent(
      factor: ScoreFactor.debtRatio,
      subscore: _clamp01(1 - ratio),
      measuredValue: ratio,
    );
  }

  ScoreComponent _regularity(List<MonthlyCashflow> window) {
    if (window.length < 3) {
      return const ScoreComponent(factor: ScoreFactor.savingsRegularity, subscore: null);
    }
    final positive = window.where((m) => m.savings.isPositive).length;
    final share = positive / window.length;
    return ScoreComponent(
      factor: ScoreFactor.savingsRegularity,
      subscore: share,
      measuredValue: share,
    );
  }

  ScoreComponent _trend(
    NetWorthBreakdown breakdown,
    List<NetWorthSnapshot> history,
    DateTime asOf,
  ) {
    final latestAllowed = asOf.subtract(minimumTrendAge);
    final ideal = asOf.subtract(idealTrendAge);
    NetWorthSnapshot? reference;
    for (final snapshot in history) {
      if (snapshot.date.isAfter(latestAllowed) ||
          snapshot.netWorth.currency != breakdown.currency) {
        continue;
      }
      if (reference == null ||
          snapshot.date.difference(ideal).abs() < reference.date.difference(ideal).abs()) {
        reference = snapshot;
      }
    }
    if (reference == null) {
      return const ScoreComponent(factor: ScoreFactor.netWorthTrend, subscore: null);
    }
    final now = breakdown.netWorth;
    final past = reference.netWorth;
    if (!past.isPositive) {
      // Pas de variation relative calculable depuis un patrimoine nul ou
      // négatif : on regarde seulement le sens de l'évolution.
      return ScoreComponent(factor: ScoreFactor.netWorthTrend, subscore: now > past ? 1.0 : 0.0);
    }
    final growth = (now - past).ratioTo(past);
    return ScoreComponent(
      factor: ScoreFactor.netWorthTrend,
      subscore: _clamp01((growth + trendRange) / (2 * trendRange)),
      measuredValue: growth,
    );
  }

  ScoreComponent _diversification(NetWorthBreakdown breakdown) {
    if (!breakdown.grossAssets.isPositive) {
      return const ScoreComponent(factor: ScoreFactor.diversification, subscore: null);
    }
    final classes = AssetClass.values;
    final hhi = classes.fold<double>(0, (sum, c) {
      final share = breakdown.shareOf(c);
      return sum + share * share;
    });
    final index = (1 - hhi) / (1 - 1 / classes.length);
    return ScoreComponent(
      factor: ScoreFactor.diversification,
      subscore: _clamp01(index),
      measuredValue: index,
    );
  }
}
