extends Node
## Monedas tipo Robux.
## - Cache local en user://coins.cfg (siempre)
## - Si GITHUB_TOKEN + GITHUB_COINS_REPO están definidos, sincroniza
##   wallets/<user>.json en ese repo (mismo backend que la versión Flet).

const PATH := "user://coins.cfg"
const WELCOME_BALANCE := 100

var _wallets: Dictionary = {}
var _gh_enabled := false
var _gh_token := ""
var _gh_repo := ""
var _gh_error := ""

func _ready() -> void:
    _load_local()
    _init_github()

# ---------- Config GitHub ----------
func _init_github() -> void:
    _gh_token = _cfg("token")
    _gh_repo = _cfg_coins_repo()
    if _gh_token == "":
        _gh_error = "Falta GITHUB_TOKEN"
        return
    if _gh_repo == "" or not _gh_repo.contains("/"):
        _gh_error = "Falta GITHUB_COINS_REPO (usuario/repo)"
        return
    _gh_enabled = true

func _cfg(key: String) -> String:
    var env := OS.get_environment("GITHUB_" + key.to_upper())
    if env != "":
        return env.strip_edges()
    return str(ProjectSettings.get_setting("bitqbad/github/" + key, "")).strip_edges()

func _cfg_coins_repo() -> String:
    var env := OS.get_environment("GITHUB_COINS_REPO")
    if env != "":
        return env.strip_edges()
    return str(ProjectSettings.get_setting("bitqbad/github/coins_repo", "")).strip_edges()

func is_github_enabled() -> bool:
    return _gh_enabled

func github_error() -> String:
    return _gh_error

# ---------- Cache local ----------
func _load_local() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(PATH) == OK:
        var raw = cfg.get_value("data", "wallets", "{}")
        var parsed = JSON.parse_string(str(raw))
        if parsed is Dictionary:
            _wallets = parsed

func _save_local() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("data", "wallets", JSON.stringify(_wallets))
    cfg.save(PATH)

# ---------- API ----------
func get_wallet(user := "anon") -> Dictionary:
    if not _wallets.has(user):
        _wallets[user] = {"user": user, "balance": WELCOME_BALANCE, "transactions": []}
        _save_local()
    return _wallets[user]

func add_coins(user: String, amount: int, reason: String) -> Dictionary:
    var w: Dictionary = get_wallet(user)
    w["balance"] = int(w["balance"]) + amount
    var txs: Array = w.get("transactions", [])
    txs.append({"amount": amount, "reason": reason, "timestamp": Time.get_datetime_string_from_system()})
    if txs.size() > 50:
        txs = txs.slice(txs.size() - 50)
    w["transactions"] = txs
    _wallets[user] = w
    _save_local()
    _sync_github(user, w)
    return w

func spend_coins(user: String, amount: int, reason: String) -> bool:
    var w: Dictionary = get_wallet(user)
    if int(w["balance"]) < amount:
        return false
    w["balance"] = int(w["balance"]) - amount
    var txs: Array = w.get("transactions", [])
    txs.append({"amount": -amount, "reason": reason, "timestamp": Time.get_datetime_string_from_system()})
    if txs.size() > 50:
        txs = txs.slice(txs.size() - 50)
    w["transactions"] = txs
    _wallets[user] = w
    _save_local()
    _sync_github(user, w)
    return true

# ---------- Sincronización GitHub (best-effort) ----------
func _sync_github(user: String, wallet: Dictionary) -> void:
    if not _gh_enabled:
        return
    var safe := ""
    for ch in user:
        if ch.is_valid_identifier() or ch == "-" or ch == "_" or (ch >= "0" and ch <= "9"):
            safe += ch
    if safe == "":
        safe = "anon"
    var path := "wallets/%s.json" % safe
    var content := JSON.stringify(wallet, "  ")
    var b64 := Marshalls.utf8_to_base64(content)
    _get_sha_then_write(path, b64, user)

func _get_sha_then_write(path: String, b64: String, user: String) -> void:
    var http := HTTPRequest.new()
    add_child(http)
    http.request_completed.connect(_on_get_sha.bind(http, path, b64, user), CONNECT_ONE_SHOT)
    var headers := PackedStringArray([
        "Authorization: Bearer " + _gh_token,
        "Accept: application/vnd.github+json",
        "User-Agent: BitQbadPlayStore"
    ])
    http.request("https://api.github.com/repos/%s/contents/%s" % [_gh_repo, path], headers, HTTPClient.METHOD_GET)

func _on_get_sha(result: int, code: int, _h: PackedStringArray, body: PackedByteArray, http: HTTPRequest, path: String, b64: String, user: String) -> void:
    http.queue_free()
    var sha := ""
    if result == HTTPRequest.RESULT_SUCCESS and code == 200:
        var data = JSON.parse_string(body.get_string_from_utf8())
        if data is Dictionary:
            sha = str(data.get("sha", ""))
    _write_file(path, b64, sha, user)

func _write_file(path: String, b64: String, sha: String, user: String) -> void:
    var http := HTTPRequest.new()
    add_child(http)
    var payload := {
        "message": "update wallet %s" % user,
        "content": b64
    }
    if sha != "":
        payload["sha"] = sha
    var headers := PackedStringArray([
        "Authorization: Bearer " + _gh_token,
        "Accept: application/vnd.github+json",
        "Content-Type: application/json",
        "User-Agent: BitQbadPlayStore"
    ])
    http.request("https://api.github.com/repos/%s/contents/%s" % [_gh_repo, path], headers, HTTPClient.METHOD_PUT, JSON.stringify(payload))
    http.request_completed.connect(func(_r, _c, _h, _b, h): h.queue_free(), CONNECT_ONE_SHOT)