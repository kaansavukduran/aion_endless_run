## Real-renderer visual fixtures with explicitly assigned model state.
extends SceneTree
func _initialize():call_deferred("run")
func run():
	var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame
	g.set_physics_process(false);g.touch_tutorial_done=true;g.language="tr"
	DirAccess.make_dir_recursive_absolute("res://build/story-review")
	for dims in [Vector2i(1280,720),Vector2i(393,873)]:
		root.size=dims;await process_frame;g.touch_mode=true;g.interface_options.text_scale=1.;g.build_theme();g.ui.theme=g.ui_theme
		for hero in g.FRIENDS:
			g.character=hero;g.start_run();g.set_physics_process(false);g.world.distance=28.;g.world.time=.1
			g.update_friend();g.update_weapon_visual();g.update_hud();g.queue_redraw();g.frontier_view.queue_redraw()
			await process_frame;await process_frame;await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://build/story-review/%s-ground-%d.png"%[hero,dims.x])
		g.character="aion";g.start_run();g.set_physics_process(false);g.world.frontier.request_boss(5);g.world.step(.01);g.rebuild()
		for kind in 3:
			g.world.frontier.boss_kind=kind
			for beat in 3:
				g.world.frontier.story_index=beat;g.world.frontier.story_time=1.8;g.update_friend();g.update_hud();g.frontier_view.queue_redraw();g.queue_redraw()
				await process_frame;await process_frame;await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://build/story-review/boss-%d-beat-%d-%d.png"%[kind,beat,dims.x])
	print("Captured30 real-rendered ground/story fixtures; explicit state assignment, not normal-input proof")
	g.queue_free();await process_frame;quit()
