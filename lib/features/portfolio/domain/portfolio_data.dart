import 'package:cairn/core/money/currency.dart';
import 'package:cairn/core/money/fx_rates.dart';
import 'package:cairn/core/money/money.dart';
import 'package:cairn/features/net_worth/domain/asset_item.dart';
import 'package:cairn/features/net_worth/domain/liability_item.dart';
import 'package:cairn/features/net_worth/domain/net_worth_snapshot.dart';
import 'package:cairn/features/transactions/domain/bank_transaction.dart';
import 'package:meta/meta.dart';

/// Données brutes d'un utilisateur, telles que fournies par un repository
/// (démo aujourd'hui, backend synchronisé demain).
@immutable
final class PortfolioData {
  const PortfolioData({
    required this.reportingCurrency,
    required this.target,
    required this.assets,
    required this.liabilities,
    required this.transactions,
    required this.snapshots,
    required this.fx,
    required this.lastSyncedAt,
    required this.isDemo,
    this.displayName,
  });

  final Currency reportingCurrency;

  /// Cible de progression, 1 000 000 dans la devise de reporting par défaut.
  final Money target;
  final List<AssetItem> assets;
  final List<LiabilityItem> liabilities;
  final List<BankTransaction> transactions;
  final List<NetWorthSnapshot> snapshots;
  final FxRates fx;
  final DateTime? lastSyncedAt;
  final bool isDemo;
  final String? displayName;
}
