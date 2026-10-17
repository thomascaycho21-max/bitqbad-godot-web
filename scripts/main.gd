extends Control
## Entry point: sidebar + header + router content

var content_area: Container
var user_area: HBoxContainer
var nav_buttons: Dictionary = {}
var selected_app_id: String = ""

func _ready() -> void:
	_register_routes()
	_build_ui()
	Router.container = content_area
	Router.route_changed.connect(_on_route_changed)
	Router.go("home")

func _register_routes() -> void:
	Router.register("home", Callable(self, "_view_home"))
	Router.register("store", Callable(self, "_view_store"))
	Router.register("reviews", Callable(self, "_view_reviews"))
	Router.register("coins", Callable(self, "_view_coins"))
	Router.register("about", Callable(self, "_view_about"))
	Router.register("app-detail", Callable(self, "_view_app_detail"))
	Router.register("login", Callable(self, "_view_login"))

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = BitTheme.BG_DARK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var root := HBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	# ---------- Sidebar ----------
	var sidebar := PanelContainer.new()
	sidebar.custom_minimum_size = Vector2(230, 0)
	sidebar.add_theme_stylebox_override("panel", BitTheme.stylebox(BitTheme.SIDEBAR, 0, 0))
	root.add_child(sidebar)

	var side_wrap := MarginContainer.new()
	side_wrap.add_theme_constant_override("margin_left", 12)
	side_wrap.add_theme_constant_override("margin_right", 12)
	side_wrap.add_theme_constant_override("margin_top", 20)
	side_wrap.add_theme_constant_override("margin_bottom", 20)
	sidebar.add_child(side_wrap)

	var side_vbox := VBoxContainer.new()
	side_vbox.add_theme_constant_override("separation", 6)
	side_wrap.add_child(side_vbox)

	var logo := HBoxContainer.new()
	logo.add_theme_constant_override("separation", 8)
	var logo_icon := BitTheme.label("B", 28, BitTheme.ACCENT)
	logo.add_child(logo_icon)
	var logo_text := BitTheme.label("BitQbad", 22, BitTheme.TEXT)
	logo.add_child(logo_text)
	side_vbox.add_child(logo)
	side_vbox.add_child(HSeparator.new())

	_add_nav(side_vbox, "home", "Inicio")
	_add_nav(side_vbox, "store", "Tienda")
	_add_nav(side_vbox, "reviews", "Reseñas")
	_add_nav(side_vbox, "coins", "Monedas")
	_add_nav(side_vbox, "about", "Acerca de")

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side_vbox.add_child(spacer)
	side_vbox.add_child(BitTheme.label("v0.1.6 (Godot)", 12, BitTheme.TEXT_DIM))

	# ---------- Right ----------
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 0)
	root.add_child(right)

	var header := PanelContainer.new()
	header.add_theme_stylebox_override("panel", BitTheme.stylebox(BitTheme.BG_DARK, 0, 12))
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	header.add_child(hbox)
	hbox.add_child(BitTheme.label("BitQbad PlayStore", 18, BitTheme.TEXT))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(sp)
	user_area = HBoxContainer.new()
	user_area.add_theme_constant_override("separation", 10)
	hbox.add_child(user_area)
	right.add_child(header)
	right.add_child(HSeparator.new())

	content_area = PanelContainer.new()
	content_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_area.add_theme_stylebox_override("panel", BitTheme.stylebox(BitTheme.BG_DARK, 0, 0))
	var cm := MarginContainer.new()
	cm.add_theme_constant_override("margin_left", 24)
	cm.add_theme_constant_override("margin_right", 24)
	cm.add_theme_constant_override("margin_top", 24)
	cm.add_theme_constant_override("margin_bottom", 24)
	content_area.add_child(cm)
	right.add_child(content_area)

	_refresh_user_area()

func _add_nav(parent: VBoxContainer, route: String, text: String) -> void:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(0, 44)
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_color_override("font_color", BitTheme.TEXT_DIM)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color.TRANSPARENT
	sb.corner_radius_top_left = BitTheme.RADIUS_MD
	sb.corner_radius_top_right = BitTheme.RADIUS_MD
	sb.corner_radius_bottom_left = BitTheme.RADIUS_MD
	sb.corner_radius_bottom_right = BitTheme.RADIUS_MD
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	b.add_theme_stylebox_override("normal", sb)
	var sbh := sb.duplicate() as StyleBoxFlat
	sbh.bg_color = BitTheme.BG_HOVER
	b.add_theme_stylebox_override("hover", sbh)
	b.pressed.connect(func(): Router.go(route))
	nav_buttons[route] = b
	parent.add_child(b)

func _on_route_changed(name: String) -> void:
	var active := "store" if name == "app-detail" else name
	for k in nav_buttons.keys():
		var b: Button = nav_buttons[k]
		b.add_theme_color_override("font_color", BitTheme.ACCENT if k == active else BitTheme.TEXT_DIM)

func _refresh_user_area() -> void:
	for c in user_area.get_children():
		c.queue_free()
	if Session.is_logged_in():
		var name_txt := str(Session.user.get("name", Session.user.get("login", "user")))
		user_area.add_child(BitTheme.label(name_txt, 14, BitTheme.TEXT))
		var out := BitTheme.button("Salir", false)
		out.pressed.connect(func():
			Session.logout()
			_refresh_user_area()
		)
		user_area.add_child(out)
	else:
		var btn := BitTheme.button("Iniciar sesión", true)
		btn.pressed.connect(func(): Router.go("login"))
		user_area.add_child(btn)

func _scroll(children: Array) -> Control:
	var sc := ScrollContainer.new()
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 14)
	for c in children:
		vb.add_child(c)
	sc.add_child(vb)
	return sc

# ----------------- VIEWS -----------------
func _view_home() -> Control:
	var hero := PanelContainer.new()
	hero.add_theme_stylebox_override("panel", BitTheme.stylebox(BitTheme.ACCENT, BitTheme.RADIUS_LG, 30))
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", 8)
	hv.add_child(BitTheme.label("Bienvenido a BitQbad", 32, BitTheme.TEXT))
	hv.add_child(BitTheme.label("Tu tienda de apps multiplataforma", 16, BitTheme.TEXT))
	var explore := BitTheme.button("Explorar tienda", false)
	explore.pressed.connect(func(): Router.go("store"))
	hv.add_child(explore)
	hero.add_child(hv)

	var features := HBoxContainer.new()
	features.add_theme_constant_override("separation", 16)
	for pair in [["Descubrir", "Apps para todas las plataformas"], ["Reseñar", "Comparte tu opinion"], ["Ganar monedas", "Vi ads y comparte"]]:
		var fv := VBoxContainer.new()
		fv.add_theme_constant_override("separation", 6)
		fv.add_child(BitTheme.label(str(pair[0]), 18, BitTheme.TEXT))
		fv.add_child(BitTheme.label(str(pair[1]), 13, BitTheme.TEXT_DIM))
		features.add_child(BitTheme.card(fv))

	return _scroll([hero, BitTheme.label("¿Qué puedes hacer?", 20, BitTheme.TEXT), features])

func _view_store() -> Control:
	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 12)
	root.add_child(BitTheme.label("Tienda", 28, BitTheme.TEXT))

	var search := LineEdit.new()
	search.placeholder_text = "Buscar apps..."
	search.custom_minimum_size = Vector2(0, 40)
	root.add_child(search)

	var cats_row := HBoxContainer.new()
	cats_row.add_theme_constant_override("separation", 8)
	root.add_child(cats_row)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	scroll.add_child(grid)

	var current_cat := "Todas"
	var current_query := ""

	var rebuild := func():
		for c in grid.get_children():
			c.queue_free()
		var results := StoreRepo.filter_apps(current_cat, current_query)
		for app in results:
			grid.add_child(_app_card(app))

	var set_cat := func(cat: String, chip: Button):
		current_cat = cat
		for cc in cats_row.get_children():
			if cc is Button:
				var b: Button = cc
				b.add_theme_color_override("font_color", BitTheme.TEXT if b == chip else BitTheme.TEXT_DIM)
		rebuild.call()

	for cat in StoreRepo.categories:
		var chip := Button.new()
		chip.text = str(cat)
		chip.custom_minimum_size = Vector2(0, 34)
		chip.add_theme_color_override("font_color", BitTheme.ACCENT if cat == "Todas" else BitTheme.TEXT_DIM)
		chip.add_theme_stylebox_override("normal", BitTheme.stylebox(BitTheme.BG_CARD, BitTheme.RADIUS_SM, 10))
		chip.add_theme_stylebox_override("hover", BitTheme.stylebox(BitTheme.BG_HOVER, BitTheme.RADIUS_SM, 10))
		chip.pressed.connect(func(): set_cat.call(cat, chip))
		cats_row.add_child(chip)

	search.text_changed.connect(func(t: String):
		current_query = t
		rebuild.call()
	)
	rebuild.call()
	return root

func _app_card(app: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(300, 190)
	card.add_theme_stylebox_override("panel", BitTheme.stylebox(BitTheme.BG_CARD, BitTheme.RADIUS_MD, 16))

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	card.add_child(vb)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	vb.add_child(top)

	var icon := PanelContainer.new()
	icon.custom_minimum_size = Vector2(56, 56)
	var icon_color := BitTheme.hex(str(app.get("icon_color", "#7C4DFF")))
	icon.add_theme_stylebox_override("panel", BitTheme.stylebox(icon_color, 14, 0))
	var ic := BitTheme.label(str(app.get("icon_emoji", "?")), 24, BitTheme.TEXT)
	ic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ic.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.add_child(ic)
	top.add_child(icon)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(BitTheme.label(str(app.get("name", "")), 15, BitTheme.TEXT))
	info.add_child(BitTheme.label(str(app.get("category", "")), 12, BitTheme.TEXT_DIM))
	top.add_child(info)

	vb.add_child(BitTheme.label(str(app.get("short_desc", "")), 12, BitTheme.TEXT_DIM))

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(spacer)

	var bottom := HBoxContainer.new()
	bottom.add_child(BitTheme.label("⭐ %.1f" % float(app.get("rating", 0)), 12, BitTheme.TEXT))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(sp)
	bottom.add_child(BitTheme.label("v" + str(app.get("version", "1.0")), 12, BitTheme.TEXT_DIM))
	vb.add_child(bottom)

	var btn := Button.new()
	btn.flat = true
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.pressed.connect(func():
		selected_app_id = str(app.get("id", ""))
		Router.go("app-detail")
	)
	card.add_child(btn)
	return card

func _view_app_detail() -> Control:
	var app := StoreRepo.by_id(selected_app_id)
	if app.is_empty():
		return BitTheme.label("App no encontrada", 16, BitTheme.DANGER)

	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 14)

	var back := BitTheme.button("← Volver a la tienda", false)
	back.pressed.connect(func(): Router.go("store"))
	vb.add_child(back)

	var header := PanelContainer.new()
	var icon_color := BitTheme.hex(str(app.get("icon_color", "#7C4DFF")))
	header.add_theme_stylebox_override("panel", BitTheme.stylebox(icon_color, BitTheme.RADIUS_LG, 24))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 20)
	hb.add_child(BitTheme.label(str(app.get("icon_emoji", "?")), 48, BitTheme.TEXT))
	var hv := VBoxContainer.new()
	hv.add_child(BitTheme.label(str(app.get("name", "")), 26, BitTheme.TEXT))
	hv.add_child(BitTheme.label(str(app.get("short_desc", "")), 14, BitTheme.TEXT))
	hv.add_child(BitTheme.label("⭐ %.1f · %s descargas · %s MB" % [
		float(app.get("rating", 0)),
		StoreRepo.downloads_str(int(app.get("downloads", 0))),
		str(app.get("size_mb", 0))
	], 13, BitTheme.TEXT))
	hb.add_child(hv)
	header.add_child(hb)
	vb.add_child(header)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var dl := BitTheme.button("Descargar", true)
	dl.pressed.connect(func(): OS.shell_open(str(app.get("download_url", ""))))
	var gh := BitTheme.button("GitHub", false)
	gh.pressed.connect(func(): OS.shell_open(str(app.get("repo_url", ""))))
	row.add_child(dl)
	row.add_child(gh)
	vb.add_child(row)

	vb.add_child(BitTheme.label("Descripción", 15, BitTheme.TEXT))
	vb.add_child(BitTheme.label(str(app.get("long_desc", "")), 14, BitTheme.TEXT_DIM))

	# ----- Formulario de reseña -----
	vb.add_child(BitTheme.label("Escribe una reseña", 15, BitTheme.TEXT))

	var name_field := LineEdit.new()
	name_field.placeholder_text = "Tu nombre (anon)"
	name_field.text = "anon"
	name_field.custom_minimum_size = Vector2(200, 36)
	vb.add_child(name_field)

	var rating_opt := OptionButton.new()
	for i in range(5, 0, -1):
		rating_opt.add_item("%d ⭐" % i, i)
	rating_opt.select(0)
	vb.add_child(rating_opt)

	var title_field := LineEdit.new()
	title_field.placeholder_text = "Título"
	title_field.custom_minimum_size = Vector2(0, 36)
	vb.add_child(title_field)

	var body_field := TextEdit.new()
	body_field.custom_minimum_size = Vector2(0, 100)
	body_field.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	body_field.placeholder_text = "Comentario"
	vb.add_child(body_field)

	var status := BitTheme.label("", 12, BitTheme.TEXT_DIM)
	vb.add_child(status)

	var post := BitTheme.button("Publicar reseña", true)
	post.pressed.connect(func():
		if not Reviews.enabled:
			status.text = "GitHub no configurado"
			status.add_theme_color_override("font_color", BitTheme.DANGER)
			return
		var body_txt := body_field.text.strip_edges()
		if title_field.text.strip_edges() == "" or body_txt == "":
			status.text = "Rellena título y comentario"
			status.add_theme_color_override("font_color", BitTheme.WARNING)
			return
		var on_ok := func(ok: bool, msg: String):
			status.text = msg
			status.add_theme_color_override("font_color", BitTheme.SUCCESS if ok else BitTheme.DANGER)
			if ok:
				title_field.text = ""
				body_field.text = ""
		if not Reviews.review_posted.is_connected(on_ok):
			Reviews.review_posted.connect(on_ok, CONNECT_ONE_SHOT)
		Reviews.post_review(
			str(app.get("id", "")),
			title_field.text.strip_edges(),
			body_txt,
			int(rating_opt.get_item_id(rating_opt.selected)),
			name_field.text.strip_edges()
		)
	)
	vb.add_child(post)

	# ----- Lista de reseñas -----
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 10)
	vb.add_child(list)

	Reviews.reviews_loaded.connect(func(app_id: String, revs: Array):
		if not is_instance_valid(list):
			return
		if app_id != str(app.get("id", "")):
			return
		for c in list.get_children():
			c.queue_free()
		if revs.is_empty():
			list.add_child(BitTheme.label("Sin reseñas aún. ¡Sé el primero!", 12, BitTheme.TEXT_DIM))
			return
		for r in revs:
			var rv := VBoxContainer.new()
			rv.add_theme_constant_override("separation", 4)
			rv.add_child(BitTheme.label("%s · %d/5" % [str(r.get("user", "anon")), int(r.get("rating", 0))], 13, BitTheme.ACCENT_2))
			rv.add_child(BitTheme.label(str(r.get("title", "")), 14, BitTheme.TEXT))
			rv.add_child(BitTheme.label(str(r.get("body", "")), 12, BitTheme.TEXT_DIM))
			list.add_child(BitTheme.card(rv))
	)
	Reviews.list_reviews(str(app.get("id", "")))

	return _scroll([vb])

func _view_reviews() -> Control:
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 12)
	vb.add_child(BitTheme.label("Reseñas", 28, BitTheme.TEXT))
	if not Reviews.enabled:
		vb.add_child(BitTheme.label("GitHub no configurado: " + Reviews.error, 14, BitTheme.WARNING))
		return _scroll([vb])
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 10)
	vb.add_child(list)

	Reviews.reviews_loaded.connect(func(app_id: String, revs: Array):
		if not is_instance_valid(list):
			return
		if revs.is_empty():
			return
		var app := StoreRepo.by_id(app_id)
		list.add_child(BitTheme.label("Reseñas de " + str(app.get("name", app_id)), 16, BitTheme.TEXT))
		for r in revs:
			var rv := VBoxContainer.new()
			rv.add_theme_constant_override("separation", 4)
			rv.add_child(BitTheme.label("%s · %d/5" % [str(r.get("user", "anon")), int(r.get("rating", 0))], 13, BitTheme.ACCENT_2))
			rv.add_child(BitTheme.label(str(r.get("title", "")), 14, BitTheme.TEXT))
			rv.add_child(BitTheme.label(str(r.get("body", "")), 12, BitTheme.TEXT_DIM))
			list.add_child(BitTheme.card(rv))
	)

	for app in StoreRepo.all():
		Reviews.list_reviews(str(app.get("id", "")))
	return _scroll([vb])

func _view_coins() -> Control:
	var user := "anon"
	if Session.is_logged_in():
		user = str(Session.user.get("login", "anon"))
	var w := Coins.get_wallet(user)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 14)
	vb.add_child(BitTheme.label("Monedas", 28, BitTheme.TEXT))

	var header := PanelContainer.new()
	header.add_theme_stylebox_override("panel", BitTheme.stylebox(BitTheme.ACCENT, BitTheme.RADIUS_LG, 24))
	var hv := VBoxContainer.new()
	hv.add_child(BitTheme.label("Tu cartera", 16, BitTheme.TEXT))
	hv.add_child(BitTheme.label(str(w.get("balance", 0)) + " monedas", 44, BitTheme.TEXT))
	hv.add_child(BitTheme.label("Usuario: " + user, 12, BitTheme.TEXT))
	var sync_txt := "GitHub: ACTIVO" if Coins.is_github_enabled() else "GitHub: OFF (" + Coins.github_error() + ")"
	hv.add_child(BitTheme.label(sync_txt, 12, BitTheme.SUCCESS if Coins.is_github_enabled() else BitTheme.WARNING))
	header.add_child(hv)
	vb.add_child(header)

	vb.add_child(BitTheme.label("Gana monedas", 18, BitTheme.TEXT))
	var earn := HBoxContainer.new()
	earn.add_theme_constant_override("separation", 12)
	for pair in [["Ver anuncio", 10], ["Compartir", 20], ["Suscribirse", 50]]:
		var b := BitTheme.button(str(pair[0]), true)
		var amt: int = int(pair[1])
		var reason: String = str(pair[0])
		b.pressed.connect(func():
			Coins.add_coins(user, amt, reason)
			Router.go("coins")
		)
		earn.add_child(b)
	vb.add_child(earn)

	# Historial
	vb.add_child(BitTheme.label("Historial", 18, BitTheme.TEXT))
	var txs: Array = w.get("transactions", [])
	if txs.is_empty():
		vb.add_child(BitTheme.label("Sin movimientos aún.", 12, BitTheme.TEXT_DIM))
	else:
		var last: Array = txs.slice(max(0, txs.size() - 10))
		last.reverse()
		for t in last:
			var amt_i: int = int(t.get("amount", 0))
			var sign := "+" if amt_i >= 0 else ""
			vb.add_child(BitTheme.label(
				"%s%d · %s · %s" % [sign, amt_i, str(t.get("reason", "")), str(t.get("timestamp", "")).substr(0, 16).replace("T", " ")],
				12, BitTheme.SUCCESS if amt_i >= 0 else BitTheme.DANGER
			))

	return _scroll([vb])

func _view_about() -> Control:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	vb.add_child(BitTheme.label("Acerca de", 28, BitTheme.TEXT))
	var body := BitTheme.label("BitQbad PlayStore\nGodot 4.7.1\nWindows · Linux · macOS · Android · iOS · Web", 14, BitTheme.TEXT_DIM)
	vb.add_child(BitTheme.card(body))
	return _scroll([vb])

func _view_login() -> Control:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	vb.custom_minimum_size = Vector2(500, 0)
	vb.add_child(BitTheme.label("Iniciar sesión con GitHub", 22, BitTheme.TEXT))
	vb.add_child(BitTheme.label("Pega tu token personal (ghp_...)", 13, BitTheme.TEXT_DIM))
	var field := LineEdit.new()
	field.secret = true
	field.placeholder_text = "ghp_xxxxxxxxxxxxx"
	field.custom_minimum_size = Vector2(0, 40)
	vb.add_child(field)
	var status := BitTheme.label("", 13, BitTheme.TEXT_DIM)
	vb.add_child(status)
	var btn := BitTheme.button("Entrar", true)
	vb.add_child(btn)

	btn.pressed.connect(func():
		status.text = "Validando..."
		var on_ok := func(u: Dictionary):
			Session.save_session(u)
			status.text = "Bienvenido, " + str(u.get("name", ""))
			_refresh_user_area()
			Router.go("home")
		var on_fail := func(m: String):
			status.text = "Error: " + m
		if not GitHubAuth.validated.is_connected(on_ok):
			GitHubAuth.validated.connect(on_ok, CONNECT_ONE_SHOT)
		if not GitHubAuth.failed.is_connected(on_fail):
			GitHubAuth.failed.connect(on_fail, CONNECT_ONE_SHOT)
		GitHubAuth.validate_token(field.text)
	)
	return _scroll([vb])
