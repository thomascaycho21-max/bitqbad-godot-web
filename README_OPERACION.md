# BitQbad PlayStore — Godot 4.7.1 (operación)

## 1) Abrir en Godot
- Godot 4.7.1 → Import → `V:\godot\bitqbad_playstore\project.godot`
- Deja escanear. Ignora warnings de "export template". F5 para correr.

## 2) Probar en Web (local)
- Editor → Manage Export Templates → Download (4.7.1)
- Project → Export → preset **Web** → Export Project a `build/web/`
- `cd build\web; python -m http.server 8080`
- Abre `http://localhost:8080`

## 3) Probar en APK
- JDK 17 + Android SDK instalados
- Editor Settings → Export → Android → Android SDK Path
- Project → Install Android Build Template
- Project → Export → preset **Android** → Export (APK queda en `build/android/`)

## 4) Reseñas (GitHub Issues) — mismo backend que Flet
Edita `project.godot` sección `[bitqbad]`:
GITHUB_TOKEN=tu_token_aqui
GITHUB_REPO=thomascaycho21-max/bitqbad-reviews
GITHUB_REVIEW_LABEL=review
o define variables de entorno `GITHUB_TOKEN`, `GITHUB_REPO`, `GITHUB_REVIEW_LABEL`.
Cada reseña es un Issue con título `review:<app_id> :: <título>` y label `review`.
El rating y el usuario van en el body como `<!-- meta: {"rating":5,"user":"x"} -->`.

## 5) Monedas — mismo backend GitHub que Flet
Añade a `[bitqbad]`:
GITHUB_COINS_REPO=thomascaycho21-max/bitqbad-coins
o define `GITHUB_COINS_REPO`.
Se crea `wallets/<user>.json` en ese repo con `{user,balance,transactions}`,
igual que en la versión Flet (`modules/coins/github_wallet.py`).
El cache local siempre está en `user://coins.cfg` (funciona sin red).

## 6) Render (web pública)
1. `git add . && git commit -m "godot web build" && git push`
   - Asegúrate de incluir `build/web/` en el commit (el Dockerfile lo sirve).
2. Render → New Web Service → conecta el repo de GitHub.
   - Render detecta `render.yaml` (runtime docker).
   - El Dockerfile usa `nginx:alpine` y sirve `build/web/`.
3. URL resultante: `https://bitqbad-playstore-godot.onrender.com` (o similar).

> Nota: Render **NO** ejecuta Godot ni Python. Sirve el HTML/JS/WASM
> ya compilado por el export Web de Godot. Cada vez que quieras
> actualizar la web pública: exportas Web otra vez y haces commit de `build/web/`.

## 7) URLs de ejemplo en apps.json
Cambia `https://github.com/tu-usuario/...` por tus repos reales.
