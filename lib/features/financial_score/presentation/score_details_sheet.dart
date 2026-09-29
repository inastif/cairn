import 'package:cairn/features/financial_score/domain/financial_score.dart';
import 'package:cairn/shared/labels/domain_labels.dart';
import 'package:cairn/theme/app_colors.dart';
import 'package:cairn/theme/app_tokens.dart';
import 'package:flutter/material.dart';

Future<void> showScoreDetails(BuildContext context, FinancialScore score) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, controller) => ScoreDetails(score: score, controller: controller),
    ),
  );
}

/// Explique précisément d'où vient chaque point du score.
class ScoreDetails extends StatelessWidget {
  const ScoreDetails({required this.score, super.key, this.controller});

  final FinancialScore score;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.colors;
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(AppSpacing.screen, 0, AppSpacing.screen, AppSpacing.xxl),
      children: [
        Text('Score financier', style: text.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${score.value}/100, ${DomainLabels.scoreBand(score.band).toLowerCase()}.',
          style: text.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Chaque facteur donne un sous-score entre 0 et 1, multiplié par son poids. '
          'Les facteurs sans données suffisantes sont écartés et les autres sont '
          'ramenés sur 100.',
          style: text.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xl),
        for (final component in score.components) ...[
          _ComponentTile(component: component, colors: colors),
          const SizedBox(height: AppSpacing.lg),
        ],
        const Divider(),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Ce score est un indicateur pédagogique calculé à partir de tes données. '
          'Il ne constitue ni un conseil financier ni une évaluation de solvabilité.',
          style: text.bodySmall,
        ),
      ],
    );
  }
}

class _ComponentTile extends StatelessWidget {
  const _ComponentTile({required this.component, required this.colors});

  final ScoreComponent component;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final factor = component.factor;
    final available = component.isAvailable;
    final points = component.points.round();
    return Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(DomainLabels.scoreFactorTitle(factor), style: text.titleMedium)),
              Text(
                available ? '$points/${factor.weight}' : 'non compté',
                style: text.titleMedium?.copyWith(
                  color: available ? colors.textPrimary : colors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: component.subscore ?? 0,
              minHeight: 6,
              color: colors.accent,
              backgroundColor: colors.surfaceSunken,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(DomainLabels.scoreMeasured(component), style: text.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Text(DomainLabels.scoreFactorMethod(factor), style: text.bodyMedium),
        ],
      ),
    );
  }
}
