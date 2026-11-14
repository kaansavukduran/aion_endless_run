class_name AionCampaignView
extends Node2D

var host
var world: AionCampaignWorld
var frames := RunnerFrameBank.new()
var art := AionCampaignArt.new()
var landscape := RunnerLandscapeView.new()
var terrain := RunnerTerrainView.new()
var ground := 440.0
var scene_w := 1152.0
var scene_h := 648.0
var camera_x := 0.0
var camera_y := 0.0
var font: Font
var gun_parts: Dictionary = {}
var hero_marker: Dictionary = {}

func at(p: Vector2) -> Vector2: return Vector2(p.x-camera_x,p.y+ground).round()

func draw_pose(pose: Dictionary, p: Vector2, direction: int=1, growth: float=1., tint: Color=Color.WHITE) -> void:
	var factor: float = float(pose.get("scale",1.))
	var dimensions: Vector2 = pose.get("size",pose.texture.get_size()*factor)
	draw_set_transform(at(p),0,Vector2(direction*growth,growth))
	draw_texture_rect(pose.texture,Rect2((Vector2(pose.offset)*factor).round(),dimensions),false,tint)
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)

func existing(key: String,row: int,frame: int,p: Vector2,direction: int=1,growth: float=1.,tint: Color=Color.WHITE) -> void:
	draw_pose(frames.pose(key,row,clampi(frame,0,frames.count(key,row)-1)),p,direction,growth,tint)

func hero_pose(hero: String, moving: bool, airborne: bool, clock: float) -> Dictionary:
	var row: int = frames.hero_row(hero)
	var motion: bool=host.motion_enabled and not host.options.reduced_motion
	if world.state in ["dying","dead"] and world.death_cause!="pit":
		var death_row:=row*2+1
		return frames.pose("deaths",death_row,frames.progress("deaths",death_row,world.death_time/.8) if motion else frames.count("deaths",death_row)-1)
	if bool(world.mount.ridden):return frames.pose("gun-run",row,0)
	if world.melee_time>0.:
		return art.melee(hero,clampi(int((.28-world.melee_time)/.28*6.),0,5) if motion else 3)
	var key := "gun-fire" if world.shot_flash>0. else "gun-run"
	var frame: int = int((.18-world.shot_flash)/.18*frames.count(key,row)) if world.shot_flash>0. else (frames.cycle(key,row,clock,180.) if moving and motion else 0)
	if airborne or world.charging or (hero=="wolf" and world.boost_held and moving):
		key = "runner-"+hero; row = 2
		if world.charging or (hero=="wolf" and world.boost_held) or (hero=="owl" and world.gliding): row = 6
		if hero=="owl" and world.flap_time>0.: key = "owl-flap"; row = 0
		frame = (frames.cycle(key,row,world.time,.6) if row==6 or key=="owl-flap" else RunnerWorld.flight_frame_for(world.velocity.y,world.air_time,frames.count(key,row))) if motion else 0
		if world.charging:frame=frames.progress(key,row,world.charge_ratio()) if motion else 0
		elif key=="owl-flap":frame=frames.progress(key,row,1.-world.flap_time/.3) if motion else 0
	return frames.pose(key,row,clampi(frame,0,frames.count(key,row)-1))

func held_gun(hero: String,p: Vector2,direction: int) -> void:
	var row: int = frames.hero_row(hero)
	var key: String="gun-fire" if world.shot_flash>0. else "gun-run"
	var frame: int=clampi(int((.18-world.shot_flash)/.18*6.),0,5) if world.shot_flash>0. else 0
	var cache_key:=hero+key+str(frame)
	var point: Array=frames.PIXEL.data.atlases["pixel-"+hero].frames[4 if world.shot_flash>0. else 3][frame].muzzle
	if not gun_parts.has(cache_key):
		var pose: Dictionary = frames.pose(key,row,frame)
		var factor: float = pose.scale
		var from: Vector2 = ((Vector2(point[0],point[1])-Vector2(24,5))/factor-Vector2(pose.offset)).floor()
		var image: Image = pose.texture.get_image()
		var region := Rect2i(Vector2i(from),Vector2i(ceilf(37/factor),ceilf(12/factor))).intersection(Rect2i(Vector2i.ZERO,image.get_size()))
		gun_parts[cache_key] = {"texture":ImageTexture.create_from_image(image.get_region(region)),"offset":Vector2(pose.offset)+Vector2(region.position),"scale":factor}
	var hand_offset: Vector2=world.muzzle_offset()-Vector2(point[0],point[1])
	draw_pose(gun_parts[cache_key],p+Vector2(hand_offset.x*direction,hand_offset.y),direction)

func _draw() -> void:
	if world==null: return
	landscape.panorama(self,world.biome(),camera_x,.05)
	var base_ground:=ground
	ground-=camera_y
	draw_world()
	ground=base_ground

func draw_world() -> void:
	# Ground props share the exact collision groundline. They are decorative,
	# never platforms or invisible obstacles.
	for i in range(floori(camera_x/390.)-1,ceili((camera_x+scene_w)/390.)+1):
		var x: float = i*390.+160.
		if world.floor_at(x)!=0.: continue
		existing("flora",world.biome(),0 if host.options.reduced_motion or not host.motion_enabled else posmod(int(world.time/.7)+i,3),Vector2(x,0),1,.74)
	terrain.draw(self,world.biome(),world.biome(),1.,camera_x,.05)
	for pit in world.pits:
		var rect := Rect2(pit.x-camera_x,ground,pit.y-pit.x,scene_h-ground)
		draw_rect(rect,Color("131d26"))
		for side in [pit.x-8.,pit.y]:
			for y in range(0,120,12): draw_rect(Rect2(side-camera_x,ground+y,8,9),Color("536345"))
	for platform in world.platforms:
		var r := Rect2(at(platform.position),platform.size)
		# Bracketed wooden walkways, with posts in the scenery layer behind
		# the actors. Their caps exactly match the one-way collision surface.
		for dx in [14.,r.size.x-22.]:
			var post_height: float=ground-r.position.y
			draw_rect(Rect2(r.position+Vector2(dx,9),Vector2(7,post_height-9)),Color("635744"))
			draw_rect(Rect2(r.position+Vector2(dx+1,10),Vector2(2,post_height-10)),Color("aa9263"))
		draw_rect(r,Color("493f38")); draw_rect(Rect2(r.position,Vector2(r.size.x,3)),Color("d1bc86"))
		for x in range(0,int(r.size.x),18):
			draw_rect(Rect2(r.position+Vector2(x+1,3),Vector2(minf(16,r.size.x-x-1),9)),Color("9b835a") if x%36==0 else Color("8b7953"))
			draw_rect(Rect2(r.position+Vector2(x+3,4),Vector2(minf(9,r.size.x-x-3),1)),Color("c5a46c"))
		for dx in [7.,r.size.x-12.]:
			draw_rect(Rect2(r.position+Vector2(dx,3),Vector2(5,15)),Color("686c62"));draw_rect(Rect2(r.position+Vector2(dx+1,5),Vector2(2,2)),Color("d2cba4"))
	for gate in world.gates:
		if not world.gate_closed(gate): continue
		var p := at(Vector2(float(gate.x),0))
		draw_rect(Rect2(p-Vector2(6,155),Vector2(12,155)),Color("44445f"))
		for y in range(8,151,18): draw_rect(Rect2(p-Vector2(3,y),Vector2(6,9)),Color("f2bf77"))
		caption(host.t("arc_clear"),p+Vector2(-72,-168),16)
	for npc in world.npcs:
		existing("celebrants",int(npc.variant),posmod(int(world.time*5),frames.count("celebrants",int(npc.variant))),Vector2(float(npc.x),0),-1,.72)
		if not bool(npc.freed):
			var p := at(Vector2(float(npc.x),0))
			for x in range(-32,37,16): draw_rect(Rect2(p+Vector2(x,-82),Vector2(3,82)),Color("a9ccb9"))
			draw_rect(Rect2(p+Vector2(-36,-86),Vector2(76,5)),Color("e8bf7a"))
			caption(host.t("arc_rescue"),p+Vector2(-65,-99),16)
	for crate in world.crates:
		if int(crate.hp)<=0: continue
		var p := at(Vector2(float(crate.x),float(crate.y)))
		draw_rect(Rect2(p-Vector2(22,42),Vector2(44,42)),Color("63493b"))
		draw_rect(Rect2(p-Vector2(19,39),Vector2(38,36)),Color("b48d62"),false,3)
		draw_line(p-Vector2(16,6),p+Vector2(16,-36),Color("725445"),4)
	for item in world.pickups:
		if world.taken.has(str(item.id)): continue
		var p := Vector2(float(item.x),float(item.y))
		if str(item.kind).begins_with("fruit_"):
			var fruit: int=int(str(item.kind).trim_prefix("fruit_"))%8
			existing("pickups",int(fruit/6),fruit%6,p)
		else:
			var point := at(p)
			draw_rect(Rect2(point-Vector2(18,18),Vector2(36,36)),Color("3a3443"))
			draw_rect(Rect2(point-Vector2(15,15),Vector2(30,30)),Color("a7d7c5"),false,2)
			if item.kind=="grenade":
				draw_circle(point,7,Color(AionCampaignWorld.COLORS[world.character]));draw_rect(Rect2(point-Vector2(2,12),Vector2(4,6)),Color("fff2d4"))
			elif item.kind=="shield":
				draw_polygon(PackedVector2Array([point+Vector2(-10,-10),point+Vector2(10,-10),point+Vector2(8,5),point+Vector2(0,12),point+Vector2(-8,5)]),PackedColorArray([Color("9bd4c5")]))
			elif item.kind in ["heal","repair"]:
				var ink:=Color("f3aaac") if item.kind=="heal" else Color("e9c47e")
				draw_rect(Rect2(point-Vector2(3,11),Vector2(6,22)),ink);draw_rect(Rect2(point-Vector2(11,3),Vector2(22,6)),ink)
				if item.kind=="repair":draw_rect(Rect2(point-Vector2(11,3),Vector2(6,6)),Color("3a3443"))
			else:
				draw_line(point+Vector2(-10,-5),point+Vector2(11,-5),Color("fff2d4"),6.)
				draw_line(point+Vector2(-7,-3),point+Vector2(-7,10),Color("fff2d4"),5.)
				if item.kind=="arc":draw_line(point+Vector2(2,-10),point+Vector2(2,1),Color("7bd5ea"),3.)
	for e in world.enemies:
		if bool(e.defeated) and float(e.get("dead_age",0.))>.3: continue
		var p := Vector2(float(e.x),float(e.y))
		var tint := Color.WHITE
		if bool(e.defeated): tint.a = maxf(0.,1.-float(e.get("dead_age",0.))/.3)
		var attack: bool = float(e.windup)>0. or float(e.get("flash",0.))>0. or float(e.get("dash",0.))>0. or float(e.get("dive",0.))>0.
		var frame: int = posmod(int(float(e.age)*9.),6)
		if float(e.windup)>0.:frame=clampi(int((1.-float(e.windup)/(.85 if bool(e.mini) else .65))*3.),0,2)
		elif float(e.get("flash",0.))>0.:frame=clampi(3+int((.24-float(e.flash))/.24*3.),3,5)
		if str(e.kind) in ["drone","seed","warden"]:
			var row: int = {"drone":0,"seed":2,"warden":6}[str(e.kind)]+int(attack)
			draw_pose(art.pose(row,frame),p,int(e.facing),1.,tint)
		elif e.kind=="gnome": existing("enemies",4 if attack else 3,frame,p,int(e.facing),1.,tint)
		elif e.kind=="crow": existing("enemies",1 if attack else 0,frame,p,int(e.facing),1.,tint)
		else:
			var row: int = {"moth":0,"slime":1,"beetle":2,"wisp":3}.get(str(e.kind),0)
			existing("creatures",row,frame,p,int(e.facing),1.,tint)
		if attack:
			var point := at(p+Vector2(0,-70))
			draw_circle(point,5,Color("f7bb70")); caption("!",point+Vector2(-3,-10),20)
		if bool(e.mini) and not bool(e.defeated): small_health(at(p+Vector2(-35,-130)),70,float(e.hp)/float(e.max_hp))
	if bool(world.boss.active) or world.completed:
		var row: int = 8 if world.completed else (7 if float(world.boss.windup)>0. else 6)
		var frame: int=frames.progress("boss-designs",row,world.victory_time/1.2) if world.completed else posmod(int(float(world.boss.clock)*8),frames.count("boss-designs",row))
		existing("boss-designs",row,frame,Vector2(float(world.boss.x),float(world.boss.y)),-1,1.7)
		if float(world.boss.windup)>0.: caption(host.t("arc_boss_warning"),at(Vector2(float(world.boss.x)-130.,-215.)),19)
	if bool(world.mount.available) and int(world.mount.hp)>0:
		var p := Vector2(float(world.mount.x),-42.)
		if bool(world.mount.ridden): p.y = world.player.y
		var firing: bool=world.shot_flash>0. and bool(world.mount.ridden)
		var frame: int=clampi(int((.18-world.shot_flash)/.18*6.),0,5) if firing else posmod(int(world.time*8),6)
		draw_pose(art.pose(5 if firing else 4,frame),p,world.facing if bool(world.mount.ridden) else 1)
		if bool(world.mount.ridden):
			small_health(at(p+Vector2(-28,53)),56,float(world.mount.hp)/4.)
			if world.character=="sheep" and world.flock>1:
				draw_set_transform(at(p),0,Vector2(world.facing,1))
				draw_rect(Rect2(-66,12,59,5),Color("b89461"));draw_rect(Rect2(-66,17,59,3),Color("634b3a"));draw_line(Vector2(-62,20),Vector2(-35,31),Color("9e8058"),4.)
				draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
	var pose: Dictionary = hero_pose(world.character,absf(world.velocity.x)>1.,not world.grounded(),world.walk_distance)
	var tint := Color.WHITE
	if world.invulnerable>0.: tint=Color("ffd9ca")
	draw_pose(pose,world.player,world.facing,1.,tint)
	hero_marker={"anchor":[world.player.x,world.player.y],"facing":world.facing,"source":pose.get("source_key","campaign-melee"),"row":pose.get("source_row",0),"frame":pose.get("source_frame",0),"floor":world.floor_at(world.player.x)}
	if not bool(world.mount.ridden) and (not world.grounded() or world.charging or (world.character=="wolf" and world.boost_held)) and world.melee_time<=0.: held_gun(world.character,world.player,world.facing)
	if world.character=="sheep":
		for i in world.flock-1:
			if bool(world.mount.ridden):
				existing("runner-sheep",0,0,world.player+Vector2(-world.facing*(28.+i*24.),12.),world.facing,.55)
				continue
			var sample: Dictionary = {"p":world.player-Vector2((i+1)*52,0),"facing":world.facing}
			for old in world.trail:
				if float(old.time)<=world.time-float(i+1)*.27: sample=old
			var p: Vector2=sample.p
			existing("runner-sheep",2 if p.y<-.1 else 1,posmod(int(world.walk_distance/24.),frames.count("runner-sheep",1)),p,int(sample.facing),.67)
	if world.charging: small_health(at(world.player+Vector2(-28,-112)),56,world.charge_ratio())
	for b in world.bullets:
		var p := at(b.p)
		var color := Color("e1f5e7") if b.owner=="hero" else Color("eeb079")
		if b.kind=="arc": color=Color("89dbec")
		if b.kind=="wave": draw_rect(Rect2(p-Vector2(20,9),Vector2(40,18)),color)
		else: draw_line(p,p-Vector2(b.v).normalized()*12.,color,4.)
	for bomb in world.bombs:
		var p := at(bomb.p); var color := Color(str(bomb.color))
		draw_circle(p,9,Color("292331"));draw_circle(p,6,color);draw_rect(Rect2(p-Vector2(2,13),Vector2(4,7)),Color("f5e6bf"))
		for a in 4: draw_circle(p+Vector2.from_angle(world.time*5.+a*PI*.5)*12.,2,color)
	for blast in world.blasts:
		var phase: float=float(blast.age)/.5
		var color := Color(str(blast.color));color.a=(1.-phase)*.8
		draw_arc(at(blast.p),float(blast.radius)*phase,0,TAU,24,color,6.)
		for i in 8: draw_rect(Rect2(at(blast.p)+Vector2.from_angle(i*TAU/8.)*float(blast.radius)*phase-Vector2(3,3),Vector2(6,6)),color)
	if world.section!="arena":
		var p := at(Vector2(world.length()-140.,0))
		draw_rect(Rect2(p-Vector2(3,100),Vector2(6,100)),Color("cabb99"))
		draw_polygon(PackedVector2Array([p+Vector2(3,-100),p+Vector2(52,-80),p+Vector2(3,-60)]),PackedColorArray([Color("eaad7d")]))

func caption(value: String,p: Vector2,size: int) -> void:
	if font!=null: draw_string(font,p,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color("fff2d4"))

func small_health(p: Vector2,width: float,ratio: float) -> void:
	draw_rect(Rect2(p,Vector2(width,7)),Color("332638"))
	draw_rect(Rect2(p+Vector2(1,1),Vector2((width-2.)*clampf(ratio,0,1),5)),Color("e9ba7e"))
