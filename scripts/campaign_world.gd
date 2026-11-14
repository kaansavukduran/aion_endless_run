class_name AionCampaignWorld
extends RefCounted

## Finite arcade rules. Coordinates are world positions; floor Y is zero.
## The old RunnerWorld, its saves and its automatic-run rules are independent.
const HEROES := ["aion", "sheep", "wolf", "owl", "rabbit", "eren"]
const COLORS := {"aion":"ef86b7", "sheep":"f5d6a6", "wolf":"aa84d2", "owl":"e8a34f", "rabbit":"f08d55", "eren":"58c4bb"}
const HERO_ART=preload("res://assets/PIXEL-HEROES-PROVENANCE.json")
const ABILITY_ART=preload("res://assets/POLISH-PROVENANCE.json")
const STAGES := {
	"shore": {"length":2600., "biome":4, "title":"arc_shore", "next":"quay"},
	"quay": {"length":2600., "biome":4, "title":"arc_quay", "next":"fork_one"},
	"canopy": {"length":2200., "biome":4, "title":"arc_canopy", "next":"fork_two"},
	"water": {"length":5000., "biome":2, "title":"arc_water", "next":"relay"},
	"terrace": {"length":3600., "biome":4, "title":"arc_terrace", "next":"relay"},
	"roots": {"length":3600., "biome":2, "title":"arc_roots", "next":"relay"},
	"relay": {"length":3200., "biome":3, "title":"arc_relay", "next":"arena"},
	"arena": {"length":1800., "biome":4, "title":"arc_arena", "next":"complete"}
}
var character := "aion"
var state := "briefing"
var section := "shore"
var player := Vector2(140, 0)
var velocity := Vector2.ZERO
var facing := 1
var move_axis := Vector2.ZERO
var time := 0.0
var run_seed := 7719
var walk_distance := 0.0
var hp := 3
var max_hp := 3
var grenades := 5
var score := 0
var kills := 0
var shots := 0
var rescued: Array[String] = []
var awarded: Dictionary = {}
var taken: Dictionary = {}
var route: Array[String] = []
var checkpoint := "shore"
var checkpoint_ready := false
var travel_target := ""
var completed := false
var victory_time := 0.0
var death_time := 0.0
var death_cause := "enemy"
var invulnerable := 0.0
var hurt_time := 0.0
var fire_held := false
var melee_latched := false
var melee_time := 0.0
var melee_variant := 0
var melee_target := ""
var melee_hit_done := true
var fire_time := 0.0
var shot_flash := 0.0
var grenade_time := 0.0
var jump_held := false
var jumps := 0
var flap_count := 0
var flap_time := 0.0
var gliding := false
var charging := false
var charge_time := 0.0
var boost_held := false
var air_time := 0.0
var weapon := "pistol"
var ammunition := 0
var shield := 0
var enemies: Array[Dictionary] = []
var bullets: Array[Dictionary] = []
var bombs: Array[Dictionary] = []
var blasts: Array[Dictionary] = []
var pickups: Array[Dictionary] = []
var npcs: Array[Dictionary] = []
var platforms: Array[Rect2] = []
var pits: Array[Vector2] = []
var crates: Array[Dictionary] = []
var gates: Array[Dictionary] = []
var mount := {"available":false, "ridden":false, "x":0., "hp":4}
var trail: Array[Dictionary] = []
var flock := 1
var boss := {"active":false, "hp":90, "max_hp":90, "x":1300., "y":0., "clock":0., "attack":0, "windup":0., "wait":1.4, "phase":1}
var notice := ""
var notice_time := 0.0
var pending_events: Array[String] = []

func biome() -> int: return int(STAGES[section].biome)
func length() -> float: return float(STAGES[section].length)
func charge_ratio() -> float: return clampf(charge_time / 1.2, 0., 1.)
func floor_at(x: float) -> float:
	for pit in pits:
		if x > pit.x and x < pit.y: return 1000.
	return 0.
func crossing_floor(x: float,old_y: float,new_y: float,falling_speed: float) -> float:
	var support:=floor_at(x)
	for platform in platforms:
		if x>=platform.position.x-9. and x<=platform.end.x+9. and old_y<=platform.position.y+.01 and new_y>=platform.position.y and falling_speed>=0.:support=minf(support,platform.position.y)
	return support
func grounded() -> bool:
	if bool(mount.ridden): return player.y >= -42. - .1 and absf(velocity.y) < 1.
	if absf(player.y) < .1 and floor_at(player.x) == 0.: return true
	for platform in platforms:
		if player.x >= platform.position.x - 9. and player.x <= platform.end.x + 9. and absf(player.y - platform.position.y) < .1: return true
	return false

func begin(hero: String) -> void:
	character = hero if hero in HEROES else "aion"
	hp = max_hp; grenades = 5; score = 0; kills = 0; shots = 0
	time=0.;walk_distance=0.;victory_time=0.
	var run_rng:=RandomNumberGenerator.new();run_rng.randomize();run_seed=run_rng.randi_range(1,2000000000)
	rescued.clear(); awarded.clear(); taken.clear(); route.clear()
	completed = false; flock = 1; weapon = "pistol"; ammunition = 0; shield = 0
	load_section("shore")
	state = "briefing"

func stop_inputs() -> void:
	move_axis = Vector2.ZERO; fire_held = false; jump_held = false
	charging = false; charge_time = 0.; boost_held = false; gliding = false
	melee_latched = false

func spawn_enemy(kind: String, x: float, y: float, index: int, mini: bool = false) -> void:
	enemies.append({"id":section+":enemy:"+str(index), "kind":kind, "x":x, "y":y, "home":Vector2(x,y), "hp":12 if mini else 1, "max_hp":12 if mini else 1, "mini":mini, "age":0., "wait":1.1+float(index%4)*.23, "windup":0., "attacks":0, "facing":-1, "active":false, "defeated":false})

func load_section(id: String) -> void:
	assert(STAGES.has(id))
	section = id; checkpoint = id; checkpoint_ready = true
	player = Vector2(140, 0); velocity = Vector2.ZERO; facing=1; stop_inputs()
	jumps = 0; flap_count = 0; air_time = 0.; fire_time = 0.; melee_time = 0.
	melee_target="";melee_hit_done=true
	invulnerable = 1.2; hurt_time = 0.; flap_time = 0.
	enemies.clear(); bullets.clear(); bombs.clear(); blasts.clear(); pickups.clear()
	platforms.clear(); pits.clear(); crates.clear(); gates.clear(); npcs.clear(); trail.clear()
	mount = {"available":false, "ridden":false, "x":0., "hp":4}
	boss = {"active":false, "engaged":false, "hp":90, "max_hp":90, "x":length()-420., "y":0., "clock":0., "attack":0, "windup":0., "wait":1.4, "phase":1}
	var types: Array = ["gnome", "beetle", "seed", "crow"]
	if section in ["quay", "relay"]: types = ["seed", "gnome", "drone", "beetle"]
	elif section in ["canopy", "terrace"]: types = ["crow", "moth", "drone", "seed"]
	elif section in ["water", "roots"]: types = ["slime", "seed", "beetle", "wisp"]
	if section != "arena":
		var layout_rng:=RandomNumberGenerator.new();layout_rng.seed=run_seed+abs(section.hash())
		var spawn_x:=500.;var spawn_index:=0
		while spawn_x<length()-260.:
			var kind: String = str(types[spawn_index] if spawn_index<types.size() else types[layout_rng.randi_range(0,types.size()-1)])
			spawn_enemy(kind, spawn_x, -115. if kind in ["crow","moth","wisp","drone"] else 0., spawn_index)
			spawn_x+=layout_rng.randf_range(125.,270.);spawn_index+=1
		for i in range(1, int(length()/650.)):
			var x: float = float(i)*650.
			platforms.append(Rect2(x, -70., 170., 20.))
			if section in ["canopy","terrace"]: platforms.append(Rect2(x+190., -135., 150., 20.))
		for i in range(1, int(length()/1000.)):
			var x: float = float(i)*1000.+80.
			var ids: Array[String] = []
			for e in enemies:
				if float(e.home.x) >= x-500. and float(e.home.x) < x+300.: ids.append(str(e.id))
			gates.append({"x":x, "ids":ids})
		for i in range(1, int(length()/780.)):
			var x: float = i*780.+95.
			var id_key: String = section+":crate:"+str(i)
			if not taken.has(id_key): crates.append({"id":id_key, "x":x, "y":0., "kind":["arc","grenade","scatter","shield","heal","repair"][(i-1)%6], "hp":1})
		for i in range(1, int(length()/220.)):
			var key: String = section+":fruit:"+str(i)
			if not taken.has(key): pickups.append({"id":key, "x":i*220.+35., "y":-40., "kind":"fruit_"+str(i%8)})
		var npc_id: String = section+":keeper"
		npcs.append({"id":npc_id, "x":length()*.55, "y":0., "freed":rescued.has(npc_id), "variant":posmod(STAGES.keys().find(section),8)})
		if section in ["quay", "water"]:
			mount = {"available":true, "ridden":false, "x":360., "hp":4}
			var repair_key:=section+":repair"
			if not taken.has(repair_key):pickups.append({"id":repair_key,"x":length()*.72,"y":-35.,"kind":"repair"})
		if section in ["water", "terrace", "roots"]:
			spawn_enemy("warden", length()-580., 0., 99, true)
			gates.append({"x":length()-340., "ids":[section+":enemy:99"]})
		if section in ["water", "terrace"]:
			for i in range(1, int(length()/1200.)):
				var x: float = i*1200.+400.
				pits.append(Vector2(x,x+95.))
				platforms.append(Rect2(x+12.,-55.,75.,18.))
		# Grounded actors/props never begin inside an actual gap. Airborne loot
		# above a crossing rests over its reachable stepping platform instead.
		for pit in pits:
			for e in enemies:
				if e.kind not in ["crow","moth","drone","wisp"] and float(e.x)>pit.x and float(e.x)<pit.y:
					e.x = pit.x-55.; e.home.x = float(e.x)
			for crate in crates:
				if float(crate.x)>pit.x-20. and float(crate.x)<pit.y+20.: crate.x = pit.x-55.
			for item in pickups:
				if float(item.x)>pit.x and float(item.x)<pit.y: item.y = -105.
	else:
		platforms.append(Rect2(690., -75., 175., 20.))
		platforms.append(Rect2(980., -135., 150., 20.))
		boss.active = true
	state = "playing"
	notice = "arc_checkpoint"; notice_time = 2.
	pending_events.append("checkpoint")

func retry() -> void:
	hp = max_hp; grenades = maxi(3, grenades); weapon = "pistol"; ammunition = 0
	load_section(checkpoint)

func choose_route(choice: String) -> bool:
	if state == "fork_one" and choice in ["canopy", "water"]:
		if not route.has(choice): route.append(choice)
		travel_target = choice; state = "travel"; stop_inputs(); return true
	if state == "fork_two" and choice in ["terrace", "roots"]:
		if not route.has(choice): route.append(choice)
		travel_target = choice; state = "travel"; stop_inputs(); return true
	return false

func finish_travel() -> void:
	if state == "travel" and STAGES.has(travel_target): load_section(travel_target)

func jump_press() -> void:
	if state != "playing": return
	jump_held = true
	if grounded() and character in ["rabbit","eren"] and not bool(mount.ridden):
		charging = true; charge_time = 0.; return
	if grounded():
		velocity.y = -650.; jumps = 1; air_time = 0.; return
	if character == "aion" and jumps < 2:
		velocity.y = -620.; jumps += 1; air_time = 0.
	elif character == "owl" and flap_count < 3:
		velocity.y = minf(velocity.y,-300.); flap_count += 1; flap_time = .3

func jump_release(launch: bool = true) -> void:
	jump_held = false; gliding = false
	if charging:
		if launch and state == "playing":
			velocity.y = -650.*lerpf(.70,1.6,charge_ratio()); jumps = 1; air_time = 0.
		charging = false; charge_time = 0.

func close_enemy() -> Dictionary:
	for e in enemies:
		if bool(e.defeated): continue
		var dx: float = (float(e.x)-player.x)*facing
		if dx >= -12. and dx < 95. and absf(float(e.y)-player.y) < 75.: return e
	if bool(boss.active) and bool(boss.get("engaged",false)) and (float(boss.x)-player.x)*facing >= 0. and absf(float(boss.x)-player.x)<130.: return boss
	return {}

func attack_press() -> void:
	if state != "playing": return
	fire_held = true; melee_latched = false
	attack()
func attack_release() -> void: fire_held = false; melee_latched = false

func muzzle_offset() -> Vector2:
	if bool(mount.ridden):return Vector2(61,16)
	if character=="eren" and (charging or not grounded()):
		var atlas: Dictionary=ABILITY_ART.data.atlases["polish-abilities"]
		var row: int=2 if charging else 3
		var col: int=clampi(int(charge_ratio()*6),0,5) if charging else RunnerWorld.flight_frame_for(velocity.y,air_time,6)
		var f: Dictionary=atlas.frames[row][col]
		return (Vector2(f.weapon_grip[0],f.weapon_grip[1])-Vector2(f.origin[0],f.origin[1]))*float(atlas.scale[row])+Vector2(23,-5)
	var atlas: Dictionary=HERO_ART.data.atlases["pixel-"+character]
	var point: Array=atlas.frames[4 if shot_flash>0. else 3][0].muzzle
	return Vector2(point[0],point[1])+Vector2(0,14 if charging else 0)

func attack() -> void:
	if fire_time > 0. or state != "playing": return
	var close: Dictionary = close_enemy()
	if not close.is_empty() and not bool(mount.ridden):
		if melee_latched: return
		melee_latched = true; melee_variant = 1-melee_variant
		melee_time = .28; fire_time = .32
		melee_target="boss" if close==boss else str(close.id);melee_hit_done=false
		pending_events.append("melee")
		return
	melee_latched = false
	shot_flash=.18
	var muzzle:=muzzle_offset()
	var origin := player + Vector2(facing*muzzle.x,muzzle.y)
	var speed := 760.
	var rays: Array = [-.17,0.,.17] if weapon == "scatter" else [0.]
	for angle in rays:
		bullets.append({"p":origin, "v":Vector2(facing*cos(angle),sin(angle))*speed, "owner":"hero", "age":0., "kind":weapon, "damage":2 if bool(mount.ridden) else 1, "pierce":2 if weapon == "arc" else 0, "hit":[]})
	shots += 1; fire_time = .18 if weapon != "pistol" or bool(mount.ridden) else .32
	shot_flash = .18; pending_events.append("shot")
	if weapon != "pistol":
		ammunition -= 1
		if ammunition <= 0: weapon = "pistol"; ammunition = 0

func throw_grenade() -> bool:
	if state != "playing" or grenades <= 0 or grenade_time > 0.: return false
	grenades -= 1; grenade_time = .55
	bombs.append({"p":player+Vector2(facing*25.,-65.), "v":Vector2(facing*330.+velocity.x*.2,-430.), "age":0., "color":COLORS[character]})
	pending_events.append("grenade")
	return true

func interact() -> bool:
	if state != "playing": return false
	if bool(mount.ridden):
		mount.ridden = false; mount.x = player.x-60.; player.y = -62.; velocity.y = -220.; return true
	if bool(mount.available) and int(mount.hp)>0 and absf(player.x-float(mount.x))<110. and player.y > -90.:
		mount.ridden = true; player.y = -42.; velocity.y = 0.; return true
	return false

func award(id: String, points: int) -> void:
	if awarded.has(id): return
	awarded[id] = true; score += points

func damage_enemy(e: Dictionary, amount: int) -> void:
	if bool(e.defeated): return
	e.hp = int(e.hp)-amount
	if int(e.hp) > 0: return
	e.defeated = true; e.dead_age = 0.
	if not awarded.has(str(e.id)): kills += 1
	award(str(e.id),500 if bool(e.mini) else 100)
	blasts.append({"p":Vector2(float(e.x),float(e.y)-25.), "age":0., "radius":40., "color":"85d7c4"})
	pending_events.append("enemy")

func damage_boss(amount: int) -> void:
	if not bool(boss.active) or not bool(boss.get("engaged",false)): return
	boss.hp = maxi(0,int(boss.hp)-amount)
	if int(boss.hp) == 0:
		boss.active = false; completed = true; state = "victory"; victory_time = 0.; checkpoint_ready = false
		award("mission:1",3000+rescued.size()*300); stop_inputs(); pending_events.append("complete")

func damage_player(cause: String="enemy") -> void:
	if state != "playing" or invulnerable > 0.: return
	invulnerable = 1.2; hurt_time = .3
	if shield > 0: shield -= 1
	elif bool(mount.ridden):
		mount.hp = int(mount.hp)-1
		if int(mount.hp)<=0:
			mount.ridden = false; mount.available = false; player.y -= 30.; velocity.y = -260.
	elif character == "sheep" and flock > 1: flock -= 1
	else: hp -= 1
	pending_events.append("hurt")
	if hp <= 0: state = "dying";death_time=0.;death_cause=cause; stop_inputs()

func explode(bomb: Dictionary) -> void:
	var p: Vector2 = bomb.p
	blasts.append({"p":p, "age":0., "radius":135., "color":bomb.color})
	for e in enemies:
		if not bool(e.defeated) and p.distance_to(Vector2(float(e.x),float(e.y)-30.))<150.: damage_enemy(e,5)
	if bool(boss.active) and p.distance_to(Vector2(float(boss.x),float(boss.y)-70.))<200.: damage_boss(8)
	for crate in crates:
		if p.distance_to(Vector2(float(crate.x),float(crate.y)-20.))<150.: open_crate(crate)
	for npc in npcs:
		if p.distance_to(Vector2(float(npc.x),float(npc.y)-40.))<150.: rescue(npc)
	pending_events.append("blast")

func open_crate(crate: Dictionary) -> void:
	if int(crate.hp)<=0: return
	crate.hp = 0
	var id: String = str(crate.id)
	if not taken.has(id): pickups.append({"id":id,"x":float(crate.x),"y":-35.,"kind":str(crate.kind)})

func rescue(npc: Dictionary) -> void:
	if bool(npc.freed): return
	npc.freed = true
	var id: String = str(npc.id)
	if not rescued.has(id):
		rescued.append(id); award(id,300); grenades = mini(9,grenades+1)
		hp=mini(max_hp,hp+1)
		if character == "sheep": flock = mini(3,flock+1)
		pending_events.append("rescue")

func collect(item: Dictionary) -> void:
	var id: String = str(item.id)
	if taken.has(id): return
	taken[id] = true
	var kind: String = str(item.kind)
	if kind.begins_with("fruit_"): award(id,25)
	elif kind in ["scatter","arc"]: weapon = kind; ammunition = 36
	elif kind == "grenade": grenades = mini(9,grenades+3)
	elif kind == "shield": shield = mini(3,shield+2)
	elif kind == "heal": hp = mini(max_hp,hp+1)
	elif kind == "repair": mount.hp = mini(4,int(mount.hp)+2)
	else: return
	pending_events.append("pickup")

func gate_closed(gate: Dictionary) -> bool:
	for e in enemies:
		if str(e.id) in gate.ids and not bool(e.defeated): return true
	return false

func enemy_shot(e: Dictionary, fan: bool = false) -> void:
	e.flash=.24
	if e.kind in ["gnome","beetle","slime"]:
		e.dash=.45 if e.kind=="gnome" else .65
		e.dash_direction=signf(player.x-float(e.x));return
	if e.kind=="crow":
		e.dive=.70;e.dive_start=Vector2(float(e.x),float(e.y));e.dive_target=player+Vector2(0,-25.);return
	var origin := Vector2(float(e.x),float(e.y)-32.)
	if e.kind=="moth":
		bullets.append({"p":origin,"v":Vector2(signf(player.x-origin.x)*80.,50.),"owner":"enemy","age":0.,"kind":"spore","damage":1,"pierce":0,"hit":[],"gravity":180.});return
	if e.kind=="warden" and int(e.attacks)%2==1:
		bullets.append({"p":Vector2(float(e.x),-16.),"v":Vector2(signf(player.x-float(e.x))*240.,0.),"owner":"enemy","age":0.,"kind":"wave","damage":1,"pierce":0,"hit":[]});return
	var direction: Vector2 = (player+Vector2(0,-36)-origin).normalized()
	if direction.length_squared()<.5: direction = Vector2.LEFT
	var angles: Array = [-.22,0.,.22] if fan else ([-.12,.12] if e.kind=="drone" else [0.])
	for angle in angles: bullets.append({"p":origin,"v":direction.rotated(angle)*210.,"owner":"enemy","age":0.,"kind":"seed","damage":1,"pierce":0,"hit":[]})

func step_enemies(dt: float) -> void:
	for e in enemies:
		if bool(e.defeated): e.dead_age = float(e.get("dead_age",0.))+dt; continue
		if absf(float(e.x)-player.x)>780. and not bool(e.active): continue
		e.active = true; e.age = float(e.age)+dt
		e.flash=maxf(0.,float(e.get("flash",0.))-dt)
		e.facing = -1 if float(e.x)>player.x else 1
		var dx: float = player.x-float(e.x)
		var flying: bool = e.kind in ["crow","moth","drone","wisp"]
		if flying:
			e.y = float(e.home.y)+sin(float(e.age)*2.2)*20.
			if absf(dx)>240.: e.x = float(e.x)+signf(dx)*82.*dt
		elif absf(dx)>155. and e.kind != "seed":
			var candidate: float = clampf(float(e.x)+signf(dx)*(58. if bool(e.mini) else 76.)*dt,60.,length()-80.)
			if floor_at(candidate)==0.: e.x = candidate
		if e.kind in ["gnome","slime"] and absf(dx)>75.:
			var next_x: float=float(e.x)+signf(dx)*62.*dt
			if floor_at(next_x)==0.:e.x=next_x
		if e.kind=="slime":e.y=-absf(sin(float(e.age)*3.))*38.
		if float(e.get("dash",0.))>0.:
			e.dash=maxf(0.,float(e.dash)-dt)
			var next_x: float=float(e.x)+float(e.dash_direction)*(260. if e.kind=="beetle" else 220.)*dt
			if floor_at(next_x)==0.:e.x=next_x
			if absf(player.x-float(e.x))<34. and absf(player.y-float(e.y))<55.:damage_player()
		if float(e.get("dive",0.))>0.:
			e.dive=maxf(0.,float(e.dive)-dt)
			var phase: float=1.-float(e.dive)/.7
			var p: Vector2=Vector2(e.dive_start).lerp(Vector2(e.dive_target),minf(1.,phase*2.)) if phase<.5 else Vector2(e.dive_target).lerp(Vector2(float(e.dive_target.x)-65.,float(e.home.y)),(phase-.5)*2.)
			e.x=p.x;e.y=p.y
			if p.distance_to(player+Vector2(0,-25.))<35.:damage_player()
		if float(e.windup)>0.:
			e.windup = maxf(0.,float(e.windup)-dt)
			if float(e.windup)==0.:
				enemy_shot(e,bool(e.mini)); e.attacks = int(e.attacks)+1
				e.wait = 1.8 if bool(e.mini) else 2.2+float(int(e.attacks)%3)*.25
		else:
			e.wait = float(e.wait)-dt
			if float(e.wait)<=0. and absf(dx)<(150. if e.kind=="gnome" else 600.):
				e.windup = .85 if bool(e.mini) else .65
		if absf(dx)<35. and absf(float(e.y)-player.y)<55. and float(e.windup)>.03 and float(e.windup)<.27: damage_player()

func step_boss(dt: float) -> void:
	if not bool(boss.active) or not bool(boss.get("engaged",false)): return
	boss.clock = float(boss.clock)+dt
	boss.phase = 1 + int(int(boss.hp)<60) + int(int(boss.hp)<30)
	boss.x = length()-420.+sin(float(boss.clock)*.65)*75.
	boss.y = 0. # A walking root machine stays on its actual collision floor.
	if float(boss.windup)>0.:
		boss.windup = maxf(0.,float(boss.windup)-dt)
		if float(boss.windup)==0.:
			var attack: int = int(boss.attack)%3
			if attack == 0:
				for offset in [-.32,-.16,0.,.16,.32]:
					var aim := (player+Vector2(0,-42)-Vector2(float(boss.x)-55.,-90.)).normalized().rotated(offset)
					bullets.append({"p":Vector2(float(boss.x)-55.,-90.),"v":aim*230.,"owner":"enemy","age":0.,"kind":"seed","damage":1,"pierce":0,"hit":[]})
			elif attack == 1:
				bullets.append({"p":Vector2(float(boss.x)-60.,-16.),"v":Vector2(-320.,0.),"owner":"enemy","age":0.,"kind":"wave","damage":1,"pierce":0,"hit":[]})
			else:
				for i in 2: spawn_enemy("drone",float(boss.x)-120.-i*110.,-135.-i*25.,200+int(boss.attack)*2+i)
			boss.attack = int(boss.attack)+1; boss.wait = 2.15-float(int(boss.phase)-1)*.25
	else:
		boss.wait = float(boss.wait)-dt
		if float(boss.wait)<=0.: boss.windup = .95

func step_bullets(dt: float) -> void:
	for b in bullets:
		if b.has("gravity"):b.v=Vector2(b.v)+Vector2(0,float(b.gravity)*dt)
		b.age = float(b.age)+dt; b.p = Vector2(b.p)+Vector2(b.v)*dt
		if b.owner == "enemy":
			if float(b.p.y)>0. and floor_at(float(b.p.x))==0.:b.age=99.;continue
			if Vector2(b.p).distance_to(player+Vector2(0,-37.))<30.: damage_player(); b.age = 99.
			continue
		for e in enemies:
			if bool(e.defeated) or str(e.id) in b.hit: continue
			var radius: float = 58. if bool(e.mini) else 34.
			if Vector2(b.p).distance_to(Vector2(float(e.x),float(e.y)-30.))<radius:
				damage_enemy(e,int(b.damage)); b.hit.append(str(e.id)); b.pierce = int(b.pierce)-1
				if int(b.pierce)<0: b.age = 99.; break
		if float(b.age)>3.:continue
		if bool(boss.active) and Vector2(b.p).distance_to(Vector2(float(boss.x),float(boss.y)-75.))<105. and not "boss" in b.hit:
			damage_boss(int(b.damage)); b.hit.append("boss"); b.age = 99.
		if float(b.age)>3.:continue
		for crate in crates:
			if int(crate.hp)>0 and Vector2(b.p).distance_to(Vector2(float(crate.x),float(crate.y)-24.))<30.: open_crate(crate); b.age = 99.;break
		if float(b.age)>3.:continue
		for npc in npcs:
			if not bool(npc.freed) and Vector2(b.p).distance_to(Vector2(float(npc.x),float(npc.y)-35.))<35.: rescue(npc); b.age = 99.
	bullets = bullets.filter(func(b):return float(b.age)<3. and float(b.p.x)>-80. and float(b.p.x)<length()+100.)

func step(dt: float) -> void:
	if state=="dying":
		dt=clampf(dt,0.,.05);death_time+=dt
		var old_y:=player.y
		velocity.x=0.;velocity.y+=1700.*dt;player.y+=velocity.y*dt
		var support:=crossing_floor(player.x,old_y,player.y,velocity.y)
		if player.y>=support and velocity.y>=0.:player.y=support;velocity.y=0.
		if death_time>=.8 and (grounded() or player.y>180. or death_time>1.8):state="dead"
		return
	if state=="victory":
		victory_time+=clampf(dt,0.,.05);boss.clock=float(boss.clock)+clampf(dt,0.,.05)
		if victory_time>=1.2:state="complete"
		return
	if state != "playing": return
	dt = clampf(dt,0.,.05)
	time += dt
	for property in ["invulnerable","hurt_time","fire_time","shot_flash","melee_time","grenade_time","flap_time","notice_time"]: set(property,maxf(0.,float(get(property))-dt))
	if not melee_hit_done and melee_time<=.14:
		melee_hit_done=true
		if melee_target=="boss":
			if absf(float(boss.x)-player.x)<150.:damage_boss(2)
		else:
			for enemy in enemies:
				if str(enemy.id)==melee_target and absf(float(enemy.x)-player.x)<125. and absf(float(enemy.y)-player.y)<85.:damage_enemy(enemy,2)
	var on_floor := grounded()
	if charging: charge_time = minf(1.2,charge_time+dt)
	var speed: float = 235.*(1.55 if character == "wolf" and boost_held else 1.)*(1.35 if bool(mount.ridden) else 1.)
	velocity.x = move_axis.x*speed*(.3 if charging else 1.)
	if absf(move_axis.x)>.1: facing = 1 if move_axis.x>0. else -1
	var old_x: float = player.x
	player.x = clampf(player.x+velocity.x*dt,35.,length()-90.)
	for gate in gates:
		if gate_closed(gate) and old_x<=float(gate.x): player.x = minf(player.x,float(gate.x))
	walk_distance += absf(player.x-old_x)
	var old_y: float = player.y
	if bool(mount.ridden):
		mount.x = player.x
		velocity.y += 1700.*dt; player.y += velocity.y*dt
		if player.y >= -42.: player.y = -42.; velocity.y = 0.; jumps = 0; air_time = 0.
		else: air_time += dt
	else:
		gliding = character == "owl" and jump_held and velocity.y>0. and not on_floor
		velocity.y += 1700.*(.12 if gliding else 1.)*dt
		if gliding: velocity.y = minf(velocity.y,85.)
		player.y += velocity.y*dt
		if player.y < -380.: player.y = -380.; velocity.y = maxf(0.,velocity.y)
		var support: float = crossing_floor(player.x,old_y,player.y,velocity.y)
		if player.y>=support and velocity.y>=0.:
			player.y = support; velocity.y = 0.; jumps = 0; flap_count = 0; flap_time = 0.; gliding = false; air_time = 0.
		else: air_time += dt
	if player.y>180.:
		damage_player("pit")
		if state == "playing": player = Vector2(maxf(70.,old_x-160.),-80.); velocity = Vector2(0,-300.)
	if velocity.y>0.:
		for enemy in enemies:
			if bool(enemy.defeated):continue
			var top: float=float(enemy.y)-58.
			if absf(player.x-float(enemy.x))<34. and old_y<=top and player.y>=top:
				damage_enemy(enemy,2 if bool(enemy.mini) else 1);player.y=top-2.;velocity.y=-420.;jumps=1;air_time=0.;pending_events.append("melee");break
	if fire_held: attack()
	step_enemies(dt); step_boss(dt); step_bullets(dt)
	for bomb in bombs:
		bomb.age = float(bomb.age)+dt; bomb.v = Vector2(bomb.v)+Vector2(0,780.)*dt; bomb.p = Vector2(bomb.p)+Vector2(bomb.v)*dt
		if float(bomb.p.y)>-12. and floor_at(float(bomb.p.x))==0.: bomb.p = Vector2(float(bomb.p.x),-12.); bomb.age = 2.
		if float(bomb.age)>=1.15: explode(bomb)
	bombs = bombs.filter(func(b):return float(b.age)<1.15)
	for blast in blasts: blast.age = float(blast.age)+dt
	blasts = blasts.filter(func(b):return float(b.age)<.5)
	for item in pickups:
		if not taken.has(str(item.id)) and player.distance_to(Vector2(float(item.x),float(item.y)))<63.: collect(item)
	for npc in npcs:
		if not bool(npc.freed) and absf(player.x-float(npc.x))<52. and absf(player.y-float(npc.y))<80.: rescue(npc)
	trail.append({"p":player,"time":time,"facing":facing})
	while trail.size()>1 and time-float(trail[0].time)>4.: trail.pop_front()
	if player.x>=length()-130. and section != "arena":
		var blocked := false
		for e in enemies:
			if not bool(e.defeated) and (bool(e.mini) or float(e.x)>length()-650.): blocked = true
		if not blocked:
			var next: String = str(STAGES[section].next)
			if next.begins_with("fork"): state = next; stop_inputs()
			else: travel_target = next; state = "travel"; stop_inputs()

func snapshot() -> Dictionary:
	return {"schema":1,"run_seed":run_seed,"character":character,"checkpoint":checkpoint,"checkpoint_ready":checkpoint_ready,"score":score,"kills":kills,"rescued":rescued,"awarded":awarded,"taken":taken,"route":route,"completed":completed,"time":time,"flock":flock}

func restore(data: Dictionary) -> bool:
	if int(data.get("schema",0))!=1 or not STAGES.has(str(data.get("checkpoint",""))): return false
	if str(data.get("character","")) not in HEROES: return false
	for key in ["rescued","route"]:
		if not data.get(key,[]) is Array or data.get(key,[]).size()>512:return false
		for item in data.get(key,[]):
			if not item is String:return false
	for key in ["awarded","taken"]:
		if not data.get(key,{}) is Dictionary or data.get(key,{}).size()>4096:return false
	for key in ["score","kills","time","flock"]:
		var number=data.get(key,0)
		if typeof(number) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(number)) or absf(float(number))>1000000000.:return false
	if data.has("completed") and not data.completed is bool:return false
	character = str(data.character); score = maxi(0,int(data.get("score",0))); kills = maxi(0,int(data.get("kills",0)))
	run_seed=clampi(int(data.get("run_seed",7719)),1,2000000000)
	rescued.assign(Array(data.get("rescued",[]))); awarded = Dictionary(data.get("awarded",{})); taken = Dictionary(data.get("taken",{}))
	route.assign(Array(data.get("route",[]))); completed = bool(data.get("completed",false)); time = maxf(0.,float(data.get("time",0.)))
	flock = clampi(int(data.get("flock",1)),1,3); hp = max_hp; grenades = 5
	load_section(str(data.checkpoint))
	if completed: state = "complete"; checkpoint_ready = false; boss.active = false
	return true
