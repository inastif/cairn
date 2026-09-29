// Ce fichier remplace volontairement le test d'exemple que `flutter create`
// génère (il référence une classe MyApp inexistante et casserait la suite).
import 'package:cairn/app.dart';
import 'package:cairn/features/portfolio/application/portfolio_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async => initializeDateFormatting('fr_FR'));

  Widget app() {
    return ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime(2026, 9, 28, 10)),
      ],
      child: const CairnApp(),
    );
  }

  testWidgets('le dashboard affiche le pourcentage millionnaire du profil moyen', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Tu es millionnaire à'), findsOneWidget);
    expect(find.textContaining('7,42'), findsOneWidget);
    expect(find.text('Accueil'), findsOneWidget);
    expect(find.text('Patrimoine'), findsOneWidget);
  });

  testWidgets('le mode confidentialité masque les montants et le pourcentage', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Masquer les montants'));
    await tester.pumpAndSettle();

    expect(find.textContaining('7,42'), findsNothing);
    expect(find.textContaining('•••••'), findsWidgets);
    expect(find.byTooltip('Afficher les montants'), findsOneWidget);
  });

  testWidgets("l'onglet Patrimoine liste les actifs", (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Patrimoine'));
    await tester.pumpAndSettle();

    expect(find.text('Livret A', skipOffstage: false), findsOneWidget);
    expect(find.text('Répartition des actifs', skipOffstage: false), findsOneWidget);
  });
}
