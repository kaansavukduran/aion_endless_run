class_name RunnerAdventure
extends RefCounted

const POWER_NAMES := ["mushroom", "lightning", "slow", "haste", "shield", "magnet", "leaf"]
const ATTACK_DURATION := 0.40
const ATTACK_COOLDOWN := 0.46
var enabled := true
var enemies: Array[Dictionary] = []
var items: Array[Dictionary] = []
var powers := {"mushroom":0.0, "slow":0.0, "haste":0.0, "shield":0.0, "magnet":0.0}
var discoveries: Array[String] = []
var attack_held := false
var duck_held := false
var attack_time := 0.0
var attack_cooldown := 0.0
var duck_time := 0.0
var swing_id := 0
var goal_index := 0
var goal_start := 0
var items_collected := 0
var kills := 0
var stomps := 0
var stomp_chain := 0
var bonus_score := 0
var lightning_charges := 0
var lightning_time := 0.0
var lightning_targets: Array[Vector2] = []
var item_wait := 0.85
var first_item := true
var gnome_wait := 0.25
var weather := "clear"
var weather_wait := 11.0
var thunder_wait := 3.0
var thunder_time := 0.0
var thunder_x := 760.0
var tempo := 1.0
var tempo_target := 1.0
var tempo_wait := 8.0
var encounter_bag: Array[String] = []
var power_bag: Array[String] = []
var spawn_gap := 700.0
var last_spawn_distance := -10000.0
var last_encounter := ""
var item_id := 0
var enemy_id := 0

func reset() -> void:
	enemies.clear()
	items.clear()
	for key in powers: powers[key] = 0.0
	attack_held = false
	duck_held = false
	attack_time = 0.0
	attack_cooldown = 0.0
	duck_time = 0.0
	swing_id = 0
	goal_index = 0
	goal_start = 0
	items_collected = 0
	kills = 0
	stomps = 0
	stomp_chain = 0
	bonus_score = 0
	lightning_charges = 0
	lightning_time = 0.0
	lightning_targets.clear()
	item_wait = 0.85
	first_item = true
	gnome_wait = 0.3
	weather = "clear"
	weather_wait = 11.0
	thunder_time = 0.0
	thunder_wait = 3.0
	tempo = 1.0
	tempo_target = 1.0
	tempo_wait = 8.0
	encounter_bag.clear()
	power_bag.clear()
	last_spawn_distance = -10000.0
	last_encounter = ""

func giant() -> bool:
	return enabled and float(powers.mushroom) > 0.0

func size_multiplier() -> float:
	return 1.65 if giant() else 1.0

func ducking(world) -> bool:
	return enabled and duck_held and world.y >= -0.01

func body_height(world) -> float:
	return (35.0 if ducking(world) else 82.0) * size_multiplier()

func speed_multiplier() -> float:
	if not enabled: return 1.0
	var factor := tempo
	if float(powers.slow) > 0.0: factor *= 0.68
	if float(powers.haste) > 0.0: factor *= 1.28
	return factor

func attack(world) -> bool:
	if not enabled or world.state != "running" or attack_cooldown > 0.0: return false
	swing_id += 1
	attack_time = ATTACK_DURATION
	attack_cooldown = ATTACK_COOLDOWN
	world.event("attack_" + world.character)
	if lightning_charges > 0:
		lightning_charges -= 1
		lightning_time = 0.32
		lightning_targets.clear()
		for enemy in enemies:
			if enemy.hp > 0 and enemy.x > world.PLAYER_X - 40 and enemy.x < world.PLAYER_X + 700:
				lightning_targets.append(Vector2(enemy.x, enemy.y))
				hit_enemy(world, enemy, 3, false)
				if lightning_targets.size() >= 5: break
		world.event("lightning_cast")
	return true

func attack_active() -> bool:
	return attack_time > 0.10 and attack_time <= 0.27

func attack_frame() -> int:
	return clampi(int((ATTACK_DURATION - attack_time) * 15.0), 0, 5)

func body_rect(world) -> Rect2:
	var scale := size_multiplier()
	return Rect2(world.PLAYER_X - 16 * scale, world.y - body_height(world), 32 * scale, body_height(world))

func hit_enemy(world, enemy: Dictionary, damage: int, stomp: bool) -> void:
	if enemy.hp <= 0: return
	enemy.hp -= damage
	enemy.hurt = 0.32
	if enemy.hp > 0: enemy.x += 200.0
	world.event("enemy_hit")
	if enemy.hp <= 0:
		enemy.defeat = 0.001
		kills += 1
		if stomp:
			stomps += 1
			stomp_chain = mini(5, stomp_chain + 1)
			bonus_score += 50 + stomp_chain * 10
		else:
			bonus_score += 35
		world.event("stomp" if stomp else "enemy_down")

func spawn_enemy(world, kind: String, x: float = -1.0, altitude: float = -74.0) -> Dictionary:
	enemy_id += 1
	var hp := 2 if kind == "gnome" else 1
	var enemy := {"id":enemy_id, "kind":kind, "x":world.field_width + 70.0 if x < 0 else x, "y":altitude if kind == "crow" else -23.0, "base_y":altitude, "hp":hp, "max_hp":hp, "hurt":0.0, "defeat":0.0, "age":0.0, "last_swing":-1, "diving":false}
	enemies.append(enemy)
	return enemy

func shuffled_pick(world, bag: Array[String], values: Array[String]) -> String:
	if bag.is_empty():
		bag.assign(values)
		for i in range(bag.size() - 1, 0, -1):
			var other: int = world.rng.randi_range(0, i)
			var old: String = bag[i]
			bag[i] = bag[other]
			bag[other] = old
	return bag.pop_back()

func spawn_encounter(world) -> void:
	var kind := shuffled_pick(world, encounter_bag, ["fire", "ice", "crow", "crow_high", "arch"])
	if kind == last_encounter: kind = "crow" if kind != "crow" else "ice"
	last_encounter = kind
	last_spawn_distance = world.distance
	spawn_gap = world.rng.randf_range(680.0, 1550.0)
	if kind.begins_with("crow"):
		spawn_enemy(world, "crow", -1.0, -154.0 if kind == "crow_high" else -71.0)
	else:
		world.obstacles.append({"x":world.field_width + 70.0, "kind":kind, "counted":false, "broken":false})
	# A broad gap distribution creates bursts and breathing spaces. Distances
	# also reserve enough clearance for a full jump at the future speed cap.
	world.obstacle_wait = world.rng.randf_range(0.8, 2.7)
	world.pickups.append({"x":world.field_width + 75.0, "y":-112.0, "taken":false})

func spawn_item(world, kind: String, x: float = -1.0) -> Dictionary:
	item_id += 1
	var item := {"id":item_id, "kind":kind, "x":world.field_width + 60.0 if x < 0 else x, "y":-32.0, "taken":false}
	items.append(item)
	return item

func collect(world, kind: String) -> void:
	items_collected += 1
	bonus_score += 15
	if not discoveries.has(kind): discoveries.append(kind)
	match kind:
		"mushroom":
			powers.mushroom = 10.0
			gnome_wait = 0.20
			world.invulnerable = maxf(world.invulnerable, 0.5)
		"lightning": lightning_charges = mini(3, lightning_charges + 2)
		"slow":
			powers.slow = 7.0
			powers.haste = 0.0
		"haste":
			powers.haste = 8.0
			powers.slow = 0.0
		"shield": powers.shield = 12.0
		"magnet": powers.magnet = 10.0
		"leaf":
			if world.character == "sheep" and world.sheep_count < 3: world.sheep_count += 1
			else: powers.shield = maxf(float(powers.shield), 8.0)
	world.event("power_" + kind)

func absorb_hit(world) -> bool:
	if not enabled: return false
	if float(powers.shield) > 0.0:
		powers.shield = 0.0
		world.invulnerable = 1.1
		world.event("shield_saved")
		return true
	if giant():
		powers.mushroom = maxf(0.0, float(powers.mushroom) - 2.0)
		world.invulnerable = 0.9
		world.event("giant_hit")
		return true
	return false

func goal_info() -> Dictionary:
	var kind: String = ["kill", "stomp", "collect"][goal_index % 3]
	var count := kills if kind == "kill" else (stomps if kind == "stomp" else items_collected)
	var target: int = (3 if kind != "stomp" else 2) + goal_index / 3
	return {"kind":kind, "progress":maxi(0, count - goal_start), "target":target}

func update_goal(world) -> void:
	var goal := goal_info()
	if goal.progress < goal.target: return
	bonus_score += 100
	goal_index += 1
	var next := goal_info()
	goal_start = kills if next.kind == "kill" else (stomps if next.kind == "stomp" else items_collected)
	world.event("goal_done")

func before_step(world, dt: float) -> void:
	if not enabled: return
	var was_giant := giant()
	for key in powers: powers[key] = maxf(0.0, float(powers[key]) - dt)
	if was_giant and not giant(): world.invulnerable = maxf(world.invulnerable, 1.2)
	attack_time = maxf(0.0, attack_time - dt)
	attack_cooldown = maxf(0.0, attack_cooldown - dt)
	duck_time = duck_time + dt if ducking(world) else 0.0
	lightning_time = maxf(0.0, lightning_time - dt)
	thunder_time = maxf(0.0, thunder_time - dt)
	if attack_held and attack_cooldown <= 0.0: attack(world)
	tempo_wait -= dt
	if tempo_wait <= 0.0:
		tempo_target = world.rng.randf_range(0.82, 1.16)
		tempo_wait = world.rng.randf_range(8.0, 14.0)
	tempo = move_toward(tempo, tempo_target, dt * 0.075)
	weather_wait -= dt
	if weather_wait <= 0.0:
		var options := ["rain", "storm", "snow", "sand", "clear"]
		options.erase(weather)
		weather = options[world.rng.randi_range(0, options.size() - 1)]
		weather_wait = world.rng.randf_range(14.0, 25.0)
		world.event("weather_" + weather)
	if weather == "storm":
		thunder_wait -= dt
		if thunder_wait <= 0.0:
			thunder_time = 0.55
			thunder_wait = world.rng.randf_range(6.0, 11.0)
			thunder_x = world.rng.randf_range(world.field_width * 0.45, world.field_width * 0.90)
			world.event("thunder")

func after_step(world, dt: float, movement: float, previous_y: float) -> void:
	if not enabled: return
	if world.y >= 0.0: stomp_chain = 0
	item_wait -= dt
	if item_wait <= 0.0:
		var kind := "mushroom" if first_item else shuffled_pick(world, power_bag, POWER_NAMES)
		spawn_item(world, kind, world.PLAYER_X + 410.0 if first_item else -1.0)
		first_item = false
		item_wait = world.rng.randf_range(6.5, 10.0)
	if giant():
		gnome_wait -= dt
		if gnome_wait <= 0.0 and enemies.filter(func(e): return e.kind == "gnome" and e.hp > 0).size() < 7:
			spawn_enemy(world, "gnome")
			gnome_wait = world.rng.randf_range(0.55, 1.05)
	var body := body_rect(world)
	for item in items:
		item.x -= movement
		if body.grow(18).has_point(Vector2(item.x, item.y)):
			item.taken = true
			collect(world, item.kind)
	items = items.filter(func(i): return i.x > -80.0 and not i.taken)
	if float(powers.magnet) > 0.0:
		for crystal in world.pickups:
			if absf(crystal.x - world.PLAYER_X) < 270:
				crystal.x = move_toward(crystal.x, world.PLAYER_X, dt * 650)
				crystal.y = move_toward(crystal.y, world.y - 35.0, dt * 480)
	for enemy in enemies:
		enemy.age += dt
		enemy.x -= movement * (1.13 if enemy.kind == "crow" else 1.04) * (0.1 if enemy.hurt > 0.0 and enemy.hp > 0 else 1.0)
		enemy.hurt = maxf(0.0, enemy.hurt - dt)
		if enemy.hp <= 0:
			enemy.defeat += dt
			continue
		if enemy.kind == "crow":
			enemy.diving = enemy.base_y > -100 and enemy.x < world.PLAYER_X + 380
			enemy.y = enemy.base_y + sin(enemy.age * 4.0 + enemy.id) * 7.0
			if enemy.diving: enemy.y += 5.0
		var rect := Rect2(enemy.x - 22, enemy.y - 19, 44, 38) if enemy.kind == "crow" else Rect2(enemy.x - 18, -46, 36, 46)
		# A descending foot crossing the top wins over side damage on that tick.
		if world.velocity > 0.0 and previous_y <= rect.position.y + 9 and world.y >= rect.position.y and absf(enemy.x - world.PLAYER_X) < 35 * size_multiplier():
			hit_enemy(world, enemy, 3, true)
			world.y = rect.position.y - 2.0
			world.velocity = -455.0
			world.gliding = false
			world.air_time = 0.0
			world.jumps_used = 1
			world.invulnerable = maxf(world.invulnerable, 0.18)
			continue
		if attack_active() and enemy.last_swing != swing_id:
			var attack_rect := Rect2(world.PLAYER_X + 4, world.y - (48.0 if ducking(world) else 92.0) * size_multiplier(), 135 * size_multiplier(), (44.0 if ducking(world) else 88.0) * size_multiplier())
			if attack_rect.intersects(rect):
				enemy.last_swing = swing_id
				hit_enemy(world, enemy, 2 if giant() else 1, false)
				if enemy.hp <= 0: continue
		if body.intersects(rect) and world.invulnerable <= 0.0 and enemy.hurt <= 0.0:
			world.take_hit("bonk")
			if world.state != "running": break
	enemies = enemies.filter(func(e): return e.x > -120 and (e.hp > 0 or e.defeat < 0.65))
	update_goal(world)
