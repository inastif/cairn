# Image de l'API Cairn (Node.js 22, Alpine : petite et rapide à télécharger)
FROM node:22-alpine

ENV NODE_ENV=production
WORKDIR /app

# 1) Dépendances d'abord : cette couche reste en cache tant que
#    package.json / package-lock.json ne changent pas.
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# 2) Puis le code (seul src/ est nécessaire pour démarrer l'API)
COPY src ./src

# Ne jamais faire tourner l'application en root
USER node

EXPOSE 3000

# Docker interroge /health : le conteneur passe en "healthy" ou "unhealthy"
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- "http://127.0.0.1:${PORT:-3000}/health" || exit 1

CMD ["node", "src/server.js"]
