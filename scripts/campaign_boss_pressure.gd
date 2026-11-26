class_name CampaignBossPressure
extends RefCounted

const ACTIVE_DRONE_LIMIT := 2
const MAX_HP := 270
const LEGACY_MAX_HP := 90
const PHASE_TWO_HP := 180
const PHASE_THREE_HP := 90
const DASH_SPEED := 500.
const DASH_TIME := .95
const DASH_WINDUP := .95
const DASH_RADIUS := 95.
const DASH_MIN_X := 1860.
const CORE_RECOVERY := 1.1
const HULL_RADIUS := 105.
const ECHO_DELAY := .64
const WAVE_SPEED := 320.
const WAVE_OFFSET := 60.
const WAVE_LIFE := 3.
const ERUPTION_WARNING := 1.05
const ERUPTION_TIME := .26
const ERUPTION_RADIUS := 90.
const ERUPTION_HEIGHT := 106.
const VICTORY_SECONDS := 1.2
const LANTERN_BEATS := [.18, .46, .74]
# The service alcove is outside the main charge lane, reachable on foot by
# every hero. The station refills only the low sidearm, never premium ammo.
const SUPPLY_X := 1740.
const SUPPLY_LOW := 14
const SUPPLY_ROUNDS := 32
const SUPPLY_RECHARGE := [2.2, 2.6, 3.]

static func initial_state(x: float) -> Dictionary:
	return {
		"active":false, "engaged":false, "hp":MAX_HP, "max_hp":MAX_HP,
		"x":x, "y":0., "clock":0., "attack":0, "windup":0., "wait":1.4, "phase":1,
		"supply_cooldown":0.
	}

static func phase_for(hp: int) -> int:
	return 1+int(hp<PHASE_TWO_HP)+int(hp<PHASE_THREE_HP)

static func migrate_saved_state(boss: Dictionary) -> void:
	if boss.get("max_hp")==LEGACY_MAX_HP and boss.get("hp") is int:
		boss.hp=roundi(clampf(float(boss.hp)/LEGACY_MAX_HP,0.,1.)*MAX_HP)
		boss.max_hp=MAX_HP
		boss.phase=phase_for(int(boss.hp))

static func vulnerable(w) -> bool:
	var boss: Dictionary=w.boss
	if float(boss.get("shift_pause",0.))>0. or float(boss.get("dash",0.))>0.:
		return false
	return int(boss.phase)!=2 or float(boss.windup)>.15 or float(boss.wait)>.8

static func core_exposed(w) -> bool:
	if not vulnerable(w):return false
	match int(w.boss.phase):
		1:
			return float(w.boss.wait)>.8 or float(w.boss.get("port_open",0.))>0.
		2:
			return true
	return float(w.boss.get("recover",0.))>0.

static func hud_cue(w) -> String:
	var boss: Dictionary=w.boss
	if float(boss.get("beam_warning",0.))>0. or float(boss.get("eruption",0.))>0.:
		return "boss_beam_move"
	if float(boss.get("echo_wait",0.))>0.:return "boss_echo"
	if float(boss.windup)>0.:
		match int(boss.attack)%3:
			1:return "boss_wave_jump"
			2:
				if int(boss.phase)==3:return "boss_dash"
		return "boss_warning"
	if core_exposed(w):return "boss_core"
	return ""

static func step(w,dt: float) -> void:
	var boss: Dictionary=w.boss
	if not bool(boss.active) or not bool(boss.engaged):return
	step_supply(w,dt)
	boss.clock=float(boss.clock)+dt
	var phase:=phase_for(int(boss.hp))
	if phase>int(boss.phase) and float(boss.clock)>.05:on_phase_change(w,int(boss.phase),phase)
	boss.phase=phase
	boss.port_open=maxf(0.,float(boss.get("port_open",0.))-dt)
	if motion(w,dt):return
	if phase<3:boss.x=w.length()-420.+sin(float(boss.clock)*.65)*75.
	boss.y=w.floor_at(float(boss.x))
	step_echo(w,dt)
	step_eruption(w,dt)
	if float(boss.windup)>0.:
		boss.windup=maxf(0.,float(boss.windup)-dt)
		if float(boss.windup)>0.:return
		var pattern:=int(boss.attack)%3
		if attack(w):w.pending_events.append("boss_attack")
		elif pattern==0:fire_fan(w)
		elif pattern==1:fire_wave(w)
		elif phase==2:arm_eruption(w)
		else:call_drones(w)
		if phase==2 and pattern==1:w.platform_timers[2020.]=2.1
		boss.attack=int(boss.attack)+1
		boss.wait=2.15-float(phase-1)*.25
	else:
		boss.wait=float(boss.wait)-dt
		if float(boss.wait)<=0.:arm_warning(w)

static func fire_fan(w) -> void:
	w.pending_events.append("boss_port")
	var ports: Array=w.boss.get("ports",[3,3])
	var phase:=int(w.boss.phase)
	for angle in [-.32,-.16,0.,.16,.32]:
		var side:=int(angle>0.)
		if phase==1 and int(ports[side])<=0:continue
		var origin:=port_point(w,side) if phase==1 else core_point(w)
		var heading: Vector2=(w.player+Vector2(0.,-42.)-origin).normalized().rotated(angle)
		w.bullets.append({"p":origin,"v":heading*(265. if phase==3 else 230.),"owner":"enemy","age":0.,"kind":"seed","damage":1,"pierce":0,"hit":[],"boss_shot":true})

static func arm_eruption(w) -> void:
	w.boss.beam_x=clampf(w.player.x,ERUPTION_RADIUS,w.length()-ERUPTION_RADIUS)
	w.boss.beam_warning=ERUPTION_WARNING
	w.boss.eruption_hit=false
	w.pending_events.append("boss_beam")

static func step_eruption(w,dt: float) -> void:
	var warning: float=w.boss.get("beam_warning",0.)
	var active: float=w.boss.get("eruption",0.)
	if warning<=0. and active<=0.:return
	if warning>0.:
		w.boss.beam_warning=maxf(0.,warning-dt)
		if float(w.boss.beam_warning)>0.:return
		active=ERUPTION_TIME-(dt-warning)
		w.pending_events.append("boss_eruption")
	else:active=maxf(0.,active-dt)
	w.boss.eruption=active
	if active<=0. or bool(w.boss.get("eruption_hit",false)):return
	if absf(w.player.x-float(w.boss.beam_x))>=ERUPTION_RADIUS:return
	if w.player.y<=w.floor_at(w.player.x)-ERUPTION_HEIGHT:return
	w.boss.eruption_hit=true
	w.damage_player("beam")

static func supply_point(w) -> Vector2:
	return Vector2(SUPPLY_X,w.floor_at(SUPPLY_X))

static func supply_ready(w) -> bool:
	return bool(w.boss.engaged) and float(w.boss.get("supply_cooldown",0.))<=0. and CampaignWeapons.sidearm_stock(w)<=SUPPLY_LOW

static func step_supply(w,dt: float) -> void:
	if w.state!="playing" or w.section!="arena" or not bool(w.boss.active) or not bool(w.boss.engaged):
		return
	w.boss.supply_cooldown=maxf(0.,float(w.boss.get("supply_cooldown",0.))-dt)
	if absf(w.player.x-SUPPLY_X)>96. or not supply_ready(w):
		return
	var point:=supply_point(w)-Vector2(0.,20.)
	if not w.touches_pickup({"id":"arena:pistol_dispenser","x":point.x,"y":point.y,"kind":"pistol_ammo"}):
		return
	CampaignWeapons.grant_sidearm(w,SUPPLY_ROUNDS)
	w.boss.supply_cooldown=SUPPLY_RECHARGE[clampi(int(w.boss.phase)-1,0,2)]
	w.notice="boss_supply_taken"
	w.notice_time=1.65
	w.pending_events.append("pickup")
	w.pending_events.append("boss_supply")

static func draw_supply(view) -> void:
	var w=view.world
	if w.section!="arena" or not bool(w.boss.active) or SUPPLY_X<view.camera_x-36. or SUPPLY_X>view.camera_x+view.scene_w+36.:
		return
	var foot: Vector2=view.at(supply_point(w)).round()
	var ready:=supply_ready(w)
	var recharge:=float(w.boss.get("supply_cooldown",0.))
	var copper:=Color("cf9862")
	var frame:=Color("253242")
	var lamp:=Color("bce6ae") if ready else Color("987351")
	view.draw_rect(Rect2(foot+Vector2(-26.,-38.),Vector2(52.,38.)),Color("161d2a"))
	view.draw_rect(Rect2(foot+Vector2(-22.,-34.),Vector2(44.,29.)),frame)
	view.draw_rect(Rect2(foot+Vector2(-18.,-39.),Vector2(36.,5.)),copper)
	view.draw_rect(Rect2(foot+Vector2(-17.,-25.),Vector2(34.,15.)),Color("111b26"))
	for i in 3:
		var tab:=foot+Vector2(-10.+i*8.,-23.)
		view.draw_rect(Rect2(tab,Vector2(4.,10.)),lamp)
		view.draw_rect(Rect2(tab+Vector2(1.,-2.),Vector2(2.,2.)),Color("f4cf91") if ready else frame)
	for side in [-1.,1.]:
		view.draw_rect(Rect2(foot+Vector2(side*19.-2.,-30.),Vector2(4.,4.)),copper)
		view.draw_rect(Rect2(foot+Vector2(side*20.-6.,-5.),Vector2(12.,5.)),Color("655566"))
	if recharge>0.:
		var interval: float=SUPPLY_RECHARGE[clampi(int(w.boss.phase)-1,0,2)]
		view.draw_rect(Rect2(foot+Vector2(-17.,-8.),Vector2(floorf(34.*(1.-clampf(recharge/interval,0.,1.))),2.)),copper)
	if ready and absf(w.player.x-SUPPLY_X)<210. and view.font!=null:
		var label: String=view.host.t("boss_supply_ready")
		var width: float=ceilf(view.font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x)
		var label_pos:=foot+Vector2(-roundf(width*.5),-49.)
		view.draw_rect(Rect2(label_pos-Vector2(4.,13.),Vector2(width+8.,17.)),Color("181b28e8"))
		view.caption(label,label_pos,14)

static func call_drones(w) -> void:
	var available:=ACTIVE_DRONE_LIMIT
	for enemy in w.enemies:
		if str(enemy.kind)=="drone" and not bool(enemy.defeated):available-=1
	if available<=0:return
	w.pending_events.append("boss_attack")
	for i in available:
		w.spawn_enemy("drone",float(w.boss.x)-120.-i*110.,float(w.boss.y)-135.-i*25.,200+int(w.boss.attack)*2+i)

static func port_point(w,index: int) -> Vector2:
	return Vector2(float(w.boss.x)+(-65. if index==0 else 65.),float(w.boss.y)-95.)

static func core_point(w) -> Vector2:
	# Keep the damage point and armor aligned with the painted chest lens.
	return Vector2(float(w.boss.x),float(w.boss.y)-54.)

static func impact_path_end(w, from: Vector2, to: Vector2) -> Vector2:
	# The player's projectile ends at the broad hull. Test the aim line
	# through that hull for an exposed socket so short physics slices can
	# still reward an accurate shot before the visible impact removes it.
	var core:=core_point(w)
	if Geometry2D.get_closest_point_to_segment(core,from,to).distance_squared_to(core)>=HULL_RADIUS*HULL_RADIUS:
		return to
	return to+(to-from).normalized()*HULL_RADIUS*2.

static func damage_allowed(w,amount: int) -> int:
	var boss: Dictionary=w.boss
	if not vulnerable(w):
		if amount>0:shield_deflect(w,w.player.x)
		return 0
	# A single bomb or fast burst may reach the next phase. The remaining
	# force of that same hit cannot bypass its new attack and recovery rhythm.
	var threshold:=PHASE_TWO_HP-1 if int(boss.phase)==1 else (PHASE_THREE_HP-1 if int(boss.phase)==2 else 0)
	return clampi(amount,0,maxi(0,int(boss.hp)-threshold))

static func on_phase_change(w,old_phase: int,new_phase: int) -> void:
	if new_phase<=old_phase:return
	w.boss.beam_warning=0.
	w.boss.eruption=0.
	w.boss.echo_wait=0.
	w.boss.lane_direction=0.
	w.boss.windup=0.
	w.boss.dash=0.
	w.boss.recover=0.
	w.boss.port_open=0.
	w.boss.ports=[0,0]
	w.boss.shift_pause=0.75
	# The exposed window starts only after the warning has resolved.
	w.boss.wait=maxf(float(w.boss.wait),0.95)
	for bullet in w.bullets:
		if bool(bullet.get("boss_shot",false)):bullet.age=99.
	w.pending_events.append("mechanism")

static func hit(w,bullet: Dictionary,from: Vector2,to: Vector2) -> bool:
	var boss: Dictionary=w.boss
	if float(boss.get("shift_pause",0.))>0.:return false
	if int(boss.phase)==1:
		if float(boss.x)<minf(from.x,to.x)-HULL_RADIUS or float(boss.x)>maxf(from.x,to.x)+HULL_RADIUS:
			return false
		if not boss.has("ports"):boss.ports=[3,3]
		var path_end:=impact_path_end(w,from,to)
		for side in 2:
			var i:=1-side if from.x>float(boss.x) else side
			if int(boss.ports[i])<=0:continue
			var target:=port_point(w,i)
			if Geometry2D.get_closest_point_to_segment(target,from,path_end).distance_squared_to(target)>625.:continue
			boss.ports[i]=maxi(0,int(boss.ports[i])-int(bullet.damage));w.damage_boss(int(bullet.damage)*2)
			w.pending_events.append("armour_hit")
			if int(boss.ports[i])==0:
				boss.port_open=1.35
				w.award("boss:port:"+str(i),150)
				w.pending_events.append("enemy")
			return true
	return false

static func motion(w,dt: float) -> bool:
	if float(w.boss.get("shift_pause",0.))>0.:
		w.boss.shift_pause=maxf(0.,float(w.boss.shift_pause)-dt)
		return true
	if float(w.boss.get("recover",0.))>0.:
		w.boss.recover=maxf(0.,float(w.boss.recover)-dt)
		return true
	if float(w.boss.get("dash",0.))<=0.:return false
	var active_dt: float=minf(dt,float(w.boss.dash))
	w.boss.dash=maxf(0.,float(w.boss.dash)-dt)
	var from: float=w.boss.x
	var direction: float=w.boss.get("dash_direction",-1.)
	w.boss.x=dash_destination(w,direction,active_dt)
	w.boss.y=w.floor_at(float(w.boss.x))
	var nearest:=clampf(w.player.x,minf(from,float(w.boss.x)),maxf(from,float(w.boss.x)))
	if absf(w.player.x-nearest)<DASH_RADIUS and w.player.y>w.floor_at(nearest)-80.:w.damage_player("impact")
	if absf(float(w.boss.x)-from)<active_dt*DASH_SPEED-.01:w.boss.dash=0.
	if float(w.boss.dash)<=0.:
		w.boss.recover=maxf(0.,CORE_RECOVERY-(dt-active_dt))
		w.boss.wait=maxf(float(w.boss.wait),1.15)
		w.pending_events.append("boss_core_open")
	return true

static func dash_destination(w,direction: float,seconds: float=DASH_TIME) -> float:
	return clampf(float(w.boss.x)+direction*DASH_SPEED*seconds,DASH_MIN_X,w.length()-170.)

static func lane_direction(w) -> float:
	var locked: float=w.boss.get("lane_direction",0.)
	if locked!=0.:return locked
	return -1. if w.player.x<=float(w.boss.x) else 1.

static func arm_warning(w) -> void:
	w.boss.windup=DASH_WINDUP
	w.boss.lane_direction=0.
	var pattern: int=int(w.boss.attack)%3
	if pattern==1:w.boss.lane_direction=lane_direction(w)
	if pattern==2 and int(w.boss.phase)==3:
		var direction:=lane_direction(w)
		if absf(dash_destination(w,direction)-float(w.boss.x))<150.:direction=-direction
		w.boss.lane_direction=direction
		w.boss.dash_direction=direction
		w.pending_events.append("boss_charge_warning")

static func dash_warning(w) -> bool:
	return int(w.boss.phase)==3 and int(w.boss.attack)%3==2 and float(w.boss.windup)>0.

static func sprite_facing(w) -> int:
	# The authored atlas looks left. Keep the committed direction through
	# windup, charge and recovery, so the turn never follows the player mid-hit.
	return -1 if int(w.boss.phase)==3 and float(w.boss.get("dash_direction",-1.))>0. else 1

static func fire_wave(w) -> void:
	var direction:=lane_direction(w)
	emit_wave(w,direction)
	if int(w.boss.phase)==3:
		w.boss.echo_wait=ECHO_DELAY
		w.boss.echo_direction=direction

static func step_echo(w,dt: float) -> void:
	var remaining: float=w.boss.get("echo_wait",0.)
	if remaining<=0.:return
	w.boss.echo_wait=maxf(0.,remaining-dt)
	if float(w.boss.echo_wait)==0.:emit_wave(w,float(w.boss.get("echo_direction",-1.)),true)

static func emit_wave(w,direction: float,echo: bool=false) -> void:
	var x:=float(w.boss.x)+direction*WAVE_OFFSET
	w.pending_events.append("boss_wave_echo" if echo else "boss_wave")
	w.bullets.append({"p":Vector2(x,w.floor_at(x)-16.),"v":Vector2(direction*WAVE_SPEED,0.),"owner":"enemy","age":0.,"kind":"wave","damage":1,"pierce":0,"hit":[],"life":WAVE_LIFE,"boss_shot":true,"echo":echo})

static func core_damage(w,bullet: Dictionary,from: Vector2,to: Vector2) -> int:
	var damage: int=int(bullet.damage)
	if not vulnerable(w):
		shield_deflect(w,from.x)
		return 0
	if core_exposed(w):
		var core:=core_point(w)
		if Geometry2D.get_closest_point_to_segment(core,from,impact_path_end(w,from,to)).distance_squared_to(core)<900.:
			return damage*(3 if int(w.boss.phase)==3 else 2)
	return damage

static func shield_deflect(w,source_x: float) -> void:
	w.boss.shield_contact=float(w.boss.clock)
	w.boss.shield_side=-1. if source_x<float(w.boss.x) else 1.
	w.pending_events.append("armour_hit")

static func attack(w) -> bool:
	if int(w.boss.phase)!=3 or int(w.boss.attack)%3!=2:return false
	w.boss.beam_warning=0.
	w.boss.dash=DASH_TIME
	w.boss.dash_direction=lane_direction(w)
	return true

static func begin_victory(w) -> void:
	w.boss.beam_warning=0.
	w.boss.eruption=0.
	w.boss.echo_wait=0.
	w.boss.windup=0.
	w.boss.dash=0.
	w.boss.recover=0.
	w.boss.shift_pause=0.

static func step_victory(w,dt: float) -> void:
	var before: float=w.victory_time
	w.victory_time=minf(VICTORY_SECONDS,before+dt)
	for moment in LANTERN_BEATS:
		if before<float(moment) and w.victory_time>=float(moment):
			w.pending_events.append("boss_lantern")
	if w.victory_time>=VICTORY_SECONDS:w.state="complete"
