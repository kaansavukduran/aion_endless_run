class_name MissionHeroAbilities
extends RefCounted

## Ephemeral skill choreography. World remains the sole movement/physics owner.
## Candidate balance: roll 520px/s for .38s, 3 damage, no immunity; tongue
## 240px reach, 2 damage, first target only. Recovery starts AFTER active play.
const ROLL_WINDUP := .16
const ROLL_ACTIVE := .38
const ROLL_BRAKE := .14
const ROLL_RECOVER := .32
const SHELL_CONTACT_LIFE := .18
const SHELL_CONTACT_SPACING := 22.
const TONGUE_REACH := 240.
const TONGUE_SPEED := 1000.

static func active(w) -> bool:
	return not w.hero_skill.is_empty() and str(w.hero_skill.get("phase",""))!="cooldown"

static func rolling(w) -> bool:
	return w.character=="armadillo" and str(w.hero_skill.get("phase",""))=="roll"

static func compact(w) -> bool:
	return w.character=="armadillo" and active(w)

static func context(w) -> Dictionary:
	var supported: bool=w.character in ["armadillo","frog"]
	var available: bool=supported and w.state=="playing" and not bool(w.mount.ridden) and w.mount_transition==""
	var phase: String=str(w.hero_skill.get("phase","ready"))
	var ready: bool=available and w.hero_skill.is_empty() and w.hurt_time<=0. and w.rescue_time<=0. and (w.character!="armadillo" or w.crouching())
	var cooldown:=0.
	var remaining:=0.
	if not w.hero_skill.is_empty():
		var clock: float=float(w.hero_skill.clock)
		var durations: Dictionary={"windup":ROLL_WINDUP,"roll":ROLL_ACTIVE,"brake":ROLL_BRAKE,"recover":ROLL_RECOVER,"cooldown":.40} if w.character=="armadillo" else {"windup":.12,"extend":TONGUE_REACH/TONGUE_SPEED,"retract":TONGUE_REACH/1300.,"recover":.30,"cooldown":.40}
		var total:=0.;var include:=false
		for name in durations:
			total+=float(durations[name])
			if name==phase:include=true;remaining+=maxf(0.,float(durations[name])-clock)
			elif include:remaining+=float(durations[name])
		if w.character=="frog" and phase=="retract":remaining=float(w.hero_skill.extent)/1300.+.30+.40
		cooldown=clampf(remaining/maxf(.001,total),0.,1.)
	var status: String="skill_ready" if ready else ("skill_crouch" if w.hero_skill.is_empty() and w.character=="armadillo" else "skill_active")
	if phase in ["recover","cooldown"]:status="skill_"+phase
	return {"visible":available,"ready":ready,"label_key":"skill_roll" if w.character=="armadillo" else "skill_tongue","phase":phase,"status_key":status,"phase_key":status,"cooldown":cooldown,"remaining":remaining}

static func body_facing(w) -> int:
	if active(w):return int(w.hero_skill.face)
	return M1CombatArt.body_facing(w)

static func press(w) -> bool:
	if w.character not in ["armadillo","frog"] or w.state!="playing" or not w.hero_skill.is_empty():return false
	if bool(w.mount.ridden) or w.mount_transition!="" or w.rescue_time>0. or w.hurt_time>0.:return false
	if w.character=="armadillo" and (not w.grounded() or not w.crouching()):return false
	var direction: Vector2=w.aim_direction.normalized() if w.aim_direction.length_squared()>.01 else Vector2(w.facing,0.)
	var face: int=(-1 if direction.x<0. else 1) if absf(direction.x)>.1 else int(w.facing)
	w.hero_skill={"kind":w.character,"phase":"windup","clock":0.,"direction":direction,"face":face,"previous_p":Vector2(w.player),"hits":[],"extent":0.,"previous_tip":Vector2(w.player),"contact":false}
	# A roll consumes current gun input. No deferred fire, grenade or jump event.
	if w.character=="armadillo":w.fire_held=false;w.jump_buffer_timer=0.;w.jump_held=false
	w.pending_events.append("hero_windup")
	return true

static func cancel(w) -> void:
	w.hero_skill.clear()

## base is the world's already computed signed horizontal velocity.
static func movement_speed(w,base: float) -> float:
	if not compact(w):return base
	var phase: String=str(w.hero_skill.phase)
	if phase=="roll":return float(w.hero_skill.face)*520.
	if phase=="brake":return float(w.hero_skill.face)*520.*maxf(0.,1.-float(w.hero_skill.clock)/ROLL_BRAKE)
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
	if w.hero_skill.is_empty() or dt<=0.:return
	# Pause freezes choreography; transitions/death cancel it at their owner.
	if w.state!="playing":return
	if bool(w.mount.ridden) or w.mount_transition!="" or w.hurt_time>0.:
		cancel(w);return
	var s: Dictionary=w.hero_skill
	s.clock=float(s.clock)+dt
	var phase: String=str(s.phase)
	if phase=="cooldown":
		if float(s.clock)>=.40:cancel(w)
		return
	if w.character=="armadillo":
		if phase=="windup" and float(s.clock)>=ROLL_WINDUP:set_phase(w,"roll");w.pending_events.append("hero_roll")
		elif phase=="roll":
			roll_hits(w,Vector2(s.previous_p),Vector2(w.player))
			if w.hero_skill.is_empty():return
			var stopped: bool=Vector2(w.player).distance_to(Vector2(s.previous_p))<1. and float(s.clock)>.055
			if float(s.clock)>=ROLL_ACTIVE or stopped or not w.grounded():set_phase(w,"brake")
		elif phase=="brake" and float(s.clock)>=ROLL_BRAKE:set_phase(w,"recover")
		elif phase=="recover" and float(s.clock)>=ROLL_RECOVER:set_phase(w,"cooldown")
		s.previous_p=Vector2(w.player)
		return
	if phase=="windup":
		if float(s.clock)>=.12:set_phase(w,"extend");w.pending_events.append("hero_tongue")
	elif phase in ["extend","retract"]:
		var origin: Vector2=mouth(w)
		var extent: float=minf(TONGUE_REACH,float(s.extent)+TONGUE_SPEED*dt) if phase=="extend" else maxf(0.,float(s.extent)-1300.*dt)
		var end: Vector2=origin+Vector2(s.direction)*extent
		var contact: Dictionary=first_contact(w,origin,end,phase=="extend")
		if not contact.is_empty():
			extent=origin.distance_to(Vector2(contact.point));s.contact=true
			if phase=="extend":
				apply_contact(w,contact,2)
				if w.hero_skill.is_empty():return
				set_phase(w,"retract");w.pending_events.append("hero_contact")
		s.extent=extent;s.previous_tip=origin+Vector2(s.direction)*extent
		if phase=="extend" and extent>=TONGUE_REACH:set_phase(w,"retract")
		elif phase=="retract" and extent<=.01:set_phase(w,"recover")
	elif phase=="recover" and float(s.clock)>=.30:set_phase(w,"cooldown")

static func roll_hits(w,from: Vector2,to: Vector2) -> void:
	var a:=from+Vector2(0.,-22.);var b:=to+Vector2(0.,-22.)
	for enemy in w.enemies:
		var id: String=str(enemy.id)
		if bool(enemy.defeated) or CampaignEnemies.hidden(enemy) or id in w.hero_skill.hits:continue
		var center:=Vector2(float(enemy.x),float(enemy.y)-30.)
		if Geometry2D.get_closest_point_to_segment(center,a,b).distance_to(center)<50.:
			w.hero_skill.hits.append(id);w.damage_enemy(enemy,3,"roll")
	if bool(w.boss.active) and bool(w.boss.get("engaged",false)) and not "boss" in w.hero_skill.hits:
		var target:=Vector2(float(w.boss.x),float(w.boss.y)-60.)
		if Geometry2D.get_closest_point_to_segment(target,a,b).distance_to(target)<113.:
			w.hero_skill.hits.append("boss")
			if w.boss_vulnerable():w.damage_boss(3)
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
				if w.boss_vulnerable():w.damage_boss(damage)
				if w.state!="playing":cancel(w)
		"crate":w.open_crate(contact.target)
		"object":CampaignContent.hit_object(w,Vector2(float(contact.target.x),float(contact.target.y)-35.),damage)
