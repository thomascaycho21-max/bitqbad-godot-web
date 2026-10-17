extends Node
## Carga apps desde res://data/apps.json

var apps: Array = []
var categories: Array = ["Todas"]

func _ready() -> void:
    load_apps()

func load_apps() -> void:
    apps.clear()
    categories = ["Todas"]
    var f := FileAccess.open("res://data/apps.json", FileAccess.READ)
    if f == null:
        push_error("[StoreRepo] No se pudo abrir res://data/apps.json")
        return
    var txt := f.get_as_text()
    f.close()
    var parsed = JSON.parse_string(txt)
    if parsed == null or not parsed.has("apps"):
        push_error("[StoreRepo] JSON invalido")
        return
    apps = parsed["apps"]
    var cats := {}
    for a in apps:
        cats[str(a.get("category", "Otros"))] = true
    var sorted_cats: Array = cats.keys()
    sorted_cats.sort()
    categories.append_array(sorted_cats)
    print("[StoreRepo] %d apps, %d categorias" % [apps.size(), sorted_cats.size()])

func all() -> Array:
    return apps

func by_id(app_id: String) -> Dictionary:
    for a in apps:
        if str(a.get("id", "")) == app_id:
            return a
    return {}

func filter_apps(category := "Todas", query := "") -> Array:
    var q := query.strip_edges().to_lower()
    var out: Array = []
    for a in apps:
        if category != "Todas" and str(a.get("category", "")) != category:
            continue
        if q != "":
            var hay := (str(a.get("name","")) + " " + str(a.get("short_desc","")) + " " + str(a.get("category",""))).to_lower()
            if not hay.contains(q):
                continue
        out.append(a)
    return out

func downloads_str(downloads: int) -> String:
    if downloads >= 1000000:
        return "%.1fM" % (downloads / 1000000.0)
    if downloads >= 1000:
        return "%.1fK" % (downloads / 1000.0)
    return str(downloads)