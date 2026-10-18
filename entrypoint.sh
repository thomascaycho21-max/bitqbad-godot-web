#!/bin/sh
echo "window.BITQBAD_CONFIG = { token: '\', repo: '\', coins_repo: '\' };" > /usr/share/nginx/html/config.js
sed -i "s|<head>|<head><script src=\"config.js\"></script>|g" /usr/share/nginx/html/index.html
exec "\$@"