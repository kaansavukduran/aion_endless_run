class_name AionCampaignWorld
extends RefCounted

## Finite arcade rules in world coordinates. Terrain supplies the foot support.
## The old RunnerWorld, its saves and its automatic-run rules are independent.
const CHARGE_HEROES := ["rabbit", "eren", "frog"]
const MAX_FLOCK := 2
const AION_JUMPS := 3
const RABBIT_JUMP_HOLD := 1.0
const RABBIT_CHARGE_SECONDS := .72
const HEROES := ["aion", "sheep", "rabbit", "eren", "armadillo", "frog"]
const COLORS := {"aion":"ef86b7", "sheep":"f5d6a6", "wolf":"aa84d2", "owl":"e8a34f", "rabbit":"f08d55", "eren":"58c4bb", "armadillo":"c49268", "frog":"80bd64"}
const HERO_ART=preload("res://assets/PIXEL-HEROES-PROVENANCE.json")
const ABILITY_ART=preload("res://assets/POLISH-PROVENANCE.json")
const VEHICLE_GUN_ART=preload("res://scripts/forge_vehicle_art.gd")
const ARMED_ART=preload("res://assets/FORGE-HEROES-PROVENANCE.json")
const ARMED_HEROES := ["aion","wolf","sheep","owl","rabbit","eren"]
const STAGES := {
	"shore": {"length":7800., "biome":4, "title":"arc_shore", "next":"quay"},
	"quay": {"length":9500., "biome":4, "title":"arc_quay", "next":"fork_one"},
	"canopy": {"length":3600., "biome":4, "title":"arc_canopy", "next":"fork_two"},
	"fork_one": {"length":1800., "biome":4, "title":"arc_quay", "next":"water"},
	"fork_two": {"length":1800., "biome":4, "title":"arc_canopy", "next":"roots"},
	"causeway": {"length":3400., "biome":4, "title":"arc_causeway", "next":"relay"},
	"water": {"length":15600., "biome":2, "title":"arc_water", "next":"relay"},
	"terrace": {"length":14800., "biome":4, "title":"arc_terrace", "next":"relay"},
	"roots": {"length":15200., "biome":2, "title":"arc_roots", "next":"relay"},
	"relay": {"length":10000., "biome":3, "title":"arc_relay", "next":"arena"},
	"arena": {"length":3000., "biome":4, "title":"arc_arena", "next":"complete"}
}
var discovered: Dictionary={}
var activated: Dictionary={}
var buffs: Dictionary={}
var assists: Array[Dictionary]=[]
var assist_attacks:=0
var encounters: Array[Dictionary]=[]
var objects: Array[Dictionary]=[]
var zones: Array[Dictionary]=[]
var rooms: Array[Dictionary]=[]
var hazards: Array[Dictionary]=[]
var disabled_platforms: Dictionary={}
var platform_timers: Dictionary={}
var rescue_time:=0.
var rescue_target:=""
var rescue_contact:=false
var rescue_latched:=false
var character := "aion"
var pose_motion_enabled := true # Ephemeral rendering contract; never saved.
var paused_crouch := false # Frozen presentation stance; never an input or save field.
var state := "briefing"
var section := "shore"
var player := Vector2(140, 0)
var velocity := Vector2.ZERO
var facing := 1
var aim_direction := Vector2.RIGHT # Rendered/firing direction, including the sweep between eight target directions.
var aim_sweep_gate := 0.
var move_axis := Vector2.ZERO
var time := 0.0
var run_seed := 7719
var walk_distance := 0.0
var hp := 1
const MAX_HP := 1
# Existing checkpoints stored up to eight seconds of elapsed shield charge.
const LEGACY_SHIELD_CHARGE_MAX := 8.
var max_hp: int:
	get: return MAX_HP
var attempts_remaining := CampaignLives.ATTEMPTS
var continues_used := 0
var continue_remaining := 0.
var continue_hero := "aion"
var recovery_view := Rect2()
var entry_from := Vector2.ZERO
var entry_to := Vector2.ZERO
var entry_clock := 0.
var entry_guard := false
var shield_charge := 0.
var grenades := 5
var score := 0
var kills := 0
var shots := 0
var rescued: Array[String] = []
var rescue_life_start := 0
const CLEAR_BONUS := 3000
const KEEPER_BONUS := 300
var greeted: Dictionary = {}
var gift_drops: Dictionary = {} # Unclaimed physical gifts, keyed by stable NPC ID.
var rescue_roles: Dictionary = {}
var losses := 0
var weapons_used: Array[String] = []
var vehicles_used: Array[String] = []
var awarded: Dictionary = {}
var taken: Dictionary = {}
var route: Array[String] = []
var checkpoint := "shore"
var checkpoint_ready := false
var rally: Dictionary = {}
var retry_count := 0
var chain := 0
var chain_time := 0.
var best_chain := 0
var score_popups: Array[Dictionary] = []
var bridge_timers: Dictionary = {}
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
var shot_weapon := "" # Ephemeral last shot; not inventory or checkpoint state.
var last_shot_mounted := false
var grenade_time := 0.0
var grenade_throw: Dictionary = {}
var hero_skill: Dictionary = {}
var frog_meal: Dictionary = {}
var frog_cooldown := 0.
var roll_charges := MissionHeroAbilities.ROLL_CHARGES
var roll_cooldown := 0.
var sprint_fire := 0.
var sprint_recovery := 0.
var sprint_ignition := true
var shell_contacts: Array[Dictionary] = []
var jump_held := false
var jumps := 0
var flap_count := 0
var flap_time := 0.0
var gliding := false
var charging := false
var charge_time := 0.0
var jump_hold_before_charge := 0.0
var waiting_to_charge := false
var boost_held := false
const COYOTE_TIME := 0.09
const JUMP_BUFFER := 0.10
var air_time := 0.0
var coyote_timer := 0.0
var jump_buffer_timer := 0.0
var drop_through_time := 0.0
var weapon := "pistol"
var ammunition := CampaignWeapons.PISTOL_START
var pistol_reserve := 0
var spider_parade: Dictionary = {}
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
var mount := {"available":false, "ridden":false, "x":0., "hp":CampaignVehicles.MAX_HP}
var mount_transition := ""
var mount_transition_time := 0.0
var mount_transition_duration := .45
var eject_target_x := -1.
var mount_transition_from := Vector2.ZERO
var mount_transition_to := Vector2.ZERO
var trail: Array[Dictionary] = []
var flock := 1
var boss := CampaignBossPressure.initial_state(1300.)
var notice := ""
var notice_time := 0.0
var pending_events: Array[String] = []

func biome() -> int: return int(STAGES[section].biome)
func length() -> float: return float(STAGES[section].length)
func charge_duration() -> float: return RABBIT_CHARGE_SECONDS
func charge_ratio() -> float: return clampf(charge_time / charge_duration(), 0., 1.)
## y is the support query height; the default asks for the lowest floor.
func floor_at(x: float,y: float=1e9) -> float:
	if CampaignRoutes.is_fork(section):return CampaignRoutes.floor_height(self,x,y)
	for pit in pits:
		if x > pit.x and x < pit.y:return CampaignGround.VOID_HEIGHT
	return CampaignGround.height(section,x)
func crossing_floor(x: float,old_y: float,new_y: float,falling_speed: float,hero_drop: bool=true) -> float:
	var support:=floor_at(x,old_y)
	for platform in platforms:
		if (hero_drop and drop_through_time>0.) or disabled_platforms.has(platform.position.x):continue
		if x>=platform.position.x-9. and x<=platform.end.x+9. and old_y<=platform.position.y+.01 and new_y>=platform.position.y and falling_speed>=0.:support=minf(support,platform.position.y)
	return support
func grounded() -> bool:
	if bool(mount.ridden):
		var foot: float=player.y+42.-(24. if float(mount.get("dive",0.))>0. else 0.)
		if absf(foot-floor_at(player.x))<.1 and absf(velocity.y)<1.:return true
		for platform in platforms:
			if not disabled_platforms.has(platform.position.x) and player.x>=platform.position.x-9. and player.x<=platform.end.x+9. and absf(foot-platform.position.y)<.1 and absf(velocity.y)<1.:return true
		return false
	if absf(player.y-floor_at(player.x))<.1 and CampaignGround.has_floor(floor_at(player.x)):return true
	for platform in platforms:
		if disabled_platforms.has(platform.position.x):continue
		if player.x >= platform.position.x - 9. and player.x <= platform.end.x + 9. and absf(player.y - platform.position.y) < .1: return true
	return false

func crouching() -> bool:
	if state=="paused":return paused_crouch
	# A real low ceiling keeps the hero crouched until there is room to stand.
	return state=="playing" and mount_transition=="" and not bool(mount.ridden) and grounded() and (move_axis.y>.55 or CampaignRoutes.low_ceiling(self) or MissionHeroAbilities.compact(self))

func player_hit_center() -> Vector2:
	return player+Vector2(0.,-20. if crouching() else -37.)

## Mounted logical player is a saddle42px above the vehicle foot, not a
## standing hero. Use the same physical hull envelope for NPCs and supplies.
func mounted_contact_rect() -> Rect2:
	var foot: float=player.y+42.-(24. if float(mount.get("dive",0.))>0. else 0.)
	return Rect2(player.x-82.,foot-132.,164.,132.)

func touches_npc(n: Dictionary) -> bool:
	if bool(mount.ridden):return mounted_contact_rect().intersects(Rect2(float(n.x)-18.,float(n.y)-75.,36.,75.))
	return absf(player.x-float(n.x))<48. and absf(player.y-float(n.y))<30.

func touches_pickup(item: Dictionary) -> bool:
	if not CampaignRoutes.pickup_exposed(self,item):return false
	var point:=Vector2(float(item.x),float(item.y))
	if bool(mount.ridden):return mounted_contact_rect().grow(10.).has_point(point)
	if item.has("rescue_id"):return player_hit_center().distance_to(point)<48.
	if player.distance_to(point)<63.:return true
	if character=="sheep" and flock>1 and str(item.kind).begins_with("fruit_"):
		for companion in flock-1:
			if CampaignLives.follower_position(self,companion).distance_to(point)<44.*CampaignUpgrades.recovery_scale(self):return true
	return false

## Eight input targets, a bounded shortest-arc turn, and one controlled early
## shot window per180ms while sweeping. Actual gun and projectile share aim.
func steer_aim(target: Vector2,dt: float) -> void:
	if target.length_squared()<.01:return
	if dt<=0. or bool(mount.ridden):aim_direction=target.normalized();return
	aim_sweep_gate=maxf(0.,aim_sweep_gate-dt)
	var angle:=aim_direction.angle()
	var delta:=wrapf(target.angle()-angle,-PI,PI)
	var step:=9.*minf(dt,.05)
	if absf(delta)<=step:
		aim_direction=target.normalized()
		return
	angle+=signf(delta)*step
	aim_direction=Vector2.from_angle(angle)
	# Spend the one early shot on an actual in-between angle. Scheduling it
	# for a later frame can leave only a snapped shot at low render rates.
	var main_angle:=snappedf(angle,PI/4.)
	if fire_held and absf(delta)>.20 and absf(angle-main_angle)>.045 and aim_sweep_gate<=0. and weapon not in ["rocket","nova","disc"]:
		fire_time=0.;aim_sweep_gate=.18


func player_hit_radius() -> float:
	return 17. if crouching() else 30.

func begin(hero: String) -> void:
	pending_events.clear()
	character = hero if hero in HEROES else "aion"
	CampaignLives.reset(self)
	MissionHeroAbilities.reset(self)
	hp = max_hp; grenades = 5; score = 0; kills = 0; shots = 0
	time=0.;walk_distance=0.;victory_time=0.;assists.clear();assist_attacks=0
	var run_rng:=RandomNumberGenerator.new();run_rng.randomize();run_seed=run_rng.randi_range(1,2000000000)
	rescued.clear(); rescue_life_start=0; greeted.clear(); gift_drops.clear(); rescue_roles.clear(); awarded.clear(); taken.clear(); route.clear()
	losses=0;weapons_used.clear();vehicles_used.clear()
	discovered.clear();activated.clear();buffs.clear()
	completed = false; flock = 1; weapon = "pistol"; ammunition = CampaignWeapons.PISTOL_START; pistol_reserve = 0
	rally.clear();retry_count=0;chain=0;chain_time=0.;best_chain=0;score_popups.clear()
	load_section("shore")
	state = "briefing"

func stop_inputs() -> void:
	move_axis = Vector2.ZERO; aim_direction = Vector2(facing,0.); aim_sweep_gate=0.; fire_held = false; jump_held = false
	charging = false; charge_time = 0.; waiting_to_charge = false; jump_hold_before_charge = 0.
	boost_held = false; gliding = false
	melee_latched = false
	rescue_latched=false
	coyote_timer = 0.; jump_buffer_timer = 0.

func spawn_enemy(kind: String, x: float, y: float, index: int, mini: bool = false) -> void:
	if not CampaignContent.flying(kind):
		for pit in pits:
			if x>pit.x-30. and x<pit.y+30.:x=pit.x-55.
	var health:=12 if mini else (8 if kind in CampaignContent.HEAVIES else 1)
	if kind==CampaignHive.KIND:health=CampaignHive.HP
	enemies.append({"id":section+":enemy:"+str(index), "kind":kind, "x":x, "y":y, "home":Vector2(x,y), "hp":health, "max_hp":health, "mini":mini,"heavy":kind in CampaignContent.HEAVIES,"armour":2 if kind in CampaignContent.HEAVIES else 0, "age":0., "wait":1.1+float(index%4)*.23, "windup":0., "attacks":0, "facing":-1, "active":false, "defeated":false})

func load_section(id: String) -> void:
	assert(STAGES.has(id))
	# Loads run behind the travel fade: pre-decode sheets this section used before.
	RunnerSourcePixels.enter_section(id)
	paused_crouch=false
	CampaignGrenade.cancel(self,true)
	MissionHeroAbilities.cancel(self)
	shell_contacts.clear()
	section = id; checkpoint = id; checkpoint_ready = true
	discovered["map:section:"+id]=true
	spider_parade.clear()
	travel_target=""
	player = Vector2(140, 0); velocity = Vector2.ZERO; facing=1; stop_inputs()
	CampaignAssists.section_changed(self)
	mount_transition="";mount_transition_time=0.;eject_target_x=-1.
	jumps = 0; flap_count = 0; air_time = 0.; coyote_timer = 0.; jump_buffer_timer = 0.; drop_through_time=0.; fire_time = 0.; melee_time = 0.; grenade_time = 0.
	shot_flash=0.;shot_weapon="";last_shot_mounted=false
	melee_target="";melee_hit_done=true
	rescue_time=0.;rescue_target="";rescue_contact=false;rescue_latched=false
	if not entry_guard:invulnerable=1.2
	hurt_time=0.;flap_time=0.
	enemies.clear(); bullets.clear(); bombs.clear(); blasts.clear(); pickups.clear()
	platforms.clear(); pits.clear(); crates.clear(); gates.clear(); npcs.clear(); trail.clear()
	platform_timers.clear();disabled_platforms.clear()
	bridge_timers.clear()
	mount = {"available":false, "ridden":false, "x":0., "hp":CampaignVehicles.MAX_HP}
	boss = CampaignBossPressure.initial_state(length()-420.)
	var types: Array = ["gnome", "beetle", "seed", "crow"]
	if section in ["quay", "relay"]: types = ["seed", "gnome", "drone", "beetle"]
	elif section in ["canopy", "terrace"]: types = ["crow", "moth", "drone", "seed"]
	elif section in ["water", "roots"]: types = ["slime", "seed", "beetle", "wisp"]
	if CampaignRoutes.is_fork(section):pass
	elif section != "arena":
		var layout_rng:=RandomNumberGenerator.new();layout_rng.seed=run_seed+abs(section.hash())
		var is_leaf_route: bool = section in ["water", "terrace", "roots"]
		var spawn_x:=500.;var spawn_index:=0
		while spawn_x<minf(length()-260.,1050. if is_leaf_route else 1600.):
			var kind: String = str(types[spawn_index] if spawn_index<types.size() else types[layout_rng.randi_range(0,types.size()-1)])
			spawn_enemy(kind, spawn_x, -115. if kind in ["crow","moth","wisp","drone"] else 0., spawn_index)
			spawn_x+=layout_rng.randf_range(160.,270.);spawn_index+=1
		if not is_leaf_route and not CampaignContent.MAIN_PLANS.has(section):
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
		if section in ["quay", "water"]:
			mount = {"available":true, "ridden":false, "x":360., "hp":CampaignVehicles.MAX_HP}
			var repair_key:=section+":repair"
			if not taken.has(repair_key):pickups.append({"id":repair_key,"x":length()*.72,"y":-35.,"kind":"repair"})
		if is_leaf_route:
			spawn_enemy("warden", length()-580., 0., 99, true)
			gates.append({"x":length()-340., "ids":[section+":enemy:99"]})
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
		platforms.append_array(CampaignGround.ARENA_WALKWAYS)
		boss.active = true
	if CampaignRoutes.is_fork(section):CampaignRoutes.populate(self)
	else:
		CampaignContent.populate(self)
		CampaignRescue.populate(self)
	CampaignRhythm.populate(self)
	CampaignGround.align_world(self)
	CampaignWeapons.populate_sidearm(self)
	state = "playing"
	CampaignRecovery.enter(self)
	notice = "arc_checkpoint"; notice_time = 2.
	pending_events.append("checkpoint")

func choose_route(choice: String) -> bool:
	if state == "fork_one" and choice in ["canopy", "causeway", "water"]:
		if not route.has(choice): route.append(choice)
		begin_travel(choice);return true
	if state == "fork_two" and choice in ["terrace", "roots"]:
		if not route.has(choice): route.append(choice)
		begin_travel(choice);return true
	return false

func begin_travel(destination: String) -> void:
	travel_target=destination;state="travel";facing=1
	stop_inputs()
	CampaignGrenade.cancel(self,true)
	MissionHeroAbilities.cancel(self)
	shot_flash=0.;melee_time=0.;rescue_time=0.;hurt_time=0.

func advance_exit(dt: float) -> bool:
	dt=clampf(dt,0.,.05)
	var end_x:=CampaignRoutes.EXIT_X+140. if CampaignRoutes.is_fork(section) else length()-12.
	if bool(mount.ridden):
		# The flag is on solid ground. Step out on the same lane, ahead of
		# the vehicle, and keep space for the short walk after landing.
		var foot:=CampaignRoutes.foot(self)
		var x:=minf(foot.x+72.,maxf(foot.x,end_x-56.))
		var support:=CampaignVehicles.support_below(self,x,foot.y)
		var target:=Vector2(x,support) if CampaignGround.has_floor(support) else foot
		facing=1;CampaignVehicles.start_exit(self,target)
	if mount_transition!="":
		CampaignVehicles.step_transition(self,dt)
		return false
	facing=1;aim_direction=Vector2.RIGHT
	var distance:=minf(235.*dt,maxf(0.,end_x-player.x))
	if distance<=0.:return true
	var next_x:=player.x+distance
	var floor:=CampaignVehicles.support_below(self,next_x,player.y)
	if not CampaignGround.has_floor(floor):return true
	player=Vector2(next_x,floor)
	velocity=Vector2(235.,0.);walk_distance+=distance
	return next_x>=end_x

func finish_travel() -> void:
	if state == "travel" and STAGES.has(travel_target): load_section(travel_target)

func jump_press() -> void:
	if state != "playing" or CampaignVehicles.stunned(self) or rescue_time>0. or mount_transition!="" or jump_held or MissionHeroAbilities.compact(self): return
	jump_held = true
	# No jump into a low ceiling: the crawlway keeps the hero on its floor.
	if CampaignRoutes.low_ceiling(self):return
	# Down+Jump drops through one-way platforms; Down alone is a crawl.
	if move_axis.y>.55 and not bool(mount.ridden) and grounded() and player.y<floor_at(player.x,player.y)-1.:
		drop_through_time=.25;player.y+=3.;velocity.y=70.;jumps=1;return
	if CampaignVehicles.jump(self):return
	if grounded() and character in CHARGE_HEROES and not bool(mount.ridden):
		waiting_to_charge = true
		jump_hold_before_charge = 0.
		charging = false
		charge_time = 0.
		return
	if grounded() or (coyote_timer > 0. and jumps == 0 and not bool(mount.ridden) and character not in CHARGE_HEROES):
		velocity.y = -650.; jumps = 1; air_time = 0.; coyote_timer = 0.; jump_buffer_timer = 0.; return
	if character == "aion" and jumps < AION_JUMPS:
		velocity.y = -620. * (1.12 if CampaignUpgrades.selected(self,"spark") else 1.)
		jumps += 1; air_time = 0.; return
	elif character == "owl" and flap_count < 3:
		velocity.y = minf(velocity.y,-650.*sqrt(1.5)); flap_count += 1; flap_time = .3; air_time=0.; return
	if not bool(mount.ridden) and character not in CHARGE_HEROES:
		jump_buffer_timer = JUMP_BUFFER

func jump_release(launch: bool = true) -> void:
	jump_held = false; gliding = false
	if charging or waiting_to_charge:
		if launch and state == "playing" and (grounded() or coyote_timer > 0.):
			velocity.y = -650.*sqrt(lerpf(1.75,4.0,charge_ratio())); jumps = 1; air_time = 0.
			coyote_timer = 0.; jump_buffer_timer = 0.
		charging = false; charge_time = 0.; waiting_to_charge = false; jump_hold_before_charge = 0.

func step_jump_charge(dt: float, on_floor: bool) -> void:
	if waiting_to_charge:
		if not on_floor or CampaignRoutes.low_ceiling(self):
			waiting_to_charge = false
			return
		jump_hold_before_charge += dt
		if jump_hold_before_charge+0.000001 < RABBIT_JUMP_HOLD:return
		waiting_to_charge = false
		charging = true
		dt = maxf(0.,jump_hold_before_charge-RABBIT_JUMP_HOLD)
	if charging:
		if on_floor and not CampaignRoutes.low_ceiling(self):
			charge_time = minf(charge_duration(),charge_time+dt)
		else:
			charging = false
			charge_time = 0.

func close_enemy() -> Dictionary:
	# Up/down aiming is ranged fire, never an accidental knife/rescue.
	if crouching() or absf(aim_direction.y) > .25: return {}
	for e in enemies:
		if bool(e.defeated): continue
		var dx: float = (float(e.x)-player.x)*facing
		if dx >= -12. and dx < 95. and absf(float(e.y)-player.y) < 75.: return e
	if bool(boss.active) and bool(boss.get("engaged",false)) and (float(boss.x)-player.x)*facing >= 0. and absf(float(boss.x)-player.x)<130.: return boss
	return {}

func attack_press() -> void:
	if state != "playing" or CampaignVehicles.stunned(self) or mount_transition!="" or MissionHeroAbilities.compact(self) or not grenade_throw.is_empty(): return
	if not fire_held and CampaignRescue.begin(self):return
	if rescue_time>0. or rescue_latched:return
	fire_held = true; melee_latched = false
	attack()
func attack_release() -> void: fire_held = false; melee_latched = false;rescue_latched=false

## The renderer and projectile system select the same immutable source pose.
## Absolute eight-direction keyposes already include their authored facing.
func armed_art_spec() -> Dictionary:
	if bool(mount.ridden) or mount_transition!="":return {}
	return M1CombatArt.body_spec(self)

## Visible vehicle and muzzle use the same pose selection.
func vehicle_art_spec() -> Dictionary:
	if not bool(mount.ridden) or mount_transition!="":return {"phase":0,"frame":0}
	var aim: Vector2=aim_direction.normalized() if aim_direction.length_squared()>.01 else Vector2(facing,0.)
	var aligned: bool=absf(aim.y)<.005 and aim.x*float(facing)>0.
	var phase: int=2 if bool(mount.ridden) and float(mount.get("hurt",0.))>0. else (1 if CampaignVehicles.firing(self) and aligned else 0)
	var frame: int=posmod(int(time*8.),6)
	if phase==1:frame=clampi(int((.18-shot_flash)/.18*6.),0,5)
	elif phase==2:frame=clampi(int((1.-float(mount.get("break_time",0.))/CampaignVehicles.IMPACT_SECONDS)*6.),0,5)
	return {"phase":phase,"frame":frame}

func armed_muzzle() -> Vector2:
	if bool(mount.ridden):
		var aim: Vector2=aim_direction.normalized() if aim_direction.length_squared()>.01 else Vector2(facing,0.)
		var spec:=vehicle_art_spec()
		var metrics: Dictionary=VEHICLE_GUN_ART.aim_anchors(CampaignVehicles.kind(self),int(spec.phase),int(spec.frame))
		var pivot: Vector2=metrics.pivot_local
		# Vehicle art is rooted to its supporting floor; mounted player feet
		# have always used a logical saddle root 42px above that same floor.
		return Vector2(pivot.x*float(facing),pivot.y)+aim*float(metrics.barrel_length)+Vector2(0.,42.)
	return Vector2(M1CombatArt.placement(self).muzzle)

func muzzle_offset() -> Vector2:
	return armed_muzzle()

func muzzle_flashing() -> bool:
	return shot_flash>.122

func legacy_muzzle_offset() -> Vector2:
	if character=="eren" and (charging or not grounded()):
		var atlas: Dictionary=ABILITY_ART.data.atlases["polish-abilities"]
		var row: int=2 if charging else 3
		var col: int=clampi(int(charge_ratio()*6),0,5) if charging else RunnerWorld.flight_frame_for(velocity.y,air_time,6)
		var f: Dictionary=atlas.frames[row][col]
		return (Vector2(f.weapon_grip[0],f.weapon_grip[1])-Vector2(f.origin[0],f.origin[1]))*float(atlas.scale[row])+Vector2(23,-5)
	var atlas: Dictionary=HERO_ART.data.atlases["pixel-"+character]
	var frame: int=clampi(int((.18-shot_flash)/.18*6.),0,5) if shot_flash>0. else 0
	var point: Array=atlas.frames[4 if shot_flash>0. else 3][frame].muzzle
	return Vector2(point[0],point[1])+Vector2(0,14 if charging else 0)

func attack() -> void:
	if fire_time > 0. or state != "playing" or CampaignVehicles.stunned(self) or rescue_time>0. or mount_transition!="" or MissionHeroAbilities.compact(self) or not grenade_throw.is_empty(): return
	var close: Dictionary = close_enemy()
	if not bool(mount.ridden) and (not close.is_empty() or not CampaignWeapons.has_rounds(self)):
		if melee_latched: return
		melee_latched = true; melee_variant = 1-melee_variant
		melee_time = .28; fire_time = .32
		melee_target="boss" if close==boss else str(close.get("id",""));melee_hit_done=false
		pending_events.append("melee")
		return
	melee_latched = false
	CampaignWeapons.fire(self)

func throw_grenade() -> bool:
	return not CampaignVehicles.stunned(self) and CampaignGrenade.press(self)

func interact() -> bool:
	if state != "playing" or mount_transition!="" or CampaignVehicles.stunned(self): return false
	if CampaignRoutes.use_context(self):return true
	if CampaignVehicles.interact(self):
		CampaignGrenade.cancel(self)
		MissionHeroAbilities.cancel(self)
		return true
	return MissionHeroAbilities.press(self)

func award(id: String, points: int) -> void:
	if awarded.has(id): return
	awarded[id] = true; score += points

func damage_enemy(e: Dictionary, amount: int, style: String="") -> void:
	if bool(e.defeated): return
	if int(e.get("armour",0))>0 and style!="flame_dash":e.armour=int(e.armour)-1;e.flash=.25;pending_events.append("armour_hit");return
	e.hp = int(e.hp)-amount
	if int(e.hp) > 0: return
	e.defeated = true; e.dead_age = 0.
	CampaignStyle.defeat(self,e,500 if bool(e.mini) else (400 if bool(e.get("heavy",false)) else 100),style)
	if style=="swallow":return
	blasts.append({"p":Vector2(float(e.x),float(e.y)-25.), "age":0., "radius":40., "color":"85d7c4"})
	pending_events.append("enemy")

func damage_boss(amount: int) -> void:
	if not bool(boss.active) or not bool(boss.get("engaged",false)): return
	amount=CampaignBossPressure.damage_allowed(self,amount)
	if amount<=0:return
	boss.hp = maxi(0,int(boss.hp)-amount)
	if int(boss.hp) == 0:
		boss.active = false; boss.beam_warning = 0.; boss.windup = 0.; completed = true; state = "victory"; victory_time = 0.; checkpoint_ready = false
		boss.echo_wait=0.;boss.dash=0.;boss.recover=0.
		bullets = bullets.filter(func(b): return str(b.owner) != "enemy")
		hazards.clear()
		for e in enemies:
			if not bool(e.defeated): e.defeated = true; e.dead_age = 0.
		blasts.append({"p":Vector2(float(boss.x),float(boss.y)-80.), "age":0., "radius":130., "color":"ffcf8c"})
		award("mission:1",CLEAR_BONUS+life_rescues()*KEEPER_BONUS); stop_inputs(); pending_events.append("complete")
	else:
		var phase:=CampaignBossPressure.phase_for(int(boss.hp))
		if phase>int(boss.phase):
			CampaignBossPressure.on_phase_change(self,int(boss.phase),phase)
			boss.phase=phase

func enemy_body_hit(enemy: Dictionary) -> void:
	if state!="playing":return
	if MissionHeroAbilities.sprinting(self) and sprint_fire>0. and MissionHeroAbilities.sprint_enemy(self,enemy,player_hit_center(),player_hit_center()):return
	damage_player()

func shield_ready() -> bool:
	return is_equal_approx(shield_charge,CampaignLives.SHIELD_CHARGE_SECONDS)

func damage_player(cause: String="enemy") -> void:
	if state != "playing" or invulnerable > 0. or mount_transition!="" or CampaignVehicles.stunned(self): return
	if cause!="pit" and not bool(mount.ridden) and CampaignLives.absorb_hit(self):return
	chain=0;chain_time=0.
	MissionHeroAbilities.cancel(self)
	CampaignGrenade.cancel(self)
	hurt_time = .3
	if bool(mount.ridden):
		CampaignVehicles.damage(self)
	else:
		frog_meal.clear()
		pending_events.append("hurt")
		CampaignLives.lethal(self,cause)

func explode(bomb: Dictionary) -> void:
	var p: Vector2 = bomb.p
	blasts.append({"p":p, "age":0., "radius":135., "color":bomb.color})
	if state=="continue_offer":
		pending_events.append("blast")
		return
	for e in enemies:
		if not bool(e.defeated) and p.distance_to(Vector2(float(e.x),float(e.y)-30.))<150.: damage_enemy(e,5)
	if bool(boss.active) and p.distance_to(Vector2(float(boss.x),float(boss.y)-70.))<200.: damage_boss(8)
	for crate in crates:
		if p.distance_to(Vector2(float(crate.x),float(crate.y)-20.))<150.: open_crate(crate)
	CampaignContent.hit_object(self,p,3)
	pending_events.append("blast")

func open_crate(crate: Dictionary) -> void:
	if int(crate.hp)<=0: return
	crate.hp = 0
	var id: String = str(crate.id)
	if not taken.has(id): pickups.append({"id":id,"x":float(crate.x),"y":float(crate.y)-35.,"kind":str(crate.kind)})

func rescue(npc: Dictionary) -> void:
	if bool(npc.freed): return
	npc.freed = true
	npc.free_age=0.;npc.phase="free";npc.thank_age=0.;npc.facing=-1 if player.x<float(npc.x) else 1
	npc.clip=CampaignRescue.clip_name(npc)
	var id: String = str(npc.id)
	if not rescued.has(id):
		rescued.append(id); rescue_roles[id]=str(npc.get("role","keeper")); award(id,300)
		pending_events.append("rescue")

func collect(item: Dictionary) -> void:
	var id: String = str(item.id)
	if taken.has(id): return
	taken[id] = true
	var kind:=CampaignWeapons.canonical_kind(str(item.kind))
	if kind.begins_with("fruit_"): award(id,25)
	elif kind in CampaignWeapons.SPECIAL:
		CampaignWeapons.equip(self,kind)
		if kind=="rocket":CampaignWeapons.start_spider_parade(self,item)
	elif kind == "pistol_ammo": CampaignWeapons.grant_sidearm(self,CampaignWeapons.PISTOL_REFILL)
	elif kind == "relay_part":
		if item.has("rescue_id"):CampaignRescue.on_gift_collected(self,item)
		CampaignRoutes.collect_item(self,item)
		pending_events.append("pickup")
		return
	elif kind == "grenade": grenades = mini(9,grenades+3)
	elif kind == "shield": buffs["power"]=maxf(8.,float(buffs.get("power",0.)))
	elif kind == "heal": supply(id,1)
	elif kind == "repair": supply(id,2)
	elif kind=="points":award(id,500)
	elif kind in ["haste","power","reveal","magnet"]:buffs[kind]=12.
	elif kind in ["owl_feather","wolf_charm"]:CampaignAssists.summon(self,kind)
	else: return
	if item.has("rescue_id"):CampaignRescue.on_gift_collected(self,item)
	pending_events.append("pickup")

func supply(id: String,amount: int) -> void:
	if grenades>=9:award(id,amount*100)
	else:grenades=mini(9,grenades+amount)

## alive: optional set from alive_enemy_ids() built at the same moment, so a
## loop over every gate scans the enemies once instead of once per gate.
func gate_closed(gate: Dictionary,alive: Dictionary={}) -> bool:
	if not alive.is_empty() or enemies.is_empty():
		for id in gate.ids:
			if alive.has(str(id)):return true
		return false
	for e in enemies:
		if str(e.id) in gate.ids and not bool(e.defeated): return true
	return false

func alive_enemy_ids() -> Dictionary:
	var alive:={}
	for e in enemies:
		if not bool(e.defeated):alive[str(e.id)]=true
	return alive

func enemy_shot(e: Dictionary, fan: bool = false) -> void:
	pending_events.append("enemy_shot")
	e.flash=.24
	if CampaignRhythm.lane_shot(self,e):return
	if e.kind in ["gnome","beetle","slime"]:
		e.dash=.45 if e.kind=="gnome" else .65
		e.dash_direction=signf(player.x-float(e.x));return
	if e.kind=="crow":
		e.dive=.70/.9;e.dive_duration=.70/.9;e.dive_start=Vector2(float(e.x),float(e.y));e.dive_target=player+Vector2(0,-25.);return
	var origin := Vector2(float(e.x),float(e.y)-32.)
	if e.kind=="moth":
		bullets.append({"p":origin,"v":Vector2(signf(player.x-origin.x)*80.,50.),"owner":"enemy","age":0.,"kind":"spore","damage":1,"pierce":0,"hit":[],"gravity":180.});return
	if e.kind=="warden" and int(e.attacks)%2==1:
		bullets.append({"p":Vector2(float(e.x),-16.),"v":Vector2(signf(player.x-float(e.x))*240.,0.),"owner":"enemy","age":0.,"kind":"wave","damage":1,"pierce":0,"hit":[]});return
	var direction: Vector2 = (player+Vector2(0,-36)-origin).normalized()
	if direction.length_squared()<.5: direction = Vector2.LEFT
	var angles: Array = [-.22,0.,.22] if fan else ([-.12,.12] if e.kind=="drone" else [0.])
	var speed:=228. if e.kind=="seed" and (section!="shore" or float(e.home.x)>=1850.) else 210.
	for angle in angles: bullets.append({"p":origin,"v":direction.rotated(angle)*speed,"owner":"enemy","age":0.,"kind":"seed","damage":1,"pierce":0,"hit":[]})

func step_enemies(dt: float) -> void:
	for e in enemies:
		if state=="dying":break
		if bool(e.defeated): e.dead_age = float(e.get("dead_age",0.))+dt; continue
		if absf(float(e.x)-player.x)>780. and not bool(e.active): continue
		e.active = true; e.age = float(e.age)+dt
		e.flash=maxf(0.,float(e.get("flash",0.))-dt)
		if CampaignGroundShooters.step(self,e,dt):continue
		CampaignWeapons.step_shell(e,dt)
		e.facing = CampaignWeapons.beetle_facing(e,-1 if float(e.x)>player.x else 1)
		if e.kind==CampaignHive.KIND:
			CampaignHive.step(self,e,dt)
			continue
		if CampaignEnemies.step(self,e,dt):continue
		var dx: float = player.x-float(e.x)
		var flying: bool = e.kind in ["crow","moth","drone","wisp"]
		if flying:
			e.y = float(e.home.y)+sin(float(e.age)*2.2)*20.
			if absf(dx)>240.: e.x = float(e.x)+signf(dx)*82.*dt
		elif absf(dx)>155. and e.kind != "seed":
			var candidate: float = clampf(float(e.x)+signf(dx)*(58. if bool(e.mini) else 76.)*dt,60.,length()-80.)
			if CampaignGround.has_floor(floor_at(candidate)):e.x=candidate
		if e.kind in ["gnome","slime"] and absf(dx)>75.:
			var next_x: float=float(e.x)+signf(dx)*62.*dt
			if CampaignGround.has_floor(floor_at(next_x)):e.x=next_x
		if e.kind=="slime":e.y=floor_at(float(e.x))-absf(sin(float(e.age)*3.))*38.
		if float(e.get("dash",0.))>0.:
			e.dash=maxf(0.,float(e.dash)-dt)
			var next_x: float=float(e.x)+float(e.dash_direction)*(260. if e.kind=="beetle" else 220.)*dt
			if CampaignGround.has_floor(floor_at(next_x)):e.x=next_x
			if state=="playing" and absf(player.x-float(e.x))<34. and absf(player.y-float(e.y))<55.:
				enemy_body_hit(e)
				if state!="playing":break
		if float(e.get("dive",0.))>0.:
			e.dive=maxf(0.,float(e.dive)-dt)
			var phase: float=1.-float(e.dive)/float(e.get("dive_duration",.7/.9))
			var p: Vector2=Vector2(e.dive_start).lerp(Vector2(e.dive_target),minf(1.,phase*2.)) if phase<.5 else Vector2(e.dive_target).lerp(Vector2(float(e.dive_target.x)-65.,float(e.home.y)),(phase-.5)*2.)
			if str(e.kind)=="crow" and CampaignRoutes.crow_roof_hit(self,Vector2(e.get("dive_last",e.dive_start)),p):
				e.dive=0.;e.wait=maxf(float(e.wait),1.35)
				e.erase("dive_last")
				continue
			e.x=p.x;e.y=p.y
			if e.dive>0.:e.dive_last=p
			else:e.erase("dive_last")
			if state=="playing" and p.distance_to(player+Vector2(0,-25.))<35. and not (str(e.kind)=="crow" and CampaignRoutes.crow_sheltered(self,player)):
				enemy_body_hit(e)
				if state!="playing":break
		if not flying and e.kind!="slime" and CampaignGround.has_floor(floor_at(float(e.x))) and str(e.kind)!="seed":e.y=floor_at(float(e.x))
		if float(e.windup)>0.:
			e.windup = maxf(0.,float(e.windup)-dt)
			if float(e.windup)==0.:
				enemy_shot(e,bool(e.mini)); e.attacks = int(e.attacks)+1
				var rapid_seed: bool=e.kind=="seed" and (section!="shore" or float(e.home.x)>=1850.)
				e.wait = 1.8 if bool(e.mini) else (1.85 if rapid_seed else 2.2)+float(int(e.attacks)%3)*.25
		else:
			e.wait = float(e.wait)-dt
			if float(e.wait)<=0. and absf(dx)<(150. if e.kind=="gnome" else 600.):
				e.windup = .85 if bool(e.mini) else .65
		if float(e.age)>.35 and absf(dx)<35. and absf(float(e.y)-player.y)<55. and float(e.windup)>.03 and float(e.windup)<.27: enemy_body_hit(e)

func step_boss(dt: float) -> void:
	if not bool(boss.active) or not bool(boss.get("engaged",false)): return
	CampaignBossPressure.step_supply(self,dt)
	boss.clock = float(boss.clock)+dt
	var old_phase: int = int(boss.phase)
	boss.phase = CampaignBossPressure.phase_for(int(boss.hp))
	if int(boss.phase) > old_phase and float(boss.clock) > 0.05:
		CampaignBossPressure.on_phase_change(self, old_phase, int(boss.phase))
	if CampaignBossPressure.motion(self,dt):return
	if int(boss.phase)<3:boss.x = length()-420.+sin(float(boss.clock)*.65)*75.
	boss.y = floor_at(float(boss.x))
	CampaignBossPressure.step_echo(self,dt)
	var old_beam_warning: float=float(boss.get("beam_warning",0.))
	boss.beam_warning=maxf(0.,old_beam_warning-dt)
	if old_beam_warning>0. and float(boss.beam_warning)<=0.:
		if absf(player.x-float(boss.get("beam_x",-999.)))<36.:damage_player("beam")
		blasts.append({"p":Vector2(float(boss.beam_x),floor_at(float(boss.beam_x))-100.),"age":0.,"radius":65.,"color":"efc97e"})
	if float(boss.windup)>0.:
		boss.windup = maxf(0.,float(boss.windup)-dt)
		if float(boss.windup)==0.:
			var attack: int = int(boss.attack)%3
			if CampaignBossPressure.attack(self):pending_events.append("boss_attack")
			elif int(boss.phase)==2 and attack==2:
				boss.beam_x=player.x;boss.beam_warning=.9
				pending_events.append("boss_beam")
			elif attack == 0:
				pending_events.append("boss_port")
				for offset in [-.32,-.16,0.,.16,.32]:
					var ports: Array=boss.get("ports",[3,3])
					var port_index:=0 if offset<=0. else 1
					var late: bool=int(boss.phase)==3
					if not late and int(ports[port_index])<=0:continue
					var port:=Vector2(float(boss.x),float(boss.y)-75.) if late else CampaignBossPressure.port_point(self,port_index)
					var aim := (player+Vector2(0,-42)-port).normalized().rotated(offset)
					bullets.append({"p":port,"v":aim*(265. if late else 230.),"owner":"enemy","age":0.,"kind":"seed","damage":1,"pierce":0,"hit":[],"boss_shot":true})
			elif attack == 1:
				CampaignBossPressure.fire_wave(self)
				if int(boss.phase)==2:platform_timers[2020.]=2.1
			else:
				CampaignBossPressure.call_drones(self)
			boss.attack = int(boss.attack)+1; boss.wait = 2.15-float(int(boss.phase)-1)*.25
	else:
		boss.wait = float(boss.wait)-dt
		if float(boss.wait)<=0.:CampaignBossPressure.arm_warning(self)

func step_bullets(dt: float) -> void:
	var continuing:=state=="continue_offer"
	for b in bullets:
		if float(b.age)>=float(b.get("life",3.)):continue
		if continuing and b.owner!="enemy":b.age=99.;continue
		if b.kind=="frog_spit":
			MissionHeroAbilities.spit_step(self,b,dt)
			continue
		if b.kind=="honeycomb":
			CampaignHive.step_comb(self,b,dt)
			if not continuing and state!="playing":break
			continue
		if CampaignWeapons.step(self,b,dt):continue
		var previous: Vector2=b.get("start",b.p)
		b.erase("start")
		if b.has("gravity"):b.v=Vector2(b.v)+Vector2(0,float(b.gravity)*dt)
		b.age = float(b.age)+dt; b.p = Vector2(b.p)+Vector2(b.v)*dt
		var rocket: bool=b.kind=="rocket" and b.owner=="hero"
		if rocket:
			var contact:=CampaignWeapons.rocket_contact(self,previous,b.p)
			if contact.is_finite():
				CampaignWeapons.rocket_impact(self,b,contact)
				continue
		if b.kind=="wave" and section=="arena":
			b.p.y=floor_at(float(b.p.x))-16.
			previous.y=floor_at(previous.x)-16.
		# Solid route structures stop shots from either side.
		if CampaignRoutes.solid_at(self,b.p) or CampaignGround.touches_ground(self,previous,b.p):b.age=99.;continue
		if b.owner == "enemy":
			var floor:=floor_at(float(b.p.x))
			if CampaignGround.has_floor(floor) and float(b.p.y)>floor:b.age=99.;continue
			if not continuing and Vector2(b.p).distance_to(player_hit_center())<player_hit_radius():
				damage_player("shot")
				b.age=99.
				if state!="playing":break
			continue
		var seg_min_x: float = minf(previous.x, b.p.x) - 105.
		var seg_max_x: float = maxf(previous.x, b.p.x) + 105.
		for e in enemies:
			if bool(e.defeated) or float(e.x) < seg_min_x or float(e.x) > seg_max_x or str(e.id) in b.hit: continue
			if CampaignEnemies.hidden(e):continue
			var radius: float = 58. if bool(e.mini) or bool(e.get("heavy",false)) else float(CampaignContent.NEW_ENEMIES.get(str(e.kind),{}).get("radius",34.))
			if e.kind==CampaignHive.KIND:radius=46.
			var target:=Vector2(float(e.x),float(e.y)-30.)
			var contact:=Geometry2D.get_closest_point_to_segment(target,previous,b.p)
			if contact.distance_to(target)<radius+float(b.get("hit_radius",0.)):
				if rocket:
					CampaignWeapons.rocket_impact(self,b,contact)
					break
				if CampaignWeapons.beetle_blocks(self,e,b,contact):
					b.age=99.
					break
				if bool(e.mini) and float(e.windup)<=.3 and float(e.get("flash",0.))<=0. and (float(e.get("recover",0.))<=0. or CampaignEnemies.active_time(e)>0.) and int(e.hp)>5:b.age=99.;break
				if str(e.kind)=="mirror" and float(e.windup)>0.:
					b.owner="enemy";b.v=-Vector2(b.v);b.age=0.;break
				if b.kind=="nova":CampaignWeapons.blast(self,b.p,170.,int(b.damage),str(b.colour));b.age=99.;break
				damage_enemy(e,int(b.damage)); b.hit.append(str(e.id)); b.pierce = int(b.pierce)-1
				if int(b.pierce)<0: b.age = 99.; break
		if float(b.age)>=float(b.get("life",3.)):continue
		if bool(boss.active) and bool(boss.get("engaged",false)) and CampaignBossPressure.hit(self,b,previous,b.p):
			if rocket:CampaignWeapons.rocket_impact(self,b,b.p,false)
			b.age=99.
			continue
		if bool(boss.active) and Geometry2D.get_closest_point_to_segment(Vector2(float(boss.x),float(boss.y)-75.),previous,b.p).distance_to(Vector2(float(boss.x),float(boss.y)-75.))<105. and not "boss" in b.hit:
			damage_boss(CampaignBossPressure.core_damage(self,b,previous,b.p))
			if rocket:CampaignWeapons.rocket_impact(self,b,b.p,false)
			b.hit.append("boss"); b.age = 99.
		if float(b.age)>=float(b.get("life",3.)):continue
		for crate in crates:
			var center:=Vector2(float(crate.x),float(crate.y)-24.)
			var hit:=Geometry2D.get_closest_point_to_segment(center,previous,b.p)
			if int(crate.hp)>0 and hit.distance_to(center)<30.:
				open_crate(crate)
				if rocket:CampaignWeapons.rocket_impact(self,b,hit)
				b.age=99.
				break
		if float(b.age)>=float(b.get("life",3.)):continue
		if CampaignContent.hit_object(self,b.p,int(b.damage),previous) or CampaignRescue.hit_rope(self,previous,b.p):
			if rocket:CampaignWeapons.rocket_impact(self,b,b.p)
			b.age=99.
		if float(b.p.y)>=floor_at(float(b.p.x)) and float(b.v.y)>0.:b.age=99. # Downward shots collide with solid ground.
	bullets = bullets.filter(func(b):return float(b.age)<float(b.get("life",3.)) and float(b.p.x)>-80. and float(b.p.x)<length()+100.)

func boss_vulnerable() -> bool:
	return CampaignBossPressure.vulnerable(self)

func age_blasts(dt: float) -> void:
	if blasts.is_empty():return
	for blast in blasts:blast.age=float(blast.age)+dt
	blasts=blasts.filter(func(b):return float(b.age)<float(b.get("life",.5)))

func step(dt: float,input_dt: float=-1.) -> void:
	if state=="respawn":
		CampaignLives.step_entry(self,clampf(dt,0.,.05))
		return
	if state=="dying":
		dt=clampf(dt,0.,.05);death_time+=dt
		var old_y:=player.y
		velocity.x=0.;velocity.y+=1700.*dt;player.y+=velocity.y*dt
		var support:=crossing_floor(player.x,old_y,player.y,velocity.y)
		if player.y>=support and velocity.y>=0.:player.y=support;velocity.y=0.
		if death_time>=.8 and (grounded() or CampaignGround.fell_into_pit(self,player) or death_time>1.8):CampaignLives.finish_death(self)
		return
	if state=="continue_offer":
		CampaignLives.tick_offer(self,dt)
		if state!="continue_offer":return
		dt=clampf(dt,0.,.05)
		time+=dt
		CampaignContent.step(self,dt)
		CampaignRescue.step(self,dt)
		CampaignVehicles.step_parked(self,dt)
		step_enemies(dt)
		step_boss(dt)
		step_bullets(dt)
		age_blasts(dt)
		CampaignGrenade.step(self,dt)
		return
	if state=="victory":
		dt=clampf(dt,0.,.05)
		CampaignRescue.step(self,dt)
		var earlier:=victory_time
		victory_time+=dt;boss.clock=float(boss.clock)+dt
		age_blasts(dt)
		for moment in [.25,.62]:
			if earlier<moment and victory_time>=moment:
				var side:=-1. if moment<.4 else 1.
				var part:=Vector2(float(boss.x)+side*76.,float(boss.y)-48.)
				blasts.append({"p":part,"age":0.,"radius":55.,"color":"d9a873"})
				if side>0.:pending_events.append("boss_wave")
		if victory_time>=1.2:state="complete"
		return
	if state != "playing": return
	dt = clampf(dt,0.,.05)
	if mount_transition!="":
		CampaignVehicles.step_transition(self,dt)
		return
	CampaignVehicles.step_damage(self,dt)
	time += dt
	CampaignLives.step_protection(self,dt)
	CampaignStyle.step(self,dt)
	CampaignRescue.step(self,dt)
	CampaignContent.step(self,dt);CampaignVehicles.step_parked(self,dt)
	for property in ["hurt_time","fire_time","shot_flash","melee_time","grenade_time","flap_time","notice_time","drop_through_time"]: set(property,maxf(0.,float(get(property))-dt))
	if not melee_hit_done and melee_time<=.14:
		melee_hit_done=true
		if melee_target=="boss":
			if absf(float(boss.x)-player.x)<150.:damage_boss(2)
		elif melee_target.is_empty():CampaignWeapons.melee_environment(self)
		else:
			for enemy in enemies:
				if str(enemy.id)==melee_target and absf(float(enemy.x)-player.x)<125. and absf(float(enemy.y)-player.y)<85.:damage_enemy(enemy,2,"melee")
	var on_floor := grounded()
	if on_floor and not CampaignRoutes.low_ceiling(self): coyote_timer = COYOTE_TIME
	else: coyote_timer = maxf(0., coyote_timer - dt)
	jump_buffer_timer = maxf(0., jump_buffer_timer - dt)
	if waiting_to_charge or charging:
		# The visible hold uses the active input clock even on a slow frame.
		# Physics remains bounded and blur/pause cancels the unspent input.
		step_jump_charge(dt if input_dt<0. else clampf(input_dt,0.,.5),on_floor)
	var speed: float = 235.*(1.55 if boost_held else 1.)*(1.35 if bool(mount.ridden) else 1.)*(1.25 if float(buffs.get("haste",0.))>0. else 1.)*(.65 if float(buffs.get("slow",0.))>0. else 1.)
	velocity.x = MissionHeroAbilities.movement_speed(self,move_axis.x*speed*(.3 if charging else (.42 if crouching() else 1.)))
	if rescue_time>0. or CampaignVehicles.stunned(self):velocity.x=0.
	if eject_target_x>=0.:
		velocity.x=clampf((eject_target_x-player.x)/maxf(dt,.001),-980.,980.)
		if absf(eject_target_x-player.x)<1.:eject_target_x=-1.
	if absf(aim_direction.x)>.15: facing = 1 if aim_direction.x>0. else -1
	var before_movement := player
	var old_x: float = before_movement.x
	player.x = clampf(player.x+velocity.x*dt,35.,length()-90.)
	player.x = CampaignRoutes.clamp_horizontal(self,old_x,player.x)
	# Solid object gates must block a fast roll on the crossing tick too.
	for object in objects:
		if str(object.kind)!="gate" or bool(object.active) or player.y<=float(object.y)-80.:continue
		var left: float=float(object.x)-40.
		var right: float=float(object.x)+45.
		if old_x<=left and player.x>left:player.x=left
		elif old_x>=right and player.x<right:player.x=right
	var alive:=alive_enemy_ids() if not gates.is_empty() else {}
	for gate in gates:
		if gate_closed(gate,alive) if not alive.is_empty() else false:
			gate.open_age=0.
			if old_x<=float(gate.x):player.x=minf(player.x,float(gate.x))
		else:gate.open_age=minf(.4,float(gate.get("open_age",.4))+dt)
	# Animation and inherited throw speed follow the resolved movement, not
	# an intent that a boundary, locked gate or solid pier has blocked.
	velocity.x=(player.x-old_x)/dt if dt>0. else 0.
	walk_distance += absf(player.x-old_x)
	# Walking already grounded on the main surface follows its gradual
	# height in both directions. Airborne actors still land via crossing_floor.
	if on_floor and absf(player.x-old_x)>.01 and CampaignGround.PROFILES.has(section):
		var saddle:=42. if bool(mount.ridden) else 0.
		var previous_ground:=floor_at(old_x)
		var upcoming_ground:=floor_at(player.x)
		if CampaignGround.has_floor(upcoming_ground) and absf(player.y+saddle-previous_ground)<.1 and absf(upcoming_ground-previous_ground)<28.:
			player.y=upcoming_ground-saddle
	var old_y: float = player.y
	if bool(mount.ridden):
		mount.x = player.x
		if not CampaignVehicles.stunned(self):CampaignVehicles.step(self,dt)
	else:
		gliding = character == "owl" and jump_held and velocity.y>0. and not on_floor
		velocity.y += 1700.*(.12 if gliding else 1.)*dt
		if gliding: velocity.y = minf(velocity.y,85.)
		player.y += velocity.y*dt
		if player.y < -900.: player.y = -900.; velocity.y = maxf(0.,velocity.y)
		var support: float = crossing_floor(player.x,old_y,player.y,velocity.y)
		if player.y>=support and velocity.y>=0.:
			player.y = support; velocity.y = 0.; jumps = 0; flap_count = 0; flap_time = 0.; gliding = false; air_time = 0.
			if jump_buffer_timer > 0. and not CampaignRoutes.low_ceiling(self) and character not in CHARGE_HEROES:
				velocity.y = -650.; jumps = 1; jump_buffer_timer = 0.; coyote_timer = 0.
		else: air_time += dt
	if CampaignGround.fell_into_pit(self,player):
		damage_player("pit")
		if state!="playing":return
	MissionHeroAbilities.sprint_contacts(self,before_movement,on_floor,dt)
	if state!="playing":return
	if velocity.y>0.:
		for enemy in enemies:
			if bool(enemy.defeated) or CampaignEnemies.hidden(enemy):continue
			var top: float=float(enemy.y)-58.
			if absf(player.x-float(enemy.x))<34. and old_y<=top and player.y>=top:
				damage_enemy(enemy,2 if bool(enemy.mini) else 1,"stomp");player.y=top-2.;velocity.y=-420.;jumps=1;air_time=0.;pending_events.append("melee");break
	if not shell_contacts.is_empty() or MissionHeroAbilities.rolling(self):
		MissionHeroAbilities.trace_shell_contact(self,on_floor,player.x-old_x)
	MissionHeroAbilities.step(self,dt)
	if fire_held: attack()
	step_enemies(dt)
	if state!="playing":return
	if MissionHeroAbilities.sprinting(self):
		MissionHeroAbilities.sprint_hit(self,player_hit_center(),player_hit_center())
		if state!="playing":return
	CampaignAssists.step(self,dt);step_boss(dt)
	if state!="playing":return
	step_bullets(dt)
	if state!="playing":return
	# Age existing effects first: a new blast must retain its ignition cel.
	age_blasts(dt)
	CampaignGrenade.step(self,dt)
	if CampaignVehicles.stunned(self):return
	CampaignWeapons.step_spider_parade(self)
	for item in pickups:
		item.age=float(item.get("age",0.))+dt
		# No contact rule reaches beyond 160px horizontally (rider rect 92, foot 63).
		if absf(float(item.x)-player.x)>160.:continue
		if item.has("secret") and not discovered.has(str(item.secret)):continue
		if item.has("rescue_id") and float(item.age)<.25:continue
		if not taken.has(str(item.id)) and touches_pickup(item):collect(item)
	CampaignRecovery.step(self)
	trail.append({"p":player,"time":time,"facing":facing,"grounded":grounded(),"crouched":crouching(),"walk_distance":walk_distance,"moving":absf(velocity.x)>1.,"velocity_y":velocity.y,"air_time":air_time})
	while trail.size()>1 and time-float(trail[0].time)>4.: trail.pop_front()
	if CampaignRoutes.is_fork(section):
		CampaignRoutes.step(self);return
	if player.x>=length()-130. and section != "arena" and grounded():
		var blocked := false
		for npc in npcs:
			if str(npc.get("phase",""))=="thanks" and float(npc.get("thank_age",0.))<1.7:blocked=true
		for e in enemies:
			if not bool(e.defeated) and (bool(e.mini) or float(e.x)>length()-650.): blocked = true
		if not blocked:
			begin_travel(str(STAGES[section].next))

func life_rescues() -> int:
	return maxi(0,rescued.size()-rescue_life_start)

func snapshot(include_encounter: bool=true) -> Dictionary:
	var data := {"schema":4,"rally":rally,"retry_count":retry_count,"best_chain":best_chain,"rescue_roles":rescue_roles,"greeted":greeted,"gift_drops":gift_drops,"losses":losses,"weapons_used":weapons_used,"vehicles_used":vehicles_used,"run_seed":run_seed,"character":character,"checkpoint":checkpoint,"checkpoint_ready":checkpoint_ready,"score":score,"kills":kills,"rescued":rescued,"rescue_life_start":rescue_life_start,"awarded":awarded,"taken":taken,"route":route,"completed":completed,"time":time,"flock":flock,"discovered":discovered,"activated":activated,"attempts":attempts_remaining,"continues":continues_used}.duplicate(true)
	if character=="frog" and not completed:
		data.frog_meal=frog_meal.duplicate()
		data.frog_cooldown=frog_cooldown
	if character=="armadillo" and not completed:
		data.roll_charges=roll_charges
		data.roll_cooldown=roll_cooldown if roll_cooldown>0. or roll_charges>0 else MissionHeroAbilities.ROLL_COOLDOWN
	if include_encounter:
		data.shield_charge=shield_charge
		CampaignEncounterSave.write(self,data)
	return data

func restore(data: Dictionary) -> bool:
	if int(data.get("schema",0)) not in [1,2,3,4] or not STAGES.has(str(data.get("checkpoint",""))): return false
	if str(data.get("character","")) not in HEROES and str(data.get("character","")) not in ["owl","wolf"]: return false
	for key in ["rescued","route","weapons_used","vehicles_used"]:
		if not data.get(key,[]) is Array or data.get(key,[]).size()>512:return false
		for item in data.get(key,[]):
			if not item is String:return false
	for key in ["awarded","taken","discovered","activated","greeted","rescue_roles","gift_drops"]:
		if not data.get(key,{}) is Dictionary or data.get(key,{}).size()>4096:return false
	for id in Dictionary(data.get("gift_drops",{})):
		var item=Dictionary(data.get("gift_drops",{}))[id]
		if not id is String or not item is Dictionary:return false
		if str(item.get("id",""))!=str(id)+":supply" or str(item.get("rescue_id",""))!=str(id):return false
		if not CampaignRescue.valid_gift(CampaignWeapons.canonical_kind(str(item.get("kind","")))) or str(item.get("role","")) not in CampaignRescue.ROLES:return false
		for key in ["x","y"]:
			if typeof(item.get(key,null)) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(item[key])) or absf(float(item[key]))>10000000.:return false
	for key in ["score","kills","time","flock","losses"]:
		var number=data.get(key,0)
		if typeof(number) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(number)) or absf(float(number))>1000000000.:return false
	if not CampaignEncounterSave.valid_number(data.get("rescue_life_start",0),0,Array(data.get("rescued",[])).size()):return false
	if data.has("completed") and not data.completed is bool:return false
	var meal=data.get("frog_meal",{})
	if not meal is Dictionary:return false
	if not meal.is_empty():
		if str(data.character)!="frog" or meal.size()!=2 or meal.get("kind") not in MissionHeroAbilities.SWALLOWABLE:return false
		if not meal.get("id") is String or not Dictionary(data.get("awarded",{})).has(meal.id):return false
	if not CampaignEncounterSave.valid_number(data.get("frog_cooldown",0.),0.,MissionHeroAbilities.LEGACY_SWALLOW_COOLDOWN):return false
	if not CampaignEncounterSave.valid_number(data.get("roll_charges",MissionHeroAbilities.ROLL_CHARGES),0,MissionHeroAbilities.ROLL_CHARGES):return false
	if not CampaignEncounterSave.valid_number(data.get("roll_cooldown",0.),0.,MissionHeroAbilities.ROLL_COOLDOWN):return false
	if not CampaignEncounterSave.valid_number(data.get("shield_charge",0.),0.,LEGACY_SHIELD_CHARGE_MAX):return false
	if not CampaignRecovery.valid(data.get("rally",{}),str(data.checkpoint)):return false
	for key in ["retry_count","best_chain"]:
		var value=data.get(key,0)
		if typeof(value) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(value)) or float(value)<0. or float(value)>1000000.:return false
	var encounter: Dictionary={}
	if int(data.schema)==4:
		encounter=CampaignEncounterSave.read(data)
		if encounter.is_empty():return false
	rally=Dictionary(data.get("rally",{})).duplicate(true);retry_count=int(data.get("retry_count",0));best_chain=int(data.get("best_chain",0))
	if not rally.is_empty():CampaignWeapons.migrate_stock(rally)
	character = str(data.character) if str(data.character) in HEROES else "aion"; score = maxi(0,int(data.get("score",0))); kills = maxi(0,int(data.get("kills",0)))
	losses=maxi(0,int(data.get("losses",0)));vehicles_used.assign(Array(data.get("vehicles_used",[])))
	weapons_used.clear()
	for name in data.get("weapons_used",[]):
		var kind:=CampaignWeapons.canonical_kind(str(name))
		if not weapons_used.has(kind):weapons_used.append(kind)
	greeted=Dictionary(data.get("greeted",{}));gift_drops=Dictionary(data.get("gift_drops",{})).duplicate(true);rescue_roles=Dictionary(data.get("rescue_roles",{}))
	for item in gift_drops.values():item.kind=CampaignWeapons.canonical_kind(str(item.kind))
	run_seed=clampi(int(data.get("run_seed",7719)),1,2000000000)
	rescued.assign(Array(data.get("rescued",[]))); rescue_life_start=int(data.get("rescue_life_start",rescued.size() if losses>0 and not bool(data.get("completed",false)) else 0)); awarded = Dictionary(data.get("awarded",{})); taken = Dictionary(data.get("taken",{}))
	discovered=Dictionary(data.get("discovered",{}));activated=Dictionary(data.get("activated",{}))
	if int(data.schema)==1:
		for id in rescued:awarded[str(id)+":gift"]=true # Old rescues must not manufacture new supplies.
	route.assign(Array(data.get("route",[]))); completed = bool(data.get("completed",false)); time = maxf(0.,float(data.get("time",0.)))
	flock = clampi(int(data.get("flock",1)),1,MAX_FLOCK); hp = max_hp; grenades = 5
	weapon="pistol";ammunition=CampaignWeapons.PISTOL_START;pistol_reserve=0
	CampaignLives.reset(self)
	MissionHeroAbilities.reset(self)
	load_section(str(data.checkpoint))
	if character=="frog":
		frog_meal=meal.duplicate()
		frog_cooldown=minf(float(data.get("frog_cooldown",0.)),MissionHeroAbilities.SWALLOW_COOLDOWN)
	if character=="armadillo":
		roll_charges=int(data.get("roll_charges",MissionHeroAbilities.ROLL_CHARGES))
		roll_cooldown=clampf(float(data.get("roll_cooldown",0.)),0.,MissionHeroAbilities.ROLL_COOLDOWN)
		if roll_charges==0 and roll_cooldown<=0.:roll_charges=MissionHeroAbilities.ROLL_CHARGES
	if encounter.is_empty():
		CampaignRecovery.apply(self,rally)
	else:
		CampaignEncounterSave.apply(self,data,encounter)
		CampaignBossPressure.migrate_saved_state(boss)
		CampaignRoutes.after_restore(self)
		CampaignWeapons.populate_sidearm(self)
		if hp>0:shield_charge=minf(float(data.get("shield_charge",0.)),CampaignLives.SHIELD_CHARGE_SECONDS)
	if completed: state = "complete"; checkpoint_ready = false; boss.active = false
	return true
