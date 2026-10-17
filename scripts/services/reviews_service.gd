extends Node
## Reseñas usando GitHub Issues.

signal reviews_loaded(app_id: String, reviews: Array)
signal review_posted(ok: bool, message: String)

var enabled := false
var error := ""

func _ready() -> void:
    var token := _cfg("token")
    var repo := _cfg("repo")
    if token == "":
        error = "Falta GITHUB_TOKEN"
        return
    if repo == "" or not repo.contains("/"):
        error = "Falta GITHUB_REPO (usuario/repo)"
        return
    enabled = true

func _cfg(key: String) -> String:
    var env := OS.get_environment("GITHUB_" + key.to_upper())
    if env != "": return env.strip_edges()
    if OS.has_feature("web"):
        var js_code = "new URLSearchParams(window.location.search).get('" + key + "')"
        var url_val = JavaScriptBridge.eval(js_code)
        if url_val != null and str(url_val) != "null" and str(url_val) != "": return str(url_val).strip_edges()
    return str(ProjectSettings.get_setting("bitqbad/github/" + key, "")).strip_edges()

func list_reviews(app_id: String) -> void:
    if not enabled:
        reviews_loaded.emit(app_id, [])
        return
    var http := HTTPRequest.new()
    add_child(http)
    http.request_completed.connect(_on_list.bind(app_id, http), CONNECT_ONE_SHOT)
    var label := _cfg("review_label")
    if label == "": label = "review"
    var url := "https://api.github.com/repos/%s/issues?state=all&labels=%s&per_page=100" % [_cfg("repo"), label]
    var headers := PackedStringArray(["Authorization: Bearer " + _cfg("token"), "Accept: application/vnd.github+json", "User-Agent: BitQbadPlayStore"])
    http.request(url, headers, HTTPClient.METHOD_GET)

func _on_list(result: int, code: int, _h: PackedStringArray, body: PackedByteArray, app_id: String, http: HTTPRequest) -> void:
    http.queue_free()
    if result != HTTPRequest.RESULT_SUCCESS or code != 200:
        reviews_loaded.emit(app_id, [])
        return
    var arr = JSON.parse_string(body.get_string_from_utf8())
    if not (arr is Array):
        reviews_loaded.emit(app_id, [])
        return
    var out: Array = []
    for issue in arr:
        if not (issue is Dictionary): continue
        if issue.has("pull_request"): continue
        var title := str(issue.get("title", ""))
        if not title.begins_with("review:" + app_id): continue
        out.append(_parse_issue(issue, app_id))
    reviews_loaded.emit(app_id, out)

func _parse_issue(issue: Dictionary, app_id: String) -> Dictionary:
    var title := str(issue.get("title", ""))
    var prefix := "review:" + app_id + " ::"
    var real_title := title
    if title.begins_with(prefix): real_title = title.substr(prefix.length()).strip_edges()
    var body := str(issue.get("body", ""))
    var rating := 0
    var user := "anon"
    var re := RegEx.new()
    re.compile("<!--\\s*meta:\\s*(\\{.*?\\})\\s*-->")
    var m := re.search(body)
    if m:
        var meta = JSON.parse_string(m.get_string(1))
        if meta is Dictionary:
            rating = int(meta.get("rating", 0))
            user = str(meta.get("user", user))
        body = body.replace(m.get_string(0), "").strip_edges()
    return {"id": issue.get("number", 0), "app_id": app_id, "user": user, "rating": rating, "title": real_title, "body": body, "created_at": str(issue.get("created_at", "")), "url": str(issue.get("html_url", "")),}

func post_review(app_id: String, title: String, body: String, rating: int, user := "anon") -> void:
    if not enabled:
        review_posted.emit(false, error)
        return
    var label := _cfg("review_label")
    if label == "": label = "review"
    var meta := JSON.stringify({"rating": rating, "user": user})
    var full_body := "<!-- meta: %s -->\n\n**App:** `%s`\n**Rating:** %d/5\n\n---\n\n%s\n" % [meta, app_id, rating, body]
    var payload := JSON.stringify({"title": "review:%s :: %s" % [app_id, title], "body": full_body, "labels": [label]})
    var http := HTTPRequest.new()
    add_child(http)
    http.request_completed.connect(_on_post.bind(http), CONNECT_ONE_SHOT)
    var headers := PackedStringArray(["Authorization: Bearer " + _cfg("token"), "Accept: application/vnd.github+json", "Content-Type: application/json", "User-Agent: BitQbadPlayStore"])
    http.request("https://api.github.com/repos/%s/issues" % _cfg("repo"), headers, HTTPClient.METHOD_POST, payload)

func _on_post(result: int, code: int, _h: PackedStringArray, _b: PackedByteArray, http: HTTPRequest) -> void:
    http.queue_free()
    if result == HTTPRequest.RESULT_SUCCESS and (code == 201 or code == 200):
        review_posted.emit(true, "Reseña publicada")
    else:
        review_posted.emit(false, "Error HTTP %d" % code)