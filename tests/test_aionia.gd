extends SceneTree
const Options=preload("res://scripts/interface_options.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+message)
func _initialize() -> void:call_deferred("run")
func luminance(hex: String) -> float:
	var c:=Color(hex).srgb_to_linear()
	return c.r*.2126+c.g*.7152+c.b*.0722
func contrast(a: String,b: String) -> float:
	var x:=luminance(a);var y:=luminance(b)
	return (maxf(x,y)+.05)/(minf(x,y)+.05)
func joy(game,button: int,pressed: bool=true) -> void:
	var e:=InputEventJoypadButton.new();e.button_index=button;e.pressed=pressed;e.device=0;game._input(e)
func run() -> void:
	for scale_value in [1,2,3]:
		var safe:=Options.safe_layout(Vector2(1080,2400),Rect2i(0,0,1080*scale_value,2400*scale_value),Rect2i(0,80*scale_value,1080*scale_value,2240*scale_value))
		check(safe==Rect2(0,80,1080,2240),"Native safe areas map physical window pixels at DPI "+str(scale_value))
	check(Options.safe_layout(Vector2(400,800),Rect2i(20,40,400,800),Rect2i(0,60,500,740))==Rect2(0,20,400,740),"A safe-area intersection accounts for nonzero window origin")
	check(Options.safe_layout(Vector2(400,800),Rect2i(),Rect2i())==Rect2(0,0,400,800),"Unavailable native safe-area data falls back without shrinking usable controls")
	var o:=Options.new();var cfg:=ConfigFile.new();o.load_from(cfg)
	check(o.theme_mode=="dark" and o.dark and o.font_mode=="system" and o.text_scale==1.0,"First launch is dark with system font, independent of OS theme")
	check(o.font_for(preload("res://assets/PixelifySans.ttf")) is SystemFont,"Normal text uses a real SystemFont with safe fallback")
	for palette in [o.DARK,o.LIGHT]:
		for pair in [["text","surface"],["muted","surface"],["text","raised"],["on_primary","primary"],["on_primary","primary_hover"],["on_primary","primary_pressed"]]:check(contrast(palette[pair[0]],palette[pair[1]])>=4.5,"Actual text token contrast >=4.5 "+str(pair))
		for pair in [["border","surface"],["border","raised"],["border","background"]]:check(contrast(palette[pair[0]],palette[pair[1]])>=3,"Actual control boundaries >=3 "+str(pair))
	o.theme_mode="light";o.font_mode="pixel";o.text_scale=2;o.reduced_motion=true;o.save_to(cfg)
	var restored:=Options.new();restored.load_from(cfg)
	check(not restored.dark and restored.theme_mode=="light" and restored.font_mode=="pixel" and restored.text_scale==2 and restored.reduced_motion,"Explicit appearance choices survive settings serialization")
	var path:="user://save.cfg";var original:=FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()
	var game=load("res://main.tscn").instantiate();root.add_child(game);await process_frame;game.set_physics_process(false)
	print("AIONIA_BODY_FONT ",game.interface_options.body_font.get_font_name())
	check(game.GAME_VERSION==ProjectSettings.get_setting("application/config/version"),"Displayed and exported application versions agree")
	for code in ["tr","en","cs"]:
		game.language=code;check(game.text("version").contains(game.GAME_VERSION),"Localized version agrees with the running application "+code)
	game.touch_mode=true;game.touch_tutorial_done=true;game.interface_options.text_scale=1.0;game.interface_options.font_mode="system"
	game.interface_options.theme_mode="dark";game.interface_options.resolve_theme();game.build_theme();game.ui.theme=game.ui_theme
	check(not game.gamepad.haptics,"Controller vibration is opt-in by default")
	for action in game.gamepad.DEFAULT_BINDINGS:check(game.gamepad.bindings[action]==game.gamepad.DEFAULT_BINDINGS[action],"Existing Xbox/PlayStation action is preserved "+action)
	game.page="settings";game.rebuild();await process_frame
	game.gamepad.begin_capture("jump");joy(game,JOY_BUTTON_Y)
	check(game.gamepad.bindings.jump==JOY_BUTTON_Y and game.gamepad.capturing=="","The first fresh pad press rebinds after activating a remap control")
	game.gamepad.begin_capture("attack");joy(game,JOY_BUTTON_Y)
	check(game.gamepad.bindings.attack==JOY_BUTTON_Y and game.gamepad.bindings.jump==JOY_BUTTON_X,"Reusing a button swaps actions without duplicate bindings")
	game.gamepad.begin_capture("duck");joy(game,JOY_BUTTON_START)
	check(game.gamepad.capturing=="" and game.page=="settings","Start cancels remapping without activating or closing the settings page")
	var pad_cfg:=ConfigFile.new();game.gamepad.deadzone=.36;game.gamepad.haptics=true;game.gamepad.save_to(pad_cfg)
	var pad=load("res://scripts/gamepad.gd").new();pad.load_from(pad_cfg)
	check(pad.bindings==game.gamepad.bindings and is_equal_approx(pad.deadzone,.36) and pad.haptics,"Mappings, deadzone and optional vibration persist")
	game.gamepad.bindings=game.gamepad.DEFAULT_BINDINGS.duplicate();game.gamepad.haptics=false
	game.main_menu();game.select_character("aion");game.start_run();joy(game,JOY_BUTTON_A);game.world.step(.02)
	check(game.world.y<0 and game.world.jump_held,"Default pad A still jumps and holds")
	joy(game,JOY_BUTTON_A,false);joy(game,JOY_BUTTON_X);game.world.step(.02)
	check(game.world.adventure.attack_time>0 and game.active_input=="gamepad","Pad attack reaches the actual action and updates input prompts")
	joy(game,JOY_BUTTON_X,false);game.update_hud()
	check(game.footer_label.text.contains(game.gamepad.binding_name("attack")),"Live pad prompts use actual current mapping")
	game.on_gamepad_connection(0,false)
	check(game.page=="paused" and not game.world.jump_held and not game.world.boost_held and game.attack_sources.is_empty(),"Controller disconnect pauses and clears every held action")
	game.interface_options.reduced_motion=true;game.motion=true
	check(not game.decorative_motion() and game.motion,"Reduced motion suppresses decoration without freezing hero animation")
	for dimensions in [Vector2i(393,873),Vector2i(873,393),Vector2i(1440,2560)]:
		root.size=dimensions;await process_frame
		for lang in ["tr","en","cs"]:
			game.language=lang
			for key in ["theme","theme_dark","theme_light","theme_system","ui_font","text_size","reduced_motion","controller","pad_capture","pad_remap_help","pad_reset"]:check(game.text(key)!=key,"Localized AIONIA option "+lang+"/"+key)
			for scale_value in [1.0,2.0]:
				game.interface_options.text_scale=scale_value;game.build_theme();game.ui.theme=game.ui_theme
				for target in ["main","finished","paused","settings"]:
					game.page=target;game.rebuild();await process_frame;await process_frame
					var screen:=Rect2(Vector2.ZERO,Vector2(game.view_w,game.view_h))
					var panel: Control=game.menu_layer.get_node("PagePanel")
					if game.touch_mode and game.interface_options.touch_layout=="split":check(game.action_buttons.jump.position.x<game.view_w*.5 and game.action_buttons.attack.position.x>game.view_w*.5,"Approved split-thumb layout "+str(dimensions))
					if target=="main" and scale_value==1.0:
						var choose: Label=game.menu_layer.get_node("StartChooser")
						check(not panel.get_global_rect().intersects(choose.get_global_rect()),"Character heading does not overlap main actions "+lang+str(dimensions))
						check(choose.size.x>=floorf(game.view_w-56) and choose.get_minimum_size().y<=choose.size.y,"Character heading has real readable width "+lang)
						for tile in game.menu_layer.find_children("StartSelect_*","Button",true,false):
							check(tile.get_global_rect().grow(1).encloses(tile.get_child(0).get_global_rect()),"Actual portrait/name content stays inside its character card "+lang+str(tile.name))
					check(screen.encloses(panel.get_global_rect()),"Panel fits "+str(dimensions)+lang+str(scale_value)+target)
					var scrolls=panel.find_children("*","ScrollContainer",true,false)
					check(scrolls.size()==(1 if target=="settings" or scale_value>1.25 else 0),"Only necessary settings/enlarged text pages scroll "+target)
					if not scrolls.is_empty():
						var buttons=scrolls[0].find_children("*","Button",true,false)
						if not buttons.is_empty():
							scrolls[0].ensure_control_visible(buttons[-1]);await process_frame;await process_frame
							check(scrolls[0].get_global_rect().encloses(buttons[-1].get_global_rect()),"Last enlarged/long-menu action is reachable "+lang+target)
	root.size=Vector2i(1200,540);await process_frame
	game.interface_options.text_scale=1;game.language="cs";game.page="main"
	for family in ["DejaVu Sans","Liberation Sans"]:
		var alternate:=SystemFont.new();alternate.font_names=PackedStringArray([family]);alternate.fallbacks=[ThemeDB.fallback_font]
		game.interface_options.body_font=alternate;game.ui_theme.default_font=alternate
		game.rebuild();await process_frame;await process_frame
		print("AIONIA_ALTERNATE_FONT ",alternate.get_font_name())
		for tile in game.menu_layer.find_children("StartSelect_*","Button",true,false):
			if not tile.get_global_rect().grow(1).encloses(tile.get_child(0).get_global_rect()):
				var title: Label=tile.get_child(0).get_child(1)
				print("FONT_LAYOUT_DEBUG ",tile.get_global_rect()," row ",tile.get_child(0).get_global_rect()," title ",title.get_global_rect()," min ",title.get_minimum_size()," font ",title.get_theme_font("font").get_font_name()," theme ",game.ui.theme.default_font.get_font_name()," same ",game.ui.theme==game.ui_theme," lines ",title.get_line_count()," size ",title.get_theme_font_size("font_size")," measure ",alternate.get_multiline_string_size(title.text,HORIZONTAL_ALIGNMENT_LEFT,title.size.x,title.get_theme_font_size("font_size")))
			check(tile.get_global_rect().grow(1).encloses(tile.get_child(0).get_global_rect()),"Czech names fit measured alternate font "+family+str(tile.name))
		check(not game.menu_layer.get_node("PagePanel").get_global_rect().intersects(game.menu_layer.get_node("StartChooser").get_global_rect()),"Measured alternate-font roster does not overlap main actions "+family)
	game.interface_options.text_scale=1;game.world.reset();game.world.state="running";game.world.adventure.celebrations_enabled=true
	game.world.adventure.collect(game.world,"fragaria")
	var party: Array=game.evolution_view.fragaria_tableau()
	check(party.size()==8 and party[0].row==0 and party[-1].row==7,"Fragaria uses eight distinct existing celebration identities")
	check(party.all(func(item):return item.anchor.y<game.ground-40),"All eight party figures stand behind and above the running road")
	var before: float=party[0].anchor.x;game.world.distance+=100
	check(game.evolution_view.fragaria_tableau()[0].anchor.x<before,"Fragaria background travels behind the runner with world progress")
	game.world.adventure.fragaria_time=0
	check(game.evolution_view.fragaria_tableau().is_empty(),"The full celebration cleans up when its real timer ends")
	game.queue_free();await process_frame
	if original.is_empty():DirAccess.remove_absolute(path)
	else:
		var f:=FileAccess.open(path,FileAccess.WRITE);f.store_buffer(original);f.close()
	print("RESULT: %d AIONIA checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
