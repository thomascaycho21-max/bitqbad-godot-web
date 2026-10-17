extends Node
const PATH := "user://coins.cfg"
var _wallets: Dictionary = {}
var _gh_enabled := false
var _gh_token := ""
var _gh_repo := ""
var _gh_error := ""

func _ready() -> void:
    _load_local()
    # Esperar 1 segundo para que el HTML inyecte el token en Render
    await get_tree().create_timer(1.0).timeout
    
    _gh_token = _cfg("token")
    _gh_repo = _cfg("coins_repo")
    if _gh_token == "": _gh_error = "Falta GITHUB_TOKEN"; return
    if _gh_repo == "" or not _gh_repo.contains("/"): _gh_error = "Falta GITHUB_COINS_REPO"; return
    _gh_enabled = true

func _cfg(key: String) -> String:
    var secrets_path = "res://scripts/services/secrets.gd"
    if FileAccess.file_exists(secrets_path):
        var secrets_script = load(secrets_path)
        if secrets_script:
            var secrets = secrets_script.new()
            var val = secrets.get(key.to_upper())
            if val != null and str(val) != "": return str(val).strip_edges()
            secrets.free()
    var env := OS.get_environment("GITHUB_" + key.to_upper())
    if env != "": return env.strip_edges()
    return str(ProjectSettings.get_setting("bitqbad/github/" + key, "")).strip_edges()

func is_github_enabled() -> bool: return _gh_enabled
func github_error() -> String: return _gh_error

func _load_local() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(PATH) == OK:
        var parsed = JSON.parse_string(str(cfg.get_value("data", "wallets", "{}")))
        if parsed is Dictionary: _wallets = parsed

func _save_local() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("data", "wallets", JSON.stringify(_wallets))
    cfg.save(PATH)

func get_wallet(user := "anon") -> Dictionary:
    if not _wallets.has(user):
        _wallets[user] = {"user": user, "balance": 100, "transactions": []}
        _save_local()
    return _wallets[user]

func add_coins(user: String, amount: int, reason: String) -> Dictionary:
    var w: Dictionary = get_wallet(user)
    w["balance"] = int(w["balance"]) + amount
    var txs: Array = w.get("transactions", [])
    txs.append({"amount": amount, "reason": reason, "timestamp": Time.get_datetime_string_from_system()})
    if txs.size() > 50: txs = txs.slice(txs.size() - 50)
    w["transactions"] = txs
    _wallets[user] = w
    _save_local()
    if _gh_enabled: _sync_github(user, w)
    return w

func spend_coins(user: String, amount: int, reason: String) -> bool:
    var w: Dictionary = get_wallet(user)
    if int(w["balance"]) < amount: return false
    w["balance"] = int(w["balance"]) - amount
    var txs: Array = w.get("transactions", [])
    txs.append({"amount": -amount, "reason": reason, "timestamp": Time.get_datetime_string_from_system()})
    if txs.size() > 50: txs = txs.slice(txs.size() - 50)
    w["transactions"] = txs
    _wallets[user] = w
    _save_local()
    if _gh_enabled: _sync_github(user, w)
    return true

func _sync_github(user: String, wallet: Dictionary) -> void:
    var safe := ""
    for ch in user:
        if ch.is_valid_identifier() or ch == "-" or ch == "_" or (ch >= "0" and ch <= "9"): safe += ch
    if safe == "": safe = "anon"
    _get_sha_then_write("wallets/%s.json" % safe, Marshalls.utf8_to_base64(JSON.stringify(wallet, "  ")), user)

func _get_sha_then_write(path: String, b64: String, user: String) -> void:
    var http := HTTPRequest.new(); add_child(http)
    http.request_completed.connect(_on_get_sha.bind(http, path, b64, user), CONNECT_ONE_SHOT)
    var headers := PackedStringArray(["Authorization: Bearer " + _gh_token, "Accept: application/vnd.github+json", "User-Agent: BitQbadPlayStore"])
    http.request("https://api.github.com/repos/%s/contents/%s" % [_gh_repo, path], headers, HTTPClient.METHOD_GET)

func _on_get_sha(result: int, code: int, _h: PackedStringArray, body: PackedByteArray, http: HTTPRequest, path: String, b64: String, user: String) -> void:
    http.queue_free()
    var sha := ""
    if result == HTTPRequest.RESULT_SUCCESS and code == 200:
        var data = JSON.parse_string(body.get_string_from_utf8())
        if data is Dictionary: sha = str(data.get("sha", ""))
    _write_file(path, b64, sha, user)

func _write_file(path: String, b64: String, sha: String, user: String) -> void:
    var http := HTTPRequest.new(); add_child(http)
    var payload := {"message": "update wallet %s" % user, "content": b64}
    if sha != "": payload["sha"] = sha
    var headers := PackedStringArray(["Authorization: Bearer " + _gh_token, "Accept: application/vnd.github+json", "Content-Type: application/json", "User-Agent: BitQbadPlayStore"])
    http.request("https://api.github.com/repos/%s/contents/%s" % [_gh_repo, path], headers, HTTPClient.METHOD_PUT, JSON.stringify(payload))
    http.request_completed.connect(func(_r, _c, _h, _b, h): h.queue_free(), CONNECT_ONE_SHOT)