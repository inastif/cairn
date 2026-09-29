import 'package:meta/meta.dart';

/// Facteurs du score financier et leur poids (total = 100).
///
/// MÉTHODOLOGIE (également expliquée dans l'application) :
/// chaque facteur produit un sous-score entre 0 et 1, multiplié par son
/// poids. Un facteur sans données suffisantes est EXCLU et les poids restants
/// sont renormalisés ; si moins de 50 points de poids sont calculables, le
/// score est marqué « données insuffisantes ».
///
/// | Facteur              | Poids | Sous-score                                          |
/// |----------------------|-------|-----------------------------------------------------|
/// | Taux d'épargne       | 25    | taux sur 6 mois complets / 20 %, borné à [0, 1]      |
/// | Réserve de sécurité  | 20    | liquidités / dépenses mensuelles moyennes / 6 mois   |
/// | Endettement          | 20    | 1 − dettes / actifs bruts, borné à [0, 1]            |
/// | Régularité           | 15    | part des mois (≥ 3) avec une épargne positive        |
/// | Évolution            | 10    | variation du patrimoine net : −10 % → 0, +10 % → 1  |
/// | Diversification      | 10    | (1 − HHI) / (1 − 1/5) sur les 5 classes d'actifs      |
///
/// C'est un indicateur pédagogique, pas un conseil financier.
enum ScoreFactor {
  savingsRate(25),
  emergencyFund(20),
  debtRatio(20),
  savingsRegularity(15),
  netWorthTrend(10),
  diversification(10);

  const ScoreFactor(this.weight);

  final int weight;
}

@immutable
final class ScoreComponent {
  const ScoreComponent({required this.factor, required this.subscore, this.measuredValue});

  final ScoreFactor factor;

  /// Entre 0 et 1, `null` si les données sont insuffisantes.
  final double? subscore;

  /// Valeur mesurée, dans l'unité propre au facteur : taux (0,18), nombre de
  /// mois de réserve (4,2), ratio d'endettement (0,3), part de mois positifs,
  /// variation relative, indice de diversification.
  final double? measuredValue;

  bool get isAvailable => subscore != null;

  double get points => (subscore ?? 0) * factor.weight;
}

enum ScoreBand {
  excellent(80),
  good(65),
  fair(50),
  building(35),
  consolidating(0);

  const ScoreBand(this.minimum);

  final int minimum;

  static ScoreBand fromValue(int value) =>
      ScoreBand.values.firstWhere((band) => value >= band.minimum);
}

@immutable
final class FinancialScore {
  const FinancialScore({
    required this.value,
    required this.components,
    required this.availableWeight,
  });

  static const int minimumWeightForReliableScore = 50;

  /// Score entier entre 0 et 100.
  final int value;
  final List<ScoreComponent> components;

  /// Somme des poids des facteurs effectivement calculés.
  final int availableWeight;

  bool get hasEnoughData => availableWeight >= minimumWeightForReliableScore;

  ScoreBand get band => ScoreBand.fromValue(value);
}
