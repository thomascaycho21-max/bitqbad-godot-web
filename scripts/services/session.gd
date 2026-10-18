extends Node
## Sesion persistente. Sin country/age (se piden al pagar).

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
        "provider": cfg.get_value("user", "provider", "github"),
        "role": cfg.get_value("user", "role", "user"),
    }

func save_session(u: Dictionary) -> void:
    user = u
    var cfg := ConfigFile.new()
    cfg.set_value("user", "login", u.get("login", ""))
    cfg.set_value("user", "name", u.get("name", ""))
    cfg.set_value("user", "avatar", u.get("avatar", ""))
    cfg.set_value("user", "provider", u.get("provider", "github"))
    cfg.set_value("user", "role", u.get("role", "user"))
    cfg.save(PATH)

func logout() -> void:
    user = {}
    if FileAccess.file_exists(PATH):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))

func is_logged_in() -> bool:
    return not user.is_empty()

func is_developer() -> bool:
    return str(user.get("role", "user")) == "developer"

func login() -> String:
    return str(user.get("login", "anon"))