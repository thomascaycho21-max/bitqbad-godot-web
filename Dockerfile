FROM nginx:alpine

# Instalar Node.js
RUN apk add --no-cache nodejs

# Copiar build web y scripts
COPY build/web /usr/share/nginx/html
COPY inject.js /inject.js
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Configurar Nginx
RUN printf 'server {\n\
  listen 80;\n\
  root /usr/share/nginx/html;\n\
  index index.html;\n\
  location / {\n\
    add_header Cross-Origin-Opener-Policy same-origin;\n\
    add_header Cross-Origin-Embedder-Policy require-corp;\n\
    try_files $uri $uri/ /index.html;\n\
  }\n\
}\n' > /etc/nginx/conf.d/default.conf

EXPOSE 80
ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]