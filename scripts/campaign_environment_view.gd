class_name CampaignEnvironmentView
extends RefCounted
const PANORAMA=preload("res://assets/campaign-panorama.png")

static func background(v) -> bool:
	var row: int=["water","terrace","roots"].find(v.world.section)
	if row<0:return false
	var source_h: float=PANORAMA.get_height()/3.
	var scale: float=maxf(v.scene_w/PANORAMA.get_width(),v.ground/source_h)*1.1
	var width: float=PANORAMA.get_width()*scale
	var offset: float=fmod(v.camera_x*.12,width) if v.host.motion_enabled and not v.host.options.reduced_motion else 0.
	for i in range(-1,ceili(v.scene_w/width)+2):
		var mirror: bool=posmod(i,2)==1
		v.draw_set_transform(Vector2(i*width-offset+(width if mirror else 0.),0.),0.,Vector2(-1 if mirror else 1,1))
		v.draw_texture_rect_region(PANORAMA,Rect2(0,0,width,source_h*scale),Rect2(0,row*source_h+2.,PANORAMA.get_width(),source_h-4.))
	v.draw_set_transform(Vector2.ZERO,0.,Vector2.ONE)
	return true

static func draw(v) -> void:
	var w=v.world
	for room in w.rooms:
		if absf(float(room.x)-w.player.x)>v.scene_w:continue
		if bool(room.opened):
			v.draw_pose(v.catalogue.pose("environment",7,3),Vector2(float(room.x),float(room.y)))
		elif float(w.buffs.get("reveal",0.))>0.:
			v.draw_arc(v.at(Vector2(float(room.x),-140.)),40.,0,TAU,16,Color("f1d98c"),3.)
	for o in w.objects:
		if absf(float(o.x)-w.player.x)>v.scene_w:continue
		var row: int=CampaignContent.OBJECTS.find(str(o.kind))
		var frame:=0
		if bool(o.active):frame=clampi(int(float(o.get("changed",9.))/.18),1,3) if v.host.motion_enabled and not v.host.options.reduced_motion else 3
		elif o.kind in ["current","updraft"]:frame=3
		elif o.kind=="turret" and fmod(float(o.get("clock",0.)),3.)>2.2:frame=1
		if w.completed and o.kind=="lamp":frame=3
		v.draw_pose(v.catalogue.pose("environment",row,frame),Vector2(float(o.x),float(o.y)))
	for z in w.zones:
		if absf(float(z.x)-w.player.x)>v.scene_w+float(z.width):continue
		var colour:=Color("83c6d5");colour.a=.28
		var phase: float=fmod(w.time*30.,90.) if v.host.motion_enabled and not v.host.options.reduced_motion else 0.
		for i in range(0,int(z.width),90):
			var p: Vector2=v.at(Vector2(float(z.x)+i+phase,-26.))
			if z.kind=="current":v.draw_line(p,p+Vector2(28,0),colour,2.)
			elif z.kind=="updraft":v.draw_line(p,p-Vector2(0,90),colour,2.)
	for h in w.hazards:
		if absf(float(h.x)-w.player.x)>v.scene_w:continue
		var p: Vector2=v.at(Vector2(float(h.x),0))
		var active: bool=float(h.phase)>=3.5 and float(h.phase)<4.1
		if bool(h.warn):
			for x in range(-50,51,15):v.draw_rect(Rect2(p+Vector2(x,-5),Vector2(7,4)),Color("efbc6b"))
		if active:
			var ink:=Color("87d5ed") if h.kind=="electric" else Color("cfaa78")
			for x in range(-45,46,15):
				if h.kind=="electric":v.draw_polyline(PackedVector2Array([p+Vector2(x,0),p+Vector2(x+6,-35),p+Vector2(x,-28),p+Vector2(x+8,-65)]),ink,3.)
				else:v.draw_rect(Rect2(p+Vector2(x,-60),Vector2(8,60)),ink)
	if w.section=="arena" and float(w.boss.get("beam_warning",0.))>0.:
		var p: Vector2=v.at(Vector2(float(w.boss.beam_x),0))
		v.draw_rect(Rect2(p-Vector2(36,350),Vector2(72,350)),Color(1.,.7,.3,.18))
		v.draw_line(p-Vector2(0,330),p,Color("ebc37f"),3.)
