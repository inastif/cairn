import 'package:cairn/core/money/money.dart';
import 'package:meta/meta.dart';

/// Photographie datée du patrimoine, base de l'historique.
@immutable
final class NetWorthSnapshot {
  NetWorthSnapshot({
    required this.date,
    required this.grossAssets,
    required this.liabilities,
  }) {
    if (grossAssets.currency != liabilities.currency) {
      throw ArgumentError('Snapshot : devises incohérentes');
    }
  }

  final DateTime date;
  final Money grossAssets;
  final Money liabilities;

  Money get netWorth => grossAssets - liabilities;
}
