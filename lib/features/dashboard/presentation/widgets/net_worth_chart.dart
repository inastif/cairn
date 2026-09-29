import 'package:cairn/core/formatting/app_formatters.dart';
import 'package:cairn/features/net_worth/domain/net_worth_snapshot.dart';
import 'package:cairn/shared/widgets/panel.dart';
import 'package:cairn/theme/app_colors.dart';
import 'package:cairn/theme/app_tokens.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Courbe du patrimoine net sur 12 mois. Sans axe chiffré : la forme reste
/// lisible même en mode confidentialité, sans révéler de montant.
class NetWorthChart extends StatelessWidget {
  const NetWorthChart({required this.history, required this.asOf, super.key});

  final List<NetWorthSnapshot> history;
  final DateTime asOf;

  static const AppFormatters _format = AppFormatters();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.colors;
    final from = DateTime(asOf.year - 1, asOf.month, asOf.day);
    final points = history.where((s) => !s.date.isBefore(from)).toList();

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Évolution sur 12 mois'),
          if (points.length < 2)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Text(
                "L'historique se construit à chaque synchronisation. Reviens dans quelques jours.",
                style: text.bodyMedium,
              ),
            )
          else ...[
            SizedBox(
              height: 140,
              child: Semantics(
                label: _describe(points),
                child: ExcludeSemantics(child: _chart(points, colors)),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_format.monthYear(points.first.date), style: text.bodySmall),
                Text("Aujourd'hui", style: text.bodySmall),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _describe(List<NetWorthSnapshot> points) {
    final first = points.first.netWorth;
    final last = points.last.netWorth;
    final trend = last > first ? 'en hausse' : (last < first ? 'en baisse' : 'stable');
    return 'Courbe du patrimoine net sur 12 mois, $trend.';
  }

  Widget _chart(List<NetWorthSnapshot> points, AppColors colors) {
    final spots = [
      for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].netWorth.major),
    ];
    var minY = spots.first.y;
    var maxY = spots.first.y;
    for (final spot in spots) {
      if (spot.y < minY) minY = spot.y;
      if (spot.y > maxY) maxY = spot.y;
    }
    final padding = (maxY - minY).abs() * 0.12 + 1;

    return LineChart(
      LineChartData(
        minY: minY - padding,
        maxY: maxY + padding,
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            preventCurveOverShooting: true,
            color: colors.accent,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colors.accent.withValues(alpha: 0.16),
                  colors.accent.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
