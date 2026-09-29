# 3. UX / UI

## Parti pris visuel

Identité **minérale**, issue du nom : pierre, basalte, jade, laiton.
Ni le noir et néon des néobanques, ni le fond crème des apps « éditoriales ».

| Jeton | Clair | Sombre | Usage |
|-------|-------|--------|-------|
| background | #F1F3F0 | #101312 | Fond d'écran, gris pierre légèrement verdi |
| surface | #FFFFFF | #181C1A | Panneaux |
| textPrimary | #1A1E1C | #EEF0EC | Texte principal (basalte) |
| accent | #245E55 | #72C2B1 | Actions, courbe (jade profond) |
| milestone | #7A5418 | #D9B26A | Paliers du million uniquement (laiton) |
| positive / negative | #2B7548 / #A3433A | #66C28E / #E38A7C | Variations |

Contrastes vérifiés ≥ 4,5:1 (WCAG AA) pour tous les textes.

**Typographie** : une seule famille, Manrope (licence OFL, embarquée), en 400 à 700.
Chiffres **tabulaires** pour tous les montants. Le pourcentage millionnaire est en 64 pt,
graisse 700, approche resserrée.

**Élément signature** : le **cairn**. Sept pierres empilées, de la plus large à la plus
petite, une par palier (1, 5, 10, 25, 50, 75, 100 %). Les pierres franchies sont pleines
de laiton, la pierre en cours se remplit proportionnellement. C'est la seule animation
non déclenchée par l'utilisateur (une fois, à l'ouverture), désactivée si le système
demande de réduire les animations.

Le reste reste calme : panneaux à bordure fine sans ombre, rayons hiérarchisés
(8 / 14 / 22), pas de dégradé décoratif, pas d'étiquettes en capitales.

## Navigation (5 onglets)

Accueil · Patrimoine · Activité · Investir · Profil. L'état de chaque onglet est conservé.

## Écrans

| Écran | Contenu | État module 1 |
|-------|---------|---------------|
| Accueil | % millionnaire, cairn, paliers, patrimoine net et variation du mois, brut, dettes, depuis le 1er janvier, reste à 1 M, courbe 12 mois, flux du mois, score, projection, dernière synchro | Fait |
| Détail du score | Points par facteur, valeur mesurée, méthode, avertissement | Fait |
| Patrimoine | Net, actifs, dettes, équité immobilière, répartition, détail par classe avec devise d'origine | Fait |
| Activité | Liste des opérations catégorisées | Lecture seule ; filtres, recatégorisation, dépenses, épargne au module 3 |
| Investir | Totaux placements et crypto | Détail par position au module 5 |
| Profil | Banques, profil démo, thème, confidentialité | Fait (banques désactivées) |
| Onboarding, connexion, verrouillage | | Modules 2 et 6 |

## Règles d'écriture

Tutoiement, phrases courtes, verbes d'action (« Synchroniser maintenant », « Réessayer »).
Jamais de jugement : « Situation à consolider », pas « Mauvais ». Toute estimation est
nommée comme telle. Les erreurs disent ce qui se passe et quoi faire.

## Accessibilité

Zones tactiles ≥ 48 px, libellés sémantiques sur les graphiques et le cairn, tailles de
texte système respectées (pourcentage en `FittedBox`), couleur jamais seule porteuse
d'information, mode sombre complet, animations réduites respectées.

## États

Chargement, erreur avec « Réessayer », vide avec invitation à ajouter un premier
élément, données insuffisantes (score), taux de change manquant (signalé).
