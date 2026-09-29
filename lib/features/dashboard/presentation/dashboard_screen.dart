import 'package:cairn/config/app_config.dart';
import 'package:cairn/core/backend/backend_providers.dart';
import 'package:cairn/core/formatting/app_formatters.dart';
import 'package:cairn/features/dashboard/presentation/widgets/millionaire_hero.dart';
import 'package:cairn/features/dashboard/presentation/widgets/month_cashflow_panel.dart';
import 'package:cairn/features/dashboard/presentation/widgets/net_worth_chart.dart';
import 'package:cairn/features/dashboard/presentation/widgets/net_worth_summary.dart';
import 'package:cairn/features/dashboard/presentation/widgets/projection_panel.dart';
import 'package:cairn/features/dashboard/presentation/widgets/score_panel.dart';
import 'package:cairn/features/portfolio/application/portfolio_providers.dart';
import 'package:cairn/features/portfolio/domain/financial_overview.dart';
import 'package:cairn/routing/app_routes.dart';
import 'package:cairn/shared/settings/app_settings.dart';
import 'package:cairn/shared/widgets/state_views.dart';
import 'package:cairn/theme/app_colors.dart';
import 'package:cairn/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(financialOverviewProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: overview.when(
          data: (data) => RefreshIndicator(
            onRefresh: () => ref.refresh(financialOverviewProvider.future),
            child: _DashboardContent(overview: data),
          ),
          loading: () => const LoadingView(),
          error: (error, stackTrace) => ErrorView(
            message: 'Impossible de calculer ton patrimoine pour le moment. '
                'Réessaie dans quelques instants.',
            onRetry: () => ref.invalidate(financialOverviewProvider),
          ),
        ),
      ),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent({required this.overview});

  final FinancialOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asOf = ref.watch(clockProvider)();
    if (overview.assets.isEmpty && overview.liabilities.isEmpty) {
      final editable = !ref.watch(isDemoModeProvider);
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          EmptyView(
            icon: Icons.account_balance_outlined,
            title: 'Ton patrimoine commence ici',
            message: 'Ajoute un compte, un placement ou un bien pour calculer '
                'ton patrimoine net et ton pourcentage millionnaire.',
            actionLabel: editable ? 'Ajouter un élément' : null,
            onAction: editable ? () => context.push(AppRoutes.newAsset) : null,
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.sm,
        AppSpacing.screen,
        AppSpacing.xxxl,
      ),
      children: [
        const _TopBar(),
        const SizedBox(height: AppSpacing.xl),
        MillionaireHero(progress: overview.millionaire),
        const SizedBox(height: AppSpacing.xxl),
        NetWorthSummary(
          overview: overview,
          onTap: () => context.go(AppRoutes.wealth),
        ),
        const SizedBox(height: AppSpacing.lg),
        NetWorthChart(history: overview.history, asOf: asOf),
        const SizedBox(height: AppSpacing.lg),
        MonthCashflowPanel(month: overview.currentMonth, asOf: asOf),
        const SizedBox(height: AppSpacing.lg),
        ScorePanel(score: overview.score),
        const SizedBox(height: AppSpacing.lg),
        ProjectionPanel(overview: overview),
        const SizedBox(height: AppSpacing.xl),
        _SyncFooter(overview: overview, now: asOf),
      ],
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(privacyModeProvider);
    final colors = context.colors;
    return Row(
      children: [
        Expanded(
          child: Text(AppConfig.appName, style: Theme.of(context).textTheme.titleLarge),
        ),
        IconButton(
          tooltip: hidden ? 'Afficher les montants' : 'Masquer les montants',
          onPressed: () => ref.read(privacyModeProvider.notifier).toggle(),
          icon: Icon(
            hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: colors.textSecondary,
          ),
        ),
        IconButton(
          tooltip: 'Synchroniser maintenant',
          onPressed: () => ref.invalidate(financialOverviewProvider),
          icon: Icon(Icons.sync_rounded, color: colors.textSecondary),
        ),
      ],
    );
  }
}

class _SyncFooter extends StatelessWidget {
  const _SyncFooter({required this.overview, required this.now});

  final FinancialOverview overview;
  final DateTime now;

  static const AppFormatters _format = AppFormatters();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final syncedAt = overview.data.lastSyncedAt;
    final hasForeignCurrency =
        overview.assets.any((a) => a.value.currency != overview.breakdown.currency);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          syncedAt == null
              ? 'Jamais synchronisé'
              : 'Dernière synchronisation : ${_format.relativeDateTime(syncedAt, now)}',
          style: text.bodySmall,
        ),
        if (hasForeignCurrency)
          Text(
            overview.breakdown.isComplete
                ? 'Taux de change ${overview.fx.source} du ${_format.dayMonth(overview.fx.asOf)}.'
                : 'Taux de change indisponible pour certaines devises : ces éléments ne sont pas comptés.',
            style: text.bodySmall,
          ),
        if (overview.data.isDemo)
          Text(
            'Données de démonstration. Aucun compte réel n’est connecté.',
            style: text.bodySmall,
          ),
      ],
    );
  }
}
