extends SceneTree
var checks:=0
var failures:=0
func check(value: bool,message: String) -> void:
	checks+=1
	if not value:failures+=1;printerr("FAIL: "+message)
func settle() -> void:
	await process_frame
	await process_frame
	await process_frame
func bytes(path: String) -> PackedByteArray:
	return FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var game=load("res://scripts/game.gd").new()
	root.add_child(game)
	await settle()
	game.set_physics_process(false)
	check(game.front.intro_active,"Fresh application has the opening presentation")
	var event:=InputEventKey.new();event.keycode=KEY_ENTER;event.pressed=true
	game._input(event)
	await settle()
	check(not game.front.intro_active and game.menu_layer.visible,"Enter skips without starting a run")
	check(game.world.state=="ready" and game.page=="main","Skip reaches the actual main menu")
	var endless: Dictionary={"best":game.best,"score":game.world.score,"hero":game.character}
	var original_save:=bytes("user://save.cfg");var original_campaign:=bytes("user://campaign.json")
	game.front.start_demo(0)
	check(game.front.demo_world!=null and game.front.demo_world!=game.world,"Attract uses its own real campaign world")
	var first_x: float=game.front.demo_world.player.x
	for i in 240:game.front.step(1./60.)
	check(game.front.demo_world.player.x>first_x+100. and game.front.demo_world.shots>0,"Autonomous demo really moves and shoots through game actions")
	check(game.best==endless.best and game.world.score==endless.score and game.character==endless.hero,"Demo leaves player's Endless state intact")
	check(bytes("user://save.cfg")==original_save and bytes("user://campaign.json")==original_campaign,"Demo cannot write preferences or campaign checkpoint")
	game.front.input(event)
	check(game.front.demo_world==null and game.menu_layer.visible,"Any input stops attract and returns cleanly")
	game.front.begin_intro();game.front.frozen=true;var t: float=game.front.intro_time;game.front.step(.05)
	check(game.front.intro_time==t,"Focus pause freezes intro timing")
	game.front.frozen=false;game.front.skip_intro()
	for language in GameText.LANGUAGES:
		for key in RunnerFrontText.KEYS:check(RunnerFrontText.word(language,key)!=key,"Translated front label "+language+" "+key)
		for hero in game.FRIENDS:check(not RunnerFrontText.ability(language,hero).is_empty(),"Translated hero ability "+language+" "+hero)
	# Layout checks are authored scene fixtures, separate from ordinary browser input.
	for dimensions in [Vector2i(1152,648),Vector2i(873,393),Vector2i(393,873),Vector2i(1024,768)]:
		root.size=dimensions
		game.touch_mode=dimensions.x<1000
		for scale_value in [1.,1.5,2.]:
			for language in ["tr","en","de","ja"]:
				game.language=language;game.interface_options.text_scale=scale_value;game.build_theme();game.ui.theme=game.ui_theme;game.rebuild()
				await settle()
				for item in game.menu_layer.find_children("*","Button",true,false):
					if not item.is_visible_in_tree():continue
					var r: Rect2=item.get_global_rect()
					check(r.position.x>=-1. and r.position.y>=-1. and r.end.x<=game.view_w+1. and r.end.y<=game.view_h+1.,"Reachable main action "+str(item.name)+" "+str(dimensions)+" "+str(scale_value)+" "+language+" "+str(r))
	for dimensions in [Vector2i(1152,648),Vector2i(873,393),Vector2i(393,873)]:
		root.size=dimensions;game.touch_mode=dimensions.x<1000
		for scale_value in [1.,2.]:
			for language in ["tr","en","de","ja"]:
				game.language=language;game.interface_options.text_scale=scale_value;game.build_theme();game.ui.theme=game.ui_theme;game.show_page("characters")
				await settle()
				for index in game.menu_pages.pages.size():
					game.menu_pages.select(index,false);await settle()
					for item in game.menu_layer.find_children("*","Control",true,false):
						if not item.is_visible_in_tree() or not (item is Button or item is Label or item is RunnerHeroPreview):continue
						var r: Rect2=item.get_global_rect()
						check(r.position.x>=-1. and r.position.y>=-1. and r.end.x<=game.view_w+1. and r.end.y<=game.view_h+1.,"Reachable hero card "+str(item.name)+" "+str(dimensions)+" "+str(scale_value)+" "+language+" "+str(r))
	game.show_page("main");await settle()
	for hero in game.FRIENDS:
		game.select_character(hero)
		check(game.character==hero and game.world.character==hero,"Six distinct main selections: "+hero)
	game.show_page("help");await settle()
	check(game.page=="help" and game.world.state=="ready","Help freezes gameplay")
	game.gamepad.back();await settle()
	check(game.page=="main","Gamepad Back returns from help")
	game.queue_free();await settle()
	print("RESULT: ",checks," front presentation checks, ",failures," failures")
	quit(1 if failures else 0)
