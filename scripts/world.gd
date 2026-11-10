class_name RunnerWorld
extends RefCounted

const PLAYER_X := 196.0
const GRAVITY := 1700.0
const JUMP_SPEED := -650.0
const BIOME_DISTANCE := 6500.0
const GLIDE_FALL_SPEED := 85.0
const BOOST_MULTIPLIER := 1.55
const FLOCK_GAP := 64.0
const WIND_CEILING := -270.0
const WIND_RISE_SPEED := -155.0
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
var obstacle_wait := 2.1
var obstacles: Array[Dictionary] = []
var pickups: Array[Dictionary] = []
var jump_buffer := 0.0
var last_event := ""
var event_id := 0
var field_width := 1152.0

func reset() -> void:
	state = "running"
	time = 0.0
	distance = 0.0
	y = 0.0
	velocity = 0.0
	score = 0
	passed = 0
	gems = 0
	combo = 0
	hit_time = 0.0
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
	trail = [{"distance":0.0, "y":0.0, "velocity":0.0, "air_time":0.0, "landing_time":0.0}]
	gusts.clear()
	gust_wait = 380.0
	riding_gust = false
	obstacles.clear()
	pickups.clear()
	last_event = ""
	event_id += 1

func speed() -> float:
	var base := minf(580.0, 320.0 + distance / 450.0)
	return base * BOOST_MULTIPLIER if boosting() else base

func boosting() -> bool:
	return character == "wolf" and boost_held and state == "running"

func max_jumps() -> int:
	return 2 if character == "aion" else 1

func release_controls() -> void:
	jump_held = false
	boost_held = false
	gliding = false
	riding_gust = false
	jump_buffer = 0.0

func biome() -> int:
	return int(distance / BIOME_DISTANCE) % 2

func jump() -> void:
	if state != "running": return
	if y < 0.0 and character == "aion" and jumps_used < 2:
		velocity = JUMP_SPEED
		jumps_used += 1
		air_time = 0.0
		jump_buffer = 0.0
		event("double_jump")
	else:
		jump_buffer = 0.12

func event(value: String) -> void:
	last_event = value
	event_id += 1

# Sample the leader's actual path at the follower's world coordinate. A fixed
# spatial gap stays correct as speed changes, including mid-jump speed changes.
func flock_pose(index: int) -> Dictionary:
	var target := distance - FLOCK_GAP * (index + 1)
	if trail.is_empty(): return {"y":0.0, "velocity":0.0, "air_time":0.0, "landing_time":0.0}
	if target <= float(trail[0].distance): return trail[0].duplicate()
	for i in range(1, trail.size()):
		var right: Dictionary = trail[i]
		if float(right.distance) < target: continue
		var left: Dictionary = trail[i - 1]
		var weight := inverse_lerp(float(left.distance), float(right.distance), target)
		var pose := {}
		for key in ["y", "velocity", "air_time", "landing_time"]:
			pose[key] = lerpf(float(left[key]), float(right[key]), weight)
		return pose
	return trail[-1].duplicate()

func record_trail() -> void:
	trail.append({"distance":distance, "y":y, "velocity":velocity, "air_time":air_time, "landing_time":landing_time})
	while trail.size() > 2 and float(trail[1].distance) < distance - FLOCK_GAP * 2.0 - 32.0:
		trail.pop_front()

func gust_strength() -> float:
	if y >= -24.0: return 0.0
	for gust in gusts:
		var across := absf(PLAYER_X - float(gust.x)) / (float(gust.width) * 0.5)
		if across < 1.0: return 0.55 + (1.0 - across) * 0.45
	return 0.0

func advance_gusts(movement: float) -> void:
	for gust in gusts: gust.x -= movement
	gusts = gusts.filter(func(g): return float(g.x) + float(g.width) * 0.5 > -80.0)
	if character != "owl": return
	gust_wait -= movement
	if gust_wait <= 0.0:
		gusts.append({"x":field_width + 150.0, "width":rng.randf_range(240.0, 310.0)})
		gust_wait = rng.randf_range(1350.0, 2150.0)

func step(dt: float) -> void:
	if state in ["ice", "fire"]:
		gliding = false
		riding_gust = false
		hit_time += dt
		return
	if state != "running" or dt <= 0.0 or dt > 0.05:
		return
	time += dt
	landing_time = maxf(0.0, landing_time - dt)
	var movement := speed() * dt
	advance_gusts(movement)
	invulnerable = maxf(0.0, invulnerable - dt)
	if jump_buffer > 0.0 and y >= 0.0:
		velocity = JUMP_SPEED
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
		velocity = move_toward(velocity, WIND_RISE_SPEED, 850.0 * gust_strength() * dt)
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
	record_trail()
	if biome() != old_biome:
		event("biome")
	obstacle_wait -= dt
	if obstacle_wait <= 0.0:
		var kind := "ice" if rng.randf() < (0.78 if biome() else 0.22) else "fire"
		obstacles.append({"x": field_width + 60.0, "kind": kind, "counted": false})
		# A whole flight fits between every pair even at maximum speed.
		obstacle_wait = rng.randf_range(1.30, 1.95)
		pickups.append({"x": field_width + 65.0, "y": -113.0, "taken": false})
	for obstacle in obstacles:
		obstacle.x -= movement
		# Body only: decorative tail, coat, gills and particles never cause a hit.
		if invulnerable <= 0.0 and obstacle.x + 20.0 > PLAYER_X - 15.0 and obstacle.x - 20.0 < PLAYER_X + 15.0 and y > -49.0:
			if character == "sheep" and sheep_count > 1:
				sheep_count -= 1
				invulnerable = 1.1
				obstacle.counted = true
				event("sheep_saved")
				continue
			state = obstacle.kind
			hit_time = 0.0
			event(state)
			return
		if not obstacle.counted and obstacle.x + 20.0 < PLAYER_X - 15.0:
			obstacle.counted = true
			passed += 1
			combo += 1
			event("clear")
	for pickup in pickups:
		pickup.x -= movement
		if not pickup.taken and absf(pickup.x - PLAYER_X) < 34.0 and absf(pickup.y - (y - 35.0)) < 43.0:
			pickup.taken = true
			gems += 1
			event("gem")
	obstacles = obstacles.filter(func(o): return o.x > -90.0)
	pickups = pickups.filter(func(o): return o.x > -90.0 and not o.taken)
	score = int(distance / 32.0) + passed * 10 + gems * 25
