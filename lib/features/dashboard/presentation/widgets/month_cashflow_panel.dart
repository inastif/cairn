import 'package:cairn/core/formatting/app_formatters.dart';
import 'package:cairn/features/transactions/domain/cashflow_calculator.dart';
import 'package:cairn/shared/widgets/amount_text.dart';
import 'package:cairn/shared/widgets/panel.dart';
import 'package:cairn/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class MonthCashflowPanel extends StatelessWidget {
  const MonthCashflowPanel({required this.month, required this.asOf, super.key});

  final MonthlyCashflow? month;
  final DateTime asOf;

  static const AppFormatters _format = AppFormatters();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final current = month;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            'Ce mois-ci',
            trailing: Text('au ${_format.dayMonth(asOf)}', style: text.bodySmall),
          ),
          if (current == null)
            Text('Aucune opération ce mois-ci pour le moment.', style: text.bodyMedium)
          else ...[
            _Row(label: 'Revenus', child: AmountText(current.income, style: text.titleMedium)),
            _Row(label: 'Dépenses', child: AmountText(current.expenses, style: text.titleMedium)),
            _Row(label: 'Épargne', child: AmountText(current.savings, signed: true, style: text.titleMedium)),
            if (current.invested.isPositive)
              _Row(label: 'dont investi', child: AmountText(current.invested, style: text.bodyMedium)),
            if (current.savingsRate case final rate?)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: PrivateText(
                  "Taux d'épargne du mois : ${_format.percentFromRatio(rate)}",
                  masked: "Taux d'épargne du mois : ••\u00A0%",
                  style: text.bodyMedium,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
          child,
        ],
      ),
    );
  }
}
