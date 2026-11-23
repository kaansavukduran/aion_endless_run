## Isolated real OpenGL frames for ranged silhouettes and event-owned cues.
extends SceneTree

func _initialize() -> void:call_deferred("run")

func run() -> void:
	var directory:=OS.get_environment("AION_SHOOTER_REVIEW")
	if directory.is_empty():directory="user://campaign-shooter-review"
	DirAccess.make_dir_recursive_absolute(directory)
	root.size=Vector2i(1280,720)
	var game:=AionCampaignGame.new()
	root.add_child(game)
	await process_frame
	game.set_process(false);game.audio_enabled=false
	game.menu_kind="";game.presentation_stage="";game.fade=-1.
	game.world.begin("aion");game.world.state="playing"
	game.world.enemies.clear();game.world.gates.clear();game.world.objects.clear()
	game.world.player=Vector2(1300.,0.)
	game.world.spawn_enemy("lantern_scout",1640.,0.,89)
	game.world.spawn_enemy("cap_lobber",1720.,0.,90)
	for e in game.world.enemies:e.wait=0.
	game.view.camera_x=960.
	game.world.recovery_view=Rect2(960.,-430.,1152.,650.)
	game.build_ui()
	for sample in [["warning",.65],["release",.82],["recover",.28],["defeat",0.]]:
		for tick in roundi(float(sample[1])*120.):game.world.step_enemies(1./120.)
		if sample[0]=="defeat":
			for e in game.world.enemies:
				game.world.damage_enemy(e,1)
				e.dead_age=.32
		game.view.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		if root.get_texture().get_image().save_png(directory.path_join(str(sample[0])+".png"))!=OK:
			printerr("Could not save the shooter review");quit(1);return
	print("RESULT: 4 ranged shooter render checks, 0 failures")
	game.queue_free();await process_frame;quit()
