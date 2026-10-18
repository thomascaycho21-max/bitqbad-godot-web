#!/bin/sh
# Crea el script que inyectará las variables en el HTML usando Node.js
cat << 'EOF' > /tmp/inject.js
const fs = require('fs');
const path = '/usr/share/nginx/html/index.html';
const token = process.env.GITHUB_TOKEN || '';
const repo = process.env.GITHUB_REPO || '';
const coins_repo = process.env.GITHUB_COINS_REPO || '';
try {
    let html = fs.readFileSync(path, 'utf8');
    // Elimina inyecciones viejas si existen
    html = html.replace(/<script id="bitqbad-config">.*?<\/script>/g, '');
    const config = <script id="bitqbad-config">window.BITQBAD_CONFIG = { token: '${token}', repo: '${repo}', coins_repo: '${coins_repo}' };</script>;
    // Inyecta la nueva configuración justo antes de </head>
    html = html.replace('</head>', config + '</head>');
    fs.writeFileSync(path, html);
    console.log('✅ Variables inyectadas con éxito.');
} catch (e) {
    console.error('❌ Error inyectando variables:', e);
}
EOF
node /tmp/inject.js
exec "\$@"