extends SceneTree

const World = preload("res://scripts/world.gd")
var checks := 0
var failures := 0

func classic_world() -> RunnerWorld:
	var world = World.new()
	world.adventure.enabled = false
	return world

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
	event.position = game.global_transform * point
	event.pressed = pressed
	if pressed: game._unhandled_input(event)
	else: game._input(event)

func ability_tests() -> void:
	var owl := classic_world()
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
	var aion := classic_world()
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
	var wolf := classic_world()
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
	var sheep := classic_world()
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

func flock_and_wind_tests() -> void:
	var flock := classic_world()
	flock.character = "sheep"
	flock.reset()
	flock.sheep_count = 3
	flock.obstacle_wait = 999.0
	flock.jump()
	flock.step(1.0 / 120)
	check(flock.y < 0.0 and flock.flock_pose(0).y == 0.0 and flock.flock_pose(1).y == 0.0, "Only the leader takes off on the Space press")
	var takeoffs := [-1.0, -1.0]
	var crossing_heights := [0.0, 0.0, 0.0]
	for tick in 180:
		flock.step(1.0 / 120)
		for i in 2:
			if takeoffs[i] < 0.0 and float(flock.flock_pose(i).y) < -0.01: takeoffs[i] = flock.distance
		for i in 3:
			var target := 100.0 + World.FLOCK_GAP * i
			if absf(flock.distance - target) < flock.speed() / 120.0:
				crossing_heights[i] = flock.y if i == 0 else float(flock.flock_pose(i - 1).y)
	check(takeoffs[0] >= World.FLOCK_GAP and takeoffs[0] < World.FLOCK_GAP + 6.0, "Second sheep takes off at the leader's original world coordinate")
	check(takeoffs[1] >= World.FLOCK_GAP * 2 and takeoffs[1] < World.FLOCK_GAP * 2 + 6.0, "Third sheep follows after its own spatial gap")
	check(crossing_heights.all(func(height): return height < -90.0), "All three sheep clear an obstacle at the same world position")
	check(absf(crossing_heights[0] - crossing_heights[2]) < 6.0, "Follower paths preserve the leader's obstacle clearance height")
	flock.state = "paused"
	var old_pose := flock.flock_pose(0)
	var old_trail_size := flock.trail.size()
	flock.step(0.02)
	check(flock.flock_pose(0) == old_pose and flock.trail.size() == old_trail_size, "Pause freezes every delayed flock pose and its trail")
	flock.state = "running"
	for i in 500: flock.step(1.0 / 60)
	check(flock.trail.size() < 100, "Long runs retain only the short spatial history needed for followers")
	flock.reset()
	check(flock.trail.size() == 1 and flock.flock_pose(1).y == 0.0, "Retry clears the previous run's delayed jumps")
	for base_distance in [0.0, 150000.0]:
		flock.reset()
		flock.obstacle_wait = 999.0
		flock.distance = base_distance
		flock.trail[0].distance = base_distance
		flock.jump()
		while float(flock.flock_pose(0).y) >= 0.0: flock.step(1.0 / 240)
		check(absf(flock.distance - base_distance - World.FLOCK_GAP) < 5.0, "Spatial follower timing stays correct at speed " + str(flock.speed()))
	var owl := classic_world()
	owl.character = "owl"
	owl.reset()
	owl.obstacle_wait = 999.0
	owl.y = -90.0
	owl.velocity = 40.0
	owl.jumps_used = 1
	owl.jump_held = true
	owl.gust_wait = 999999.0 # This fixture tests one finite gust, without unrelated future gusts.
	owl.gusts = [{"x":World.PLAYER_X + 50.0, "width":400.0}]
	for i in 20: owl.step(1.0 / 120)
	check(owl.riding_gust and owl.gliding and owl.velocity < 0.0 and owl.y < -90.0, "An airborne gliding owl gains real upward height in an updraft")
	owl.jump()
	owl.step(1.0 / 120)
	check(owl.jumps_used == 1, "Catching wind never grants the owl another jump")
	var rising_velocity := owl.velocity
	owl.release_controls()
	owl.step(1.0 / 120)
	check(not owl.riding_gust and not owl.gliding and owl.velocity > rising_velocity, "Release exits lift immediately and restores normal gravity")
	owl.jump_held = true
	owl.gliding = true
	for i in 500: owl.step(1.0 / 120)
	check(owl.y == 0.0 and not owl.riding_gust and owl.jumps_used == 0, "A finite passing gust still lets the owl land and reset its jump")
	owl.reset()
	owl.obstacle_wait = 999.0
	owl.jump_held = true
	owl.gusts = [{"x":World.PLAYER_X, "width":50000.0}]
	owl.step(0.02)
	check(owl.y == 0.0 and not owl.riding_gust, "Ground wind cannot launch an owl without a jump")
	owl.y = -260.0
	owl.velocity = 0.0
	owl.jumps_used = 1
	for i in 180: owl.step(1.0 / 120)
	check(owl.y >= World.WIND_CEILING and owl.riding_gust, "Even a very wide wind respects the ceiling without toggling lift")
	var events_at_ceiling := owl.event_id
	for i in 60: owl.step(1.0 / 120)
	check(owl.event_id == events_at_ceiling, "A steady updraft emits one catch event instead of a burst every frame")
	owl.state = "paused"
	var gust_x: float = owl.gusts[0].x
	var wind_y: float = owl.y
	owl.step(0.02)
	check(owl.gusts[0].x == gust_x and owl.y == wind_y, "Pause freezes both the passing wind and lifted owl")
	for id in ["aion", "wolf", "sheep"]:
		owl.reset()
		owl.character = id
		owl.y = -90.0
		owl.velocity = 50.0
		owl.jump_held = true
		owl.gusts = [{"x":World.PLAYER_X, "width":300.0}]
		owl.step(0.02)
		check(not owl.riding_gust and owl.velocity > 50.0, "Updraft lift is exclusive to owl: " + id)

func run() -> void:
	ability_tests()
	flock_and_wind_tests()
	var world := classic_world()
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
	game.world.adventure.enabled = false
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
	check(game.page == "paused", "Character selection is blocked inside pause")
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
	game.open_subpage("settings")
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
	second.world.adventure.enabled = false
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
	second.main_menu()
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
	second.main_menu()
	second.select_character("owl")
	second.start_run()
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
		second.main_menu()
		second.select_character(id)
		second.start_run()
		second.world.state = "running"
		second.world.y = 0.0
		second.world.time = 0.0
		second.world.distance = 0.0
		second.update_friend()
		var region: Rect2 = second.friend_sprite.region_rect
		second.world.time = 0.15
		second.world.distance = 45.0
		second.update_friend()
		check(second.friend_row == second.COMPANION_RUN_ROWS[id] and second.friend_sprite.region_rect != region, "Right-facing run atlas advances actual frames: " + id)
		for state in ["ice", "fire"]:
			second.world.state = state
			second.world.hit_time = 0.4
			second.update_friend()
			check(second.friend_row == (3 if state == "ice" else 4) and second.friend_sprite.visible, "Species-specific collision animation remains visible: " + id + "/" + state)
		second.world.state = "fire"
		second.world.hit_time = 1.2
		second.update_friend()
		check(second.friend_row == 5 and second.friend_sprite.visible and second.friend_sprite.texture == second.RUNNER_SHEETS[id], "Ash preserves the actual species artwork: " + id)
	second.main_menu()
	second.select_character("owl")
	second.world.state = "running"
	second.world.y = -80.0
	second.world.gliding = true
	second.update_friend()
	check(second.friend_row == 6, "Owl glide uses its dedicated extended-wing artwork")
	second.main_menu()
	second.select_character("wolf")
	second.start_run()
	second.world.y = 0.0
	second.world.boost_held = true
	second.update_friend()
	check(second.friend_row == 6, "Wolf boost uses a different forward-leaning dash cycle")
	second.pause_run()
	var paused_region: Rect2 = second.friend_sprite.region_rect
	second.world.time += 1.0
	second.update_friend()
	check(second.friend_sprite.region_rect == paused_region, "Pausing preserves the exact animation pose")
	second.world.state = "running"
	second.main_menu()
	second.select_character("sheep")
	second.start_run()
	second.world.sheep_count = 3
	second.update_friend()
	check(second.followers[0].visible and second.followers[1].visible, "Three lives render as three running sheep")
	second.world.reset()
	second.world.character = "sheep"
	second.world.sheep_count = 3
	second.world.jump()
	second.world.step(0.02)
	second.update_friend()
	check(second.friend_sprite.position.y < second.followers[0].position.y and second.followers[0].position.y == second.followers[1].position.y, "Real follower sprites stay grounded while the leading sheep takes off")
	check(second.friend_sprite.texture == second.ACTION_SHEET and second.followers[0].texture == second.RUNNER_SHEETS.sheep, "Sheep jump uses new squash/flight frames while its follower still runs")
	second.main_menu()
	second.select_character("wolf")
	second.start_run()
	second.world.time = 0.5
	var ribbon_a: Array = second.wolf_wind_ribbons()
	second.world.time = 0.6
	var ribbon_b: Array = second.wolf_wind_ribbons()
	check(ribbon_a[0].points != ribbon_b[0].points and ribbon_a[0].alpha != ribbon_b[0].alpha, "Wolf wind physically flows and fades instead of staying as three fixed lines")
	second.motion = false
	check(second.wolf_wind_ribbons().is_empty(), "Reduced motion removes decorative wind ribbons without disabling abilities")
	game.queue_free()
	second.queue_free()
	await process_frame
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
