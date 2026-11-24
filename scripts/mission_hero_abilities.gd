class_name MissionHeroAbilities
extends RefCounted

## Ephemeral skill choreography. World remains the sole movement/physics owner.
## Roll and tongue share the normal movement, collision and damage systems.
const ROLL_WINDUP := .16
const ROLL_ACTIVE := .78
const ROLL_SPEED := 660.
const ROLL_DAMAGE := 5
const ROLL_BRAKE := .14
const ROLL_RECOVER := .32
const ROLL_CHARGES := 3
const ROLL_COOLDOWN := 3.
const SPRINT_FIRE_TIME := 3.
const SPRINT_RECOVERY_TIME := 3.
const SHELL_CONTACT_LIFE := .18
const SHELL_CONTACT_SPACING := 22.
const TONGUE_REACH := 240.
const TONGUE_SPEED := 1000.
const TONGUE_COOLDOWN := .2
const LEGACY_SWALLOW_COOLDOWN := 10.
const SWALLOW_COOLDOWN := 5.
const SPIT_RADIUS := 115.
const SPIT_SPEED := 710.
const SWALLOWABLE := ["gnome","beetle","crow","slime"]

static func active(w) -> bool:
	return not w.hero_skill.is_empty() and str(w.hero_skill.get("phase",""))!="cooldown"

static func rolling(w) -> bool:
	return w.character=="armadillo" and str(w.hero_skill.get("phase",""))=="roll"

static func compact(w) -> bool:
	return w.character=="armadillo" and active(w)

static func roll_ready(w) -> bool:
	if w.roll_charges<=0 or not w.grounded():return false
	return w.hero_skill.is_empty() or w.hero_skill.phase in ["roll","brake"]

static func context(w) -> Dictionary:
	var supported: bool=w.character in ["armadillo","frog"]
	var available: bool=supported and w.state=="playing" and not bool(w.mount.ridden) and w.mount_transition==""
	var phase: String=str(w.hero_skill.get("phase","ready"))
	var loaded: bool=w.character=="frog" and not w.frog_meal.is_empty()
	var ready: bool=available and w.hurt_time<=0. and w.rescue_time<=0. and (roll_ready(w) if w.character=="armadillo" else w.hero_skill.is_empty())
	var cooldown:=0.
	var remaining:=0.
	if not w.hero_skill.is_empty():
		var clock: float=float(w.hero_skill.clock)
		var durations: Dictionary={"windup":ROLL_WINDUP,"roll":ROLL_ACTIVE,"brake":ROLL_BRAKE,"recover":ROLL_RECOVER} if w.character=="armadillo" else {"windup":.12,"extend":TONGUE_REACH/TONGUE_SPEED,"retract":TONGUE_REACH/1300.,"recover":.30,"cooldown":TONGUE_COOLDOWN}
		var total:=0.;var include:=false
		for name in durations:
			total+=float(durations[name])
			if name==phase:include=true;remaining+=maxf(0.,float(durations[name])-clock)
			elif include:remaining+=float(durations[name])
		if w.character=="frog" and phase=="retract":remaining=float(w.hero_skill.extent)/1300.+.30+TONGUE_COOLDOWN
		cooldown=clampf(remaining/maxf(.001,total),0.,1.)
	if w.character=="armadillo" and w.roll_cooldown>0.:
		phase="cooldown"
		remaining=w.roll_cooldown
		cooldown=remaining/ROLL_COOLDOWN
	if w.character=="frog" and not loaded and w.frog_cooldown>0.:
		ready=false
		if w.hero_skill.is_empty():phase="cooldown"
		remaining=maxf(remaining,w.frog_cooldown)
		cooldown=remaining/SWALLOW_COOLDOWN
	var status: String="skill_ready" if ready else "skill_active"
	if w.character=="armadillo" and w.hero_skill.is_empty() and not w.grounded():status="skill_land"
	if phase in ["recover","cooldown"]:status="skill_"+phase
	return {"visible":available,"ready":ready,"label_key":"skill_roll" if w.character=="armadillo" else ("skill_spit" if loaded else "skill_tongue"),"phase":phase,"status_key":status,"phase_key":status,"cooldown":0. if ready else cooldown,"remaining":remaining}

static func body_facing(w) -> int:
	if active(w):return int(w.hero_skill.face)
	return M1CombatArt.body_facing(w)

static func press(w) -> bool:
	if w.character not in ["armadillo","frog"] or w.state!="playing":return false
	if bool(w.mount.ridden) or w.mount_transition!="" or w.rescue_time>0. or w.hurt_time>0.:return false
	var shell_chain: bool=rolling(w) or (w.character=="armadillo" and w.hero_skill.get("phase","")=="brake")
	if w.character=="armadillo":
		if not roll_ready(w):return false
	elif not w.hero_skill.is_empty():return false
	var direction: Vector2=w.aim_direction.normalized() if w.aim_direction.length_squared()>.01 else Vector2(w.facing,0.)
	var face: int=(-1 if direction.x<0. else 1) if absf(direction.x)>.1 else int(w.facing)
	if w.character=="armadillo" and absf(w.move_axis.x)>.25:
		face=1 if w.move_axis.x>0. else -1
	if w.character=="frog" and not w.frog_meal.is_empty():
		w.hero_skill={"kind":"frog","phase":"spit","clock":0.,"direction":direction,"face":face}
		w.bullets.append({"id":w.frog_meal.id,"p":mouth(w),"v":direction*SPIT_SPEED,
			"kind":"frog_spit","creature":w.frog_meal.kind,"owner":"hero","age":0.,"life":.85})
		w.frog_meal.clear()
		w.pending_events.append("hero_tongue")
		return true
	if w.character=="frog" and w.frog_cooldown>0.:return false
	w.hero_skill={"kind":w.character,"phase":"roll" if shell_chain else "windup","clock":0.,"direction":direction,"face":face,"previous_p":Vector2(w.player),"hits":[],"extent":0.,"previous_tip":Vector2(w.player),"contact":false}
	# A roll consumes current gun input. No deferred fire, grenade or jump event.
	if w.character=="armadillo":
		w.roll_charges-=1
		w.fire_held=false;w.jump_buffer_timer=0.;w.jump_held=false
	w.pending_events.append("hero_roll" if shell_chain else "hero_windup")
	return true

static func cancel(w) -> void:
	w.hero_skill.clear()
	if w.roll_charges==0 and w.roll_cooldown<=0.:w.roll_cooldown=ROLL_COOLDOWN
	if w.sprint_fire>0.:
		w.sprint_fire=0.
		w.sprint_recovery=SPRINT_RECOVERY_TIME

static func reset(w) -> void:
	cancel(w)
	w.frog_meal.clear()
	w.frog_cooldown=0.
	w.roll_charges=ROLL_CHARGES
	w.roll_cooldown=0.
	w.sprint_fire=0.
	w.sprint_recovery=0.
	w.sprint_ignition=true

static func sprinting(w) -> bool:
	return w.character in ["rabbit","eren"] and w.boost_held and not bool(w.mount.ridden) \
		and w.grounded() and not w.crouching() and not w.charging and absf(w.velocity.x)>1.

static func sprint_contacts(w,previous: Vector2,was_grounded: bool,dt: float) -> void:
	if w.character not in ["rabbit","eren"] or dt<=0.:return
	var running:=sprinting(w)
	w.sprint_recovery=maxf(0.,w.sprint_recovery-dt)
	if not w.boost_held:w.sprint_ignition=true
	if w.sprint_fire>0.:
		w.sprint_fire=maxf(0.,w.sprint_fire-dt) if running else 0.
		if w.sprint_fire<=0.:w.sprint_recovery=SPRINT_RECOVERY_TIME
	elif running and w.sprint_ignition and w.sprint_recovery<=0.:
		w.sprint_fire=SPRINT_FIRE_TIME
		w.sprint_ignition=false
	if running:
		var center: Vector2=w.player_hit_center()
		var from: Vector2=previous+Vector2(0.,-37.) if was_grounded else center
		sprint_hit(w,from,center)

static func sprint_hit(w,from: Vector2,to: Vector2) -> void:
	for e in w.enemies:
		if sprint_enemy(w,e,from,to) and w.state!="playing":return

static func sprint_enemy(w,e: Dictionary,from: Vector2,to: Vector2) -> bool:
	if bool(e.defeated) or CampaignEnemies.hidden(e):return false
	var center:=Vector2(float(e.x),float(e.y)-30.)
	var reach: float=54. if w.sprint_fire>0. else 48.
	if circle_t(from,to,center,reach)==INF:return false
	if w.sprint_fire>0.:
		w.damage_enemy(e,int(e.hp),"flame_dash")
	else:
		w.damage_player()
	return true

static func swallowable(enemy: Dictionary) -> bool:
	return str(enemy.kind) in SWALLOWABLE and not bool(enemy.get("mini",false)) \
		and not bool(enemy.get("heavy",false)) and int(enemy.get("armour",0))==0 \
		and int(enemy.get("max_hp",1))<=2

static func spit_step(w,b: Dictionary,dt: float) -> void:
	var from: Vector2=b.p
	var next: Vector2=from+Vector2(b.v)*dt
	var hit:=first_contact(w,from,next)
	b.age=float(b.age)+dt
	b.p=next if hit.is_empty() else hit.point
	if hit.is_empty() and float(b.age)<float(b.life):return
	var point: Vector2=b.p
	b.age=99.
	# The direct hit is included; walls shield the other side of the blast.
	for enemy in w.enemies:
		if bool(enemy.defeated) or CampaignEnemies.hidden(enemy):continue
		var center:=Vector2(float(enemy.x),float(enemy.y)-30.)
		if center.distance_to(point)>=SPIT_RADIUS:continue
		if not hit.is_empty() and hit.get("target",{})==enemy:
			w.damage_enemy(enemy,4,"spit")
		elif first_contact(w,point.lerp(from,.15),center,false).is_empty():
			w.damage_enemy(enemy,3,"spit")
	if not hit.is_empty() and hit.kind=="crate":w.open_crate(hit.target)
	if not hit.is_empty() and hit.kind=="object":CampaignContent.hit_object(w,point,3)
	if not hit.is_empty() and hit.kind=="boss":w.damage_boss(4)
	w.blasts.append({"p":point,"age":0.,"radius":SPIT_RADIUS,"color":"a7dc75"})
	w.pending_events.append("hero_contact")


## base is the world's already computed signed horizontal velocity.
static func movement_speed(w,base: float) -> float:
	if not compact(w):return base
	var phase: String=str(w.hero_skill.phase)
	if phase=="roll":return float(w.hero_skill.face)*ROLL_SPEED
	if phase=="brake":return float(w.hero_skill.face)*ROLL_SPEED*maxf(0.,1.-float(w.hero_skill.clock)/ROLL_BRAKE)
	return base*.18

static func trace_shell_contact(w,started_grounded: bool,travel: float) -> void:
	while not w.shell_contacts.is_empty() and w.time-float(w.shell_contacts[0].born)>=SHELL_CONTACT_LIFE:
		w.shell_contacts.pop_front()
	if not rolling(w) or not started_grounded or not w.grounded() or absf(travel)<1.:
		return
	if not w.shell_contacts.is_empty():
		var last: Vector2=w.shell_contacts.back().point
		if absf(w.player.x-last.x)<SHELL_CONTACT_SPACING:
			return
	w.shell_contacts.append({"point":w.player,"born":w.time,"direction":signf(travel)})

static func mouth(w) -> Vector2:
	var local:=Vector2(22.,-43. if not w.crouching() else -23.)
	var face: int=body_facing(w)
	# The same authored face socket drives both drawing and collision.
	if MissionHeroArt.has(str(w.character)):
		var pose: Dictionary=MissionHeroArt.body_spec(w)
		local=MissionHeroArt.metrics(str(w.character),str(pose.action),int(pose.frame)).face_local
		face=int(pose.mirror)
	return Vector2(w.player)+local*Vector2(face,1.)

static func tongue_tip(w) -> Vector2:
	if w.hero_skill.is_empty():return mouth(w)
	return mouth(w)+Vector2(w.hero_skill.direction)*float(w.hero_skill.extent)

static func set_phase(w,phase: String) -> void:
	w.hero_skill.phase=phase;w.hero_skill.clock=0.

static func step(w,dt: float) -> void:
	if dt<=0. or w.state!="playing":return
	w.frog_cooldown=maxf(0.,float(w.frog_cooldown)-dt)
	if w.roll_cooldown>0.:
		w.roll_cooldown=maxf(0.,w.roll_cooldown-dt)
		if w.roll_cooldown<=0.:w.roll_charges=ROLL_CHARGES
	if w.hero_skill.is_empty():return
	if bool(w.mount.ridden) or w.mount_transition!="" or w.hurt_time>0.:
		cancel(w);return
	var s: Dictionary=w.hero_skill
	s.clock=float(s.clock)+dt
	var phase: String=str(s.phase)
	if phase=="cooldown":
		if float(s.clock)>=TONGUE_COOLDOWN:cancel(w)
		return
	if w.character=="armadillo":
		if phase=="windup" and float(s.clock)>=ROLL_WINDUP:set_phase(w,"roll");w.pending_events.append("hero_roll")
		elif phase=="roll":
			roll_hits(w,Vector2(s.previous_p),Vector2(w.player))
			if w.hero_skill.is_empty():return
			var stopped: bool=Vector2(w.player).distance_to(Vector2(s.previous_p))<1. and float(s.clock)>.055
			if float(s.clock)>=ROLL_ACTIVE or stopped or not w.grounded():set_phase(w,"brake")
		elif phase=="brake" and float(s.clock)>=ROLL_BRAKE:set_phase(w,"recover")
		elif phase=="recover" and float(s.clock)>=ROLL_RECOVER:cancel(w);return
		s.previous_p=Vector2(w.player)
		return
	if phase=="spit":
		if float(s.clock)>=.25:cancel(w)
	elif phase=="windup":
		if float(s.clock)>=.12:set_phase(w,"extend");w.pending_events.append("hero_tongue")
	elif phase in ["extend","retract"]:
		var origin: Vector2=mouth(w)
		var extent: float=minf(TONGUE_REACH,float(s.extent)+TONGUE_SPEED*dt) if phase=="extend" else maxf(0.,float(s.extent)-1300.*dt)
		var end: Vector2=origin+Vector2(s.direction)*extent
		var contact: Dictionary=first_contact(w,origin,end) if phase=="extend" else {}
		if not contact.is_empty():
			extent=origin.distance_to(Vector2(contact.point));s.contact=true
			if phase=="extend":
				if contact.kind=="enemy" and swallowable(contact.target):
					var enemy: Dictionary=contact.target
					s.caught={"id":enemy.id,"kind":enemy.kind}
					w.frog_meal=s.caught.duplicate()
					w.frog_cooldown=SWALLOW_COOLDOWN
					enemy.swallowed=true
					w.damage_enemy(enemy,int(enemy.hp),"swallow")
				else:apply_contact(w,contact,2)
				if w.hero_skill.is_empty():return
				set_phase(w,"retract");w.pending_events.append("hero_contact")
		s.extent=extent;s.previous_tip=origin+Vector2(s.direction)*extent
		if phase=="extend" and extent>=TONGUE_REACH:set_phase(w,"retract")
		elif phase=="retract" and extent<=.01:
			set_phase(w,"recover")
	elif phase=="recover" and float(s.clock)>=(.17 if not w.frog_meal.is_empty() else .30):
		if w.frog_meal.is_empty():set_phase(w,"cooldown")
		else:cancel(w)

static func roll_hits(w,from: Vector2,to: Vector2) -> void:
	var a:=from+Vector2(0.,-22.);var b:=to+Vector2(0.,-22.)
	for enemy in w.enemies:
		var id: String=str(enemy.id)
		if bool(enemy.defeated) or CampaignEnemies.hidden(enemy) or id in w.hero_skill.hits:continue
		var center:=Vector2(float(enemy.x),float(enemy.y)-30.)
		if Geometry2D.get_closest_point_to_segment(center,a,b).distance_to(center)<58.:
			w.hero_skill.hits.append(id);w.damage_enemy(enemy,ROLL_DAMAGE,"roll")
	if bool(w.boss.active) and bool(w.boss.get("engaged",false)) and not "boss" in w.hero_skill.hits:
		var target:=Vector2(float(w.boss.x),float(w.boss.y)-60.)
		if Geometry2D.get_closest_point_to_segment(target,a,b).distance_to(target)<113.:
			w.hero_skill.hits.append("boss")
			w.damage_boss(ROLL_DAMAGE)
			if w.state!="playing":cancel(w);return
			if w.hero_skill.is_empty():return
			set_phase(w,"brake")
	for object in w.objects:
		if bool(object.active) or str(object.kind) in ["current","updraft"] or str(object.id) in w.hero_skill.get("hits",[]):continue
		var center:=Vector2(float(object.x),float(object.y)-35.)
		if Geometry2D.get_closest_point_to_segment(center,a,b).distance_to(center)<48.:
			w.hero_skill.hits.append(str(object.id));CampaignContent.hit_object(w,center,3,center)
	for crate in w.crates:
		if int(crate.hp)>0 and Geometry2D.get_closest_point_to_segment(Vector2(float(crate.x),float(crate.y)-24.),a,b).distance_to(Vector2(float(crate.x),float(crate.y)-24.))<48.:w.open_crate(crate)

## Parametric segment tests provide the FIRST impact even on a long frame.
static func circle_t(a: Vector2,b: Vector2,c: Vector2,r: float) -> float:
	var d:=b-a;var offset:=a-c
	if offset.length_squared()<=r*r:return 0.
	var aa:=d.length_squared()
	if aa<.00001:return INF
	var bb:=2.*offset.dot(d);var cc:=offset.length_squared()-r*r
	var disc:=bb*bb-4.*aa*cc
	if disc<0.:return INF
	var t:=(-bb-sqrt(disc))/(2.*aa)
	return t if t>=0. and t<=1. else INF

static func rect_t(a: Vector2,b: Vector2,r: Rect2) -> float:
	var lo:=0.;var hi:=1.;var delta:=b-a
	for axis in 2:
		if absf(delta[axis])<.00001:
			if a[axis]<r.position[axis] or a[axis]>r.end[axis]:return INF
		else:
			var t1: float=(r.position[axis]-a[axis])/delta[axis];var t2: float=(r.end[axis]-a[axis])/delta[axis]
			lo=maxf(lo,minf(t1,t2));hi=minf(hi,maxf(t1,t2))
			if lo>hi:return INF
	return lo

static func first_contact(w,a: Vector2,b: Vector2,targets: bool=true) -> Dictionary:
	var best:=INF;var found: Dictionary={}
	var solids: Array[Rect2]=[]
	if w.section=="fork_one":solids.append(CampaignRoutes.PIER)
	if w.section=="fork_two" and not CampaignRoutes.hatch_open(w):solids.append(Rect2(CampaignRoutes.HATCH_X,-5.,500.,10.))
	for platform in w.platforms:
		if not w.disabled_platforms.has(platform.position.x):solids.append(platform)
	for gate in w.gates:
		if w.gate_closed(gate):solids.append(Rect2(float(gate.x)-3.,w.floor_at(float(gate.x))-240.,6.,240.))
	# Ground collision is sampled at at most 3px spacing: route floor API remains
	# authoritative, including open/closed hatch and platform support.
	var samples:=maxi(1,int(ceil(a.distance_to(b)/3.)))
	for i in range(1,samples+1):
		var t:=float(i)/float(samples);var p:=a.lerp(b,t)
		if p.y>=w.floor_at(p.x,p.y):best=t;found={"kind":"wall"};break
	for rect in solids:
		var t:=rect_t(a,b,rect)
		if t<best:best=t;found={"kind":"wall"}
	for object in w.objects:
		if bool(object.active) or str(object.kind) in ["current","updraft"]:continue
		var t:=circle_t(a,b,Vector2(float(object.x),float(object.y)-35.),45.)
		if t<best:best=t;found={"kind":"object","target":object}
	if targets:
		for enemy in w.enemies:
			if bool(enemy.defeated) or CampaignEnemies.hidden(enemy):continue
			var radius:=58. if bool(enemy.get("mini",false)) or bool(enemy.get("heavy",false)) else 34.
			var t:=circle_t(a,b,Vector2(float(enemy.x),float(enemy.y)-30.),radius)
			if t<best:best=t;found={"kind":"enemy","target":enemy}
		if bool(w.boss.active) and bool(w.boss.get("engaged",false)):
			var t:=circle_t(a,b,Vector2(float(w.boss.x),float(w.boss.y)-75.),105.)
			if t<best:best=t;found={"kind":"boss"}
		for crate in w.crates:
			if int(crate.hp)<=0:continue
			var t:=circle_t(a,b,Vector2(float(crate.x),float(crate.y)-24.),30.)
			if t<best:best=t;found={"kind":"crate","target":crate}
	if not found.is_empty():found.point=a.lerp(b,best)
	return found

static func apply_contact(w,contact: Dictionary,damage: int) -> void:
	match str(contact.kind):
		"enemy":
			var id: String=str(contact.target.id)
			if not id in w.hero_skill.hits:w.hero_skill.hits.append(id);w.damage_enemy(contact.target,damage,"tongue")
		"boss":
			if not "boss" in w.hero_skill.hits:
				w.hero_skill.hits.append("boss")
				w.damage_boss(damage)
				if w.state!="playing":cancel(w)
		"crate":w.open_crate(contact.target)
		"object":CampaignContent.hit_object(w,Vector2(float(contact.target.x),float(contact.target.y)-35.),damage)
