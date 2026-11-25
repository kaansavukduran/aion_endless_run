extends SceneTree
var game: AionCampaignGame
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var directory:=OS.get_environment("AION_ROUTE_REVIEW")
	if directory.is_empty():directory="res://build/route-review"
	DirAccess.make_dir_recursive_absolute(directory)
	game=AionCampaignGame.new();game.language="tr";root.add_child(game);await process_frame;game.set_process(false)
	game.audio_enabled=false;game.touch_mode=true;game.options.text_scale=1.;game.presentation_stage="";game.menu_kind=""
	var count:=0
	var fixtures: Array=[
		["fork_one","upper",Vector2(980.,CampaignRoutes.UPPER_FLOOR)],
		["fork_one","lower",Vector2(980.,CampaignRoutes.LOWER_FLOOR)],
		["fork_one","middle",Vector2(1470.,CampaignRoutes.MIDDLE_FLOOR)],
		["fork_one","drained",Vector2(1450.,CampaignRoutes.DRY_FLOOR)],
		["fork_two","upper",Vector2(980.,CampaignRoutes.UPPER_FLOOR)],
		["fork_two","lower",Vector2(980.,CampaignRoutes.LOWER_FLOOR)],
		["causeway","stone-basin",Vector2(945.,70.)],
		["shore","crow-shelter",Vector2(3030.,54.)]
	]
	for viewport in [Vector2i(1152,648),Vector2i(393,873)]:
		root.size=viewport;await process_frame;game.resize()
		for fixture in fixtures:
			var section: String=fixture[0]
			var variant: String=fixture[1]
			game.world.activated.erase(CampaignRoutes.PUMP_ID)
			game.world.activated.erase(CampaignRoutes.HATCH_ID)
			if variant=="drained":game.world.activated[CampaignRoutes.PUMP_ID]=true
			if section=="fork_two" and variant=="lower":game.world.activated[CampaignRoutes.HATCH_ID]=true
			game.world.load_section(section);game.menu_kind="";game.presentation_stage=""
			game.world.player=Vector2(fixture[2]);game.world.velocity=Vector2.ZERO
			if not CampaignRoutes.is_fork(section):game.world.player.y=game.world.floor_at(game.world.player.x)
			game.view.camera_x=clampf(game.world.player.x-game.view.scene_w*.34,0.,maxf(0.,game.world.length()-game.view.scene_w))
			game.view.camera_y=CampaignRoutes.camera_y(game.world,maxf(0.,game.world.player.y) if not CampaignRoutes.is_fork(section) else 0.)
			game.build_ui();game.view.queue_redraw();game.update_hud()
			await process_frame;await process_frame;await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(directory+"/"+section+"-"+variant+"-"+str(viewport.x)+"x"+str(viewport.y)+".png");count+=1
	game.queue_free();await process_frame;print("RESULT: ",count," route render fixtures, 0 failures");quit()
