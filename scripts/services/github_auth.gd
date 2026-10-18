extends Node

signal validated(user: Dictionary)
signal failed(message: String)

func _dev_token() -> String:
    var sp := "res://scripts/services/secrets.gd"
    if FileAccess.file_exists(sp):
        var s = load(sp).new()
        var v = s.get("DEVELOPER_TOKEN")
        s.free()
        if v != null: return str(v).strip_edges()
    return ""

func validate_token(token: String) -> void:
    token = token.strip_edges()
    if token == "":
        failed.emit("Token vacio"); return

    var http := HTTPRequest.new(); add_child(http)
    http.request_completed.connect(_on_github.bind(http, token), CONNECT_ONE_SHOT)
    var headers := PackedStringArray([
        "Authorization: Bearer " + token,
        "Accept: application/vnd.github+json",
        "User-Agent: BitQbadPlayStore",
        "X-GitHub-Api-Version: 2022-11-28"
    ])
    var err := http.request("https://api.github.com/user", headers, HTTPClient.METHOD_GET)
    if err != OK:
        failed.emit("Error de red: " + str(err))

func _on_github(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest, used_token: String) -> void:
    http.queue_free()
    if result != HTTPRequest.RESULT_SUCCESS:
        failed.emit("Fallo de conexion"); return
    if code == 401:
        var msg := body.get_string_from_utf8()
        failed.emit("Token invalido o sin permisos (401). " + msg.substr(0, 120)); return
    if code == 403:
        failed.emit("Token bloqueado o rate-limit (403)"); return
    if code != 200:
        failed.emit("Token invalido (HTTP %d)" % code); return
    var data = JSON.parse_string(body.get_string_from_utf8())
    if data == null or not data.has("login"):
        failed.emit("Respuesta invalida de GitHub"); return
    
    # VERIFICACION ESTRICTA
    var role := "user"
    var d_token := _dev_token()
    if d_token != "" and used_token == d_token:
        role = "developer"
        
    validated.emit({
        "login": str(data["login"]),
        "name": str(data.get("name", data["login"])),
        "avatar": str(data.get("avatar_url", "")),
        "provider": "github",
        "role": role,
    })

func validate_google_token(access_token: String) -> void:
    access_token = access_token.strip_edges()
    if access_token == "":
        failed.emit("Token de Google vacio"); return
    var http := HTTPRequest.new(); add_child(http)
    http.request_completed.connect(_on_google.bind(http), CONNECT_ONE_SHOT)
    var headers := PackedStringArray(["Authorization: Bearer " + access_token, "Accept: application/json", "User-Agent: BitQbadPlayStore"])
    var err := http.request("https://www.googleapis.com/oauth2/v3/userinfo", headers, HTTPClient.METHOD_GET)
    if err != OK:
        failed.emit("Error de red Google: " + str(err))

func _on_google(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest) -> void:
    http.queue_free()
    if result != HTTPRequest.RESULT_SUCCESS:
        failed.emit("Fallo de conexion Google"); return
    if code != 200:
        failed.emit("Token Google invalido (HTTP %d)" % code); return
    var data = JSON.parse_string(body.get_string_from_utf8())
    if data == null or not data.has("sub"):
        failed.emit("Respuesta invalida de Google"); return
    var email := str(data.get("email", ""))
    var name := str(data.get("name", email))
    var login := email.split("@")[0] if email != "" else "google_" + str(data["sub"]).substr(0, 8)
    validated.emit({
        "login": login,
        "name": name,
        "avatar": str(data.get("picture", "")),
        "provider": "google",
        "email": email,
        "role": "user",
    })