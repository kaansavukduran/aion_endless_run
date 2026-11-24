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
	for viewport in [Vector2i(1152,648),Vector2i(393,873)]:
		root.size=viewport;await process_frame;game.resize()
		for section in CampaignRoutes.FORKS:
			for upper in [false,true]:
				game.world.load_section(section);game.menu_kind="";game.presentation_stage=""
				game.world.player=Vector2(980.,CampaignRoutes.UPPER_FLOOR if upper else CampaignRoutes.LOWER_FLOOR);game.world.velocity=Vector2.ZERO
				game.view.camera_x=clampf(game.world.player.x-game.view.scene_w*.34,0.,maxf(0.,game.world.length()-game.view.scene_w))
				game.view.camera_y=CampaignRoutes.camera_y(game.world,0.);game.build_ui();game.view.queue_redraw();game.update_hud()
				await process_frame;await process_frame;await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(directory+"/"+section+"-"+("upper" if upper else "lower")+"-"+str(viewport.x)+"x"+str(viewport.y)+".png");count+=1
	game.queue_free();await process_frame;print("RESULT: ",count," route render fixtures, 0 failures");quit()
