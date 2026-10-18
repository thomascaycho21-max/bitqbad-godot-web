extends Node
const PATH := "user://coins.cfg"
signal wallet_updated(user: String, wallet: Dictionary)
signal sync_finished(user: String, ok: bool)
signal package_purchased(user: String, package_id: String, ok: bool, message: String)

var _wallets: Dictionary = {}
var _gh_enabled := false
var _gh_token := ""
var _gh_repo := ""
var _gh_error := ""
var _sync_busy: Dictionary = {}

# Paquetes tipo Roblox (precio base USD, referencia de mercado)
const PACKAGES := [
    {"id": "basic",  "coins": 400,   "usd": 4.99},
    {"id": "standard","coins": 800,  "usd": 9.99},
    {"id": "plus",   "coins": 1700,  "usd": 19.99},
    {"id": "mega",   "coins": 4500,  "usd": 49.99},
    {"id": "ultra",  "coins": 10000, "usd": 99.99},
]

func _ready() -> void:
    _load_local()
    if OS.has_feature("web"):
        await get_tree().create_timer(0.5).timeout
    _gh_token = _cfg("token")
    _gh_repo = _cfg("coins_repo")
    if _gh_token == "": _gh_error = "Falta GITHUB_TOKEN"; return
    if _gh_repo == "" or not _gh_repo.contains("/"): _gh_error = "Falta GITHUB_COINS_REPO"; return
    _gh_enabled = true

func _cfg(key: String) -> String:
    if OS.has_feature("web"):
        var v = JavaScriptBridge.eval("window.BITQBAD_CONFIG ? window.BITQBAD_CONFIG." + key + " : null")
        if v != null and str(v) not in ["null", "undefined", ""]: return str(v).strip_edges()
    var sp := "res://scripts/services/secrets.gd"
    if FileAccess.file_exists(sp):
        var s = load(sp).new()
        var val = s.get(key.to_upper())
        s.free()
        if val != null and str(val) != "": return str(val).strip_edges()
    var env := OS.get_environment("GITHUB_" + key.to_upper())
    if env != "": return env.strip_edges()
    return str(ProjectSettings.get_setting("bitqbad/github/" + key, "")).strip_edges()

func is_github_enabled() -> bool: return _gh_enabled
func github_error() -> String: return _gh_error
func packages() -> Array: return PACKAGES

func _load_local() -> void:
    var cfg := ConfigFile.new()
    if cfg.load(PATH) == OK:
        var parsed = JSON.parse_string(str(cfg.get_value("data", "wallets", "{}")))
        if parsed is Dictionary: _wallets = parsed

func _save_local() -> void:
    var cfg := ConfigFile.new()
    cfg.set_value("data", "wallets", JSON.stringify(_wallets))
    cfg.save(PATH)

func clear_local() -> void:
    _wallets.clear()
    _save_local()
    wallet_updated.emit("", {})

func has_wallet(user: String) -> bool:
    return _wallets.has(user) and int(_wallets[user].get("balance", 0)) != 0

func get_wallet(user := "anon") -> Dictionary:
    if not _wallets.has(user):
        _wallets[user] = {"user": user, "balance": 0, "transactions": []}
        _save_local()
    return _wallets[user]

func set_wallet_from_remote(user: String, remote: Dictionary) -> void:
    if remote.has("wallet"):
        _wallets[user] = remote["wallet"]
        _save_local()
        wallet_updated.emit(user, _wallets[user])

func add_coins(user: String, amount: int, reason: String) -> Dictionary:
    var w: Dictionary = get_wallet(user)
    w["balance"] = int(w["balance"]) + amount
    var txs: Array = w.get("transactions", [])
    txs.append({"amount": amount, "reason": reason, "timestamp": Time.get_datetime_string_from_system()})
    if txs.size() > 50: txs = txs.slice(txs.size() - 50)
    w["transactions"] = txs
    _wallets[user] = w
    _save_local()
    wallet_updated.emit(user, w)
    _queue_sync(user, w)
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
    wallet_updated.emit(user, w)
    _queue_sync(user, w)
    return true

# Compatibilidad: la compra real ocurre en la vista "pay".
# Aqui solo se expone el paquete para que la UI lo use.
func find_package(package_id: String) -> Dictionary:
    for p in PACKAGES:
        if str(p["id"]) == package_id: return p
    return {}

func buy_package(_user: String, _package_id: String) -> void:
    push_warning("[Coins] buy_package() obsoleto: usa la vista 'pay' para comprar.")

func _queue_sync(user: String, wallet: Dictionary) -> void:
    if not _gh_enabled: return
    if _sync_busy.get(user, false): return
    _sync_busy[user] = true
    await _sync_github(user, wallet)
    _sync_busy[user] = false
    sync_finished.emit(user, true)

func _sync_github(user: String, wallet: Dictionary) -> void:
    var safe := ""
    for ch in user:
        if ch.is_valid_identifier() or ch == "-" or ch == "_" or (ch >= "0" and ch <= "9"): safe += ch
    if safe == "": safe = "anon"
    var path := "wallets/%s.json" % safe
    var sha := await _get_sha(path)
    var b64 := Marshalls.utf8_to_base64(JSON.stringify(wallet, "  "))
    var payload := {"message": "update wallet %s" % safe, "content": b64}
    if sha != "": payload["sha"] = sha
    var http := HTTPRequest.new(); add_child(http)
    var headers := PackedStringArray(["Authorization: Bearer " + _gh_token, "Accept: application/vnd.github+json", "Content-Type: application/json", "User-Agent: BitQbadPlayStore"])
    http.request("https://api.github.com/repos/%s/contents/%s" % [_gh_repo, path], headers, HTTPClient.METHOD_PUT, JSON.stringify(payload))
    await http.request_completed
    http.queue_free()

func _get_sha(path: String) -> String:
    var http := HTTPRequest.new(); add_child(http)
    var headers := PackedStringArray(["Authorization: Bearer " + _gh_token, "Accept: application/vnd.github+json", "User-Agent: BitQbadPlayStore"])
    http.request("https://api.github.com/repos/%s/contents/%s" % [_gh_repo, path], headers, HTTPClient.METHOD_GET)
    var res = await http.request_completed
    http.queue_free()
    if int(res[1]) == 200:
        var d = JSON.parse_string(res[3].get_string_from_utf8())
        if d is Dictionary: return str(d.get("sha", ""))
    return ""