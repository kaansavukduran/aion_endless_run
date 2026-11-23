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
	var result: Image=root.get_texture().get_image()
	check(result.get_size()==root.size,"Actual native viewport captured: "+name)
	if name!="temp":check(result.save_png(output+"/"+name+".png")==OK,"Native PNG was written: "+name)
	return result
func stage(key: String,x: float=400.) -> void:
	game.world.load_section(key);game.world.player=Vector2(x,0);game.world.velocity=Vector2.ZERO;game.world.state="playing";game.menu_kind="";game.build_ui()
	game.view.camera_x=clampf(x-game.view.scene_w*.35,0.,maxf(0.,game.world.length()-game.view.scene_w));game.view.camera_y=0.
func run() -> void:
	output=OS.get_environment("AION_EXPANSION_REVIEW")
	if output.is_empty():output="res://build/expansion-review"
	DirAccess.make_dir_recursive_absolute(output);root.size=Vector2i(1280,720)
	game=AionCampaignGame.new();game.language="tr";root.add_child(game);await process_frame;game.set_process(false)
	game.options.theme_mode="dark";game.options.reduced_motion=false;game.motion_enabled=true;game.world.pose_motion_enabled=true;game.options.resolve_theme();game.ui.theme=game.options.theme(game.FONT);game.touch_mode=true;game.resize()
	for hero in AionCampaignWorld.HEROES:
		game.world.begin(hero);stage("shore");game.world.enemies.clear();game.world.gates.clear();game.world.objects.clear();game.world.hazards.clear();game.world.zones.clear();game.world.pickups.clear();game.world.crates.clear()
		var n: Dictionary=game.world.npcs[0];n.x=465.;n.home_x=465.;n.y=0.;game.world.player=Vector2(400,0)
		game.world.attack_press();var sheet:=Image.create_empty(7*240,200,false,Image.FORMAT_RGBA8)
		check(game.world.rescue_time>0.,"The actual attack action starts the contextual cut: "+hero)
		for i in 7:
			var image: Image=await capture("temp")
			var point: Vector2=root.get_final_transform()*game.view.get_global_transform_with_canvas()*Vector2(400.-game.view.camera_x,game.view.ground)
			var area:=Rect2i(Vector2i(point)-Vector2i(70,175),Vector2i(240,200))
			check(Rect2i(Vector2i.ZERO,image.get_size()).encloses(area),"Complete cut/NPC cel fits the native viewport")
			sheet.blit_rect(image,area,Vector2i(i*240,0))
			check(game.world.player.is_equal_approx(Vector2(400,0)),"All six playable cut sequences preserve the real physics anchor: "+hero)
			var body: Dictionary=M1CombatArt.body_spec(game.world)
			var expected: Dictionary=M1HeroArt.metrics(hero,str(body.action),int(body.frame))
			check(str(game.view.hero_marker.source)==str(expected.source_key) and int(game.view.hero_marker.row)==int(expected.source_row) and int(game.view.hero_marker.frame)==int(expected.source_frame),"Cut uses the selected hero's exact registered body and cel")
			game.world.step(.05);game.world.step(.05)
		check(sheet.save_png(output+"/"+hero+"-knife.png")==OK,"Seven native cut/NPC cels were written: "+hero)
		check(bool(n.freed),"Drawn cut actually frees captive: "+hero)
		# Rope release now starts roaming; the thanks/gift fixture must approach
		# through normal movement before naming a capture after that real phase.
		for i in 150:
			if str(n.get("phase",""))=="thanks":break
			game.world.move_axis=Vector2(signf(float(n.x)-game.world.player.x),0.);game.world.step(.01)
		game.world.move_axis=Vector2.ZERO;game.world.step(.001)
		check(str(n.get("phase",""))=="thanks","Thanks capture is a real contact-triggered phase: "+hero)
		await capture(hero+"-thanks")
		var weapon_before: String=game.world.weapon
		for i in 95:game.world.step(.01)
		check(game.world.gift_drops.has(str(n.id)) and game.world.pickups.any(func(p):return str(p.get("rescue_id",""))==str(n.id)),"Bag extraction leaves an actual unclaimed pickup: "+hero)
		check(game.world.weapon==weapon_before and not game.world.awarded.has(str(n.id)+":gift"),"A visible bag drop does not grant its reward remotely")
		await capture(hero+"-gift")
		for i in 200:
			if game.world.taken.has(str(n.id)+":supply"):break
			var gift: Dictionary=game.world.gift_drops.get(str(n.id),{})
			if gift.is_empty():break
			game.world.move_axis=Vector2(signf(float(gift.x)-game.world.player.x),0.);game.world.step(.01)
		game.world.move_axis=Vector2.ZERO;game.world.step(.001)
		check(game.world.taken.has(str(n.id)+":supply") and game.world.awarded.has(str(n.id)+":gift") and not game.world.gift_drops.has(str(n.id)),"Ordinary walking contact collects and claims the physical gift once: "+hero)
		await capture(hero+"-gift-collected")
	for leaf in ["water","terrace","roots"]:
		for section in 3:stage(leaf,game.world.STAGES[leaf].length*(.15+section*.33));await capture(leaf+"-"+str(section))
		stage(leaf,600.)
		check(game.world.interact() and game.world.mount_transition=="enter","Vehicle fixture begins through the actual contextual entry: "+leaf)
		await capture(leaf+"-vehicle-entry")
		for i in 10:game.world.step(.05)
		check(bool(game.world.mount.ridden) and game.world.mount_transition.is_empty() and int(game.world.mount.hp)==1,"Vehicle capture is actually mounted, complete and has one HP: "+leaf)
		await capture(leaf+"-vehicle")
		game.world.aim_direction=Vector2(-.8,-.6)
		await capture(leaf+"-vehicle-aim-left")
		stage(leaf,game.world.length()-1050.);await capture(leaf+"-guardian")
	for phase in 3:
		stage("arena",2200.);game.world.boss.phase=phase+1;game.world.boss.engaged=true;game.world.boss.windup=.7;await capture("boss-phase-"+str(phase+1))
	for viewport in [Vector2i(393,873),Vector2i(873,393)]:
		root.size=viewport;await process_frame;game.resize();stage("water",4200.);await capture("mobile-%dx%d" % [viewport.x,viewport.y])
		stage("arena",2200.);game.world.boss.engaged=true;await capture("mobile-boss-%dx%d" % [viewport.x,viewport.y])
	game.queue_free();await process_frame
	print("RESULT: %d expansion render checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
