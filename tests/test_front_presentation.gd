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

func verify_field_story() -> void:
	var world:=AionCampaignWorld.new()
	world.begin("aion")
	world.state="playing"
	world.pending_events.clear()
	CampaignStory.step(world)
	check(CampaignStory.latest_note(world,"en").is_empty(),"Story discovery is tied to the physical first lantern")
	check(world.notice=="arc_checkpoint" and world.notice_time>0.,"Opening uses the existing checkpoint notice slot")
	world.player.x=610.
	CampaignStory.step(world)
	check(world.state=="playing" and world.notice=="story_lantern","Approaching the cut lantern delivers a non-blocking clue")
	CampaignStory.step(world)
	check(world.pending_events.count("story_clue")==1,"Lantern discovery emits its save event only once")
	var crow: Dictionary=world.enemies.filter(func(enemy):return enemy.kind=="crow" and absf(float(enemy.home.x)-CampaignStory.SIGNAL_X)<=390.).front()
	world.player.x=850.
	CampaignStory.step(world)
	check(world.notice=="story_lantern","An idle crow does not publish the signal clue")
	crow.active=true
	crow.windup=.54
	CampaignStory.step(world)
	check(world.notice=="story_signal" and world.discovered.has(CampaignStory.clue_id("story_signal")),"A real attacking crow can reveal the relay clue over the opening caption")
	var keeper: Dictionary=world.npcs.front()
	world.player=Vector2(float(keeper.x),float(keeper.y))
	world.rescue(keeper)
	CampaignRescue.step(world,.21)
	CampaignStory.step(world)
	check(keeper.phase=="thanks" and world.notice=="story_keeper","Meeting the freed keeper explains the supply during its thanks animation")
	check(keeper.thank_age==0. and not world.gift_drops.has(keeper.id),"Story cue leaves the real gift animation and timing intact")
	world.discovered["map:section:shore"]=true
	world.discovered["shore:secret:fixture"]=true
	check(CampaignStory.secret_count(world)==1,"Narrative and map markers do not inflate the secret score")
	var restored:=AionCampaignWorld.new()
	check(restored.restore(world.snapshot()) and CampaignStory.latest_note(restored,"tr")==CampaignStory.line("tr","story_keeper"),"The witnessed story survives the existing checkpoint format")
	for section: String in CampaignStory.ROUTE_CLUES:
		var route:=AionCampaignWorld.new()
		route.begin("aion")
		route.load_section(section)
		route.state="playing"
		route.notice_time=0.
		var floor:=route.floor_at(CampaignStory.PLATE_X)
		check(CampaignGround.has_floor(floor),"Field plate is grounded in "+section)
		route.player=Vector2(CampaignStory.PLATE_X,floor)
		CampaignStory.step(route)
		var key: String=CampaignStory.ROUTE_CLUES[section][0]
		check(route.notice==key and CampaignStory.latest_note(route,"en")==CampaignStory.line("en",key),"Grounded route plate writes the correct map clue for "+section)

func run() -> void:
	var game=load("res://scripts/game.gd").new()
	root.add_child(game)
	await settle()
	game.set_physics_process(false)
	check(game.opening_guide and not game.front.intro_active and game.ui.find_child("OpeningGuide",true,false)!=null,"Fresh application exposes controls directly after loading")
	var event:=InputEventKey.new();event.keycode=KEY_Y;event.pressed=true
	game._input(event)
	await settle()
	check(game.world.state=="ready" and game.page=="characters","The guide shortcut reaches hero selection without starting the mission")
	game.show_page("main");await settle()
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
	await settle()
	# Reproduce Help -> freshly rebuilt, immediately hidden Main -> Escape.
	# Browser rAFs do not imply that Godot's hidden containers have sorted.
	game.show_page("help");await settle()
	game.show_page("main");game.front.start_demo(0)
	await settle()
	check(game.ui_layout_ready and not game.menu_layer.visible,"Demo may be ready while its freshly built main menu is hidden")
	game.front.input(event)
	check(not game.ui_layout_ready,"Unhiding the menu invalidates stale hit-target telemetry immediately")
	await settle()
	var start: Control=game.menu_layer.find_child("StartCampaign",true,false)
	var panel: Control=game.menu_layer.find_child("PagePanel",true,false)
	check(game.ui_layout_ready and start.is_visible_in_tree(),"Menu readiness returns after real Godot process frames")
	check(start.get_global_rect().position.y>panel.get_global_rect().position.y and start.get_global_rect().size.x>0.,"Ready menu publishes the sorted real StartCampaign rectangle")
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
				var selection: Control=game.menu_layer.find_child("HeroSelection",true,false)
				check(selection.find_children("*","Label",true,false).size()==game.FRIENDS.size()+1,"Selection shows a heading and one name per portrait "+str(dimensions)+" "+str(scale_value)+" "+language)
				for item in game.menu_layer.find_children("*","Control",true,false):
					if not item.is_visible_in_tree() or not (item is Button or item is Label or item is RunnerHeroPreview):continue
					var r: Rect2=item.get_global_rect()
					check(r.position.x>=-1. and r.position.y>=-1. and r.end.x<=game.view_w+1. and r.end.y<=game.view_h+1.,"Reachable hero card "+str(item.name)+" "+str(dimensions)+" "+str(scale_value)+" "+language+" "+str(r))
	game.show_page("characters");await settle()
	for hero in game.FRIENDS:
		game.select_character(hero)
		check(game.character==hero and game.world.character==hero,"Six distinct main selections: "+hero)
	game.show_page("help");await settle()
	check(game.page=="help" and game.world.state=="ready","Help freezes gameplay")
	game.gamepad.back();await settle()
	check(game.page=="main","Gamepad Back returns from help")
	verify_field_story()
	game.queue_free();await settle()
	print("RESULT: ",checks," front presentation checks, ",failures," failures")
	quit(1 if failures else 0)
