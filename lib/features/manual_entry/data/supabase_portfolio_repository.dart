import 'package:cairn/core/money/currency.dart';
import 'package:cairn/core/money/money.dart';
import 'package:cairn/features/manual_entry/data/supabase_rows.dart';
import 'package:cairn/features/manual_entry/domain/portfolio_writer.dart';
import 'package:cairn/features/millionaire/domain/millionaire_progress.dart';
import 'package:cairn/features/net_worth/domain/net_worth_calculator.dart';
import 'package:cairn/features/portfolio/domain/portfolio_data.dart';
import 'package:cairn/features/portfolio/domain/portfolio_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Lecture / écriture des données de l'utilisateur connecté.
/// Chaque requête est filtrée côté serveur par les politiques RLS : même un
/// client modifié ne peut lire que ses propres lignes.
final class SupabasePortfolioRepository implements PortfolioRepository, PortfolioWriter {
  SupabasePortfolioRepository(this._client);

  final SupabaseClient _client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw const PortfolioWriteException('Session expirée. Reconnecte-toi.');
    }
    return id;
  }

  @override
  Future<PortfolioData> load({required DateTime asOf}) async {
    final profile = await _loadProfile();
    final reporting = Currency.of(profile['reporting_currency'] as String? ?? 'EUR');
    final targetCurrency = Currency.of(profile['target_currency'] as String? ?? reporting.code);
    final targetMinor = (profile['target_amount_minor'] as num?)?.toInt() ??
        MillionaireCalculator.defaultTargetMajor * 100;

    final assetRows = await _client.from('assets').select().order('created_at');
    final liabilityRows = await _client.from('liabilities').select().order('created_at');
    final snapshotRows = await _client
        .from('net_worth_snapshots')
        .select()
        .gte('snapshot_date', SupabaseRows.isoDate(asOf.subtract(const Duration(days: 800))))
        .order('snapshot_date');

    final assets = assetRows.map(SupabaseRows.assetFromRow).toList();
    final liabilities = liabilityRows.map(SupabaseRows.liabilityFromRow).toList();
    final needsFx = [
      ...assets.map((a) => a.value.currency),
      ...liabilities.map((l) => l.outstanding.currency),
      targetCurrency,
    ].any((c) => c != reporting);

    var fxRows = needsFx ? await _loadFxRows(asOf) : const <Map<String, dynamic>>[];
    if (needsFx && _isStale(fxRows, asOf)) {
      await _refreshFx();
      fxRows = await _loadFxRows(asOf);
    }

    return PortfolioData(
      reportingCurrency: reporting,
      target: Money(targetMinor, targetCurrency),
      assets: assets,
      liabilities: liabilities,
      transactions: const [],
      snapshots: snapshotRows.map(SupabaseRows.snapshotFromRow).toList(),
      fx: SupabaseRows.fxRatesFromRows(fxRows, fallbackDate: asOf),
      lastSyncedAt: asOf,
      isDemo: false,
      displayName: _client.auth.currentUser?.email,
    );
  }

  /// Enregistre (ou met à jour) le point d'historique du jour.
  Future<void> recordSnapshot(NetWorthBreakdown breakdown, DateTime asOf) async {
    await _client.from('net_worth_snapshots').upsert(
          SupabaseRows.snapshotToRow(
            userId: _userId,
            date: asOf,
            gross: breakdown.grossAssets,
            liabilities: breakdown.totalLiabilities,
          ),
          onConflict: 'user_id,snapshot_date',
        );
  }

  @override
  Future<void> saveAsset(AssetDraft draft) => _write(() async {
        final row = SupabaseRows.assetToRow(draft, now: DateTime.now());
        final id = draft.id;
        if (id == null) {
          await _client.from('assets').insert({...row, 'user_id': _userId});
        } else {
          await _client.from('assets').update(row).eq('id', id);
        }
      });

  @override
  Future<void> deleteAsset(String id) =>
      _write(() async => _client.from('assets').delete().eq('id', id));

  @override
  Future<void> saveLiability(LiabilityDraft draft) => _write(() async {
        final row = SupabaseRows.liabilityToRow(draft);
        final id = draft.id;
        if (id == null) {
          await _client.from('liabilities').insert({...row, 'user_id': _userId});
        } else {
          await _client.from('liabilities').update(row).eq('id', id);
        }
      });

  @override
  Future<void> deleteLiability(String id) =>
      _write(() async => _client.from('liabilities').delete().eq('id', id));

  @override
  Future<void> updateReportingCurrency(Currency currency) => _write(() async {
        await _client.from('profiles').update({
          'reporting_currency': currency.code,
          'target_currency': currency.code,
        }).eq('id', _userId);
      });

  Future<Map<String, dynamic>> _loadProfile() async {
    final existing = await _client.from('profiles').select().eq('id', _userId).maybeSingle();
    if (existing != null) {
      return existing;
    }
    // Filet de sécurité si le déclencheur de création n'a pas tourné.
    return _client.from('profiles').upsert({'id': _userId}).select().single();
  }

  Future<List<Map<String, dynamic>>> _loadFxRows(DateTime asOf) => _client
      .from('fx_rates')
      .select('quote, rate, rate_date')
      .eq('base', 'EUR')
      .gte('rate_date', SupabaseRows.isoDate(asOf.subtract(const Duration(days: 14))))
      .order('rate_date', ascending: false);

  /// Taux BCE publiés les jours ouvrés : au-delà de 4 jours, on rafraîchit.
  bool _isStale(List<Map<String, dynamic>> rows, DateTime asOf) {
    if (rows.isEmpty) {
      return true;
    }
    final newest = DateTime.parse(rows.first['rate_date'] as String);
    return asOf.difference(newest).inDays > 4;
  }

  /// Demande à la fonction serveur de récupérer les taux BCE. Silencieux en
  /// cas d'échec : les éléments sans taux seront signalés à l'écran.
  Future<void> _refreshFx() async {
    try {
      await _client.functions.invoke('fx-ecb');
    } on Object {
      // Fonction non déployée ou BCE indisponible.
    }
  }

  Future<void> _write(Future<void> Function() action) async {
    try {
      await action();
    } on PortfolioWriteException {
      rethrow;
    } on PostgrestException {
      throw const PortfolioWriteException("L'enregistrement a été refusé. Vérifie les valeurs saisies.");
    } on Object {
      throw const PortfolioWriteException('Enregistrement impossible. Vérifie ta connexion.');
    }
  }
}
