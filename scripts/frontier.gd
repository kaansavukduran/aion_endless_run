class_name RunnerFrontier
extends RefCounted

const RETURN_DURATION := 1.25
var return_start_speed := 0.0
var phase := "run"
var pending_level := 0
var milestone := 0
var stage_time := 0.0
var chase_distance := 0.0
var clock := 0.0
var hp := 0
var max_hp := 0
var player_hp := 3
var boss_x := 950.0
var boss_y := -110.0
var warning := ""
var warning_time := 0.0
var pattern_wait := 1.2
var last_pattern := "high"
var shoot_held := false
var shot_cooldown := 0.0
var shot_flash := 0.0
var shots_fired := 0
var hits := 0
var wins := 0
var projectiles: Array[Dictionary] = []
var plants: Array[Dictionary] = []
var plant_wait := 28.0
var saved_powers := {}
const SHOT_DURATION := 0.30
const SHOT_CADENCE := 0.32
const MUZZLES = preload("res://assets/PIXEL-HEROES-PROVENANCE.json")
var boss_kind := 0
var pattern := "high"
var pattern_bag: Array[String] = []
var pending_shot := -1.0
var salvo: Array[Dictionary] = []
var attacks_cast := 0
var rage := false
var cast_flash := 0.0


func active() -> bool: return phase != "run"

func reset() -> void:
	phase = "run"
	pending_level = 0
	milestone = 0
	stage_time = 0.0
	chase_distance = 0.0
	clock = 0.0
	hp = 0
	max_hp = 0
	player_hp = 3
	warning = ""
	warning_time = 0.0
	pattern_wait = 1.2
	shoot_held = false
	shot_cooldown = 0.0
	shot_flash = 0.0
	shots_fired = 0
	hits = 0
	wins = 0
	projectiles.clear()
	plants.clear()
	plant_wait = 28.0
	saved_powers.clear()
	boss_kind = 0
	pattern_bag.clear()
	salvo.clear()
	pending_shot = -1
	attacks_cast = 0
	cast_flash = 0
	rage = false

func request_boss(level: int) -> void:
	if not active(): pending_level = maxi(pending_level,level)

func begin(world) -> void:
	milestone = pending_level
	boss_kind = posmod(milestone/10-1,3)
	pattern_bag.clear()
	salvo.clear()
	pending_shot = -1
	attacks_cast = 0
	cast_flash = 0
	rage = false
	pending_level = 0
	phase = "intro"
	stage_time = 0.0
	clock = 0.0
	chase_distance = world.travel_distance()
	max_hp = 36 + mini(36,maxi(0,milestone/10-1)*6)
	hp = max_hp
	player_hp = 3
	boss_x = world.field_width + 160.0
	boss_y = -110.0
	pattern_wait = 1.1
	warning = ""
	warning_time = 0.0
	shoot_held = false
	shot_flash = 0.0
	shot_cooldown = 0.0
	projectiles.clear()
	plants.clear()
	world.obstacles.clear()
	world.pickups.clear()
	world.sheep_pickups.clear()
	world.gusts.clear()
	world.adventure.heart_time = minf(world.adventure.heart_time,1.4)
	world.adventure.enemies.clear()
	world.adventure.items.clear()
	saved_powers = world.adventure.powers.duplicate()
	for key in world.adventure.powers: world.adventure.powers[key] = 0.0
	world.release_controls()
	world.adventure.attack_time = 0.0
	world.adventure.roll_time = 0.0
	world.y = 0.0
	world.velocity = 0.0
	world.invulnerable = 1.0
	world.event("boss_intro")

func finish(world) -> void:
	phase = "run"
	shoot_held = false
	pending_shot = -1
	salvo.clear()
	projectiles.clear()
	for key in saved_powers: world.adventure.powers[key] = saved_powers[key]
	saved_powers.clear()
	world.adventure.last_spawn_distance = world.distance
	world.adventure.spawn_gap = 1100.0
	world.obstacle_wait = 2.5
	world.adventure.ambient_gnome_wait = maxf(world.adventure.ambient_gnome_wait,8.0)
	world.adventure.item_wait = maxf(world.adventure.item_wait,5.0)
	world.invulnerable = 1.3
	world.release_controls()
	# One continuous travel coordinate for scenery, strides and follower history.
	world.boss_travel_offset = chase_distance-world.distance
	if hp==0: world.adventure.offer_fragaria(world,milestone)
	world.event("boss_return")

func step_weapon(world,dt: float) -> void:
	if phase not in ["run","fight"]:return
	shot_cooldown=maxf(0.0,shot_cooldown-dt)
	shot_flash=maxf(0.0,shot_flash-dt)
	if pending_shot>=0:
		pending_shot-=dt
		if pending_shot<=0:
			pending_shot=-1
			emit_hero_shot(world)
	if shoot_held:fire(world)

func fire(world) -> bool:
	if world.state!="running" or phase not in ["run","fight"] or world.adventure.hugging() or shot_cooldown>0 or world.adventure.ducking(world):return false
	shot_cooldown=SHOT_CADENCE
	shot_flash=SHOT_DURATION
	pending_shot=0.075
	return true

func emit_hero_shot(world) -> void:
	var muzzle: Array = MUZZLES.data.muzzles[world.character]
	var origin := Vector2(world.PLAYER_X+float(muzzle[0]),world.y+float(muzzle[1])+(14 if world.charging else 0))
	shots_fired += 1
	if not active() and world.adventure.lightning_charges>0:world.adventure.cast_lightning(world)
	# Energy bolts leave the measured muzzle, then gently converge on the core.
	var vertical := 0.0 # Every shot travels straight forward; no automatic boss aiming.
	projectiles.append({"owner":"hero","kind":"energy","x":origin.x,"y":origin.y,"vx":1050.0,"vy":vertical,"r":12.0})
	world.event("shot")

func gun_frame(frame_count: int) -> int:
	return clampi(int((SHOT_DURATION-shot_flash)/SHOT_DURATION*frame_count),0,frame_count-1)

func hit_player(world) -> bool:
	if phase != "fight" or world.invulnerable > 0.0: return false
	world.cancel_charge()
	player_hp -= 1
	world.invulnerable = 1.1
	world.event("boss_player_hit")
	if player_hp <= 0:
		world.state = "bonk"
		world.death_cause = "projectile"
		world.hit_time = 0.0
		world.event("bonk")
	return true

func update_projectiles(world,dt: float) -> void:
	var body: Rect2 = world.adventure.body_rect(world)
	for p in projectiles:
		var previous_x: float=p.x
		p.x += p.vx*dt
		p.y += p.vy*dt
		if p.has("target_y"):
			p.age += dt
			p.y = lerpf(p.start_y,p.target_y,smoothstep(0.0,0.30,p.age))
		if p.owner == "hero":
			if phase=="run":
				var sweep:=Rect2(previous_x-p.r,p.y-p.r,maxf(1,p.x-previous_x)+p.r*2,p.r*2)
				for enemy in world.adventure.enemies:
					if enemy.hp>0 and sweep.intersects(world.adventure.enemy_rect(enemy)):
						world.adventure.hit_enemy(world,enemy,1,false)
						p.x=-1000.0
						break
				if p.x>-100:
					for plant in plants:
						if plant.hp>0 and sweep.intersects(Rect2(plant.x-25,-68,50,68)):
							plant.hp=0
							world.adventure.reward_enemy(world,false)
							world.event("enemy_down")
							p.x=-1000.0
							break
			var target := boss_rect()
			if phase == "fight" and target.grow(p.r).has_point(Vector2(p.x,p.y)):
				p.x = -1000.0
				hp = maxi(0,hp-1)
				hits += 1
				world.event("boss_hit")
				if hp == 0:
					phase = "victory"
					pending_shot = -1
					salvo.clear()
					stage_time = 0.0
					wins += 1
					world.adventure.award_xp(100)
					world.adventure.bonus_score += 500 + milestone*10
					world.event("boss_won")
		else:
			if p.x < world.PLAYER_X+45 and p.x > world.PLAYER_X-45 and body.grow(p.r).has_point(Vector2(p.x,p.y)):
				p.x = -1000.0
				if active(): hit_player(world)
				else: world.take_hit("fire")
	projectiles = projectiles.filter(func(p):return p.x > -100 and p.x < world.field_width+250)
	if phase == "victory": projectiles.clear()

func boss_rect() -> Rect2:
	var size := Vector2(168,190) if boss_kind == 0 else (Vector2(230,110) if boss_kind == 1 else Vector2(184,168))
	return Rect2(Vector2(boss_x,boss_y)-size*0.5,size)

func choose_pattern(world) -> String:
	var bags := [["high","low","burst"],["arc","dive","ribbon"],["seeds","sweep","hop"]]
	if pattern_bag.is_empty():
		pattern_bag.assign(bags[boss_kind])
		for i in range(pattern_bag.size()-1,0,-1):
			var n: int = world.rng.randi_range(0,i)
			var old: String = pattern_bag[i]
			pattern_bag[i] = pattern_bag[n]
			pattern_bag[n] = old
	return pattern_bag.pop_back()

func cast_pattern(world) -> void:
	attacks_cast += 1
	cast_flash = 0.45
	var low := warning == "low"
	var count := 3 if pattern in ["burst","ribbon","seeds"] else (2 if pattern in ["arc","sweep"] else 1)
	for i in count:
		salvo.append({"wait":float(i)*0.18,"low":low,"kind":"seed" if boss_kind==2 and low else ("ember" if low else "bolt"),"speed":450.0+float(boss_kind)*25+(45.0 if rage else 0.0)})
	world.event("boss_cast")

func step_boss(world,dt: float) -> void:
	clock += dt
	stage_time += dt
	var chase_speed := 380.0+minf(float(milestone),60.0)
	if phase == "return": chase_speed = lerpf(return_start_speed, world.speed(), smoothstep(0.0, RETURN_DURATION, stage_time))
	chase_distance += chase_speed*dt
	cast_flash = maxf(0.0,cast_flash-dt)
	rage = hp>0 and hp<=max_hp/2
	var reach: float = world.field_width-180.0
	var wave := sin(clock*(1.2 if boss_kind==1 else 0.85))
	var target_x: float = reach+wave*(90.0 if boss_kind==1 else 55.0)
	if pattern=="dive" and warning_time>0.0: target_x -= sin((1.0-warning_time/0.95)*PI)*160.0
	boss_x = move_toward(boss_x,maxf(world.PLAYER_X+260,target_x),dt*(410.0 if boss_kind==1 else 290.0))
	boss_y = -118.0+sin(clock*(2.1 if boss_kind==1 else 1.4))*(48.0 if boss_kind==1 else 25.0)
	if boss_kind==2: boss_y = -98.0-absf(sin(clock*1.5))*26.0
	if pattern=="hop" and warning_time>0: boss_y -= sin((1.0-warning_time/0.95)*PI)*65.0
	if phase == "intro":
		if stage_time >= 1.6:
			phase = "fight"
			stage_time = 0.0
			world.adventure.heart_time = 0.0
			world.adventure.celebration_time = 0.0
			world.event("boss_fight")
		return
	if phase == "victory":
		if stage_time >= 1.6:
			phase = "return"
			stage_time = 0.0
			return_start_speed = 380.0+minf(float(milestone),60.0)
			for key in saved_powers: world.adventure.powers[key] = saved_powers[key]
			shoot_held = false
			world.event("boss_returning")
		return
	if phase == "return":
		if stage_time >= RETURN_DURATION: finish(world)
		return
	if warning_time > 0.0:
		warning_time = maxf(0.0,warning_time-dt)
		if warning_time <= 0.0:
			cast_pattern(world)
			warning = ""
	else:
		pattern_wait -= dt
		if pattern_wait <= 0.0:
			pattern = choose_pattern(world)
			warning = "low" if pattern in ["low","arc","seeds","hop"] else "high"
			last_pattern = warning
			warning_time = 0.95
			# One lane per salvo; reserve time for its last orb to clear the hero.
			pattern_wait = world.rng.randf_range(1.15,1.65) if rage else world.rng.randf_range(1.65,2.2)
			world.event("boss_warn_"+warning)
	for shot in salvo:
		shot.wait -= dt
		if shot.wait <= 0.0:
			projectiles.append({"owner":"boss","kind":shot.kind,"x":boss_x-80,"y":boss_y,"start_y":boss_y,"target_y":-14.0 if shot.low else -82.0,"age":0.0,"vx":-shot.speed,"vy":0.0,"r":12.0})
	salvo = salvo.filter(func(s):return s.wait>0)
	update_projectiles(world,dt)

func step_plants(world,dt: float,movement: float) -> void:
	plant_wait -= dt
	if plant_wait <= 0.0:
		var crowded: bool = world.obstacles.any(func(o):return o.x > world.field_width-420) or world.adventure.enemies.any(func(e):return e.hp > 0 and e.x > world.field_width-420)
		if not crowded:
			plants.append({"x":world.field_width+90.0,"age":0.0,"shot":false,"hp":1,"hurt":0.0,"last_swing":-1})
			world.adventure.last_spawn_distance = world.distance
			world.adventure.spawn_gap = 1200.0
			world.obstacle_wait = 2.4
			plant_wait = world.rng.randf_range(35.0,70.0)
		else: plant_wait = world.rng.randf_range(0.5,1.2)
	for plant in plants:
		plant.x -= movement
		plant.age += dt
		plant.hurt = maxf(0.0,plant.hurt-dt)
		if plant.hp <= 0: continue
		if not plant.shot and plant.x-world.PLAYER_X < 720:
			plant.shot = true
			plant.age = 0.0
		if plant.shot and plant.age >= 0.9 and plant.age-dt < 0.9:
			projectiles.append({"owner":"plant","kind":"ember","x":plant.x-35.0,"y":-36.0,"vx":-movement/dt-160.0,"vy":0.0,"r":10.0})
			world.event("plant_fire")
		var stomped := false
		var rect := Rect2(plant.x-25,-68,50,68)
		if world.adventure.attack_active() and plant.last_swing != world.adventure.swing_id and world.adventure.attack_rect(world).intersects(rect):
			plant.last_swing = world.adventure.swing_id
			plant.hp = 0
			plant.hurt = 0.30
		if world.y < 0 and world.velocity > 0 and world.y > -78 and absf(plant.x-world.PLAYER_X)<35:
			plant.hp = 0
			world.velocity = -455
			world.y = -70
			stomped = true
		if plant.hp <= 0:
			world.adventure.reward_enemy(world, stomped)
			world.event("enemy_down")
		elif world.adventure.body_rect(world).intersects(rect) and plant.hurt <= 0.0: world.take_hit("bonk","enemy")
	plants = plants.filter(func(p):return p.x > -100 and p.hp > 0)
	update_projectiles(world,dt)
