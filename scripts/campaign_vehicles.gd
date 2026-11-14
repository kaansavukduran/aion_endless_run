class_name CampaignVehicles
extends RefCounted

const TYPES := ["skimmer","shell","wind","drill"]
static func kind(w) -> String:return str(w.mount.get("type","skimmer"))
static func eject(w) -> void:
	w.mount.ridden=false;w.mount.available=false;w.mount.wreck_age=0.
	w.mount_transition="";w.mount_transition_time=0.;w.stop_inputs()
	for offset in [0.,-80.,80.,-160.,160.,-260.,260.]:
		var x: float=clampf(w.player.x+offset,70.,w.length()-80.)
		if w.floor_at(x)==0.:w.player=Vector2(x,-80.);break
	w.velocity=Vector2(0,-260.)


## Board/exit have deliberate short root motion, independent of sprite-frame
## registration. While the hatch is moving the world is paused and safe.
static func interact(w) -> bool:
	if bool(w.mount.ridden):
		var target:=Vector2.ZERO
		var found:=false
		for offset in [-100.,100.,-180.,180.,-260.,260.]:
			var x: float=clampf(w.player.x+offset,35.,w.length()-90.)
			if w.floor_at(x)==0.:target=Vector2(x,0.);found=true;break
		if not found:return false
		w.mount_transition="exit";w.mount.ridden=false;w.mount.x=w.player.x
		w.mount_transition_to=target
	elif bool(w.mount.available) and int(w.mount.hp)>0 and absf(w.player.x-float(w.mount.x))<150. and w.player.y>-90.:
		w.mount_transition="enter";w.mount.ridden=true
		w.mount_transition_to=Vector2(float(w.mount.x),-42.)
	else:return false
	w.mount.facing=w.facing
	w.mount_transition_from=w.player;w.mount_transition_time=0.
	w.velocity=Vector2.ZERO;w.stop_inputs()
	return true

static func step_transition(w,dt: float) -> void:
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
	if kind(w)=="shell":w.mount.dive=1.;w.velocity.y=0.;return true
	return false

static func step(w,dt: float) -> void:
	w.mount.dive=maxf(0.,float(w.mount.get("dive",0.))-dt)
	var gravity:=1700.
	if kind(w)=="wind" and w.jump_held and w.velocity.y>0.:gravity*=.12
	w.velocity.y+=gravity*dt;w.player.y+=w.velocity.y*dt
	var floor: float=-42.+(24. if float(w.mount.dive)>0. else 0.)
	if kind(w)=="drill":floor+=w.floor_at(w.player.x)
	if w.player.y>=floor:w.player.y=floor;w.velocity.y=0.;w.jumps=0;w.air_time=0.
	else:w.air_time+=dt
	if kind(w)=="drill":
		for o in w.objects:
			if o.kind=="rock" and not bool(o.active) and absf(float(o.x)-w.player.x)<100. and w.fire_held:CampaignContent.hit_object(w,Vector2(float(o.x),-35.),3)
