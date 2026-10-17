# BitQbad PlayStore — Godot 4.7.1

Proyecto GENERADO con el FIX. Abre `project.godot` en Godot 4.7.1.

## Importante
- El autoload de tema se llama **BitTheme** (no `Theme`, que es clase built-in y provoca error).
- Los `.uid` e `.import` se regeneran solos al abrir el proyecto. No los crees a mano.
- `main.tscn` NO lleva `uid=` en el `gd_scene`. Godot lo asigna al importar.

## Abrir
1. Godot 4.7.1 → Import → `V:\copilacion\bitqbad_indexacion\project.godot`.
2. Deja que termine el escaneo. Ignora warnings de "no export template".
3. F5 para correr.

## Web
1. Editor → Manage Export Templates → Download (4.7.1).
2. Project → Export → preset Web → Export Project a `build/web/`.
3. `cd build\web; python -m http.server 8080` → `http://localhost:8080`.

## APK
1. JDK 17 + Android SDK.
2. Editor Settings → Export → Android → Android SDK Path.
3. Project → Install Android Build Template.
4. Project → Export → preset Android → Export.

## Configurar GitHub (reseñas)
Edita `project.godot` sección `[bitqbad]`:
github/token="ghp_xxx"
github/repo="usuario/repo"
github/review_label="review"
O define variables de entorno `GITHUB_TOKEN`, `GITHUB_REPO`, `GITHUB_REVIEW_LABEL`.

## Estructura
- `scripts/main.gd` — UI + vistas (home, store, detail, reviews, coins, about, login)
- `scripts/ui/theme.gd` — autoload **BitTheme** (colores + helpers)
- `scripts/ui/router.gd` — autoload Router
- `scripts/services/` — Session, StoreRepo, Reviews, Coins, GitHubAuth
- `data/apps.json` — catálogo
- `scenes/main.tscn` — escena raíz