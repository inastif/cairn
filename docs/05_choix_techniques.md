# 5. Choix techniques

Versions vérifiées sur les dépôts officiels le 28/09/2026 : Flutter stable 3.47.5,
Dart 3.13.

## Gestion d'état : Riverpod 3 plutôt que Bloc

| | Riverpod | Bloc |
|---|----------|------|
| Code répétitif | Faible | Événements + états par écran |
| Données asynchrones | `FutureProvider` / `AsyncValue` natifs | À modéliser |
| Injection et tests | Overrides intégrés (ex. horloge figée) | Via un conteneur séparé |
| Adapté ici | Beaucoup de données dérivées d'une même source | Flux d'événements complexes |

Utilisé **sans génération de code** (pas de build_runner) : `Notifier`,
`NotifierProvider`, `FutureProvider`.

## Navigation : go_router 17.x

`StatefulShellRoute` conserve l'état des 5 onglets et facilitera les redirections
d'authentification. La 18.0 migre vers le paquet séparé `material_ui` ; tant que Flutter
expose encore `package:flutter/material.dart`, la contrainte reste `<18.0.0` pour éviter
de mélanger les deux. À réévaluer lors de la migration officielle de Flutter.

## Autres dépendances (volontairement peu nombreuses)

- `fl_chart` 1.2 : courbes, maintenu, sans dépendance native.
- `intl` : formats monétaires et dates localisés.
- `flutter_localizations` : textes Material en français.
- `meta` : annotations `@immutable` dans le domaine pur Dart.

Prévues plus tard : `supabase_flutter`, `flutter_secure_storage`, `local_auth`,
`drift` + `sqlcipher_flutter_libs` (cache hors ligne chiffré).

## Argent

Montants en **entiers d'unités mineures** avec leur devise ; addition de devises
différentes interdite par construction ; conversion uniquement via `FxRates`, qui
retourne `null` si un taux manque. Les pourcentages millionnaires sont **tronqués**
(jamais arrondis vers le haut).

## Internationalisation

Textes aujourd'hui en français, centralisés (`DomainLabels`, écrans). Passage aux
fichiers ARB (`gen-l10n`) au module i18n, avant l'ouverture hors francophonie.

## Qualité

`flutter_lints` + analyse stricte (`strict-casts`, `strict-inference`,
`strict-raw-types`). Tests unitaires sur tout le domaine, tests de widget sur le
dashboard. Tests d'intégration et CI GitHub Actions au module 7.
