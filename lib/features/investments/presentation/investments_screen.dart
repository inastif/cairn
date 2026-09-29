import 'package:cairn/features/net_worth/domain/asset_item.dart';
import 'package:cairn/features/portfolio/application/portfolio_providers.dart';
import 'package:cairn/shared/widgets/amount_text.dart';
import 'package:cairn/shared/widgets/panel.dart';
import 'package:cairn/shared/widgets/state_views.dart';
import 'package:cairn/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Vue synthétique. Le suivi par position (quantités, prix de revient,
/// plus-values, cours datés) arrive avec le module Investissements.
class InvestmentsScreen extends ConsumerWidget {
  const InvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(financialOverviewProvider);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Investissements')),
      body: overview.when(
        loading: () => const LoadingView(),
        error: (error, stackTrace) => ErrorView(
          message: 'Impossible d’afficher tes investissements pour le moment.',
          onRetry: () => ref.invalidate(financialOverviewProvider),
        ),
        data: (data) {
          final investments = data.breakdown.assetsOf(AssetClass.investments);
          final crypto = data.breakdown.assetsOf(AssetClass.crypto);
          if (!investments.isPositive && !crypto.isPositive) {
            return const EmptyView(
              icon: Icons.show_chart_rounded,
              title: 'Aucun investissement',
              message: 'Ton PEA, ton compte-titres, ton assurance-vie ou tes cryptos apparaîtront ici.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: [
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Placements', style: text.bodyMedium),
                    AmountText(investments, style: text.headlineMedium),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Crypto', style: text.bodyMedium),
                    AmountText(crypto, style: text.headlineMedium),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Le détail par position, la performance et les cours datés arrivent '
                'avec le module Investissements. Aucun prix n’est affiché tant qu’une '
                'source de marché fiable n’est pas branchée.',
                style: text.bodyMedium,
              ),
            ],
          );
        },
      ),
    );
  }
}
