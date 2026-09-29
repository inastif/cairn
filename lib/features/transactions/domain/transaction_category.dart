/// Nature économique d'un flux, utilisée pour ne pas fausser les
/// statistiques : un virement interne n'est ni un revenu ni une dépense,
/// un versement sur un PEA est de l'épargne investie, pas une dépense.
enum TransactionFlow { income, expense, transfer, investment }

enum TransactionCategory {
  housing(TransactionFlow.expense),
  groceries(TransactionFlow.expense),
  restaurants(TransactionFlow.expense),
  transport(TransactionFlow.expense),
  shopping(TransactionFlow.expense),
  subscriptions(TransactionFlow.expense),
  leisure(TransactionFlow.expense),
  travel(TransactionFlow.expense),
  health(TransactionFlow.expense),
  insurance(TransactionFlow.expense),
  taxes(TransactionFlow.expense),
  education(TransactionFlow.expense),

  /// Échéances de prêt (capital + intérêts, non ventilés par les banques).
  /// Comptées comme dépenses : hypothèse prudente sur le taux d'épargne.
  loanRepayment(TransactionFlow.expense),
  salary(TransactionFlow.income),
  otherIncome(TransactionFlow.income),
  investment(TransactionFlow.investment),
  transfer(TransactionFlow.transfer),
  other(TransactionFlow.expense);

  const TransactionCategory(this.flow);

  final TransactionFlow flow;
}
