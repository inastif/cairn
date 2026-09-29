import 'package:cairn/core/money/money.dart';
import 'package:cairn/features/net_worth/domain/asset_item.dart';
import 'package:meta/meta.dart';

enum LiabilityType {
  mortgage,
  autoLoan,
  personalLoan,
  studentLoan,
  creditCard,

  /// Découvert, généré automatiquement depuis un solde courant négatif.
  overdraft,
  other,
}

@immutable
final class LiabilityItem {
  const LiabilityItem({
    required this.id,
    required this.name,
    required this.type,
    required this.outstanding,
    required this.source,
    this.institutionName,
    this.securedAssetId,
  });

  final String id;
  final String name;
  final LiabilityType type;

  /// Capital restant dû, toujours positif ou nul.
  final Money outstanding;
  final DataSource source;
  final String? institutionName;

  /// Actif financé par ce prêt (ex. crédit immobilier -> appartement).
  final String? securedAssetId;
}
