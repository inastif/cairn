import 'dart:math' as math;

import 'package:cairn/core/money/currency.dart';
import 'package:cairn/core/money/fx_rates.dart';
import 'package:cairn/core/money/money.dart';
import 'package:cairn/features/millionaire/domain/millionaire_progress.dart';
import 'package:cairn/features/net_worth/domain/asset_item.dart';
import 'package:cairn/features/net_worth/domain/liability_item.dart';
import 'package:cairn/features/net_worth/domain/net_worth_calculator.dart';
import 'package:cairn/features/net_worth/domain/net_worth_snapshot.dart';
import 'package:cairn/features/portfolio/domain/portfolio_data.dart';
import 'package:cairn/features/transactions/domain/bank_transaction.dart';
import 'package:cairn/features/transactions/domain/transaction_categorizer.dart';
import 'package:cairn/features/transactions/domain/transaction_category.dart';

/// Profils fictifs servant à tester les calculs et l'interface sans aucune
/// donnée bancaire réelle. Les établissements sont volontairement fictifs.
enum DemoProfileId {
  lowWealth('Patrimoine faible', 'Premier emploi, petit livret, prêt étudiant.'),
  midWealth('Patrimoine moyen', 'Salarié épargnant, livrets, PEA et assurance-vie.'),
  investor('Investisseur', 'PEA, compte-titres en dollars, crypto, sans dette.'),
  realEstate('Patrimoine immobilier', 'Résidence principale et investissement locatif.'),
  highDebt('Dettes importantes', 'Crédits à la consommation et compte à découvert.');

  const DemoProfileId(this.label, this.description);

  final String label;
  final String description;
}

/// Taux de DÉMONSTRATION (base EUR), pas des cotations réelles. La source
/// réelle prévue est le jeu de taux de référence quotidien de la BCE.
FxRates demoFxRates(DateTime asOf) => FxRates(
      base: Currency.eur,
      rates: const {'USD': 1.10, 'GBP': 0.85, 'CHF': 0.95, 'JPY': 160, 'CAD': 1.50},
      asOf: DateTime(asOf.year, asOf.month, asOf.day),
      source: 'démo',
    );

abstract final class DemoProfiles {
  static const String checkingAccountId = 'demo-checking';

  static PortfolioData build(
    DemoProfileId id, {
    required DateTime asOf,
    TransactionCategorizer? categorizer,
  }) {
    final spec = _specs[id]!;
    final fx = demoFxRates(asOf);
    final eur = Currency.eur;
    final effectiveCategorizer = categorizer ?? TransactionCategorizer();

    final transactions = _generateTransactions(id, spec, asOf, effectiveCategorizer);
    final breakdown = const NetWorthCalculator().compute(
      assets: spec.assets,
      liabilities: spec.liabilities,
      reportingCurrency: eur,
      fx: fx,
    );

    return PortfolioData(
      reportingCurrency: eur,
      target: Money.fromMajor(MillionaireCalculator.defaultTargetMajor, eur),
      assets: spec.assets,
      liabilities: spec.liabilities,
      transactions: transactions,
      snapshots: _generateSnapshots(spec, breakdown, asOf),
      fx: fx,
      lastSyncedAt: asOf.subtract(const Duration(minutes: 18)),
      isDemo: true,
      displayName: id.label,
    );
  }

  static List<BankTransaction> _generateTransactions(
    DemoProfileId id,
    _ProfileSpec spec,
    DateTime asOf,
    TransactionCategorizer categorizer,
  ) {
    final random = _ParkMiller(id.index + 7);
    final result = <BankTransaction>[];
    for (var offset = 11; offset >= 0; offset--) {
      final month = DateTime(asOf.year, asOf.month - offset);
      final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
      for (var index = 0; index < spec.recurring.length; index++) {
        final item = spec.recurring[index];
        for (var occurrence = 0; occurrence < item.timesPerMonth; occurrence++) {
          final day = math.min(item.day + occurrence * 7, daysInMonth);
          final date = DateTime(month.year, month.month, day, 10);
          if (date.isAfter(asOf)) {
            continue;
          }
          final amount = item.amount * (1 + item.variation * random.nextSigned());
          final raw = BankTransaction(
            id: 'demo-${id.name}-${month.year}-${month.month}-$index-$occurrence',
            accountId: checkingAccountId,
            bookedAt: date,
            amount: Money.fromMajor(amount, Currency.eur),
            description: item.description,
            category: TransactionCategory.other,
          );
          result.add(categorizer.apply(raw));
        }
      }
    }
    result.sort((a, b) => b.bookedAt.compareTo(a.bookedAt));
    return List<BankTransaction>.unmodifiable(result);
  }

  /// Historique de fin de mois reconstitué de façon déterministe.
  static List<NetWorthSnapshot> _generateSnapshots(
    _ProfileSpec spec,
    NetWorthBreakdown now,
    DateTime asOf,
  ) {
    final snapshots = <NetWorthSnapshot>[];
    for (var k = 1; k <= 24; k++) {
      final date = DateTime(asOf.year, asOf.month - k + 1, 0, 23, 59);
      final net = now.netWorth.major - k * spec.monthlyGrowth + spec.wiggle * math.sin(k * 1.3);
      final liabilities = now.totalLiabilities.major + k * spec.monthlyDebtRepayment;
      snapshots.add(
        NetWorthSnapshot(
          date: date,
          grossAssets: Money.fromMajor(math.max(0, net + liabilities), Currency.eur),
          liabilities: Money.fromMajor(liabilities, Currency.eur),
        ),
      );
    }
    snapshots.sort((a, b) => a.date.compareTo(b.date));
    return List<NetWorthSnapshot>.unmodifiable(snapshots);
  }

  static Money _eur(num amount) => Money.fromMajor(amount, Currency.eur);

  static AssetItem _asset(
    String id,
    String name,
    AssetClass assetClass,
    Money value, {
    String? subtype,
    String institution = 'Banque Démo',
  }) =>
      AssetItem(
        id: id,
        name: name,
        assetClass: assetClass,
        value: value,
        source: DataSource.demo,
        subtype: subtype,
        institutionName: institution,
      );

  static LiabilityItem _debt(
    String id,
    String name,
    LiabilityType type,
    num amount, {
    String? securedAssetId,
  }) =>
      LiabilityItem(
        id: id,
        name: name,
        type: type,
        outstanding: _eur(amount),
        source: DataSource.demo,
        institutionName: 'Banque Démo',
        securedAssetId: securedAssetId,
      );

  static final Map<DemoProfileId, _ProfileSpec> _specs = {
    DemoProfileId.lowWealth: _ProfileSpec(
      assets: [
        _asset('low-checking', 'Compte courant', AssetClass.cash, _eur(1850)),
        _asset('low-livret-a', 'Livret A', AssetClass.cash, _eur(4200), subtype: 'Livret A'),
      ],
      liabilities: [_debt('low-student', 'Prêt étudiant', LiabilityType.studentLoan, 3500)],
      recurring: const [
        _Recurring(1, 'VIR SALAIRE STARTUP SAS', 1650, variation: 0.01),
        _Recurring(5, 'PRLV LOYER STUDIO', -620),
        _Recurring(8, 'PRLV EDF', -38, variation: 0.1),
        _Recurring(9, 'PRLV FREE MOBILE', -15.99),
        _Recurring(12, 'CB NETFLIX.COM', -8.99),
        _Recurring(3, 'CB LIDL', -55, variation: 0.3, timesPerMonth: 4),
        _Recurring(6, 'CB UBER EATS', -22, variation: 0.4, timesPerMonth: 2),
        _Recurring(14, 'CB SNCF', -45, variation: 0.5),
        _Recurring(15, 'PRLV ECHEANCE PRET ETUDIANT', -120),
        _Recurring(18, 'CB ZALANDO', -150, variation: 0.6),
        _Recurring(20, 'CB CINEMA UGC', -30, variation: 0.5, timesPerMonth: 2),
        _Recurring(2, 'VIR INTERNE VERS LIVRET A', -100),
      ],
      monthlyGrowth: 250,
      monthlyDebtRepayment: 110,
      wiggle: 150,
    ),
    DemoProfileId.midWealth: _ProfileSpec(
      assets: [
        _asset('mid-checking', 'Compte courant', AssetClass.cash, _eur(3400)),
        _asset('mid-ldds', 'LDDS', AssetClass.cash, _eur(12000), subtype: 'LDDS'),
        _asset('mid-livret-a', 'Livret A', AssetClass.cash, _eur(22950), subtype: 'Livret A'),
        _asset('mid-av', 'Assurance-vie', AssetClass.investments, _eur(28000),
            subtype: 'Assurance-vie', institution: 'Assureur Démo'),
        _asset('mid-pea', 'PEA', AssetClass.investments, _eur(15500),
            subtype: 'PEA', institution: 'Courtier Démo'),
      ],
      liabilities: [_debt('mid-car', 'Crédit auto', LiabilityType.autoLoan, 7650)],
      recurring: const [
        _Recurring(1, 'VIR SALAIRE ACME SAS', 3100, variation: 0.01),
        _Recurring(4, 'PRLV LOYER AGENCE CENTRALE', -950),
        _Recurring(8, 'PRLV EDF', -65, variation: 0.15),
        _Recurring(9, 'PRLV SFR BOX', -39.99),
        _Recurring(11, 'CB SPOTIFY', -11.99),
        _Recurring(2, 'CB CARREFOUR MARKET', -90, variation: 0.25, timesPerMonth: 4),
        _Recurring(5, 'CB BRASSERIE DU PORT', -35, variation: 0.4, timesPerMonth: 3),
        _Recurring(3, 'PRLV NAVIGO', -86.40),
        _Recurring(10, 'PRLV ECHEANCE CREDIT AUTO', -280),
        _Recurring(12, 'PRLV MAIF', -62),
        _Recurring(16, 'CB AMAZON', -120, variation: 0.6),
        _Recurring(19, 'CB CINEMA UGC', -25, variation: 0.3),
        _Recurring(6, 'VERSEMENT PEA', -300),
        _Recurring(6, 'VIR INTERNE VERS LDDS', -200),
      ],
      monthlyGrowth: 1300,
      monthlyDebtRepayment: 240,
      wiggle: 900,
    ),
    DemoProfileId.investor: _ProfileSpec(
      assets: [
        _asset('inv-checking', 'Compte courant', AssetClass.cash, _eur(5200)),
        _asset('inv-gbp', 'Compte en livres', AssetClass.cash, Money.fromMajor(3400, Currency.gbp)),
        _asset('inv-pea', 'PEA', AssetClass.investments, _eur(142000),
            subtype: 'PEA', institution: 'Courtier Démo'),
        _asset('inv-cto', 'Compte-titres US', AssetClass.investments,
            Money.fromMajor(85000, Currency.usd), subtype: 'CTO', institution: 'Courtier Démo'),
        _asset('inv-av', 'Assurance-vie', AssetClass.investments, _eur(60000),
            subtype: 'Assurance-vie', institution: 'Assureur Démo'),
        _asset('inv-btc', 'Bitcoin', AssetClass.crypto, _eur(38000),
            subtype: 'BTC', institution: 'Plateforme Démo'),
        _asset('inv-eth', 'Ethereum', AssetClass.crypto, _eur(9500),
            subtype: 'ETH', institution: 'Plateforme Démo'),
      ],
      liabilities: const [],
      recurring: const [
        _Recurring(1, 'VIR SALAIRE NORTHWIND SA', 5800, variation: 0.02),
        _Recurring(4, 'PRLV LOYER RESIDENCE', -1400),
        _Recurring(8, 'PRLV ENGIE', -80, variation: 0.2),
        _Recurring(9, 'PRLV BOUYGUES TELECOM', -45),
        _Recurring(2, 'CB MONOPRIX', -120, variation: 0.25, timesPerMonth: 4),
        _Recurring(5, 'CB RESTAURANT LE COMPTOIR', -45, variation: 0.5, timesPerMonth: 4),
        _Recurring(7, 'CB UBER', -18, variation: 0.5, timesPerMonth: 3),
        _Recurring(12, 'PRLV AXA', -70),
        _Recurring(20, 'CB AIRBNB', -260, variation: 0.8),
        _Recurring(6, 'VERSEMENT PEA', -1000),
        _Recurring(6, 'DEGIRO', -500),
        _Recurring(6, 'COINBASE', -300),
      ],
      monthlyGrowth: 4500,
      monthlyDebtRepayment: 0,
      wiggle: 6000,
    ),
    DemoProfileId.realEstate: _ProfileSpec(
      assets: [
        _asset('re-checking', 'Compte joint', AssetClass.cash, _eur(6100)),
        _asset('re-livret-a', 'Livret A', AssetClass.cash, _eur(22950), subtype: 'Livret A'),
        _asset('re-home', 'Résidence principale', AssetClass.realEstate, _eur(420000),
            subtype: 'Résidence principale', institution: 'Estimation manuelle'),
        _asset('re-rental', 'Appartement locatif', AssetClass.realEstate, _eur(185000),
            subtype: 'Investissement locatif', institution: 'Estimation manuelle'),
        _asset('re-av', 'Assurance-vie', AssetClass.investments, _eur(45000),
            subtype: 'Assurance-vie', institution: 'Assureur Démo'),
      ],
      liabilities: [
        _debt('re-home-loan', 'Crédit résidence principale', LiabilityType.mortgage, 265000,
            securedAssetId: 're-home'),
        _debt('re-rental-loan', 'Crédit locatif', LiabilityType.mortgage, 142000,
            securedAssetId: 're-rental'),
      ],
      recurring: const [
        _Recurring(1, 'VIR SALAIRE CONTOSO', 4200, variation: 0.01),
        _Recurring(1, 'VIR SALAIRE FABRIKAM', 3000, variation: 0.01),
        _Recurring(5, 'VIR LOYER PERCU LOCATAIRE', 850),
        _Recurring(5, 'PRLV ECHEANCE PRET IMMO RP', -1450),
        _Recurring(5, 'PRLV ECHEANCE PRET IMMO LOCATIF', -780),
        _Recurring(8, 'PRLV EDF', -140, variation: 0.2),
        _Recurring(9, 'PRLV ORANGE', -55),
        _Recurring(2, 'CB E.LECLERC', -160, variation: 0.2, timesPerMonth: 4),
        _Recurring(6, 'CB PIZZERIA NAPOLI', -60, variation: 0.4, timesPerMonth: 2),
        _Recurring(10, 'CB TOTALENERGIES', -75, variation: 0.3, timesPerMonth: 2),
        _Recurring(12, 'PRLV MACIF', -120),
        _Recurring(15, 'PRLV DGFIP IMPOT', -420),
        _Recurring(17, 'CB IKEA', -140, variation: 0.7),
        _Recurring(21, 'CB PHARMACIE DU CENTRE', -28, variation: 0.5),
        _Recurring(6, 'VERSEMENT ASSURANCE VIE', -400),
      ],
      monthlyGrowth: 2800,
      monthlyDebtRepayment: 1300,
      wiggle: 2500,
    ),
    DemoProfileId.highDebt: _ProfileSpec(
      assets: [
        _asset('debt-checking', 'Compte courant', AssetClass.cash, _eur(-320)),
        _asset('debt-livret', 'Livret bancaire', AssetClass.cash, _eur(600), subtype: 'Livret'),
      ],
      liabilities: [
        _debt('debt-personal', 'Prêt personnel', LiabilityType.personalLoan, 18500),
        _debt('debt-car', 'Crédit auto', LiabilityType.autoLoan, 14200),
        _debt('debt-card', 'Crédit renouvelable', LiabilityType.creditCard, 3100),
      ],
      recurring: const [
        _Recurring(1, 'VIR SALAIRE LOGISTIQUE OUEST', 2400, variation: 0.02),
        _Recurring(4, 'PRLV LOYER T2', -780),
        _Recurring(7, 'PRLV ECHEANCE PRET PERSO', -420),
        _Recurring(7, 'PRLV ECHEANCE CREDIT AUTO', -310),
        _Recurring(8, 'PRLV ENGIE', -60, variation: 0.2),
        _Recurring(9, 'PRLV FREE MOBILE', -19.99),
        _Recurring(10, 'CB NETFLIX.COM', -13.49),
        _Recurring(3, 'CB AUCHAN', -85, variation: 0.3, timesPerMonth: 4),
        _Recurring(5, 'CB DELIVEROO', -28, variation: 0.4, timesPerMonth: 4),
        _Recurring(11, 'CB SHELL', -65, variation: 0.3, timesPerMonth: 2),
        _Recurring(14, 'CB AMAZON', -110, variation: 0.6),
        _Recurring(22, 'CB STEAM', -35, variation: 0.8),
      ],
      monthlyGrowth: -40,
      monthlyDebtRepayment: 520,
      wiggle: 200,
    ),
  };
}

final class _ProfileSpec {
  const _ProfileSpec({
    required this.assets,
    required this.liabilities,
    required this.recurring,
    required this.monthlyGrowth,
    required this.monthlyDebtRepayment,
    required this.wiggle,
  });

  final List<AssetItem> assets;
  final List<LiabilityItem> liabilities;
  final List<_Recurring> recurring;
  final double monthlyGrowth;
  final double monthlyDebtRepayment;
  final double wiggle;
}

final class _Recurring {
  const _Recurring(
    this.day,
    this.description,
    this.amount, {
    this.variation = 0,
    this.timesPerMonth = 1,
  });

  final int day;
  final String description;
  final double amount;
  final double variation;
  final int timesPerMonth;
}

/// Générateur pseudo-aléatoire de Park-Miller : déterministe et sûr sur le
/// web (produits < 2^53).
final class _ParkMiller {
  _ParkMiller(int seed) : _state = seed <= 0 ? 1 : seed;

  int _state;

  double nextSigned() {
    _state = (_state * 16807) % 2147483647;
    return _state / 2147483647 * 2 - 1;
  }
}
