extends Node2D

const World = preload("res://scripts/world.gd")
const Words = preload("res://scripts/text.gd")
const SHEET = preload("res://assets/aion-runner.png")
const FONT = preload("res://assets/Lexend.ttf")
const RUNNER_SHEETS = {"wolf":preload("res://assets/wolf-runner.png"), "sheep":preload("res://assets/sheep-runner.png"), "owl":preload("res://assets/owl-runner.png")}
const RUNNER_DATA = preload("res://assets/FULL-RUNNER-PROVENANCE.json")
const ACTION_SHEET = preload("res://assets/companion-actions.png")
const ACTION_DATA = preload("res://assets/ACTION-PROVENANCE.json")
const COMBAT_SHEET = preload("res://assets/evolution-strikes.png")
const ADVENTURE_DATA = preload("res://assets/ADVENTURE-PROVENANCE.json")
const COMBAT_ROWS := {"aion":0,"owl":1,"sheep":2,"wolf":3}
const GAME_VERSION = "0.12.0"
const ROLL_SHEET = preload("res://assets/evolution-rolls.png")
const EVOLUTION_DATA = preload("res://assets/EVOLUTION-PROVENANCE.json")
const COMPANION_RUN_ROWS := {"wolf":1,"sheep":1,"owl":1}
const REGISTRATION = preload("res://assets/SPRITE-REGISTRATION.json")
const NORMAL_HEIGHT := 90.0
const FOLLOWER_RATIO := 0.72
const FRIENDS := ["aion", "owl", "wolf", "sheep"]
const COLORS := [Color("f4a7cd"), Color("ffca84"), Color("b8baf0"), Color("b8ebd3")]
var frames := preload("res://scripts/frame_bank.gd").new()
var world := World.new()
var language := "en"
var language_override := false
var language_picker_open := false
var language_button: Button
var language_picker: PanelContainer
var character := "aion"
var best_level := 1
var prism_intensity := 0.60
var evolution_view: Node2D
var level_label: Label
var level_progress: ProgressBar
var settings_inputs := {}
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
var friend_action := false
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
var web_update_callback: JavaScriptObject
var gamepad := preload("res://scripts/gamepad.gd").new()
var effects_enabled := true
var canvas_layer: CanvasLayer
var screen_transform := Transform2D.IDENTITY
var device_portrait := false
var frontier_view: Node2D
var boss_bar: ProgressBar
var boss_label: Label
var shoot_sources := {}
var adventure_view: Node2D
var world_tint: CanvasModulate
var power_label: Label
var goal_label: Label
var action_buttons := {}
var duck_sources := {}
var attack_sources := {}
var touch_actions := {}
var visual_size := 1.0
var friend_combat := -1
var ui_layout_ready := false
var layout_generation := 0

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("0a1222"))
	gamepad.host = self
	Input.joy_connection_changed.connect(on_gamepad_connection)
	load_settings()
	evolution_view = preload("res://scripts/evolution_view.gd").new()
	evolution_view.host = self
	var party_material := ShaderMaterial.new()
	party_material.shader = preload("res://scripts/companion_alpha.gdshader")
	evolution_view.material = party_material
	add_child(evolution_view)
	adventure_view = preload("res://scripts/adventure_view.gd").new()
	adventure_view.host = self
	var fx_material := ShaderMaterial.new()
	fx_material.shader = preload("res://scripts/companion_alpha.gdshader")
	adventure_view.material = fx_material
	add_child(adventure_view)
	frontier_view = preload("res://scripts/frontier_view.gd").new()
	frontier_view.host = self
	add_child(frontier_view)
	world_tint = CanvasModulate.new()
	add_child(world_tint)
	if OS.has_feature("web"):
		web_update_callback = JavaScriptBridge.create_callback(prepare_web_update)
		JavaScriptBridge.get_interface("window").aionSaveForUpdate = web_update_callback
		JavaScriptBridge.eval("document.getElementById('canvas').addEventListener('contextmenu',e=>{if(e.currentTarget.dataset.bossActive==='true')e.preventDefault()})")
	for i in 2:
		followers.append(make_companion_sprite())
	sheep_collectible = make_companion_sprite()
	friend_sprite = make_companion_sprite()
	player_sound = AudioStreamPlayer.new()
	add_child(player_sound)
	var canvas := CanvasLayer.new()
	canvas_layer = canvas
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
	item.texture = RUNNER_SHEETS["owl"]
	item.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	item.region_enabled = true
	item.region_filter_clip_enabled = true
	item.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
	item.centered = false
	var material := ShaderMaterial.new()
	material.shader = preload("res://scripts/companion_alpha.gdshader")
	item.material = material
	add_child(item)
	return item

func text(key: String) -> String:
	return Words.get_text(language, key)

func character_name(id: String) -> String:
	return text("name_" + id)

func default_language() -> String:
	var locale := OS.get_locale()
	if OS.has_feature("web"):
		var browser_locale = JavaScriptBridge.eval("navigator.language || 'en'")
		if browser_locale is String: locale = browser_locale
	return Words.language_for_locale(locale)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	language = default_language()
	if cfg.load("user://save.cfg") != OK:
		return
	language_override = bool(cfg.get_value("prefs", "language_override", cfg.has_section_key("prefs", "language")))
	if language_override:
		var saved_language := str(cfg.get_value("prefs", "language", ""))
		if saved_language in Words.LANGUAGES: language = saved_language
		else: language_override = false
	character = str(cfg.get_value("prefs", "character", "aion"))
	if character not in FRIENDS:
		character = "aion"
	best = maxi(0, int(cfg.get_value("records", "best", 0)))
	best_level = maxi(1,int(cfg.get_value("records", "best_level", 1)))
	world.adventure.mushroom_chance = clampf(float(cfg.get_value("prefs", "mushroom_chance", 0.02)),0.0,1.0)
	world.adventure.celebrations_enabled = bool(cfg.get_value("prefs", "celebrations", true))
	prism_intensity = clampf(float(cfg.get_value("prefs", "prism_intensity",0.60)),0.0,1.0)
	audio_enabled = bool(cfg.get_value("prefs", "audio", true))
	motion = bool(cfg.get_value("prefs", "motion", true))
	effects_enabled = bool(cfg.get_value("prefs", "effects", true))
	world.adventure.discoveries.assign(Array(cfg.get_value("progress", "powers", [])).filter(func(id): return id in world.adventure.POWER_NAMES))
	volume = clampf(float(cfg.get_value("prefs", "volume", 0.45)), 0.0, 1.0)
	fullscreen = bool(cfg.get_value("prefs", "fullscreen", false))

func save_settings() -> void:
	if not world.practice:
		best = maxi(best, world.score)
		best_level = maxi(best_level, world.adventure.level)
	var cfg := ConfigFile.new()
	cfg.set_value("prefs", "language", language)
	cfg.set_value("prefs", "language_override", language_override)
	cfg.set_value("prefs", "character", character)
	cfg.set_value("prefs", "audio", audio_enabled)
	cfg.set_value("prefs", "motion", motion)
	cfg.set_value("prefs", "volume", volume)
	cfg.set_value("prefs", "effects", effects_enabled)
	cfg.set_value("progress", "powers", world.adventure.discoveries)
	cfg.set_value("prefs", "fullscreen", fullscreen)
	cfg.set_value("records", "best", best)
	cfg.set_value("records", "best_level", best_level)
	cfg.set_value("prefs", "mushroom_chance", world.adventure.mushroom_chance)
	cfg.set_value("prefs", "celebrations", world.adventure.celebrations_enabled)
	cfg.set_value("prefs", "prism_intensity", prism_intensity)
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
		item.add_theme_color_override("font_focus_color", Color("102b30"))
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
	var raw := get_viewport_rect().size
	device_portrait = raw.y > raw.x
	var aspect := raw.y / raw.x if device_portrait else raw.x / raw.y
	view_h = 648.0
	view_w = maxf(1024.0, view_h * aspect)
	var scale_value := minf(raw.x / view_h, raw.y / view_w) if device_portrait else minf(raw.x / view_w, raw.y / view_h)
	if device_portrait:
		screen_transform = Transform2D(PI * 0.5, Vector2.ONE * scale_value, 0, Vector2((raw.x + view_h * scale_value) * 0.5, (raw.y - view_w * scale_value) * 0.5))
	else:
		screen_transform = Transform2D(0, Vector2.ONE * scale_value, 0, (raw - Vector2(view_w, view_h) * scale_value) * 0.5)
	canvas_layer.transform = screen_transform
	ui.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	ui.size = Vector2(view_w, view_h)
	portrait = false
	ground = view_h - 132.0
	apply_scene_transform()
	web_stamp = ""
	ui_layout_ready = false
	layout_generation += 1
	refresh_interface_metadata.call_deferred(layout_generation)
	world.field_width = view_w
	settings_inputs.clear()
	for child in ui.get_children():
		# Keep the pressed control in the tree until Godot finishes GUI dispatch.
		child.hide()
		child.name = "RetiredUI_" + str(child.get_instance_id())
		child.queue_free()
	hud = Control.new()
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(hud)
	var brand := label("AION  /  ENDLESS RUN", 19, "e9e9f5")
	hud.add_child(brand)
	brand.position = Vector2(32, 27)
	var offline_label := label(text("offline") + " · v" + GAME_VERSION, 11, "94d4bf")
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
	footer_label = label(text("hint"), 12, "c5d1e7")
	ui.add_child(footer_label)
	footer_label.position = Vector2(32, view_h - 75)
	var local_label := label("", 11, "8397b6")
	ui.add_child(local_label)
	local_label.position = Vector2(32, view_h - 44)
	var footer_name := label(character_name(character), 13, "b0e1d2")
	ui.add_child(footer_name)
	footer_name.position = Vector2(32, view_h - 111)
	ability_label = label("", 11, "b8e6d6")
	ui.add_child(ability_label)
	position_control(ability_label, Vector2(32, view_h - 40), Vector2(view_w - 460, 25))
	power_label = label("", 12, "d7d8f6")
	hud.add_child(power_label)
	position_control(power_label, Vector2(32, 138), Vector2(view_w - 470, 25))
	power_label.clip_text = true
	goal_label = label("", 12, "ecdaa7")
	hud.add_child(goal_label)
	position_control(goal_label, Vector2(view_w - 415, 138), Vector2(385, 25))
	level_label = label("",12,"ffe2b6")
	ui.add_child(level_label)
	position_control(level_label,Vector2(view_w-560,view_h-124),Vector2(350,24))
	level_progress = ProgressBar.new()
	level_progress.show_percentage = false
	level_progress.max_value = world.adventure.LEVEL_DISTANCE
	level_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(level_progress)
	position_control(level_progress,Vector2(view_w-207,view_h-113),Vector2(175,6))
	boss_label = label("",15,"ffdaa3")
	ui.add_child(boss_label)
	position_control(boss_label,Vector2(view_w*0.5-230,208),Vector2(460,26))
	boss_bar = ProgressBar.new()
	boss_bar.show_percentage = false
	ui.add_child(boss_bar)
	position_control(boss_bar,Vector2(view_w*0.5-230,236),Vector2(460,10))
	build_action_buttons()
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
	build_language_picker()
	update_hud()
	queue_redraw()

func refresh_interface_metadata(generation: int) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if generation != layout_generation: return
	ui_layout_ready = true
	web_stamp = ""
	publish_web_status()

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
	if value == "characters" and world.state != "ready": return
	language_picker_open = false
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
		column.add_theme_constant_override("separation", 7)
		column.add_child(label("01 / " + text("desert"), 12, "9edccb"))
		column.add_child(label("AION\nENDLESS RUN", 40))
		column.add_child(wrap_label(text("tagline"), 15))
		first = button(text("play"), start_run, true)
		column.add_child(first)
		column.add_child(button(text("characters"), func(): open_subpage("characters")))
		column.add_child(button(text("boss_training"), func(): show_page("bosses")))
		column.add_child(button(text("settings"), func(): open_subpage("settings")))
		column.add_child(label("SPACE / ENTER", 10, "99abc8"))
		build_start_roster()
	elif page == "paused":
		column.add_child(label(text("paused"), 28))
		column.add_child(wrap_label(text("pause_note")))
		first = button(text("resume"), resume_run, true)
		column.add_child(first)
		column.add_child(button(text("menu"), main_menu))
		if not OS.has_feature("web") and not OS.has_feature("mobile"):
			column.add_child(button(text("quit"), quit_game))
		column.add_child(button(text("settings"), func(): open_subpage("settings")))
	elif page == "finished":
		column.add_child(label(text("frozen" if world.state == "ice" else ("bonked" if world.state == "bonk" else "burnt")), 26))
		var result := HBoxContainer.new()
		column.add_child(result)
		result.add_child(label("%05d" % world.score, 54, "b6f0d9"))
		result.add_child(label(text("score"), 13, "adbbd4"))
		if not world.practice and world.score > best_at_start:
			column.add_child(label(text("new_best"), 14, "ffda93"))
		column.add_child(wrap_label(text("runstats") % [world.passed, world.gems]))
		column.add_child(wrap_label(text("level_record") % [world.adventure.level,best_level],13))
		first = button(text("again"), retry_run, true)
		column.add_child(first)
		column.add_child(button(text("menu"), main_menu))
		column.add_child(button(text("settings"), func(): open_subpage("settings")))
	elif page == "bosses":
		column.add_child(label(text("boss_training"),25,"c1f1e2"))
		column.add_child(wrap_label(text("boss_training_help"),14))
		for kind in 3:
			var entry := button(text(["boss_name","boss_ray","boss_root"][kind]),start_boss_practice.bind(kind))
			entry.name = "PracticeBoss_"+str(kind)
			column.add_child(entry)
			if kind==0: first = entry
		column.add_child(button(text("menu"),main_menu))
	elif page == "settings":
		column.add_child(label(text("settings"), 28))
		column.add_child(label(text("language"), 13, "a8bcd8"))
		var row := HBoxContainer.new()
		column.add_child(row)
		for lang in Words.LANGUAGES:
			var option := button(("[x]  " if language == lang else "") + Words.LANGUAGE_NAMES[lang], func(): set_language(lang))
			option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(option)
		column.add_child(wrap_label(text("language_hint"), 12))
		column.add_child(label(text("appearance"), 14, "a8bcd8"))
		add_toggle(column, "motion", motion, func(value): motion = value; save_settings())
		add_toggle(column, "screen_fx", effects_enabled, func(value): effects_enabled = value; save_settings())
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
		column.add_child(label(text("gameplay"),17,"b5e7d6"))
		add_toggle(column,"celebrations",world.adventure.celebrations_enabled,func(value):
			world.adventure.celebrations_enabled = value
			if not value:
				if world.adventure.hugging(): world.frontier.request_boss(world.adventure.hug_level)
				elif not world.adventure.hug_queue.is_empty(): world.frontier.request_boss(world.adventure.hug_queue[0].level)
				if world.adventure.hugging(): world.invulnerable = maxf(world.invulnerable,0.65)
				world.adventure.hug_time = 0.0
				world.adventure.hug_pending = false
				world.adventure.hug_queue.clear()
				world.adventure.celebration_time = 0.0
				world.adventure.heart_time = 0.0
			save_settings())
		add_range_setting(column,"mushroom_chance",world.adventure.mushroom_chance*100,func(value): world.adventure.mushroom_chance = value/100.0; save_settings(),"MushroomChance")
		column.add_child(wrap_label(text("mushroom_chance_help"),12))
		add_range_setting(column,"prism_intensity",prism_intensity*100,func(value): prism_intensity = value/100.0; save_settings(),"PrismIntensity")
		column.add_child(label(text("how"), 17, "b5e7d6"))
		column.add_child(wrap_label(text("help"), 13))
		column.add_child(wrap_label(text("boss_help"),13))
		column.add_child(wrap_label(text("motion_help"),13))
		column.add_child(wrap_label(text("gamepad_help"),13))
		column.add_child(label(text("discoveries") % world.adventure.discoveries.size(), 16))
		for power in world.adventure.POWER_NAMES:
			column.add_child(wrap_label(("✓ " if world.adventure.discoveries.has(power) else "○ ") + text("power_" + power) + " · " + text("desc_" + power), 12))
		column.add_child(label(text("version"), 11, "8e9fbb"))
		first = button("‹  " + text("back"), func(): show_page(return_page))
		column.add_child(first)
	if is_instance_valid(first):
		focus_later.call_deferred(first)

func build_language_picker() -> void:
	language_button = button(language.to_upper(), toggle_language_picker)
	language_button.name = "LanguageMenu"
	language_button.tooltip_text = text("language")
	var chevron := Control.new()
	chevron.set_script(preload("res://scripts/language_chevron.gd"))
	chevron.mouse_filter = Control.MOUSE_FILTER_IGNORE
	language_button.add_child(chevron)
	chevron.position = Vector2(68, 24)
	language_button.visible = page != ""
	language_button.add_theme_font_size_override("font_size", 13)
	ui.add_child(language_button)
	position_control(language_button, Vector2(view_w - 270, 23), Vector2(84, 48))
	language_picker = PanelContainer.new()
	language_picker.name = "LanguagePicker"
	language_picker.z_index = 100
	language_picker.add_theme_stylebox_override("panel", box("18283d", "79d7c7", 12))
	ui.add_child(language_picker)
	language_picker.position = Vector2(view_w - 282, 78)
	var options := VBoxContainer.new()
	language_picker.add_child(options)
	for lang in Words.LANGUAGES:
		var option := button(lang.to_upper() + "  " + Words.LANGUAGE_NAMES[lang], func(): set_language(lang), lang == language)
		option.name = "Language_" + lang
		option.custom_minimum_size = Vector2(176, 44)
		options.add_child(option)
	language_picker.visible = language_picker_open and page != ""

func toggle_language_picker() -> void:
	language_picker_open = not language_picker_open
	language_picker.visible = language_picker_open
	web_stamp = ""
	if language_picker_open: language_picker.get_child(0).get_child(Words.LANGUAGES.find(language)).grab_focus()

func character_portrait(id: String) -> TextureRect:
	var picture := TextureRect.new()
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.custom_minimum_size = Vector2(58, 66)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var atlas := AtlasTexture.new()
	atlas.atlas = SHEET if id == "aion" else RUNNER_SHEETS[id]
	atlas.region = Rect2(0, 0, 209, 157) if id == "aion" else runner_region(id, 1, 0)
	picture.texture = frames.pose("runner-"+id,1,0).texture
	if id != "aion":
		var mat := ShaderMaterial.new()
		mat.shader = preload("res://scripts/companion_alpha.gdshader")
		picture.material = mat
	return picture

func build_start_roster() -> void:
	var width := minf(564.0, view_w - 570.0)
	var panel := PanelContainer.new()
	menu_layer.add_child(panel)
	panel.position = Vector2(32, 178)
	panel.custom_minimum_size.x = width
	panel.add_theme_stylebox_override("panel", box("132034", "2d3c57", 14))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	column.add_child(wrap_label(text("choose_before_run"), 16, "b1eddb"))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	column.add_child(grid)
	for id in FRIENDS:
		var tile := button("", func(): select_character(id), id == character)
		tile.name = "StartSelect_" + id
		tile.tooltip_text = text("ability_" + id)
		tile.custom_minimum_size = Vector2((width - 50) * 0.5, 90)
		grid.add_child(tile)
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(row)
		row.position = Vector2(8, 8)
		row.size = Vector2((width - 50) * 0.5 - 16, 74)
		row.add_child(character_portrait(id))
		var name_label := wrap_label(character_name(id), 13, "102b30" if id == character else "eef3ff")
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(name_label)

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
		atlas.atlas = SHEET if id == "aion" else RUNNER_SHEETS[id]
		atlas.region = Rect2(0, 0, 209, 157) if id == "aion" else runner_region(id, 1, 0)
		picture.texture = frames.pose("runner-"+id,1,0).texture
		if id != "aion":
			var mat := ShaderMaterial.new()
			mat.shader = preload("res://scripts/companion_alpha.gdshader")
			picture.material = mat
		row.add_child(picture)
		var details := VBoxContainer.new()
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(details)
		details.add_child(wrap_label(character_name(id), 17, "eef3ff"))
		details.add_child(wrap_label(text("ability_" + id), 11, "b6e6d7"))
		var choice := button(text("selected" if character == id else "select"), func(): select_character(id), character == id)
		choice.name = "Select_" + id
		details.add_child(choice)
	focus_later.call_deferred(back)

func add_toggle(column: VBoxContainer, key: String, value: bool, callback: Callable) -> void:
	var row := HBoxContainer.new()
	column.add_child(row)
	var toggle := CheckButton.new()
	toggle.name = "Setting_"+key
	toggle.text = text(key)
	toggle.button_pressed = value
	toggle.custom_minimum_size.y = 46
	toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toggle.add_theme_font_size_override("font_size", 14)
	row.add_child(toggle)
	var status := label(text("setting_on" if value else "setting_off"),13,"a8efd4" if value else "a6b8d1")
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(status)
	toggle.toggled.connect(func(enabled):
		status.text = text("setting_on" if enabled else "setting_off")
		status.modulate = Color("a8efd4") if enabled else Color("a6b8d1")
		callback.call(enabled))

func add_range_setting(column: VBoxContainer,key: String,value: float,callback: Callable,id: String) -> void:
	column.add_child(wrap_label(text(key),14))
	var row := HBoxContainer.new()
	column.add_child(row)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size.y = 46
	row.add_child(slider)
	var number := SpinBox.new()
	number.name = id
	number.min_value = 0
	number.max_value = 100
	number.step = 1
	number.value = value
	number.suffix = "%"
	number.custom_minimum_size = Vector2(118,46)
	row.add_child(number)
	settings_inputs[id] = number
	slider.value_changed.connect(func(v): number.value = v)
	number.value_changed.connect(func(v): slider.set_value_no_signal(v); callback.call(v))

func set_language(value: String) -> void:
	if value not in Words.LANGUAGES: return
	language_override = true
	language_picker_open = false
	language = value
	save_settings()
	rebuild()

func apply_fullscreen() -> void:
	if not OS.has_feature("web") and not OS.has_feature("mobile"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)

func open_subpage(value: String) -> void:
	if value == "characters" and (page != "main" or world.state != "ready"): return
	return_page = page
	show_page(value)

func start_run() -> void:
	visual_size = 1.0
	if OS.has_feature("web"):
		JavaScriptBridge.eval("if (matchMedia('(pointer:coarse)').matches) { const c=document.getElementById('canvas'); if(c.requestFullscreen) c.requestFullscreen().then(()=>screen.orientation?.lock?.('landscape')).catch(()=>{}); }")
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
	visual_size = 1.0
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
	if id not in FRIENDS or world.state != "ready" or page not in ["main", "characters"]: return
	character = id
	world.character = id
	clear_held_controls()
	save_settings()
	rebuild()

func clear_held_controls() -> void:
	gamepad.clear()
	jump_sources.clear()
	boost_sources.clear()
	duck_sources.clear()
	attack_sources.clear()
	shoot_sources.clear()
	touch_actions.clear()
	world.release_controls()

func press_jump(source: String) -> void:
	if page != "" or world.state != "running" or world.adventure.hugging() or jump_sources.has(source): return
	world.character = character
	jump_sources[source] = true
	world.jump_held = true
	world.jump()

func release_jump(source: String) -> void:
	jump_sources.erase(source)
	world.jump_held = not jump_sources.is_empty()

func press_boost(source: String) -> void:
	if page != "" or world.state != "running" or world.adventure.hugging(): return
	world.character = character
	boost_sources[source] = true
	world.boost_held = true

func release_boost(source: String) -> void:
	boost_sources.erase(source)
	world.boost_held = not boost_sources.is_empty()

func press_attack(source: String) -> void:
	if page != "" or world.state != "running" or world.adventure.hugging() or world.frontier.active(): return
	if attack_sources.has(source): return
	var first := attack_sources.is_empty()
	attack_sources[source] = true
	if first: world.adventure.request_attack(world)

func press_shoot(source: String) -> void:
	if page != "" or world.state != "running" or not world.frontier.active(): return
	shoot_sources[source] = true
	world.frontier.shoot_held = true
	world.frontier.fire(world)

func release_shoot(source: String) -> void:
	shoot_sources.erase(source)
	world.frontier.shoot_held = not shoot_sources.is_empty()

func release_attack(source: String) -> void:
	attack_sources.erase(source)
	world.adventure.attack_held = not attack_sources.is_empty()

func press_duck(source: String) -> void:
	if page != "" or world.state != "running" or world.adventure.hugging(): return
	duck_sources[source] = true
	world.adventure.press_roll(world)

func release_duck(source: String) -> void:
	duck_sources.erase(source)
	world.adventure.duck_held = not duck_sources.is_empty()

func build_action_buttons() -> void:
	action_buttons.clear()
	var names := ["jump", "attack", "duck", "shoot"]
	for i in 4:
		var id: String = names[i]
		var control := button(text("control_" + id), func(): pass)
		ui.add_child(control)
		position_control(control, Vector2(view_w - 420 + i * 132, view_h - 89), Vector2(124, 72))
		control.visible = page == "" and world.state == "running"
		match id:
			"jump":
				control.button_down.connect(func(): press_jump("jump-button"))
				control.button_up.connect(func(): release_jump("jump-button"))
			"attack":
				control.button_down.connect(func(): press_attack("attack-button"))
				control.button_up.connect(func(): release_attack("attack-button"))
			"shoot":
				control.button_down.connect(func(): press_shoot("shoot-button"))
				control.button_up.connect(func(): release_shoot("shoot-button"))
			"duck":
				control.button_down.connect(func(): press_duck("duck-button"))
				control.button_up.connect(func(): release_duck("duck-button"))
		action_buttons[id] = control

func to_game_point(point: Vector2) -> Vector2:
	return global_transform.affine_inverse() * point

func apply_scene_transform() -> void:
	var camera := Transform2D.IDENTITY
	var a = world.adventure
	if a.giant() and effects_enabled and motion:
		var clock := animation_clock()
		var zoom := 1.0 + prism_intensity * (0.020 + sin(clock * 0.65) * 0.008)
		camera = Transform2D(sin(clock * 0.8) * 0.008 * prism_intensity, Vector2.ONE * zoom, 0, Vector2.ZERO)
		var center := Vector2(view_w * 0.5, ground * 0.6)
		camera.origin = center - (camera * center) + Vector2(sin(clock * 0.7) * 4, cos(clock * 0.6)*2)*prism_intensity
		if is_instance_valid(world_tint): world_tint.color = Color.WHITE.lerp(Color.from_hsv(fposmod(clock * 0.045, 1.0), 0.30, 1.0), 0.60*prism_intensity)
	elif is_instance_valid(world_tint): world_tint.color = Color.WHITE
	transform = screen_transform * camera

func on_wolf(point: Vector2) -> bool:
	return character == "wolf" and Rect2(World.PLAYER_X - 65, ground + world.y - 115, 130, 130).has_point(point)

func _input(event: InputEvent) -> void:
	# Route game touch buttons by finger ID. BaseButton's emulated mouse alone
	# cannot reliably represent jump + attack held by two different fingers.
	if event is InputEventScreenTouch:
		var touch_source := "touch:" + str(event.index)
		if not event.pressed:
			release_shoot(touch_source)
			release_attack(touch_source)
			release_duck(touch_source)
			touch_actions.erase(event.index)
		elif page == "" and world.state == "running":
			var point: Vector2 = screen_transform.affine_inverse() * event.position
			if is_instance_valid(pause_button) and pause_button.get_global_rect().has_point(point):
				pause_run()
				get_viewport().set_input_as_handled()
				return
			for id in action_buttons:
				var control: Button = action_buttons[id]
				if control.visible and control.get_global_rect().has_point(point):
					touch_actions[event.index] = id
					if id == "jump": press_jump(touch_source)
					elif id == "attack": press_attack(touch_source)
					elif id == "shoot": press_shoot(touch_source)
					else: press_duck(touch_source)
					get_viewport().set_input_as_handled()
					return
	if event is InputEventMouseButton and event.device == -1 and page == "":
		get_viewport().set_input_as_handled()
		return
	# Releases are observed before GUI dispatch so dragging away from a control
	# or opening a menu can never leave glide/boost latched on.
	if event is InputEventKey and not event.pressed:
		if event.keycode == KEY_SPACE: release_jump("key")
		if event.keycode == KEY_SHIFT: release_boost("shift")
		if event.keycode == KEY_J: release_attack("key")
		if event.keycode == KEY_F: release_shoot("key")
		if event.keycode in [KEY_DOWN, KEY_S, KEY_CTRL]: release_duck("key:" + str(event.keycode))
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed: release_shoot("mouse")
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		release_jump("mouse")
		release_boost("mouse")
		release_attack("mouse")
	if event is InputEventScreenTouch and not event.pressed:
		release_jump("touch:" + str(event.index))
		release_boost("touch:" + str(event.index))
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if language_picker_open:
				language_picker_open = false
				language_picker.hide()
				web_stamp = ""
				get_viewport().set_input_as_handled()
				return
			if page == "": pause_run()
			elif page == "paused": resume_run()
			elif page in ["characters", "settings"]: show_page(return_page)
			elif page == "finished": main_menu()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_SPACE and page == "":
			press_jump("key")
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F and page == "":
			press_shoot("key")
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_J and page == "":
			press_attack("key")
			get_viewport().set_input_as_handled()
		elif event.keycode in [KEY_DOWN, KEY_S, KEY_CTRL] and page == "":
			press_duck("key:" + str(event.keycode))
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_SHIFT and page == "":
			press_boost("shift")
			get_viewport().set_input_as_handled()
		elif event.keycode in [KEY_SPACE, KEY_ENTER] and page == "main" and not language_picker_open:
			var focused := get_viewport().gui_get_focus_owner()
			if focused == null or not (str(focused.name).begins_with("StartSelect_") or str(focused.name) == "LanguageMenu"):
				start_run()
				get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F11:
			fullscreen = not fullscreen
			apply_fullscreen()
			save_settings()
	if gamepad.handle(event): get_viewport().set_input_as_handled()

func on_gamepad_connection(id: int,connected: bool) -> void:
	if not connected and gamepad.device==id:
		clear_held_controls()
		gamepad.clear()
		if page=="": pause_run()

func _unhandled_input(event: InputEvent) -> void:
	if page != "": return
	if event is InputEventScreenTouch and event.pressed:
		if is_instance_valid(pause_button) and pause_button.get_global_rect().has_point(screen_transform.affine_inverse() * event.position): return
		var source := "touch:" + str(event.index)
		if on_wolf(to_game_point(event.position)): press_boost(source)
		else: press_jump(source)
		get_viewport().set_input_as_handled()
	if event is InputEventMouseButton and event.device != -1 and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		press_shoot("mouse")
		get_viewport().set_input_as_handled()
	if event is InputEventMouseButton and event.device != -1 and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		press_attack("mouse")
		get_viewport().set_input_as_handled()

func _physics_process(dt: float) -> void:
	gamepad.step(dt)
	world.character = character
	if page == "" or (world.state in ["fire", "ice", "bonk", "fall"] and page == "finished"):
		world.step(dt)
	if world.event_id != last_event:
		last_event = world.event_id
		if world.pending_events.is_empty(): handle_event(world.last_event)
		else:
			for value in world.pending_events: handle_event(value)
			world.pending_events.clear()
	if world.state in ["fire", "ice", "bonk", "fall"] and world.hit_time > 1.45 and not finished_panel:
		finished_panel = true
		save_settings()
		show_page("finished")
	if world.state == "running":
		if not world.practice: best = maxi(best, world.score)
		notice_time = maxf(0.0, notice_time - dt)
	if page == "main" and motion:
		menu_clock += dt
	for p in particles:
		if world.state != "paused":
			p.position += p.velocity * dt
			p.velocity.y += 190.0 * dt
			p.life -= dt
	particles = particles.filter(func(p): return p.life > 0.0)
	if world.state != "paused" and not world.adventure.hugging(): visual_size = move_toward(visual_size, world.adventure.size_multiplier(), dt * 3.0) if motion else world.adventure.size_multiplier()
	apply_scene_transform()
	update_friend()
	update_hud()
	evolution_view.z_index = 1 if world.adventure.hugging() else 0
	evolution_view.queue_redraw()
	frontier_view.queue_redraw()
	adventure_view.queue_redraw()
	queue_redraw()

func handle_event(value: String) -> void:
	if value == "boss_return" and world.practice:
		world.state = "ready"
		show_page("bosses")
	if value == "level_up":
		best_level = maxi(best_level,world.adventure.level)
		notice = text("level_up") % world.adventure.level
		notice_time = 1.5
		tone(1180,0.13)
		save_settings()
	if value == "hug_start":
		clear_held_controls()
		notice = text("hug_notice")
		notice_time = 1.0
	if value in ["boss_intro","boss_fight","boss_return","boss_player_hit"]:
		notice = text(value)
		notice_time = 2.5
		if value == "boss_intro": clear_held_controls()
		tone(460 if value == "boss_player_hit" else 780,0.1)
		return
	if value == "boss_won":
		notice = text(value) % (500+world.frontier.milestone*10)
		notice_time = 2.6
		tone(1046,0.24)
		return
	if value == "carrier_down":
		notice = text(value)
		notice_time = 1.0
		return
	if value == "gate_boost":
		notice = text("gate_boost")
		notice_time = 1.2
		tone(1180,0.1)
		return
	if value == "shot":
		tone(980,0.035)
		return
	if value == "hug_end":
		notice = text("hug_happy")
		notice_time = 1.7
		tone(980,0.12)
	if value.begins_with("power_"):
		notice = text(value)
		notice_time = 1.8
		burst(Vector2(World.PLAYER_X, ground + world.y - 40), Color("bce8ff"), 16)
		tone(1050, 0.14)
		save_settings()
	if value.begins_with("attack_"): tone(390 if character in ["wolf", "sheep"] else 620, 0.055)
	if value in ["enemy_down", "enemy_hit", "stomp", "smash", "shield_saved", "giant_hit", "lightning_cast", "goal_done"]:
		notice = text(value)
		notice_time = 0.8
		burst(Vector2(World.PLAYER_X + 55, ground + world.y - 45), Color("ffe0a6"), 9)
		tone(820 if value == "stomp" else 290, 0.07)
	if value == "thunder": tone(84, 0.22)
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
	if value == "updraft":
		notice = text("updraft")
		notice_time = 1.25
		burst(Vector2(World.PLAYER_X, ground + world.y - 40), Color("c5f7f1"), 10)
		tone(1150, 0.16)
	if value == "land": burst(Vector2(World.PLAYER_X, ground), Color("b9c4d1"), 6)
	if value in ["gem", "clear", "biome"]:
		notice = text(value)
		notice_time = 1.0 if value != "biome" else 2.2
		if value == "gem":
			burst(Vector2(World.PLAYER_X, ground + world.y - 35), Color("9cffe0"), 12)
			tone(1080, 0.1)
		elif value == "biome": tone(740, 0.18)
		elif world.combo % 5 == 0: tone(840, 0.1)
	if value in ["ice", "fire", "bonk", "fall"]:
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
	biome_label.text = "%02d  /  " % (world.biome()+1) + text(["desert","snow","swamp","city"][world.biome()])
	biome_label.text += "  ·  " + text("weather_" + world.adventure.weather)
	var powers: Array[String] = []
	for id in world.adventure.powers:
		if float(world.adventure.powers[id]) > 0.0: powers.append(text("power_" + id) + " " + str(ceili(world.adventure.powers[id])) + "s")
	if world.adventure.rush_time > 0.0: powers.append(text("gate_rush") % ceili(world.adventure.rush_time))
	if world.adventure.lightning_charges > 0: powers.append(text("power_lightning") + " ×" + str(world.adventure.lightning_charges))
	if is_instance_valid(power_label): power_label.text = (" · ".join(powers) if not powers.is_empty() else text("power_hint")) + "  |  " + text("defeated") % world.adventure.kills + "  |  " + str(roundi(world.speed() / 320 * 100)) + "%"
	if is_instance_valid(goal_label):
		var goal: Dictionary = world.adventure.goal_info()
		goal_label.text = text("goal_" + goal.kind) % [mini(goal.progress, goal.target), goal.target]
		goal_label.visible = page == "" and not world.frontier.active()
	var boss = world.frontier
	boss_label.visible = boss.active() and page in ["","paused"]
	boss_bar.visible = boss_label.visible
	boss_bar.max_value = maxi(1,boss.max_hp)
	boss_bar.value = boss.hp
	footer_label.text = text("boss_fight") if boss.active() else text("hint")
	boss_label.text = text(["boss_name","boss_ray","boss_root"][boss.boss_kind]) + "  ·  %d/%d  ·  " % [boss.hp,boss.max_hp] + text("boss_hearts") % boss.player_hp
	if boss.warning != "": boss_label.text += " · " + text("boss_pattern_"+boss.pattern) + " · " + text("boss_dodge_"+boss.warning)
	var ids: Array = ["jump","duck","shoot"] if boss.active() else ["jump","attack","duck"]
	for id in action_buttons:
		var index: int = ids.find(id)
		action_buttons[id].visible = page == "" and world.state == "running" and index >= 0
		if index >= 0: position_control(action_buttons[id],Vector2(view_w-420+index*132,view_h-89),Vector2(124,72))
	if action_buttons.has("attack"):
		action_buttons.attack.modulate.a = 0.70 if world.adventure.attack_cooldown > 0 else 1.0
		action_buttons.jump.modulate = Color("a9ead9") if world.jump_held else Color.WHITE
		action_buttons.duck.modulate = Color("a9ead9") if world.adventure.ducking(world) else Color.WHITE
	level_label.visible = page == "" or page == "paused"
	level_progress.visible = level_label.visible
	level_label.text = (text("level_short") % world.adventure.level) + " · " + (text("level_requirements") % [mini(30,int(world.adventure.level_elapsed)),mini(12000,int(world.adventure.level_distance(world)))])
	level_progress.value = world.adventure.level_progress(world)
	for control in action_buttons.values(): control.disabled = world.adventure.hugging()
	progress.value = fmod(world.distance, World.BIOME_DISTANCE)
	pause_button.visible = page == "" and world.state == "running"
	notice_label.text = text("saved_error") if save_failed else (notice if notice_time > 0.0 and page == "" else "")
	if is_instance_valid(ability_label):
		ability_label.text = text("ability_" + character)
		if world.frontier.active(): ability_label.text = text("boss_hearts") % world.frontier.player_hp
		elif character == "sheep": ability_label.text = text("flock") % world.sheep_count
		elif world.riding_gust: ability_label.text = text("riding_gust") if world.wind_kind() == "up" else text("riding_"+world.wind_kind())
		elif world.gliding: ability_label.text = text("gliding")
		elif world.boosting(): ability_label.text = text("boosting")
	publish_web_status()

func publish_web_status() -> void:
	if not OS.has_feature("web"): return
	var stamp := "%s:%s:%d:%s:%s:%s:%d:%s:%s:%d" % [world.state, page, world.score, character, language, world.y < 0.0, world.jumps_used, world.gliding, world.boosting(), world.sheep_count]
	stamp += ":" + str(world.adventure.hug_time) + ":" + str(world.adventure.attack_variant) + ":" + str(world.adventure.mushroom_chance) + ":" + str(prism_intensity)
	stamp += ":" + world.frontier.phase + ":" + str(world.frontier.hp) + ":" + str(world.frontier.shot_flash)
	stamp += ":" + str(language_picker_open)
	stamp += ":" + str(effects_enabled) + ":" + str(motion) + ":" + str(audio_enabled) + ":" + str(world.adventure.celebrations_enabled)
	stamp += ":%.2f:%s:%d:%d:%s" % [world.y, world.riding_gust, friend_row, friend_frame, friend_action]
	if character == "sheep": stamp += ":%.2f:%.2f" % [world.flock_pose(0).y, world.flock_pose(1).y]
	stamp += ":%.2f:%s:%s:%d:%d" % [world.time, world.adventure.ducking(world), world.adventure.giant(), world.adventure.kills, friend_combat]
	for scroll in ui.find_children("*", "VScrollBar", true, false): stamp += ":" + str(scroll.value)
	for field in settings_inputs.values(): stamp += ":" + str(field.get_global_rect())
	var focused: Control = get_viewport().gui_get_focus_owner()
	stamp += ":"+str(focused.get_instance_id()) if is_instance_valid(focused) else ":none"
	if stamp == web_stamp: return
	web_stamp = stamp
	var document = JavaScriptBridge.get_interface("document")
	var canvas = document.getElementById("canvas")
	if canvas == null: return
	canvas.setAttribute("data-ui-ready", str(ui_layout_ready))
	canvas.setAttribute("data-level-elapsed",str(world.adventure.level_elapsed))
	canvas.setAttribute("data-level-distance",str(world.adventure.level_distance(world)))
	canvas.setAttribute("data-celebration-x",str(world.adventure.celebration_x(world,motion)))
	canvas.setAttribute("data-celebration-time",str(world.adventure.celebration_time))
	canvas.setAttribute("data-girl-facing","left")
	canvas.setAttribute("data-rush-time",str(world.adventure.rush_time))
	canvas.setAttribute("data-attack-kind","peck" if world.adventure.attack_airborne else ("sprint-bite" if character=="wolf" and world.adventure.attack_sprinting else ("bite" if world.adventure.attack_variant==0 else "claw") if character=="wolf" else "melee"))
	canvas.setAttribute("data-visual-x",str(friend_sprite.position.x))
	canvas.setAttribute("data-combat-lunge",str(combat_lunge().x))
	var gaze: Vector2 = friend_sprite.get_meta("eye_world",Vector2.ZERO)
	canvas.setAttribute("data-gaze-x",str(gaze.x))
	canvas.setAttribute("data-pose-source",str(friend_sprite.get_meta("source_key","")))
	canvas.setAttribute("data-source-frame",str(friend_sprite.get_meta("source_frame",0)))
	canvas.setAttribute("data-source-row",str(friend_sprite.get_meta("source_row",0)))
	canvas.setAttribute("data-boss-active",str(world.frontier.active()))
	canvas.setAttribute("data-boss-phase",world.frontier.phase)
	canvas.setAttribute("data-boss-kind",str(world.frontier.boss_kind))
	canvas.setAttribute("data-boss-pattern",world.frontier.pattern)
	canvas.setAttribute("data-boss-attacks",str(world.frontier.attacks_cast))
	canvas.setAttribute("data-practice",str(world.practice))
	canvas.setAttribute("data-death-cause",world.death_cause)
	canvas.setAttribute("data-follower-visible",JSON.stringify([followers[0].visible,followers[1].visible]))
	canvas.setAttribute("data-girl-ground",str(ground-58))
	var focus: Control = get_viewport().gui_get_focus_owner()
	canvas.setAttribute("data-focused",str(focus.name) if is_instance_valid(focus) else "")
	canvas.setAttribute("data-boss-hp",str(world.frontier.hp))
	canvas.setAttribute("data-boss-max-hp",str(world.frontier.max_hp))
	canvas.setAttribute("data-boss-player-hp",str(world.frontier.player_hp))
	canvas.setAttribute("data-boss-shots",str(world.frontier.shots_fired))
	canvas.setAttribute("data-boss-hits",str(world.frontier.hits))
	canvas.setAttribute("data-boss-wins",str(world.frontier.wins))
	canvas.setAttribute("data-boss-warning",world.frontier.warning)
	canvas.setAttribute("data-projectiles",JSON.stringify(world.frontier.projectiles))
	canvas.setAttribute("data-plants",JSON.stringify(world.frontier.plants))
	canvas.setAttribute("data-biome",str(world.biome()))
	canvas.setAttribute("data-hero-head-size",str(friend_sprite.get_meta("head_size",0)))
	canvas.setAttribute("data-isolated-frame",str(not friend_sprite.region_enabled))
	canvas.setAttribute("data-version", GAME_VERSION)
	canvas.setAttribute("data-audio-enabled",str(audio_enabled))
	canvas.setAttribute("data-motion-enabled",str(motion))
	canvas.setAttribute("data-celebrations-enabled",str(world.adventure.celebrations_enabled))
	canvas.setAttribute("data-player-x", str(World.PLAYER_X))
	canvas.setAttribute("data-ducking", str(world.adventure.ducking(world)))
	canvas.setAttribute("data-combat-row", str(friend_combat))
	canvas.setAttribute("data-attacking", str(world.adventure.attack_time > 0.0))
	canvas.setAttribute("data-attack-cooldown", str(world.adventure.attack_cooldown))
	canvas.setAttribute("data-giant", str(world.adventure.giant()))
	canvas.setAttribute("data-kills", str(world.adventure.kills))
	canvas.setAttribute("data-stomps", str(world.adventure.stomps))
	canvas.setAttribute("data-weather", world.adventure.weather)
	canvas.setAttribute("data-speed", str(world.speed()))
	canvas.setAttribute("data-orientation", "landscape")
	canvas.setAttribute("data-device-portrait", str(device_portrait))
	canvas.setAttribute("data-view-width", str(view_w))
	canvas.setAttribute("data-view-height", str(view_h))
	canvas.setAttribute("data-raw-width", str(get_viewport_rect().size.x))
	canvas.setAttribute("data-raw-height", str(get_viewport_rect().size.y))
	canvas.setAttribute("data-screen-transform", JSON.stringify([screen_transform.x.x,screen_transform.x.y,screen_transform.y.x,screen_transform.y.y,screen_transform.origin.x,screen_transform.origin.y]))
	var controls := {}
	for id in action_buttons:
		var button: Button = action_buttons[id]
		controls[id] = {"x":button.position.x,"y":button.position.y,"w":button.size.x,"h":button.size.y}
	canvas.setAttribute("data-controls", JSON.stringify(controls))
	var buttons: Array = []
	for node in ui.find_children("*", "Button", true, false):
		if node.is_visible_in_tree():
			var rect: Rect2 = node.get_global_rect()
			buttons.append({"text":node.text,"name":str(node.name),"x":rect.position.x,"y":rect.position.y,"w":rect.size.x,"h":rect.size.y})
	canvas.setAttribute("data-ui", JSON.stringify(buttons))
	canvas.setAttribute("data-goal", JSON.stringify(world.adventure.goal_info()))
	canvas.setAttribute("data-discoveries", JSON.stringify(world.adventure.discoveries))
	canvas.setAttribute("data-effects-enabled", str(effects_enabled))
	canvas.setAttribute("data-enemies", JSON.stringify(world.adventure.enemies))
	canvas.setAttribute("data-obstacles", JSON.stringify(world.obstacles))
	canvas.setAttribute("data-powers", JSON.stringify(world.adventure.powers))
	canvas.setAttribute("data-items", JSON.stringify(world.adventure.items))
	canvas.setAttribute("data-character-name", character_name(character))
	canvas.setAttribute("data-language-picker", str(language_picker_open))
	canvas.setAttribute("data-language-override", str(language_override))
	canvas.setAttribute("data-normal-height", str(NORMAL_HEIGHT))
	canvas.setAttribute("data-hero-opaque-height", str(registered_height(friend_sprite)))
	canvas.setAttribute("data-followers-opaque-height", JSON.stringify([registered_height(followers[0]), registered_height(followers[1])]))
	canvas.setAttribute("data-follower-ratio", str(FOLLOWER_RATIO))
	canvas.setAttribute("data-world-time",str(world.time))
	canvas.setAttribute("data-world-distance",str(world.distance))
	canvas.setAttribute("data-wind-kind",world.wind_kind())
	canvas.setAttribute("data-wind-push",str(world.wind_push))
	canvas.setAttribute("data-heart-time",str(world.adventure.heart_time))
	canvas.setAttribute("data-level",str(world.adventure.level))
	canvas.setAttribute("data-level-progress",str(world.adventure.level_progress(world)))
	canvas.setAttribute("data-best-level",str(best_level))
	canvas.setAttribute("data-hugging",str(world.adventure.hugging()))
	canvas.setAttribute("data-hug-time",str(world.adventure.hug_time))
	canvas.setAttribute("data-hug-count",str(world.adventure.hug_count))
	canvas.setAttribute("data-girl",str(world.adventure.girl_index))
	canvas.setAttribute("data-party-style",str(world.adventure.celebration_style))
	canvas.setAttribute("data-attack-variant",str(world.adventure.attack_variant))
	canvas.setAttribute("data-swing-count",str(world.adventure.swing_id))
	canvas.setAttribute("data-roll-frame",str(world.adventure.roll_frame()))
	canvas.setAttribute("data-mushroom-chance",str(world.adventure.mushroom_chance))
	canvas.setAttribute("data-prism-intensity",str(prism_intensity))
	var numeric_controls := {}
	for id in settings_inputs:
		var rect: Rect2 = settings_inputs[id].get_global_rect()
		numeric_controls[id] = {"x":rect.position.x,"y":rect.position.y,"w":rect.size.x,"h":rect.size.y}
	canvas.setAttribute("data-settings-inputs",JSON.stringify(numeric_controls))
	canvas.setAttribute("data-best", str(best))
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
	canvas.setAttribute("data-action-sheet", str(friend_action))
	canvas.setAttribute("data-wind-head", str(wolf_wind_ribbons()[0].points[0]) if world.boosting() and motion else "")
	canvas.setAttribute("data-player-y", str(world.y))
	canvas.setAttribute("data-riding-gust", str(world.riding_gust))
	canvas.setAttribute("data-follower-1-y", str(world.flock_pose(0).y))
	canvas.setAttribute("data-follower-2-y", str(world.flock_pose(1).y))
	canvas.setAttribute("data-next-gust", str(world.gusts[0].x) if not world.gusts.is_empty() else "-1")
	canvas.setAttribute("data-gust-width", str(world.gusts[0].width) if not world.gusts.is_empty() else "0")
	var next_x := -1.0
	for obstacle in world.obstacles:
		if obstacle.x > World.PLAYER_X - 35 and (next_x < 0 or obstacle.x < next_x): next_x = obstacle.x
	canvas.setAttribute("data-next-obstacle", str(next_x))
	canvas.setAttribute("data-next-sheep", str(world.sheep_pickups[0].x) if not world.sheep_pickups.is_empty() else "-1")

func animation_clock() -> float:
	if not motion: return 0.0
	return menu_clock if world.state == "ready" else world.time

func prepare_web_update(_arguments: Array) -> void:
	if world.state == "running": pause_run()
	save_settings()

func runner_region(id: String, row: int, frame: int) -> Rect2:
	var data: Dictionary = RUNNER_DATA.data.characters[id]
	var ys: Array = data.row_y
	return Rect2(frame * 181, ys[row], 181, ys[row + 1] - ys[row])

func update_friend() -> void:
	var a = world.adventure
	if world.state != "paused" or friend_character != character:
		friend_combat = -1
		if world.state == "running":
			if a.attack_time > 0.0: friend_combat = COMBAT_ROWS[character]
			elif a.ducking(world): friend_combat = COMBAT_ROWS[character] + 4
	friend_sprite.visible = true
	for item in followers: item.visible = false
	sheep_collectible.visible = character == "sheep" and not world.sheep_pickups.is_empty() and world.sheep_count < 3
	if sheep_collectible.visible:
		place_companion(sheep_collectible, "sheep", 7, frames.cycle("runner-sheep",0,animation_clock(),0.9), Vector2(world.sheep_pickups[0].x, ground), 0.46)

	if friend_character != character:
		friend_character = character
		friend_row = 0
		friend_frame = 0
		friend_action = false
	if world.state == "running":
		friend_action = world.boosting() or world.riding_gust
		friend_row = 6 if world.boosting() else 1
		# Strides follow distance so feet accelerate with the world and freeze on pause.
		friend_frame = frames.cycle("runner-"+character,friend_row,world.distance,174.0)
		if world.y < 0.0:
			friend_row = 6 if world.gliding else 2
			if world.gliding: friend_frame = frames.cycle("runner-"+character,6,animation_clock(),1.0)
			else: friend_frame = flight_frame(world.velocity, world.air_time, frames.count("runner-"+character,2))
			if character == "sheep": friend_action = true
			if character == "wolf": friend_action = false
			if character == "aion" and world.jumps_used == 2 and world.air_time < 0.4:
				friend_row = 6
				friend_frame = frames.progress("runner-aion",6,world.air_time/0.4)
		elif world.landing_time > 0.0:
			friend_row = 2
			friend_frame = frames.count("runner-"+character,2)-1
			friend_action = character == "sheep"
	elif world.state == "ready":
		friend_action = false
		friend_row = 0
		friend_frame = frames.cycle("runner-"+character,0,animation_clock(),1.5)
	elif world.state == "ice":
		friend_action = false
		friend_row = 3
		friend_frame = frames.progress("runner-"+character,3,world.hit_time/0.7) if motion else frames.count("runner-"+character,3)-1
	elif world.state in ["fire", "bonk"]:
		friend_action = false
		friend_row = 4 if world.hit_time < 0.75 and motion else 5
		friend_frame = frames.progress("runner-"+character,4,world.hit_time/0.7) if friend_row == 4 else (frames.cycle("runner-"+character,5,world.hit_time,1.2) if motion else 0)
	if world.state == "fall":
		friend_action = false
		friend_row = 2
		friend_frame = frames.count("runner-"+character,2)-3
	if a.hugging():
		friend_row = 0
		friend_frame = 4
		friend_action = false
	if not motion and world.state not in ["ice", "fire", "bonk", "fall"]: friend_frame = 0
	place_companion(friend_sprite, character, friend_row, friend_frame, Vector2(World.PLAYER_X, ground + world.y), 0.62 * visual_size, friend_action)
	if friend_combat >= 0:
		var pose_spec := combat_pose(character,friend_combat >= 4 or a.ducking(world))
		var combat_count := frames.count(pose_spec.key,pose_spec.row)
		var combat_frame: int = (contact_frame(combat_count) if friend_combat < 4 else a.roll_frame(combat_count)) if motion else combat_count/2
		var combat_anchor := Vector2(World.PLAYER_X,ground+world.y)+combat_lunge()
		place_combat(friend_sprite, character, friend_combat, combat_frame, combat_anchor, visual_size, friend_combat >= 4 or a.ducking(world))
	if world.state in ["running","paused"] and world.frontier.active() and not a.ducking(world) and (world.frontier.phase != "intro" or world.frontier.stage_time > 0.75):
		var firing: bool = world.frontier.shot_flash>0
		var key := "gun-fire" if firing else "gun-run"
		var row: int = COMBAT_ROWS[character]
		var shooting: int = world.frontier.gun_frame(frames.count(key,row)) if firing else frames.cycle(key,row,world.travel_distance(),174.0)
		if not motion: shooting = 3 if firing else 0
		frames.place(friend_sprite,key,row,shooting,Vector2(World.PLAYER_X,ground+world.y))
	if world.state == "bonk":
		var row: int = COMBAT_ROWS[character]*2+(1 if world.death_cause=="enemy" else 0)
		frames.place(friend_sprite,"deaths",row,frames.progress("deaths",row,world.hit_time/1.25) if motion else frames.count("deaths",row)-1,Vector2(World.PLAYER_X,ground+world.y),visual_size)

	friend_sprite.modulate = Color.WHITE
	if character == "sheep":
		for i in 2:
			followers[i].visible = world.sheep_count > i + 1 and world.state not in ["fire", "ice", "bonk", "fall"]
			var pose: Dictionary = world.flock_pose(i)
			var in_air: bool = float(pose.y) < -0.01
			var landing: bool = float(pose.landing_time) > 0.0
			var row := 2 if in_air or landing else (0 if world.state == "ready" else 1)
			var frame := flight_frame(float(pose.velocity), float(pose.air_time), frames.count("runner-sheep",2)) if in_air else (frames.count("runner-sheep",2)-1 if landing else frames.cycle("runner-sheep",1,world.travel_distance()-World.FLOCK_GAP*(i+1),174.0))
			place_companion(followers[i], "sheep", row, frame if motion else 0, Vector2(World.PLAYER_X - World.FLOCK_GAP * (i + 1), ground + float(pose.y)), 0.62 * FOLLOWER_RATIO, in_air or landing)
			if float(pose.get("duck", 0.0)) > 0.5:
				place_combat(followers[i], "sheep", 6, posmod(int(float(pose.get("roll_phase",0.0))/0.68*frames.count("rolls",2)),frames.count("rolls",2)) if motion else 4, Vector2(World.PLAYER_X - World.FLOCK_GAP * (i + 1), ground + float(pose.y)), FOLLOWER_RATIO, true)
		if world.invulnerable > 0.0 and motion and int(world.time * 12) % 2 == 0: friend_sprite.modulate.a = 0.45

func combat_pose(id: String,crouch: bool) -> Dictionary:
	if crouch: return {"key":"rolls","row":COMBAT_ROWS[id]}
	if id=="owl" and world.adventure.attack_airborne: return {"key":"owl-peck","row":0}
	if id=="wolf" and world.adventure.attack_sprinting: return {"key":"wolf-dash-bite","row":0}
	return {"key":"strikes","row":COMBAT_ROWS[id]*2+world.adventure.attack_variant}

func contact_frame(frame_count: int) -> int:
	var a = world.adventure
	if character!="wolf" or (not a.attack_sprinting and a.attack_variant!=0): return a.attack_frame(frame_count)
	# Let the open jaws read at contact; the snap still occurs in the hit window.
	var phase: float = clampf((a.ATTACK_DURATION-a.attack_time)/a.ATTACK_DURATION,0,1)
	var ends := [0.10,0.20,0.32,0.60,0.72,0.82,0.90,1.01]
	for i in ends.size():
		if phase<float(ends[i]): return mini(i,frame_count-1)
	return frame_count-1

func combat_lunge() -> Vector2:
	var a = world.adventure
	if a.attack_time<=0 or a.ducking(world): return Vector2.ZERO
	var phase: float = clampf((a.ATTACK_DURATION-a.attack_time)/a.ATTACK_DURATION,0,1)
	var pulse := sin(phase*PI)
	if character=="wolf": return Vector2(48 if a.attack_sprinting else (34 if a.attack_variant==0 else 24),-3)*pulse
	if character=="owl": return Vector2(18 if a.attack_airborne else 0,0)*pulse
	if character=="sheep": return (Vector2(6,5) if a.attack_variant==0 else Vector2(-24,0))*pulse
	return Vector2.ZERO

func place_combat(item: Sprite2D,id: String,row: int,frame: int,anchor: Vector2,growth: float,crouch: bool) -> void:
	var spec := combat_pose(id,crouch)
	frames.place(item,spec.key,spec.row,frame,anchor,growth)

func registered_height(item: Sprite2D) -> float:
	return float(item.get_meta("pose_height",0.0)) if item.visible else 0.0

func flight_frame(velocity: float, air_time: float, frame_count: int = 12) -> int:
	if air_time < 0.03: return 0
	var phase := 0.5 + clampf(velocity / absf(World.JUMP_SPEED),-1.0,1.0)*0.5
	return clampi(int(phase*(frame_count-1)),0,frame_count-2)

func place_companion(item: Sprite2D, id: String, row: int, frame: int, anchor: Vector2, scale_value: float = 0.62, action: bool = false) -> void:
	var key := "actions" if action else "runner-"+id
	var actual_row: int = int(ACTION_DATA.data.characters[id].row) if action else row
	frames.place(item,key,actual_row,frame,anchor,scale_value/0.62)

# Moving ribbons flow away from the wolf with independent offsets, curved paths,
# lengths and fade envelopes. Derived from the paused simulation clock, not FPS.
func wolf_wind_ribbons() -> Array[Dictionary]:
	var ribbons: Array[Dictionary] = []
	if not motion: return ribbons
	var clock := animation_clock()
	for i in 12:
		var phase := fposmod(clock * (2.0 + i * 0.09) + i * 0.173, 1.0)
		var origin := Vector2(World.PLAYER_X - 34.0 - phase * 145.0, ground + world.y - 44.0 + float(i % 5 - 2) * 14.0 + sin(clock * 4.0 + i) * 7.0)
		var length := 16.0 + 27.0 * sin(phase * PI)
		var points := PackedVector2Array()
		for j in 6:
			var portion := float(j) / 5.0
			points.append((origin - Vector2(portion * length, sin(portion * PI + clock * 5 + i) * 6.0)).round())
		ribbons.append({"points":points, "alpha":sin(phase * PI) * 0.72, "width":2.0 if i % 3 else 3.0})
	return ribbons

func draw_wind() -> void:
	if character == "wolf" and (world.boosting() or (world.state == "paused" and friend_row == 6)):
		for ribbon in wolf_wind_ribbons():
			var color := Color("d5d0ff")
			color.a = ribbon.alpha
			draw_polyline(ribbon.points, color, ribbon.width)
	# Updraft markers are gameplay cues, so they remain visible with motion off.
	for gust in world.gusts:
		var center: float = gust.x
		var kind: String = gust.get("kind","up")
		var width: float = gust.width
		draw_rect(Rect2(center - width * 0.5, ground - 255, width, 218), Color(0.58, 0.93, 0.89, 0.045))
		for i in 14:
			var phase := fposmod(animation_clock() * (0.55 + i * 0.027) + i * 0.231, 1.0)
			var x := center + sin(animation_clock() * 2.0 + i * 1.7) * width * 0.35
			var y := ground - 35 - phase * 216.0
			var color := Color("c5f7f1")
			color.a = 0.25 + sin(phase * PI) * 0.45
			var points := PackedVector2Array([Vector2(x-12,y+7),Vector2(x,y),Vector2(x+12,y+7)])
			if kind == "forward": points = PackedVector2Array([Vector2(x-7,y-12),Vector2(x,y),Vector2(x-7,y+12)])
			elif kind == "diagonal": points = PackedVector2Array([Vector2(x-14,y),Vector2(x,y-6),Vector2(x,y+8)])
			draw_polyline(points, color, 2.0)
		if character == "owl":
			draw_string(FONT, Vector2(center - 46, ground - 273), text("gust_"+kind), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("b5e8dd"))

func sprite(row: int, frame: int, x: float, bottom: float, width: float) -> void:
	var sy := roundf(float(row) * 1254.0 / 8.0)
	var sh := roundf(float(row + 1) * 1254.0 / 8.0) - sy
	draw_texture_rect_region(SHEET, Rect2(roundf(x), roundf(bottom - width * sh / 209.0), width, width * sh / 209.0), Rect2(frame * 209, sy, 209, sh))

func _draw() -> void:
	if not is_instance_valid(ui): return
	draw_scenery()
	draw_wind()
	if character == "sheep" and not world.sheep_pickups.is_empty() and world.sheep_count < 3:
		var x: float = world.sheep_pickups[0].x
		draw_rect(Rect2(x - 10, ground - 104, 20, 20), Color("9ce4cc"))
		draw_line(Vector2(x - 5, ground - 94), Vector2(x + 5, ground - 94), Color("102b30"), 3)
		draw_line(Vector2(x, ground - 99), Vector2(x, ground - 89), Color("102b30"), 3)
	for o in world.obstacles:
		if str(o.kind).begins_with("arch") or str(o.kind).begins_with("carrier") or o.kind == "gate" or str(o.kind).begins_with("block") or str(o.kind).begins_with("pit"): continue
		var effect: Dictionary = frames.pose("hazards",0 if o.kind == "ice" else 1,frames.cycle("hazards",0 if o.kind == "ice" else 1,animation_clock(),0.7))
		var tex: Texture2D = effect.texture
		var factor := 76.0/float(tex.get_width())
		draw_texture_rect(tex,Rect2(Vector2(o.x-38,ground+3-tex.get_height()*factor).round(),tex.get_size()*factor),false)
	for pickup in world.pickups:
		var point := Vector2(pickup.x, ground + pickup.y)
		var bob := sin(animation_clock() * 4.0 + pickup.x * 0.01) * 4.0
		point.y += bob
		var diamond := PackedVector2Array([point + Vector2(0, -12), point + Vector2(9, 0), point + Vector2(0, 12), point + Vector2(-9, 0)])
		draw_colored_polygon(diamond, Color("8befd1"))
		draw_line(point + Vector2(0, -8), point + Vector2(-5, 0), Color("e0fff0"), 3)
	# Soft pixel shadow remains on the floor while the character jumps.
	draw_rect(Rect2(World.PLAYER_X - 35, ground - 2, 70, 5), Color(0.02, 0.04, 0.09, 0.4))
	if character == "sheep":
		for i in maxi(0, world.sheep_count - 1):
			draw_rect(Rect2(World.PLAYER_X - World.FLOCK_GAP * (i + 1) - 30, ground - 2, 60, 5), Color(0.02, 0.04, 0.09, 0.3))
	for p in particles:
		var c: Color = p.color
		c.a = minf(1.0, p.life * 3.0)
		draw_rect(Rect2(p.position.round(), Vector2(4, 4)), c)

func draw_scenery() -> void:
	var time: float = world.time
	var scroll: float = world.frontier.chase_distance if world.frontier.active() else world.distance
	if world.state == "ready":
		time = menu_clock
		scroll = menu_clock*20.0
	if not motion: scroll = 0.0
	var night := (cos(time*TAU/72.0)+1.0)/2.0
	var weights := [0.0,0.0,0.0,0.0]
	var biome: int = world.biome()
	var blend := 1.0 if world.distance < World.BIOME_DISTANCE else smoothstep(0.0,0.08,fmod(world.distance/World.BIOME_DISTANCE,1.0))
	weights[biome] = blend
	weights[posmod(biome-1,4)] += 1.0-blend
	var days := [Color("e5a58b"),Color("7396b0"),Color("6b9476"),Color("9183ad")]
	var nights := [Color("3b3655"),Color("253f59"),Color("193c3a"),Color("272d4d")]
	var floors := [Color("553e50"),Color("233b51"),Color("193e39"),Color("2d3445")]
	var edges := [Color("c48d91"),Color("c4e7f0"),Color("a5bd7c"),Color("a7b7c8")]
	var top := Color("355c80").lerp(Color("0c142a"),night)
	var bottom := Color(0,0,0,1)
	var floor_color := Color(0,0,0,1)
	var edge_color := Color(0,0,0,1)
	for n in 4:
		bottom += days[n].lerp(nights[n],night)*float(weights[n])
		floor_color += floors[n]*float(weights[n])
		edge_color += edges[n]*float(weights[n])
	bottom.a = 1.0
	floor_color.a = 1.0
	edge_color.a = 1.0
	for i in 48:
		var fraction := float(i)/48.0
		draw_rect(Rect2(0,fraction*ground,view_w,ground/48.0+1),top.lerp(bottom,fraction))
	for i in 45:
		var x := fposmod(float(i*173+51)-scroll*0.018,view_w)
		var y := 151.0+fposmod(float(i*67),maxf(60,ground-280))
		draw_rect(Rect2(roundf(x),roundf(y),2 if i%4 else 4,2 if i%4 else 4),Color(0.85,0.91,1.0,night*(0.32+0.5*float(i%3)/2.0)))
	var moon := Vector2(view_w*0.77,224)
	draw_rect(Rect2(moon-Vector2(26,30),Vector2(52,60)),Color("f5dfbc").lerp(Color("f3ba89"),1-night))
	draw_rect(Rect2(moon-Vector2(33,19),Vector2(66,38)),Color("f5dfbc").lerp(Color("f3ba89"),1-night))
	for layer in 3:
		var base := ground-14.0+float(layer)*6
		var spacing := 235.0+float(layer)*95
		var offset := fposmod(scroll*(0.08+float(layer)*0.09),spacing)
		for i in range(-1,int(view_w/spacing)+2):
			var x := float(i)*spacing-offset
			var height := 100.0+float((i+22)%3)*31-float(layer)*19
			var color := Color("6d5266").lerp(Color("25304f"),night).lerp(Color("355774"),weights[1]).lerp(Color("234b43"),weights[2]).lerp(Color("353958"),weights[3]).darkened(float(layer)*0.15)
			var points := PackedVector2Array([Vector2(x,base),Vector2(x,base-29),Vector2(x+35,base-29),Vector2(x+35,base-height*0.55),Vector2(x+62,base-height*0.55),Vector2(x+62,base-height),Vector2(x+123,base-height),Vector2(x+123,base-height*0.72),Vector2(x+161,base-height*0.72),Vector2(x+161,base-height*0.35),Vector2(x+spacing,base-height*0.35),Vector2(x+spacing,base)])
			draw_colored_polygon(points,color)
			if weights[1] > 0 and layer<2: draw_rect(Rect2(x+62,base-height,61,8),Color(0.75,0.85,0.9,float(weights[1])*0.65))
			if weights[3] > 0:
				for row in 3:
					for col in 3: draw_rect(Rect2(x+68+col*15,base-height+15+row*19,6,9),Color(0.92,0.74,0.48,float(weights[3])*(0.35+night*0.35)))
	evolution_view.draw_scene(self,true)
	for kind in 4:
		var alpha: float = weights[kind]
		if alpha <= 0: continue
		for i in range(-1,int(view_w/275)+2):
			var x := float(i)*275-fposmod(scroll*0.55,275)
			var c := Color("263b48")
			c.a = alpha
			match kind:
				0:
					draw_rect(Rect2(x+26,ground-71,14,71),c)
					draw_rect(Rect2(x+3,ground-51,37,10),c)
					draw_rect(Rect2(x+3,ground-68,10,23),c)
					draw_rect(Rect2(x+32,ground-38,34,10),c)
					draw_rect(Rect2(x+56,ground-59,10,29),c)
				1:
					draw_rect(Rect2(x+30,ground-75,8,75),c)
					for j in 3:
						draw_rect(Rect2(x+18-j*9,ground-85+j*19,32+j*18,21),c)
						draw_rect(Rect2(x+18-j*9,ground-85+j*19,32+j*18,4),Color(0.72,0.83,0.88,alpha))
				2:
					draw_rect(Rect2(x+40,ground-128,13,128),Color(0.18,0.29,0.24,alpha))
					for j in 4:
						var leaf := Vector2(x+12+j*20,ground-135+absf(j-1.5)*10)
						draw_rect(Rect2(leaf,Vector2(55,24)),Color(0.18,0.38,0.27,alpha))
						draw_line(leaf+Vector2(12,19),leaf+Vector2(12,75+sin(time+j)*7),Color(0.32,0.49,0.33,alpha),3)
					draw_rect(Rect2(x+80,ground-8,125,5),Color(0.4,0.7,0.58,alpha*0.4))
					for j in 4: draw_rect(Rect2(x+80+j*33,ground-46-sin(time*0.8+j)*12,3,3),Color(0.85,0.94,0.46,alpha*0.65))
				3:
					draw_rect(Rect2(x+16,ground-145,86,145),Color(0.16,0.19,0.29,alpha))
					draw_rect(Rect2(x+12,ground-150,94,6),Color(0.46,0.48,0.58,alpha))
					for j in 4:
						for k in 3: draw_rect(Rect2(x+27+k*24,ground-130+j*28,10,15),Color(0.92,0.73,0.47,alpha*(0.5+night*0.35)))
					draw_rect(Rect2(x+145,ground-106,5,106),c)
					draw_rect(Rect2(x+130,ground-110,35,7),Color(0.98,0.82,0.5,alpha))
	draw_rect(Rect2(0,ground,view_w,view_h-ground),floor_color)
	draw_rect(Rect2(0,ground,view_w,4),edge_color)
	draw_rect(Rect2(0,ground+4,view_w,10),floor_color.lightened(0.22))
	for i in range(-1,int(view_w/43)+2):
		var x := float(i)*43-fposmod(scroll,43)
		draw_rect(Rect2(x,ground+27+(i%3)*7,9,3),edge_color.darkened(0.25))
	draw_rect(Rect2(0,view_h-98,view_w,98),Color("101a2d"))
	draw_line(Vector2(32,view_h-98),Vector2(view_w-32,view_h-98),Color("31415a"),1)
	if weights[1]>0.4:
		for i in 28:
			var x := fposmod(float(i*109)-scroll*0.15,view_w)
			var y := 150.0+fposmod(float(i*73)+(time*24.0 if motion else 0.0),maxf(1,ground-150))
			draw_rect(Rect2(x,y,3,3),Color(0.88,0.96,1.0,float(weights[1])*0.5))

func start_boss_practice(kind: int) -> void:
	start_run()
	world.practice = true
	if character=="sheep": world.sheep_count = 3
	world.frontier.request_boss((clampi(kind,0,2)+1)*10)

func retry_run() -> void:
	if world.practice: start_boss_practice(world.frontier.boss_kind)
	else: start_run()
