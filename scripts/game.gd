extends Node2D

const World = preload("res://scripts/world.gd")
const Words = preload("res://scripts/text.gd")
const SHEET = preload("res://assets/aion-runner.png")
const FONT = preload("res://assets/PixelifySans.ttf")
const RUNNER_SHEETS = {"wolf":preload("res://assets/wolf-runner.png"), "sheep":preload("res://assets/sheep-runner.png"), "owl":preload("res://assets/owl-runner.png")}
const RUNNER_DATA = preload("res://assets/FULL-RUNNER-PROVENANCE.json")
const ACTION_SHEET = preload("res://assets/companion-actions.png")
const ACTION_DATA = preload("res://assets/ACTION-PROVENANCE.json")
const COMBAT_SHEET = preload("res://assets/evolution-strikes.png")
const ADVENTURE_DATA = preload("res://assets/ADVENTURE-PROVENANCE.json")
const COMBAT_ROWS := {"aion":0,"owl":1,"sheep":2,"wolf":3,"rabbit":4,"eren":5}
const GAME_VERSION = "0.22.0"
const ROLL_SHEET = preload("res://assets/evolution-rolls.png")
const EVOLUTION_DATA = preload("res://assets/EVOLUTION-PROVENANCE.json")
const COMPANION_RUN_ROWS := {"wolf":1,"sheep":1,"owl":1}
const REGISTRATION = preload("res://assets/SPRITE-REGISTRATION.json")
const NORMAL_HEIGHT := 90.0
const FOLLOWER_RATIO := 0.72
const FRIENDS := ["aion", "sheep", "wolf", "owl", "rabbit", "eren"]
const COLORS := [Color("f4a7cd"), Color("ffca84"), Color("b8baf0"), Color("b8ebd3")]
var interface_options := preload("res://scripts/interface_options.gd").new()
var native_diagnostics := preload("res://scripts/native_diagnostics.gd").new()
var web_accessibility := preload("res://scripts/web_accessibility.gd").new()
var active_input := "keyboard"
var theme_check := 0.0
var story_ui := preload("res://scripts/boss_story.gd").new()
var pixel_ui := preload("res://scripts/pixel_interface.gd").new()
var touch_controls := preload("res://scripts/touch_controls.gd").new()
var scene_w := 1152.0
var scene_h := 648.0
var scene_zoom := 1.0
var touch_mode := false
var landscape := preload("res://scripts/landscape_view.gd").new()
var terrain := preload("res://scripts/terrain_view.gd").new()
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
var ammo_label: Label
var level_label: Label
var xp_label: Label
var xp_progress: ProgressBar
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
var touch_tutorial_done := false
var tutorial_panel: Control
var fragaria_panel: Control
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
var gun_parts := {}
var gun_echo: Sprite2D
var friend_sprite: Sprite2D
var followers: Array[Sprite2D] = []
var sheep_collectible: Sprite2D
var friend_row := 0
var friend_frame := 0
var friend_character := ""
var friend_action := false
var jump_sources := {}
var menu_pages=preload("res://scripts/menu_pages.gd").new()
var boost_sources := {}
var ability_label: Label
var last_event := 0
var notice := ""
var notice_time := 0.0
var menu_clock := 0.0
var particles: Array[Dictionary] = []
var save_failed := false
var save_observation := {}
var save_revision := 0
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
var web_touch_cancel_callback: JavaScriptObject
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
	story_ui.host = self
	pixel_ui.host = self
	touch_controls.host = self
	touch_mode = OS.has_feature("mobile")
	if OS.has_feature("web"): touch_mode = bool(JavaScriptBridge.eval("matchMedia('(pointer:coarse)').matches"))
	gamepad.host = self
	Input.joy_connection_changed.connect(on_gamepad_connection)
	load_settings()
	native_diagnostics.host=self
	web_accessibility.host=self
	web_accessibility.setup()
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
		web_touch_cancel_callback=JavaScriptBridge.create_callback(cancel_web_touch)
		JavaScriptBridge.get_interface("window").aionCancelTouches=web_touch_cancel_callback
		# Some web engine paths map DOM touchcancel to an ordinary release.
		# Clear ownership in capture phase before such a release can launch Emre.
		# Do not cancel on pointercancel: Chrome emits it for valid legacy-touch holds.
		JavaScriptBridge.eval("if(!window.aionTouchCancelInstalled){window.aionTouchCancelInstalled=true;window.addEventListener('touchcancel',()=>window.aionCancelTouches?.(),{capture:true,passive:true})}")
		JavaScriptBridge.eval("document.getElementById('canvas').addEventListener('contextmenu',e=>{if(e.currentTarget.dataset.page==='')e.preventDefault()})")
	for i in 2:
		followers.append(make_companion_sprite())
	sheep_collectible = make_companion_sprite()
	friend_sprite = make_companion_sprite()
	gun_echo = make_companion_sprite()
	gun_echo.visible = false
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
	print("AION_READY "+GAME_VERSION)
	if "--aion-smoke-test" in OS.get_cmdline_user_args():get_tree().quit.call_deferred()

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
		var browser_locale = JavaScriptBridge.eval("(typeof Intl !== 'undefined' && Intl.DateTimeFormat().resolvedOptions().locale) || (navigator.languages && navigator.languages[0]) || navigator.language || 'en'")
		if browser_locale is String: locale = browser_locale
	return Words.language_for_locale(locale)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	language = default_language()
	var loaded := cfg.load("user://save.cfg")
	if preload("res://scripts/browser_save.gd").restore(cfg):loaded=OK
	save_revision=maxi(0,int(cfg.get_value("meta","revision",0)))
	interface_options.load_from(cfg)
	gamepad.load_from(cfg)
	if loaded != OK:
		return
	language_override = int(cfg.get_value("prefs","language_mode_revision",0))>=2 and bool(cfg.get_value("prefs", "language_override",false))
	if language_override:
		var saved_language := str(cfg.get_value("prefs", "language", ""))
		if saved_language in Words.LANGUAGES: language = saved_language
		else: language_override = false
	touch_tutorial_done = bool(cfg.get_value("prefs","touch_tutorial_done",false))
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
	cfg.set_value("prefs","language_mode_revision",2)
	cfg.set_value("prefs", "character", character)
	cfg.set_value("prefs","touch_tutorial_done",touch_tutorial_done)
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
	interface_options.save_to(cfg)
	gamepad.save_to(cfg)
	save_revision=maxi(save_revision+1,int(Time.get_unix_time_from_system()*1000.0))
	cfg.set_value("meta","schema",1);cfg.set_value("meta","revision",save_revision)
	var mirrored:=preload("res://scripts/browser_save.gd").persist(cfg,save_revision)
	var result := cfg.save("user://save.tmp")
	if result == OK:
		result = DirAccess.rename_absolute("user://save.tmp", "user://save.cfg")
	save_failed = result != OK and not mirrored
	var written:=ConfigFile.new()
	var read_result:=written.load("user://save.cfg")
	save_observation={"write_error":result,"read_error":read_result,"theme":str(written.get_value("prefs","theme_mode","missing")),"scale":float(written.get_value("prefs","text_scale",0)),"modified":FileAccess.get_modified_time("user://save.cfg")}
	if result==OK and OS.has_feature("web"):
		# The final atomic rename must be part of the persistent snapshot.
		JavaScriptBridge.force_fs_sync()

func box(bg: String, border: String = "886575", radius: int = 16) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = interface_options.authored(bg,"surface")
	style.border_color = interface_options.authored(border,"border")
	style.set_border_width_all(2)
	style.set_corner_radius_all(0)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func build_theme() -> void:
	ui_theme = interface_options.theme(FONT)
	ui_theme.default_font_size=ui_size(22)
	RenderingServer.set_default_clear_color(interface_options.color("background"))

func ui_size(value: int) -> int:
	return roundi(value*interface_options.text_scale)

func decorative_motion() -> bool:
	return motion and not interface_options.reduced_motion

func apply_interface_option(key: String,value: Variant) -> void:
	interface_options.set(key,value)
	interface_options.resolve_theme()
	save_settings()
	build_theme()
	ui.theme=ui_theme
	rebuild()

func add_choice(column: VBoxContainer,key: String,values: Array,current: Variant,callback: Callable) -> void:
	column.add_child(wrap_label(text(key),17))
	for entry in values:
		var option := button(("[x] " if entry[0]==current else "[ ] ")+text(str(entry[1])),callback.bind(entry[0]),entry[0]==current)
		option.name="Option_"+key+"_"+str(entry[0])
		column.add_child(option)


func label(value: String, size: int = 17, color: String = "eef3ff") -> Label:
	var item := Label.new()
	item.text = value
	item.add_theme_font_size_override("font_size", ui_size(maxi(size,24) if touch_mode else size))
	item.accessibility_name=value
	item.add_theme_color_override("font_color", interface_options.authored(color))
	return item

func button(value: String, callback: Callable, primary: bool = false) -> Button:
	var item := Button.new()
	item.text = value
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.accessibility_name=value
	item.custom_minimum_size.y = maxf((76 if portrait else 64) if touch_mode else 48,ui_size(34)+18)
	item.add_theme_font_size_override("font_size",ui_size(30 if touch_mode else 22))
	item.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	item.pressed.connect(callback)
	if primary:
		item.add_theme_stylebox_override("normal", box("ad536e", "f2b1a6", 12))
		item.add_theme_color_override("font_color", interface_options.color("on_primary"))
		item.add_theme_color_override("font_focus_color", interface_options.color("on_primary"))
		item.add_theme_stylebox_override("hover", box("cb7587", "cb7587", 12))
		item.add_theme_color_override("font_hover_color", interface_options.color("on_primary"))
		item.add_theme_stylebox_override("pressed", box("91415e", "91415e", 12))
		item.add_theme_color_override("font_pressed_color", interface_options.color("on_primary"))
	return item

func position_control(item: Control, pos: Vector2, dimensions: Vector2) -> void:
	item.position = pos
	item.size = dimensions

func rebuild() -> void:
	if not is_instance_valid(ui):
		return
	var previous_focus:=get_viewport().gui_get_focus_owner()
	var previous_name: String=str(previous_focus.name) if is_instance_valid(previous_focus) else ""
	menu_pages.focus_name=previous_name
	var raw := get_viewport_rect().size
	if layout_size != Vector2.ZERO and not layout_size.is_equal_approx(raw): clear_held_controls()
	layout_size = raw
	device_portrait = raw.y > raw.x
	portrait = device_portrait
	var safe_origin := Vector2.ZERO
	var usable := raw
	if OS.has_feature("web"):
		var safe_json = JavaScriptBridge.eval("(()=>{const d=document.createElement('div');d.style.cssText='position:fixed;visibility:hidden;padding:env(safe-area-inset-top) env(safe-area-inset-right) env(safe-area-inset-bottom) env(safe-area-inset-left)';document.body.append(d);const s=getComputedStyle(d);const a=[parseFloat(s.paddingLeft),parseFloat(s.paddingTop),parseFloat(s.paddingRight),parseFloat(s.paddingBottom),innerWidth,innerHeight];d.remove();return JSON.stringify(a)})()")
		var insets = JSON.parse_string(str(safe_json))
		if insets is Array and insets.size()==6:
			var unit := Vector2(raw.x/maxf(1,float(insets[4])),raw.y/maxf(1,float(insets[5])))
			safe_origin=Vector2(float(insets[0]),float(insets[1]))*unit
			usable=raw-safe_origin-Vector2(float(insets[2]),float(insets[3]))*unit
	elif OS.has_feature("mobile"):
		var safe: Rect2=interface_options.native_safe_layout(raw)
		safe_origin=safe.position;usable=safe.size
	var aspect := usable.x / maxf(1,usable.y)
	view_h = maxf(920.0,540.0/aspect) if portrait else (540.0 if touch_mode else 648.0)
	view_w = 540.0 if portrait else maxf(960.0,view_h*aspect)
	var scale_value := minf(usable.x/view_w,usable.y/view_h)
	screen_transform = Transform2D(0,Vector2.ONE*scale_value,0,safe_origin+(usable-Vector2(view_w,view_h)*scale_value)*0.5)
	canvas_layer.transform = screen_transform
	ui.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	ui.size = Vector2(view_w,view_h)
	scene_zoom = 0.72 if portrait else 1.0
	scene_w = (view_w+World.PLAYER_X*scene_zoom-92.0)/scene_zoom if portrait else view_w
	scene_h = view_h/scene_zoom
	ground = (pixel_ui.stage_y() if page=="main" else view_h-(172.0 if touch_mode else 112.0))/scene_zoom
	apply_scene_transform()
	web_stamp = ""
	ui_layout_ready = false
	layout_generation += 1
	refresh_interface_metadata.call_deferred(layout_generation)
	world.field_width = scene_w
	settings_inputs.clear()
	for child in ui.get_children():
		# Keep the pressed control in the tree until Godot finishes GUI dispatch.
		child.hide()
		child.name = "RetiredUI_" + str(child.get_instance_id())
		child.queue_free()
	pixel_ui.hud()
	build_action_buttons()
	pixel_ui.fragaria()
	menu_layer = Control.new()
	menu_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(menu_layer)
	if page != "":
		build_page()
	build_language_picker()
	story_ui.build()
	if previous_name!="":
		var replacement=ui.find_child(previous_name,true,false)
		if replacement is Control and replacement.is_visible_in_tree():focus_later.call_deferred(replacement)
	if touch_mode and page=="" and not touch_tutorial_done: pixel_ui.tutorial()
	update_hud()
	queue_redraw()

func refresh_interface_metadata(generation: int) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if generation != layout_generation: return
	ui_layout_ready = true
	native_diagnostics.layout()
	web_stamp = ""
	publish_web_status()

func card(width: float = 520.0) -> VBoxContainer:
	return pixel_ui.card(width)

func wrap_label(value: String, size: int = 15, color: String = "a6b8d1") -> Label:
	var item := label(value, size, color)
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return item

func show_page(value: String) -> void:
	if value!=page:menu_pages.reset(value)
	if value == "characters" and world.state != "ready": return
	language_picker_open = false
	page = value
	rebuild()

func build_page() -> void:
	menu_pages.host=self
	if page=="main":menu_pages.pages=[];menu_pages.current=0
	if page not in ["main"]:
		var shade := ColorRect.new()
		shade.color = Color("17121cc4")
		position_control(shade, Vector2(0, 64), Vector2(view_w, view_h - 64))
		menu_layer.add_child(shade)
	if page == "characters":
		build_characters()
		return
	var column := card(440.0 if page == "main" else 560.0)
	var first: Button
	if page == "main":
		first = pixel_ui.main(column)
	elif page == "paused":
		column.add_child(wrap_label(text("paused"), 28))
		column.add_child(wrap_label(text("pause_note")))
		first = button(text("resume"), resume_run, true)
		column.add_child(first)
		column.add_child(button(text("menu"), main_menu))
		if not OS.has_feature("web") and not OS.has_feature("mobile"):
			column.add_child(button(text("quit"), quit_game))
		column.add_child(button(text("settings"), func(): open_subpage("settings")))
	elif page == "finished":
		column.add_child(wrap_label(text("frozen" if world.state == "ice" else ("bonked" if world.state == "bonk" else "burnt")), 26))
		var result := HBoxContainer.new()
		column.add_child(result)
		result.add_child(label("%05d" % world.score, 30, "f8db96"))
		result.add_child(label(text("score"), 13, "e6c8b0"))
		column.add_child(wrap_label(text("best")+"  %05d" % best+(" · "+text("new_best") if not world.practice and world.score>best_at_start else ""),20,"f3c788"))
		column.add_child(wrap_label(text("runstats") % [world.passed, world.gems],18))
		column.add_child(wrap_label(text("level_record") % [world.adventure.level,best_level],13))
		first = button(text("again"), retry_run, true)
		first.set_meta("menu_pin",true)
		column.add_child(first)
		var actions := HBoxContainer.new()
		actions.set_meta("menu_pin",true)
		column.add_child(actions)
		for entry in [button(text("menu"),main_menu),button(text("settings"),func():open_subpage("settings"))]:
			entry.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			actions.add_child(entry)
	elif page == "bosses":
		column.add_child(wrap_label(text("boss_training"),25,"f8db96"))
		column.add_child(wrap_label(text("boss_training_help"),14))
		for kind in 3:
			var entry := button(text(["boss_name","boss_ray","boss_root"][kind]),start_boss_practice.bind(kind))
			entry.name = "PracticeBoss_"+str(kind)
			column.add_child(entry)
			if kind==0: first = entry
		column.add_child(button(text("menu"),main_menu))
	elif page == "settings":
		column.add_child(wrap_label(text("settings"), 28))
		column.add_child(wrap_label(text("language"), 13, "d4b6b2"))
		var choose_language:=button(Words.LANGUAGE_NAMES[language]+"  ▾",toggle_language_picker)
		choose_language.name="SettingsLanguage"
		column.add_child(choose_language)
		first=choose_language
		column.add_child(wrap_label(text("language_hint"), 12))
		column.add_child(wrap_label(text("appearance"), 14, "d4b6b2"))
		add_choice(column,"theme",[["dark","theme_dark"],["light","theme_light"],["system","theme_system"]],interface_options.theme_mode,func(v):apply_interface_option("theme_mode",v))
		add_choice(column,"ui_font",[["system","font_system"],["pixel","font_pixel"]],interface_options.font_mode,func(v):apply_interface_option("font_mode",v))
		add_choice(column,"text_size",[[1.0,"size_100"],[1.25,"size_125"],[1.5,"size_150"],[2.0,"size_200"]],interface_options.text_scale,func(v):apply_interface_option("text_scale",v))
		add_toggle(column,"reduced_motion",interface_options.reduced_motion,func(v):apply_interface_option("reduced_motion",v))
		add_choice(column,"touch_layout",[["split","layout_split"],["right","layout_right"]],interface_options.touch_layout,func(v):apply_interface_option("touch_layout",v))
		gamepad.build_settings(column)
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
		slider.accessibility_name=text("volume")
		slider.custom_minimum_size.y = 48
		slider.value_changed.connect(func(value): volume = value / 100.0; volume_label.text = text("volume") + "  %d%%" % value; save_settings())
		column.add_child(slider)
		if not OS.has_feature("web") and not OS.has_feature("mobile"):
			add_toggle(column, "fullscreen", fullscreen, func(value): fullscreen = value; apply_fullscreen(); save_settings())
		column.add_child(wrap_label(text("gameplay"),17,"eed3b4"))
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
		column.add_child(wrap_label(text("how"), 17, "eed3b4"))
		column.add_child(wrap_label(text("help"), 13))
		column.add_child(wrap_label(text("boss_help"),13))
		column.add_child(wrap_label(text("motion_help"),13))
		column.add_child(wrap_label(text("gamepad_help"),13))
		column.add_child(wrap_label(text("discoveries") % world.adventure.discoveries.size(), 16))
		for power in world.adventure.POWER_NAMES:
			column.add_child(wrap_label(("✓ " if world.adventure.discoveries.has(power) else "○ ") + text("power_" + power) + " · " + text("desc_" + power), 12))
		column.add_child(wrap_label(text("version"), 11, "c6a8a5"))
	if page!="main":menu_pages.prepare(column,Vector2(float(column.get_meta("page_width")),float(column.get_meta("page_height"))))
	if is_instance_valid(first):
		focus_later.call_deferred(first)

func build_language_picker() -> void:
	language_button = button(language.to_upper(), toggle_language_picker)
	language_button.name = "LanguageMenu"
	language_button.tooltip_text = text("language")
	# Two-letter language control has its own48px geometry, not the generic
	# enlarged menu-action minimum (86px at200%), which covered a roster card.
	language_button.custom_minimum_size=Vector2(84,48)
	var chevron := Control.new()
	chevron.set_script(preload("res://scripts/language_chevron.gd"))
	chevron.mouse_filter = Control.MOUSE_FILTER_IGNORE
	language_button.add_child(chevron)
	chevron.position = Vector2(68, 24)
	language_button.visible = page != ""
	language_button.add_theme_font_size_override("font_size",24 if touch_mode else 18)
	ui.add_child(language_button)
	position_control(language_button, Vector2(view_w-100,8), Vector2(84,48))
	language_picker = PanelContainer.new()
	language_picker.name = "LanguagePicker"
	language_picker.z_index = 100
	language_picker.add_theme_stylebox_override("panel", box("18283d", "79d7c7", 12))
	ui.add_child(language_picker)
	var picker_width: float=view_w-56
	language_picker.position=Vector2(28,76)
	var options:=VBoxContainer.new()
	language_picker.add_child(options)
	var auto_option:=button(text("language_system"),func():set_language("system"),not language_override)
	auto_option.name="Language_system"
	auto_option.add_theme_font_size_override("font_size",ui_size(24))
	var grid:=GridContainer.new()
	grid.columns=2 if portrait else 4
	grid.add_theme_constant_override("h_separation",8)
	grid.add_theme_constant_override("v_separation",8)
	options.add_child(grid)
	auto_option.custom_minimum_size.x=(picker_width-28-8*(grid.columns-1))/grid.columns
	grid.add_child(auto_option)
	for lang in Words.LANGUAGES:
		var option:=button(Words.LANGUAGE_NAMES[lang],func():set_language(lang),lang==language)
		option.name="Language_"+lang
		option.accessibility_name=lang.to_upper()+"  "+Words.LANGUAGE_NAMES[lang]
		option.custom_minimum_size.x=(picker_width-28-8*(grid.columns-1))/grid.columns
		option.add_theme_font_size_override("font_size",ui_size(24))
		grid.add_child(option)
	language_picker.visible = language_picker_open and page != ""

func toggle_language_picker() -> void:
	language_picker_open = not language_picker_open
	language_picker.visible = language_picker_open
	web_stamp = ""
	if language_picker_open: focus_language_option.call_deferred(layout_generation)
	# Visibility changes do not rebuild the page. Publish the real popup
	# layout after container sorting for native touch diagnostics as well.
	refresh_interface_metadata.call_deferred(layout_generation)

func focus_language_option(generation: int) -> void:
	# Hidden containers have no final row positions on their first visible frame.
	await get_tree().process_frame
	await get_tree().process_frame
	if generation != layout_generation or not language_picker_open or not is_instance_valid(language_picker): return
	var option: Control = language_picker.find_child("Language_"+language,true,false)
	option.grab_focus()
	refresh_interface_metadata.call_deferred(generation)

func character_portrait(id: String) -> TextureRect:
	var picture := TextureRect.new()
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.custom_minimum_size = Vector2(58, 66)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var atlas := AtlasTexture.new()
	picture.texture = frames.pose("runner-"+id,1,0).texture
	if id != "aion":
		var mat := ShaderMaterial.new()
		mat.shader = preload("res://scripts/companion_alpha.gdshader")
		picture.material = mat
	return picture

func build_start_roster() -> void:
	pixel_ui.roster(menu_layer,Vector2(28,view_h-154),view_w-56)

func focus_later(item: Control) -> void:
	if is_instance_valid(item) and item.is_inside_tree() and item.is_visible_in_tree() and not item.is_queued_for_deletion():
		item.grab_focus()

func build_characters() -> void:
	pixel_ui.characters()

func add_toggle(column: VBoxContainer, key: String, value: bool, callback: Callable) -> void:
	var row := HBoxContainer.new()
	column.add_child(row)
	var toggle := CheckButton.new()
	toggle.name = "Setting_"+key
	toggle.text = text(key)
	toggle.accessibility_name=text(key)
	toggle.button_pressed = value
	toggle.custom_minimum_size.y = 64 if touch_mode else 54
	toggle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toggle.add_theme_font_size_override("font_size",ui_size(24 if touch_mode else 18))
	row.add_child(toggle)
	var status := label(text("setting_on" if value else "setting_off"),13,"a8efd4" if value else "a6b8d1")
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(status)
	toggle.toggled.connect(func(enabled):
		status.text = text("setting_on" if enabled else "setting_off")
		status.add_theme_color_override("font_color",interface_options.color("success" if enabled else "muted"))
		callback.call(enabled))

func add_range_setting(column: VBoxContainer,key: String,value: float,callback: Callable,id: String) -> void:
	var group:=VBoxContainer.new()
	column.add_child(group)
	group.add_child(wrap_label(text(key),14))
	var row := HBoxContainer.new()
	group.add_child(row)
	var slider := HSlider.new()
	slider.accessibility_name=text(key)
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size.y = 64 if touch_mode else 46
	row.add_child(slider)
	var number := SpinBox.new()
	number.name = id
	number.accessibility_name=text(key)
	number.min_value = 0
	number.max_value = 100
	number.step = 1
	number.value = value
	number.suffix = "%"
	number.custom_minimum_size = Vector2(118,64 if touch_mode else 46)
	number.add_theme_font_size_override("font_size",ui_size(24 if touch_mode else 20))
	row.add_child(number)
	settings_inputs[id] = number
	slider.value_changed.connect(func(v): number.value = v)
	number.value_changed.connect(func(v): slider.set_value_no_signal(v); callback.call(v))

func set_language(value: String) -> void:
	if value!="system" and value not in Words.LANGUAGES:return
	language_override = value!="system"
	language_picker_open = false
	language = default_language() if value=="system" else value
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
		JavaScriptBridge.eval("try { screen.orientation?.unlock?.(); } catch (_) {}")
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
	touch_controls.clear()
	world.release_controls()

func tutorial_waiting() -> bool:
	return touch_mode and not touch_tutorial_done and is_instance_valid(tutorial_panel) and tutorial_panel.is_visible_in_tree()

func begin_playing() -> void:
	if tutorial_waiting():
		touch_tutorial_done=true
		tutorial_panel.hide()
		save_settings()

func press_jump(source: String) -> void:
	begin_playing()
	if page != "" or world.state != "running" or world.adventure.hugging() or world.frontier.storytelling() or jump_sources.has(source): return
	world.character = character
	jump_sources[source] = true
	world.jump_held = true
	world.jump()

func release_jump(source: String,launch: bool=true) -> void:
	var owned: bool=jump_sources.has(source)
	jump_sources.erase(source)
	world.jump_held = not jump_sources.is_empty()
	if owned and jump_sources.is_empty():
		if launch:world.release_charged_jump()
		else:world.cancel_charge()

func cancel_web_touch(_arguments: Array) -> void:
	clear_held_controls()

func press_boost(source: String) -> void:
	begin_playing()
	if page != "" or world.state != "running" or world.adventure.hugging() or world.frontier.storytelling(): return
	world.character = character
	boost_sources[source] = true
	world.boost_held = true

func release_boost(source: String) -> void:
	boost_sources.erase(source)
	world.boost_held = not boost_sources.is_empty()

func press_attack(source: String) -> void:
	# Preserve saved X/J/R alternate bindings; all firearm inputs share cadence.
	press_shoot("alternate:"+source)

func press_shoot(source: String) -> void:
	begin_playing()
	if page != "" or world.state != "running" or world.adventure.hugging() or world.frontier.storytelling(): return
	if shoot_sources.has(source): return
	var first := shoot_sources.is_empty()
	shoot_sources[source] = true
	world.frontier.shoot_held = true
	world.frontier.fire(world)

func release_shoot(source: String) -> void:
	shoot_sources.erase(source)
	world.frontier.shoot_held = not shoot_sources.is_empty()

func release_attack(source: String) -> void:
	release_shoot("alternate:"+source)

func press_duck(source: String) -> void:
	begin_playing()
	if page != "" or world.state != "running" or world.adventure.hugging() or world.frontier.storytelling(): return
	duck_sources[source] = true
	world.cancel_charge()
	world.adventure.press_roll(world)

func release_duck(source: String) -> void:
	var owned: bool=duck_sources.has(source)
	duck_sources.erase(source)
	world.adventure.duck_held = not duck_sources.is_empty()
	if owned and duck_sources.is_empty() and world.adventure.roll_time<=0 and world.adventure.roll_elapsed>0:
		world.adventure.roll_time=0.15

func build_action_buttons() -> void:
	action_buttons.clear()
	var size_value := 96.0 if touch_mode else 80.0
	var start := Vector2(view_w-294,view_h-108)
	var positions := {"duck":Vector2.ZERO,"attack":Vector2(-6,-110),"jump":Vector2(184,0),"shoot":Vector2(92,-60),"boost":Vector2(-92,0)}
	for id in ["jump","duck","shoot","boost"]:
		var control := preload("res://scripts/touch_button.gd").new()
		control.name = "Touch_"+id
		control.action = id
		control.caption = text("control_"+id)
		if touch_mode and interface_options.touch_layout=="split":
			var split: Dictionary={"jump":Vector2(22,view_h-108),"boost":Vector2(124,view_h-108),"duck":Vector2(view_w-210,view_h-108),"attack":Vector2(view_w-210,view_h-218),"shoot":Vector2(view_w-112,view_h-168)}
			positions[id]=split[id]-start
		control.font = interface_options.body_font
		control.accessibility_name=control.caption
		control.palette=interface_options.colors
		ui.add_child(control)
		# Snap the entire hit target and texture to actual device pixels.
		var unit: float=screen_transform.get_scale().x
		var pixel_step: float=maxf(1,roundf(2.0*unit))
		var pixels: float=maxf(24,roundf(size_value*unit/pixel_step/2.0)*2.0)*pixel_step
		var physical: Vector2=(screen_transform*(start+positions[id])).round()
		position_control(control,screen_transform.affine_inverse()*physical,Vector2.ONE*pixels/unit)
		action_buttons[id]=control

func to_game_point(point: Vector2) -> Vector2:
	return global_transform.affine_inverse() * point

func apply_scene_transform() -> void:
	var camera := Transform2D.IDENTITY
	var a = world.adventure
	if a.giant() and effects_enabled and decorative_motion():
		var clock := animation_clock()
		var zoom := 1.0 + prism_intensity * (0.020 + sin(clock * 0.65) * 0.008)
		camera = Transform2D(sin(clock * 0.8) * 0.008 * prism_intensity, Vector2.ONE * zoom, 0, Vector2.ZERO)
		var center := Vector2(scene_w * 0.5, ground * 0.6)
		camera.origin = center - (camera * center) + Vector2(sin(clock * 0.7) * 4, cos(clock * 0.6)*2)*prism_intensity
		if is_instance_valid(world_tint): world_tint.color = Color.WHITE.lerp(Color.from_hsv(fposmod(clock * 0.045, 1.0), 0.30, 1.0), 0.60*prism_intensity)
	elif is_instance_valid(world_tint): world_tint.color = Color.WHITE
	var base := Transform2D(0,Vector2.ONE*scene_zoom,0,Vector2(92.0-World.PLAYER_X*scene_zoom,0) if portrait else Vector2.ZERO)
	transform = screen_transform * base * camera

func on_wolf(point: Vector2) -> bool:
	return character == "wolf" and Rect2(World.PLAYER_X - 65, ground + world.y - 115, 130, 130).has_point(point)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed: active_input="touch"
	elif event is InputEventKey and event.pressed and not event.echo: active_input="keyboard"
	elif event is InputEventMouseButton and event.pressed and event.device!=-1: active_input="keyboard"
	elif event is InputEventJoypadButton and event.pressed: active_input="gamepad"
	if gamepad.capture_event(event):
		get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch and is_instance_valid(tutorial_panel) and tutorial_panel.is_visible_in_tree() and tutorial_panel.get_global_rect().has_point(screen_transform.affine_inverse()*event.position): return
	if page=="" and world.frontier.storytelling():
		if event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE,KEY_ENTER]:
			story_ui.advance();get_viewport().set_input_as_handled();return
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			if gamepad.handle(event):get_viewport().set_input_as_handled()
			return
		if event is InputEventScreenTouch or event is InputEventScreenDrag or event is InputEventMouseButton:return
	if touch_controls.handle(event):
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.device == -1 and page == "":
		# Godot's ordinary GUI buttons still need the touch-emulated mouse.
		# Only consume it over gameplay, where finger actions were already routed.
		if is_instance_valid(tutorial_panel) and tutorial_panel.is_visible_in_tree() and tutorial_panel.get_global_rect().has_point(screen_transform.affine_inverse()*event.position): return
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.device != -1 and event.button_index==MOUSE_BUTTON_LEFT and page=="":
		if event.pressed:
			var p: Vector2 = screen_transform.affine_inverse()*event.position
			for id in action_buttons:
				if action_buttons[id].hit(p):
					if not action_buttons[id].disabled: touch_controls.action(id,"action-mouse",true)
					get_viewport().set_input_as_handled()
					return
		else: touch_controls.action("","action-mouse",false)
	# Releases are observed before GUI dispatch so dragging away from a control
	# or opening a menu can never leave glide/boost latched on.
	if event is InputEventKey and not event.pressed:
		if event.keycode == KEY_SPACE: release_jump("key")
		if event.keycode == KEY_SHIFT: release_boost("shift")
		if event.keycode in [KEY_J,KEY_R]: release_attack("key")
		if event.keycode == KEY_F: release_shoot("key")
		if event.keycode in [KEY_DOWN, KEY_S, KEY_CTRL]: release_duck("key:" + str(event.keycode))
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed: release_shoot("mouse")
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		release_jump("mouse")
		release_boost("mouse")
		release_shoot("mouse")
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
		elif event.keycode in [KEY_J,KEY_R] and page == "":
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
	if page != "" or world.frontier.storytelling(): return
	if event is InputEventMouseButton and event.device != -1 and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		press_shoot("mouse")
		get_viewport().set_input_as_handled()
	if event is InputEventMouseButton and event.device != -1 and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		press_shoot("mouse")
		get_viewport().set_input_as_handled()

func _physics_process(dt: float) -> void:
	theme_check+=dt
	if theme_check>1.0:
		theme_check=0.0
		if interface_options.theme_mode=="system" and interface_options.resolve_theme():
			build_theme();ui.theme=ui_theme;rebuild()
	gamepad.step(dt)
	touch_controls.step(dt)
	world.character = character
	if page == "" or (world.state in ["fire", "ice", "bonk", "fall"] and page == "finished"):
		if not tutorial_waiting(): world.step(dt)
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
	if page == "main" and decorative_motion():
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
	update_weapon_visual()
	update_hud()
	native_diagnostics.state()
	evolution_view.z_index = 1 if world.adventure.hugging() else 0
	evolution_view.queue_redraw()
	frontier_view.queue_redraw()
	adventure_view.queue_redraw()
	queue_redraw()

func handle_event(value: String) -> void:
	if value in ["story_start","story_beat","story_end"]:clear_held_controls()
	if value=="fragaria_found":
		notice=text("fragaria_found")
		notice_time=3.8
		tone(1046,0.12)
	if value in ["attack","jump","boss_shot"]: gamepad.rumble()
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
		notice = "" if touch_mode and value=="boss_fight" else text(value)
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
	if value == "boss_returning":
		notice = text(value)
		notice_time = 1.25
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
			notice = text("fruit_"+world.orchard.last_kind)+"  +25"
			burst(Vector2(World.PLAYER_X, ground + world.y - 35), Color("ffcf8c"), 8)
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
	hud.visible = page in ["","paused"]
	score_label.text = "%05d" % world.score
	best_label.text = "%05d" % best
	crystal_label.text = "%02d" % world.gems
	biome_label.text = text(World.BIOME_NAMES[world.biome()])
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
	footer_label.text=text("firearm_touch") if touch_mode else text("firearm_hint")
	if active_input=="gamepad":footer_label.text=gamepad.prompts(boss.active())
	var exit_fade: float = 1.0-smoothstep(0.0,world.frontier.RETURN_DURATION,world.frontier.stage_time) if world.frontier.phase=="return" else 1.0
	boss_label.modulate.a = exit_fade
	boss_bar.modulate.a = exit_fade
	boss_label.text = text(["boss_name","boss_ray","boss_root"][boss.boss_kind]) + "  ·  %d/%d  ·  " % [boss.hp,boss.max_hp] + text("boss_hearts") % boss.player_hp
	if boss.warning != "": boss_label.text += " · " + text("boss_pattern_"+boss.pattern) + " · " + text("boss_dodge_"+boss.warning)
	var ids: Array = ["jump","duck","shoot"]
	if character=="wolf": ids.append("boost")
	for id in action_buttons:
		var index: int = ids.find(id)
		action_buttons[id].visible = page == "" and world.state == "running" and index >= 0
		if id=="shoot":
			action_buttons[id].elemental=false
			action_buttons[id].caption=text("control_shoot")
			action_buttons[id].accessibility_name=text("control_shoot")
	action_buttons.jump.pressed=world.jump_held
	action_buttons.duck.pressed=world.adventure.ducking(world)
	action_buttons.shoot.pressed=world.frontier.shoot_held
	action_buttons.boost.pressed=world.boosting()
	level_label.visible = page == "" or page == "paused"
	level_progress.visible = false
	level_label.text = text("level_short") % world.adventure.level
	level_progress.value = world.adventure.level_progress(world)
	xp_label.text = "XP %d · %s %d" % [world.adventure.run_xp,text("mastery"),world.adventure.mastery_rank()]
	xp_label.visible = level_label.visible and interface_options.text_scale<=1.0
	xp_progress.visible = false
	xp_progress.value = world.adventure.run_xp % 100
	for id in action_buttons:
		var control=action_buttons[id]
		control.disabled=world.adventure.hugging() or (id=="shoot" and world.adventure.ducking(world))
		control.cooldown=boss.shot_cooldown/boss.SHOT_CADENCE if id=="shoot" else 0.0
		control.queue_redraw()
	ammo_label.visible=false
	if is_instance_valid(fragaria_panel): fragaria_panel.visible = world.adventure.fragaria_time>0 and page in ["","paused"] and interface_options.text_scale<=1.0
	footer_label.visible = page==""
	ability_label.visible = page=="" and not boss.active()
	biome_label.visible = page in ["","paused"]
	power_label.visible = page=="" and not powers.is_empty()
	progress.value = fmod(world.distance, World.BIOME_DISTANCE)
	pause_button.visible = page == "" and world.state == "running"
	notice_label.text = text("saved_error") if save_failed else (notice if notice_time > 0.0 and page == "" else "")
	if is_instance_valid(ability_label):
		ability_label.text = text(("touch_ability_" if touch_mode else "ability_") + character)
		if active_input=="gamepad":
			ability_label.text=text("pad_ability_"+character)
			if character!="sheep":ability_label.text=ability_label.text % gamepad.binding_name("boost" if character=="wolf" else "jump")
		if portrait and character in World.CHARGE_HEROES and active_input=="gamepad":ability_label.text=gamepad.binding_name("jump")+" ↑"
		if world.frontier.active(): ability_label.text = text("boss_hearts") % world.frontier.player_hp
		elif character == "sheep": ability_label.text = text("flock") % world.sheep_count
		elif world.charging:
			ability_label.text="↑ %d%%" % roundi(world.charge_ratio()*100)
			ability_label.accessibility_name=text("charging") % roundi(world.charge_ratio()*100)
		elif world.riding_gust: ability_label.text = text("riding_gust") if world.wind_kind() == "up" else text("riding_"+world.wind_kind())
		elif world.gliding: ability_label.text = text("owl_flaps") % maxi(0,World.OWL_FLAPS-world.owl_flaps_used)
		elif world.boosting(): ability_label.text = text("boosting")
		if portrait and touch_mode:
			# The narrow lane above Jump shows live ability state. Full input
			# instructions stay in the tutorial/help and accessibility name.
			ability_label.accessibility_name=ability_label.text if not world.charging else text("charging") % roundi(world.charge_ratio()*100)
			if character=="sheep":ability_label.text=ability_label.text.replace("・","·").get_slice("·",0).strip_edges()
			elif world.charging:ability_label.text="↑ %d%%" % roundi(world.charge_ratio()*100)
			elif world.riding_gust:ability_label.text="↑" if world.wind_kind()=="up" else ("→" if world.wind_kind()=="forward" else "↑→")
			elif world.gliding:ability_label.text=text("owl_flaps") % maxi(0,World.OWL_FLAPS-world.owl_flaps_used)
			elif world.boosting():ability_label.text=text("boosting")
			elif character=="aion":ability_label.text="↑ ×%d" % maxi(0,2-world.jumps_used)
			else:ability_label.hide()
			ability_label.text=ability_label.text.replace("・","·").get_slice("·",0).strip_edges()
	if interface_options.text_scale>1.0:
		biome_label.hide();power_label.hide();goal_label.hide();ability_label.hide();footer_label.hide()
	story_ui.update()
	if boss.storytelling() and page=="":
		hud.hide();boss_label.hide();boss_bar.hide();notice_label.hide();ability_label.hide();footer_label.hide()
		for control in action_buttons.values():control.hide()
	publish_web_status()

func publish_web_status() -> void:
	if not OS.has_feature("web"): return
	var stamp := "%s:%s:%d:%s:%s:%s:%d:%s:%s:%d" % [world.state, page, world.score, character, language, world.y < 0.0, world.jumps_used, world.gliding, world.boosting(), world.sheep_count]
	stamp += ":" + str(world.adventure.hug_time) + ":" + str(world.adventure.attack_variant) + ":" + str(world.adventure.mushroom_chance) + ":" + str(prism_intensity)
	stamp += ":" + world.frontier.phase + ":" + str(world.frontier.hp) + ":" + str(world.frontier.shot_flash)
	stamp += ":" + str(language_picker_open)+":"+interface_options.theme_mode+":"+str(interface_options.dark)+":"+interface_options.font_mode+":"+str(interface_options.text_scale)+":"+str(interface_options.reduced_motion)+":"+active_input
	stamp += ":"+str(world.owl_flaps_used)+":"+str(world.owl_flap_time)
	stamp += ":"+interface_options.touch_layout
	if world.frontier.storytelling():stamp+=":"+str(world.frontier.story_index)+":"+str(world.frontier.story_time)
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
	web_accessibility.update()
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
	var head_probe: Vector2 = friend_sprite.get_meta("head_probe_world",Vector2(-999,-999))
	canvas.setAttribute("data-head-probe-x",str(head_probe.x))
	canvas.setAttribute("data-head-probe-y",str(head_probe.y))
	canvas.setAttribute("data-actor-scale",str(friend_sprite.scale.x))
	canvas.setAttribute("data-frame-count",str(frames.count(str(friend_sprite.get_meta("pose_key","runner-aion")),int(friend_sprite.get_meta("pose_row",0)))))
	var menu_panel = menu_layer.get_node_or_null("PagePanel") if is_instance_valid(menu_layer) else null
	var panel_rect: Rect2 = menu_panel.get_global_rect() if is_instance_valid(menu_panel) else Rect2()
	canvas.setAttribute("data-main-panel",JSON.stringify([panel_rect.position.x,panel_rect.position.y,panel_rect.size.x,panel_rect.size.y]) if page=="main" else "[]")
	canvas.setAttribute("data-pose-source",str(friend_sprite.get_meta("source_key","")))
	canvas.setAttribute("data-source-frame",str(friend_sprite.get_meta("source_frame",0)))
	canvas.setAttribute("data-source-row",str(friend_sprite.get_meta("source_row",0)))
	canvas.setAttribute("data-boss-active",str(world.frontier.active()))
	canvas.setAttribute("data-boss-phase",world.frontier.phase)
	canvas.setAttribute("data-boss-kind",str(world.frontier.boss_kind))
	canvas.setAttribute("data-story-index",str(world.frontier.story_index))
	canvas.setAttribute("data-red-weapon",str(world.frontier.red_weapon))
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
	canvas.setAttribute("data-ammo","infinite")
	canvas.setAttribute("data-reloads","0")
	canvas.setAttribute("data-shooting",str(world.frontier.shot_flash>0))
	canvas.setAttribute("data-gun-overlay",str(gun_echo.visible))
	canvas.setAttribute("data-ground-y",str(ground))
	canvas.setAttribute("data-foot-y",str(friend_sprite.get_meta("foot_world",Vector2(-1,-1)).y))
	canvas.setAttribute("data-reloading","0.0")
	canvas.setAttribute("data-level-bar-visible",str(level_progress.visible))
	canvas.setAttribute("data-boss-hits",str(world.frontier.hits))
	canvas.setAttribute("data-boss-wins",str(world.frontier.wins))
	canvas.setAttribute("data-boss-warning",world.frontier.warning)
	canvas.setAttribute("data-projectiles",JSON.stringify(world.frontier.projectiles))
	canvas.setAttribute("data-plants",JSON.stringify(world.frontier.plants))
	canvas.setAttribute("data-biome",str(world.biome()))
	canvas.setAttribute("data-fruits",JSON.stringify(world.pickups))
	canvas.setAttribute("data-fruit-count",str(world.gems))
	canvas.setAttribute("data-xp",str(world.adventure.run_xp))
	canvas.setAttribute("data-lightning-charges",str(world.adventure.lightning_charges))
	canvas.setAttribute("data-travel-distance",str(world.travel_distance()))
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
	canvas.setAttribute("data-swing-id",str(world.adventure.swing_id))
	canvas.setAttribute("data-jump-held",str(world.jump_held))
	canvas.setAttribute("data-owl-flaps-left",str(World.OWL_FLAPS-world.owl_flaps_used))
	canvas.setAttribute("data-owl-flap-time",str(world.owl_flap_time))
	canvas.setAttribute("data-charging",str(world.charging))
	canvas.setAttribute("data-charge-ratio",str(world.charge_ratio()))
	canvas.setAttribute("data-menu-page",str(menu_pages.current))
	canvas.setAttribute("data-menu-pages",str(menu_pages.pages.size()))
	canvas.setAttribute("data-attack-cooldown", str(world.adventure.attack_cooldown))
	canvas.setAttribute("data-giant", str(world.adventure.giant()))
	canvas.setAttribute("data-kills", str(world.adventure.kills))
	canvas.setAttribute("data-stomps", str(world.adventure.stomps))
	canvas.setAttribute("data-weather", world.adventure.weather)
	canvas.setAttribute("data-speed", str(world.speed()))
	canvas.setAttribute("data-orientation", "portrait" if portrait else "landscape")
	canvas.setAttribute("data-device-portrait", str(device_portrait))
	canvas.setAttribute("data-fragaria-time",str(world.adventure.fragaria_time))
	canvas.setAttribute("data-fragaria-found",str(world.adventure.fragaria_found))
	canvas.setAttribute("data-fragaria-celebrants",str(evolution_view.fragaria_tableau().size()))
	canvas.setAttribute("data-touch-swipes",str(touch_controls.swipe_count))
	canvas.setAttribute("data-touch-fingers",str(touch_controls.fingers.size()))
	canvas.setAttribute("data-touch-input",JSON.stringify(touch_controls.last_input))
	canvas.setAttribute("data-touch-trace",JSON.stringify(touch_controls.trace))
	canvas.setAttribute("data-view-width", str(view_w))
	canvas.setAttribute("data-view-height", str(view_h))
	canvas.setAttribute("data-raw-width", str(get_viewport_rect().size.x))
	canvas.setAttribute("data-raw-height", str(get_viewport_rect().size.y))
	canvas.setAttribute("data-screen-transform", JSON.stringify([screen_transform.x.x,screen_transform.x.y,screen_transform.y.x,screen_transform.y.y,screen_transform.origin.x,screen_transform.origin.y]))
	var controls := {}
	for id in action_buttons:
		var button: Control = action_buttons[id]
		controls[id] = {"x":button.position.x,"y":button.position.y,"w":button.size.x,"h":button.size.y,"visible":button.visible,"disabled":button.disabled}
	canvas.setAttribute("data-controls", JSON.stringify(controls))
	var buttons: Array = []
	for node in ui.find_children("*", "Button", true, false):
		if node.is_visible_in_tree():
			var rect: Rect2 = node.get_global_rect()
			buttons.append({"text":node.text,"name":str(node.name),"x":rect.position.x,"y":rect.position.y,"w":rect.size.x,"h":rect.size.y})
	canvas.setAttribute("data-ui", JSON.stringify(buttons))
	var boss_text := {}
	for id in ["status","notice"]:
		var item: Label=boss_label if id=="status" else notice_label
		var rect: Rect2=item.get_global_rect()
		boss_text[id]={"text":item.text,"x":rect.position.x,"y":rect.position.y,"w":rect.size.x,"h":rect.size.y,"required_h":item.get_minimum_size().y,"visible":item.is_visible_in_tree()}
	boss_text["bar_y"]=boss_bar.position.y
	canvas.setAttribute("data-boss-hud",JSON.stringify(boss_text))
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
	canvas.setAttribute("data-save-observation",JSON.stringify(save_observation))
	canvas.setAttribute("data-theme",interface_options.theme_mode)
	canvas.setAttribute("data-theme-dark",str(interface_options.dark))
	canvas.setAttribute("data-font-mode",interface_options.font_mode)
	canvas.setAttribute("data-touch-layout",interface_options.touch_layout)
	canvas.setAttribute("data-font-family",interface_options.body_font.get_font_name())
	canvas.setAttribute("data-text-scale",str(interface_options.text_scale))
	canvas.setAttribute("data-reduced-motion",str(interface_options.reduced_motion))
	canvas.setAttribute("data-active-input",active_input)
	canvas.setAttribute("data-pad-bindings",JSON.stringify(gamepad.bindings))
	canvas.setAttribute("data-pad-capturing",gamepad.capturing)
	canvas.setAttribute("data-pad-haptics",str(gamepad.haptics))
	canvas.setAttribute("data-footer",footer_label.text)
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
			elif a.ducking(world): friend_combat = COMBAT_ROWS[character] + FRIENDS.size()
	friend_sprite.visible = not (world.state=="ready" and pixel_ui.split_main())
	gun_echo.visible = false
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
		friend_frame = frames.cycle("runner-"+character,friend_row,world.travel_distance(),174.0)
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
	var preview := world.state=="ready" and page=="main"
	var anchor_x := ((view_w*.5-92)/scene_zoom+World.PLAYER_X) if portrait else view_w*.73
	place_companion(friend_sprite, character, friend_row, friend_frame, Vector2(anchor_x if preview else World.PLAYER_X, ground + world.y), 0.62 * (1.65 if preview else visual_size), friend_action)
	if friend_combat >= 0:
		var pose_spec := combat_pose(character,friend_combat >= FRIENDS.size() or a.ducking(world))
		var combat_count := frames.count(pose_spec.key,pose_spec.row)
		var combat_frame: int = (contact_frame(combat_count) if friend_combat < FRIENDS.size() else a.roll_frame(combat_count)) if motion else combat_count/2
		var combat_anchor := Vector2(World.PLAYER_X,ground+world.y)+combat_lunge()
		place_combat(friend_sprite, character, friend_combat, combat_frame, combat_anchor, visual_size, friend_combat >= FRIENDS.size() or a.ducking(world))
	if world.state in ["running","paused"] and not a.ducking(world) and not a.hugging() and world.y>=0 and not world.boosting() and not (world.state=="paused" and character=="wolf" and friend_row==6):
		var firing: bool = world.frontier.shot_flash>0
		var key := "gun-fire" if firing else "gun-run"
		var row: int = COMBAT_ROWS[character]
		var shooting: int = world.frontier.gun_frame(frames.count(key,row)) if firing else frames.cycle(key,row,world.travel_distance(),174.0)
		if not motion: shooting = 3 if firing else 0
		frames.place(friend_sprite,key,row,shooting,Vector2(World.PLAYER_X,ground+world.y))
	if character=="owl" and world.owl_flap_time>0 and world.state in ["running","paused"] and not a.ducking(world):
		frames.place(friend_sprite,"owl-flap",0,frames.progress("owl-flap",0,1-world.owl_flap_time/World.OWL_FLAP_DURATION) if motion else 2,Vector2(World.PLAYER_X,ground+world.y))
	if world.state in ["running","paused"] and not a.ducking(world) and not a.hugging() and (world.y<0 or world.boosting() or (world.state=="paused" and character=="wolf" and friend_row==6)):
		place_held_gun()
	if world.charging:
		frames.place(friend_sprite,"runner-"+character,6,frames.progress("runner-"+character,6,world.charge_ratio()),Vector2(World.PLAYER_X,ground))
		place_held_gun()
		if character=="rabbit":gun_echo.position.y+=14
	if world.state == "bonk":
		var row: int = COMBAT_ROWS[character]*2+(1 if world.death_cause=="enemy" else 0)
		frames.place(friend_sprite,"deaths",row,frames.progress("deaths",row,world.hit_time/1.25) if motion else frames.count("deaths",row)-1,Vector2(World.PLAYER_X,ground+world.y),visual_size)

	if world.frontier.storytelling():
		var f=world.frontier
		var phase: float=clampf(f.story_time/2.4,0,1)
		var reaction: int=maxi(1,frames.progress("boss-story-reactions",COMBAT_ROWS[character],phase)) if f.story_index==1 and motion else (4 if f.story_index==1 else 1)
		frames.place(friend_sprite,"boss-story-reactions",COMBAT_ROWS[character],reaction,Vector2(World.PLAYER_X,ground))
		gun_echo.hide()
		if f.story_index==2:
			var offer: float=smoothstep(0,1.2,f.story_time) if decorative_motion() else 1.0
			frames.place(gun_echo,"boss-story-reactions",6,0,Vector2(World.PLAYER_X+74-offer*35,ground-30))
			gun_echo.show()
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
				place_combat(followers[i], "sheep", 6, a.roll_pose(float(pose.get("roll_phase",0.0)),float(pose.get("roll_remaining",0.0)),bool(pose.get("roll_held",false)),frames.count("rolls",2)) if motion else 5, Vector2(World.PLAYER_X - World.FLOCK_GAP * (i + 1), ground + float(pose.y)), FOLLOWER_RATIO, true)
		if world.invulnerable > 0.0 and motion and int(world.time * 12) % 2 == 0: friend_sprite.modulate.a = 0.45

func place_held_gun() -> void:
	# Keep the established jump/glide/four-legged sprint art and add only its
	# own isolated pistol/paw pixels. Never resize or sway the hero to aim.
	var f=world.frontier
	var key: String="gun-fire" if f.shot_flash>0 else "gun-run"
	var row: int=COMBAT_ROWS[character]
	var frame: int=f.gun_frame(frames.count(key,row)) if f.shot_flash>0 else 0
	var cache_key:=character+":"+key+":"+str(frame)
	var muzzle: Array=frames.PIXEL.data.atlases["pixel-"+character].frames[4 if f.shot_flash>0 else 3][frame].muzzle
	if not gun_parts.has(cache_key):
		var pose: Dictionary=frames.pose(key,row,frame)
		var factor: float=pose.scale
		var point:=Vector2(muzzle[0],muzzle[1])
		# Only barrel/grip pixels, never a second cheek/eye from the atlas.
		var from: Vector2=((point-Vector2(24,5))/factor-pose.offset).floor()
		var wanted:=Rect2i(Vector2i(from),Vector2i(ceilf(37/factor),ceilf(12/factor)))
		var image: Image=pose.texture.get_image()
		var region:=wanted.intersection(Rect2i(Vector2i.ZERO,image.get_size()))
		gun_parts[cache_key]={"texture":ImageTexture.create_from_image(image.get_region(region)),"offset":pose.offset+Vector2(region.position),"scale":factor}
	var part: Dictionary=gun_parts[cache_key]
	gun_echo.region_enabled=false;gun_echo.texture=part.texture;gun_echo.offset=part.offset
	gun_echo.position=Vector2(World.PLAYER_X,ground+world.y).round()
	if character=="eren" and friend_sprite.get_meta("source_key")=="polish-abilities":
		gun_echo.position+=(f.weapon_muzzle(world)-Vector2(muzzle[0],muzzle[1]))*visual_size
	gun_echo.scale=Vector2.ONE*float(part.scale)*visual_size
	gun_echo.modulate=Color.WHITE;gun_echo.visible=true

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
	return World.flight_frame_for(velocity,air_time,frame_count)

func place_companion(item: Sprite2D, id: String, row: int, frame: int, anchor: Vector2, scale_value: float = 0.62, action: bool = false) -> void:
	if id in ["rabbit","eren"]:action=false
	if id=="owl" and action:
		action=false
		row=6
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
	if world.charging:
		for i in 5:
			draw_rect(Rect2(World.PLAYER_X-28+i*12,ground-94,8,8),Color("f8d9b1") if world.charge_ratio()>=float(i+1)/5 else Color("554154"))
	if character == "sheep" and not world.sheep_pickups.is_empty() and world.sheep_count < 3:
		var x: float = world.sheep_pickups[0].x
		draw_rect(Rect2(x - 10, ground - 104, 20, 20), Color("ad536e"))
		draw_line(Vector2(x - 5, ground - 94), Vector2(x + 5, ground - 94), Color("fff1d5"), 3)
		draw_line(Vector2(x, ground - 99), Vector2(x, ground - 89), Color("fff1d5"), 3)
	for o in world.obstacles:
		if str(o.kind).begins_with("arch") or str(o.kind).begins_with("carrier") or o.kind == "gate" or str(o.kind).begins_with("block") or str(o.kind).begins_with("pit"): continue
		var effect: Dictionary = frames.pose("hazards",0 if o.kind == "ice" else 1,frames.cycle("hazards",0 if o.kind == "ice" else 1,animation_clock(),0.7))
		var tex: Texture2D = effect.texture
		var factor := 76.0/float(tex.get_width())
		draw_texture_rect(tex,Rect2(Vector2(o.x-38,ground+3-tex.get_height()*factor).round(),tex.get_size()*factor),false)
	for pickup in world.pickups:
		var kind: int=maxi(0,world.orchard.KINDS.find(str(pickup.get("kind","apple"))))
		var pose: Dictionary=frames.pickup_pose(world.orchard.KINDS[kind])
		var factor: float=pose.scale
		var bob: float=sin(animation_clock()*3.5+float(pickup.get("id",0)))*2.0 if decorative_motion() else 0.0
		var point:=Vector2(pickup.x,ground+pickup.y+bob)
		draw_texture_rect(pose.texture,Rect2((point+pose.offset*factor).round(),pose.texture.get_size()*factor),false)
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
	var scroll: float = world.travel_distance()
	if world.state == "ready":
		time = menu_clock
		scroll = menu_clock*20.0
	if not decorative_motion(): scroll = 0.0
	var night := 0.12 if world.state=="ready" else (cos(time*TAU/72.0)+1.0)/2.0
	var weights := [0.0,0.0,0.0,0.0,0.0,0.0]
	var biome: int = world.biome()
	var blend := 1.0 if world.distance < World.BIOME_DISTANCE else smoothstep(0.0,0.08,fmod(world.distance/World.BIOME_DISTANCE,1.0))
	weights[biome] = blend
	weights[posmod(biome-1,World.BIOME_NAMES.size())] += 1.0-blend
	var days := [Color("e5a58b"),Color("7396b0"),Color("6b9476"),Color("9183ad"),Color("94ab79"),Color("bd7975")]
	var nights := [Color("3b3655"),Color("253f59"),Color("193c3a"),Color("272d4d"),Color("203842"),Color("492a40")]
	var top := Color("9d667e") if world.state=="ready" else Color("355c80").lerp(Color("0c142a"),night)
	var bottom := Color(0,0,0,1)
	for n in World.BIOME_NAMES.size():
		bottom += days[n].lerp(nights[n],night)*float(weights[n])
	bottom.a = 1.0
	for i in 48:
		var fraction := float(i)/48.0
		draw_rect(Rect2(0,fraction*ground,scene_w,ground/48.0+1),top.lerp(bottom,fraction))
	var previous: int=posmod(biome-1,World.BIOME_NAMES.size())
	if blend<1.0:landscape.panorama(self,previous,scroll,night)
	landscape.panorama(self,biome,scroll,night,blend)
	evolution_view.draw_scene(self,true)
	landscape.foreground(self,scroll,night)
	terrain.draw(self, biome, previous, blend, scroll, night)
	if weights[1]>0.4:
		for i in 28:
			var x := fposmod(float(i*109)-scroll*0.15,scene_w)
			var y := 150.0+fposmod(float(i*73)+(time*24.0 if decorative_motion() else 0.0),maxf(1,ground-150))
			draw_rect(Rect2(x,y,3,3),Color(0.88,0.96,1.0,float(weights[1])*0.5))

func start_boss_practice(kind: int) -> void:
	start_run()
	world.practice = true
	if is_instance_valid(tutorial_panel): tutorial_panel.hide()
	if character=="sheep": world.sheep_count = 3
	world.frontier.request_boss((clampi(kind,0,2)+1)*world.frontier.BOSS_INTERVAL)

func retry_run() -> void:
	if world.practice: start_boss_practice(world.frontier.boss_kind)
	else: start_run()

func update_weapon_visual() -> void:
	var mat: ShaderMaterial=friend_sprite.material
	mat.set_shader_parameter("weapon_red",false)
	var overlay_mat: ShaderMaterial=gun_echo.material
	overlay_mat.set_shader_parameter("weapon_red",world.frontier.red_weapon)
	overlay_mat.set_shader_parameter("weapon_uv",Vector4(0,0,1,1))
	if not world.frontier.red_weapon:return
	if friend_sprite.get_meta("pose_key","") not in ["gun-run","gun-fire"]:return
	var key: String=friend_sprite.get_meta("pose_key")
	var row: int=COMBAT_ROWS[character]
	var col: int=friend_sprite.get_meta("source_frame")
	var pose: Dictionary=frames.pose(key,row,col)
	var data: Dictionary=frames.PIXEL.data.atlases["pixel-"+character]
	var m: Array=data.frames[4 if key=="gun-fire" else 3][col].muzzle
	var lo: Vector2=(Vector2(m[0]-24,m[1]-6)/pose.scale-pose.offset)/pose.texture.get_size()
	var hi: Vector2=(Vector2(m[0]+13,m[1]+8)/pose.scale-pose.offset)/pose.texture.get_size()
	mat.set_shader_parameter("weapon_uv",Vector4(lo.x,lo.y,hi.x,hi.y))
	mat.set_shader_parameter("weapon_red",true)
