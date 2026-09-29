import 'package:cairn/core/money/money.dart';
import 'package:cairn/features/transactions/domain/transaction_category.dart';
import 'package:meta/meta.dart';

enum TransactionStatus { pending, booked }

@immutable
final class BankTransaction {
  const BankTransaction({
    required this.id,
    required this.accountId,
    required this.bookedAt,
    required this.amount,
    required this.description,
    required this.category,
    this.merchant,
    this.status = TransactionStatus.booked,
    this.isUserCategorized = false,
  });

  final String id;
  final String accountId;
  final DateTime bookedAt;

  /// Signé : positif = entrée d'argent, négatif = sortie.
  final Money amount;
  final String description;
  final String? merchant;
  final TransactionCategory category;
  final TransactionStatus status;

  /// Une catégorie choisie par l'utilisateur n'est jamais écrasée par la
  /// catégorisation automatique.
  final bool isUserCategorized;

  bool get isInflow => amount.isPositive;

  BankTransaction withCategory(TransactionCategory newCategory, {required bool byUser}) =>
      BankTransaction(
        id: id,
        accountId: accountId,
        bookedAt: bookedAt,
        amount: amount,
        description: description,
        merchant: merchant,
        category: newCategory,
        status: status,
        isUserCategorized: byUser,
      );
}
