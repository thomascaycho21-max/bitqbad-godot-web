extends Node

signal validated(user: Dictionary)
signal failed(message: String)

func validate_token(token: String) -> void:
    token = token.strip_edges()
    if token == "":
        failed.emit("Token vacio")
        return
    if not (token.begins_with("ghp_") or token.begins_with("github_pat_")):
        failed.emit("Formato invalido (debe empezar con ghp_ o github_pat_)")
        return
    var http := HTTPRequest.new()
    add_child(http)
    http.request_completed.connect(_on_response.bind(http), CONNECT_ONE_SHOT)
    var headers := PackedStringArray([
        "Authorization: Bearer " + token,
        "Accept: application/vnd.github+json",
        "User-Agent: BitQbadPlayStore"
    ])
    var err := http.request("https://api.github.com/user", headers, HTTPClient.METHOD_GET)
    if err != OK:
        failed.emit("Error de red: " + str(err))

func _on_response(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest) -> void:
    http.queue_free()
    if result != HTTPRequest.RESULT_SUCCESS:
        failed.emit("Fallo de conexion")
        return
    if code != 200:
        failed.emit("Token invalido (HTTP %d)" % code)
        return
    var data = JSON.parse_string(body.get_string_from_utf8())
    if data == null or not data.has("login"):
        failed.emit("Respuesta invalida de GitHub")
        return
    validated.emit({
        "login": str(data["login"]),
        "name": str(data.get("name", data["login"])),
        "avatar": str(data.get("avatar_url", "")),
    })