import 'package:cairn/core/formatting/app_formatters.dart';
import 'package:cairn/features/goals/domain/projection_calculator.dart';
import 'package:cairn/features/portfolio/domain/financial_overview.dart';
import 'package:cairn/shared/widgets/amount_text.dart';
import 'package:cairn/shared/widgets/panel.dart';
import 'package:cairn/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class ProjectionPanel extends StatelessWidget {
  const ProjectionPanel({required this.overview, super.key});

  final FinancialOverview overview;

  static const AppFormatters _format = AppFormatters();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final projection = overview.projection;
    final target = _format.money(overview.millionaire.target);

    final headline = switch (projection.outcome) {
      ProjectionOutcome.alreadyReached => 'Objectif de $target atteint.',
      ProjectionOutcome.reachable =>
        'À ton rythme actuel, $target vers ${projection.estimatedDate!.year}',
      ProjectionOutcome.noPositiveGrowth =>
        "Pas d'estimation possible : l'épargne moyenne récente n'est pas positive.",
      ProjectionOutcome.beyondHorizon =>
        "Au rythme actuel, l'objectif dépasse l'horizon de 100 ans simulé.",
    };

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Projection'),
          Text(headline, style: text.bodyLarge),
          if (projection.outcome == ProjectionOutcome.reachable) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Hypothèses : épargne moyenne de', style: text.bodySmall),
                AmountText(overview.averageMonthlySavings, style: text.bodySmall),
                Text(
                  'par mois et rendement de '
                  '${_format.percentFromRatio(overview.annualReturnAssumption)} par an.',
                  style: text.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text('Estimation indicative, pas une promesse.', style: text.bodySmall),
          ],
        ],
      ),
    );
  }
}
