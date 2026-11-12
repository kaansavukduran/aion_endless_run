class_name RunnerWorld
extends RefCounted

const PLAYER_X := 288.0
const GRAVITY := 1700.0
const JUMP_SPEED := -650.0
const BIOME_DISTANCE := 6500.0
const BIOME_NAMES := ["desert", "snow", "swamp", "city", "forest", "volcano"]
var boss_travel_offset := 0.0
const GLIDE_FALL_SPEED := 85.0
const BOOST_MULTIPLIER := 1.55
const FLOCK_GAP := 112.0
const WIND_CEILING := -270.0
const WIND_RISE_SPEED := -155.0
var frontier = preload("res://scripts/frontier.gd").new()
var adventure = preload("res://scripts/adventure.gd").new()
var pending_events: Array[String] = []
var character := "aion"
var jumps_used := 0
var jump_held := false
var boost_held := false
var gliding := false
var air_time := 0.0
var sheep_count := 1
var sheep_wait := 1100.0
var sheep_pickups: Array[Dictionary] = []
var invulnerable := 0.0
var landing_time := 0.0
var trail: Array[Dictionary] = []
var gusts: Array[Dictionary] = []
var gust_wait := 380.0
var riding_gust := false
var wind_push := 0.0
var rng := RandomNumberGenerator.new()
var state := "ready"
var time := 0.0
var distance := 0.0
var y := 0.0
var velocity := 0.0
var score := 0
var passed := 0
var gems := 0
var combo := 0
var hit_time := 0.0
var death_cause := ""
var practice := false
var obstacle_wait := 2.1
var obstacles: Array[Dictionary] = []
var pickups: Array[Dictionary] = []
var jump_buffer := 0.0
var last_event := ""
var event_id := 0
var field_width := 1152.0

func reset() -> void:
	state = "running"
	adventure.reset()
	frontier.reset()
	frontier.plant_wait = rng.randf_range(26.0,42.0)
	pending_events.clear()
	time = 0.0
	distance = 0.0
	boss_travel_offset = 0.0
	y = 0.0
	velocity = 0.0
	score = 0
	passed = 0
	gems = 0
	combo = 0
	hit_time = 0.0
	death_cause = ""
	practice = false
	obstacle_wait = 2.1
	jump_buffer = 0.0
	jumps_used = 0
	jump_held = false
	boost_held = false
	gliding = false
	air_time = 0.0
	sheep_count = 1
	sheep_wait = 1100.0
	sheep_pickups.clear()
	invulnerable = 0.0
	landing_time = 0.0
	trail = [{"distance":0.0, "y":0.0, "velocity":0.0, "air_time":0.0, "landing_time":0.0, "duck":0.0, "roll_phase":0.0}]
	gusts.clear()
	gust_wait = 380.0
	riding_gust = false
	wind_push = 0.0
	obstacles.clear()
	pickups.clear()
	last_event = ""
	event_id += 1

func speed() -> float:
	var base := minf(580.0, 320.0 + distance / 450.0)
	var actual := (base * BOOST_MULTIPLIER if boosting() else base) * float(adventure.speed_multiplier()) * (1.0 + wind_push)
	return minf(760.0, actual) if adventure.enabled else actual

func boosting() -> bool:
	return character == "wolf" and boost_held and state == "running"

func max_jumps() -> int:
	return 2 if character == "aion" else 1

func release_controls() -> void:
	jump_held = false
	boost_held = false
	frontier.shoot_held = false
	gliding = false
	riding_gust = false
	adventure.attack_held = false
	adventure.duck_held = false
	adventure.pending_attack = false
	jump_buffer = 0.0

func biome() -> int:
	return int(distance / BIOME_DISTANCE) % BIOME_NAMES.size()

func jump() -> void:
	if state != "running" or adventure.hugging(): return
	if y < 0.0 and character == "aion" and jumps_used < 2:
		velocity = JUMP_SPEED * adventure.jump_multiplier()
		jumps_used += 1
		air_time = 0.0
		jump_buffer = 0.0
		event("double_jump")
	else:
		jump_buffer = 0.12

func event(value: String) -> void:
	last_event = value
	event_id += 1
	pending_events.append(value)
	if pending_events.size() > 24: pending_events.pop_front()

func take_hit(kind: String,cause: String = "") -> bool:
	if invulnerable > 0.0: return false
	if frontier.active(): return frontier.hit_player(self)
	if adventure.absorb_hit(self): return true
	if character == "sheep" and sheep_count > 1:
		sheep_count -= 1
		invulnerable = 1.1
		event("sheep_saved")
		return true
	state = kind
	death_cause = cause if cause != "" else kind
	hit_time = 0.0
	event(kind)
	recompute_score()
	return true

# Sample the leader's actual path at the follower's world coordinate. A fixed
# spatial gap stays correct as speed changes, including mid-jump speed changes.
func flock_pose(index: int) -> Dictionary:
	var target := travel_distance() - FLOCK_GAP * (index + 1)
	if trail.is_empty(): return {"y":0.0, "velocity":0.0, "air_time":0.0, "landing_time":0.0, "duck":0.0, "roll_phase":0.0}
	if target <= float(trail[0].distance): return trail[0].duplicate()
	for i in range(1, trail.size()):
		var right: Dictionary = trail[i]
		if float(right.distance) < target: continue
		var left: Dictionary = trail[i - 1]
		var weight := inverse_lerp(float(left.distance), float(right.distance), target)
		var pose := {}
		for key in ["y", "velocity", "air_time", "landing_time"]:
			pose[key] = lerpf(float(left[key]), float(right[key]), weight)
		if float(left.get("duck",0.0)) > 0.5 and float(right.get("duck",0.0)) > 0.5:
			pose["roll_phase"] = lerpf(float(left.get("roll_phase",0.0)),float(right.get("roll_phase",0.0)),weight)
		else: pose["roll_phase"] = right.get("roll_phase",0.0) if float(right.get("duck",0.0)) > 0.5 else left.get("roll_phase",0.0)
		pose["duck"] = lerpf(float(left.get("duck", 0.0)), float(right.get("duck", 0.0)), weight)
		return pose
	return trail[-1].duplicate()

func travel_distance() -> float:
	return frontier.chase_distance if frontier.active() else distance + boss_travel_offset

func record_trail() -> void:
	trail.append({"distance":travel_distance(), "y":y, "velocity":velocity, "air_time":air_time, "landing_time":landing_time, "duck":1.0 if adventure.ducking(self) else 0.0, "roll_phase":adventure.roll_elapsed})
	while trail.size() > 2 and float(trail[1].distance) < travel_distance() - FLOCK_GAP * 2.0 - 32.0:
		trail.pop_front()

func gust_strength() -> float:
	if y >= -24.0: return 0.0
	for gust in gusts:
		var across := absf(PLAYER_X - float(gust.x)) / (float(gust.width) * 0.5)
		if across < 1.0: return 0.55 + (1.0 - across) * 0.45
	return 0.0

func wind_kind() -> String:
	for gust in gusts:
		if absf(PLAYER_X-float(gust.x)) < float(gust.width)*0.5: return str(gust.get("kind","up"))
	return "up"

func wind_components() -> Vector2:
	if y >= -24.0: return Vector2.ZERO
	for gust in gusts:
		if absf(PLAYER_X - float(gust.x)) < float(gust.width) * 0.5:
			var kind: String = gust.get("kind", "up")
			return Vector2(0.34, 0.0) if kind == "forward" else (Vector2(0.18, 0.70) if kind == "diagonal" else Vector2(0.0, 1.0))
	return Vector2.ZERO

func advance_gusts(movement: float) -> void:
	for gust in gusts: gust.x -= movement
	gusts = gusts.filter(func(g): return float(g.x) + float(g.width) * 0.5 > -80.0)
	if character != "owl": return
	gust_wait -= movement
	if gust_wait <= 0.0:
		gusts.append({"x":field_width + rng.randf_range(30.0, 240.0), "width":rng.randf_range(200.0, 380.0), "kind":["up", "forward", "diagonal"][rng.randi_range(0,2)] if adventure.enabled else "up"})
		gust_wait = rng.randf_range(900.0, 2400.0) if adventure.enabled else rng.randf_range(1350.0, 2150.0)

func step(dt: float) -> void:
	if state in ["ice", "fire", "bonk", "fall"]:
		gliding = false
		riding_gust = false
		hit_time += dt
		if state == "fall": y += (250.0+hit_time*650.0)*dt
		if state == "bonk" and y<0:
			velocity += GRAVITY*dt
			y = minf(0.0,y+maxf(80.0,velocity)*dt)
		return
	if state != "running" or dt <= 0.0 or dt > 0.05:
		return
	if adventure.hugging():
		adventure.advance_hug(self, dt)
		return
	if frontier.pending_level > 0 and y >= 0.0 and not frontier.active(): frontier.begin(self)
	adventure.before_step(self, dt)
	var previous_y := y
	time += dt
	landing_time = maxf(0.0, landing_time - dt)
	var wind := wind_components() if character == "owl" and gliding else Vector2.ZERO
	wind_push = move_toward(wind_push, wind.x, dt * 0.7)
	var movement := speed() * dt
	if not frontier.active(): advance_gusts(movement)
	invulnerable = maxf(0.0, invulnerable - dt)
	if jump_buffer > 0.0 and y >= 0.0:
		velocity = JUMP_SPEED * adventure.jump_multiplier()
		jumps_used = 1
		air_time = 0.0
		landing_time = 0.0
		jump_buffer = 0.0
		gliding = false
		event("jump")
	jump_buffer = maxf(0.0, jump_buffer - dt)
	var was_air := y < 0.0
	var was_riding := riding_gust
	gliding = character == "owl" and jump_held and y < 0.0 and (velocity >= 0.0 or gliding)
	riding_gust = gliding and gust_strength() > 0.0
	if riding_gust:
		velocity = move_toward(velocity, WIND_RISE_SPEED * wind_components().y, 850.0 * gust_strength() * dt)
		if not was_riding: event("updraft")
	elif gliding:
		velocity = minf(GLIDE_FALL_SPEED, velocity + GRAVITY * 0.18 * dt)
	else:
		velocity += GRAVITY * dt
	y = minf(0.0, y + velocity * dt)
	if character == "owl" and y < WIND_CEILING:
		y = WIND_CEILING
		velocity = maxf(0.0, velocity)
	if y < 0.0: air_time += dt
	if y >= 0.0:
		velocity = 0.0
		jumps_used = 0
		gliding = false
		riding_gust = false
		air_time = 0.0
		if was_air:
			landing_time = 0.14
			event("land")
	if frontier.active():
		frontier.step_boss(self,dt)
		if frontier.active(): record_trail()
		recompute_score()
		return
	if character == "sheep" and sheep_count < 3:
		sheep_wait -= movement
		if sheep_wait <= 0.0 and sheep_pickups.is_empty():
			sheep_pickups.append({"x": field_width + 60.0})
			sheep_wait = rng.randf_range(2400.0, 3200.0)
	for friend in sheep_pickups:
		friend.x -= movement
		if character == "sheep" and sheep_count < 3 and absf(friend.x - PLAYER_X) < 38.0 and y > -72.0:
			sheep_count += 1
			friend.x = -1000.0
			event("sheep_join")
	sheep_pickups = sheep_pickups.filter(func(f): return f.x > -90.0)
	var old_biome := biome()
	distance += movement
	if biome() != old_biome:
		event("biome")
	obstacle_wait -= dt
	if obstacle_wait <= 0.0:
		if adventure.enabled:
			if distance - float(adventure.last_spawn_distance) >= float(adventure.spawn_gap):
				adventure.spawn_encounter(self)
		else:
			var kind := "ice" if rng.randf() < (0.78 if biome() else 0.22) else "fire"
			obstacles.append({"x":field_width + 60.0, "kind":kind, "counted":false})
			obstacle_wait = rng.randf_range(1.30, 1.95)
			pickups.append({"x":field_width + 65.0, "y":-113.0, "taken":false})
	adventure.after_step(self, dt, movement, previous_y)
	if adventure.enabled: frontier.step_plants(self,dt,movement)
	record_trail()
	if state != "running" or adventure.hugging(): return
	for obstacle in obstacles:
		obstacle.x -= movement
		var collides := false
		var kind: String = obstacle.kind
		if kind == "gate" or kind.begins_with("arch"):
			if not obstacle.counted and absf(obstacle.x-PLAYER_X)<60 and y>-35:
				adventure.rush_time = maxf(adventure.rush_time,3.5)
				obstacle.counted = true
				passed += 1
				event("gate_boost")
			continue
		if str(obstacle.kind).begins_with("pit"):
			collides = absf(obstacle.x-PLAYER_X) < float(obstacle.get("width",150.0))*0.5-5.0 and y > -20.0
		elif kind.begins_with("carrier"):
			var targets := [Rect2(obstacle.x-80,-92,160,24),Rect2(obstacle.x-73,-177,36,40),Rect2(obstacle.x+37,-177,36,40)]
			var body: Rect2 = adventure.body_rect(self)
			for target in targets: collides = collides or body.intersects(target)
			if not obstacle.counted and adventure.attack_active() and y < -30:
				var strike: Rect2 = adventure.attack_rect(self)
				if targets.any(func(r):return strike.intersects(r)):
					obstacle.x = -1000
					obstacle.counted = true
					passed += 1
					adventure.reward_enemy(self, false)
					event("carrier_down")
					continue
		else:
			collides = obstacle.x + 20.0 > PLAYER_X - 15.0 and obstacle.x - 20.0 < PLAYER_X + 15.0 and y > -49.0
		if collides and adventure.giant() and not str(obstacle.kind).begins_with("pit"):
			obstacle.x = -1000.0
			if not obstacle.counted:
				obstacle.counted = true
				passed += 1
				event("smash")
			continue
		if collides and invulnerable <= 0.0:
			if take_hit("fall" if kind.begins_with("pit") else ("bonk" if kind.begins_with("carrier") or kind.begins_with("block") else kind)):
				obstacle.counted = true
				if kind.begins_with("pit") and state == "running":
					y = -30.0
					velocity = -550.0
					jumps_used = 1
			if state != "running": return
			continue
		if not obstacle.counted and obstacle.x + (float(obstacle.get("width",150))*0.5 if str(obstacle.kind).begins_with("pit") else 20.0) < PLAYER_X - 15.0:
			obstacle.counted = true
			passed += 1
			combo += 1
			event("clear")
	for pickup in pickups:
		pickup.x -= movement
		if not pickup.taken and absf(pickup.x - PLAYER_X) < 34.0 and absf(pickup.y - (y - 35.0)) < 43.0:
			pickup.taken = true
			gems += 1
			if adventure.powers.fortune > 0: adventure.bonus_score += 25
			event("gem")
	obstacles = obstacles.filter(func(o): return o.x > -90.0)
	pickups = pickups.filter(func(o): return o.x > -90.0 and not o.taken)
	recompute_score()
	adventure.update_level(self)

func recompute_score() -> void:
	score = int(distance / 32.0) + passed * 10 + gems * 25 + int(adventure.bonus_score)
