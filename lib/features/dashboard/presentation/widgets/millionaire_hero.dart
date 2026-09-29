import 'package:cairn/core/formatting/app_formatters.dart';
import 'package:cairn/features/dashboard/presentation/widgets/cairn_progress.dart';
import 'package:cairn/features/millionaire/domain/millionaire_progress.dart';
import 'package:cairn/shared/settings/app_settings.dart';
import 'package:cairn/shared/widgets/amount_text.dart';
import 'package:cairn/theme/app_colors.dart';
import 'package:cairn/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// L'indicateur principal : « à quel pourcentage suis-je millionnaire ? »
class MillionaireHero extends ConsumerWidget {
  const MillionaireHero({required this.progress, super.key});

  final MillionaireProgress progress;

  static const AppFormatters _format = AppFormatters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final colors = context.colors;
    final hidden = ref.watch(privacyModeProvider);
    final percentText = _format.millionairePercent(progress.percent);
    final targetText = _format.money(progress.target);

    return Semantics(
      container: true,
      label: hidden
          ? 'Pourcentage millionnaire masqué'
          : 'Tu es millionnaire à $percentText. Objectif : $targetText.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tu es millionnaire à', style: text.bodyMedium),
                      const SizedBox(height: AppSpacing.sm),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: PrivateText(percentText, style: text.displayLarge),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AmountText(progress.netWorth, style: text.titleMedium),
                      Text('de patrimoine net, objectif $targetText', style: text.bodyMedium),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              CairnProgress(percent: progress.percent),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _MilestoneLine(progress: progress, colors: colors),
        ],
      ),
    );
  }
}

class _MilestoneLine extends StatelessWidget {
  const _MilestoneLine({required this.progress, required this.colors});

  final MillionaireProgress progress;
  final AppColors colors;

  static const AppFormatters _format = AppFormatters();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final reached = progress.lastReachedMilestone;
    final next = progress.nextMilestone;
    final toNext = progress.amountToNextMilestone;

    if (progress.isMillionaire) {
      return Text(
        'Objectif atteint. Chaque nouveau palier se mesure désormais au-delà de 100 %.',
        style: text.bodyMedium,
      );
    }
    if (progress.netWorth.isNegative) {
      return Text(
        "Patrimoine net négatif pour l'instant. Chaque dette remboursée te rapproche du premier palier.",
        style: text.bodyMedium,
      );
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (reached != null)
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.milestoneSoft,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
              child: Text(
                'Palier ${_format.decimal(reached, decimals: 0)}\u00A0% atteint',
                style: text.labelMedium?.copyWith(color: colors.milestone),
              ),
            ),
          ),
        if (next != null && toNext != null) ...[
          Text('Prochain palier ${_format.decimal(next, decimals: 0)}\u00A0%, encore', style: text.bodyMedium),
          AmountText(toNext, style: text.bodyMedium?.copyWith(color: colors.textPrimary)),
        ],
      ],
    );
  }
}
