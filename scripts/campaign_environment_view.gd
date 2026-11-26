class_name CampaignEnvironmentView
extends RefCounted
const PANORAMA=preload("res://assets/campaign-panorama.png")

static func background(v) -> bool:
	var row: int=["water","terrace","roots"].find("terrace" if v.world.section=="fork_two" else v.world.section)
	if row<0:return false
	var source_h: float=PANORAMA.get_height()/3.
	var scale: float=maxf(v.scene_w/PANORAMA.get_width(),v.scene_h/source_h)*1.1
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
	var animated: bool=v.host.motion_enabled and not v.host.options.reduced_motion
	for room in w.rooms:
		if absf(float(room.x)-w.player.x)>v.scene_w:continue
		if bool(room.opened):
			v.draw_pose(v.catalogue.pose("environment",7,3),Vector2(float(room.x),float(room.y)))
		elif float(w.buffs.get("reveal",0.))>0.:
			v.draw_arc(v.at(Vector2(float(room.x),-140.)),40.,0,TAU,16,Color("f1d98c"),3.)
	if w.section=="relay":
		for cover: Rect2 in CampaignContent.RELAY_COVERS:
			if cover.end.x>=v.camera_x and cover.position.x<=v.camera_x+v.scene_w:
				CampaignForgePropArt.draw(v,"relay_cover",v.at(Vector2(cover.get_center().x,cover.end.y)))
	for o in w.objects:
		if absf(float(o.x)-w.player.x)>v.scene_w:continue
		var row: int=CampaignContent.OBJECTS.find(str(o.kind))
		var frame:=0
		if bool(o.active):frame=clampi(int(float(o.get("changed",9.))/.18),1,3) if animated else 3
		elif o.kind in ["current","updraft"]:frame=3
		elif o.kind=="turret" and CampaignContent.turret_warning(o):frame=1
		if w.completed and o.kind=="lamp":frame=3
		if o.kind=="copper_grate":
			var grate_frame:=3 if bool(o.active) else 2-int(o.hp)
			if bool(o.active) and animated and float(o.get("changed",9.))<.18:grate_frame=2
			CampaignForgePropArt.draw(v,"copper_grate",v.at(Vector2(float(o.x),float(o.y))),grate_frame)
		elif o.kind=="gate":
			CampaignLockArt.gate(v,v.at(Vector2(float(o.x),float(o.y))),w.section,
				CampaignLockArt.opening_frame(float(o.get("changed",9.)),animated) if bool(o.active) else 0,.76)
		elif o.kind=="turret":
			v.draw_pose(v.catalogue.pose("environment",row,frame),Vector2(float(o.x),float(o.y)),int(o.get("facing",1)))
		else:v.draw_pose(v.catalogue.pose("environment",row,frame),Vector2(float(o.x),float(o.y)))
	CampaignStory.draw(v)
	# 0.38.0: Distinct, readable environmental zone cues for water current, terrace updraft, and roots darkness.
	for z in w.zones:
		if float(z.x)+float(z.width)<v.camera_x-80. or float(z.x)>v.camera_x+v.scene_w+80.:continue
		var z_left: float=v.at(Vector2(float(z.x),0.)).x
		var surface: float=w.floor_at(float(z.x))
		if not CampaignGround.has_floor(surface):surface=0.
		var z_w: float=float(z.width)
		var garden: bool=z.id=="terrace:garden-draft"
		var lifting: bool=not garden or CampaignGround.garden_draft_active(w.time)
		if garden:
			var cycle: float=fposmod(w.time,CampaignGround.GARDEN_DRAFT_PERIOD)
			var pennant:=1 if lifting else (2 if cycle<CampaignGround.GARDEN_DRAFT_WARNING else 0)
			if lifting and animated and posmod(int(w.time*8.),2)==1:pennant=3
			for x in [float(z.x)+36.,float(z.x)+230.]:
				CampaignForgePropArt.draw(v,"wind_pennant",v.at(Vector2(x,w.floor_at(x))),pennant)
		if z.kind=="dark":
			# Subtle shadow veil drawn behind actors/bullets so telegraphs stay crystal-clear.
			var ground_only: bool=bool(z.get("ground_only",false))
			var shade_top: float=v.at(Vector2(float(z.x),-24.)).y if ground_only else 0.
			var shade_bottom: float=v.scene_h if ground_only else v.ground+12.
			v.draw_rect(Rect2(z_left,shade_top,z_w,shade_bottom-shade_top),Color(0.04,0.03,0.08,0.34))
			var lantern: Vector2=v.at(w.player+Vector2(0.,-36.))
			if lantern.y>=shade_top:
				v.draw_circle(lantern,110.,Color(1.0,0.84,0.56,0.10))
				v.draw_arc(lantern,110.,0.,TAU,24,Color(1.0,0.84,0.56,0.18),2.)
			continue
		var colour:=Color("83c6d5") if z.kind=="current" else Color("bfe8d4")
		colour.a=.34 if lifting else .12
		var phase: float=fmod(w.time*45.,90.) if animated else 0.
		if z.kind=="current":
			var zone_end: float=float(z.x)+z_w
			var start_x: float=maxf(v.camera_x,float(z.x))
			var end_x: float=minf(v.camera_x+v.scene_w,zone_end)
			for left in range(floori(start_x),ceili(end_x),45):
				var right: float=minf(left+45.,zone_end)
				var left_floor: float=w.floor_at(left)
				var right_floor: float=w.floor_at(right)
				if not CampaignGround.has_floor(left_floor) or not CampaignGround.has_floor(right_floor):continue
				var a: Vector2=v.at(Vector2(left,left_floor))
				var b: Vector2=v.at(Vector2(right,right_floor))
				v.draw_colored_polygon(PackedVector2Array([a-Vector2(0,34),b-Vector2(0,34),b,a]),Color(0.24,0.58,0.70,0.14))
		else:
			v.draw_rect(Rect2(z_left,v.ground+surface-175.,z_w,175.),Color(0.55,0.82,0.74,0.10))
		for i in range(0,int(z.width),90):
			if z.kind=="current":
				var x: float=float(z.x)+i+phase
				var base: float=w.floor_at(x)
				if not CampaignGround.has_floor(base):continue
				var p: Vector2=v.at(Vector2(x,base-20.))
				v.draw_rect(Rect2(p,Vector2(24.,2.)),colour)
				v.draw_rect(Rect2(p+Vector2(22.,-3.),Vector2(9.,2.)),colour)
				v.draw_rect(Rect2(p+Vector2(29.,0.),Vector2(6.,2.)),colour.lightened(.3))
				v.draw_rect(Rect2(p+Vector2(22.,3.),Vector2(9.,2.)),colour)
			elif z.kind=="updraft":
				var lift: float=fmod(w.time*65.+float(i),130.) if animated else 45.
				var x: float=float(z.x)+i
				var base: float=w.floor_at(x)
				if not CampaignGround.has_floor(base):continue
				var p: Vector2=v.at(Vector2(x,base-18.-lift))
				v.draw_line(p,p-Vector2(0,48),colour,2.5)
				v.draw_line(p+Vector2(-5,-42),p-Vector2(0,48),colour,2.)
				v.draw_line(p+Vector2(5,-42),p-Vector2(0,48),colour,2.)
	# 0.38.0: Hazard telegraphs match each hazard's real danger altitude and mechanism.
	for h in w.hazards:
		if absf(float(h.x)-w.player.x)>v.scene_w:continue
		var surface: float=w.floor_at(float(h.x))
		if not CampaignGround.has_floor(surface):continue
		var p: Vector2=v.at(Vector2(float(h.x),surface))
		CampaignLockArt.trap(v,p,str(h.kind),float(h.phase),animated)
