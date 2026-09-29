import 'package:cairn/core/money/currency.dart';
import 'package:cairn/core/money/money.dart';
import 'package:cairn/features/transactions/domain/bank_transaction.dart';
import 'package:cairn/features/transactions/domain/transaction_categorizer.dart';
import 'package:cairn/features/transactions/domain/transaction_category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final categorizer = TransactionCategorizer();
  final out = Money.fromMajor(-20, Currency.eur);
  final income = Money.fromMajor(2000, Currency.eur);

  TransactionCategory categorize(String description, [Money? amount]) =>
      categorizer.categorize(description: description, amount: amount ?? out);

  test('normalise casse, accents et ponctuation', () {
    expect(TransactionCategorizer.normalize('  Café-Pâtisserie  ÉLÉONORE '), 'cafe patisserie eleonore');
    expect(TransactionCategorizer.normalize('APPLE.COM/BILL'), 'apple com bill');
  });

  test('catégories courantes', () {
    const cases = {
      'VIR SALAIRE ACME SAS': TransactionCategory.salary,
      'PRLV LOYER AGENCE': TransactionCategory.housing,
      'CB CARREFOUR MARKET': TransactionCategory.groceries,
      'CB E.LECLERC': TransactionCategory.groceries,
      'CB NETFLIX.COM': TransactionCategory.subscriptions,
      'CB SNCF': TransactionCategory.transport,
      'PRLV MAIF': TransactionCategory.insurance,
      'CB PHARMACIE DU CENTRE': TransactionCategory.health,
      'PRLV DGFIP IMPOT': TransactionCategory.taxes,
      'CB AIRBNB': TransactionCategory.travel,
      'CB AMAZON': TransactionCategory.shopping,
      'PRLV ECHEANCE CREDIT AUTO': TransactionCategory.loanRepayment,
      'VERSEMENT PEA': TransactionCategory.investment,
    };
    for (final entry in cases.entries) {
      expect(categorize(entry.key), entry.value, reason: entry.key);
    }
  });

  test("l'ordre des règles lève les ambiguïtés", () {
    expect(categorize('CB UBER EATS'), TransactionCategory.restaurants);
    expect(categorize('CB UBER'), TransactionCategory.transport);
    expect(categorize('VERSEMENT ASSURANCE VIE'), TransactionCategory.investment);
    expect(categorize('VIR LOYER PERCU LOCATAIRE', income), TransactionCategory.otherIncome);
    expect(categorize('VIR INTERNE VERS LIVRET A'), TransactionCategory.transfer);
    expect(categorize('CB AMAZON PRIME'), TransactionCategory.subscriptions);
  });

  test('pas de faux positif à l’intérieur des mots', () {
    // « tax » ne doit pas correspondre à « taxi », ni « eau » à « bureau ».
    expect(categorize('CB TAXI G7'), TransactionCategory.other);
    expect(categorize('CB BUREAU VALLEE'), TransactionCategory.other);
  });

  test('repli selon le sens du flux', () {
    expect(categorize('OPERATION INCONNUE', income), TransactionCategory.otherIncome);
    expect(categorize('OPERATION INCONNUE'), TransactionCategory.other);
  });

  test('une correction utilisateur est mémorisée par commerçant', () {
    final learned = categorizer.withMerchantOverride('Bureau Vallée', TransactionCategory.education);
    expect(
      learned.categorize(description: 'CB BUREAU VALLEE', merchant: 'BUREAU VALLEE', amount: out),
      TransactionCategory.education,
    );
  });

  test('ne réécrit jamais une catégorie choisie par l’utilisateur', () {
    final manual = BankTransaction(
      id: '1',
      accountId: 'a',
      bookedAt: DateTime(2026, 9, 1),
      amount: out,
      description: 'CB CARREFOUR',
      category: TransactionCategory.leisure,
      isUserCategorized: true,
    );
    expect(categorizer.apply(manual).category, TransactionCategory.leisure);

    final auto = manual.withCategory(TransactionCategory.other, byUser: false);
    expect(categorizer.apply(auto).category, TransactionCategory.groceries);
  });
}
