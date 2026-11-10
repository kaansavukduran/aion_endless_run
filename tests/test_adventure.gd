extends SceneTree
const World = preload("res://scripts/world.gd")
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)
func _initialize() -> void: call_deferred("run")
func arena() -> RunnerWorld:
	var w := World.new()
	w.reset()
	w.obstacle_wait = 999.0
	w.adventure.item_wait = 999.0
	w.adventure.first_item = false
	w.adventure.weather_wait = 999.0
	w.adventure.tempo_wait = 999.0
	w.adventure.gnome_wait = 999.0
	return w
func advance(w: RunnerWorld, seconds: float) -> void:
	for i in int(seconds * 120): w.step(1.0 / 120)
func run() -> void:
	for id in ["aion", "owl", "sheep", "wolf"]:
		var w := arena()
		w.character = id
		var crow: Dictionary = w.adventure.spawn_enemy(w, "crow", World.PLAYER_X + 110, -70)
		check(w.adventure.attack(w), "Attack begins for " + id)
		check(not w.adventure.attack(w), "Attack cooldown rejects immediate spam for " + id)
		advance(w, 0.06)
		check(crow.hp == 1, "Windup cannot damage before contact frames: " + id)
		advance(w, 0.12)
		check(crow.hp == 0 and w.adventure.kills == 1 and w.state == "running", "Actual attack contact defeats a crow without side damage: " + id)
		var bonus: int = w.adventure.bonus_score
		advance(w, 0.4)
		check(w.adventure.kills == 1 and w.adventure.bonus_score == bonus, "A defeated enemy cannot award twice: " + id)
	var w := arena()
	var gnome: Dictionary = w.adventure.spawn_enemy(w, "gnome", World.PLAYER_X + 95)
	w.adventure.attack_held = true
	advance(w, 0.24)
	check(gnome.hp == 1 and gnome.x > World.PLAYER_X + 60 and w.state == "running", "A nonlethal hit knocks a two-HP gnome back instead of immediately hurting the player")
	advance(w, 1.0)
	check(gnome.hp <= 0 and w.adventure.kills == 1, "Held attacks can finish a recovering two-HP gnome")
	w = arena()
	w.adventure.spawn_enemy(w, "gnome", World.PLAYER_X, -23)
	w.y = -52.0
	w.velocity = 350.0
	w.jumps_used = 1
	advance(w, 0.04)
	check(w.adventure.stomps == 1 and w.adventure.kills == 1 and w.velocity < 0.0, "Descending onto a gnome defeats it and creates a real upward bounce")
	w = arena()
	w.adventure.spawn_enemy(w, "crow", World.PLAYER_X, -70)
	w.y = -92.0
	w.velocity = 250.0
	advance(w, 0.10)
	check(w.adventure.stomps == 1 and w.velocity < 0.0, "Flying crows can also be stomped from above")
	w = arena()
	w.adventure.spawn_enemy(w, "gnome", World.PLAYER_X, -23)
	w.y = -30.0
	w.velocity = -250.0
	w.step(1.0 / 120)
	check(w.adventure.stomps == 0, "Ascending or side contact cannot count as a stomp")
	for crouched in [false, true]:
		w = arena()
		w.adventure.duck_held = crouched
		w.obstacles = [{"x":World.PLAYER_X,"kind":"arch","counted":false}]
		w.step(1.0 / 120)
		check((w.state == "running") == crouched, "Only a short ducked body fits beneath a low branch: " + str(crouched))
	w = arena()
	w.adventure.duck_held = true
	w.jump()
	w.step(1.0 / 120)
	check(w.y < 0 and not w.adventure.ducking(w), "Jumping from a crouch uses the full airborne body")
	w = arena()
	w.adventure.duck_held = true
	w.adventure.spawn_enemy(w, "crow", World.PLAYER_X, -70)
	w.step(1.0 / 120)
	check(w.state == "running", "A low crow passes safely over a ducking player")
	w = arena()
	var speed_before := w.speed()
	w.adventure.collect(w, "slow")
	check(w.speed() < speed_before * 0.7, "Time sand changes real world travel speed")
	w.adventure.collect(w, "haste")
	check(w.speed() > speed_before * 1.2 and w.adventure.powers.slow == 0.0, "Haste changes real speed and replaces a conflicting slow buff")
	advance(w, 8.2)
	check(is_equal_approx(w.speed(), minf(580,320+w.distance/450)), "Expired speed buffs return to the base curve")
	w = arena()
	w.character = "wolf"
	w.distance = 200000
	w.boost_held = true
	w.adventure.collect(w, "haste")
	w.adventure.tempo = 1.16
	check(w.speed() <= 760.0, "Combined boosts respect the encounter safety speed cap")
	w = arena()
	w.adventure.collect(w, "shield")
	w.take_hit("bonk")
	check(w.state == "running" and w.adventure.powers.shield == 0.0 and w.invulnerable > 0, "Shield absorbs one real hit and then expires")
	w.invulnerable = 0
	w.take_hit("bonk")
	check(w.state == "bonk", "A used shield cannot silently protect a second hit")
	w = arena()
	w.adventure.collect(w, "mushroom")
	check(w.adventure.giant() and w.adventure.size_multiplier() > 1.5, "Mushroom grants real enlarged collision and combat size")
	w.adventure.gnome_wait = 0.01
	w.step(0.02)
	check(w.adventure.enemies.any(func(e): return e.kind == "gnome"), "Mushroom starts the red-cap gnome encounter wave")
	w.obstacles = [{"x":World.PLAYER_X,"kind":"fire","counted":false}]
	w.step(0.02)
	check(w.state == "running" and w.obstacles.is_empty() and w.passed == 1, "Giant form physically smashes a ground obstacle")
	w.adventure.powers.mushroom = 0.01
	w.step(0.02)
	check(not w.adventure.giant() and w.invulnerable > 1, "Shrinking gives a short grace period instead of an unavoidable contact death")
	w = arena()
	w.character = "sheep"
	w.sheep_count = 2
	w.adventure.collect(w, "leaf")
	check(w.sheep_count == 3, "Life leaf can recruit the third sheep")
	w.adventure.collect(w, "leaf")
	check(w.sheep_count == 3 and w.adventure.powers.shield > 0, "Another leaf never creates a fourth sheep")
	w = arena()
	w.adventure.collect(w, "magnet")
	w.pickups = [{"x":World.PLAYER_X+150,"y":-113.0,"taken":false}]
	advance(w, 0.5)
	check(w.gems == 1, "Magnet moves a real crystal into pickup range")
	w = arena()
	w.adventure.collect(w, "lightning")
	w.adventure.spawn_enemy(w, "crow", World.PLAYER_X+350,-70)
	w.adventure.spawn_enemy(w, "gnome", World.PLAYER_X+550)
	w.adventure.attack(w)
	check(w.adventure.kills == 2 and w.adventure.lightning_charges == 1 and w.adventure.lightning_targets.size() == 2, "A collected lightning charge chains actual damage to distant enemies")
	for id in w.adventure.POWER_NAMES: w.adventure.collect(w, id)
	w.adventure.collect(w, "mushroom")
	check(w.adventure.discoveries.size() == 7, "Discovery progress records each power once")
	w.reset()
	check(w.adventure.discoveries.size() == 7 and not w.adventure.giant() and w.adventure.enemies.is_empty(), "Retry preserves discoveries but clears temporary buffs and enemies")
	w = arena()
	w.adventure.powers.mushroom = 4.0
	w.adventure.attack_held = true
	w.adventure.duck_held = true
	w.adventure.weather = "storm"
	w.adventure.thunder_time = 0.3
	w.state = "paused"
	w.step(0.02)
	check(w.adventure.powers.mushroom == 4.0 and w.adventure.thunder_time == 0.3, "Pause freezes power durations, weather and attack clocks")
	w.release_controls()
	check(not w.adventure.attack_held and not w.adventure.duck_held, "Focus/pause cancellation releases attack and duck holds")
	w = arena()
	w.adventure.weather_wait = 0.01
	w.rng.seed = 44
	w.step(0.02)
	check(w.adventure.weather != "clear", "The weather scheduler actually changes the weather")
	w.adventure.weather = "storm"
	w.adventure.thunder_wait = 0.01
	w.step(0.02)
	check(w.adventure.thunder_time > 0 and w.adventure.thunder_wait >= 6, "Storm lightning is an occasional bounded fade, not rapid repeated flashes")
	w.adventure.tempo_wait = 0.01
	w.step(0.02)
	check(w.adventure.tempo_target >= 0.82 and w.adventure.tempo_target <= 1.16, "Tempo variation stays inside the planned speed range")
	w = arena()
	var kinds := {}
	var min_gap := 99999.0
	var max_gap := 0.0
	for i in 30:
		w.adventure.spawn_encounter(w)
		kinds[w.adventure.last_encounter] = true
		min_gap = minf(min_gap, w.adventure.spawn_gap)
		max_gap = maxf(max_gap, w.adventure.spawn_gap)
	check(kinds.size() == 5, "Encounter bags include ground hazards, low branches and both crow heights")
	check(min_gap >= 680 and max_gap - min_gap > 400, "Random encounter distances vary broadly while retaining safe clearance")
	w = arena()
	w.character = "sheep"
	w.sheep_count = 3
	w.jump()
	w.step(1.0 / 120)
	check(w.flock_pose(0).y == 0 and w.flock_pose(1).y == 0 and World.FLOCK_GAP == 112, "The new wider flock spacing leaves both followers grounded on leader takeoff")
	var takeoff_times := [-1.0,-1.0]
	for i in 120:
		w.step(1.0 / 120)
		for n in 2:
			if takeoff_times[n] < 0 and w.flock_pose(n).y < -0.01: takeoff_times[n] = w.time
	check(takeoff_times[0] > 0.32 and takeoff_times[1] > takeoff_times[0] + 0.32, "At starting speed the sheep take off in visibly distinct roughly 0.35-second stages")
	w = arena()
	w.adventure.kills = 3
	w.adventure.update_goal(w)
	check(w.adventure.goal_index == 1 and w.adventure.bonus_score == 100, "A real completed kill goal grants its reward once")
	w.adventure.update_goal(w)
	check(w.adventure.bonus_score == 100, "Repeated goal checks cannot award the previous goal twice")
	w = arena()
	w.adventure.spawn_enemy(w, "gnome", World.PLAYER_X)
	w.obstacles = [{"x":World.PLAYER_X,"kind":"fire","counted":false}]
	w.y = -49.0
	w.velocity = 350.0
	w.step(1.0 / 120)
	check(w.state == "running" and w.adventure.stomps == 1, "Stomp bounce has brief protection against a coincident ground hazard")
	print("RESULT: %d adventure checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
