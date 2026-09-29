import 'package:cairn/core/formatting/app_formatters.dart';
import 'package:cairn/features/portfolio/domain/financial_overview.dart';
import 'package:cairn/shared/widgets/amount_text.dart';
import 'package:cairn/shared/widgets/panel.dart';
import 'package:cairn/theme/app_colors.dart';
import 'package:cairn/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class NetWorthSummary extends StatelessWidget {
  const NetWorthSummary({required this.overview, super.key, this.onTap});

  final FinancialOverview overview;
  final VoidCallback? onTap;

  static const AppFormatters _format = AppFormatters();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.colors;
    final breakdown = overview.breakdown;
    final change = overview.changeThisMonth;

    return Panel(
      onTap: onTap,
      semanticLabel: 'Détail du patrimoine',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Patrimoine net', style: text.bodyMedium),
          const SizedBox(height: AppSpacing.xs),
          AmountText(breakdown.netWorth, style: text.headlineMedium),
          if (change != null) ...[
            const SizedBox(height: AppSpacing.xs),
            _ChangeLine(change: change, label: 'ce mois-ci', colors: colors),
          ],
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(child: _Figure(label: 'Patrimoine brut', child: AmountText(breakdown.grossAssets, style: text.titleMedium))),
              Expanded(child: _Figure(label: 'Dettes', child: AmountText(breakdown.totalLiabilities, style: text.titleMedium))),
            ],
          ),
          if (overview.changeThisYear case final year?) ...[
            const SizedBox(height: AppSpacing.lg),
            _ChangeLine(change: year, label: 'depuis le 1er janvier', colors: colors),
          ],
          if (!overview.millionaire.isMillionaire) ...[
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Encore', style: text.bodyMedium),
                AmountText(overview.millionaire.remaining, style: text.bodyMedium?.copyWith(color: colors.textPrimary)),
                Text('pour atteindre ${_format.money(overview.millionaire.target)}', style: text.bodyMedium),
              ],
            ),
          ],
          if (!breakdown.isComplete) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              '${breakdown.excludedItemIds.length} élément(s) non comptés : taux de change indisponible.',
              style: text.bodySmall?.copyWith(color: colors.warning),
            ),
          ],
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.child});

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

class _ChangeLine extends StatelessWidget {
  const _ChangeLine({required this.change, required this.label, required this.colors});

  final Change change;
  final String label;
  final AppColors colors;

  static const AppFormatters _format = AppFormatters();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final up = !change.amount.isNegative;
    final color = up ? colors.positive : colors.negative;
    final relative = change.relative;
    final style = text.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w600);
    return Wrap(
      spacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Icon(up ? Icons.north_east_rounded : Icons.south_east_rounded, size: 16, color: color),
        if (relative != null)
          PrivateText(_format.signedPercentFromRatio(relative), style: style, masked: '••\u00A0%')
        else
          AmountText(change.amount, signed: true, style: style),
        Text(label, style: text.bodyMedium),
      ],
    );
  }
}
