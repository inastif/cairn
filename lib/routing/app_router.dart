import 'package:cairn/core/backend/backend_providers.dart';
import 'package:cairn/features/auth/application/auth_providers.dart';
import 'package:cairn/features/auth/presentation/sign_in_screen.dart';
import 'package:cairn/features/dashboard/presentation/dashboard_screen.dart';
import 'package:cairn/features/investments/presentation/investments_screen.dart';
import 'package:cairn/features/manual_entry/presentation/asset_form_screen.dart';
import 'package:cairn/features/manual_entry/presentation/liability_form_screen.dart';
import 'package:cairn/features/profile/presentation/profile_screen.dart';
import 'package:cairn/features/security/application/app_lock_controller.dart';
import 'package:cairn/features/security/presentation/lock_screen.dart';
import 'package:cairn/features/security/presentation/pin_setup_screen.dart';
import 'package:cairn/features/shell/application/app_gate.dart';
import 'package:cairn/features/shell/presentation/app_shell.dart';
import 'package:cairn/features/transactions/presentation/activity_screen.dart';
import 'package:cairn/features/wealth/presentation/wealth_screen.dart';
import 'package:cairn/routing/app_routes.dart';
import 'package:cairn/shared/widgets/state_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final demoMode = ref.watch(isDemoModeProvider);
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);

  if (!demoMode) {
    // Réévalue les redirections à chaque changement de session ou de verrou.
    ref
      ..listen(authSessionProvider, (_, _) => refresh.value++)
      ..listen(appLockProvider, (_, _) => refresh.value++);
  }

  GateStage stage() {
    if (!ref.read(authSessionProvider)) {
      return GateStage.signedOut;
    }
    final lock = ref.read(appLockProvider);
    if (lock.hasError) {
      return GateStage.needsPinSetup;
    }
    final value = lock.value;
    if (value == null) {
      return GateStage.lockLoading;
    }
    if (!value.pinConfigured) {
      return GateStage.needsPinSetup;
    }
    return value.locked ? GateStage.locked : GateStage.ready;
  }

  final router = GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: refresh,
    redirect: (context, state) => resolveRedirect(
      demoMode: demoMode,
      stage: demoMode ? GateStage.ready : stage(),
      location: state.uri,
    ),
    routes: [
      GoRoute(path: AppRoutes.signIn, builder: (context, state) => const SignInScreen()),
      GoRoute(path: AppRoutes.lock, builder: (context, state) => const LockScreen()),
      GoRoute(
        path: AppRoutes.loading,
        builder: (context, state) => const Scaffold(body: LoadingView(message: 'Sécurisation')),
      ),
      GoRoute(
        path: AppRoutes.pinSetup,
        builder: (context, state) =>
            PinSetupScreen(isChange: state.uri.queryParameters['change'] == '1'),
      ),
      GoRoute(path: AppRoutes.newAsset, builder: (context, state) => const AssetFormScreen()),
      GoRoute(
        path: '/assets/:id',
        builder: (context, state) => AssetFormScreen(assetId: state.pathParameters['id']),
      ),
      GoRoute(path: AppRoutes.newLiability, builder: (context, state) => const LiabilityFormScreen()),
      GoRoute(
        path: '/liabilities/:id',
        builder: (context, state) => LiabilityFormScreen(liabilityId: state.pathParameters['id']),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.home, builder: (context, state) => const DashboardScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.wealth, builder: (context, state) => const WealthScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.activity, builder: (context, state) => const ActivityScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: AppRoutes.investments, builder: (context, state) => const InvestmentsScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.profile, builder: (context, state) => const ProfileScreen())],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
