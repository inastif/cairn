import 'package:cairn/features/financial_score/domain/financial_score.dart';
import 'package:cairn/features/financial_score/presentation/score_details_sheet.dart';
import 'package:cairn/shared/labels/domain_labels.dart';
import 'package:cairn/shared/widgets/panel.dart';
import 'package:cairn/theme/app_colors.dart';
import 'package:cairn/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class ScorePanel extends StatelessWidget {
  const ScorePanel({required this.score, super.key});

  final FinancialScore score;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.colors;
    final reliable = score.hasEnoughData;
    return Panel(
      onTap: () => showScoreDetails(context, score),
      semanticLabel: 'Score financier ${score.value} sur 100. Toucher pour le détail.',
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Score financier', style: text.bodyMedium),
                const SizedBox(height: AppSpacing.xs),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '${score.value}', style: text.headlineMedium),
                      TextSpan(text: ' / 100', style: text.bodyMedium),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  reliable
                      ? DomainLabels.scoreBand(score.band)
                      : 'Données encore insuffisantes pour un score fiable',
                  style: text.bodyMedium?.copyWith(
                    color: reliable ? colors.textPrimary : colors.warning,
                  ),
                ),
              ],
            ),
          ),
          Text('Comprendre', style: text.labelLarge?.copyWith(color: colors.accent)),
          Icon(Icons.chevron_right_rounded, color: colors.accent),
        ],
      ),
    );
  }
}
