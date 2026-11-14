## Authored review states only; ordinary-input browser checks are recorded separately.
extends SceneTree
var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1280, 720)
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.touch_tutorial_done = true
	game.language = "tr"
	game.interface_options.text_scale = 1.0
	game.build_theme()
	game.ui.theme = game.ui_theme
	game.main_menu()
	game.start_run()
	game.set_physics_process(false)
	game.world.obstacles.clear()
	game.world.pickups.clear()
	game.world.adventure.enemies.clear()
	game.world.adventure.items.clear()
	var output = OS.get_environment("AION_TERRAIN_REVIEW")
	if output.is_empty(): output = "res://build/terrain-review"
	DirAccess.make_dir_recursive_absolute(output)
	for biome in 6:
		game.world.distance = (biome + 0.35) * game.World.BIOME_DISTANCE
		game.world.time = 32.0
		game.update_friend()
		game.update_hud()
		game.queue_redraw()
		for layer in game.find_children("*", "Node2D", true, false): layer.queue_redraw()
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var image: Image = root.get_texture().get_image()
		image.save_png(output + "/biome-%d.png" % biome)
		var night: float = (cos(game.world.time * TAU / 72.) + 1.) / 2.
		var expected: Color = game.terrain.palette(biome)[0] * Color.WHITE.lerp(Color("7e86a4"), night * .32)
		for x in [16., 128., 410., 520., 640., 850.]:
			var point: Vector2 = root.get_final_transform() * game.get_global_transform_with_canvas() * Vector2(x, game.ground + 1.)
			var actual: Color = image.get_pixelv(Vector2i(point.floor()))
			check(absf(actual.r - expected.r) < .015 and absf(actual.g - expected.g) < .015 and absf(actual.b - expected.b) < .015, "Rendered walking rim remains continuous in biome " + str(biome))
	# The real pit overlay must cut through the new surface, with collision unchanged.
	game.world.obstacles.assign([{"x":580., "width":150., "kind":"pit", "counted":false}])
	for layer in game.find_children("*", "Node2D", true, false): layer.queue_redraw()
	game.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var pit_image: Image = root.get_texture().get_image()
	pit_image.save_png(output + "/pit.png")
	var pit_point: Vector2 = root.get_final_transform() * game.get_global_transform_with_canvas() * Vector2(580., game.ground + 4.)
	var pit_color: Color = pit_image.get_pixelv(Vector2i(pit_point.floor()))
	check(pit_color.r < .09 and pit_color.g < .14 and pit_color.b < .18, "The actual pit opening is not painted over by the new terrain")
	game.world.obstacles.clear()
	game.world.distance = 3.04 * game.World.BIOME_DISTANCE
	game.queue_redraw()
	for layer in game.find_children("*", "Node2D", true, false): layer.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var transition: Image = root.get_texture().get_image()
	transition.save_png(output + "/biome-transition.png")
	var transition_point: Vector2 = root.get_final_transform() * game.get_global_transform_with_canvas() * Vector2(128., game.ground + 1.)
	var transition_color: Color = transition.get_pixelv(Vector2i(transition_point.floor()))
	var target: Color = game.terrain.palette(2)[0].lerp(game.terrain.palette(3)[0], .5) * Color.WHITE.lerp(Color("7e86a4"), (cos(32. * TAU / 72.) + 1.) / 2. * .32)
	check(absf(transition_color.r-target.r)<.015 and absf(transition_color.g-target.g)<.015 and absf(transition_color.b-target.b)<.015, "Mid-biome ground blends once, matching the background transition")
	for dimensions in [Vector2i(393, 873), Vector2i(873, 393)]:
		root.size = dimensions
		await process_frame
		await process_frame
		game.touch_mode = true
		game.rebuild()
		game.update_friend()
		game.update_hud()
		game.queue_redraw()
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var rotated: Image = root.get_texture().get_image()
		rotated.save_png(output + "/mobile-%dx%d.png" % [dimensions.x, dimensions.y])
		var sample_point: Vector2 = root.get_final_transform() * game.get_global_transform_with_canvas() * Vector2(game.World.PLAYER_X + 80., game.ground + 1.)
		var sample_color: Color = rotated.get_pixelv(Vector2i(sample_point.floor()))
		check(absf(sample_color.r-target.r)<.015 and absf(sample_color.g-target.g)<.015 and absf(sample_color.b-target.b)<.015, "The drawn rim still matches the physical floor after mobile rotation")
	game.queue_free()
	await process_frame
	print("RESULT: %d rendered terrain checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
