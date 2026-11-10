extends SceneTree

const World = preload("res://scripts/world.gd")
var checks := 0
var failures := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func key(game: Node, code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	game._input(event)
	event = event.duplicate()
	event.pressed = false
	game._input(event)

func hold_key(game: Node, code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = pressed
	game._input(event)

func touch(game: Node, index: int, point: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = point
	event.pressed = pressed
	if pressed: game._unhandled_input(event)
	else: game._input(event)

func ability_tests() -> void:
	var owl := World.new()
	owl.character = "owl"
	owl.reset()
	owl.obstacle_wait = 999.0
	owl.jump_held = true
	owl.jump()
	for i in 40: owl.step(1.0 / 60)
	check(owl.gliding and owl.velocity <= World.GLIDE_FALL_SPEED, "Holding after an owl jump engages a bounded glide")
	var v: float = owl.velocity
	owl.jump()
	owl.step(1.0 / 60)
	check(owl.jumps_used == 1 and owl.velocity >= v, "Owl has one jump and cannot gain height by pressing again")
	owl.jump_held = false
	owl.step(1.0 / 60)
	check(not owl.gliding and owl.velocity > World.GLIDE_FALL_SPEED, "Release immediately restores normal falling gravity")
	var flights := []
	for held in [false, true]:
		owl.reset()
		owl.obstacle_wait = 999.0
		owl.jump_held = held
		owl.jump()
		var duration := 0.0
		for i in 600:
			owl.step(1.0 / 120)
			duration += 1.0 / 120
			if owl.y == 0.0: break
		flights.append(duration)
		check(owl.y == 0.0 and owl.jumps_used == 0 and not owl.gliding, "Owl eventually lands and restores one jump")
	check(flights[1] > flights[0] + 0.7, "Glide creates measurably longer airtime without infinite flight")
	var aion := World.new()
	aion.reset()
	aion.obstacle_wait = 999.0
	aion.jump()
	aion.step(0.02)
	aion.jump()
	for i in 180:
		aion.step(1.0 / 120)
		if aion.y == 0.0: break
	check(aion.jumps_used == 0, "Landing replenishes Aion's two jumps")
	aion.jump()
	aion.step(0.02)
	aion.jump()
	check(aion.jumps_used == 2, "Aion can double jump again after landing")
	var wolf := World.new()
	wolf.character = "wolf"
	wolf.reset()
	var normal_speed: float = wolf.speed()
	wolf.boost_held = true
	check(is_equal_approx(wolf.speed(), normal_speed * World.BOOST_MULTIPLIER), "Wolf hold boosts real world speed")
	wolf.step(0.02)
	check(wolf.distance > normal_speed * 0.02, "Boost increases actual distance travelled, not just leg animation")
	wolf.release_controls()
	check(not wolf.boosting() and wolf.speed() < normal_speed * 1.01, "Wolf release returns to normal speed")
	for id in ["owl", "sheep", "aion"]:
		wolf.character = id
		wolf.boost_held = true
		check(not wolf.boosting(), "Boost is specific to wolf: " + id)
	var sheep := World.new()
	sheep.character = "sheep"
	sheep.reset()
	sheep.obstacle_wait = 999.0
	sheep.sheep_wait = 1.0
	sheep.step(0.02)
	check(sheep.sheep_pickups.size() == 1 and sheep.sheep_count == 1, "Interval spawns a collectible sheep instead of granting a free life")
	sheep.sheep_pickups[0].x = World.PLAYER_X
	sheep.step(0.02)
	check(sheep.sheep_count == 2 and sheep.sheep_pickups.is_empty(), "Ground contact recruits a second sheep exactly once")
	sheep.sheep_pickups = [{"x": World.PLAYER_X}]
	sheep.step(0.02)
	check(sheep.sheep_count == 3, "A third sheep joins the flock")
	sheep.sheep_pickups = [{"x": World.PLAYER_X}]
	sheep.step(0.02)
	check(sheep.sheep_count == 3, "A flock can never exceed three sheep")
	sheep.y = -120.0
	sheep.sheep_count = 1
	sheep.sheep_pickups = [{"x": World.PLAYER_X}]
	sheep.step(0.02)
	check(sheep.sheep_count == 1, "A sheep must actually touch the collectible to recruit it")
	for kind in ["fire", "ice"]:
		sheep.reset()
		sheep.sheep_count = 3
		for remaining in [2, 1]:
			sheep.invulnerable = 0.0
			sheep.obstacles = [{"x": World.PLAYER_X, "kind": kind, "counted": false}]
			sheep.step(0.02)
			check(sheep.state == "running" and sheep.sheep_count == remaining, "Each extra sheep absorbs one " + kind + " collision")
			sheep.step(0.02)
			check(sheep.sheep_count == remaining and sheep.passed == 0, "Same contact cannot remove another life or earn clear points")
		sheep.invulnerable = 0.0
		sheep.obstacles = [{"x": World.PLAYER_X, "kind": kind, "counted": false}]
		sheep.step(0.02)
		check(sheep.state == kind and sheep.sheep_count == 1, "Final sheep ends the run with the correct " + kind + " reaction")
	sheep.reset()
	check(sheep.sheep_count == 1 and sheep.sheep_pickups.is_empty() and sheep.invulnerable == 0.0, "A new run resets the flock and protection")

func run() -> void:
	ability_tests()
	var world := World.new()
	world.rng.seed = 44
	world.reset()
	world.jump()
	world.step(1.0 / 60)
	check(world.y < 0.0 and world.velocity < 0.0, "Space makes grounded character jump")
	var vy: float = world.velocity
	world.jump()
	check(world.jumps_used == 2 and world.velocity < vy, "Aion can jump a second time in mid-air")
	world.step(1.0 / 60)
	vy = world.velocity
	world.jump()
	world.step(1.0 / 60)
	check(world.jumps_used == 2 and world.velocity > vy, "Aion cannot jump a third time before landing")
	world.state = "paused"
	var distance: float = world.distance
	var y: float = world.y
	world.step(1.0 / 60)
	check(world.distance == distance and world.y == y, "Pause freezes physics and distance")
	for kind in ["ice", "fire"]:
		world.reset()
		world.obstacles = [{"x": World.PLAYER_X, "kind": kind, "counted": false}]
		world.step(1.0 / 60)
		check(world.state == kind, "Correct collision state: " + kind)
		world.step(1.0 / 60)
		check(world.hit_time > 0.0, "Collision animation advances")
	world.reset()
	world.y = -110
	world.pickups = [{"x": World.PLAYER_X, "y": -113.0, "taken": false}]
	world.step(1.0 / 60)
	check(world.gems == 1 and world.score >= 25, "Real crystal pickup awards +25")
	for i in 3: world.step(1.0 / 60)
	check(world.gems == 1, "Crystal cannot award twice")
	world.reset()
	world.y = -90
	world.obstacles = [{"x": World.PLAYER_X - 40.0, "kind": "fire", "counted": false}]
	world.step(1.0 / 60)
	check(world.passed == 1 and world.score >= 10, "Obstacle clear awards +10")
	for i in 3: world.step(1.0 / 60)
	check(world.passed == 1, "Obstacle cannot award twice")
	# Long deterministic run through both biomes with actual generated obstacles.
	world.reset()
	var visited := {0: true}
	for i in 16000:
		if world.y == 0.0:
			for obstacle in world.obstacles:
				if obstacle.x > World.PLAYER_X and obstacle.x - World.PLAYER_X < world.speed() * 0.29:
					world.jump()
		world.step(1.0 / 120)
		visited[world.biome()] = true
		if world.state != "running": break
	check(world.state == "running", "Generated obstacles remain jumpable through a long run")
	check(visited.size() == 2 and world.distance > 13000, "Both biomes transition during real progress")
	check(world.passed > 30 and world.gems > 15, "Long run records real obstacles and pickups")
	world.reset()
	check(world.score == 0 and world.gems == 0 and world.obstacles.is_empty(), "Retry resets run counters")
	# Actual main scene and its keyboard, menus, settings, four characters and disk save.
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	check(game.page == "main", "Normal entry opens main menu")
	key(game, KEY_SPACE)
	check(game.world.state == "running" and game.page == "", "Space starts at real entry")
	key(game, KEY_SPACE)
	game.world.step(1.0 / 60)
	check(game.world.y < 0, "Space jumps through input handler")
	key(game, KEY_ESCAPE)
	check(game.world.state == "paused" and game.page == "paused", "Esc opens pause menu")
	var previous_y: float = game.world.y
	game.open_subpage("characters")
	check(game.page == "characters", "Character selection opens inside pause")
	for id in game.FRIENDS:
		game.character = id
		game.update_friend()
		check(game.character == id, "Character selectable: " + id)
		for kind in ["ice", "fire"]:
			game.world.state = kind
			game.world.hit_time = 1.1
			game.update_friend()
			check(game.world.state == kind, "Character supports " + kind + ": " + id)
	game.world.state = "paused"
	game.character = "owl"
	key(game, KEY_ESCAPE)
	check(game.page == "paused", "Back returns to pause")
	key(game, KEY_ESCAPE)
	check(game.world.state == "running" and game.world.y == previous_y, "Resume preserves open run")
	game.pause_run()
	game.open_subpage("settings")
	game.set_language("en")
	check(game.page == "settings" and game.text("pause") == "Pause", "Language changes without leaving screen")
	game.motion = false
	game.audio_enabled = false
	game.volume = 0.35
	game.best = 4321
	game.save_settings()
	check(not game.save_failed, "Atomic local save succeeds")
	var second = load("res://main.tscn").instantiate()
	root.add_child(second)
	await process_frame
	second.set_physics_process(false)
	check(second.best == 4321 and second.character == "owl", "Best and character survive new instance")
	check(second.language == "en" and not second.motion and not second.audio_enabled and is_equal_approx(second.volume, 0.35), "Settings persist independently")
	second.start_run()
	key(second, KEY_SPACE)
	second.world.step(1.0 / 60)
	check(second.world.y < 0.0, "Gameplay works with sound and animation disabled")
	second.main_menu()
	check(second.world.state == "ready" and second.world.y == 0.0 and second.world.score == 0 and second.world.obstacles.is_empty(), "Main menu resets airborne pose and previous hazards while preserving the best")
	second.select_character("wolf")
	second.start_run()
	touch(second, 0, Vector2(World.PLAYER_X, second.ground - 35), true)
	check(second.world.boosting(), "Mobile hold on the wolf activates boost")
	touch(second, 1, Vector2(World.PLAYER_X + 230, second.ground - 35), true)
	second.world.step(0.02)
	check(second.world.y < 0.0 and second.world.boosting(), "A second mobile finger can jump while the first holds boost")
	touch(second, 0, Vector2(800, 200), false)
	check(not second.world.boosting() and second.world.jump_held, "Lifting boost finger away from the character preserves the other finger")
	touch(second, 1, Vector2(900, 200), false)
	check(not second.world.jump_held, "Touch release clears held jump even outside its original area")
	hold_key(second, KEY_SHIFT, true)
	check(second.world.boosting(), "Shift activates wolf boost")
	second.pause_run()
	check(not second.world.boost_held and not second.world.jump_held, "Pause clears held controls")
	second.resume_run()
	check(not second.world.boosting(), "Resume cannot latch an old boost press")
	second.select_character("owl")
	second.world.y = -100.0
	second.world.velocity = 110.0
	second.world.jumps_used = 1
	hold_key(second, KEY_SPACE, true)
	second.world.step(0.02)
	check(second.world.gliding and second.world.jumps_used == 1, "Keyboard hold engages owl glide without a second jump")
	hold_key(second, KEY_SPACE, false)
	second.world.step(0.02)
	check(not second.world.gliding, "Keyboard release ends owl glide")
	second.motion = true
	for id in ["wolf", "sheep", "owl"]:
		second.select_character(id)
		second.world.state = "running"
		second.world.y = 0.0
		second.world.time = 0.0
		second.update_friend()
		var region: Rect2 = second.friend_sprite.region_rect
		second.world.time = 0.15
		second.update_friend()
		check(second.friend_row == second.COMPANION_RUN_ROWS[id] and second.friend_sprite.region_rect != region, "Right-facing run atlas advances actual frames: " + id)
	second.select_character("sheep")
	second.world.sheep_count = 3
	second.update_friend()
	check(second.followers[0].visible and second.followers[1].visible, "Three lives render as three running sheep")
	game.queue_free()
	second.queue_free()
	await process_frame
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
