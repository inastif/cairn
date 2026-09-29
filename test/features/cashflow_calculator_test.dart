import 'package:cairn/core/money/currency.dart';
import 'package:cairn/core/money/fx_rates.dart';
import 'package:cairn/core/money/money.dart';
import 'package:cairn/features/transactions/domain/bank_transaction.dart';
import 'package:cairn/features/transactions/domain/cashflow_calculator.dart';
import 'package:cairn/features/transactions/domain/transaction_category.dart';
import 'package:flutter_test/flutter_test.dart';

Money eur(num v) => Money.fromMajor(v, Currency.eur);

BankTransaction tx(
  String id,
  DateTime date,
  Money amount,
  TransactionCategory category, {
  TransactionStatus status = TransactionStatus.booked,
}) =>
    BankTransaction(
      id: id,
      accountId: 'a',
      bookedAt: date,
      amount: amount,
      description: id,
      category: category,
      status: status,
    );

void main() {
  const calculator = CashflowCalculator();
  final fx = FxRates.identity(Currency.eur);

  test('distingue revenus, dépenses, virements internes et investissements', () {
    final result = calculator.compute(
      transactions: [
        tx('salary', DateTime(2026, 1, 1), eur(3000), TransactionCategory.salary),
        tx('food', DateTime(2026, 1, 5), eur(-200), TransactionCategory.groceries),
        tx('refund', DateTime(2026, 1, 8), eur(50), TransactionCategory.groceries),
        tx('to-savings', DateTime(2026, 1, 10), eur(-500), TransactionCategory.transfer),
        tx('pea', DateTime(2026, 1, 12), eur(-300), TransactionCategory.investment),
        tx('pending', DateTime(2026, 1, 30), eur(-1000), TransactionCategory.shopping,
            status: TransactionStatus.pending),
        tx('march', DateTime(2026, 3, 3), eur(-100), TransactionCategory.leisure),
        tx('yen', DateTime(2026, 3, 4), Money.fromMajor(-5000, Currency.of('JPY')),
            TransactionCategory.travel),
      ],
      currency: Currency.eur,
      fx: fx,
    );

    expect(result.months, hasLength(3), reason: 'février vide est inclus');
    final january = result.months.first;
    expect(january.month, DateTime(2026, 1));
    expect(january.income, eur(3000));
    expect(january.expenses, eur(150));
    expect(january.invested, eur(300));
    expect(january.savings, eur(2850));
    expect(january.savingsRate, closeTo(0.95, 1e-9));
    expect(january.expensesByCategory[TransactionCategory.groceries], eur(150));

    final february = result.months[1];
    expect(february.income, eur(0));
    expect(february.savingsRate, isNull);

    expect(result.months.last.expenses, eur(100));
    expect(result.skippedTransactionIds, ['yen']);
  });

  test('un remboursement de prêt compte comme une dépense (hypothèse prudente)', () {
    final result = calculator.compute(
      transactions: [
        tx('salary', DateTime(2026, 2, 1), eur(2000), TransactionCategory.salary),
        tx('loan', DateTime(2026, 2, 5), eur(-500), TransactionCategory.loanRepayment),
      ],
      currency: Currency.eur,
      fx: fx,
    );
    expect(result.months.single.expenses, eur(500));
    expect(result.months.single.savingsRate, closeTo(0.75, 1e-9));
  });

  test('aucune transaction', () {
    final result = calculator.compute(transactions: const [], currency: Currency.eur, fx: fx);
    expect(result.months, isEmpty);
  });
}
