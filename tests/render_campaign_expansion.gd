## Authored render fixtures. Ordinary-input rescue is verified by browser tests.
extends SceneTree
var game: AionCampaignGame
var output: String
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+label)
func _initialize() -> void:call_deferred("run")
func capture(name: String) -> Image:
	game.view.queue_redraw();game.update_hud();await process_frame;await process_frame;await RenderingServer.frame_post_draw
	var result: Image=root.get_texture().get_image();result.save_png(output+"/"+name+".png");return result
func stage(key: String,x: float=400.) -> void:
	game.world.load_section(key);game.world.player=Vector2(x,0);game.world.velocity=Vector2.ZERO;game.world.state="playing";game.menu_kind="";game.build_ui()
	game.view.camera_x=maxf(0.,x-game.view.scene_w*.35)
func run() -> void:
	output=OS.get_environment("AION_EXPANSION_REVIEW")
	if output.is_empty():output="res://build/expansion-review"
	DirAccess.make_dir_recursive_absolute(output);root.size=Vector2i(1280,720)
	game=AionCampaignGame.new();game.language="tr";root.add_child(game);await process_frame;game.set_process(false)
	game.options.theme_mode="dark";game.options.resolve_theme();game.ui.theme=game.options.theme(game.FONT);game.touch_mode=true;game.resize()
	for hero in AionCampaignWorld.HEROES:
		game.world.begin(hero);stage("shore");game.world.enemies.clear();game.world.gates.clear();game.world.objects.clear();game.world.hazards.clear();game.world.zones.clear();game.world.pickups.clear();game.world.crates.clear()
		var n: Dictionary=game.world.npcs[0];n.x=465.;n.home_x=465.;n.y=0.;game.world.player=Vector2(400,0)
		game.world.attack_press();var sheet:=Image.create_empty(7*240,200,false,Image.FORMAT_RGBA8)
		for i in 7:
			var image: Image=await capture("temp")
			var point: Vector2=root.get_final_transform()*game.view.get_global_transform_with_canvas()*Vector2(400.-game.view.camera_x,game.view.ground)
			var area:=Rect2i(Vector2i(point)-Vector2i(70,175),Vector2i(240,200));sheet.blit_rect(image,area,Vector2i(i*240,0))
			check(game.world.player.is_equal_approx(Vector2(400,0)),"Six knife sequences preserve physics anchor: "+hero)
			game.world.step(.05);game.world.step(.05)
		sheet.save_png(output+"/"+hero+"-knife.png")
		check(bool(n.freed),"Drawn cut actually frees captive: "+hero)
		game.world.step(.05);game.world.step(.05);game.world.step(.05);game.world.step(.05);await capture(hero+"-thanks")
		for i in 36:game.world.step(.01)
		await capture(hero+"-gift")
	for leaf in ["water","terrace","roots"]:
		for section in 3:stage(leaf,game.world.STAGES[leaf].length*(.15+section*.33));await capture(leaf+"-"+str(section))
		stage(leaf,600.);game.world.interact();await capture(leaf+"-vehicle")
		stage(leaf,game.world.length()-1050.);await capture(leaf+"-guardian")
	for phase in 3:
		stage("arena",2200.);game.world.boss.phase=phase+1;game.world.boss.engaged=true;game.world.boss.windup=.7;await capture("boss-phase-"+str(phase+1))
	for viewport in [Vector2i(393,873),Vector2i(873,393)]:
		root.size=viewport;await process_frame;game.resize();stage("water",4200.);await capture("mobile-%dx%d" % [viewport.x,viewport.y])
		stage("arena",2200.);game.world.boss.engaged=true;await capture("mobile-boss-%dx%d" % [viewport.x,viewport.y])
	DirAccess.remove_absolute(output+"/temp.png");game.queue_free();await process_frame
	print("RESULT: %d expansion render checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
