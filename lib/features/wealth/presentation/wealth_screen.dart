import 'package:cairn/core/backend/backend_providers.dart';
import 'package:cairn/core/formatting/app_formatters.dart';
import 'package:cairn/features/net_worth/domain/asset_item.dart';
import 'package:cairn/features/net_worth/domain/liability_item.dart';
import 'package:cairn/features/net_worth/domain/net_worth_calculator.dart';
import 'package:cairn/features/portfolio/application/portfolio_providers.dart';
import 'package:cairn/features/portfolio/domain/financial_overview.dart';
import 'package:cairn/routing/app_routes.dart';
import 'package:cairn/shared/labels/domain_labels.dart';
import 'package:cairn/shared/widgets/amount_text.dart';
import 'package:cairn/shared/widgets/panel.dart';
import 'package:cairn/shared/widgets/state_views.dart';
import 'package:cairn/theme/app_colors.dart';
import 'package:cairn/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class WealthScreen extends ConsumerWidget {
  const WealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(financialOverviewProvider);
    final editable = !ref.watch(isDemoModeProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patrimoine'),
        actions: [
          if (editable)
            IconButton(
              tooltip: 'Ajouter',
              onPressed: () => _showAddSheet(context),
              icon: const Icon(Icons.add_rounded),
            ),
        ],
      ),
      body: overview.when(
        data: (data) => data.assets.isEmpty && data.liabilities.isEmpty && editable
            ? EmptyView(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Aucun élément pour l’instant',
                message: 'Ajoute tes comptes, placements, biens et dettes pour calculer ton patrimoine net.',
                actionLabel: 'Ajouter un élément',
                onAction: () => _showAddSheet(context),
              )
            : _WealthContent(overview: data, editable: editable),
        loading: () => const LoadingView(),
        error: (error, stackTrace) => ErrorView(
          message: 'Impossible d’afficher ton patrimoine pour le moment.',
          onRetry: () => ref.invalidate(financialOverviewProvider),
        ),
      ),
    );
  }
}

Future<void> _showAddSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.savings_outlined),
            title: const Text('Un actif'),
            subtitle: const Text('Compte, livret, placement, crypto, bien immobilier'),
            onTap: () {
              Navigator.of(sheetContext).pop();
              context.push(AppRoutes.newAsset);
            },
          ),
          ListTile(
            leading: const Icon(Icons.request_quote_outlined),
            title: const Text('Une dette'),
            subtitle: const Text('Crédit immobilier, prêt, crédit renouvelable'),
            onTap: () {
              Navigator.of(sheetContext).pop();
              context.push(AppRoutes.newLiability);
            },
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    ),
  );
}

class _WealthContent extends StatelessWidget {
  const _WealthContent({required this.overview, required this.editable});

  final FinancialOverview overview;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final breakdown = overview.breakdown;
    final hasRealEstate = breakdown.assetsOf(AssetClass.realEstate).isPositive;

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm, AppSpacing.screen, AppSpacing.xxxl),
      children: [
        Text('Patrimoine net', style: text.bodyMedium),
        AmountText(breakdown.netWorth, style: text.headlineMedium),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(child: _LabeledAmount(label: 'Actifs', child: AmountText(breakdown.grossAssets, style: text.titleMedium))),
            Expanded(child: _LabeledAmount(label: 'Dettes', child: AmountText(breakdown.totalLiabilities, style: text.titleMedium))),
          ],
        ),
        if (hasRealEstate) ...[
          const SizedBox(height: AppSpacing.lg),
          _LabeledAmount(
            label: 'Patrimoine net immobilier (biens moins crédits rattachés)',
            child: AmountText(breakdown.realEstateEquity, signed: true, style: text.titleMedium),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        if (breakdown.grossAssets.isPositive) ...[
          const SectionTitle('Répartition des actifs'),
          _AllocationBar(breakdown: breakdown),
          const SizedBox(height: AppSpacing.xl),
        ],
        for (final assetClass in AssetClass.values)
          if (overview.assets.any((a) => a.assetClass == assetClass)) ...[
            SectionTitle(
              DomainLabels.assetClass(assetClass),
              trailing: AmountText(breakdown.assetsOf(assetClass), style: text.titleMedium),
            ),
            Panel(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
              child: Column(
                children: [
                  for (final asset in overview.assets.where((a) => a.assetClass == assetClass))
                    _AssetRow(
                      asset: asset,
                      overview: overview,
                      onTap: editable ? () => context.push(AppRoutes.editAsset(asset.id)) : null,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        if (overview.liabilities.isNotEmpty || breakdown.totalLiabilities.isPositive) ...[
          SectionTitle('Dettes', trailing: AmountText(breakdown.totalLiabilities, style: text.titleMedium)),
          Panel(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
            child: Column(
              children: [
                for (final liability in overview.liabilities)
                  _LiabilityRow(
                    liability: liability,
                    overview: overview,
                    onTap: editable ? () => context.push(AppRoutes.editLiability(liability.id)) : null,
                  ),
                if (breakdown.liabilitiesByType[LiabilityType.overdraft] case final overdraft?)
                  _SimpleRow(
                    title: DomainLabels.liabilityType(LiabilityType.overdraft),
                    subtitle: 'Déduit des comptes à solde négatif',
                    amount: AmountText(overdraft, style: text.bodyLarge),
                  ),
              ],
            ),
          ),
        ],
        if (!breakdown.isComplete) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Certains éléments ne sont pas comptés : aucun taux de change disponible pour leur devise.',
            style: text.bodySmall?.copyWith(color: context.colors.warning),
          ),
        ],
      ],
    );
  }
}

class _LabeledAmount extends StatelessWidget {
  const _LabeledAmount({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.xs),
        child,
      ],
    );
  }
}

class _AllocationBar extends StatelessWidget {
  const _AllocationBar({required this.breakdown});

  final NetWorthBreakdown breakdown;

  static const AppFormatters _format = AppFormatters();

  static int _flexFor(double share) {
    final flex = (share * 1000).round();
    return flex < 1 ? 1 : flex;
  }

  @override
  Widget build(BuildContext context) {
    final palette = seriesColors(Theme.of(context).brightness);
    final text = Theme.of(context).textTheme;
    final classes = [
      for (final c in AssetClass.values)
        if (breakdown.shareOf(c) > 0) c,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                for (final c in classes)
                  Expanded(
                    flex: _flexFor(breakdown.shareOf(c)),
                    child: ColoredBox(color: palette[c.index % palette.length]),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.sm,
          children: [
            for (final c in classes)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: palette[c.index % palette.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs + 2),
                  Text(
                    '${DomainLabels.assetClass(c)} ${_format.percentFromRatio(breakdown.shareOf(c))}',
                    style: text.bodySmall,
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _AssetRow extends StatelessWidget {
  const _AssetRow({required this.asset, required this.overview, this.onTap});

  final AssetItem asset;
  final FinancialOverview overview;
  final VoidCallback? onTap;

  static const AppFormatters _format = AppFormatters();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final fx = overview.fx;
    final reporting = overview.breakdown.currency;
    final converted = fx.tryConvert(asset.value, reporting);
    final isForeign = asset.value.currency != reporting;

    final details = <String>[
      ?asset.institutionName,
      if (isForeign) 'en ${asset.value.currency.code}',
      if (isForeign && converted == null) 'taux indisponible',
    ];

    return _SimpleRow(
      title: asset.name,
      subtitle: details.isEmpty ? null : details.join(', '),
      amount: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AmountText(converted ?? asset.value, style: text.bodyLarge),
          if (isForeign)
            AmountText(asset.value, style: text.bodySmall),
        ],
      ),
      semanticsHint: isForeign ? 'Montant converti depuis ${asset.value.currency.code}, ${_format.dayMonth(fx.asOf)}' : null,
      onTap: onTap,
    );
  }
}

class _LiabilityRow extends StatelessWidget {
  const _LiabilityRow({required this.liability, required this.overview, this.onTap});

  final LiabilityItem liability;
  final FinancialOverview overview;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final reporting = overview.breakdown.currency;
    final converted = overview.fx.tryConvert(liability.outstanding, reporting);
    final isForeign = liability.outstanding.currency != reporting;
    final details = <String>[
      DomainLabels.liabilityType(liability.type),
      ?liability.institutionName,
      if (isForeign && converted == null) 'taux indisponible',
    ];
    return _SimpleRow(
      title: liability.name,
      subtitle: details.join(', '),
      amount: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AmountText(converted ?? liability.outstanding, style: text.bodyLarge),
          if (isForeign) AmountText(liability.outstanding, style: text.bodySmall),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _SimpleRow extends StatelessWidget {
  const _SimpleRow({
    required this.title,
    required this.subtitle,
    required this.amount,
    this.semanticsHint,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget amount;
  final String? semanticsHint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final sub = subtitle;
    final row = Semantics(
      container: true,
      hint: semanticsHint,
      button: onTap != null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kMinTapTarget + 8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: text.bodyLarge),
                    if (sub != null) Text(sub, style: text.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              amount,
            ],
          ),
        ),
      ),
    );
    return onTap == null ? row : InkWell(onTap: onTap, child: row);
  }
}
