import 'package:cairn/core/money/money.dart';
import 'package:cairn/features/transactions/domain/bank_transaction.dart';
import 'package:cairn/features/transactions/domain/transaction_category.dart';
import 'package:meta/meta.dart';

/// Règle par mots-clés. Les mots-clés sont déjà normalisés (minuscules,
/// sans accents, ponctuation remplacée par des espaces) et sont comparés
/// sur des frontières de mots.
@immutable
final class CategorizationRule {
  const CategorizationRule(this.category, this.keywords);

  final TransactionCategory category;
  final List<String> keywords;
}

/// Catégorisation déterministe et explicable, en trois niveaux :
/// 1. correction de l'utilisateur mémorisée pour ce commerçant ;
/// 2. première règle par mots-clés qui correspond (l'ordre compte) ;
/// 3. repli : `otherIncome` pour une entrée, `other` pour une sortie.
///
/// L'interface est volontairement simple pour pouvoir brancher plus tard un
/// classifieur statistique derrière la même API.
final class TransactionCategorizer {
  TransactionCategorizer({
    List<CategorizationRule> rules = defaultRules,
    Map<String, TransactionCategory> merchantOverrides = const {},
  })  : _rules = List<CategorizationRule>.unmodifiable(rules),
        _overrides = {
          for (final entry in merchantOverrides.entries) normalize(entry.key): entry.value,
        };

  final List<CategorizationRule> _rules;
  final Map<String, TransactionCategory> _overrides;

  /// L'ordre est significatif : « uber eats » avant « uber »,
  /// « assurance vie » avant « assurance », « loyer percu » avant « loyer ».
  static const List<CategorizationRule> defaultRules = [
    CategorizationRule(TransactionCategory.salary, ['salaire', 'salary', 'payroll', 'paie']),
    CategorizationRule(TransactionCategory.otherIncome, [
      'loyer percu', 'loyers percus', 'rental income', 'dividende', 'dividend',
      'interets crediteurs', 'caf', 'pole emploi', 'france travail',
    ]),
    CategorizationRule(TransactionCategory.transfer, [
      'vir interne', 'virement interne', 'internal transfer', 'transfer between',
      'vers livret', 'vers ldds', 'vers compte epargne',
    ]),
    CategorizationRule(TransactionCategory.investment, [
      'versement pea', 'versement assurance vie', 'assurance vie', 'trade republic',
      'degiro', 'interactive brokers', 'boursorama bourse', 'coinbase', 'binance',
      'kraken', 'bitpanda', 'scalable capital',
    ]),
    CategorizationRule(TransactionCategory.loanRepayment, [
      'echeance pret', 'pret immo', 'credit auto', 'remboursement pret', 'pret perso',
      'pret etudiant', 'loan payment', 'mortgage',
    ]),
    CategorizationRule(TransactionCategory.taxes, [
      'impot', 'impots', 'dgfip', 'taxe fonciere', 'taxe habitation', 'tax',
    ]),
    CategorizationRule(TransactionCategory.restaurants, [
      'restaurant', 'uber eats', 'deliveroo', 'just eat', 'mcdonald', 'mcdonalds',
      'burger king', 'kfc', 'starbucks', 'brasserie', 'pizzeria',
    ]),
    CategorizationRule(TransactionCategory.transport, [
      'sncf', 'ratp', 'navigo', 'uber', 'bolt', 'blablacar', 'totalenergies', 'shell',
      'esso', 'peage', 'parking', 'tier', 'lime',
    ]),
    CategorizationRule(TransactionCategory.subscriptions, [
      'netflix', 'spotify', 'deezer', 'disney plus', 'apple com bill', 'youtube premium',
      'amazon prime', 'canal', 'free mobile', 'sfr', 'bouygues telecom', 'orange', 'sosh',
    ]),
    CategorizationRule(TransactionCategory.housing, [
      'loyer', 'rent', 'edf', 'engie', 'syndic', 'veolia', 'eau',
    ]),
    CategorizationRule(TransactionCategory.groceries, [
      'carrefour', 'leclerc', 'auchan', 'lidl', 'aldi', 'monoprix', 'intermarche',
      'franprix', 'super u', 'picard', 'biocoop', 'supermarket', 'tesco', 'rewe',
    ]),
    CategorizationRule(TransactionCategory.health, [
      'pharmacie', 'pharmacy', 'doctolib', 'medecin', 'dentiste', 'hopital', 'kine',
    ]),
    CategorizationRule(TransactionCategory.insurance, [
      'assurance', 'insurance', 'maif', 'macif', 'matmut', 'axa', 'allianz', 'mutuelle',
    ]),
    CategorizationRule(TransactionCategory.travel, [
      'airbnb', 'booking com', 'air france', 'easyjet', 'ryanair', 'transavia', 'hotel',
      'expedia',
    ]),
    CategorizationRule(TransactionCategory.shopping, [
      'amazon', 'fnac', 'zara', 'h m', 'decathlon', 'ikea', 'darty', 'ebay', 'zalando',
      'vinted',
    ]),
    CategorizationRule(TransactionCategory.leisure, [
      'cinema', 'ugc', 'pathe', 'steam', 'playstation', 'basic fit', 'fitness', 'concert',
      'fnac spectacles',
    ]),
    CategorizationRule(TransactionCategory.education, [
      'universite', 'ecole', 'school', 'udemy', 'coursera', 'cned',
    ]),
  ];

  static const Map<String, String> _diacritics = {
    'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a',
    'ç': 'c', 'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', 'ñ': 'n',
    'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o',
    'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ý': 'y', 'ÿ': 'y',
    'œ': 'oe', 'æ': 'ae', 'ß': 'ss',
  };

  static final RegExp _nonAlphanumeric = RegExp('[^a-z0-9]+');

  /// Minuscules, sans accents, ponctuation -> espaces, espaces compactés.
  static String normalize(String input) {
    final buffer = StringBuffer();
    for (final char in input.toLowerCase().split('')) {
      buffer.write(_diacritics[char] ?? char);
    }
    return buffer.toString().replaceAll(_nonAlphanumeric, ' ').trim();
  }

  TransactionCategory categorize({
    required String description,
    required Money amount,
    String? merchant,
  }) {
    if (merchant != null) {
      final override = _overrides[normalize(merchant)];
      if (override != null) {
        return override;
      }
    }
    final haystack = ' ${normalize('${merchant ?? ''} $description')} ';
    for (final rule in _rules) {
      for (final keyword in rule.keywords) {
        if (haystack.contains(' $keyword ')) {
          return rule.category;
        }
      }
    }
    return amount.isPositive ? TransactionCategory.otherIncome : TransactionCategory.other;
  }

  /// Catégorise une transaction sans jamais écraser un choix utilisateur.
  BankTransaction apply(BankTransaction transaction) {
    if (transaction.isUserCategorized) {
      return transaction;
    }
    final category = categorize(
      description: transaction.description,
      merchant: transaction.merchant,
      amount: transaction.amount,
    );
    return transaction.withCategory(category, byUser: false);
  }

  /// Mémorise une correction utilisateur pour les prochaines transactions
  /// du même commerçant.
  TransactionCategorizer withMerchantOverride(String merchant, TransactionCategory category) {
    return TransactionCategorizer(
      rules: _rules,
      merchantOverrides: {..._overrides, normalize(merchant): category},
    );
  }
}
