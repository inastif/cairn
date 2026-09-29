import 'package:cairn/features/millionaire/domain/millionaire_progress.dart';
import 'package:cairn/theme/app_colors.dart';
import 'package:cairn/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Signature visuelle de l'application : un cairn, ces empilements de
/// pierres qui balisent un chemin. Chaque pierre est un palier du million
/// (1, 5, 10, 25, 50, 75, 100 %), de la base vers le sommet. Une pierre se
/// remplit progressivement entre deux paliers.
class CairnProgress extends StatelessWidget {
  const CairnProgress({required this.percent, super.key, this.width = 112});

  final double percent;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: percent),
        duration: AppMotion.resolve(AppMotion.reveal, reduceMotion: reduceMotion),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => CustomPaint(
          size: Size(width, width * 1.3),
          painter: CairnPainter(
            percent: value,
            fill: colors.milestone,
            empty: colors.surfaceSunken,
            outline: colors.border,
          ),
        ),
      ),
    );
  }
}

class CairnPainter extends CustomPainter {
  CairnPainter({
    required this.percent,
    required this.fill,
    required this.empty,
    required this.outline,
  });

  final double percent;
  final Color fill;
  final Color empty;
  final Color outline;

  /// Taux de remplissage de la pierre [index], entre 0 et 1.
  static double fillFor(int index, double percent) {
    const milestones = MillionaireProgress.milestones;
    final lower = index == 0 ? 0.0 : milestones[index - 1];
    final upper = milestones[index];
    final ratio = (percent - lower) / (upper - lower);
    return ratio < 0 ? 0.0 : (ratio > 1 ? 1.0 : ratio);
  }

  @override
  void paint(Canvas canvas, Size size) {
    const milestones = MillionaireProgress.milestones;
    final count = milestones.length;
    final slot = size.height / count;
    final stoneHeight = slot * 0.8;

    final emptyPaint = Paint()..color = empty;
    final fillPaint = Paint()..color = fill;
    final outlinePaint = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var i = 0; i < count; i++) {
      // Pierres de plus en plus petites vers le sommet, légèrement décalées
      // pour évoquer un empilement naturel.
      final stoneWidth = size.width * (1 - i * 0.075);
      final offsetX = size.width * 0.035 * (i.isEven ? 1 : -1) * (i == 0 ? 0 : 1);
      final left = (size.width - stoneWidth) / 2 + offsetX;
      final top = size.height - (i + 1) * slot + (slot - stoneHeight) / 2;
      final rect = Rect.fromLTWH(left, top, stoneWidth, stoneHeight);
      final stone = RRect.fromRectAndRadius(rect, Radius.circular(stoneHeight / 2));

      canvas.drawRRect(stone, emptyPaint);
      final ratio = fillFor(i, percent);
      if (ratio > 0) {
        canvas
          ..save()
          ..clipRRect(stone)
          ..drawRect(Rect.fromLTWH(left, top, stoneWidth * ratio, stoneHeight), fillPaint)
          ..restore();
      }
      if (ratio < 1) {
        canvas.drawRRect(stone, outlinePaint);
      }
    }
  }

  @override
  bool shouldRepaint(CairnPainter oldDelegate) =>
      oldDelegate.percent != percent ||
      oldDelegate.fill != fill ||
      oldDelegate.empty != empty ||
      oldDelegate.outline != outline;
}
