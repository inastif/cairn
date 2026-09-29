import 'package:cairn/features/shell/application/app_gate.dart';
import 'package:cairn/routing/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String? go(GateStage stage, String location, {bool demo = false}) =>
      resolveRedirect(demoMode: demo, stage: stage, location: Uri.parse(location));

  test('mode démo : jamais d’écran de connexion', () {
    expect(go(GateStage.signedOut, AppRoutes.home, demo: true), isNull);
    expect(go(GateStage.signedOut, AppRoutes.signIn, demo: true), AppRoutes.home);
    expect(go(GateStage.locked, AppRoutes.lock, demo: true), AppRoutes.home);
  });

  test('parcours : connexion, création du code, déverrouillage', () {
    expect(go(GateStage.signedOut, AppRoutes.wealth), AppRoutes.signIn);
    expect(go(GateStage.signedOut, AppRoutes.signIn), isNull);
    expect(go(GateStage.lockLoading, AppRoutes.home), AppRoutes.loading);
    expect(go(GateStage.needsPinSetup, AppRoutes.home), AppRoutes.pinSetup);
    expect(go(GateStage.needsPinSetup, AppRoutes.pinSetup), isNull);
    expect(go(GateStage.locked, AppRoutes.profile), AppRoutes.lock);
    expect(go(GateStage.locked, AppRoutes.lock), isNull);
  });

  test('une fois prêt, les écrans d’accès renvoient à l’accueil', () {
    expect(go(GateStage.ready, AppRoutes.signIn), AppRoutes.home);
    expect(go(GateStage.ready, AppRoutes.lock), AppRoutes.home);
    expect(go(GateStage.ready, AppRoutes.pinSetup), AppRoutes.home);
    expect(go(GateStage.ready, AppRoutes.wealth), isNull);
    expect(go(GateStage.ready, AppRoutes.newAsset), isNull);
  });

  test('le changement de code reste accessible une fois déverrouillé', () {
    expect(go(GateStage.ready, AppRoutes.changePin), isNull);
    expect(go(GateStage.locked, AppRoutes.changePin), AppRoutes.lock);
  });
}
