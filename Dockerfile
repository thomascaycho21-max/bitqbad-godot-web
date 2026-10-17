FROM nginx:alpine
# Copia tu build web de Godot a la carpeta pública de Nginx
COPY build/web /usr/share/nginx/html
# Configuración de Nginx para Godot 4 (Headers de seguridad y redirección)
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