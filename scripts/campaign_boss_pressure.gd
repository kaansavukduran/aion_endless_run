class_name CampaignBossPressure
extends RefCounted

const ACTIVE_DRONE_LIMIT := 2
const DASH_SPEED := 450.
const DASH_TIME := .95
const DASH_RADIUS := 95.
const ECHO_DELAY := .64
const WAVE_SPEED := 320.
const WAVE_OFFSET := 60.
const WAVE_LIFE := 3.

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

static func damage_allowed(w,amount: int) -> int:
	var boss: Dictionary=w.boss
	if not w.boss_vulnerable() or float(boss.get("shift_pause",0.))>0.:return 0
	# A single bomb or fast burst may reach the next phase. The remaining
	# force of that same hit cannot bypass its new attack and recovery rhythm.
	var threshold:=59 if int(boss.phase)==1 else (29 if int(boss.phase)==2 else 0)
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
	w.boss.wait=maxf(float(w.boss.wait),0.95)
	for bullet in w.bullets:
		if bool(bullet.get("boss_shot",false)):bullet.age=99.
	w.pending_events.append("mechanism")
	w.blasts.append({"p":Vector2(float(w.boss.x),float(w.boss.y)-85.),"age":0.,"radius":95.,"color":"ffcf8c"})

static func hit(w,bullet: Dictionary,from: Vector2,to: Vector2) -> bool:
	var boss: Dictionary=w.boss
	if float(boss.get("shift_pause",0.))>0.:return false
	if int(boss.phase)==1:
		if not boss.has("ports"):boss.ports=[3,3]
		for i in 2:
			if int(boss.ports[i])<=0:continue
			var target:=port_point(w,i)
			if Geometry2D.get_closest_point_to_segment(target,from,to).distance_to(target)>25.:continue
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
		# Clear punish window after the final-phase charge so basic pistol finishes cleanly.
		w.boss.recover=maxf(0.,0.65-(dt-active_dt))
		w.boss.wait=maxf(float(w.boss.wait),1.15)
	return true

static func dash_destination(w,direction: float,seconds: float=DASH_TIME) -> float:
	return clampf(float(w.boss.x)+direction*DASH_SPEED*seconds,1800.,w.length()-170.)

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
	if int(w.boss.phase)==2 and w.boss_vulnerable():
		var core:=Vector2(float(w.boss.x),float(w.boss.y)-75.)
		if Geometry2D.get_closest_point_to_segment(core,from,to).distance_to(core)<30.:return damage*2
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
