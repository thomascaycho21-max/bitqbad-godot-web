const fs = require('fs');
const path = '/usr/share/nginx/html/index.html';
const token = process.env.GITHUB_TOKEN || '';
const repo = process.env.GITHUB_REPO || '';
const coins_repo = process.env.GITHUB_COINS_REPO || '';

try {
    let html = fs.readFileSync(path, 'utf8');
    // Elimina inyecciones viejas si existen
    html = html.replace(/<script id="bitqbad-config">.*?<\/script>/g, '');
    
    // Genera el script de configuración
    const configScript = '<script id="bitqbad-config">window.BITQBAD_CONFIG = { token: "' + token + '", repo: "' + repo + '", coins_repo: "' + coins_repo + '" };</script>';
    
    // Inyecta la nueva configuración justo antes de </head>
    html = html.replace('</head>', configScript + '</head>');
    
    fs.writeFileSync(path, html);
    console.log('✅ Variables inyectadas con éxito.');
} catch (e) {
    console.error('❌ Error inyectando variables:', e);
}