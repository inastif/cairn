# 1. Produit

## Proposition de valeur

Une application qui répond à une seule question, clairement et honnêtement :
**« À combien de pourcent suis-je millionnaire ? »**

Tout le reste (comptes, dépenses, épargne, investissements, score, projection) sert
à expliquer ce chiffre et à le faire progresser.

Formule : `% millionnaire = patrimoine net / 1 000 000 × 100`, patrimoine net = actifs − dettes.
La valeur n'est pas bornée : −3,58 % (patrimoine négatif) et 127 % (au-delà du million)
sont affichés tels quels. Seules les jauges visuelles sont bornées.

## Décision multidevise

L'application vise le monde entier dès le départ. Règles retenues :

- chaque utilisateur choisit une **devise de reporting** (EUR par défaut) ;
- la cible est **1 000 000 dans une devise choisie** (par défaut la devise de reporting).
  Elle peut être exprimée dans une autre devise (ex. 1 M USD suivi en EUR) : elle est alors
  convertie au taux du jour ;
- chaque compte, bien ou position garde sa devise d'origine ; tout est converti via des
  taux datés et sourcés ;
- un élément sans taux disponible est **exclu et signalé**, jamais converti avec un taux inventé.

> Limite assumée : « 1 million » n'a pas le même sens partout (1 M JPY ≈ quelques milliers
> d'euros). Pour les devises à faible valeur unitaire, l'onboarding proposera une cible
> dans une devise forte. À valider au module Onboarding.

## Cible

- **Principale** : 25–45 ans, actifs urbains, déjà épargnants (livrets, PEA, assurance-vie,
  ETF, un peu de crypto), qui veulent une vision globale sans tableur.
- **Secondaire** : propriétaires qui veulent voir leur patrimoine net réel (bien − crédit).
- **Hors cible au lancement** : conseil en investissement, gestion de budget au centime,
  professionnels.

## Positionnement

Sobre, premium, pédagogique. Pas une app de trading, pas une app de budget culpabilisante.
Les concurrents du suivi de patrimoine existent (agrégateurs, suivis de net worth) ;
la différence tient à l'indicateur unique, aux paliers et à l'honnêteté des données
(source et date de chaque valeur affichées, estimations signalées comme telles).

## 20 propositions de nom

Aucune vérification de disponibilité n'a pu être faite depuis cet environnement (pas
d'accès web). Tout est **à vérifier** avant engagement.

| # | Nom | Idée |
|---|-----|------|
| 1 | **Cairn** | Pierres empilées qui balisent un chemin : chaque pierre est un palier |
| 2 | **Summa** | « La somme » en latin : tout le patrimoine en un chiffre |
| 3 | **Altus** | « Élevé » en latin, sobre, international |
| 4 | **Tenfold** | Multiplier par dix, idée de progression |
| 5 | **Keel** | La quille : stabilité, cap tenu |
| 6 | Waypoint | Point de passage sur une route |
| 7 | Crest | La crête, le sommet atteint |
| 8 | Meridian | Ligne de référence |
| 9 | Aurel | Évoque l'or sans le dire |
| 10 | Vesta | Le foyer, la solidité |
| 11 | Plinth | Le socle |
| 12 | Keystone | La clé de voûte |
| 13 | Lodestar | L'étoile qui guide |
| 14 | Sextant | L'outil qui mesure la position |
| 15 | Zenith | Le point le plus haut |
| 16 | Ascent | L'ascension |
| 17 | Stride | La foulée régulière |
| 18 | Pillar | Le pilier |
| 19 | Tally | Le décompte |
| 20 | Unum | « Un » : un seul chiffre, un million |

Noms volontairement écartés car déjà connus dans la finance personnelle : Finary, Kubera,
Monarch, Mylo, Cleo, Emma, Plum, Copilot, Moneybox.

### Top 5 et vérifications à faire

1. **Cairn** (nom de travail du code, centralisé dans `AppConfig.appName`). Court,
   prononçable en français et en anglais, métaphore directement utilisée dans l'interface.
   Risque : mot courant, déjà employé par des sociétés d'autres secteurs.
2. **Summa** : très lisible, risque de proximité avec des marques existantes.
3. **Altus** : sonne premium, probablement déjà déposé dans la finance.
4. **Tenfold** : parlant en anglais, moins en français.
5. **Keel** : très court, sens moins évident.

Pour chacun, avant de choisir :

- **Marques** : recherche INPI (France), EUIPO (TMview) et OMPI (Global Brand Database),
  classes 9 (logiciels) et 36 (services financiers).
- **Domaines** : .com, .app, .fr, .io ; accepter un préfixe (`getcairn`, `cairnapp`).
- **Stores** : recherche App Store et Google Play, noms identiques ou proches.
- **Réseaux sociaux** : disponibilité des identifiants.
- **Sens** dans les principales langues ciblées.

## Périmètre

### MVP (objectif : premier usage réel, gratuit)
Saisie manuelle de comptes, placements, biens et dettes ; multidevise avec taux BCE ;
dashboard % millionnaire, paliers, patrimoine net, historique ; transactions importées
(une banque via fournisseur sandbox puis production) ; catégorisation modifiable ;
dépenses et taux d'épargne ; score financier documenté ; projection ; authentification
Apple / Google / e-mail + biométrie + code ; mode confidentialité ; export et suppression
des données.

### V2
Plusieurs banques et fournisseurs par région ; positions d'investissement détaillées
(cours datés, plus-values) ; crypto par adresse publique ou API de plateforme en lecture
seule ; objectifs multiples ; notifications de paliers ; widgets iOS / Android ; import CSV.

### V3
Foyer (patrimoine partagé à deux) ; simulations (achat immobilier, retraite) ; rapports
PDF ; offre payante (voir monétisation) ; web.

## Risques

| Risque | Impact | Réponse |
|--------|--------|---------|
| Coût et contrat Open Banking | Bloquant pour la synchro réelle | Démo + saisie manuelle d'abord ; abstraction fournisseur |
| Pas de société | Bloquant pour publier une app financière et contracter | Créer une structure avant la production (voir ci-dessous) |
| Données de marché payantes | Valorisation des actions | Taux BCE gratuits, crypto via API gratuite avec attribution, actions via valeurs remontées par l'agrégateur |
| Sécurité / fuite de données | Critique | Aucun identifiant bancaire stocké, RLS, chiffrement, minimisation |
| Mauvaise interprétation (conseil) | Juridique | Mentions « estimation », « indicateur pédagogique », pas de recommandation |
| Rétention faible | Produit | Paliers, historique, notifications sobres |

## Contraintes liées à ta situation (0 €, pas de société)

Ce qui est **possible à 0 €** : développer, tester sur Android et iOS en local (iOS : voir
plus bas), backend Supabase en offre gratuite, profils démo, sandbox Open Banking.

Ce qui **coûte ou exige une structure** :

- **Apple Developer Program** : 99 USD/an. Les consignes App Store (règle 5.1.1 ix)
  demandent que les apps de services financiers réglementés soient publiées par une
  **personne morale**, pas un particulier. À vérifier au moment de la soumission.
- **Google Play** : 25 USD une fois. Un compte personnel récent doit faire un **test fermé
  (12 testeurs pendant 14 jours)** avant la production ; Google peut exiger un compte
  **organisation** pour les apps financières. À vérifier.
- **Open Banking en production** : contrat avec un prestataire agréé (AISP) ; en pratique
  il faut une société, et c'est payant au-delà des offres d'essai.
- **iOS depuis Windows** : compilation, signature et soumission iOS exigent **macOS**.
  Options gratuites à vérifier : minutes macOS offertes par Codemagic, runners macOS de
  GitHub Actions (gratuits sur dépôt public).

Recommandation : tout construire et tester maintenant ; créer une micro-structure
(SAS/SASU ou équivalent dans ton pays) seulement quand l'app est prête à être publiée.

## Monétisation future (sans l'implémenter maintenant)

Freemium : gratuit avec saisie manuelle et une banque ; abonnement pour plusieurs banques,
historique long, investissements détaillés, foyer. Jamais de revente de données, jamais
de publicité ciblée sur des données financières.
