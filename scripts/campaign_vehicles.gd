class_name CampaignVehicles
extends RefCounted

const TYPES := ["skimmer","shell","wind","drill"]
static func kind(w) -> String:return str(w.mount.get("type","skimmer"))
static func eject(w) -> void:
	w.mount.ridden=false;w.mount.available=false;w.mount.wreck_age=0.
	for offset in [0.,-80.,80.,-160.,160.,-260.,260.]:
		var x: float=clampf(w.player.x+offset,70.,w.length()-80.)
		if w.floor_at(x)==0.:w.player=Vector2(x,-80.);break
	w.velocity=Vector2(0,-260.)

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
