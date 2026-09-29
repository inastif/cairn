import 'package:cairn/core/money/currency.dart';
import 'package:cairn/core/money/fx_rates.dart';
import 'package:cairn/core/money/money.dart';
import 'package:cairn/features/transactions/domain/bank_transaction.dart';
import 'package:cairn/features/transactions/domain/transaction_category.dart';
import 'package:meta/meta.dart';

/// Flux d'un mois calendaire, dans la devise de reporting.
@immutable
final class MonthlyCashflow {
  const MonthlyCashflow({
    required this.month,
    required this.income,
    required this.expenses,
    required this.invested,
    required this.expensesByCategory,
  });

  /// Premier jour du mois (heure locale).
  final DateTime month;
  final Money income;

  /// Dépenses de consommation, en valeur positive. Les remboursements
  /// (entrées sur une catégorie de dépense) viennent en déduction.
  final Money expenses;

  /// Versements nets vers des investissements (épargne investie).
  final Money invested;
  final Map<TransactionCategory, Money> expensesByCategory;

  /// Épargne = revenus − dépenses de consommation. L'investi en fait partie.
  Money get savings => income - expenses;

  /// `null` sans revenu : un taux d'épargne n'a alors pas de sens.
  double? get savingsRate => income.isPositive ? savings.ratioTo(income) : null;
}

@immutable
final class CashflowResult {
  const CashflowResult({required this.months, required this.skippedTransactionIds});

  /// Mois consécutifs, du plus ancien au plus récent (mois vides inclus).
  final List<MonthlyCashflow> months;

  /// Transactions ignorées faute de taux de change.
  final List<String> skippedTransactionIds;
}

final class CashflowCalculator {
  const CashflowCalculator();

  /// Règles :
  /// * transactions `pending` ignorées (montant encore susceptible de changer) ;
  /// * `transfer` ignoré : un virement entre ses propres comptes ne crée pas
  ///   de richesse ;
  /// * `investment` : sortie = argent investi, entrée = désinvestissement ;
  /// * `income` : ajouté aux revenus ;
  /// * `expense` : sortie = dépense, entrée = remboursement déduit.
  CashflowResult compute({
    required List<BankTransaction> transactions,
    required Currency currency,
    required FxRates fx,
  }) {
    final buckets = <DateTime, _MonthBucket>{};
    final skipped = <String>[];

    for (final transaction in transactions) {
      if (transaction.status == TransactionStatus.pending) {
        continue;
      }
      final amount = fx.tryConvert(transaction.amount, currency);
      if (amount == null) {
        skipped.add(transaction.id);
        continue;
      }
      final key = DateTime(transaction.bookedAt.year, transaction.bookedAt.month);
      final bucket = buckets.putIfAbsent(key, _MonthBucket.new);
      switch (transaction.category.flow) {
        case TransactionFlow.transfer:
          break;
        case TransactionFlow.investment:
          bucket.invested -= amount.minorUnits;
        case TransactionFlow.income:
          bucket.income += amount.minorUnits;
        case TransactionFlow.expense:
          bucket.expenses -= amount.minorUnits;
          bucket.byCategory.update(
            transaction.category,
            (v) => v - amount.minorUnits,
            ifAbsent: () => -amount.minorUnits,
          );
      }
    }

    if (buckets.isEmpty) {
      return CashflowResult(months: const [], skippedTransactionIds: skipped);
    }

    final keys = buckets.keys.toList()..sort();
    final months = <MonthlyCashflow>[];
    for (var month = keys.first;
        !month.isAfter(keys.last);
        month = DateTime(month.year, month.month + 1)) {
      final bucket = buckets[month] ?? _MonthBucket();
      months.add(
        MonthlyCashflow(
          month: month,
          income: Money(bucket.income, currency),
          expenses: Money(bucket.expenses, currency),
          invested: Money(bucket.invested, currency),
          expensesByCategory: Map<TransactionCategory, Money>.unmodifiable({
            for (final entry in bucket.byCategory.entries) entry.key: Money(entry.value, currency),
          }),
        ),
      );
    }
    return CashflowResult(
      months: List<MonthlyCashflow>.unmodifiable(months),
      skippedTransactionIds: List<String>.unmodifiable(skipped),
    );
  }
}

final class _MonthBucket {
  int income = 0;
  int expenses = 0;
  int invested = 0;
  final Map<TransactionCategory, int> byCategory = {};
}
