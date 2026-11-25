class_name CampaignBossPressure
extends RefCounted

const ACTIVE_DRONE_LIMIT := 2
const MAX_HP := 270
const LEGACY_MAX_HP := 90
const PHASE_TWO_HP := 180
const PHASE_THREE_HP := 90
const DASH_SPEED := 500.
const DASH_TIME := .95
const DASH_RADIUS := 95.
const DASH_MIN_X := 1860.
const CORE_RECOVERY := 1.1
const HULL_RADIUS := 105.
const ECHO_DELAY := .64
const WAVE_SPEED := 320.
const WAVE_OFFSET := 60.
const WAVE_LIFE := 3.
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
	return vulnerable(w) and (int(w.boss.phase)==2 or (int(w.boss.phase)==3 and float(w.boss.get("recover",0.))>0.))

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
	return Vector2(float(w.boss.x),float(w.boss.y)-75.)

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
	if not vulnerable(w):return 0
	# A single bomb or fast burst may reach the next phase. The remaining
	# force of that same hit cannot bypass its new attack and recovery rhythm.
	var threshold:=PHASE_TWO_HP-1 if int(boss.phase)==1 else (PHASE_THREE_HP-1 if int(boss.phase)==2 else 0)
	return clampi(amount,0,maxi(0,int(boss.hp)-threshold))

static func on_phase_change(w,old_phase: int,new_phase: int) -> void:
	if new_phase<=old_phase:return
	w.boss.beam_warning=0.
	w.boss.echo_wait=0.
	w.boss.lane_direction=0.
	w.boss.windup=0.
	w.boss.dash=0.
	w.boss.recover=0.
	w.boss.shift_pause=0.75
	# The exposed window starts only after the warning has resolved.
	w.boss.wait=maxf(float(w.boss.wait),0.95)
	for bullet in w.bullets:
		if bool(bullet.get("boss_shot",false)):bullet.age=99.
	w.pending_events.append("mechanism")
	w.blasts.append({"p":Vector2(float(w.boss.x),float(w.boss.y)-85.),"age":0.,"radius":95.,"color":"ffcf8c"})

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
			if int(boss.ports[i])==0:w.award("boss:port:"+str(i),150);w.pending_events.append("enemy")
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
	w.boss.x=dash_destination(w,float(w.boss.get("dash_direction",-1.)),active_dt)
	w.boss.y=w.floor_at(float(w.boss.x))
	var nearest:=clampf(w.player.x,minf(from,float(w.boss.x)),maxf(from,float(w.boss.x)))
	if absf(w.player.x-nearest)<DASH_RADIUS and w.player.y>w.floor_at(nearest)-80.:w.damage_player("impact")
	if float(w.boss.dash)<=0.:
		w.boss.recover=maxf(0.,CORE_RECOVERY-(dt-active_dt))
		w.boss.wait=maxf(float(w.boss.wait),1.15)
	return true

static func dash_destination(w,direction: float,seconds: float=DASH_TIME) -> float:
	return clampf(float(w.boss.x)+direction*DASH_SPEED*seconds,DASH_MIN_X,w.length()-170.)

static func lane_direction(w) -> float:
	var locked: float=w.boss.get("lane_direction",0.)
	if locked!=0.:return locked
	return -1. if w.player.x<=float(w.boss.x) else 1.

static func arm_warning(w) -> void:
	w.boss.windup=.95
	w.boss.lane_direction=0.
	var pattern: int=int(w.boss.attack)%3
	if pattern==1 or (pattern==2 and int(w.boss.phase)==3):
		w.boss.lane_direction=lane_direction(w)
	if pattern==2 and int(w.boss.phase)==3:w.pending_events.append("boss_charge_warning")

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
	if float(w.boss.echo_wait)==0.:emit_wave(w,float(w.boss.get("echo_direction",-1.)))

static func emit_wave(w,direction: float) -> void:
	var x:=float(w.boss.x)+direction*WAVE_OFFSET
	w.pending_events.append("boss_wave")
	w.bullets.append({"p":Vector2(x,w.floor_at(x)-16.),"v":Vector2(direction*WAVE_SPEED,0.),"owner":"enemy","age":0.,"kind":"wave","damage":1,"pierce":0,"hit":[],"life":WAVE_LIFE,"boss_shot":true})

static func core_damage(w,bullet: Dictionary,from: Vector2,to: Vector2) -> int:
	var damage: int=int(bullet.damage)
	if core_exposed(w):
		var core:=core_point(w)
		if Geometry2D.get_closest_point_to_segment(core,from,impact_path_end(w,from,to)).distance_squared_to(core)<900.:
			return damage*(3 if int(w.boss.phase)==3 else 2)
	return damage

static func attack(w) -> bool:
	if int(w.boss.phase)!=3 or int(w.boss.attack)%3!=2:return false
	# World may have scheduled a beam on this odd-numbered pattern. A dash
	# owns its telegraph and active window; do not freeze a second warning
	# throughout the charge and then release it during the punish interval.
	w.boss.beam_warning=0.
	w.boss.dash=DASH_TIME
	w.boss.dash_direction=lane_direction(w)
	return true
