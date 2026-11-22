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
	var event:=InputEventKey.new();event.keycode=code;event.pressed=pressed
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

func run() -> void:
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
	print("RESULT: ",checks," campaign selection flow checks, ",failures," failures")
	quit(1 if failures else 0)
