extends Node
## Sesion persistente en user://session.cfg

const PATH := "user://session.cfg"
var user: Dictionary = {}

func _ready() -> void:
    load_session()

func load_session() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(PATH) != OK:
        return
    user = {
        "login": cfg.get_value("user", "login", ""),
        "name": cfg.get_value("user", "name", ""),
        "avatar": cfg.get_value("user", "avatar", ""),
    }

func save_session(u: Dictionary) -> void:
    user = u
    var cfg := ConfigFile.new()
    cfg.set_value("user", "login", u.get("login", ""))
    cfg.set_value("user", "name", u.get("name", ""))
    cfg.set_value("user", "avatar", u.get("avatar", ""))
    cfg.save(PATH)

func logout() -> void:
    user = {}
    if FileAccess.file_exists(PATH):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))

func is_logged_in() -> bool:
    return not user.is_empty()