import 'dart:async';

import 'package:cairn/config/app_config.dart';
import 'package:cairn/core/backend/backend_providers.dart';
import 'package:cairn/core/clock/clock_provider.dart';
import 'package:cairn/features/auth/application/auth_providers.dart';
import 'package:cairn/features/demo/data/demo_portfolio_repository.dart';
import 'package:cairn/features/demo/data/demo_profiles.dart';
import 'package:cairn/features/manual_entry/data/supabase_portfolio_repository.dart';
import 'package:cairn/features/manual_entry/domain/portfolio_writer.dart';
import 'package:cairn/features/portfolio/domain/financial_overview.dart';
import 'package:cairn/features/portfolio/domain/portfolio_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:cairn/core/clock/clock_provider.dart';

final class DemoProfileNotifier extends Notifier<DemoProfileId> {
  @override
  DemoProfileId build() => DemoProfileId.midWealth;

  void select(DemoProfileId id) => state = id;
}

final demoProfileProvider =
    NotifierProvider<DemoProfileNotifier, DemoProfileId>(DemoProfileNotifier.new);

/// Repository Supabase de l'utilisateur connecté, `null` en démo.
/// Recréé à chaque changement de session.
final supabasePortfolioRepositoryProvider = Provider<SupabasePortfolioRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final signedIn = ref.watch(authSessionProvider);
  return client == null || !signedIn ? null : SupabasePortfolioRepository(client);
});

/// Point d'injection unique de la source de données.
final portfolioRepositoryProvider = Provider<PortfolioRepository>((ref) {
  return ref.watch(supabasePortfolioRepositoryProvider) ??
      DemoPortfolioRepository(ref.watch(demoProfileProvider));
});

/// Écriture des saisies manuelles, `null` en démo (lecture seule).
final portfolioWriterProvider =
    Provider<PortfolioWriter?>((ref) => ref.watch(supabasePortfolioRepositoryProvider));

final financialOverviewProvider = FutureProvider<FinancialOverview>((ref) async {
  final repository = ref.watch(portfolioRepositoryProvider);
  final now = ref.watch(clockProvider)();
  final data = await repository.load(asOf: now);
  final overview = const FinancialOverviewBuilder().build(
    data,
    asOf: now,
    annualReturnAssumption: AppConfig.defaultAnnualReturnAssumption,
  );
  if (repository is SupabasePortfolioRepository &&
      (data.assets.isNotEmpty || data.liabilities.isNotEmpty)) {
    // L'historique se construit à chaque ouverture ; un échec n'empêche pas
    // l'affichage.
    unawaited(
      repository.recordSnapshot(overview.breakdown, now).catchError((Object error) {
        debugPrint('Snapshot non enregistré : $error');
      }),
    );
  }
  return overview;
});
