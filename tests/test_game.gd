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

func run() -> void:
	var world := World.new()
	world.rng.seed = 44
	world.reset()
	world.jump()
	world.step(1.0 / 60)
	check(world.y < 0.0 and world.velocity < 0.0, "Space makes grounded character jump")
	var vy: float = world.velocity
	world.jump()
	world.step(1.0 / 60)
	check(world.velocity > vy, "No double jump")
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
	game.queue_free()
	second.queue_free()
	await process_frame
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
