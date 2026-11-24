## Authored review fixtures; NOT evidence of ordinary-input mission completion.
extends SceneTree
var game: AionCampaignGame
var output: String
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+message)
func _initialize() -> void:call_deferred("run")
func capture(name: String) -> Image:
	game.view.queue_redraw();game.update_hud()
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	var image: Image=root.get_texture().get_image()
	check(image.get_size()==root.size,"Actual renderer returned the current viewport: "+name)
	if name!="review-temp":check(image.save_png(output+"/"+name+".png")==OK,"Native PNG was written: "+name)
	return image
func stage(id: String,x: float=600.) -> void:
	game.world.load_section(id);game.world.player=Vector2(x,game.world.floor_at(x));game.world.velocity=Vector2.ZERO;game.menu_kind="";game.build_ui()
	game.view.camera_x=clampf(x-game.view.scene_w*.34,0.,maxf(0.,game.world.length()-game.view.scene_w))
	game.view.camera_y=CampaignRoutes.camera_y(game.world,0.)

func clip_pose(clip: String,frame: int) -> String:
	game.world.move_axis=Vector2.ZERO;game.world.velocity=Vector2.ZERO;game.world.player.y=0.
	game.world.charging=false;game.world.melee_time=0.;game.world.rescue_time=0.;game.world.shot_flash=0.
	game.world.walk_distance=0.;game.world.aim_direction=Vector2.RIGHT;game.world.facing=1
	match clip:
		"walk":game.world.velocity.x=235.;game.world.walk_distance=(float(frame)+.1)/6.*174.
		"crouch_walk":game.world.move_axis=Vector2(1,1);game.world.velocity.x=235.*.42;game.world.walk_distance=(float(frame)+.1)/6.*110.
		"crouch_fire":game.world.move_axis=Vector2.DOWN;game.world.shot_flash=.18*(1.-(float(frame)+.1)/6.)
		"air_fire":
			game.world.player.y=-110.;game.world.velocity.y=-150.;game.world.air_time=.3
			game.world.shot_flash=.18*(1.-(float(frame)+.1)/6.)
			if game.world.character=="armadillo":game.world.velocity.y=lerpf(-650.,650.,float(frame)/5.)
		"melee":game.world.melee_time=.28*(1.-(float(frame)+.1)/6.)
		_:game.world.shot_flash=.18*(1.-(float(frame)+.1)/6.)
	if clip=="melee" and game.world.character not in ["aion","sheep"]:
		return "idle_fire"
	return clip
func run() -> void:
	output=OS.get_environment("AION_CAMPAIGN_REVIEW")
	if output.is_empty():output="res://build/campaign-review"
	DirAccess.make_dir_recursive_absolute(output)
	root.size=Vector2i(1280,720)
	game=AionCampaignGame.new();game.language="tr";root.add_child(game);await process_frame;game.set_process(false)
	game.options.text_scale=1.;game.options.font_mode="system";game.options.theme_mode="dark";game.options.reduced_motion=false;game.motion_enabled=true;game.world.pose_motion_enabled=true;game.options.resolve_theme();game.ui.theme=game.options.theme(game.FONT)
	game.touch_mode=true;game.resize();game.world.state="playing";game.menu_kind="";game.build_ui()
	for id in ["shore","canopy","water","terrace","roots","relay"]:
		stage(id,900.);await capture(id)
	for junction in CampaignRoutes.FORKS:
		for upper in [false,true]:
			if junction=="fork_two" and not upper:
				game.world.activated.erase(CampaignRoutes.HATCH_ID)
				stage(junction,980.)
				check(not CampaignRoutes.hatch_open(game.world) and is_equal_approx(game.world.floor_at(980.),0.),"Locked fork_two hatch holds upper yard floor before unlock")
				check(CampaignRoutes.clamp_horizontal(game.world,980.,CampaignRoutes.EXIT_X)<=CampaignRoutes.YARD_END_X,"Locked fork_two hatch blocks lower passage to exit")
				for _hit in 4:
					CampaignContent.hit_object(game.world,Vector2(CampaignRoutes.HATCH_LOCK_X,-35.),1)
				check(CampaignRoutes.hatch_open(game.world) and is_equal_approx(game.world.floor_at(980.),CampaignRoutes.LOWER_FLOOR),"Breaking fork_two root lock opens lower channel")
				game.world.player=Vector2(980.,game.world.floor_at(980.))
				game.world.velocity=Vector2.ZERO
			else:
				stage(junction,980.);game.world.player.y=CampaignRoutes.UPPER_FLOOR if upper else CampaignRoutes.LOWER_FLOOR
			game.view.camera_y=CampaignRoutes.camera_y(game.world,0.)
			check(game.world.grounded(),"Rendered junction actor has real collision support: "+junction)
			check(game.menu_kind=="" and game.buttons.is_empty(),"Physical junction renders no route menu or hidden confirm")
			await capture(junction+("-upper" if upper else "-lower"))
	stage("arena",1000.);game.world.boss.engaged=true;game.world.boss.windup=.7;await capture("boss")
	game.world.begin("sheep");stage("water",480.);game.world.mount.ridden=true;game.world.mount.x=480.;game.world.player.y=-42.;game.world.flock=3
	await capture("mounted-flock")
	game.world.begin("aion");stage("shore",400.)
	for viewport in [Vector2i(393,873),Vector2i(873,393)]:
		root.size=viewport;await process_frame;game.resize();stage("water",900.);await capture("mobile-%dx%d" % [viewport.x,viewport.y])
	root.size=Vector2i(1280,720);await process_frame;game.resize()
	var fixture_data:=[]
	for hero in AionCampaignWorld.HEROES:
		game.world.begin(hero);stage("shore",400.);game.world.enemies.clear();game.world.crates.clear();game.world.pickups.clear();game.world.npcs.clear();game.world.platforms.clear();game.world.gates.clear()
		game.world.objects.clear();game.world.hazards.clear();game.world.zones.clear()
		for clip in ["walk","idle_fire","air_fire","crouch_walk","crouch_fire","melee"]:
			var count:=6
			var sheet:=Image.create_empty(count*180,160,false,Image.FORMAT_RGBA8)
			for frame in count:
				var action: String=clip_pose(clip,frame)
				var image: Image=await capture("review-temp")
				var expected_anchor:=Vector2(400.,-110. if clip=="air_fire" else 0.)
				var anchor: Vector2=root.get_final_transform()*game.view.get_global_transform_with_canvas()*Vector2(game.world.player.x-game.view.camera_x,game.world.player.y+game.view.ground-game.view.camera_y)
				var area:=Rect2i(Vector2i(anchor)-Vector2i(90,140),Vector2i(180,160))
				check(Rect2i(Vector2i.ZERO,image.get_size()).encloses(area),"Complete cel capture fits the real viewport: "+hero+" "+clip)
				sheet.blit_rect(image,area,Vector2i(frame*180,0))
				# Actor-root guide is a diagnostic overlay, not game artwork.
				# Air roots deliberately do not mean contact with the ground.
				sheet.fill_rect(Rect2i(frame*180,140,180,1),Color("e87e9a"))
				fixture_data.append({"hero":hero,"clip":clip,"runtime_action":action,"frame":frame,"guide":"physics-root","physics_anchor":[game.world.player.x,game.world.player.y],"source":game.view.hero_marker.duplicate(true)})
				check(game.world.player.is_equal_approx(expected_anchor),"Art never changes the physics anchor: "+hero+" "+clip)
				# Each provider owns its source mapping, including authored held cels.
				# Compare the actual rendered source/row/cel, never relabel new heroes
				# as a legacy atlas or assume source index equals clip index.
				var expected_frame:=frame
				if hero=="armadillo" and clip=="air_fire":
					expected_frame=RunnerWorld.flight_frame_for(game.world.velocity.y,game.world.air_time,6)
				var expected: Dictionary=M1HeroArt.metrics(hero,action,expected_frame)
				check(str(game.view.hero_marker.source)==str(expected.source_key) and int(game.view.hero_marker.row)==int(expected.source_row) and int(game.view.hero_marker.frame)==int(expected.source_frame),"Actual renderer uses the matching registered M1 hero/action/cel: "+hero+" "+clip+" "+str(frame))
			check(sheet.save_png(output+"/"+hero+"-"+clip+"-cycle.png")==OK,"Six-cel native strip was written: "+hero+" "+clip)
		clip_pose("air_fire",2)
		await capture(hero+"-air-fire")
		if hero in ["rabbit","eren"]:
			game.world.player.y=0.;game.world.velocity=Vector2.ZERO;game.world.charging=true;game.world.charge_time=.9;await capture(hero+"-charge")
			game.world.charging=false;game.world.player.y=-310.;game.view.camera_y=-85.;await capture(hero+"-high-jump");game.view.camera_y=0.
	# Removed companions remain visible as actual helper powers, not fake
	# playable owl/wolf bodies inserted into the six-hero animation matrix.
	game.world.begin("aion");stage("shore",900.);CampaignAssists.summon(game.world,"owl_feather");CampaignAssists.summon(game.world,"wolf_charm")
	await capture("companion-powers")
	var report:=FileAccess.open(output+"/fixtures.json",FileAccess.WRITE);report.store_string(JSON.stringify(fixture_data,"  "));report.close()
	game.queue_free();await process_frame
	print("RESULT: %d campaign render checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
