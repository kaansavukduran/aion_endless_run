extends Node2D

const World = preload("res://scripts/world.gd")
const Words = preload("res://scripts/text.gd")
const SHEET = preload("res://assets/aion-runner.png")
const FONT = preload("res://assets/Lexend.ttf")
const COMPANION_SHEET = preload("res://assets/companions-runner.png")
const COMPANION_BASELINES := [[207,208,208,190,209,207],[201,206,202,187,204,203],[196,198,196,183,196,196],[200,191,165,150,178,199],[203,190,172,150,180,202],[185,166,160,151,160,181]]
const COMPANION_RUN_ROWS := {"wolf":0,"sheep":1,"owl":2}
const NAMES := {"aion":"Aion", "owl":"Baykuş Ömer", "wolf":"Accursed Wise Wolf", "sheep":"Blessed Ignorant Sheep"}
const FRIENDS := ["aion", "owl", "wolf", "sheep"]
const COLORS := [Color("f4a7cd"), Color("ffca84"), Color("b8baf0"), Color("b8ebd3")]
var world := World.new()
var language := "tr"
var character := "aion"
var best := 0
var best_at_start := 0
var audio_enabled := true
var motion := true
var volume := 0.45
var fullscreen := false
var page := "main"
var return_page := "main"
var menu_layer: Control
var ui: Control
var hud: Control
var score_label: Label
var best_label: Label
var biome_label: Label
var crystal_label: Label
var progress: ProgressBar
var footer_label: Label
var notice_label: Label
var pause_button: Button
var friend_sprite: Sprite2D
var followers: Array[Sprite2D] = []
var sheep_collectible: Sprite2D
var friend_row := 0
var friend_frame := 0
var friend_character := ""
var jump_sources := {}
var boost_sources := {}
var ability_label: Label
var last_event := 0
var notice := ""
var notice_time := 0.0
var menu_clock := 0.0
var particles: Array[Dictionary] = []
var save_failed := false
var finished_panel := false
var player_sound: AudioStreamPlayer
var layout_size := Vector2.ZERO
var view_w := 1152.0
var view_h := 648.0
var ground := 493.0
var ui_theme: Theme
var portrait := false
var web_stamp := ""

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("0a1222"))
	load_settings()
	for i in 2:
		followers.append(make_companion_sprite())
	sheep_collectible = make_companion_sprite()
	friend_sprite = make_companion_sprite()
	player_sound = AudioStreamPlayer.new()
	add_child(player_sound)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(ui)
	build_theme()
	ui.theme = ui_theme
	get_viewport().size_changed.connect(rebuild)
	get_tree().auto_accept_quit = false
	apply_fullscreen()
	rebuild()

func make_companion_sprite() -> Sprite2D:
	var item := Sprite2D.new()
	item.texture = COMPANION_SHEET
	item.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	item.region_enabled = true
	item.region_filter_clip_enabled = true
	item.centered = false
	var material := ShaderMaterial.new()
	material.shader = preload("res://scripts/companion_alpha.gdshader")
	item.material = material
	add_child(item)
	return item

func text(key: String) -> String:
	return Words.get_text(language, key)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	language = "en" if OS.get_locale_language() == "en" else "tr"
	if cfg.load("user://save.cfg") != OK:
		return
	language = str(cfg.get_value("prefs", "language", language))
	if language not in ["tr", "en"]:
		language = "tr"
	character = str(cfg.get_value("prefs", "character", "aion"))
	if character not in FRIENDS:
		character = "aion"
	best = maxi(0, int(cfg.get_value("records", "best", 0)))
	audio_enabled = bool(cfg.get_value("prefs", "audio", true))
	motion = bool(cfg.get_value("prefs", "motion", true))
	volume = clampf(float(cfg.get_value("prefs", "volume", 0.45)), 0.0, 1.0)
	fullscreen = bool(cfg.get_value("prefs", "fullscreen", false))

func save_settings() -> void:
	best = maxi(best, world.score)
	var cfg := ConfigFile.new()
	cfg.set_value("prefs", "language", language)
	cfg.set_value("prefs", "character", character)
	cfg.set_value("prefs", "audio", audio_enabled)
	cfg.set_value("prefs", "motion", motion)
	cfg.set_value("prefs", "volume", volume)
	cfg.set_value("prefs", "fullscreen", fullscreen)
	cfg.set_value("records", "best", best)
	var result := cfg.save("user://save.tmp")
	if result == OK:
		result = DirAccess.rename_absolute("user://save.tmp", "user://save.cfg")
	save_failed = result != OK

func box(bg: String, border: String = "2d3c57", radius: int = 16) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(bg)
	style.border_color = Color(border)
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 13
	style.content_margin_bottom = 13
	return style

func build_theme() -> void:
	ui_theme = Theme.new()
	ui_theme.default_font = FONT
	ui_theme.default_font_size = 17
	ui_theme.set_color("font_color", "Label", Color("eef3ff"))
	ui_theme.set_color("font_color", "Button", Color("e5eafa"))
	ui_theme.set_color("font_hover_color", "Button", Color.WHITE)
	ui_theme.set_color("font_focus_color", "Button", Color.WHITE)
	ui_theme.set_stylebox("normal", "Button", box("1b2941"))
	ui_theme.set_stylebox("hover", "Button", box("2b3d59", "79dcd8"))
	ui_theme.set_stylebox("pressed", "Button", box("344c65", "79dcd8"))
	var focus := box("00000000", "8cf4e2", 12)
	focus.set_border_width_all(3)
	ui_theme.set_stylebox("focus", "Button", focus)
	ui_theme.set_stylebox("panel", "PanelContainer", box("111c30f5"))
	ui_theme.set_constant("separation", "VBoxContainer", 12)
	ui_theme.set_constant("separation", "HBoxContainer", 12)

func label(value: String, size: int = 17, color: String = "eef3ff") -> Label:
	var item := Label.new()
	item.text = value
	item.add_theme_font_size_override("font_size", size)
	item.add_theme_color_override("font_color", Color(color))
	return item

func button(value: String, callback: Callable, primary: bool = false) -> Button:
	var item := Button.new()
	item.text = value
	item.custom_minimum_size.y = 48
	item.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	item.pressed.connect(callback)
	if primary:
		item.add_theme_stylebox_override("normal", box("9ce4cc", "b7f4dc", 12))
		item.add_theme_color_override("font_color", Color("102b30"))
		item.add_theme_stylebox_override("hover", box("c2f4e4", "c2f4e4", 12))
		item.add_theme_color_override("font_hover_color", Color("102b30"))
		item.add_theme_stylebox_override("pressed", box("72cbb1", "72cbb1", 12))
		item.add_theme_color_override("font_pressed_color", Color("102b30"))
	return item

func position_control(item: Control, pos: Vector2, dimensions: Vector2) -> void:
	item.position = pos
	item.size = dimensions

func rebuild() -> void:
	if not is_instance_valid(ui):
		return
	view_w = get_viewport_rect().size.x
	view_h = get_viewport_rect().size.y
	portrait = view_h > view_w * 1.1
	ground = view_h - (190.0 if portrait else 132.0)
	world.field_width = view_w
	for child in ui.get_children():
		# Keep the pressed control in the tree until Godot finishes GUI dispatch.
		child.hide()
		child.queue_free()
	hud = Control.new()
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(hud)
	var brand := label("AION  /  ENDLESS RUN", 19, "e9e9f5")
	hud.add_child(brand)
	brand.position = Vector2(32, 27)
	var offline_label := label(text("offline"), 11, "94d4bf")
	hud.add_child(offline_label)
	offline_label.position = Vector2(32, 58)
	var score_box := HBoxContainer.new()
	hud.add_child(score_box)
	score_box.position = Vector2(view_w * 0.46, 21)
	score_box.add_theme_constant_override("separation", 32)
	for key in ["score", "best", "gems"]:
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 0)
		score_box.add_child(column)
		column.add_child(label(text(key), 10, "99abc8"))
		var number := label("00000", 25, "b1eddb" if key == "score" else "eff0fb")
		column.add_child(number)
		if key == "score": score_label = number
		elif key == "best": best_label = number
		else: crystal_label = number
	pause_button = button(text("pause"), pause_run)
	hud.add_child(pause_button)
	position_control(pause_button, Vector2(view_w - 175, 23), Vector2(143, 48))
	var line := ColorRect.new()
	line.color = Color("293951")
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(line)
	position_control(line, Vector2(32, 91), Vector2(view_w - 64, 1))
	biome_label = label("", 12, "bdcde2")
	hud.add_child(biome_label)
	biome_label.position = Vector2(32, 111)
	progress = ProgressBar.new()
	progress.show_percentage = false
	progress.max_value = World.BIOME_DISTANCE
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var progress_bg := box("18283d", "18283d", 2)
	progress_bg.set_content_margin_all(0)
	var progress_fill := box("79d7c7", "79d7c7", 2)
	progress_fill.set_content_margin_all(0)
	progress.add_theme_stylebox_override("background", progress_bg)
	progress.add_theme_stylebox_override("fill", progress_fill)
	hud.add_child(progress)
	position_control(progress, Vector2(view_w - 252, 117), Vector2(220, 5))
	var next_label := label(text("next"), 9, "96aac3")
	hud.add_child(next_label)
	next_label.position = Vector2(view_w - 252, 99)
	footer_label = label(text("hint") + "  ·  " + text("touch"), 14, "c5d1e7")
	ui.add_child(footer_label)
	footer_label.position = Vector2(32, view_h - 75)
	var local_label := label(text("local"), 11, "8397b6")
	ui.add_child(local_label)
	local_label.position = Vector2(32, view_h - 44)
	var footer_name := label(NAMES[character], 13, "b0e1d2")
	ui.add_child(footer_name)
	footer_name.position = Vector2(view_w - 265, view_h - 70)
	ability_label = label("", 11, "b8e6d6")
	ui.add_child(ability_label)
	position_control(ability_label, Vector2(view_w - 360, view_h - 43), Vector2(330, 25))
	if portrait:
		var rotate_hint := wrap_label(text("portrait"), 38, "c5d1e7")
		rotate_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ui.add_child(rotate_hint)
		position_control(rotate_hint, Vector2(70, 225), Vector2(view_w - 140, 130))
	notice_label = label("", 21, "b5ffe0")
	notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui.add_child(notice_label)
	position_control(notice_label, Vector2(0, 161), Vector2(view_w, 40))
	menu_layer = Control.new()
	menu_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(menu_layer)
	if page != "":
		build_page()
	update_hud()
	queue_redraw()

func card(width: float = 520.0) -> VBoxContainer:
	var panel := PanelContainer.new()
	menu_layer.add_child(panel)
	var available := view_h - 250.0
	var height := minf(460.0, available)
	var x := (view_w - width) / 2.0
	if page == "main" and not portrait:
		x = view_w - width - 58.0
	panel.position = Vector2(x, maxf(152.0, (view_h - height) / 2.0 - 4.0))
	panel.custom_minimum_size = Vector2(width, height)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(width - 40.0, height - 26.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)
	return column

func wrap_label(value: String, size: int = 15, color: String = "a6b8d1") -> Label:
	var item := label(value, size, color)
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return item

func show_page(value: String) -> void:
	page = value
	rebuild()

func build_page() -> void:
	if page not in ["main"]:
		var shade := ColorRect.new()
		shade.color = Color(0.025, 0.04, 0.085, 0.70)
		position_control(shade, Vector2(0, 145), Vector2(view_w, view_h - 240))
		menu_layer.add_child(shade)
	if page == "characters":
		build_characters()
		return
	var column := card(440.0 if page == "main" else 560.0)
	var first: Button
	if page == "main":
		column.add_theme_constant_override("separation", 9)
		column.add_child(label("01 / " + text("desert"), 12, "9edccb"))
		column.add_child(label("AION\nENDLESS RUN", 43))
		column.add_child(wrap_label(text("tagline"), 15))
		first = button(text("play"), start_run, true)
		column.add_child(first)
		column.add_child(button(text("characters"), func(): open_subpage("characters")))
		column.add_child(button(text("settings"), func(): open_subpage("settings")))
		column.add_child(label("SPACE / ENTER", 10, "99abc8"))
	elif page == "paused":
		column.add_child(label(text("paused"), 28))
		column.add_child(wrap_label(text("pause_note")))
		first = button(text("resume"), resume_run, true)
		column.add_child(first)
		column.add_child(button(text("characters"), func(): open_subpage("characters")))
		column.add_child(button(text("menu"), main_menu))
		if not OS.has_feature("web") and not OS.has_feature("mobile"):
			column.add_child(button(text("quit"), quit_game))
		column.add_child(button(text("settings"), func(): open_subpage("settings")))
	elif page == "finished":
		column.add_child(label(text("frozen" if world.state == "ice" else "burnt"), 26))
		var result := HBoxContainer.new()
		column.add_child(result)
		result.add_child(label("%05d" % world.score, 54, "b6f0d9"))
		result.add_child(label(text("score"), 13, "adbbd4"))
		if world.score > best_at_start:
			column.add_child(label(text("new_best"), 14, "ffda93"))
		column.add_child(wrap_label(text("runstats") % [world.passed, world.gems]))
		first = button(text("again"), start_run, true)
		column.add_child(first)
		column.add_child(button(text("characters"), func(): open_subpage("characters")))
		column.add_child(button(text("menu"), main_menu))
		column.add_child(button(text("settings"), func(): open_subpage("settings")))
	elif page == "settings":
		column.add_child(label(text("settings"), 28))
		column.add_child(label(text("language"), 13, "a8bcd8"))
		var row := HBoxContainer.new()
		column.add_child(row)
		for lang in ["tr", "en"]:
			var option := button(("[x]  " if language == lang else "") + ("Türkçe" if lang == "tr" else "English"), func(): set_language(lang))
			option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(option)
		column.add_child(label(text("appearance"), 14, "a8bcd8"))
		add_toggle(column, "motion", motion, func(value): motion = value; save_settings())
		add_toggle(column, "audio", audio_enabled, func(value): audio_enabled = value; save_settings())
		var volume_label := label(text("volume") + "  %d%%" % roundi(volume * 100.0), 13)
		column.add_child(volume_label)
		var slider := HSlider.new()
		slider.min_value = 0
		slider.max_value = 100
		slider.step = 5
		slider.value = volume * 100
		slider.custom_minimum_size.y = 36
		slider.value_changed.connect(func(value): volume = value / 100.0; volume_label.text = text("volume") + "  %d%%" % value; save_settings())
		column.add_child(slider)
		if not OS.has_feature("web") and not OS.has_feature("mobile"):
			add_toggle(column, "fullscreen", fullscreen, func(value): fullscreen = value; apply_fullscreen(); save_settings())
		column.add_child(label(text("how"), 17, "b5e7d6"))
		column.add_child(wrap_label(text("help"), 13))
		column.add_child(label(text("version"), 11, "8e9fbb"))
		first = button("‹  " + text("back"), func(): show_page(return_page))
		column.add_child(first)
	if is_instance_valid(first):
		focus_later.call_deferred(first)

func focus_later(item: Control) -> void:
	if is_instance_valid(item) and item.is_inside_tree() and item.is_visible_in_tree() and not item.is_queued_for_deletion():
		item.grab_focus()

func build_characters() -> void:
	var column := card(850.0)
	var heading := HBoxContainer.new()
	column.add_child(heading)
	var title := label(text("choose"), 27)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	var back := button("‹  " + text("back"), func(): show_page(return_page))
	heading.add_child(back)
	column.add_child(wrap_label(text("same"), 14))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	column.add_child(grid)
	for id in FRIENDS:
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if id == character:
			panel.add_theme_stylebox_override("panel", box("223b47", "9ce4cc", 12))
		grid.add_child(panel)
		var row := HBoxContainer.new()
		panel.add_child(row)
		var picture := TextureRect.new()
		picture.custom_minimum_size = Vector2(78, 84)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var atlas := AtlasTexture.new()
		atlas.atlas = SHEET if id == "aion" else COMPANION_SHEET
		atlas.region = Rect2(0, 0, 209, 157) if id == "aion" else Rect2(0, COMPANION_RUN_ROWS[id] * 209, 209, 209)
		picture.texture = atlas
		if id != "aion":
			var mat := ShaderMaterial.new()
			mat.shader = preload("res://scripts/companion_alpha.gdshader")
			picture.material = mat
		row.add_child(picture)
		var details := VBoxContainer.new()
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(details)
		details.add_child(wrap_label(NAMES[id], 17, "eef3ff"))
		details.add_child(wrap_label(text("ability_" + id), 11, "b6e6d7"))
		details.add_child(button(text("selected" if character == id else "select"), func(): select_character(id), character == id))
	focus_later.call_deferred(back)

func add_toggle(column: VBoxContainer, key: String, value: bool, callback: Callable) -> void:
	var toggle := CheckButton.new()
	toggle.text = text(key)
	toggle.button_pressed = value
	toggle.custom_minimum_size.y = 46
	toggle.add_theme_font_size_override("font_size", 14)
	toggle.toggled.connect(callback)
	column.add_child(toggle)

func set_language(value: String) -> void:
	language = value
	save_settings()
	rebuild()

func apply_fullscreen() -> void:
	if not OS.has_feature("web") and not OS.has_feature("mobile"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)

func open_subpage(value: String) -> void:
	return_page = page
	show_page(value)

func start_run() -> void:
	best_at_start = best
	world.character = character
	world.reset()
	clear_held_controls()
	particles.clear()
	finished_panel = false
	notice = ""
	notice_time = 0.0
	show_page("")
	tone(440.0, 0.09)

func pause_run() -> void:
	if world.state == "running":
		clear_held_controls()
		world.state = "paused"
		save_settings()
		show_page("paused")

func resume_run() -> void:
	world.state = "running"
	show_page("")

func main_menu() -> void:
	save_settings()
	world.reset()
	clear_held_controls()
	world.state = "ready"
	particles.clear()
	notice_time = 0.0
	show_page("main")

func quit_game() -> void:
	save_settings()
	get_tree().quit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game()
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_GO_BACK_REQUEST]:
		clear_held_controls()
		pause_run()

func select_character(id: String) -> void:
	if id not in FRIENDS: return
	character = id
	world.character = id
	clear_held_controls()
	save_settings()
	rebuild()

func clear_held_controls() -> void:
	jump_sources.clear()
	boost_sources.clear()
	world.release_controls()

func press_jump(source: String) -> void:
	if page != "" or world.state != "running" or jump_sources.has(source): return
	world.character = character
	jump_sources[source] = true
	world.jump_held = true
	world.jump()

func release_jump(source: String) -> void:
	jump_sources.erase(source)
	world.jump_held = not jump_sources.is_empty()

func press_boost(source: String) -> void:
	if page != "" or world.state != "running": return
	world.character = character
	boost_sources[source] = true
	world.boost_held = true

func release_boost(source: String) -> void:
	boost_sources.erase(source)
	world.boost_held = not boost_sources.is_empty()

func on_wolf(point: Vector2) -> bool:
	return character == "wolf" and Rect2(World.PLAYER_X - 65, ground + world.y - 115, 130, 130).has_point(point)

func _input(event: InputEvent) -> void:
	# Releases are observed before GUI dispatch so dragging away from a control
	# or opening a menu can never leave glide/boost latched on.
	if event is InputEventKey and not event.pressed:
		if event.keycode == KEY_SPACE: release_jump("key")
		if event.keycode == KEY_SHIFT: release_boost("shift")
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		release_jump("mouse")
		release_boost("mouse")
	if event is InputEventScreenTouch and not event.pressed:
		release_jump("touch:" + str(event.index))
		release_boost("touch:" + str(event.index))
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if page == "": pause_run()
			elif page == "paused": resume_run()
			elif page in ["characters", "settings"]: show_page(return_page)
			elif page == "finished": main_menu()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_SPACE and page == "":
			press_jump("key")
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_SHIFT and page == "":
			press_boost("shift")
			get_viewport().set_input_as_handled()
		elif event.keycode in [KEY_SPACE, KEY_ENTER] and page == "main":
			start_run()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F11:
			fullscreen = not fullscreen
			apply_fullscreen()
			save_settings()
	if event is InputEventJoypadButton:
		if not event.pressed:
			if event.button_index == JOY_BUTTON_A: release_jump("pad")
			if event.button_index == JOY_BUTTON_X: release_boost("pad")
			return
		if event.button_index == JOY_BUTTON_START:
			if page == "": pause_run()
			elif page == "paused": resume_run()
		elif event.button_index == JOY_BUTTON_A:
			if page == "": press_jump("pad")
			elif page == "main": start_run()
		elif event.button_index == JOY_BUTTON_X:
			press_boost("pad")

func _unhandled_input(event: InputEvent) -> void:
	if page != "": return
	if event is InputEventScreenTouch and event.pressed:
		if is_instance_valid(pause_button) and pause_button.get_global_rect().has_point(event.position): return
		var source := "touch:" + str(event.index)
		if on_wolf(event.position): press_boost(source)
		else: press_jump(source)
		get_viewport().set_input_as_handled()
	if event is InputEventMouseButton and event.device != -1 and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if on_wolf(event.position): press_boost("mouse")
		else: press_jump("mouse")
		get_viewport().set_input_as_handled()

func _physics_process(dt: float) -> void:
	world.character = character
	if page == "" or (world.state in ["fire", "ice"] and page == "finished"):
		world.step(dt)
	if world.event_id != last_event:
		last_event = world.event_id
		handle_event(world.last_event)
	if world.state in ["fire", "ice"] and world.hit_time > 1.45 and not finished_panel:
		finished_panel = true
		save_settings()
		show_page("finished")
	if world.state == "running":
		best = maxi(best, world.score)
		notice_time = maxf(0.0, notice_time - dt)
	if page == "main" and motion:
		menu_clock += dt
	for p in particles:
		if world.state != "paused":
			p.position += p.velocity * dt
			p.velocity.y += 190.0 * dt
			p.life -= dt
	particles = particles.filter(func(p): return p.life > 0.0)
	update_friend()
	update_hud()
	queue_redraw()

func handle_event(value: String) -> void:
	if value == "": return
	if value == "jump": tone(580, 0.07)
	if value == "double_jump":
		burst(Vector2(World.PLAYER_X, ground + world.y), Color("99e6ff"), 14)
		tone(860, 0.1)
	if value in ["sheep_join", "sheep_saved"]:
		notice = text(value)
		notice_time = 1.6
		burst(Vector2(World.PLAYER_X - 64, ground - 45), Color("c1f5da"), 14)
		tone(920 if value == "sheep_join" else 260, 0.14)
	if value == "land": burst(Vector2(World.PLAYER_X, ground), Color("b9c4d1"), 6)
	if value in ["gem", "clear", "biome"]:
		notice = text(value)
		notice_time = 1.0 if value != "biome" else 2.2
		if value == "gem":
			burst(Vector2(World.PLAYER_X, ground + world.y - 35), Color("9cffe0"), 12)
			tone(1080, 0.1)
		elif value == "biome": tone(740, 0.18)
		elif world.combo % 5 == 0: tone(840, 0.1)
	if value in ["ice", "fire"]:
		clear_held_controls()
		save_settings()
		burst(Vector2(World.PLAYER_X, ground - 40), Color("a5eafa") if value == "ice" else Color("ffb46b"), 22)
		tone(170, 0.22)

func tone(frequency: float, duration: float) -> void:
	if not audio_enabled or volume <= 0.0 or DisplayServer.get_name() == "headless": return
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var data := PackedByteArray()
	var count := int(duration * 22050)
	data.resize(count * 2)
	for i in count:
		var envelope := (1.0 - float(i) / count) * minf(1.0, float(i) / 120.0)
		var sample := sin(TAU * frequency * float(i) / 22050.0) * envelope * 6500.0 * volume
		data.encode_s16(i * 2, int(sample))
	stream.data = data
	player_sound.stream = stream
	player_sound.play()

func burst(pos: Vector2, color: Color, count: int) -> void:
	if not motion: return
	for i in count:
		particles.append({"position": pos, "velocity": Vector2(randf_range(-100, 100), randf_range(-160, -30)), "life": randf_range(0.25, 0.65), "color": color})

func update_hud() -> void:
	if not is_instance_valid(score_label): return
	score_label.text = "%05d" % world.score
	best_label.text = "%05d" % best
	crystal_label.text = "%02d" % world.gems
	biome_label.text = ("02  /  " + text("snow")) if world.biome() else ("01  /  " + text("desert"))
	progress.value = fmod(world.distance, World.BIOME_DISTANCE)
	pause_button.visible = page == "" and world.state == "running"
	notice_label.text = text("saved_error") if save_failed else (notice if notice_time > 0.0 and page == "" else "")
	if is_instance_valid(ability_label):
		ability_label.text = text("ability_" + character)
		if character == "sheep": ability_label.text = text("flock") % world.sheep_count
		elif world.gliding: ability_label.text = text("gliding")
		elif world.boosting(): ability_label.text = text("boosting")
	publish_web_status()

func publish_web_status() -> void:
	if not OS.has_feature("web"): return
	var stamp := "%s:%s:%d:%s:%s:%s:%d:%s:%s:%d" % [world.state, page, world.score, character, language, world.y < 0.0, world.jumps_used, world.gliding, world.boosting(), world.sheep_count]
	if stamp == web_stamp: return
	web_stamp = stamp
	var document = JavaScriptBridge.get_interface("document")
	var canvas = document.getElementById("canvas")
	if canvas == null: return
	canvas.setAttribute("role", "application")
	canvas.setAttribute("lang", language)
	canvas.setAttribute("aria-label", "Aion Endless Run. " + text("hint") + ". " + text("score") + " " + str(world.score))
	canvas.setAttribute("data-state", world.state)
	canvas.setAttribute("data-page", page)
	canvas.setAttribute("data-score", str(world.score))
	canvas.setAttribute("data-character", character)
	canvas.setAttribute("data-airborne", str(world.y < 0.0))
	canvas.setAttribute("data-jumps", str(world.jumps_used))
	canvas.setAttribute("data-gliding", str(world.gliding))
	canvas.setAttribute("data-boosting", str(world.boosting()))
	canvas.setAttribute("data-flock", str(world.sheep_count))
	canvas.setAttribute("data-sprite-row", str(friend_row))
	canvas.setAttribute("data-sprite-frame", str(friend_frame))
	var next_x := -1.0
	for obstacle in world.obstacles:
		if obstacle.x > World.PLAYER_X - 35 and (next_x < 0 or obstacle.x < next_x): next_x = obstacle.x
	canvas.setAttribute("data-next-obstacle", str(next_x))
	canvas.setAttribute("data-next-sheep", str(world.sheep_pickups[0].x) if not world.sheep_pickups.is_empty() else "-1")

func animation_clock() -> float:
	if not motion: return 0.0
	return menu_clock if world.state == "ready" else world.time

func update_friend() -> void:
	friend_sprite.visible = character != "aion"
	for item in followers: item.visible = false
	sheep_collectible.visible = character == "sheep" and not world.sheep_pickups.is_empty() and world.sheep_count < 3
	if sheep_collectible.visible:
		place_companion(sheep_collectible, 1, int(animation_clock() * 9) % 6, Vector2(world.sheep_pickups[0].x, ground), 0.4)
	if character == "aion": return
	if friend_character != character:
		friend_character = character
		friend_row = COMPANION_RUN_ROWS[character]
		friend_frame = 0
	if world.state == "running":
		friend_row = COMPANION_RUN_ROWS[character]
		friend_frame = int(animation_clock() * (17 if world.boosting() else 11)) % 6
		if world.y < 0.0:
			friend_row = 5 if character == "owl" else (3 if character == "wolf" else 4)
			if character == "owl": friend_frame = int(animation_clock() * (5 if world.gliding else 12)) % 6
			else: friend_frame = 0 if world.air_time < 0.06 else (1 if world.velocity < -250 else (2 if world.velocity < -50 else (3 if world.velocity < 120 else (4 if world.velocity < 400 else 5))))
	elif world.state == "ready":
		friend_row = COMPANION_RUN_ROWS[character]
		friend_frame = 0
	if not motion: friend_frame = 0
	place_companion(friend_sprite, friend_row, friend_frame, Vector2(World.PLAYER_X, ground + world.y))
	friend_sprite.modulate = Color("91ddff") if world.state == "ice" else Color.WHITE
	if character == "sheep":
		for i in 2:
			followers[i].visible = world.sheep_count > i + 1 and world.state not in ["fire", "ice"]
			place_companion(followers[i], friend_row, (friend_frame + (i + 1) * 2) % 6 if world.y >= 0.0 and motion else friend_frame, Vector2(World.PLAYER_X - 64 * (i + 1), ground + world.y))
		if world.invulnerable > 0.0 and motion and int(world.time * 12) % 2 == 0: friend_sprite.modulate.a = 0.45
	if world.state == "fire" and world.hit_time > 0.5:
		friend_sprite.visible = false

func place_companion(item: Sprite2D, row: int, frame: int, anchor: Vector2, scale_value: float = 0.5) -> void:
	item.region_rect = Rect2(frame * 209, row * 209, 209, 209)
	item.scale = Vector2(scale_value, scale_value)
	item.offset = Vector2(-104.5, -float(COMPANION_BASELINES[row][frame]))
	item.position = anchor.round()

func sprite(row: int, frame: int, x: float, bottom: float, width: float) -> void:
	var sy := roundf(float(row) * 1254.0 / 8.0)
	var sh := roundf(float(row + 1) * 1254.0 / 8.0) - sy
	draw_texture_rect_region(SHEET, Rect2(roundf(x), roundf(bottom - width * sh / 209.0), width, width * sh / 209.0), Rect2(frame * 209, sy, 209, sh))

func _draw() -> void:
	if not is_instance_valid(ui): return
	draw_scenery()
	if world.boosting() and motion:
		for i in 3:
			draw_rect(Rect2(World.PLAYER_X - 130 - i * 16, ground + world.y - 26 - i * 16, 42 - i * 5, 3), Color("c5b8ff"))
	if character == "sheep" and not world.sheep_pickups.is_empty() and world.sheep_count < 3:
		var x: float = world.sheep_pickups[0].x
		draw_rect(Rect2(x - 10, ground - 104, 20, 20), Color("9ce4cc"))
		draw_line(Vector2(x - 5, ground - 94), Vector2(x + 5, ground - 94), Color("102b30"), 3)
		draw_line(Vector2(x, ground - 99), Vector2(x, ground - 89), Color("102b30"), 3)
	var frame := int(animation_clock() * 10.0) % 6
	for o in world.obstacles:
		sprite(6 if o.kind == "ice" else 7, frame, o.x - 40, ground + 3, 80)
	for pickup in world.pickups:
		var point := Vector2(pickup.x, ground + pickup.y)
		var bob := sin(animation_clock() * 4.0 + pickup.x * 0.01) * 4.0
		point.y += bob
		var diamond := PackedVector2Array([point + Vector2(0, -12), point + Vector2(9, 0), point + Vector2(0, 12), point + Vector2(-9, 0)])
		draw_colored_polygon(diamond, Color("8befd1"))
		draw_line(point + Vector2(0, -8), point + Vector2(-5, 0), Color("e0fff0"), 3)
	# Soft pixel shadow remains on the floor while the character jumps.
	draw_rect(Rect2(World.PLAYER_X - 35, ground - 2, 70, 5), Color(0.02, 0.04, 0.09, 0.4))
	if character == "aion":
		var row := 0
		var f := int(animation_clock() * 4.0) % 6
		if world.state in ["running", "paused"]:
			row = 2 if world.y < 0.0 else 1
			f = frame
		if world.state == "ice":
			row = 3
			f = mini(5, int(world.hit_time * 8.0)) if motion else 5
		if world.state == "fire":
			row = 4 if world.hit_time < 0.75 and motion else 5
			f = mini(5, int(world.hit_time * 8)) if row == 4 else (int(world.hit_time * 5) % 6 if motion else 0)
		sprite(row, f, World.PLAYER_X - 65, ground + world.y + 3, 130)
	else:
		draw_companion_effect()
	for p in particles:
		var c: Color = p.color
		c.a = minf(1.0, p.life * 3.0)
		draw_rect(Rect2(p.position.round(), Vector2(4, 4)), c)

func draw_companion_effect() -> void:
	var pos := Vector2(World.PLAYER_X, ground + world.y)
	if world.state == "ice":
		var c := Color(0.4, 0.8, 1.0, 0.25)
		draw_rect(Rect2(pos + Vector2(-46, -91), Vector2(92, 93)), c)
		draw_rect(Rect2(pos + Vector2(-46, -91), Vector2(92, 93)), Color("a6eaff"), false, 3)
		draw_line(pos + Vector2(-39, -62), pos + Vector2(-15, -84), Color("e0faff"), 5)
	elif world.state == "fire":
		if world.hit_time < 0.75 and motion:
			for i in 8:
				var x := sin(float(i) * 6.3) * 38.0
				var y := -20.0 - float(i % 3) * 20 - world.hit_time * 18.0
				draw_rect(Rect2(pos + Vector2(x, y), Vector2(23, 23)), Color("ffb269") if i % 2 else Color("8d7d8d"))
		else:
			draw_colored_polygon(PackedVector2Array([pos + Vector2(-40, 0), pos + Vector2(-25, -17), pos + Vector2(-4, -29), pos + Vector2(14, -24), pos + Vector2(41, 0)]), Color("6e758c"))
			for x in [-9, 9]:
				draw_rect(Rect2(pos + Vector2(x, -15), Vector2(5, 7)), COLORS[FRIENDS.find(character)])

func draw_scenery() -> void:
	var time := world.time
	var scroll := world.distance
	if world.state == "ready":
		time = menu_clock
		scroll = menu_clock * 20.0
	if not motion:
		scroll = 0.0
	var night := (cos(time * TAU / 72.0) + 1.0) / 2.0
	var snow_weight := 0.0
	if world.distance >= World.BIOME_DISTANCE:
		snow_weight = smoothstep(0.0, 0.07, fmod(world.distance / World.BIOME_DISTANCE, 1.0))
		if world.biome() == 0: snow_weight = 1.0 - snow_weight
	var top := Color("355c80").lerp(Color("0c142a"), night)
	var bottom := Color("e5a58b").lerp(Color("3b3655"), night).lerp(Color("405d7e"), snow_weight * 0.65)
	# Large flat bands preserve the illustrated pixel landscape.
	for i in 48:
		var fraction := float(i) / 48.0
		draw_rect(Rect2(0, fraction * ground, view_w, ground / 48.0 + 1), top.lerp(bottom, fraction))
	for i in 45:
		var x := fposmod(float(i * 173 + 51) - scroll * 0.018, view_w)
		var y := 151.0 + fposmod(float(i * 67), maxf(60.0, ground - 280.0))
		var alpha := night * (0.32 + 0.5 * float(i % 3) / 2.0)
		draw_rect(Rect2(roundf(x), roundf(y), 2 if i % 4 else 4, 2 if i % 4 else 4), Color(0.85, 0.91, 1.0, alpha))
	var moon := Vector2(view_w * 0.77, 224.0 if not portrait else 400.0)
	draw_rect(Rect2(moon - Vector2(26, 30), Vector2(52, 60)), Color("f5dfbc").lerp(Color("f3ba89"), 1.0 - night))
	draw_rect(Rect2(moon - Vector2(33, 19), Vector2(66, 38)), Color("f5dfbc").lerp(Color("f3ba89"), 1.0 - night))
	# Three independently scrolling mountain layers; all shapes snap to pixel steps.
	for layer in 3:
		var base := ground - 14.0 + float(layer) * 6.0
		var mountain_color := Color("6d5266").lerp(Color("25304f"), night).lerp(Color("355774"), snow_weight)
		mountain_color = mountain_color.darkened(float(layer) * 0.15)
		var spacing := 235.0 + float(layer) * 95.0
		var offset := fposmod(scroll * (0.08 + float(layer) * 0.09), spacing)
		for i in range(-1, int(view_w / spacing) + 2):
			var x := float(i) * spacing - offset
			var height := 100.0 + float((i + 22) % 3) * 31.0 - float(layer) * 19.0
			var points := PackedVector2Array([Vector2(x, base), Vector2(x, base - 29), Vector2(x + 35, base - 29), Vector2(x + 35, base - height * 0.55), Vector2(x + 62, base - height * 0.55), Vector2(x + 62, base - height), Vector2(x + 123, base - height), Vector2(x + 123, base - height * 0.72), Vector2(x + 161, base - height * 0.72), Vector2(x + 161, base - height * 0.35), Vector2(x + spacing, base - height * 0.35), Vector2(x + spacing, base)])
			draw_colored_polygon(points, mountain_color)
			if snow_weight > 0.0 and layer < 2:
				var c := Color("bed7e3")
				c.a = snow_weight * 0.65
				draw_rect(Rect2(x + 62, base - height, 61, 8), c)
	for i in range(-1, int(view_w / 275) + 2):
		var x := float(i) * 275.0 - fposmod(scroll * 0.55, 275.0)
		var c := Color("263b48").lerp(Color("244357"), snow_weight)
		if snow_weight < 0.5:
			draw_rect(Rect2(x + 26, ground - 71, 14, 71), c)
			draw_rect(Rect2(x + 3, ground - 51, 37, 10), c)
			draw_rect(Rect2(x + 3, ground - 68, 10, 23), c)
			draw_rect(Rect2(x + 32, ground - 38, 34, 10), c)
			draw_rect(Rect2(x + 56, ground - 59, 10, 29), c)
		else:
			draw_rect(Rect2(x + 30, ground - 75, 8, 75), c)
			for j in 3:
				draw_rect(Rect2(x + 18 - j * 9, ground - 85 + j * 19, 32 + j * 18, 21), c)
				draw_rect(Rect2(x + 18 - j * 9, ground - 85 + j * 19, 32 + j * 18, 4), Color("b6d1df"))
	var floor_color := Color("553e50").lerp(Color("233b51"), snow_weight)
	draw_rect(Rect2(0, ground, view_w, view_h - ground), floor_color)
	draw_rect(Rect2(0, ground, view_w, 4), Color("c48d91").lerp(Color("c4e7f0"), snow_weight))
	draw_rect(Rect2(0, ground + 4, view_w, 10), Color("775367").lerp(Color("5b829a"), snow_weight))
	for i in range(-1, int(view_w / 43) + 2):
		var x := float(i) * 43 - fposmod(scroll, 43)
		draw_rect(Rect2(x, ground + 27 + (i % 3) * 7, 9, 3), Color("956776").lerp(Color("63849b"), snow_weight))
	# UI footer has a quiet, solid background.
	draw_rect(Rect2(0, view_h - 98, view_w, 98), Color("101a2d"))
	draw_line(Vector2(32, view_h - 98), Vector2(view_w - 32, view_h - 98), Color("31415a"), 1)
	if snow_weight > 0.4:
		for i in 28:
			var x := fposmod(float(i * 109) - scroll * 0.15, view_w)
			var y := 150.0 + fposmod(float(i * 73) + (time * 24.0 if motion else 0.0), maxf(1.0, ground - 150.0))
			draw_rect(Rect2(x, y, 3, 3), Color(0.88, 0.96, 1.0, snow_weight * 0.5))
