class_name CampaignVehicles
extends RefCounted

const MAX_HP := 1
const IMPACT_SECONDS := .10
const TYPES := ["skimmer","shell","wind","drill"]
static func kind(w) -> String:return str(w.mount.get("type","skimmer"))
## Find the first real supporting surface below a foot, including raised
## one-way decks and a positive-height lower channel. A pit returns1000.
static func support_below(w,x: float,foot: float) -> float:
	return float(w.crossing_floor(x,foot-1.,1000.,1.))

static func can_board(w) -> bool:
	var floor: float=float(w.mount.get("floor_y",w.floor_at(float(w.mount.x))))
	return bool(w.mount.available) and int(w.mount.hp)>0 and absf(w.player.x-float(w.mount.x))<150. and absf(w.player.y-floor)<90. and floor<180.

static func park(w) -> float:
	var visual_foot: float=w.player.y+42.
	var contact_foot: float=visual_foot-(24. if float(w.mount.get("dive",0.))>0. else 0.)
	var support: float=support_below(w,w.player.x,contact_foot)
	w.mount.x=w.player.x;w.mount.floor_y=visual_foot;w.mount.park_target=support
	w.mount.park_velocity=maxf(0.,w.velocity.y)
	return contact_foot

static func step_parked(w,dt: float) -> void:
	if bool(w.mount.get("ridden",false)) or not w.mount.has("park_target"):return
	var floor: float=float(w.mount.floor_y);var target: float=float(w.mount.park_target)
	if floor>=target:
		w.mount.floor_y=target;w.mount.park_velocity=0.;return
	w.mount.park_velocity=float(w.mount.get("park_velocity",0.))+1700.*dt
	w.mount.floor_y=minf(target,floor+float(w.mount.park_velocity)*dt)
	if float(w.mount.floor_y)>180. and target>=180.:w.mount.available=false

static func stunned(w) -> bool:
	return bool(w.mount.get("ridden",false)) and float(w.mount.get("break_time",0.))>0.

static func damage(w) -> void:
	if int(w.mount.hp)<=0:return
	w.mount.hp=0
	w.mount.hurt=IMPACT_SECONDS
	w.mount.break_time=IMPACT_SECONDS
	w.mount.available=false
	w.velocity=Vector2.ZERO
	w.stop_inputs()
	w.pending_events.append("vehicle_impact")

static func step_damage(w,dt: float) -> void:
	if not stunned(w):return
	w.mount.break_time=maxf(0.,float(w.mount.break_time)-dt)
	w.mount.hurt=w.mount.break_time
	if float(w.mount.break_time)>.00001:return
	w.mount.break_time=0.
	var point: Vector2=w.player-Vector2(0.,24.)
	eject(w)
	w.invulnerable=maxf(w.invulnerable,.85)
	w.blasts.append({"p":point,"age":0.,"radius":110.,"color":"eab274"})
	w.pending_events.append("vehicle_wreck")

static func eject(w) -> void:
	CampaignGrenade.cancel(w)
	var foot: float=park(w)
	w.mount.ridden=false;w.mount.available=false;w.mount.wreck_age=0.
	w.mount_transition="";w.mount_transition_time=0.;w.drop_through_time=0.;w.stop_inputs()
	var target:=Vector2(w.player.x,support_below(w,w.player.x,foot))
	if target.y>=180. or not CampaignLives.landing_clear(w,target):
		var area:=Rect2(w.player.x-220.,minf(w.player.y-200.,-380.),440.,600.)
		target=CampaignLives.landing(w,area)
	w.eject_target_x=target.x if absf(target.x-w.player.x)>1. else -1.
	# Keep the pilot at the visible saddle. If the hull has already fallen
	# past a ledge, give the throw enough lift to clear that real surface.
	var rise:=maxf(0.,w.player.y-target.y+32.)
	w.velocity=Vector2(0.,-maxf(260.,sqrt(3400.*rise)))



## Board/exit have deliberate short root motion, independent of sprite-frame
## registration. While the hatch is moving the world is paused and safe.
static func interact(w) -> bool:
	if stunned(w):return false
	if bool(w.mount.ridden):
		var target:=Vector2.ZERO
		var found:=false
		var contact_foot: float=w.player.y+42.-(24. if float(w.mount.get("dive",0.))>0. else 0.)
		for offset in [-100.,100.,-180.,180.,-260.,260.]:
			var x: float=clampf(w.player.x+offset,35.,w.length()-90.)
			var support: float=support_below(w,x,contact_foot)
			if support<180.:target=Vector2(x,support);found=true;break
		if not found:return false
		park(w)
		w.mount_transition="exit";w.mount.ridden=false
		w.mount_transition_to=target
	elif can_board(w):
		w.mount_transition="enter";w.mount.ridden=true
		w.mount_transition_to=Vector2(float(w.mount.x),float(w.mount.get("floor_y",w.floor_at(float(w.mount.x))))-42.)
	else:return false
	w.mount.facing=w.facing;w.drop_through_time=0.
	w.mount_transition_from=w.player;w.mount_transition_time=0.
	w.velocity=Vector2.ZERO;w.stop_inputs()
	return true

static func step_transition(w,dt: float) -> void:
	if w.mount_transition=="exit":step_parked(w,dt)
	w.mount_transition_time=minf(w.mount_transition_duration,w.mount_transition_time+dt)
	var phase: float=clampf(w.mount_transition_time/w.mount_transition_duration,0.,1.)
	var eased: float=phase*phase*(3.-2.*phase)
	w.player=w.mount_transition_from.lerp(w.mount_transition_to,eased)+Vector2(0.,-sin(phase*PI)*24.)
	w.velocity=Vector2.ZERO
	if phase>=1.:
		if w.mount_transition=="enter":
			var type: String=kind(w)
			if not w.vehicles_used.has(type):w.vehicles_used.append(type)
		w.mount_transition="";w.mount_transition_time=0.
		w.player=w.mount_transition_to;w.invulnerable=maxf(w.invulnerable,.3)

static func jump(w) -> bool:
	if not bool(w.mount.ridden):return false
	if w.grounded():
		w.mount.dive=0.;w.velocity.y=-650.;w.jumps=1;w.air_time=0.
	return true # Consume airborne presses too: mounted heroes cannot double-jump.

static func step(w,dt: float) -> void:
	w.mount.dive=maxf(0.,float(w.mount.get("dive",0.))-dt)
	var gravity:=1700.
	if kind(w)=="wind" and w.jump_held and w.velocity.y>0.:gravity*=.12
	var old_foot: float=w.player.y+42.
	w.velocity.y+=gravity*dt;w.player.y+=w.velocity.y*dt
	var support: float=w.crossing_floor(w.player.x,old_foot,w.player.y+42.,w.velocity.y)
	var floor: float=support-42.+(24. if float(w.mount.dive)>0. else 0.)
	if w.player.y>=floor:
		w.player.y=floor;w.velocity.y=0.;w.jumps=0;w.air_time=0.;w.mount.floor_y=support
	else:w.air_time+=dt
	if kind(w)=="drill":
		for o in w.objects:
			if o.kind=="rock" and not bool(o.active) and absf(float(o.x)-w.player.x)<100. and w.fire_held:CampaignContent.hit_object(w,Vector2(float(o.x),-35.),3)
