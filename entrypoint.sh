#!/bin/sh
# Inyecta las variables de entorno de Render en el HTML estático
sed -i "s|window.BITQBAD_CONFIG = {};|window.BITQBAD_CONFIG = { token: '\${GITHUB_TOKEN}', repo: '\${GITHUB_REPO}', coins_repo: '\${GITHUB_COINS_REPO}' };|g" /usr/share/nginx/html/index.html
exec "$@"