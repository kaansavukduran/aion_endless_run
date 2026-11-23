extends SceneTree

var checks := 0
var failures := 0

func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+message)

func _initialize() -> void:call_deferred("run")

func settle() -> void:
	for _i in 4:await process_frame

func key(code: Key,pressed: bool=true) -> void:
	var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=pressed
	root.push_input(event,true)

func pointer(at: Vector2) -> void:
	var event:=InputEventMouseMotion.new();event.position=at;event.global_position=at
	root.push_input(event,true)

func click(button: Button) -> void:
	var at: Vector2=button.get_global_transform_with_canvas()* (button.size*.5)
	pointer(at)
	for pressed in [true,false]:
		var event:=InputEventMouseButton.new();event.position=at;event.global_position=at;event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed
		root.push_input(event,true)

func actual_pointer_crouch(g) -> void:
	if g.menu_kind=="briefing":
		click(g.ui.find_child("CampaignBegin",true,false));await settle()
	for _step in 12:
		if g.menu_kind!="help":break
		for example in g.ui.find_children("*","Control",true,false):
			if example is CampaignPresentation and example.is_visible_in_tree():
				check(example.rendered_source.begins_with("mission-hero-"),"Normal newhero Help draws its actual identity: topic "+str(example.topic_index))
		click(g.ui.find_child("CampaignGo",true,false));await settle()
	var deadline: int=Time.get_ticks_msec()+10000
	while (g.presentation_stage!="" or g.world.state!="playing") and Time.get_ticks_msec()<deadline:await process_frame
	check(g.menu_kind=="" and g.world.state=="playing","The real campaign UI reaches a live actor for the pointer/crouch regression")
	if g.world.state!="playing":return
	key(KEY_F);key(KEY_D)
	deadline=Time.get_ticks_msec()+6000
	while g.world.player.x<340. and g.world.state=="playing" and Time.get_ticks_msec()<deadline:
		pointer(g.view.get_global_transform_with_canvas()*g.view.at(g.world.player+Vector2(300,-38)))
		await process_frame
	key(KEY_D,false)
	check(g.world.player.x>=340. and g.world.hp>0,"Normal movement and fire create room for both backpedal directions")
	for direction in [1,-1]:
		key(KEY_S,false)
		pointer(g.view.get_global_transform_with_canvas()*g.view.at(g.world.player+Vector2(direction*300,-38)))
		deadline=Time.get_ticks_msec()+3000
		while g.world.aim_direction.x*direction<.8 and g.world.state=="playing" and Time.get_ticks_msec()<deadline:await process_frame
		var move: Key=KEY_A if direction==1 else KEY_D
		var shots: int=g.world.shots
		var until: float=g.world.time+.55
		var frames: Dictionary={};var observed:=0;var aim_preserved:=true;var gait_correct:=true
		var accepted: Dictionary={}
		for frame in 6:
			var cel: Dictionary=M1HeroArt.metrics(g.world.character,"crouch_walk_back",frame)
			accepted[str(cel.source_key)+":"+str(cel.source_row)]=true
		key(KEY_S);key(move)
		deadline=Time.get_ticks_msec()+6000
		while g.world.time<until and g.world.state=="playing" and Time.get_ticks_msec()<deadline:
			pointer(g.view.get_global_transform_with_canvas()*g.view.at(g.world.player+Vector2(direction*300,-38)))
			if g.world.crouching() and g.world.grounded() and absf(g.world.velocity.x)>10.:
				observed+=1;aim_preserved=aim_preserved and g.world.aim_direction.x*direction>.8
				var marker: Dictionary=g.view.hero_marker
				if not marker.is_empty():
					var source: String=str(marker.source)+":"+str(marker.row)
					gait_correct=gait_correct and accepted.has(source)
					frames[int(marker.frame)]=true
			await process_frame
		key(move,false);key(KEY_S,false)
		check(observed>0 and aim_preserved,"Actual pointer + S + opposite movement preserves aim: "+str(direction))
		check(gait_correct and frames.size()>=2,"Actual rendered low backpedal gait advances through authored frames: "+str(direction))
		check(g.world.shots>shots,"Actual fire continues through pointer-locked crouch backpedal: "+str(direction))
	key(KEY_F,false)

func check_six_previews() -> void:
	for hero in ["aion","sheep","rabbit","eren","armadillo","frog"]:
		var preview:=RunnerHeroPreview.new();preview.hero=hero;preview.size=Vector2(180,130);root.add_child(preview)
		for state in ["idle","focus","select","launch"]:
			preview.set_select_state(state);preview.clock=.27;preview.set_paused(true)
			await settle()
			check(preview.rendered_frame==preview.current_frame(),hero+" "+state+" renders the active clip frame")
			check(not preview.rendered_pose.is_empty() and preview.rendered_pose.texture.get_size().x>0.,hero+" "+state+" supplies an actual body texture")
		if hero in ["armadillo","frog"]:
			preview.set_select_state("");preview.action="ability";preview.clock=1.22;await settle()
			var authored: Dictionary=M1HeroArt.metrics(hero,"skill",preview.current_frame())
			check(str(preview.playback_spec().body_action)=="skill" and str(preview.rendered_pose.source_key)==str(authored.source_key) and int(preview.rendered_pose.source_row)==int(authored.source_row) and int(preview.rendered_pose.source_frame)==int(authored.source_frame),hero+" help renders its actual authored skill atlas, row and frame")
			var frame: int=preview.current_frame();preview.step_frame();preview.set_paused(false);preview.set_paused(true)
			check(str(preview.playback_spec().body_action)=="skill" and preview.current_frame()==frame+1,hero+" stepping and resume preserve the active skill clip")
			check(RunnerFrontText.ability("tr",hero)!=RunnerFrontText.ability("en",hero),hero+" has localized skill descriptions")
		preview.free()

func run() -> void:
	await check_six_previews()
	var preview:=RunnerHeroPreview.new();preview.size=Vector2(180,130);preview.set_select_state("focus");root.add_child(preview)
	await settle()
	while preview.current_frame()<2:await process_frame
	preview.set_paused(true)
	var frozen: int=preview.current_frame()
	var frozen_clock: float=preview.clock
	await settle()
	check(preview.current_frame()==frozen and preview.clock==frozen_clock,"Pausing an attached preview preserves its visible nonzero frame and clock")
	check(preview.rendered_frame==frozen,"Renderer draws the frozen frame rather than jumping to zero")
	check(preview.step_frame()==posmod(frozen+1,int(preview.playback_spec().frames)),"Step starts from the actual paused clip frame")
	await settle()
	check(preview.rendered_frame==preview.manual_frame,"Frame step reaches the renderer")
	var stepped: int=preview.current_frame()
	preview.set_paused(false)
	while preview.current_frame()==stepped:await process_frame
	check(preview.manual_frame==-1 and preview.current_frame()!=stepped,"Resume clears manual stepping and advances from the held frame")
	preview.set_select_state("launch");preview.clock=.26;preview.set_paused(true)
	var launch_frozen: int=preview.current_frame();await settle()
	check(launch_frozen==2 and preview.rendered_frame==launch_frozen,"Pausing a one-shot launch preserves the current rendered frame")
	preview.step_frame(999)
	check(preview.current_frame()==int(preview.playback_spec().frames)-1,"One-shot stepping clamps at its actual last frame")
	preview.step_frame(-999)
	check(preview.current_frame()==0,"One-shot stepping clamps at its first frame")
	preview.free()

	var game=load("res://scripts/game.gd").new();root.add_child(game);current_scene=game
	await settle();game.front.skip_intro();game.front.stop_demo();game.motion=true;game.interface_options.reduced_motion=false;game.rebuild();await settle()
	check(game.FRIENDS==["aion","sheep","rabbit","eren","armadillo","frog"],"The current roster keeps the original four identities followed by the two new heroes")
	for hero in game.FRIENDS:
		var choice: Button=game.menu_layer.find_child("StartSelect_"+hero,true,false)
		var page_limit:=0
		while not is_instance_valid(choice) and page_limit<3:
			var next: Button=game.menu_layer.find_child("RosterNext",true,false)
			if not is_instance_valid(next) or next.disabled:break
			click(next);await settle();page_limit+=1
			choice=game.menu_layer.find_child("StartSelect_"+hero,true,false)
		check(is_instance_valid(choice) and choice.is_visible_in_tree(),hero+" is reachable through the real roster")
		if not is_instance_valid(choice):continue
		click(choice);await settle()
		check(game.character==hero and game.pixel_ui.roster_previews[hero].select_state=="select",hero+" is selected by its actual card click")
		var endless: Button=game.menu_layer.find_child("StartRun",true,false)
		check(endless.disabled==(hero not in game.World.PLAYABLE_HEROES),hero+" accurately exposes the original four-hero Endless scope")

	var selected: String=game.character
	var other: String=game.FRIENDS[1] if selected!=game.FRIENDS[1] else game.FRIENDS[0]
	var tile: Button=game.menu_layer.find_child("StartSelect_"+other,true,false)
	var image: RunnerHeroPreview=game.pixel_ui.roster_previews[other]
	tile.grab_focus();await settle()
	pointer(tile.get_global_transform_with_canvas()*(tile.size*.5));await settle()
	pointer(Vector2(2,2));await settle()
	check(tile.has_focus() and image.select_state=="focus","Mouse exit preserves active keyboard focus")
	pointer(tile.get_global_transform_with_canvas()*(tile.size*.5));await settle();tile.release_focus();await settle()
	check(tile.is_hovered() and image.select_state=="focus","Focus exit preserves active mouse hover")
	check(game.character==selected,"Hover and focus never change the selected hero")
	var start: Button=game.menu_layer.find_child("StartCampaign",true,false)
	click(start);await process_frame
	check(game.pixel_ui.launch_pending and current_scene==game,"A normal Play click leaves the selected launch visible before scene replacement")
	var launch: RunnerHeroPreview=game.pixel_ui.roster_previews[selected]
	var visible_frames: Dictionary={}
	for _i in 3:key(KEY_ENTER);key(KEY_ENTER,false)
	var launch_deadline: int=Time.get_ticks_msec()+4000
	while is_instance_valid(game) and not game.is_queued_for_deletion() and Time.get_ticks_msec()<launch_deadline:
		if is_instance_valid(launch):visible_frames[launch.rendered_frame]=true
		await process_frame
	await settle()
	if current_scene==game:
		check(false,"Visible launch completes within its clip deadline")
		game.free();quit(1);return
	check(visible_frames.size()>=3,"Actual launch renderer presents multiple frames before leaving the menu")
	check(is_instance_valid(current_scene) and current_scene.get("selected_hero")==selected,"Completed launch opens Mission 1 with the selected hero")
	var campaigns:=0
	for child in root.get_children():
		if child.get_script()==load("res://scripts/campaign_game.gd"):campaigns+=1
	check(campaigns==1,"Repeated confirmation during launch creates exactly one campaign")
	await actual_pointer_crouch(current_scene)
	var checkpoint: Dictionary=current_scene.world.snapshot()
	current_scene.free()
	var checkpoint_file:=FileAccess.open("user://campaign.json",FileAccess.WRITE)
	checkpoint_file.store_string(JSON.stringify(checkpoint));checkpoint_file.close()
	game=load("res://scripts/game.gd").new();root.add_child(game);current_scene=game;await settle()
	game.front.skip_intro();game.front.stop_demo();game.motion=true;game.rebuild();await settle()
	var continue_button: Button=game.menu_layer.find_child("ContinueCampaign",true,false)
	check(is_instance_valid(continue_button),"A valid saved campaign exposes Continue")
	click(continue_button)
	check(current_scene!=game and game.campaign_started,"Continue completes immediately without waiting for the launch clip")
	await settle()
	check(current_scene.resume_on_ready and current_scene.world.character==str(checkpoint.character),"Quick Continue uses the same selected checkpoint flow")
	current_scene.free()

	game=load("res://scripts/game.gd").new();root.add_child(game);current_scene=game;await settle()
	game.front.skip_intro();game.front.stop_demo();game.motion=false;game.rebuild();await settle()
	start=game.menu_layer.find_child("StartCampaign",true,false);click(start)
	check(current_scene!=game and game.campaign_started,"Reduced motion completes Play immediately through the same transition owner")
	await settle();current_scene.free();await process_frame
	game=load("res://scripts/game.gd").new();root.add_child(game);current_scene=game;await settle()
	game.front.skip_intro();game.front.stop_demo();game.motion=false;game.character="frog";game.world.character="frog";game.rebuild();await settle()
	game.start_run()
	check(current_scene==game and game.page=="main" and game.world.state=="ready","Unsupported Endless entry keeps the new hero on the visible main menu without a silent identity fallback")
	await settle()
	var focused: Control=root.gui_get_focus_owner()
	if is_instance_valid(focused):focused.release_focus()
	key(KEY_ENTER);key(KEY_ENTER,false)
	check(current_scene!=game and game.campaign_started,"An ordinary Enter with no focus invokes the primary Mission 1 action")
	await settle()
	check(current_scene.selected_hero=="frog","The keyboard primary-action fallback preserves the chosen new hero")
	current_scene.free();await process_frame
	print("RESULT: ",checks," campaign selection flow checks, ",failures," failures")
	quit(1 if failures else 0)
