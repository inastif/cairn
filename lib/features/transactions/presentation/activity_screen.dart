import 'package:cairn/core/formatting/app_formatters.dart';
import 'package:cairn/features/portfolio/application/portfolio_providers.dart';
import 'package:cairn/features/transactions/domain/bank_transaction.dart';
import 'package:cairn/shared/labels/domain_labels.dart';
import 'package:cairn/shared/widgets/amount_text.dart';
import 'package:cairn/shared/widgets/state_views.dart';
import 'package:cairn/theme/app_colors.dart';
import 'package:cairn/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Liste des opérations (lecture seule). Le module Transactions ajoutera
/// les filtres, la recatégorisation, l'analyse des dépenses et l'épargne.
class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(financialOverviewProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Activité')),
      body: overview.when(
        loading: () => const LoadingView(),
        error: (error, stackTrace) => ErrorView(
          message: 'Impossible d’afficher tes opérations pour le moment.',
          onRetry: () => ref.invalidate(financialOverviewProvider),
        ),
        data: (data) {
          final transactions = data.transactions;
          if (transactions.isEmpty) {
            return const EmptyView(
              icon: Icons.receipt_long_outlined,
              title: 'Aucune opération',
              message: 'Les opérations de tes comptes apparaîtront ici après la première synchronisation.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.xxxl),
            itemCount: transactions.length,
            itemBuilder: (context, index) => _TransactionRow(transaction: transactions[index]),
          );
        },
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction});

  final BankTransaction transaction;

  static const AppFormatters _format = AppFormatters();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.description, style: text.bodyLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  '${DomainLabels.category(transaction.category)}, ${_format.dayMonth(transaction.bookedAt)}',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          AmountText(
            transaction.amount,
            signed: true,
            decimals: 2,
            style: text.bodyLarge?.copyWith(
              color: transaction.isInflow ? colors.positive : colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
