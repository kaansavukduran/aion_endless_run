class_name RunnerAdventure
extends RefCounted

const POWER_NAMES := ["mushroom", "lightning", "slow", "haste", "shield", "magnet", "leaf", "spring", "fortune", "frost"]
const ATTACK_DURATION := 0.40
const ATTACK_COOLDOWN := 0.46
const LEVEL_DISTANCE := 12000.0
const MIN_LEVEL_TIME := 15.0
const HUG_DURATION := 1.0
var celebrations_enabled := true
var heart_time := 0.0
var fragaria_next_level := 100
var fragaria_time := 0.0
var fragaria_origin_distance := 0.0
var fragaria_found := 0
var level := 1
var level_elapsed := 0.0
var level_start_distance := 0.0
var celebration_spawn_distance := 0.0
var celebration_origin := 0.0
var rush_time := 0.0
var attack_airborne := false
var attack_sprinting := false
var celebration_clock := 0.0
var celebration_time := 0.0
var celebration_style := 0
var girl_index := -1
var girl_bag: Array[int] = []
var last_girl := -1
var last_hug_girl := -1
var hug_queue: Array[Dictionary] = []
var hug_level := 0
var hug_pending := false
var hug_time := 0.0
var hug_count := 0
var mushroom_chance := 0.02
var last_mushroom_at := -10000.0
var ambient_gnome_wait := 16.0
var attack_variant := 0
var pending_attack := false
var roll_time := 0.0
var roll_elapsed := 0.0
var enabled := true
var enemies: Array[Dictionary] = []
var items: Array[Dictionary] = []
var powers := {"mushroom":0.0, "slow":0.0, "haste":0.0, "shield":0.0, "magnet":0.0, "spring":0.0, "fortune":0.0, "frost":0.0}
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
const LIGHTNING_RANGE := 1500.0
const LIGHTNING_RADIUS := 92.0
const LIGHTNING_COOLDOWN := 0.65
var lightning_cooldown := 0.0
var lightning_origin := Vector2.ZERO
var lightning_end := Vector2.ZERO
var run_xp := 0
var xp_notice := 0.0
var last_xp := 0
var lightning_time := 0.0
var lightning_targets: Array[Vector2] = []
var item_wait := 12.0
var first_item := true
var gnome_wait := 0.25
var wave_candidate_count := 0
var wave_spawn_count := 0
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
	heart_time = 0.0
	fragaria_next_level = 100
	fragaria_time = 0.0
	fragaria_found = 0
	level = 1
	level_elapsed = 0.0
	level_start_distance = 0.0
	celebration_spawn_distance = 0.0
	celebration_origin = 0.0
	rush_time = 0.0
	attack_airborne = false
	celebration_clock = 0.0
	celebration_time = 0.0
	celebration_style = 0
	girl_index = -1
	girl_bag.clear()
	last_girl = -1
	last_hug_girl = -1
	hug_queue.clear()
	hug_level = 0
	hug_pending = false
	hug_time = 0.0
	hug_count = 0
	last_mushroom_at = -10000.0
	ambient_gnome_wait = 16.0
	attack_variant = 0
	attack_sprinting = false
	pending_attack = false
	roll_time = 0.0
	roll_elapsed = 0.0
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
	lightning_cooldown = 0.0
	run_xp = 0
	xp_notice = 0.0
	last_xp = 0
	lightning_targets.clear()
	item_wait = 12.0
	first_item = true
	gnome_wait = 0.3
	wave_candidate_count = 0
	wave_spawn_count = 0
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
	return enabled and (duck_held or roll_time > 0.0) and world.y >= -0.01 and not hugging()

func hugging() -> bool:
	return enabled and hug_time > 0.0

func press_roll(world) -> void:
	if not enabled or world.state != "running" or hugging(): return
	duck_held = true
	attack_time = 0.0
	pending_attack = false
	if roll_time <= 0.0: roll_elapsed = 0.0
	roll_time = maxf(roll_time, 0.68)

func request_attack(world) -> bool:
	if attack_held or hugging() or world.frontier.active() or world.state != "running": return false
	attack_held = true
	if ducking(world): return false
	if attack_cooldown > 0.0:
		pending_attack = attack_cooldown <= 0.16
		return false
	return attack(world)

func roll_frame(frame_count: int = 6) -> int:
	return roll_pose(roll_elapsed,roll_time,duck_held,frame_count)

func roll_pose(elapsed: float,remaining: float,held: bool,frame_count: int=6) -> int:
	if frame_count==6:
		# Six reviewed new poses: lower, hands, shoulder, hips over, feet,
		# crouch. Never hold the upside-down shoulder pose or loop a ball.
		if not held and remaining<0.15:return 5 if remaining>.075 else 0
		return mini(5,int(maxf(0.0,elapsed)/0.53*6))
	# A single planted-hand shoulder roll, then a low crouch while held.
	# Repeating the entry/recovery at high speed made the hero read as a ball.
	var entry:=3 if frame_count>=12 else 2
	var turn_count: int=frame_count-entry*2
	var recovery: int=entry+turn_count
	if not held and remaining<0.15:
		return mini(frame_count-1,recovery+int((0.15-remaining)/0.15*entry))
	if elapsed<0.14:return mini(entry-1,int(elapsed/0.14*entry))
	if elapsed<0.53:return entry+mini(turn_count-1,int((elapsed-0.14)/0.39*turn_count))
	return entry # Knees/hand low; never restart an endless spinning loop.

func level_distance(world) -> float:
	return maxf(0.0,world.distance-level_start_distance)

func level_progress(world) -> float:
	return clampf(level_elapsed / MIN_LEVEL_TIME, 0.0, 1.0)

func celebration_x(world, moving: bool = true) -> float:
	return celebration_origin - (world.distance-celebration_spawn_distance)*0.45 if moving else celebration_origin

func choose_power(world) -> String:
	var eligible: bool = world.time >= 20.0 and world.time - last_mushroom_at >= 45.0
	if eligible and mushroom_chance > 0.0 and world.rng.randf() < mushroom_chance:
		last_mushroom_at = world.time
		return "mushroom"
	return shuffled_pick(world, power_bag, ["lightning", "slow", "haste", "shield", "magnet", "leaf", "spring", "fortune", "frost"])

func choose_girl(world) -> void:
	if girl_bag.is_empty():
		girl_bag.assign([0,1,2,3,4,5,6,7])
		for i in range(7, 0, -1):
			var other: int = world.rng.randi_range(0, i)
			var old: int = girl_bag[i]
			girl_bag[i] = girl_bag[other]
			girl_bag[other] = old
	var next: int = girl_bag.pop_back()
	if next == last_girl or (level % 10 == 0 and next == last_hug_girl):
		for candidate in range(8):
			if candidate != last_girl and (level % 10 != 0 or candidate != last_hug_girl):
				next = candidate
				break
	girl_index = next
	last_girl = next

func update_level(world) -> void:
	if not enabled or world.frontier.active(): return
	if world.state != "running": return
	if level_elapsed + 0.000001 >= MIN_LEVEL_TIME:
		heart_time = 0.0
		level += 1
		level_elapsed = 0.0
		level_start_distance = world.distance
		celebration_spawn_distance = world.distance
		celebration_origin = world.field_width*0.70
		choose_girl(world)
		var previous_style := celebration_style
		celebration_style = world.rng.randi_range(0, 3)
		if celebration_style == previous_style: celebration_style = (celebration_style+1)%4
		celebration_time = 5.0
		world.event("level_up")
		if level % 10 == 0 and not celebrations_enabled: world.frontier.request_boss(level)
		if level % 10 == 0 and celebrations_enabled:
			hug_queue.append({"level":level,"girl":girl_index,"style":celebration_style})
			last_hug_girl = girl_index
			hug_pending = true
	if hug_pending and celebrations_enabled and world.y >= 0.0 and world.state == "running":
		var milestone: Dictionary = hug_queue.pop_front()
		hug_pending = not hug_queue.is_empty()
		hug_level = milestone.level
		girl_index = milestone.girl
		celebration_style = milestone.style
		hug_time = HUG_DURATION
		hug_count += 1
		last_hug_girl = girl_index
		attack_time = 0.0
		pending_attack = false
		roll_time = 0.0
		duck_held = false
		celebration_spawn_distance = world.distance
		world.release_controls()
		world.event("hug_start")

func advance_hug(world, dt: float) -> void:
	hug_time = maxf(0.0, hug_time - dt)
	celebration_clock += dt
	if hug_time <= 0.0:
		heart_time = 2.0
		celebration_time = 2.0
		world.invulnerable = maxf(world.invulnerable, 0.65)
		world.event("hug_end")
		world.frontier.request_boss(hug_level)

func body_height(world) -> float:
	if world.charging:return lerpf(72.0,56.0,world.charge_ratio())*size_multiplier()
	return (52.0 if ducking(world) else 82.0) * size_multiplier()

func speed_multiplier() -> float:
	if not enabled: return 1.0
	var factor := tempo * (1.18 if rush_time > 0.0 else 1.0)
	if float(powers.slow) > 0.0: factor *= 0.68
	if float(powers.haste) > 0.0: factor *= 1.28
	return factor

func attack(world) -> bool:
	if not enabled or world.state != "running" or attack_cooldown > 0.0 or hugging() or ducking(world) or world.frontier.active(): return false
	swing_id += 1
	attack_variant = (swing_id - 1) % 2
	attack_airborne = world.character == "owl" and world.y < -1.0
	attack_sprinting = world.character == "wolf" and world.boosting() and world.y >= -1.0
	attack_time = ATTACK_DURATION
	attack_cooldown = ATTACK_COOLDOWN
	world.event("attack_" + world.character)

	return true

func attack_active() -> bool:
	return attack_time > 0.10 and attack_time <= 0.27

func attack_frame(frame_count: int = 6) -> int:
	return clampi(int((ATTACK_DURATION-attack_time)/ATTACK_DURATION*frame_count),0,frame_count-1)

func body_rect(world) -> Rect2:
	var scale := size_multiplier()
	return Rect2(world.PLAYER_X - 16 * scale, world.y - body_height(world), 32 * scale, body_height(world))

func attack_rect(world) -> Rect2:
	if world.character == "wolf":
		var size := size_multiplier()
		return Rect2(world.PLAYER_X+4*size,world.y-88*size,(142 if attack_sprinting else 124)*size,84*size)
	if attack_airborne: return Rect2(world.PLAYER_X+18,world.y-76,88,38)
	return Rect2(world.PLAYER_X+4,world.y-92.0*size_multiplier(),(100.0+float(attack_variant)*12.0)*size_multiplier(),88.0*size_multiplier())

func hit_enemy(world, enemy: Dictionary, damage: int, stomp: bool) -> void:
	if enemy.hp <= 0: return
	enemy.hp -= damage
	enemy.hurt = 0.32
	if enemy.hp > 0: enemy.x += 200.0
	world.event("enemy_hit")
	if enemy.hp <= 0:
		enemy.defeat = 0.001
		reward_enemy(world, stomp)

func reward_enemy(world, stomp: bool) -> void:
	kills += 1
	award_xp(15 if stomp else 10)
	if stomp:
		stomps += 1
		stomp_chain = mini(5, stomp_chain + 1)
		bonus_score += 50 + stomp_chain * 10
	else: bonus_score += 35
	world.event("stomp" if stomp else "enemy_down")

func award_xp(amount: int) -> void:
	last_xp = amount
	run_xp += amount
	xp_notice = 1.0

func mastery_rank() -> int: return 1 + run_xp / 100
func jump_multiplier() -> float: return 1.16 if enabled and powers.spring > 0.0 else 1.0

func cast_lightning(world) -> bool:
	if not enabled or world.state != "running" or world.frontier.active() or hugging() or ducking(world) or lightning_charges <= 0 or lightning_cooldown > 0: return false
	lightning_charges -= 1
	lightning_cooldown = LIGHTNING_COOLDOWN
	lightning_time = 0.32
	lightning_origin = Vector2(world.PLAYER_X+28, world.y-48)
	lightning_end = lightning_origin + Vector2(LIGHTNING_RANGE, 0)
	lightning_targets.clear()
	var corridor := Rect2(lightning_origin-Vector2(0,LIGHTNING_RADIUS),Vector2(LIGHTNING_RANGE,LIGHTNING_RADIUS*2))
	for enemy in enemies:
		if enemy.hp > 0 and corridor.intersects(enemy_rect(enemy)):
			lightning_targets.append(Vector2(enemy.x, enemy.y))
			hit_enemy(world, enemy, 1, false)
	for plant in world.frontier.plants:
		if plant.hp > 0 and corridor.intersects(Rect2(plant.x-25,-68,50,68)):
			plant.hp = 0
			reward_enemy(world, false)
			lightning_targets.append(Vector2(plant.x,-36))
	world.event("lightning_cast")
	return true

func flying(kind: String) -> bool: return kind in ["crow", "bat", "wisp"]

func enemy_rect(enemy: Dictionary) -> Rect2:
	if flying(enemy.kind): return Rect2(enemy.x-22,enemy.y-19,44,38)
	if enemy.kind == "slime": return Rect2(enemy.x-23,enemy.y-15,46,30)
	return Rect2(enemy.x-18,enemy.y-23,36,46)

func spawn_enemy(world, kind: String, x: float = -1.0, altitude: float = -74.0) -> Dictionary:
	enemy_id += 1
	var hp := 1
	var enemy := {"id":enemy_id, "kind":kind, "x":world.field_width + 70.0 if x < 0 else x, "y":altitude if flying(kind) else (-15.0 if kind == "slime" else -23.0), "base_y":altitude, "hp":hp, "max_hp":hp, "hurt":0.0, "defeat":0.0, "age":0.0, "last_swing":-1, "diving":false,"wave":false}
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
	var kind := shuffled_pick(world, encounter_bag, ["fire", "ice", "crow", "crow_high", "bat", "wisp", "slime", "beetle", "gate", "carrier_pipe", "carrier_plank"])
	if kind == last_encounter: kind = "crow" if kind != "crow" else "ice"
	if world.rng.randf() < 0.30:
		kind = ["block_crate","block_log","block_road","block_rock","block_vent","block_barrel","pit","pit_city"][world.rng.randi_range(0,7)]
	# A bag guarantees variety; occasional weighted draws break its repeating cadence.
	if world.rng.randf() < 0.28:
		var regional: Array = [["beetle","crow"],["wisp","beetle"],["slime","bat"],["crow","beetle"],["bat","slime"],["wisp","bat"]][world.biome()]
		kind = regional[world.rng.randi_range(0,1)]
	last_encounter = kind
	last_spawn_distance = world.distance
	spawn_gap = world.rng.randf_range(680.0, 1550.0)
	if level >= 4 and world.rng.randf() < 0.07:
		kind = "gnome"
		last_encounter = kind
	if kind in ["gnome", "slime", "beetle", "bat", "wisp"]:
		spawn_enemy(world, kind, -1.0, world.rng.randf_range(-128.0,-78.0) if flying(kind) else -23.0)
	elif kind.begins_with("crow"):
		spawn_enemy(world, "crow", -1.0, -154.0 if kind == "crow_high" else -86.0)
	else:
		world.obstacles.append({"x":world.field_width + 70.0, "kind":kind, "counted":false, "broken":false,"width":clampf(world.speed()*0.42,135.0,210.0) if kind.begins_with("pit") else 64.0,"theme":world.biome()})
	# A broad gap distribution creates bursts and breathing spaces. Distances
	# also reserve enough clearance for a full jump at the future speed cap.
	world.obstacle_wait = world.rng.randf_range(0.8, 2.7)

func spawn_item(world, kind: String, x: float = -1.0) -> Dictionary:
	item_id += 1
	var item := {"id":item_id, "kind":kind, "x":world.field_width + 60.0 if x < 0 else x, "y":-32.0, "taken":false}
	items.append(item)
	return item

func offer_fragaria(world, milestone: int) -> void:
	if world.practice or milestone < fragaria_next_level or level < fragaria_next_level: return
	spawn_item(world,"fragaria")
	fragaria_next_level += 100

func collect(world, kind: String) -> void:
	if kind=="fragaria":
		fragaria_found += 1
		fragaria_origin_distance=world.distance
		fragaria_time = 3.8
		world.event("fragaria_found")
		return # No score, item-goal progress, discovery, power or other reward.
	items_collected += 1
	bonus_score += 15
	if not discoveries.has(kind): discoveries.append(kind)
	match kind:
		"mushroom":
			powers.mushroom = 10.0
			gnome_wait = world.rng.randf_range(0.15, 0.65)
			wave_candidate_count = 0
			wave_spawn_count = 0
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
		"spring": powers.spring = 9.0
		"fortune": powers.fortune = 12.0
		"frost": powers.frost = 8.0
		"leaf":
			if world.character == "sheep" and world.sheep_count < 3: world.sheep_count += 1
			else: powers.shield = maxf(float(powers.shield), 8.0)
	world.event("power_" + kind)

func end_wave(world) -> void:
	for enemy in enemies:
		if enemy.get("wave",false) and enemy.hp > 0:
			enemy.hp = 0
			enemy.defeat = 0.001
	world.invulnerable = maxf(world.invulnerable,1.2)

func absorb_hit(world) -> bool:
	if not enabled: return false
	if float(powers.shield) > 0.0:
		powers.shield = 0.0
		world.invulnerable = 1.1
		world.event("shield_saved")
		return true
	if giant():
		powers.mushroom = maxf(0.0, float(powers.mushroom) - 2.0)
		if not giant(): end_wave(world)
		world.invulnerable = maxf(world.invulnerable,0.9)
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
	if not world.frontier.active(): level_elapsed += dt
	fragaria_time = maxf(0.0,fragaria_time-dt)
	rush_time = maxf(0.0,rush_time-dt)
	celebration_clock += dt
	heart_time = maxf(0.0, heart_time - dt)
	celebration_time = maxf(0.0, celebration_time - dt)
	var was_rolling: bool = ducking(world)
	roll_time = maxf(0.0, roll_time - dt)
	if was_rolling: roll_elapsed += dt
	elif not duck_held: roll_elapsed = 0.0
	var was_giant := giant()
	if not world.frontier.active():
		for key in powers: powers[key] = maxf(0.0, float(powers[key]) - dt)
	if was_giant and not giant(): end_wave(world)
	attack_time = maxf(0.0, attack_time - dt)
	attack_cooldown = maxf(0.0, attack_cooldown - dt)
	duck_time = duck_time + dt if ducking(world) else 0.0
	lightning_time = maxf(0.0, lightning_time - dt)
	lightning_cooldown = maxf(0.0, lightning_cooldown - dt)
	xp_notice = maxf(0.0, xp_notice - dt)
	thunder_time = maxf(0.0, thunder_time - dt)
	if pending_attack and attack_cooldown <= 0.0:
		pending_attack = false
		attack(world)
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
		spawn_item(world, choose_power(world))
		first_item = false
		item_wait = world.rng.randf_range(8.0, 14.0)
	if giant():
		update_mushroom_wave(world,dt)
	elif level >= 4:
		ambient_gnome_wait -= dt
		if ambient_gnome_wait <= 0.0:
			var near: bool = world.obstacles.any(func(o): return o.x > world.field_width - 400) or enemies.any(func(e): return e.hp > 0 and e.x > world.field_width - 400)
			if not near:
				spawn_enemy(world, "gnome")
				last_spawn_distance = world.distance
				spawn_gap = world.rng.randf_range(680.0,1150.0)
				world.obstacle_wait = world.rng.randf_range(1.2,2.4)
			ambient_gnome_wait = world.rng.randf_range(18.0, 34.0)
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
		enemy.x -= movement * (1.13 if flying(enemy.kind) else (1.16 if enemy.kind == "beetle" else 1.04)) * (0.55 if powers.frost > 0 and enemy.x > world.PLAYER_X and enemy.x-world.PLAYER_X < 430 else 1.0) * (0.1 if enemy.hurt > 0.0 and enemy.hp > 0 else 1.0)
		enemy.hurt = maxf(0.0, enemy.hurt - dt)
		if enemy.hp <= 0:
			enemy.defeat += dt
			continue
		if enemy.kind == "crow":
			enemy.diving = enemy.base_y > -100 and enemy.x < world.PLAYER_X + 380
			enemy.y = enemy.base_y + sin(enemy.age * 4.0 + enemy.id) * 7.0
			if enemy.diving: enemy.y += 5.0
		elif enemy.kind == "bat": enemy.y = enemy.base_y + sin(enemy.age*3.2)*18.0
		elif enemy.kind == "wisp": enemy.y = enemy.base_y + sin(enemy.age*2.0)*12.0
		elif enemy.kind == "slime": enemy.y = -15.0-absf(sin(enemy.age*2.8))*24.0
		var rect := enemy_rect(enemy)
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
			var strike := attack_rect(world)
			if strike.intersects(rect):
				enemy.last_swing = swing_id
				hit_enemy(world, enemy, 2 if giant() or (world.character == "wolf" and attack_variant == 1) else 1, false)
				if enemy.hp <= 0: continue
		if body.intersects(rect) and world.invulnerable <= 0.0 and enemy.hurt <= 0.0:
			world.take_hit("bonk","enemy")
			if world.state != "running": break
	enemies = enemies.filter(func(e): return e.x > -120 and (e.hp > 0 or e.defeat < 0.65))
	update_goal(world)

func update_mushroom_wave(world,dt: float) -> void:
	gnome_wait -= dt
	if gnome_wait <= 0.0:
		var alive: int = enemies.filter(func(e): return e.kind == "gnome" and e.hp > 0).size()
		var count: int = world.rng.randi_range(1, 3)
		for i in count:
			# Draw every candidate's spacing, even when thinning. Keep random
			# wave cadence; emit alternate candidates across wave boundaries.
			var spawn_x: float = world.field_width + 60.0 + i * world.rng.randf_range(85.0, 220.0)
			wave_candidate_count += 1
			if wave_candidate_count % 2 == 0 and alive < 7:
				var wave_enemy := spawn_enemy(world, "gnome", spawn_x)
				wave_enemy.wave = true
				wave_spawn_count += 1
				alive += 1
		gnome_wait = world.rng.randf_range(0.18, 1.30)

