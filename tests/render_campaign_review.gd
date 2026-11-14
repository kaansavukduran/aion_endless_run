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
	var image: Image=root.get_texture().get_image();image.save_png(output+"/"+name+".png");return image
func stage(id: String,x: float=600.) -> void:
	game.world.load_section(id);game.world.player=Vector2(x,0);game.world.velocity=Vector2.ZERO;game.menu_kind="";game.build_ui()
	game.view.camera_x=clampf(x-game.view.scene_w*.34,0.,maxf(0.,game.world.length()-game.view.scene_w))
func run() -> void:
	output=OS.get_environment("AION_CAMPAIGN_REVIEW")
	if output.is_empty():output="res://build/campaign-review"
	DirAccess.make_dir_recursive_absolute(output)
	root.size=Vector2i(1280,720)
	game=AionCampaignGame.new();game.language="tr";root.add_child(game);await process_frame;game.set_process(false)
	game.options.text_scale=1.;game.options.font_mode="system";game.options.theme_mode="dark";game.options.resolve_theme();game.ui.theme=game.options.theme(game.FONT)
	game.touch_mode=true;game.resize();game.world.state="playing";game.menu_kind="";game.build_ui()
	for id in ["shore","canopy","water","terrace","roots","relay"]:
		stage(id,900.);await capture(id)
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
		var row: int=game.view.frames.hero_row(hero)
		for clip in ["run","melee"]:
			var count: int=6 if clip=="melee" else game.view.frames.count("gun-run",row)
			var sheet:=Image.create_empty(count*180,160,false,Image.FORMAT_RGBA8)
			for frame in count:
				game.world.velocity=Vector2(235.,0.);game.world.walk_distance=(float(frame)+.1)/count*180.
				game.world.melee_time=.28*(1.-(float(frame)+.1)/6.) if clip=="melee" else 0.
				var image: Image=await capture("review-temp")
				var anchor: Vector2=root.get_final_transform()*game.view.get_global_transform_with_canvas()*Vector2(400.,game.view.ground)
				var area:=Rect2i(Vector2i(anchor)-Vector2i(90,140),Vector2i(180,160))
				sheet.blit_rect(image,area,Vector2i(frame*180,0))
				# Explicit ground guide in the review sheet, not in game artwork.
				sheet.fill_rect(Rect2i(frame*180,140,180,1),Color("e87e9a"))
				fixture_data.append({"hero":hero,"clip":clip,"frame":frame,"physics_anchor":[game.world.player.x,game.world.player.y],"source":game.view.hero_marker})
				check(game.world.player.is_equal_approx(Vector2(400,0)),"Art never changes the physics anchor: "+hero+" "+clip)
				if clip=="run":check(game.view.hero_marker.source=="pixel-"+hero,"Actual rendered source matches hero identity: "+hero)
			sheet.save_png(output+"/"+hero+"-"+clip+"-cycle.png")
		game.world.melee_time=0.;game.world.player.y=-110.;game.world.air_time=.3;game.world.velocity=Vector2(0,-150.);game.world.shot_flash=.12
		await capture(hero+"-air-fire")
		if hero in ["rabbit","eren"]:
			game.world.player.y=0.;game.world.velocity=Vector2.ZERO;game.world.charging=true;game.world.charge_time=.9;await capture(hero+"-charge")
			game.world.charging=false;game.world.player.y=-310.;game.view.camera_y=-85.;await capture(hero+"-high-jump");game.view.camera_y=0.
		if hero=="owl":
			game.world.gliding=true;await capture("owl-glide");game.world.flap_time=.2;await capture("owl-flap")
		if hero=="wolf":
			game.world.player.y=0.;game.world.boost_held=true;game.world.velocity=Vector2(365,0);await capture("wolf-sprint")
	DirAccess.remove_absolute(output+"/review-temp.png")
	var report:=FileAccess.open(output+"/fixtures.json",FileAccess.WRITE);report.store_string(JSON.stringify(fixture_data,"  "));report.close()
	game.queue_free();await process_frame
	print("RESULT: %d campaign render checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
