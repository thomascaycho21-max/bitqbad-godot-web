extends Node
## Sincroniza progreso con bitqbad-sesion. Autoload: Progress

const REPO := "thomascaycho21-max/bitqbad-sesion"
var _token := ""
var _enabled := false
var _queue: Dictionary = {}

func _ready() -> void:
    _token = _cfg("token")
    _enabled = _token != "" and REPO.contains("/")
    if not _enabled:
        print("[Progress] OFF (falta token o repo)")

func is_enabled() -> bool: return _enabled

func load_progress(user: String) -> Dictionary:
    if not _enabled: return {}
    var http := HTTPRequest.new(); add_child(http)
    var url := "https://api.github.com/repos/%s/contents/users/%s.json" % [REPO, _safe(user)]
    var headers := PackedStringArray(["Authorization: Bearer " + _token, "Accept: application/vnd.github+json", "User-Agent: BitQbadPlayStore"])
    http.request(url, headers, HTTPClient.METHOD_GET)
    var res = await http.request_completed
    http.queue_free()
    var code: int = res[1]
    var body: PackedByteArray = res[3]
    if code != 200: return {}
    var data = JSON.parse_string(body.get_string_from_utf8())
    if not (data is Dictionary) or not data.has("content"): return {}
    var b64: String = str(data["content"]).replace("\n", "")
    var raw := Marshalls.base64_to_utf8(b64)
    var parsed = JSON.parse_string(raw)
    return parsed if parsed is Dictionary else {}

func save_progress(user: String, data: Dictionary) -> void:
    if not _enabled: return
    if _queue.get(user, false): return
    _queue[user] = true
    await _write(user, data)
    _queue[user] = false

func _write(user: String, data: Dictionary) -> void:
    var safe := _safe(user)
    var path := "users/%s.json" % safe
    var sha := await _get_sha(path)
    var b64 := Marshalls.utf8_to_base64(JSON.stringify(data, "  "))
    var payload := {"message": "progress %s" % safe, "content": b64}
    if sha != "": payload["sha"] = sha
    var http := HTTPRequest.new(); add_child(http)
    var headers := PackedStringArray(["Authorization: Bearer " + _token, "Accept: application/vnd.github+json", "Content-Type: application/json", "User-Agent: BitQbadPlayStore"])
    http.request("https://api.github.com/repos/%s/contents/%s" % [REPO, path], headers, HTTPClient.METHOD_PUT, JSON.stringify(payload))
    await http.request_completed
    http.queue_free()

func _get_sha(path: String) -> String:
    var http := HTTPRequest.new(); add_child(http)
    var headers := PackedStringArray(["Authorization: Bearer " + _token, "Accept: application/vnd.github+json", "User-Agent: BitQbadPlayStore"])
    http.request("https://api.github.com/repos/%s/contents/%s" % [REPO, path], headers, HTTPClient.METHOD_GET)
    var res = await http.request_completed
    http.queue_free()
    if int(res[1]) == 200:
        var d = JSON.parse_string(res[3].get_string_from_utf8())
        if d is Dictionary: return str(d.get("sha", ""))
    return ""

func _safe(s: String) -> String:
    var out := ""
    for ch in s:
        if ch.is_valid_identifier() or ch == "-" or ch == "_" or (ch >= "0" and ch <= "9"): out += ch
    return out if out != "" else "anon"

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