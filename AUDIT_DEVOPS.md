# Audit DevOps — Cairn

Date : 29/09/2026 · Auteur : Inas Tifaoui · Dépôt : `inastif/cairn` (privé)

Légende : ✅ OK · ⚠️ partiel · ❌ absent

## Grille

### Git

| Critère | État | Constat |
|---------|:----:|---------|
| Dépôt GitHub existant et accessible | ✅ | `github.com/inastif/cairn`, privé |
| `.gitignore` adapté à la stack | ✅ | Flutter/Dart, Android, iOS, IDE ; `env/*.json` (secrets Supabase) exclus |
| Historique de commits lisible | ✅ | Dépôt neuf, convention Conventional Commits dès le premier commit |
| Branche `main` protégée (no direct push) | ❌ | Non configuré — sur un dépôt **privé** avec un compte GitHub Free, les règles de protection ne sont pas appliquées (voir priorité 3) |

### Build & Run

| Critère | État | Constat |
|---------|:----:|---------|
| L'app démarre en une seule commande documentée | ✅ | `flutter run -d chrome` (mode démo), documenté dans le README |
| Les dépendances sont listées | ✅ | `pubspec.yaml` (+ `pubspec.lock`) |
| Pas de chemin absolu codé en dur | ✅ | Vérifié : `git grep -n -I -E "[A-Za-z]:\\\\|/Users/|/home/"` ne renvoie rien |

### Tests

| Critère | État | Constat |
|---------|:----:|---------|
| Des tests existent | ✅ | 92 tests (domaine financier, sécurité, auth, saisie) dans `test/` ; `flutter analyze` : 0 problème |
| Les tests s'exécutent en une commande | ✅ | `flutter test` |

### Déploiement

| Critère | État | Constat |
|---------|:----:|---------|
| Méthode de déploiement connue et documentée | ❌ | Seule la commande `flutter build appbundle` existe ; aucune procédure de publication (Play Console, TestFlight, web) ni pipeline CI |
| Environnement de staging distinct de la prod | ⚠️ | `APP_ENV=staging` existe dans le code, mais pas de projet Supabase de staging séparé documenté |

### Monitoring

| Critère | État | Constat |
|---------|:----:|---------|
| L'URL de production est monitorée | ❌ | Aucun monitoring (app non encore publiée, API Supabase non surveillée) |
| Les logs sont accessibles | ⚠️ | Logs backend consultables dans le tableau de bord Supabase ; aucun remontée de crash côté app |

## Bilan

| ✅ OK | ⚠️ Partiel | ❌ Absent |
|:----:|:----:|:----:|
| **8** | **2** | **3** |

## Mes 3 priorités

1. **Documenter et automatiser le déploiement**
   - Ajouter une CI GitHub Actions : `flutter analyze` + `flutter test` + `flutter build appbundle` à chaque push / PR.
   - Rédiger `docs/08_deploiement.md` : distribution de test (Play Console « Test interne » / Firebase App Distribution), signature, versioning.

2. **Mettre en place le monitoring et les logs applicatifs**
   - Intégrer un outil de crash reporting (Sentry ou Firebase Crashlytics), désactivé en mode démo.
   - Surveiller la disponibilité de l'API Supabase de prod (UptimeRobot ou équivalent).
   - Créer un projet Supabase **staging** séparé de la prod (`env/staging.example.json`).

3. **Protéger la branche `main`**
   - Option A : passer à GitHub Pro (gratuit via le GitHub Student Developer Pack) pour garder le dépôt privé.
   - Option B : rendre le dépôt public (aucun secret n'y est versionné).
   - Puis : *Settings → Rules → Rulesets* → cible `main`, exiger une Pull Request et le passage de la CI, bloquer le force push.
