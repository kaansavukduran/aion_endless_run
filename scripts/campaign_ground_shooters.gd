class_name CampaignGroundShooters
extends RefCounted

const ROLES := {
	"lantern_scout":{"speed":78.,"ready_range":465.,"windup":.69,"recover":.69,"speed_px":372.,"gravity":0.,"colour":"f5c986","kind":"scout_bolt"},
	"cap_lobber":{"speed":61.,"ready_range":425.,"windup":.88,"recover":.83,"speed_px":0.,"gravity":590.,"colour":"cde295","kind":"lob_seed"}
}
const ARC_SECONDS := .86
const RELEASE_SECONDS := .14
const FIRST_PREPARATION := .55
const BURST_SPACING := .20
const DATA := preload("res://assets/CAMPAIGN-GROUND-SHOOTERS-PROVENANCE.json")
const ART := preload("res://assets/campaign-ground-shooters.png")
const DEFEAT_ART := preload("res://assets/campaign-ground-shooter-defeats.png")
static var frames: Dictionary={}
static var defeats: Dictionary={}

static func has(kind: String) -> bool:
	return ROLES.has(kind)

static func pose(e: Dictionary,reduced_motion: bool) -> Dictionary:
	if bool(e.defeated):return defeat_pose(e,reduced_motion)
	var row:=0
	var frame:=posmod(int(float(e.get("stride",0.))/98.*6.),6) if not reduced_motion else 0
	if float(e.windup)>0. or float(e.get("recover",0.))>0.:
		row=1
		if float(e.get("release",0.))>0.:frame=3
		elif float(e.get("recover",0.))>0.:frame=4
		else:frame=1 if float(e.windup)>float(ROLES[e.kind].windup)*.48 else 2
	var registration: Dictionary=DATA.data.roles[e.kind]
	var source_row:=int(registration.rows[row])
	var key:=Vector2i(frame,source_row)
	if not frames.has(key):
		var texture:=AtlasTexture.new();texture.atlas=ART
		texture.region=Rect2(key*256,Vector2(256.,256.));texture.filter_clip=true
		var factor: float=DATA.data.scale
		frames[key]={"texture":texture,"offset":-Vector2(float(registration.foot_x),float(registration.foot_bottom[row][frame]))*factor,"size":Vector2(256.,256.)*factor}
	return frames[key]

static func defeat_pose(e: Dictionary,reduced_motion: bool) -> Dictionary:
	var entry: Dictionary=DATA.data.roles[e.kind].defeat
	var frame:=2 if reduced_motion else clampi(int(float(e.get("dead_age",0.))/.13),0,2)
	var key:=Vector2i(frame,int(entry.row))
	if not defeats.has(key):
		var texture:=AtlasTexture.new();texture.atlas=DEFEAT_ART
		texture.region=Rect2(key*512,Vector2(512.,512.));texture.filter_clip=true
		var scale: float=entry.scale
		defeats[key]={"texture":texture,"offset":-Vector2(float(entry.foot[0]),float(entry.foot[1]))*scale,"size":Vector2(512.,512.)*scale}
	return defeats[key]

static func origin(e: Dictionary) -> Vector2:
	var registration: Dictionary=DATA.data.roles[e.kind]
	var muzzle: Array=registration.release_pixel
	var relative:=Vector2((float(muzzle[0])-float(registration.foot_x))*int(e.facing),float(muzzle[1])-float(registration.foot_bottom[1][3]))*float(DATA.data.scale)
	return Vector2(float(e.x),float(e.y))+relative

static func visible_threat(w,e: Dictionary) -> bool:
	var centre:=Vector2(float(e.x),float(e.y)-38.)
	if w.recovery_view.has_area():
		return w.recovery_view.has_point(centre) and centre.x>w.recovery_view.position.x+18. and centre.x<w.recovery_view.end.x-20.
	return absf(centre.x-w.player.x)<525.

static func velocity(e: Dictionary) -> Vector2:
	var spec: Dictionary=ROLES[e.kind]
	if float(spec.gravity)<=0.:return Vector2(int(e.facing)*float(spec.speed_px),0.)
	var point: Vector2=e.get("throw_target",Vector2(float(e.x)+180.*int(e.facing),float(e.y)-32.))
	return (point-origin(e))/ARC_SECONDS-Vector2(0.,float(spec.gravity)*ARC_SECONDS*.5)

static func walk(w,e: Dictionary,direction: int,dt: float) -> void:
	var candidate: float=clampf(float(e.x)+direction*float(ROLES[e.kind].speed)*dt,42.,w.length()-80.)
	var height: float=w.floor_at(candidate)
	if not CampaignGround.has_floor(height) or absf(height-float(e.y))>24.:return
	if not is_equal_approx(candidate,float(e.x)):
		e.stride=float(e.get("stride",0.))+absf(candidate-float(e.x))
		e.x=candidate;e.y=height;e.facing=direction

static func release_shot(w,e: Dictionary,spec: Dictionary) -> void:
	w.bullets.append({"p":origin(e),"v":velocity(e),"owner":"enemy","kind":str(spec.kind),
		"colour":str(spec.colour),"gravity":float(spec.gravity),"age":0.,"damage":1,"pierce":0,"hit":[],"life":2.})
	e.release=RELEASE_SECONDS
	w.pending_events.append("scout_shot" if e.kind=="lantern_scout" else "lob_throw")

static func step(w,e: Dictionary,dt: float) -> bool:
	if not has(str(e.kind)):return false
	var spec: Dictionary=ROLES[e.kind]
	var dx: float=w.player.x-float(e.x)
	var face:=1 if dx>=0. else -1
	if float(e.get("recover",0.))>0.:
		e.recover=maxf(0.,float(e.recover)-dt)
		e.release=maxf(0.,float(e.get("release",0.))-dt)
		if bool(e.get("burst_pending",false)) and float(e.recover)<=float(spec.recover)-BURST_SPACING:
			e.burst_pending=false
			if visible_threat(w,e) and dx*int(e.facing)>0. and absf(dx)<=float(spec.ready_range)+55.:
				release_shot(w,e,spec)
		return true
	if float(e.windup)>0.:
		e.windup=maxf(0.,float(e.windup)-dt)
		if float(e.windup)>0.:return true
		if not visible_threat(w,e) or absf(dx)>float(spec.ready_range)+55.:
			e.wait=.25;e.burst_pending=false
			return true
		release_shot(w,e,spec)
		e.recover=float(spec.recover);e.wait=.15;e.attacks=int(e.attacks)+1
		return true
	e.wait=maxf(0.,float(e.wait)-dt)
	if float(e.age)>=FIRST_PREPARATION and float(e.wait)<=0. and absf(dx)<=float(spec.ready_range) and absf(w.player.y-float(e.y))<175. and visible_threat(w,e):
		e.windup=float(spec.windup);e.facing=face
		e.throw_target=w.player+Vector2(0.,-31.)
		e.burst_pending=e.kind=="lantern_scout" and int(e.attacks)%3!=0
	elif absf(dx)>float(spec.ready_range)*.72:
		walk(w,e,face,dt)
	elif absf(dx)<160. and int(e.attacks)>0:
		walk(w,e,-face,dt)
	return true

static func draw(v,e: Dictionary,body: Vector2) -> void:
	var reduced: bool=not v.host.motion_enabled or v.host.options.reduced_motion
	v.draw_pose(pose(e,reduced),body,int(e.facing))
	if bool(e.defeated) or float(e.windup)<=0.:return
	var tint:=Color(str(ROLES[e.kind].colour))
	var start:=origin(e)
	if e.kind=="lantern_scout":
		for i in range(1,12):
			var mark:=start+Vector2(int(e.facing)*i*28.,0.)
			if CampaignGround.touches_ground(v.world,start,mark):break
			v.draw_rect(Rect2(v.at(mark),Vector2(6.,2.)),tint)
			if bool(e.get("burst_pending",false)):
				v.draw_rect(Rect2(v.at(mark+Vector2(0.,-6.)),Vector2(4.,2.)),tint)
	else:
		var direction:=velocity(e)
		for i in range(1,8):
			var elapsed:=ARC_SECONDS*i/8.
			var mark:=start+direction*elapsed+Vector2(0.,float(ROLES[e.kind].gravity)*elapsed*elapsed*.5)
			v.draw_rect(Rect2(v.at(mark),Vector2(4.,3.)),tint)
