import 'package:cairn/core/money/fx_rates.dart';
import 'package:cairn/core/money/money.dart';
import 'package:cairn/features/financial_score/domain/financial_score.dart';
import 'package:cairn/features/financial_score/domain/financial_score_calculator.dart';
import 'package:cairn/features/goals/domain/projection_calculator.dart';
import 'package:cairn/features/millionaire/domain/millionaire_progress.dart';
import 'package:cairn/features/net_worth/domain/asset_item.dart';
import 'package:cairn/features/net_worth/domain/liability_item.dart';
import 'package:cairn/features/net_worth/domain/net_worth_calculator.dart';
import 'package:cairn/features/net_worth/domain/net_worth_snapshot.dart';
import 'package:cairn/features/portfolio/domain/portfolio_data.dart';
import 'package:cairn/features/transactions/domain/bank_transaction.dart';
import 'package:cairn/features/transactions/domain/cashflow_calculator.dart';
import 'package:meta/meta.dart';

/// Variation d'un montant entre deux dates.
@immutable
final class Change {
  const Change({required this.amount, required this.relative});

  final Money amount;

  /// `null` si la valeur de départ est nulle ou négative.
  final double? relative;
}

/// Tout ce dont le dashboard a besoin, calculé une seule fois hors UI.
@immutable
final class FinancialOverview {
  const FinancialOverview({
    required this.data,
    required this.breakdown,
    required this.millionaire,
    required this.cashflows,
    required this.currentMonth,
    required this.score,
    required this.projection,
    required this.averageMonthlySavings,
    required this.annualReturnAssumption,
    required this.history,
    required this.changeThisMonth,
    required this.changeThisYear,
  });

  final PortfolioData data;
  final NetWorthBreakdown breakdown;
  final MillionaireProgress millionaire;
  final List<MonthlyCashflow> cashflows;

  /// Mois en cours (partiel), `null` s'il n'a aucune transaction.
  final MonthlyCashflow? currentMonth;
  final FinancialScore score;
  final ProjectionResult projection;
  final Money averageMonthlySavings;
  final double annualReturnAssumption;

  /// Historique trié, point courant inclus en dernière position.
  final List<NetWorthSnapshot> history;
  final Change? changeThisMonth;
  final Change? changeThisYear;

  List<AssetItem> get assets => data.assets;
  List<LiabilityItem> get liabilities => data.liabilities;
  List<BankTransaction> get transactions => data.transactions;
  FxRates get fx => data.fx;
}

/// Assemble les calculateurs du domaine. Pur Dart, entièrement testable.
final class FinancialOverviewBuilder {
  const FinancialOverviewBuilder({
    this.netWorthCalculator = const NetWorthCalculator(),
    this.millionaireCalculator = const MillionaireCalculator(),
    this.cashflowCalculator = const CashflowCalculator(),
    this.scoreCalculator = const FinancialScoreCalculator(),
    this.projectionCalculator = const ProjectionCalculator(),
  });

  final NetWorthCalculator netWorthCalculator;
  final MillionaireCalculator millionaireCalculator;
  final CashflowCalculator cashflowCalculator;
  final FinancialScoreCalculator scoreCalculator;
  final ProjectionCalculator projectionCalculator;

  FinancialOverview build(
    PortfolioData data, {
    required DateTime asOf,
    required double annualReturnAssumption,
  }) {
    final currency = data.reportingCurrency;
    final breakdown = netWorthCalculator.compute(
      assets: data.assets,
      liabilities: data.liabilities,
      reportingCurrency: currency,
      fx: data.fx,
    );
    // La cible peut être exprimée dans une autre devise (ex. 1 000 000 USD
    // suivi en EUR) : elle est alors convertie au taux du jour.
    final target = data.target.currency == currency
        ? data.target
        : data.fx.tryConvert(data.target, currency) ??
            (throw StateError('Aucun taux pour convertir la cible ${data.target.currency}'));
    final millionaire = millionaireCalculator.compute(
      netWorth: breakdown.netWorth,
      target: target,
    );
    final cashflows = cashflowCalculator
        .compute(transactions: data.transactions, currency: currency, fx: data.fx)
        .months;

    final monthStart = DateTime(asOf.year, asOf.month);
    MonthlyCashflow? currentMonth;
    for (final month in cashflows) {
      if (month.month == monthStart) {
        currentMonth = month;
      }
    }

    final history = [
      ...data.snapshots.where((s) => s.date.isBefore(asOf) && s.netWorth.currency == currency),
      NetWorthSnapshot(
        date: asOf,
        grossAssets: breakdown.grossAssets,
        liabilities: breakdown.totalLiabilities,
      ),
    ]..sort((a, b) => a.date.compareTo(b.date));

    final averageSavings = _averageSavings(cashflows, monthStart, breakdown);

    return FinancialOverview(
      data: data,
      breakdown: breakdown,
      millionaire: millionaire,
      cashflows: cashflows,
      currentMonth: currentMonth,
      score: scoreCalculator.compute(
        breakdown: breakdown,
        cashflows: cashflows,
        history: history,
        asOf: asOf,
      ),
      projection: projectionCalculator.estimate(
        current: breakdown.netWorth,
        target: target,
        monthlyContribution: averageSavings,
        annualReturn: annualReturnAssumption,
        from: asOf,
      ),
      averageMonthlySavings: averageSavings,
      annualReturnAssumption: annualReturnAssumption,
      history: List<NetWorthSnapshot>.unmodifiable(history),
      changeThisMonth: _changeSince(history, monthStart, breakdown.netWorth),
      changeThisYear: _changeSince(history, DateTime(asOf.year), breakdown.netWorth),
    );
  }

  /// Épargne mensuelle moyenne sur les 6 derniers mois complets.
  Money _averageSavings(
    List<MonthlyCashflow> cashflows,
    DateTime monthStart,
    NetWorthBreakdown breakdown,
  ) {
    final complete = cashflows.where((c) => c.month.isBefore(monthStart)).toList();
    final window = complete.length > FinancialScoreCalculator.windowMonths
        ? complete.sublist(complete.length - FinancialScoreCalculator.windowMonths)
        : complete;
    if (window.isEmpty) {
      return Money.zero(breakdown.currency);
    }
    final total = window.fold<int>(0, (sum, m) => sum + m.savings.minorUnits);
    return Money((total / window.length).round(), breakdown.currency);
  }

  /// Compare au dernier point strictement antérieur à [boundary]
  /// (ex. fin du mois précédent pour « ce mois-ci »).
  Change? _changeSince(List<NetWorthSnapshot> history, DateTime boundary, Money now) {
    NetWorthSnapshot? reference;
    for (final snapshot in history) {
      if (snapshot.date.isBefore(boundary)) {
        reference = snapshot;
      }
    }
    if (reference == null) {
      return null;
    }
    final past = reference.netWorth;
    final delta = now - past;
    return Change(amount: delta, relative: past.isPositive ? delta.ratioTo(past) : null);
  }
}
