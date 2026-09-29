import 'package:cairn/core/formatting/app_formatters.dart';
import 'package:cairn/features/financial_score/domain/financial_score.dart';
import 'package:cairn/features/net_worth/domain/asset_item.dart';
import 'package:cairn/features/net_worth/domain/liability_item.dart';
import 'package:cairn/features/transactions/domain/transaction_category.dart';

/// Libellés français des concepts du domaine. Point de passage unique en
/// vue de l'internationalisation (fichiers ARB au module i18n).
abstract final class DomainLabels {
  static const AppFormatters _format = AppFormatters();

  static String assetClass(AssetClass value) => switch (value) {
        AssetClass.cash => 'Liquidités',
        AssetClass.investments => 'Placements',
        AssetClass.crypto => 'Crypto',
        AssetClass.realEstate => 'Immobilier',
        AssetClass.other => 'Autres actifs',
      };

  static String liabilityType(LiabilityType value) => switch (value) {
        LiabilityType.mortgage => 'Crédit immobilier',
        LiabilityType.autoLoan => 'Crédit auto',
        LiabilityType.personalLoan => 'Prêt personnel',
        LiabilityType.studentLoan => 'Prêt étudiant',
        LiabilityType.creditCard => 'Crédit renouvelable',
        LiabilityType.overdraft => 'Découvert',
        LiabilityType.other => 'Autre dette',
      };

  static String category(TransactionCategory value) => switch (value) {
        TransactionCategory.housing => 'Logement',
        TransactionCategory.groceries => 'Alimentation',
        TransactionCategory.restaurants => 'Restaurants',
        TransactionCategory.transport => 'Transports',
        TransactionCategory.shopping => 'Shopping',
        TransactionCategory.subscriptions => 'Abonnements',
        TransactionCategory.leisure => 'Loisirs',
        TransactionCategory.travel => 'Voyages',
        TransactionCategory.health => 'Santé',
        TransactionCategory.insurance => 'Assurances',
        TransactionCategory.taxes => 'Impôts',
        TransactionCategory.education => 'Éducation',
        TransactionCategory.loanRepayment => 'Remboursement de prêt',
        TransactionCategory.salary => 'Salaire',
        TransactionCategory.otherIncome => 'Autres revenus',
        TransactionCategory.investment => 'Investissement',
        TransactionCategory.transfer => 'Virement interne',
        TransactionCategory.other => 'Autres',
      };

  static String scoreBand(ScoreBand band) => switch (band) {
        ScoreBand.excellent => 'Très bonne situation financière',
        ScoreBand.good => 'Bonne situation financière',
        ScoreBand.fair => 'Situation financière correcte',
        ScoreBand.building => 'Situation à renforcer',
        ScoreBand.consolidating => 'Situation à consolider',
      };

  static String scoreFactorTitle(ScoreFactor factor) => switch (factor) {
        ScoreFactor.savingsRate => "Taux d'épargne",
        ScoreFactor.emergencyFund => 'Réserve de sécurité',
        ScoreFactor.debtRatio => 'Endettement',
        ScoreFactor.savingsRegularity => "Régularité de l'épargne",
        ScoreFactor.netWorthTrend => 'Évolution du patrimoine',
        ScoreFactor.diversification => 'Diversification',
      };

  static String scoreFactorMethod(ScoreFactor factor) => switch (factor) {
        ScoreFactor.savingsRate =>
          "Part des revenus des 6 derniers mois terminés qui n'a pas été dépensée. "
              'À partir de 20 %, tous les points sont acquis.',
        ScoreFactor.emergencyFund =>
          'Tes liquidités divisées par tes dépenses mensuelles moyennes. '
              '6 mois de dépenses de côté donnent tous les points.',
        ScoreFactor.debtRatio =>
          'Tes dettes rapportées à la valeur totale de tes actifs. '
              'Plus cette part est faible, plus le sous-score est élevé.',
        ScoreFactor.savingsRegularity =>
          'Part des mois récents terminés avec une épargne positive (3 mois minimum).',
        ScoreFactor.netWorthTrend =>
          'Variation de ton patrimoine net sur environ 12 mois : −10 % donne 0 point, '
              '+10 % ou plus donne tous les points.',
        ScoreFactor.diversification =>
          'Répartition entre liquidités, placements, crypto, immobilier et autres actifs. '
              'Tout sur une seule classe donne 0 point.',
      };

  static String scoreMeasured(ScoreComponent component) {
    final value = component.measuredValue;
    if (value == null) {
      return component.isAvailable ? 'Calculé sur le sens de l’évolution' : 'Données insuffisantes';
    }
    return switch (component.factor) {
      ScoreFactor.savingsRate => 'Mesuré : ${_format.percentFromRatio(value)}',
      ScoreFactor.emergencyFund => 'Mesuré : ${_format.decimal(value)} mois',
      ScoreFactor.debtRatio => 'Mesuré : ${_format.percentFromRatio(value)} des actifs',
      ScoreFactor.savingsRegularity => 'Mesuré : ${_format.percentFromRatio(value)} des mois',
      ScoreFactor.netWorthTrend => 'Mesuré : ${_format.signedPercentFromRatio(value)}',
      ScoreFactor.diversification => 'Indice : ${_format.decimal(value, decimals: 2)} sur 1',
    };
  }
}
