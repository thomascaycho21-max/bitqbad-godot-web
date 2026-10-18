extends Control
var content_area: Container
var user_area: HBoxContainer
var nav_buttons: Dictionary = {}
var selected_app_id: String = ""
var selected_category: String = "Todas"
var selected_package_id: String = ""
var fullscreen_web: Control = null
var file_dialog: FileDialog = null
var current_edit_image_field: LineEdit = null

func _ready() -> void:
	_register_routes()
	_build_ui()
	Router.container = content_area
	Router.route_changed.connect(_on_route_changed)
	if not Session.is_logged_in():
		Coins.clear_local()
	Router.go("home")

func _register_routes() -> void:
	Router.register("home", Callable(self, "_view_home"))
	Router.register("store", Callable(self, "_view_store"))
	Router.register("reviews", Callable(self, "_view_reviews"))
	Router.register("coins", Callable(self, "_view_coins"))
	Router.register("pay", Callable(self, "_view_pay"))
	Router.register("about", Callable(self, "_view_about"))
	Router.register("app-detail", Callable(self, "_view_app_detail"))
	Router.register("login", Callable(self, "_view_login"))
	Router.register("developer", Callable(self, "_view_developer"))

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
	logo.add_child(BitTheme.label("B", 28, BitTheme.ACCENT))
	logo.add_child(BitTheme.label("BitQbad", 22, BitTheme.TEXT))
	side_vbox.add_child(logo)
	side_vbox.add_child(HSeparator.new())
	
	_add_nav(side_vbox, "home", "Inicio")
	_add_nav(side_vbox, "store", "Tienda")
	_add_nav(side_vbox, "reviews", "Resenas")
	_add_nav(side_vbox, "coins", "Monedas")
	_add_nav(side_vbox, "pay", "Pagar")
	_add_nav(side_vbox, "developer", "Desarrollador")
	_add_nav(side_vbox, "about", "Acerca de")
	
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side_vbox.add_child(spacer)
	side_vbox.add_child(BitTheme.label("v0.6.0 (Godot)", 12, BitTheme.TEXT_DIM))
	
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
	
	file_dialog = FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.add_filter("*.png, *.jpg, *.jpeg, *.ico", "Imagenes (*.png, *.jpg, *.ico)")
	file_dialog.file_selected.connect(_on_image_selected)
	add_child(file_dialog)
	
	_refresh_user_area()

func _on_image_selected(path: String) -> void:
	if current_edit_image_field == null: return
	var ext := path.get_extension().to_lower()
	var file_name := "img_" + str(Time.get_unix_time_from_system()) + "." + ext
	var dest_path := "res://assets/app_images/" + file_name
	
	var img = Image.load_from_file(path)
	if img:
		var err = img.save_png(ProjectSettings.globalize_path(dest_path)) # Guardamos como png para texturas
		if err == OK:
			current_edit_image_field.text = dest_path
			print("Imagen guardada en: ", dest_path)
		else:
			printerr("Error al guardar imagen")

func _add_nav(parent: VBoxContainer, route: String, text: String) -> void:
	if route == "developer" and not Session.is_developer():
		return
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
		if Session.is_developer():
			var dev_lbl := BitTheme.label("DEV", 12, BitTheme.WARNING)
			var dev_panel := PanelContainer.new()
			dev_panel.add_theme_stylebox_override("panel", BitTheme.stylebox(BitTheme.BG_CARD, 6, 4))
			dev_panel.add_child(dev_lbl)
			user_area.add_child(dev_panel)
		var out := BitTheme.button("Salir", false)
		out.pressed.connect(func():
			Session.logout()
			_refresh_user_area()
			Router.go("home")
		)
		user_area.add_child(out)
	else:
		var btn := BitTheme.button("Iniciar sesion", true)
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

# ================= HOME =================
func _view_home() -> Control:
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 20)
	var hero := PanelContainer.new()
	hero.add_theme_stylebox_override("panel", BitTheme.stylebox(BitTheme.ACCENT, BitTheme.RADIUS_LG, 36))
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", 10)
	hv.add_child(BitTheme.label("Bienvenido a BitQbad", 38, BitTheme.TEXT))
	hv.add_child(BitTheme.label("Tu tienda multiplataforma de apps", 18, BitTheme.TEXT))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var explore := BitTheme.button("Explorar tienda", false)
	explore.pressed.connect(func(): Router.go("store"))
	row.add_child(explore)
	var coins_btn := BitTheme.button("Comprar BitCoins", false)
	coins_btn.pressed.connect(func(): Router.go("coins"))
	row.add_child(coins_btn)
	hv.add_child(row)
	hero.add_child(hv)
	vb.add_child(hero)
	vb.add_child(BitTheme.label("Accesos rapidos", 22, BitTheme.TEXT))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	var quick := [
		["Tienda", "Explora apps", "store"],
		["Resenas", "Opiniones reales", "reviews"],
		["Monedas", "Compra o gana", "coins"],
		["Pagar", "Paga con tu metodo", "pay"],
		["Desarrollador", "Gestiona apps", "developer"],
		["Acerca de", "Sobre BitQbad", "about"]
	]
	for q in quick:
		if str(q[2]) == "developer" and not Session.is_developer():
			continue
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", BitTheme.stylebox(BitTheme.BG_CARD, BitTheme.RADIUS_MD, 18))
		card.custom_minimum_size = Vector2(0, 110)
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 6)
		cv.add_child(BitTheme.label(str(q[0]), 18, BitTheme.TEXT))
		cv.add_child(BitTheme.label(str(q[1]), 13, BitTheme.TEXT_DIM))
		var btn := Button.new()
		btn.flat = true
		btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		var target := str(q[2])
		btn.pressed.connect(func(): Router.go(target))
		card.add_child(cv)
		card.add_child(btn)
		grid.add_child(card)
	vb.add_child(grid)
	vb.add_child(BitTheme.label("Apps destacadas", 22, BitTheme.TEXT))
	var featured := HBoxContainer.new()
	featured.add_theme_constant_override("separation", 14)
	var apps: Array = StoreRepo.all()
	var count := 0
	for a in apps:
		if count >= 3:
			break
		featured.add_child(_app_card(a))
		count += 1
	vb.add_child(featured)
	return _scroll([vb])

# ================= TIENDA =================
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
	var cats_wrap := HFlowContainer.new()
	cats_wrap.add_theme_constant_override("h_separation", 8)
	cats_wrap.add_theme_constant_override("v_separation", 8)
	root.add_child(cats_wrap)
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
	var state := {"query": ""}
	var chip_buttons: Array = []
	var rebuild := func():
		for c in grid.get_children():
			c.queue_free()
		var results := StoreRepo.filter_apps(selected_category, str(state["query"]))
		for app in results:
			grid.add_child(_app_card(app))
	var set_cat := func(cat: String):
		selected_category = cat
		for pair in chip_buttons:
			var b: Button = pair[0]
			var cat_name: String = pair[1]
			b.add_theme_color_override("font_color", BitTheme.ACCENT if cat_name == cat else BitTheme.TEXT_DIM)
		rebuild.call()
	for cat in StoreRepo.categories:
		var chip := Button.new()
		chip.text = str(cat)
		chip.custom_minimum_size = Vector2(0, 34)
		chip.add_theme_color_override("font_color", BitTheme.ACCENT if cat == selected_category else BitTheme.TEXT_DIM)
		chip.add_theme_stylebox_override("normal", BitTheme.stylebox(BitTheme.BG_CARD, BitTheme.RADIUS_SM, 10))
		chip.add_theme_stylebox_override("hover", BitTheme.stylebox(BitTheme.BG_HOVER, BitTheme.RADIUS_SM, 10))
		var cat_str := str(cat)
		chip.pressed.connect(func(): set_cat.call(cat_str))
		chip_buttons.append([chip, cat_str])
		cats_wrap.add_child(chip)
	search.text_changed.connect(func(t: String):
		state["query"] = t
		rebuild.call()
	)
	rebuild.call()
	return root

func _app_card(app: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(300, 210)
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
	
	var img_path := str(app.get("image_url", ""))
	if img_path != "" and not img_path.begins_with("http") and FileAccess.file_exists(img_path):
		var img = Image.load_from_file(img_path)
		if img:
			var tex := ImageTexture.create_from_image(img)
			var tex_rect := TextureRect.new()
			tex_rect.texture = tex
			tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.add_child(tex_rect)
	else:
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
	
	var badge_row := HBoxContainer.new()
	badge_row.add_theme_constant_override("separation", 6)
	var mon: Dictionary = app.get("monetization", {})
	var mtype := str(mon.get("type", "free"))
	var badge_text := ""
	var badge_color := BitTheme.TEXT_DIM
	match mtype:
		"premium":
			badge_text = "Premium $" + str(mon.get("premium_price_usd", 0))
			badge_color = BitTheme.WARNING
		"subscription":
			badge_text = "Suscripcion"
			badge_color = BitTheme.ACCENT_2
		"freemium_donation":
			badge_text = "Donacion"
			badge_color = BitTheme.SUCCESS
		_:
			badge_text = "Gratis"
	badge_row.add_child(BitTheme.label(badge_text, 11, badge_color))
	vb.add_child(badge_row)
	
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(spacer)
	var bottom := HBoxContainer.new()
	bottom.add_child(BitTheme.label("%.1f" % float(app.get("rating", 0)), 12, BitTheme.TEXT))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(sp)
	bottom.add_child(BitTheme.label("v" + str(app.get("version", "1.0")), 12, BitTheme.TEXT_DIM))
	vb.add_child(bottom)
	
	var btn := Button.new()
	btn.flat = true
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	var aid := str(app.get("id", ""))
	btn.pressed.connect(func():
		selected_app_id = aid
		Router.go("app-detail")
	)
	card.add_child(btn)
	return card

# ================= DETALLE =================
func _view_app_detail() -> Control:
	var app := StoreRepo.by_id(selected_app_id)
	if app.is_empty():
		return BitTheme.label("App no encontrada", 16, BitTheme.DANGER)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 14)
	var back := BitTheme.button("Volver a la tienda", false)
	back.pressed.connect(func(): Router.go("store"))
	vb.add_child(back)
	var header := PanelContainer.new()
	var icon_color := BitTheme.hex(str(app.get("icon_color", "#7C4DFF")))
	header.add_theme_stylebox_override("panel", BitTheme.stylebox(icon_color, BitTheme.RADIUS_LG, 24))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 20)
	
	var img_path := str(app.get("image_url", ""))
	if img_path != "" and not img_path.begins_with("http") and FileAccess.file_exists(img_path):
		var img = Image.load_from_file(img_path)
		if img:
			var tex := ImageTexture.create_from_image(img)
			var tex_rect := TextureRect.new()
			tex_rect.custom_minimum_size = Vector2(80, 80)
			tex_rect.texture = tex
			tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			hb.add_child(tex_rect)
	else:
		hb.add_child(BitTheme.label(str(app.get("icon_emoji", "?")), 48, BitTheme.TEXT))
		
	var hv := VBoxContainer.new()
	hv.add_child(BitTheme.label(str(app.get("name", "")), 26, BitTheme.TEXT))
	hv.add_child(BitTheme.label(str(app.get("short_desc", "")), 14, BitTheme.TEXT))
	hv.add_child(BitTheme.label("%.1f - %s descargas - %s MB" % [
		float(app.get("rating", 0)),
		StoreRepo.downloads_str(int(app.get("downloads", 0))),
		str(app.get("size_mb", 0))
	], 13, BitTheme.TEXT))
	hb.add_child(hv)
	header.add_child(hb)
	vb.add_child(header)
	vb.add_child(BitTheme.label("Descargar", 15, BitTheme.TEXT))
	var dl_row := HFlowContainer.new()
	dl_row.add_theme_constant_override("h_separation", 8)
	dl_row.add_theme_constant_override("v_separation", 8)
	var platforms: Array = app.get("platforms", [])
	var archs: Dictionary = app.get("architectures", {})
	var urls: Dictionary = app.get("download_urls", {})
	var web_project := str(app.get("web_project", ""))
	for plat in platforms:
		var plat_str := str(plat)
		if plat_str == "Web" and web_project != "":
			var web_btn := BitTheme.button("Web", true)
			var app_name := str(app.get("name", ""))
			web_btn.pressed.connect(func(): _open_web_app(web_project, app_name))
			dl_row.add_child(web_btn)
			continue
		var btn := BitTheme.button(plat_str, false)
		var popup := PopupMenu.new()
		var plat_archs: Array = archs.get(plat_str, [])
		for a in plat_archs:
			popup.add_item(str(a))
		popup.id_pressed.connect(func(id: int):
			var arch := str(plat_archs[id])
			var key := plat_str + "_" + arch
			var url := str(urls.get(key, ""))
			if url == "":
				return
			if url.begins_with("res://"):
				_open_web_app(web_project, str(app.get("name", "")))
				return
			if OS.has_feature("web"):
				JavaScriptBridge.eval("window.open('" + url + "','_blank')")
			else:
				OS.shell_open(url)
		)
		btn.pressed.connect(func(): popup.position = Vector2i(btn.get_screen_position() + Vector2(0, btn.size.y)); popup.popup())
		btn.add_child(popup)
		dl_row.add_child(btn)
	vb.add_child(dl_row)
	vb.add_child(BitTheme.label("Descripcion", 15, BitTheme.TEXT))
	vb.add_child(BitTheme.label(str(app.get("long_desc", "")), 14, BitTheme.TEXT_DIM))
	
	var review_card := PanelContainer.new()
	review_card.add_theme_stylebox_override("panel", BitTheme.stylebox(BitTheme.BG_CARD, BitTheme.RADIUS_LG, 20))
	var rv := VBoxContainer.new()
	rv.add_theme_constant_override("separation", 10)
	rv.add_child(BitTheme.label("Escribe una resena", 18, BitTheme.TEXT))
	if not Session.is_logged_in():
		rv.add_child(BitTheme.label("Inicia sesion para publicar una resena.", 13, BitTheme.WARNING))
		var go_login := BitTheme.button("Iniciar sesion", true)
		go_login.pressed.connect(func(): Router.go("login"))
		rv.add_child(go_login)
	else:
		var rating_row := HBoxContainer.new()
		rating_row.add_theme_constant_override("separation", 6)
		rating_row.add_child(BitTheme.label("Puntuacion:", 13, BitTheme.TEXT_DIM))
		var rating_opt := OptionButton.new()
		for i in range(5, 0, -1):
			rating_opt.add_item(str(i) + " estrellas", i)
		rating_opt.select(0)
		rating_row.add_child(rating_opt)
		rv.add_child(rating_row)
		var title_field := LineEdit.new()
		title_field.placeholder_text = "Titulo de tu resena"
		title_field.custom_minimum_size = Vector2(0, 40)
		rv.add_child(title_field)
		var body_field := TextEdit.new()
		body_field.custom_minimum_size = Vector2(0, 100)
		body_field.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		body_field.placeholder_text = "Cuentanos tu experiencia..."
		rv.add_child(body_field)
		var status := BitTheme.label("", 12, BitTheme.TEXT_DIM)
		rv.add_child(status)
		var post := BitTheme.button("Publicar resena", true)
		var app_id := str(app.get("id", ""))
		post.pressed.connect(func():
			if not Reviews.enabled:
				status.text = "GitHub no configurado"
				status.add_theme_color_override("font_color", BitTheme.DANGER)
				return
			var body_txt := body_field.text.strip_edges()
			if title_field.text.strip_edges() == "" or body_txt == "":
				status.text = "Rellena titulo y comentario"
				status.add_theme_color_override("font_color", BitTheme.WARNING)
				return
			post.disabled = true
			status.text = "Publicando..."
			status.add_theme_color_override("font_color", BitTheme.TEXT_DIM)
			var on_ok := func(ok: bool, msg: String):
				post.disabled = false
				status.text = msg
				status.add_theme_color_override("font_color", BitTheme.SUCCESS if ok else BitTheme.DANGER)
				if ok:
					title_field.text = ""
					body_field.text = ""
					Reviews.list_reviews(app_id)
			if not Reviews.review_posted.is_connected(on_ok):
				Reviews.review_posted.connect(on_ok, CONNECT_ONE_SHOT)
			Reviews.post_review(
				app_id,
				title_field.text.strip_edges(),
				body_txt,
				int(rating_opt.get_item_id(rating_opt.selected)),
				Session.login()
			)
		)
		rv.add_child(post)
	review_card.add_child(rv)
	vb.add_child(review_card)
	
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 10)
	vb.add_child(list)
	var on_loaded := func(app_id: String, revs: Array):
		if not is_instance_valid(list):
			return
		if app_id != str(app.get("id", "")):
			return
		for c in list.get_children():
			c.queue_free()
		if revs.is_empty():
			list.add_child(BitTheme.label("Sin resenas aun. Se el primero!", 12, BitTheme.TEXT_DIM))
			return
		for r in revs:
			var rcard := PanelContainer.new()
			rcard.add_theme_stylebox_override("panel", BitTheme.stylebox(BitTheme.BG_HOVER, BitTheme.RADIUS_MD, 14))
			var rcv := VBoxContainer.new()
			rcv.add_theme_constant_override("separation", 4)
			rcv.add_child(BitTheme.label("%s - %d/5" % [str(r.get("user", "anon")), int(r.get("rating", 0))], 13, BitTheme.ACCENT_2))
			rcv.add_child(BitTheme.label(str(r.get("title", "")), 14, BitTheme.TEXT))
			rcv.add_child(BitTheme.label(str(r.get("body", "")), 12, BitTheme.TEXT_DIM))
			rcard.add_child(rcv)
			list.add_child(rcard)
	Reviews.reviews_loaded.connect(on_loaded, CONNECT_ONE_SHOT)
	Reviews.list_reviews(str(app.get("id", "")))
	return _scroll([vb])

# ================= VISOR WEB =================
func _open_web_app(project_name: String, app_name: String) -> void:
	if fullscreen_web != null and is_instance_valid(fullscreen_web):
		fullscreen_web.queue_free()
	fullscreen_web = ColorRect.new()
	fullscreen_web.color = BitTheme.BG_DARK
	fullscreen_web.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fullscreen_web)
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 0)
	fullscreen_web.add_child(vbox)
	var topbar := PanelContainer.new()
	topbar.add_theme_stylebox_override("panel", BitTheme.stylebox(BitTheme.SIDEBAR, 0, 12))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	topbar.add_child(hb)
	hb.add_child(BitTheme.label(app_name, 18, BitTheme.TEXT))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(sp)
	var back_btn := BitTheme.button("Volver a BitQbad", false)
	back_btn.pressed.connect(func():
		if OS.has_feature("web"):
			JavaScriptBridge.eval("if(window.bitqbadHideFrame)window.bitqbadHideFrame();")
		if fullscreen_web != null and is_instance_valid(fullscreen_web):
			fullscreen_web.queue_free()
			fullscreen_web = null
	)
	hb.add_child(back_btn)
	vbox.add_child(topbar)
	var web_host := Control.new()
	web_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	web_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(web_host)
	var path := "res://aplicaciones_unidas/" + project_name + "/index.html"
	if not FileAccess.file_exists(path):
		var msg := VBoxContainer.new()
		msg.set_anchors_preset(Control.PRESET_CENTER)
		msg.add_child(BitTheme.label("Proyecto web no encontrado.", 20, BitTheme.WARNING))
		msg.add_child(BitTheme.label("Coloca el build web en:", 13, BitTheme.TEXT_DIM))
		msg.add_child(BitTheme.label(path, 12, BitTheme.ACCENT_2))
		msg.add_child(BitTheme.label("O desde modo Desarrollador vincula el proyecto.", 12, BitTheme.TEXT_DIM))
		web_host.add_child(msg)
		return
	if OS.has_feature("web"):
		var js := "var f=document.getElementById('bitqbad-iframe');if(!f){f=document.createElement('iframe');f.id='bitqbad-iframe';f.style='position:fixed;top:0;left:0;width:100vw;height:100vh;border:0;z-index:9999';document.body.appendChild(f);}f.src='aplicaciones_unidas/" + project_name + "/index.html';f.style.display='block';"
		JavaScriptBridge.eval(js)
		JavaScriptBridge.eval("window.bitqbadHideFrame=function(){var f=document.getElementById('bitqbad-iframe');if(f){f.style.display='none';f.src='about:blank';}};")
		web_host.add_child(BitTheme.label("Cargando app web...", 14, BitTheme.TEXT_DIM))
	else:
		var note := VBoxContainer.new()
		note.set_anchors_preset(Control.PRESET_CENTER)
		note.add_child(BitTheme.label("El visor web solo esta disponible en la version Web.", 16, BitTheme.TEXT))
		note.add_child(BitTheme.label("En escritorio/APK descarga la app para abrirla nativa.", 13, BitTheme.TEXT_DIM))
		web_host.add_child(note)

# ================= RESENAS =================
func _view_reviews() -> Control:
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 12)
	vb.add_child(BitTheme.label("Resenas", 28, BitTheme.TEXT))
	if not Reviews.enabled:
		vb.add_child(BitTheme.label("GitHub no configurado: " + Reviews.error, 14, BitTheme.WARNING))
		return _scroll([vb])
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 12)
	vb.add_child(list)
	var on_loaded := func(grouped: Dictionary):
		if not is_instance_valid(list):
			return
		for c in list.get_children():
			c.queue_free()
		if grouped.is_empty():
			list.add_child(BitTheme.label("Sin resenas aun.", 12, BitTheme.TEXT_DIM))
			return
		for app_id in grouped.keys():
			var app := StoreRepo.by_id(str(app_id))
			var head := PanelContainer.new()
			head.add_theme_stylebox_override("panel", BitTheme.stylebox(BitTheme.BG_CARD, BitTheme.RADIUS_MD, 14))
			head.add_child(BitTheme.label("Resenas de " + str(app.get("name", app_id)), 16, BitTheme.TEXT))
			list.add_child(head)
			for r in grouped[app_id]:
				var rcard := PanelContainer.new()
				rcard.add_theme_stylebox_override("panel", BitTheme.stylebox(BitTheme.BG_HOVER, BitTheme.RADIUS_MD, 14))
				var rcv := VBoxContainer.new()
				rcv.add_theme_constant_override("separation", 4)
				rcv.add_child(BitTheme.label("%s - %d/5" % [str(r.get("user", "anon")), int(r.get("rating", 0))], 13, BitTheme.ACCENT_2))
				rcv.add_child(BitTheme.label(str(r.get("title", "")), 14, BitTheme.TEXT))
				rcv.add_child(BitTheme.label(str(r.get("body", "")), 12, BitTheme.TEXT_DIM))
				rcard.add_child(rcv)
				list.add_child(rcard)
	Reviews.all_reviews_loaded.connect(on_loaded, CONNECT_ONE_SHOT)
	Reviews.list_all_reviews()
	return _scroll([vb])

# ================= MONEDAS =================
func _view_coins() -> Control:
	var user := "anon"
	if Session.is_logged_in():
		user = Session.login()
	var w := Coins.get_wallet(user)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 14)
	vb.add_child(BitTheme.label("Monedas", 28, BitTheme.TEXT))
	var header := PanelContainer.new()
	header.add_theme_stylebox_override("panel", BitTheme.stylebox(BitTheme.ACCENT, BitTheme.RADIUS_LG, 24))
	var hv := VBoxContainer.new()
	hv.add_child(BitTheme.label("Tu cartera", 16, BitTheme.TEXT))
	var balance_label := BitTheme.label(str(w.get("balance", 0)) + " BitCoins", 44, BitTheme.TEXT)
	hv.add_child(balance_label)
	hv.add_child(BitTheme.label("Usuario: " + user, 12, BitTheme.TEXT))
	header.add_child(hv)
	vb.add_child(header)
	var on_update := func(u: String, ww: Dictionary):
		if u == user and is_instance_valid(balance_label):
			balance_label.text = str(ww.get("balance", 0)) + " BitCoins"
	Coins.wallet_updated.connect(on_update, CONNECT_ONE_SHOT)
	vb.add_child(BitTheme.label("Comprar BitCoins", 18, BitTheme.TEXT))
	var pkg_row := HFlowContainer.new()
	pkg_row.add_theme_constant_override("h_separation", 10)
	pkg_row.add_theme_constant_override("v_separation", 10)
	for p in Coins.packages():
		var pv := VBoxContainer.new()
		pv.add_theme_constant_override("separation", 4)
		pv.add_child(BitTheme.label("%d BitCoins" % int(p["coins"]), 16, BitTheme.TEXT))
		pv.add_child(BitTheme.label("$%.2f USD" % float(p["usd"]), 13, BitTheme.TEXT_DIM))
		var buy := BitTheme.button("Comprar", true)
		var pid := str(p["id"])
		buy.pressed.connect(func():
			if not Session.is_logged_in():
				Router.go("login")
				return
			selected_package_id = pid
			Router.go("pay")
		)
		pv.add_child(buy)
		pkg_row.add_child(BitTheme.card(pv))
	vb.add_child(pkg_row)
	vb.add_child(BitTheme.label("Ganar BitCoins gratis", 18, BitTheme.TEXT))
	var earn := HFlowContainer.new()
	earn.add_theme_constant_override("h_separation", 12)
	earn.add_theme_constant_override("v_separation", 8)
	for pair in [["Ver anuncio", 10], ["Compartir", 20], ["Login diario", 50]]:
		var b := BitTheme.button(str(pair[0]), true)
		var amt: int = int(pair[1])
		var reason: String = str(pair[0])
		b.pressed.connect(func():
			if not Session.is_logged_in():
				Router.go("login")
				return
			b.disabled = true
			Coins.add_coins(user, amt, reason)
			await get_tree().create_timer(1.5).timeout
			if is_instance_valid(b):
				b.disabled = false
		)
		earn.add_child(b)
	vb.add_child(earn)
	vb.add_child(BitTheme.label("Historial", 18, BitTheme.TEXT))
	var txs: Array = w.get("transactions", [])
	if txs.is_empty():
		vb.add_child(BitTheme.label("Sin movimientos aun.", 12, BitTheme.TEXT_DIM))
	else:
		var last: Array = txs.slice(max(0, txs.size() - 10))
		last.reverse()
		for t in last:
			var amt_i: int = int(t.get("amount", 0))
			var sign := "+" if amt_i >= 0 else ""
			vb.add_child(BitTheme.label(
				"%s%d - %s - %s" % [sign, amt_i, str(t.get("reason", "")), str(t.get("timestamp", "")).substr(0, 16).replace("T", " ")],
				12, BitTheme.SUCCESS if amt_i >= 0 else BitTheme.DANGER
			))
	return _scroll([vb])

# ================= PAGAR =================
func _view_pay() -> Control:
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 14)
	vb.add_child(BitTheme.label("Pagar", 28, BitTheme.TEXT))
	if not Session.is_logged_in():
		vb.add_child(BitTheme.label("Debes iniciar sesion para pagar.", 16, BitTheme.WARNING))
		var go := BitTheme.button("Iniciar sesion", true)
		go.pressed.connect(func(): Router.go("login"))
		vb.add_child(go)
		return _scroll([vb])
	var pkg: Dictionary = {}
	for p in Coins.packages():
		if str(p["id"]) == selected_package_id:
			pkg = p
			break
	if pkg.is_empty():
		vb.add_child(BitTheme.label("Elige un paquete:", 16, BitTheme.TEXT))
		var row := HFlowContainer.new()
		row.add_theme_constant_override("h_separation", 10)
		row.add_theme_constant_override("v_separation", 10)
		for p in Coins.packages():
			var b := BitTheme.button("%d BitCoins - $%.2f" % [int(p["coins"]), float(p["usd"])], false)
			var pid := str(p["id"])
			b.pressed.connect(func():
				selected_package_id = pid
				Router.go("pay")
			)
			row.add_child(b)
		vb.add_child(row)
		return _scroll([vb])
	vb.add_child(BitTheme.label("Paquete: %d BitCoins - $%.2f USD" % [int(pkg["coins"]), float(pkg["usd"])], 16, BitTheme.TEXT))
	vb.add_child(BitTheme.label("Pais:", 14, BitTheme.TEXT_DIM))
	var country_opt := OptionButton.new()
	var countries := Payments.countries()
	for c in countries:
		country_opt.add_item(str(c[0]))
	country_opt.selected = 0
	vb.add_child(country_opt)
	vb.add_child(BitTheme.label("Metodo de pago:", 14, BitTheme.TEXT_DIM))
	var gw_row := HFlowContainer.new()
	gw_row.add_theme_constant_override("h_separation", 8)
	gw_row.add_theme_constant_override("v_separation", 8)
	vb.add_child(gw_row)
	var selected_gateway := ""
	var rebuild_gw := func():
		for c in gw_row.get_children():
			c.queue_free()
		var code := str(countries[country_opt.selected][1])
		var gws := Payments.gateways_for(code)
		for g in gws:
			var b := BitTheme.button(Payments.gateway_label(str(g)), false)
			var gid := str(g)
			b.pressed.connect(func():
				selected_gateway = gid
				for cc in gw_row.get_children():
					if cc is Button:
						var bb: Button = cc
						bb.add_theme_color_override("font_color", BitTheme.ACCENT if bb.text == Payments.gateway_label(gid) else BitTheme.TEXT)
			)
			gw_row.add_child(b)
	rebuild_gw.call()
	country_opt.item_selected.connect(func(_i): rebuild_gw.call())
	var status := BitTheme.label("", 13, BitTheme.TEXT_DIM)
	vb.add_child(status)
	var confirm := BitTheme.button("Confirmar pago", true)
	confirm.pressed.connect(func():
		if selected_gateway == "":
			status.text = "Elige un metodo de pago."
			status.add_theme_color_override("font_color", BitTheme.WARNING)
			return
		confirm.disabled = true
		status.text = "Procesando pago..."
		var code := str(countries[country_opt.selected][1])
		var ok: bool = await Payments.process_purchase(Session.login(), selected_package_id, int(pkg["coins"]), float(pkg["usd"]), code, selected_gateway)
		if ok:
			Coins.add_coins(Session.login(), int(pkg["coins"]), "Compra paquete " + selected_package_id)
			status.text = "Pago exitoso. Acreditadas %d monedas." % int(pkg["coins"])
			status.add_theme_color_override("font_color", BitTheme.SUCCESS)
			selected_package_id = ""
		else:
			status.text = "Pago cancelado o pendiente."
			status.add_theme_color_override("font_color", BitTheme.WARNING)
		confirm.disabled = false
	)
	vb.add_child(confirm)
	return _scroll([vb])

func _view_about() -> Control:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	vb.add_child(BitTheme.label("Acerca de", 28, BitTheme.TEXT))
	var body := BitTheme.label("BitQbad PlayStore\nGodot 4.7.1\nWindows - Linux - macOS - Android - iOS - Web", 14, BitTheme.TEXT_DIM)
	vb.add_child(BitTheme.card(body))
	return _scroll([vb])

# ================= LOGIN =================
func _view_login() -> Control:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	vb.custom_minimum_size = Vector2(500, 0)
	vb.add_child(BitTheme.label("Iniciar sesion", 22, BitTheme.TEXT))
	vb.add_child(BitTheme.label("Usa tu token personal de GitHub o Google.", 13, BitTheme.TEXT_DIM))
	var status := BitTheme.label("", 13, BitTheme.TEXT_DIM)
	vb.add_child(status)
	vb.add_child(BitTheme.label("GitHub", 16, BitTheme.ACCENT))
	var gh_field := LineEdit.new()
	gh_field.secret = true
	gh_field.placeholder_text = "ghp_xxxxxxxxxxxxx"
	gh_field.custom_minimum_size = Vector2(0, 40)
	vb.add_child(gh_field)
	var gh_btn := BitTheme.button("Entrar con GitHub", true)
	vb.add_child(gh_btn)
	vb.add_child(BitTheme.label("Google", 16, BitTheme.ACCENT_2))
	var g_field := LineEdit.new()
	g_field.secret = true
	g_field.placeholder_text = "ya29...."
	g_field.custom_minimum_size = Vector2(0, 40)
	vb.add_child(g_field)
	var g_btn := BitTheme.button("Entrar con Google", false)
	vb.add_child(g_btn)
	var do_login := func(provider: String, token: String):
		status.text = "Validando..."
		var on_ok := func(u: Dictionary):
			Session.save_session(u)
			var suffix := " [DEV]" if u.get("role", "user") == "developer" else ""
			status.text = "Bienvenido, " + str(u.get("name", "")) + suffix
			_refresh_user_area()
			_load_remote_progress(str(u.get("login", "")))
			Router.go("home")
		var on_fail := func(m: String):
			status.text = "Error: " + m
		if not GitHubAuth.validated.is_connected(on_ok):
			GitHubAuth.validated.connect(on_ok, CONNECT_ONE_SHOT)
		if not GitHubAuth.failed.is_connected(on_fail):
			GitHubAuth.failed.connect(on_fail, CONNECT_ONE_SHOT)
		if provider == "github":
			GitHubAuth.validate_token(token)
		else:
			GitHubAuth.validate_google_token(token)
	gh_btn.pressed.connect(func(): do_login.call("github", gh_field.text))
	g_btn.pressed.connect(func(): do_login.call("google", g_field.text))
	return _scroll([vb])

func _load_remote_progress(user: String) -> void:
	if user == "":
		return
	var remote: Dictionary = await Progress.load_progress(user)
	if remote.is_empty():
		var init_wallet := {"user": user, "balance": 0, "transactions": []}
		Coins.set_wallet_from_remote(user, {"wallet": init_wallet})
		Progress.save_progress(user, {
			"user": user,
			"provider": str(Session.user.get("provider", "github")),
			"role": str(Session.user.get("role", "user")),
			"created_at": Time.get_datetime_string_from_system(),
			"last_seen": Time.get_datetime_string_from_system(),
			"wallet": init_wallet,
			"progress": {"apps_visited": [], "reviews_posted": 0, "coins_earned_total": 0, "coins_spent_total": 0}
		})
	else:
		Coins.set_wallet_from_remote(user, remote)
		remote["last_seen"] = Time.get_datetime_string_from_system()
		Progress.save_progress(user, remote)

# ================= DESARROLLADOR =================
func _view_developer() -> Control:
	if not Session.is_developer():
		var vb_denied := VBoxContainer.new()
		vb_denied.add_child(BitTheme.label("Solo el desarrollador puede acceder.", 18, BitTheme.DANGER))
		return _scroll([vb_denied])
		
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 20)
	vb.add_child(BitTheme.label("Modo Desarrollador", 28, BitTheme.WARNING))
	
	# --- CATEGORIAS ---
	var cat_panel := PanelContainer.new()
	cat_panel.add_theme_stylebox_override("panel", BitTheme.stylebox(BitTheme.BG_CARD, BitTheme.RADIUS_MD, 16))
	var cat_vb := VBoxContainer.new()
	cat_vb.add_theme_constant_override("separation", 10)
	cat_vb.add_child(BitTheme.label("Gestion de Categorias", 18, BitTheme.TEXT))
	
	var cat_row := HFlowContainer.new()
	cat_row.add_theme_constant_override("h_separation", 8)
	cat_row.add_theme_constant_override("v_separation", 8)
	for c in StoreRepo.categories:
		if str(c) == "Todas":
			continue
		var del_btn := Button.new()
		del_btn.text = str(c) + "  [X]"
		del_btn.add_theme_color_override("font_color", BitTheme.DANGER)
		var cname := str(c)
		del_btn.pressed.connect(func():
			StoreRepo.remove_category(cname)
			Router.go("developer")
		)
		cat_row.add_child(del_btn)
	cat_vb.add_child(cat_row)
	
	var add_row := HBoxContainer.new()
	add_row.add_theme_constant_override("separation", 10)
	var new_cat := LineEdit.new()
	new_cat.placeholder_text = "Nueva categoria..."
	new_cat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_row.add_child(new_cat)
	var add_cat := BitTheme.button("Anadir", true)
	add_cat.pressed.connect(func():
		StoreRepo.add_category(new_cat.text.strip_edges())
		Router.go("developer")
	)
	add_row.add_child(add_cat)
	cat_vb.add_child(add_row)
	cat_panel.add_child(cat_vb)
	vb.add_child(cat_panel)
	
	# --- EDITAR APPS ---
	vb.add_child(BitTheme.label("Editar Apps", 22, BitTheme.TEXT))
	var all_apps = StoreRepo.all()
	if all_apps.is_empty():
		vb.add_child(BitTheme.label("No hay apps cargadas (error en el JSON).", 14, BitTheme.DANGER))
		
	for app in all_apps:
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", BitTheme.stylebox(BitTheme.BG_CARD, BitTheme.RADIUS_MD, 20))
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 12)
		
		cv.add_child(BitTheme.label("ID: " + str(app.get("id", "")), 12, BitTheme.TEXT_DIM))
		cv.add_child(HSeparator.new())
		
		# Nombre y Categoria
		var row1 := HBoxContainer.new()
		row1.add_theme_constant_override("separation", 10)
		var v_name := VBoxContainer.new()
		v_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v_name.add_child(BitTheme.label("Nombre", 12, BitTheme.TEXT_DIM))
		var e_name := LineEdit.new()
		e_name.text = str(app.get("name", ""))
		v_name.add_child(e_name)
		row1.add_child(v_name)
		
		var v_cat := VBoxContainer.new()
		v_cat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v_cat.add_child(BitTheme.label("Categoria", 12, BitTheme.TEXT_DIM))
		var e_cat := LineEdit.new()
		e_cat.text = str(app.get("category", ""))
		v_cat.add_child(e_cat)
		row1.add_child(v_cat)
		cv.add_child(row1)
		
		# Descripciones
		cv.add_child(BitTheme.label("Descripcion Corta", 12, BitTheme.TEXT_DIM))
		var e_short := LineEdit.new()
		e_short.text = str(app.get("short_desc", ""))
		cv.add_child(e_short)
		
		cv.add_child(BitTheme.label("Descripcion Larga", 12, BitTheme.TEXT_DIM))
		var e_long := TextEdit.new()
		e_long.text = str(app.get("long_desc", ""))
		e_long.custom_minimum_size = Vector2(0, 80)
		cv.add_child(e_long)
		
		# Imagen
		cv.add_child(BitTheme.label("Icono / Imagen (png, jpg, ico)", 12, BitTheme.TEXT_DIM))
		var img_row := HBoxContainer.new()
		img_row.add_theme_constant_override("separation", 10)
		var e_image := LineEdit.new()
		e_image.text = str(app.get("image_url", ""))
		e_image.placeholder_text = "Ruta absoluta o res://..."
		e_image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		img_row.add_child(e_image)
		var browse_btn := BitTheme.button("Examinar...", false)
		browse_btn.pressed.connect(func():
			current_edit_image_field = e_image
			file_dialog.popup_centered(Vector2i(800, 600))
		)
		img_row.add_child(browse_btn)
		cv.add_child(img_row)
		
		# Links de descarga
		cv.add_child(HSeparator.new())
		cv.add_child(BitTheme.label("Links de Descarga", 16, BitTheme.ACCENT))
		var urls: Dictionary = app.get("download_urls", {})
		var archs: Dictionary = app.get("architectures", {})
		var url_fields := {}
		
		for plat in archs.keys():
			for arch in archs[plat]:
				var key := str(plat) + "_" + str(arch)
				var u_row := HBoxContainer.new()
				u_row.add_theme_constant_override("separation", 10)
				var lbl := BitTheme.label(key + ":", 12, BitTheme.TEXT_DIM)
				lbl.custom_minimum_size = Vector2(150, 0)
				u_row.add_child(lbl)
				var e_url := LineEdit.new()
				e_url.text = str(urls.get(key, ""))
				e_url.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				u_row.add_child(e_url)
				url_fields[key] = e_url
				cv.add_child(u_row)
				
		cv.add_child(HSeparator.new())
		var row_actions := HBoxContainer.new()
		row_actions.add_theme_constant_override("separation", 10)
		var save := BitTheme.button("Guardar Cambios", true)
		var aid := str(app.get("id", ""))
		save.pressed.connect(func():
			var new_urls := {}
			for k in url_fields.keys():
				new_urls[k] = url_fields[k].text.strip_edges()
				
			StoreRepo.update_app(aid, {
				"name": e_name.text.strip_edges(),
				"short_desc": e_short.text.strip_edges(),
				"long_desc": e_long.text.strip_edges(),
				"category": e_cat.text.strip_edges(),
				"image_url": e_image.text.strip_edges(),
				"download_urls": new_urls
			})
			Router.go("developer")
		)
		row_actions.add_child(save)
		
		var del := BitTheme.button("Eliminar App", false)
		del.pressed.connect(func():
			StoreRepo.remove_app(aid)
			Router.go("developer")
		)
		row_actions.add_child(del)
		cv.add_child(row_actions)
		
		card.add_child(cv)
		vb.add_child(card)
		
	# --- ANADIR APP ---
	var add_panel := PanelContainer.new()
	add_panel.add_theme_stylebox_override("panel", BitTheme.stylebox(BitTheme.BG_HOVER, BitTheme.RADIUS_MD, 20))
	var add_vb := VBoxContainer.new()
	add_vb.add_theme_constant_override("separation", 10)
	add_vb.add_child(BitTheme.label("Anadir nueva app", 20, BitTheme.TEXT))
	var n_id := LineEdit.new()
	n_id.placeholder_text = "ID unico (ej: com.bitqbad.nueva)"
	add_vb.add_child(n_id)
	var n_name := LineEdit.new()
	n_name.placeholder_text = "Nombre de la app"
	add_vb.add_child(n_name)
	var n_short := LineEdit.new()
	n_short.placeholder_text = "Descripcion corta"
	add_vb.add_child(n_short)
	var n_cat := LineEdit.new()
	n_cat.placeholder_text = "Categoria"
	add_vb.add_child(n_cat)
	var add_app := BitTheme.button("Crear App (se creara con links vacios)", true)
	add_app.pressed.connect(func():
		var new_app := {
			"id": n_id.text.strip_edges(),
			"name": n_name.text.strip_edges(),
			"short_desc": n_short.text.strip_edges(),
			"long_desc": "",
			"category": n_cat.text.strip_edges(),
			"version": "0.0.1",
			"size_mb": 0,
			"rating": 0,
			"downloads": 0,
			"icon_color": "#7C4DFF",
			"icon_emoji": "?",
			"image_url": "",
			"monetization": {"type": "free", "donation_url": "", "premium_price_usd": 0, "rewarded_ads": false},
			"platforms": ["Windows", "Linux", "macOS", "Android", "iOS", "Web"],
			"architectures": {
				"Windows": ["x86_64", "arm64"],
				"Linux": ["x86_64"],
				"macOS": ["arm64"],
				"Android": ["arm64-v8a"],
				"iOS": ["arm64"],
				"Web": ["wasm"]
			},
			"download_urls": {},
			"web_project": ""
		}
		StoreRepo.add_app(new_app)
		Router.go("developer")
	)
	add_vb.add_child(add_app)
	add_panel.add_child(add_vb)
	vb.add_child(add_panel)

	return _scroll([vb])
