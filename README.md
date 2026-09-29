# Cairn (nom de travail)

Application Flutter iOS / Android qui affiche **à quel pourcentage tu es millionnaire**,
à partir de ton patrimoine net (actifs − dettes), en multidevise.

Modules livrés :
1. domaine financier testé, design system, écrans, 5 profils de démonstration ;
2. base de données Supabase, connexion par code e-mail, verrouillage par code et
   biométrie, saisie manuelle des actifs et dettes, historique, suppression du compte.

Deux modes :
- **démonstration** (par défaut) : `flutter run -d chrome` ;
- **réel** : `flutter run -d chrome --dart-define-from-file=env/dev.json`, après
  avoir suivi `docs/07_supabase.md`.

## Démarrer sous Windows

1. Installer Flutter (canal stable, 3.44 ou plus récent ; testé contre 3.47) en suivant
   la documentation officielle pour Windows, puis Android Studio (SDK Android + un
   émulateur).
2. Vérifier l'installation :
   ```
   flutter doctor
   ```
3. Dans le dossier décompressé, générer les dossiers natifs Android et iOS
   (les fichiers existants ne sont pas écrasés) :
   ```
   flutter create --org com.tonnom --project-name cairn --platforms android,ios .
   ```
   Remplace `com.tonnom` par un identifiant inversé qui t'appartient : il devient
   l'identifiant de l'app sur les stores et ne se change plus ensuite.
4. Installer les dépendances, analyser, tester :
   ```
   flutter pub get
   flutter analyze
   flutter test
   ```
5. Lancer sur l'émulateur Android ou un téléphone branché :
   ```
   flutter run
   ```

iOS : le code est commun, mais compiler, signer et publier pour iOS exige un Mac
(ou un service de build macOS dans le cloud). Voir `docs/01_produit.md`.

## Environnements

```
flutter run --dart-define=APP_ENV=development
flutter run --dart-define=APP_ENV=staging
flutter build appbundle --dart-define=APP_ENV=production
```

Aucun secret n'est présent dans l'application ni dans ce dépôt.

## Utiliser la démo

Onglet **Profil** → « Profil de démonstration » : patrimoine faible, moyen (74 200 €,
soit 7,42 %), investisseur (dollars et livres), immobilier, dettes importantes.
L'icône en forme d'œil sur l'Accueil masque tous les montants.

## Documentation

| Fichier | Contenu |
|---------|---------|
| `docs/01_produit.md` | Noms, positionnement, cible, MVP / V2 / V3, risques, contraintes |
| `docs/02_architecture.md` | Architecture, backend, Open Banking, sécurité, schéma de base |
| `docs/03_ux_ui.md` | Design system, écrans, accessibilité |
| `docs/04_arborescence.md` | Organisation du code |
| `docs/05_choix_techniques.md` | Riverpod, go_router, dépendances, argent, qualité |
| `docs/06_feuille_de_route.md` | Modules suivants |
| `docs/07_supabase.md` | Brancher la base de données, pas à pas |

## Licences

Police Manrope : SIL Open Font License 1.1 (`assets/fonts/OFL-Manrope.txt`).
