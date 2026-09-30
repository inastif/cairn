# Docker

Cairn est une application Flutter. Sa version **web** peut être compilée puis servie
par Nginx dans un conteneur Docker. Les applications Android / iOS ne sont pas
concernées : elles sont distribuées par les stores.

## Image de l'application

L'application est compilée sur la machine avec le SDK Flutter déjà installé
(`flutter build web --release`), puis le `Dockerfile` à la racine copie le résultat
(`build/web`) et la configuration `docker/nginx.conf` dans l'image `nginx:alpine`.
L'image finale est légère (quelques dizaines de Mo) et ne contient ni le SDK
Flutter, ni le code source.

`docker/nginx.conf` renvoie `index.html` pour toute URL inconnue : sans cela, un
rafraîchissement sur une route de l'application (`/profil`, par exemple)
renverrait une erreur 404.

`.dockerignore` n'envoie à Docker que `build/web` et `docker/nginx.conf` : **aucun
secret (`env/*.json`) n'entre dans l'image**. Sans configuration Supabase, l'image
démarre en mode démonstration.

### Construire et lancer

```bash
flutter build web --release
docker build -t cairn-web:1.0 .
docker run --name cairn1 -p 8081:80 -d cairn-web:1.0
```

Puis ouvrir <http://localhost:8081>.

Changer d'environnement : `flutter build web --release --dart-define=APP_ENV=staging`
avant le `docker build`.

### Publier sur Docker Hub

```bash
docker login
docker tag cairn-web:1.0 inastf/cairn-web:1.0
docker tag cairn-web:1.0 inastf/cairn-web:latest
docker push inastf/cairn-web:1.0
docker push inastf/cairn-web:latest
```

## Image d'exercice

Le dossier `tp-docker-image/` contient l'image minimale du TP : une page HTML
statique copiée dans `nginx:alpine`.

```bash
cd tp-docker-image
docker build -t monsite:1.0 .
docker run --name monsite1 -p 8081:80 -d monsite:1.0
```

## Questions de validation

**1. Quelle différence entre image et conteneur ?**
Une image est un modèle figé, en lecture seule : un empilement de couches de
fichiers et une configuration (commande de démarrage, ports, variables). Un
conteneur est une instance **en cours d'exécution** (ou arrêtée) d'une image : un
processus isolé, avec en plus une couche inscriptible qui lui est propre. Une même
image peut servir à lancer plusieurs conteneurs, comme une classe et ses objets.

**2. À quoi sert `-p 8081:80` ? Dans quel sens va le mapping ?**
Il publie un port du conteneur sur la machine hôte. Le format est
`port_hôte:port_conteneur` : les requêtes reçues sur le port **8081 de l'hôte**
(`http://localhost:8081`) sont redirigées vers le port **80 du conteneur**, où
écoute Nginx. Sans `-p`, le conteneur n'est pas joignable depuis l'hôte.

**3. Différence entre `docker run` et `docker start` ?**
`docker run` **crée un nouveau conteneur** à partir d'une image (en la téléchargeant
si besoin), avec ses options (`-p`, `-e`, `-v`, `--name`…), puis le démarre.
`docker start` **redémarre un conteneur existant** qui a été arrêté : il garde sa
configuration et les fichiers écrits dans sa couche, et on ne peut plus changer
ses options.

**4. Quelle commande donne la configuration complète d'un conteneur ?**
`docker inspect <conteneur>` : sortie JSON avec l'image, les ports, les volumes,
les variables d'environnement, le réseau, l'état… Une valeur précise s'extrait
avec `-f`, par exemple `docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' web1`.

**5. Pourquoi tagger une image avant un `docker push` ?**
Le nom de l'image indique **où** la pousser : `registre/namespace/dépôt:version`.
`monsite:1.0` sous-entend `docker.io/library/monsite`, l'espace réservé aux images
officielles, où l'on n'a pas le droit d'écrire. Le tag
`<identifiant>/monsite:1.0` désigne son propre espace sur Docker Hub, et la
partie après `:` fixe la version (`1.0`, `latest`) que l'on publie.