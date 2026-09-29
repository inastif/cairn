# 4. Arborescence

Organisation **par fonctionnalité**, chaque fonctionnalité découpée en `domain`
(Dart pur), `data` (sources), `application` (providers) et `presentation` (écrans).

```
lib/
  main.dart                    initialisation (dates fr, ProviderScope)
  app.dart                     MaterialApp.router, thèmes, localisation
  config/app_config.dart       nom, environnement, mode démo (aucun secret)
  core/
    money/                     Currency, Money (entiers), FxRates
    formatting/                formatage montants, %, dates
  theme/                       couleurs, typographie, jetons, ThemeData
  routing/                     routes et GoRouter (5 onglets)
  shared/
    labels/                    libellés français du domaine
    settings/                  confidentialité, thème
    widgets/                   AmountText, Panel, états
  features/
    net_worth/domain/          actifs, dettes, calcul du patrimoine net, snapshots
    millionaire/domain/        % millionnaire et paliers
    transactions/domain/       catégories, catégorisation, flux mensuels
    transactions/presentation/ Activité
    financial_score/           méthode, calcul, feuille de détail
    goals/domain/              projection vers la cible
    portfolio/                 données, repository, vue d'ensemble, providers
    demo/data/                 5 profils de démonstration
    dashboard/presentation/    Accueil et ses sections
    wealth/presentation/       Patrimoine
    investments/presentation/  Investir
    profile/presentation/      Profil
    shell/presentation/        barre de navigation
test/
  core/                        Money, FxRates, formatage
  features/                    calculs du domaine, profils démo
  widget_test.dart             dashboard, confidentialité, navigation
docs/                          ce dossier
assets/fonts/                  Manrope (OFL)
```

Arrivent aux modules suivants : `supabase/` (migrations SQL, Edge Functions),
`features/auth`, `features/onboarding`, `features/banking`, `integration_test/`,
`.github/workflows/`.
