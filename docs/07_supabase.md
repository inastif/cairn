# 7. Brancher la base de données (Supabase)

Sans configuration, l'app reste en **mode démonstration**. Avec les étapes
ci-dessous (environ 15 minutes, gratuit), elle passe en **mode réel** : connexion
par e-mail, code de verrouillage, saisie de tes actifs et dettes, sauvegarde et
historique.

## 1. Créer le projet

1. Crée un compte gratuit sur supabase.com.
2. *New project* : nom `cairn-dev`, **région en Europe** (Paris si proposée,
   sinon Francfort), mot de passe de base généré et rangé dans un gestionnaire
   de mots de passe. Tu n'en auras pas besoin dans l'app.

## 2. Créer les tables

*SQL Editor* → *New query* → colle tout le contenu de
`supabase/migrations/20260928120000_module2_initial_schema.sql` → *Run*.
Le script peut être relancé sans risque.

Vérification : *Table Editor* affiche `profiles`, `assets`, `liabilities`,
`net_worth_snapshots`, `fx_rates`, chacune marquée **RLS enabled**.

## 3. Recevoir un code (et pas seulement un lien)

*Authentication* → *Emails* → *Templates*. Dans **Magic Link** et dans
**Confirm signup**, remplace le contenu par :

```html
<h2>Ton code de connexion</h2>
<p>Saisis ce code dans l'application :</p>
<p style="font-size:28px;letter-spacing:6px"><strong>{{ .Token }}</strong></p>
<p>Il expire dans une heure. Si tu n'as rien demandé, ignore cet e-mail.</p>
```

## 4. Relier l'app

*Project Settings* → *API Keys* : copie l'**URL du projet** et la clé
**publishable** (sur un ancien projet : clé **anon**). Ne copie jamais la clé
`service_role` / `secret`.

Dans le projet, copie `env/dev.example.json` en `env/dev.json` et remplis-le.
Ce fichier est exclu de Git.

```powershell
Copy-Item env\dev.example.json env\dev.json
notepad env\dev.json
```

## 5. Préparer Android et iOS (une fois)

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\configure_native.ps1
```

Le script adapte l'activité Android pour la biométrie et ajoute les permissions
Internet et biométrie ainsi que le texte Face ID.

## 6. Lancer en mode réel

```powershell
flutter pub get
flutter run -d chrome --dart-define-from-file=env/dev.json
```

Sur Chrome, la biométrie n'existe pas : seul le code est proposé. Sur un
téléphone ou un émulateur Android : `flutter run --dart-define-from-file=env/dev.json`.

## 7. Taux de change automatiques (facultatif)

Nécessaire seulement si tu saisis des montants dans une autre devise que ta
devise de référence. Sans cette étape, ces éléments sont signalés comme « non
comptés », jamais convertis avec un taux inventé.

Il faut Node.js (nodejs.org, version LTS). Puis :

```powershell
npx supabase login
npx supabase link --project-ref TON_ID_DE_PROJET
npx supabase functions deploy fx-ecb
```

L'identifiant du projet est la partie `xxxx` de `https://xxxx.supabase.co`.
L'app appelle ensuite la fonction d'elle-même quand ses taux ont plus de 4 jours.

## Limites de l'offre gratuite (à vérifier, elles évoluent)

- **E-mails** : le service d'envoi intégré est prévu pour les tests. Il n'envoie
  qu'à un volume très faible et, sur les projets récents, seulement aux adresses
  des membres de l'équipe du projet. Utilise l'adresse de ton compte Supabase
  pour tester. Avant d'ouvrir l'app à d'autres personnes : *Authentication* →
  *SMTP Settings* avec un service d'e-mail qui a une offre gratuite.
- **Mise en pause** d'un projet gratuit après une période sans activité : il se
  relance depuis le tableau de bord.
- **Sauvegardes** limitées : pas de restauration à un instant précis.

## Sécurité : ce qui protège tes données

| Couche | Protection |
|--------|------------|
| Base | RLS sur toutes les tables : chaque requête est filtrée par l'identifiant du compte connecté, côté serveur |
| Contraintes | Devises ISO, montants bornés, dette ≥ 0, seul un compte de liquidités peut être négatif, une dette ne peut être rattachée qu'à un bien de son propriétaire |
| Session | Rangée dans le Keychain / Keystore sur mobile |
| Appareil | Code à 6 chiffres (PBKDF2-HMAC-SHA256, 60 000 itérations, sel aléatoire), biométrie facultative, blocage progressif dès le 5e échec, effacement et reconnexion au 10e, reverrouillage après 60 s en arrière-plan |
| Secrets | Aucun dans l'app : la clé `service_role` n'existe que dans la fonction serveur |
| RGPD | Suppression complète du compte et des données depuis le profil |
