import 'package:cairn/core/money/money.dart';
import 'package:meta/meta.dart';

/// Grandes classes d'actifs. L'ordre sert à l'affichage de l'allocation.
enum AssetClass { cash, investments, crypto, realEstate, other }

/// Provenance d'une donnée, affichée pour la transparence.
enum DataSource { bankSync, manual, marketData, demo }

@immutable
final class AssetItem {
  const AssetItem({
    required this.id,
    required this.name,
    required this.assetClass,
    required this.value,
    required this.source,
    this.institutionName,
    this.subtype,
    this.valuedAt,
  });

  final String id;
  final String name;
  final AssetClass assetClass;

  /// Valeur dans la devise d'origine du compte ou du bien. Un solde de
  /// compte courant négatif (découvert) est traité comme une dette.
  final Money value;
  final DataSource source;
  final String? institutionName;

  /// Précision libre : « Livret A », « PEA », « Résidence principale »…
  final String? subtype;

  /// Date de la valeur (solde bancaire, cotation, estimation immobilière).
  final DateTime? valuedAt;
}
