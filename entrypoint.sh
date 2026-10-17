#!/bin/sh
# Elimina inyecciones viejas si existen (por si acaso)
sed -i '/window.BITQBAD_CONFIG/d' /usr/share/nginx/html/index.html
# Inyecta el token justo antes de cerrar el head
sed -i "s|</head>|<script>window.BITQBAD_CONFIG = { token: '\${GITHUB_TOKEN}', repo: '\${GITHUB_REPO}', coins_repo: '\${GITHUB_COINS_REPO}' };</script></head>|" /usr/share/nginx/html/index.html
exec "$@"