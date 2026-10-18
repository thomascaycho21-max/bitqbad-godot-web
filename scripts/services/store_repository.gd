extends Node
const DEFAULT_PATH := "res://data/apps.json"
var apps: Array = []
var categories: Array = ["Todas"]
var _custom_categories: Array = []
var _apps_path := DEFAULT_PATH

func _ready() -> void:
    load_apps()

func load_apps() -> void:
    apps.clear()
    _custom_categories.clear()
    categories = ["Todas"]
    var f := FileAccess.open(_apps_path, FileAccess.READ)
    if f == null:
        f = FileAccess.open(DEFAULT_PATH, FileAccess.READ)
        _apps_path = DEFAULT_PATH
    if f == null:
        push_error("[StoreRepo] No se pudo abrir apps.json")
        return
    var txt = f.get_as_text()
    f.close()
    var parsed = JSON.parse_string(txt)
    if parsed == null or not parsed.has("apps"):
        push_error("[StoreRepo] JSON invalido en " + _apps_path + ". Usando por defecto.")
        # Si el custom fallo, volvemos al default
        if _apps_path != DEFAULT_PATH:
            _apps_path = DEFAULT_PATH
            var f2 = FileAccess.open(DEFAULT_PATH, FileAccess.READ)
            if f2:
                parsed = JSON.parse_string(f2.get_as_text())
                f2.close()
        if parsed == null or not parsed.has("apps"):
            return
    apps = parsed["apps"]
    if parsed.has("categories"):
        _custom_categories = parsed["categories"]
    var cats := {}
    for a in apps:
        cats[str(a.get("category", "Otros"))] = true
    for c in _custom_categories:
        cats[str(c)] = true
    var sorted_cats: Array = cats.keys()
    sorted_cats.sort()
    categories.append_array(sorted_cats)
    print("[StoreRepo] %d apps cargadas desde %s" % [apps.size(), _apps_path])

func save_apps() -> void:
    var data := {"categories": [], "apps": apps}
    var cats := {}
    for a in apps:
        cats[str(a.get("category", "Otros"))] = true
    data["categories"] = cats.keys()
    var f := FileAccess.open("user://apps_custom.json", FileAccess.WRITE)
    if f == null:
        push_error("[StoreRepo] No se pudo guardar apps.json")
        return
    f.store_string(JSON.stringify(data, "  "))
    f.close()
    _apps_path = "user://apps_custom.json"
    load_apps()

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

func add_category(cat: String) -> void:
    if cat.strip_edges() == "": return
    if not categories.has(cat):
        categories.append(cat)
        save_apps()

func remove_category(cat: String) -> void:
    if cat == "Todas": return
    categories.erase(cat)
    save_apps()

func add_app(app: Dictionary) -> void:
    apps.append(app)
    save_apps()

func update_app(app_id: String, new_data: Dictionary) -> void:
    for i in range(apps.size()):
        if str(apps[i].get("id", "")) == app_id:
            for k in new_data.keys():
                apps[i][k] = new_data[k]
            save_apps()
            return

func remove_app(app_id: String) -> void:
    for i in range(apps.size()):
        if str(apps[i].get("id", "")) == app_id:
            apps.remove_at(i)
            save_apps()
            return