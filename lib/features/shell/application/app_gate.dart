import 'package:cairn/routing/app_routes.dart';

/// Étape d'accès, calculée à partir du mode, de la session et du verrou.
enum GateStage { ready, signedOut, lockLoading, needsPinSetup, locked }

/// Décide où rediriger. Fonction pure, testée sans interface.
///
/// * Démo : aucun écran d'accès, on les renvoie vers l'accueil.
/// * Réel : connexion → création du code → déverrouillage → application.
/// * Le changement de code (`?change=1`) reste accessible une fois déverrouillé.
String? resolveRedirect({
  required bool demoMode,
  required GateStage stage,
  required Uri location,
}) {
  final path = location.path;
  const gatePaths = {AppRoutes.signIn, AppRoutes.lock, AppRoutes.loading, AppRoutes.pinSetup};
  final isGatePath = gatePaths.contains(path);

  if (demoMode) {
    return isGatePath ? AppRoutes.home : null;
  }

  final target = switch (stage) {
    GateStage.signedOut => AppRoutes.signIn,
    GateStage.lockLoading => AppRoutes.loading,
    GateStage.needsPinSetup => AppRoutes.pinSetup,
    GateStage.locked => AppRoutes.lock,
    GateStage.ready => null,
  };

  if (target != null) {
    return path == target ? null : target;
  }
  final isChangingPin = path == AppRoutes.pinSetup && location.queryParameters['change'] == '1';
  if (isGatePath && !isChangingPin) {
    return AppRoutes.home;
  }
  return null;
}
