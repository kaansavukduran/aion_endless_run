class_name CampaignHive
extends RefCounted

const KIND := "hive"
const SECTIONS := {"quay":5650., "relay":6900.}
const HP := 8
const WINDUP := .84
const DROP_INTERVAL := .36
const PASS_SPEED := 212.
const BLAST_RADIUS := 72.
const GRAVITY := 690.

static func step(w, e: Dictionary, dt: float) -> void:
	var home: Vector2=e.home
	var age: float=e.age
	var goal: float=clampf(w.player.x,home.x-170.,home.x+170.)
	var left: int=int(e.get("drops_left",0))
	if left==0 and float(e.windup)<=0.:
		e.x=move_toward(float(e.x),goal+sin(age*1.7)*100.,dt*104.)
	elif left>0:
		e.x=move_toward(float(e.x),float(e.pass_end),dt*PASS_SPEED)
	e.y=home.y+sin(age*2.4)*12.
	if left>0:
		e.drop_clock=float(e.drop_clock)-dt
		if float(e.drop_clock)<=0.:
			drop(w,e)
			e.drops_left=left-1
			e.drop_clock=DROP_INTERVAL
			if left==1:e.wait=2.6
		return
	if float(e.windup)>0.:
		e.windup=maxf(0.,float(e.windup)-dt)
		if float(e.windup)<=0.:
			e.attacks=int(e.attacks)+1
			e.drops_left=3
			e.drop_clock=0.
		return
	e.wait=maxf(0.,float(e.wait)-dt)
	if float(e.wait)<=0. and absf(w.player.x-float(e.x))<445.:
		var dir:=1. if w.player.x>=float(e.x) else -1.
		e.pass_end=float(e.x)+dir*PASS_SPEED*(DROP_INTERVAL*2.+.12)
		e.pass_dir=dir
		e.windup=WINDUP

static func drop(w,e: Dictionary) -> void:
	var origin:=Vector2(float(e.x),float(e.y)+4.)
	w.bullets.append({"p":origin,"v":Vector2(48.*float(e.pass_dir),95.),"owner":"enemy",
		"age":0.,"life":2.5,"kind":"honeycomb","damage":1,"pierce":0,"hit":[]})
	w.pending_events.append("hive_drop")

static func step_comb(w, b: Dictionary, dt: float) -> void:
	var old: Vector2=b.p
	b.age=float(b.age)+dt
	b.v=Vector2(b.v)+Vector2(0.,GRAVITY*dt)
	b.p=old+Vector2(b.v)*dt
	var surface: float=w.crossing_floor(float(b.p.x),old.y+8.,float(b.p.y)+8.,float(b.v.y),false)
	var landed: bool=CampaignGround.has_floor(surface) and float(b.p.y)+8.>=surface
	if not landed and not CampaignRoutes.solid_at(w,b.p):return
	if landed:b.p.y=surface
	var p: Vector2=b.p
	w.blasts.append({"p":p,"age":0.,"life":.52,"radius":BLAST_RADIUS,"color":"ffc25e","kind":"honeycomb"})
	b.age=99.
	var center: Vector2=w.player_hit_center()
	if absf(center.x-p.x)<BLAST_RADIUS and absf(center.y-p.y)<55.:
		w.damage_player("explosion")
	w.pending_events.append("hive_splash")

const ART=preload("res://assets/MISSION1-HIVE-PROVENANCE.json")
const SHEET=preload("res://assets/mission1-hive.png")
static var cels: Dictionary={}

static func pose(frame: int) -> Dictionary:
	if not cels.has(frame):
		var is_bee:=frame==6
		var source: Dictionary={} if is_bee else ART.data.frames[frame]
		var b: Array=ART.data.bee if is_bee else source.rect
		var region:=Rect2(b[0],b[1],b[2],b[3])
		var texture:=AtlasTexture.new();texture.atlas=SHEET;texture.region=region;texture.filter_clip=true
		var scale:=.25 if is_bee else float(ART.data.scale)
		var origin:=region.size*.5 if is_bee else Vector2(source.pivot[0],source.pivot[1])
		cels[frame]={"texture":texture,"offset":-origin*scale,"size":region.size*scale}
	return cels[frame]

static func draw_hive(view,e: Dictionary,p: Vector2) -> void:
	var moving: bool=view.host.motion_enabled and not view.host.options.reduced_motion
	var age: float=e.age
	var frame:=posmod(int(age*13.),3) if moving else 0
	if int(e.get("drops_left",0))>0:frame=4 if float(e.get("drop_clock",0.))>.1 else 5
	elif float(e.windup)>0.:frame=3
	if bool(e.defeated):
		var dead: float=e.dead_age
		p.y=minf(view.world.floor_at(p.x),p.y+640.*dead*dead)
		view.draw_pose(pose(5),p,1,1.,Color("a88978"))
		return
	view.draw_pose(pose(frame),p)
	for i in 2:
		var angle: float=age*4.+PI*i if moving else PI*.2+PI*i
		var orbit:=Vector2(cos(angle)*64.,-35.+sin(angle)*28.)
		view.draw_pose(pose(6),p+orbit,-1 if sin(angle)>0. else 1)
	view.small_health(view.at(p+Vector2(-32.,-153.)),64.,float(e.hp)/float(e.max_hp))

static func draw_warning(view,e: Dictionary) -> void:
	var clock: float=e.windup
	var color:=Color("efab4b");color.a=.6+(.4*(1.-clock/WINDUP))
	for i in 3:
		var fall_x: float=move_toward(float(e.x),float(e.pass_end),PASS_SPEED*float(i)*DROP_INTERVAL)+float(e.pass_dir)*35.
		var ground: float=view.world.floor_at(fall_x)
		if not CampaignGround.has_floor(ground):continue
		var a: Vector2=view.at(Vector2(fall_x,ground))
		view.draw_rect(Rect2(a.x-BLAST_RADIUS,a.y-4.,BLAST_RADIUS*2.,4.),color)
		view.draw_rect(Rect2(a.x-3.,a.y-13.,6.,9.),color)
	view.caption("!",view.at(Vector2(float(e.x)-4.,float(e.y)-165.)),21)
