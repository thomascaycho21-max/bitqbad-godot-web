FROM nginx:alpine
# Instalar Node.js para el script de inyección
RUN apk add --no-cache nodejs
COPY build/web /usr/share/nginx/html
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
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