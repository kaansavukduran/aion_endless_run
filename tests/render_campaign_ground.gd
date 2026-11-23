## Real renderer with an isolated shoreline setup. Source physics and actual
## mission-entry play are separate verification lanes.
extends SceneTree

func _initialize() -> void:call_deferred("run")

func run() -> void:
	var directory:=OS.get_environment("AION_GROUND_REVIEW")
	if directory.is_empty():directory="user://campaign-ground-review"
	DirAccess.make_dir_recursive_absolute(directory)
	root.size=Vector2i(1280,720)
	var game:=AionCampaignGame.new()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.audio_enabled=false
	game.options.reduced_motion=false
	game.menu_kind="";game.presentation_stage="";game.fade=-1.
	game.world.begin("aion");game.world.state="playing"
	game.world.enemies.clear();game.world.gates.clear()
	game.build_ui()
	for specimen in [["shore","lower-lane",3140.],["shore","raised-shelf",3570.],["water","channel-floor",5980.],["terrace","upper-terrace",8200.],["roots","root-trench",7810.]]:
		game.world.load_section(str(specimen[0]))
		game.world.enemies.clear();game.world.gates.clear()
		var x: float=specimen[2]
		game.world.player=Vector2(x,game.world.floor_at(x))
		game.world.velocity=Vector2.ZERO
		game.view.camera_x=x-420.
		game.view.camera_y=maxf(0.,game.world.player.y)*.95
		game.update_hud()
		game.view.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var destination:=directory.path_join(str(specimen[1])+".png")
		if root.get_texture().get_image().save_png(destination)!=OK:
			printerr("Failed to save "+destination);quit(1);return
		if not game.world.grounded() or absf(float(game.view.hero_marker.floor)-game.world.player.y)>.01:
			printerr("Rendered anchor failed its actual support at "+destination);quit(1);return
	print("RESULT: 5 campaign terrain render checks, 0 failures")
	game.queue_free()
	await process_frame
	quit()
