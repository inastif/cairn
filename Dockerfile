# Image de la version web de Cairn.
# Prérequis : compiler d'abord l'application sur la machine
#   flutter build web --release
# puis construire l'image
#   docker build -t cairn-web:1.0 .
FROM nginx:alpine

COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY build/web /usr/share/nginx/html

EXPOSE 80