# Cairn API

Petite API Node.js (Fastify) qui sert les **taux de change de référence de la BCE**
(base EUR) à l'application Cairn. Elle reprend le rôle de la fonction Supabase
`fx-ecb` : même source, même format (`1 EUR = rate unités de la devise cotée`).

Supabase reste utilisé pour l'authentification et les données de l'utilisateur.

## Prérequis

- Node.js 20+

## Démarrer

```bash
cd api
cp .env.example .env     # Windows : copy .env.example .env
npm install
npm run dev
```

L'API écoute sur <http://localhost:3000>.

## Routes

| Route | Rôle |
|-------|------|
| `GET /health` | Contrôle de santé : `{"status":"ok"}` |
| `GET /fx/latest` | Taux du jour : `base`, `date`, `source`, `fetchedAt`, `stale`, `rates` |
| `GET /fx/convert?from=USD&to=GBP&amount=100` | Conversion d'un montant via l'euro |

Codes d'erreur : `400` paramètres invalides, `422` devise inconnue (aucun taux
inventé), `502` BCE injoignable et aucun taux en mémoire.

```bash
curl http://localhost:3000/fx/latest
curl "http://localhost:3000/fx/convert?from=USD&to=GBP&amount=100"
```

## Fonctionnement

- Les taux sont gardés **6 heures en mémoire** : la BCE publie une fois par jour
  ouvré, inutile de la solliciter à chaque requête.
- Des requêtes simultanées ne déclenchent **qu'un seul appel** à la BCE.
- Si la BCE tombe, l'API continue de servir les derniers taux connus avec
  `"stale": true`.

## Configuration

| Variable | Défaut | Rôle |
|----------|--------|------|
| `PORT` | `3000` | Port d'écoute |
| `HOST` | `0.0.0.0` | Interface d'écoute |
| `ECB_URL` | URL officielle de la BCE | Autre source de taux (tests) |

## Tests

```bash
npm test
```

Les tests n'appellent jamais la vraie BCE : le client HTTP est remplacé par un
faux.

## Docker

L'API est conteneurisée avec une image `node:22-alpine` (`api/Dockerfile`).
Les dépendances sont installées avant la copie du code pour profiter du cache de
Docker ; le conteneur tourne avec l'utilisateur `node` (jamais en root) et un
`HEALTHCHECK` interroge `/health`.

```bash
# Depuis la racine du dépôt, avec docker compose
copy .env.example .env       # Linux / macOS : cp .env.example .env
docker compose up -d --build
docker compose ps            # l'API passe à "healthy", puis le proxy démarre
curl http://localhost:8080/fx/latest
docker compose down
```

Compose lance deux services : l'API (visible seulement par les autres
conteneurs) et un reverse proxy nginx qui l'expose sur le port 8080.

Ou à la main :

```bash
docker build -t cairn-api:1.0 ./api
docker run --name cairn-api -p 3000:3000 -d cairn-api:1.0
docker inspect --format '{{.State.Health.Status}}' cairn-api
```

## Structure

```
api/
├── src/
│   ├── server.js          Démarrage et arrêt propre (SIGTERM)
│   ├── app.js             Routes et validation des paramètres
│   ├── rates-service.js   Cache, conversion, mode « stale »
│   └── ecb.js             Téléchargement et lecture du XML de la BCE
├── test/                  Tests (node:test)
└── Dockerfile             Image de l'API

compose.yaml               API + reverse proxy nginx (racine du dépôt)
docker/nginx-api.conf      Configuration du reverse proxy
```
