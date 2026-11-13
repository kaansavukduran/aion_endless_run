## Explicit deterministic damage-state visual fixtures, not normal-input proof.
## Requires a real renderer (e.g. DISPLAY=:101 godot --audio-driver Dummy
## --script tests/render_pixel_states.gd). Never included in game exports.
extends SceneTree
func _initialize():call_deferred("run")
func run():
	root.size=Vector2i(1152,648)
	var game=load("res://main.tscn").instantiate();root.add_child(game);await process_frame
	game.set_physics_process(false);game.touch_tutorial_done=true
	DirAccess.make_dir_recursive_absolute("res://build/pixel-states")
	for hero in game.FRIENDS:
		game.main_menu();game.select_character(hero);game.start_run();game.set_physics_process(false)
		for state in ["ice","fire"]:
			for phase in [0.0,0.35,0.7]:
				game.world.state=state;game.world.hit_time=phase;game.update_friend();game.update_hud();game.queue_redraw()
				await process_frame;await process_frame;await RenderingServer.frame_post_draw
				var file="res://build/pixel-states/%s-%s-%03d.png"%[hero,state,roundi(phase*100)]
				var error=root.get_texture().get_image().save_png(file)
				if error!=OK:printerr("Fixture capture failed: "+file);quit(1);return
	print("Captured36 real-rendered damage-state fixtures; world states were explicitly set for visual QA")
	game.queue_free();await process_frame;quit()
