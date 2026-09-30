# Docker : API des taux de change

L'application Cairn utilise Supabase (service hébergé) pour l'authentification et
les données. L'API des taux de change (`api/`) est le service que nous exécutons
nous-mêmes : c'est elle qui est conteneurisée.

## Services

| Service | Image de base | Port | Données persistantes ? |
|---------|---------------|------|------------------------|
| `api` | `node:22-alpine` (construite depuis `api/Dockerfile`) | 3000 (interne) | Non : cache en mémoire, 6 h |
| `proxy` | `nginx:1.27-alpine` | 8080 (hôte) → 80 | Non |
| Base de données | aucune : les données restent sur Supabase (hébergé) | | |
| Cache / file | aucun : un cache mémoire suffit pour un fichier publié une fois par jour | | |

```
navigateur / curl
      │  :8080
      ▼
┌───────────┐  http://api:3000  ┌────────────┐      HTTPS      ┌──────────────┐
│  proxy    │ ────────────────▶ │    api     │ ──────────────▶ │  BCE (XML)   │
│  (nginx)  │                   │ (Fastify)  │                 └──────────────┘
└───────────┘                   └────────────┘
   publié sur l'hôte             non publié : joignable
                                 uniquement via le réseau compose
```

Aucun volume n'est déclaré : aucun des deux services ne stocke de données.
Une base de données avec volume n'aurait pas de raison d'être ici, Supabase
jouant ce rôle.

## Dockerfile de l'API

- `node:22-alpine` : image légère.
- `package.json` et `package-lock.json` sont copiés **avant** le code : tant que
  les dépendances ne changent pas, Docker réutilise la couche `npm ci`.
- `npm ci --omit=dev` : uniquement les dépendances de production, versions du
  verrou.
- `USER node` : le processus ne tourne pas en root.
- `HEALTHCHECK` : interroge `/health` ; Docker marque le conteneur `healthy` ou
  `unhealthy`.
- `.dockerignore` : `node_modules`, `.env`, `test` et `.git` n'entrent pas dans
  l'image.

## compose.yaml

- `api` est construit depuis `./api`, sans port publié (`expose` seulement).
  `read_only` et `no-new-privileges` durcissent le conteneur.
- `proxy` transmet les requêtes à `http://api:3000` (le nom du service sert de
  nom d'hôte sur le réseau compose) et n'est lancé qu'une fois l'API `healthy`
  (`depends_on` avec `condition: service_healthy`).

## Variables d'environnement

| Fichier | Versionné ? | Rôle |
|---------|-------------|------|
| `.env.example` | oui | Modèle documenté, sans secret |
| `.env` | **non** (dans `.gitignore`) | Copie locale, lue par compose |

```bash
copy .env.example .env      # Linux / macOS : cp .env.example .env
```

L'API n'utilise aucun secret ; `.env` ne contient que le port du proxy, l'étiquette
de l'image et, en option, une autre source de taux.

## Lancer

```bash
copy .env.example .env
docker compose up -d --build
docker compose ps
curl http://localhost:8080/health
curl "http://localhost:8080/fx/convert?from=USD&to=GBP&amount=100"
docker compose logs api
docker compose down
```

## Vérification croisée

Un autre développeur n'a besoin que de Git et Docker (ni Node, ni Flutter) :

```bash
git clone https://github.com/inastif/cairn.git
cd cairn
copy .env.example .env
docker compose up -d --build
curl http://localhost:8080/health
```

## Publier sur Docker Hub

```bash
docker login
docker tag cairn-api:1.0 inastf/cairn-api:1.0
docker tag cairn-api:1.0 inastf/cairn-api:latest
docker push inastf/cairn-api:1.0
docker push inastf/cairn-api:latest
```

Image publiée : <https://hub.docker.com/r/inastf/cairn-api>

## Intégration continue

Le job « API image » du workflow CI construit l'image, démarre un conteneur,
attend l'état `healthy` puis appelle `/health`. Une PR dont l'image ne se
construit pas ou ne démarre pas est bloquée avant la fusion.
