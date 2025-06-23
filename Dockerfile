# ----------- Étape 1 : Build Flutter Web ----------- #
FROM ghcr.io/cirruslabs/flutter:latest AS build

WORKDIR /app

# Cache dependencies
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copier tout le code source
COPY . .

# Activer le support web et builder
RUN flutter config --enable-web && \
    flutter build web --release

# ----------- Étape 2 : NGINX Runtime sécurisé ----------- #
FROM nginx:stable-alpine AS runtime

# Sécurité : créer un user non-root
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Nettoyage des fichiers nginx par défaut
RUN rm -rf /usr/share/nginx/html/*

# Copier le build Flutter
COPY --from=build /app/build/web /usr/share/nginx/html

# Remplacer complètement la config NGINX (pas juste conf.d)
COPY docker/nginx.conf /etc/nginx/nginx.conf

# Attribuer les bons droits
RUN chown -R appuser:appgroup /usr/share/nginx/html

# Exécuter en tant que user sécurisé
USER appuser

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
