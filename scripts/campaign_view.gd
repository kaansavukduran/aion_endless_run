class_name AionCampaignView
extends Node2D

var host
var world: AionCampaignWorld
var frames := RunnerFrameBank.new()
var art := AionCampaignArt.new()
var catalogue := CampaignCatalog.new()
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
var npc_growth_cache: Dictionary = {}
var item_bank := ForgeItemBank.new()
var vehicle_art := ForgeVehicleArt.new()
var forge_art := ForgeHeroArt.new()

# World facing (-1 = left) must be relative to each source drawing.
# Original drone/seed machine rows face right; other enemy sheets face left.
static func enemy_draw_direction(kind: String, facing: int) -> int:
	var source_facing: int=1 if kind in ["drone","seed"] else -1
	return source_facing*(-1 if facing<0 else 1)

func hero_reference_height() -> float:
	# Actual alpha silhouette, without texture padding, muzzle/particles or UI.
	return float(frames.pose("gun-run",frames.hero_row("aion"),0).height)

func npc_reference_height(row: int) -> float:
	# The departure walking pose is upright; bound poses intentionally sit lower.
	var data: Dictionary=catalogue.DATA.data.atlases["rescue-npcs"]
	var body: Array=data.frames[row][6].body_bounds
	return float(body[3]-body[1])*float(data.scales[row])

func at(p: Vector2) -> Vector2: return Vector2(p.x-camera_x,p.y+ground).round()

func draw_pose(pose: Dictionary, p: Vector2, direction: int=1, growth: float=1., tint: Color=Color.WHITE) -> void:
	var factor: float = float(pose.get("scale",1.))
	var dimensions: Vector2 = pose.get("size",pose.texture.get_size()*factor)
	draw_set_transform(at(p),0,Vector2(direction*growth,growth))
	draw_texture_rect(pose.texture,Rect2((Vector2(pose.offset)*factor).round(),dimensions),false,tint)
	draw_set_transform(Vector2.ZERO,0,Vector2.ONE)

func npc_growth(row: int) -> float:
	# One standing anatomical reference per identity; no per-frame renormalizing.
	if not npc_growth_cache.has(row):
		npc_growth_cache[row]=2.*hero_reference_height()/maxf(1.,npc_reference_height(row))
	return float(npc_growth_cache[row])

func vehicle_pose(type: String,phase: int,frame: int) -> Dictionary:
	return vehicle_art.pose(type,phase,frame,hero_reference_height()*2.)

func vehicle_draw_position() -> Vector2:
	# The rider climbs into a stationary hull. Its saddle root is meaningful
	# only after entry has finished; applying it early sinks the whole hull.
	return Vector2(float(world.mount.x),world.player.y+42. if bool(world.mount.ridden) and world.mount_transition!="enter" else 0.)

func vehicle_draw_facing() -> int:
	return world.facing if bool(world.mount.ridden) or not world.mount_transition.is_empty() else int(world.mount.get("facing",1))

func existing(key: String,row: int,frame: int,p: Vector2,direction: int=1,growth: float=1.,tint: Color=Color.WHITE) -> void:
	draw_pose(frames.pose(key,row,clampi(frame,0,frames.count(key,row)-1)),p,direction,growth,tint)

func hero_pose(hero: String, moving: bool, airborne: bool, clock: float) -> Dictionary:
	var row: int = frames.hero_row(hero)
	var motion: bool=host.motion_enabled and not host.options.reduced_motion
	if world.state in ["dying","dead"] and world.death_cause!="pit":
		var death_row:=row*2+1
		return frames.pose("deaths",death_row,frames.progress("deaths",death_row,world.death_time/.8) if motion else frames.count("deaths",death_row)-1)
	if bool(world.mount.ridden):return frames.pose("gun-run",row,0)
	if world.rescue_time>0.:
		return catalogue.pose("rescue-heroes",row,clampi(int((.6-world.rescue_time)/.6*6.),0,5) if motion else 3)
	if world.melee_time>0.:
		return art.melee(hero,clampi(int((.28-world.melee_time)/.28*6.),0,5) if motion else 3)
	var armed: Dictionary=world.armed_art_spec()
	if not armed.is_empty():
		return forge_art.pose(str(armed.key),int(armed.row),int(armed.frame) if motion or str(armed.key)!="mouth-carry" else 0)
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
		var pose: Dictionary = frames.pose(key,row,frame,true)
		var factor: float = pose.scale
		var from: Vector2 = ((Vector2(point[0],point[1])-Vector2(24,5))/factor-Vector2(pose.offset)).floor()
		var image: Image = pose.texture.get_image()
		var region := Rect2i(Vector2i(from),Vector2i(ceilf(37/factor),ceilf(12/factor))).intersection(Rect2i(Vector2i.ZERO,image.get_size()))
		gun_parts[cache_key] = {"texture":ImageTexture.create_from_image(image.get_region(region)),"offset":Vector2(pose.offset)+Vector2(region.position),"scale":factor}
	var hand_offset: Vector2=world.muzzle_offset()-Vector2(float(point[0])*direction,float(point[1]))
	draw_pose(gun_parts[cache_key],p+hand_offset,direction)

func _draw() -> void:
	if world==null: return
	if not CampaignEnvironmentView.background(self):landscape.panorama(self,world.biome(),camera_x,.05)
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
	CampaignEnvironmentView.draw(self)
	for pit in world.pits:
		var rect := Rect2(pit.x-camera_x,ground,pit.y-pit.x,scene_h-ground)
		draw_rect(rect,Color("131d26"))
		for side in [pit.x-8.,pit.y]:
			for y in range(0,120,12): draw_rect(Rect2(side-camera_x,ground+y,8,9),Color("536345"))
	for platform in world.platforms:
		if platform.end.x<camera_x-50. or platform.position.x>camera_x+scene_w+50.:continue
		if world.disabled_platforms.has(platform.position.x):continue
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
		if float(gate.x)<camera_x-100. or float(gate.x)>camera_x+scene_w+100.:continue
		if not world.gate_closed(gate): continue
		var p := at(Vector2(float(gate.x),0))
		draw_rect(Rect2(p-Vector2(6,155),Vector2(12,155)),Color("44445f"))
		for y in range(8,151,18): draw_rect(Rect2(p-Vector2(3,y),Vector2(6,9)),Color("f2bf77"))
		caption(host.t("arc_clear"),p+Vector2(-72,-168),16)
	for npc in world.npcs:
		if float(npc.x)<camera_x-150. or float(npc.x)>camera_x+scene_w+150.:continue
		if str(npc.secret)!="" and not world.discovered.has(str(npc.secret)):continue
		var phase: String=str(npc.get("phase","free" if bool(npc.freed) else "bound"))
		var age: float=float(npc.get("thank_age",0.))
		if phase=="departed" and age>4.8:continue
		var animated: bool=host.motion_enabled and not host.options.reduced_motion
		var frame: int=posmod(int(world.time*2.),2) if animated else 0
		if phase in ["free","departed"]:frame=6+posmod(int(world.time*6.),2) if animated else 6
		elif phase=="thanks":frame=2 if age<.2 else (3 if age<.45 else (4 if age<.9 else (5 if age<2.4 else 6+posmod(int(age*6.),2))))
		var npc_pose: Dictionary=catalogue.pose("rescue-npcs",int(npc.variant),frame)
		var growth: float=npc_growth(int(npc.variant))
		draw_pose(npc_pose,Vector2(float(npc.x),float(npc.y)),int(npc.get("facing",1)) if phase in ["free","departed"] else 1,growth)
		var p := at(Vector2(float(npc.x),float(npc.y)))
		var label_top: float=maxf(46.,p.y+minf(-90.,float(npc_pose.offset.y)*growth-12.))
		if phase=="bound":caption(host.t("cut"),Vector2(clampf(p.x-35.,8.,scene_w-200.),label_top),17)
		elif phase=="thanks" and age<2.4:
			caption(host.t("thanks"),Vector2(clampf(p.x-48.,8.,scene_w-200.),label_top),17)
			if age>.9:caption(host.t(str(npc.gift)),Vector2(clampf(p.x-48.,8.,scene_w-200.),label_top+20.),16)
	for crate in world.crates:
		if float(crate.x)<camera_x-80. or float(crate.x)>camera_x+scene_w+80.:continue
		if int(crate.hp)<=0: continue
		var p := at(Vector2(float(crate.x),float(crate.y)))
		draw_rect(Rect2(p-Vector2(22,42),Vector2(44,42)),Color("63493b"))
		draw_rect(Rect2(p-Vector2(19,39),Vector2(38,36)),Color("b48d62"),false,3)
		draw_line(p-Vector2(16,6),p+Vector2(16,-36),Color("725445"),4)
	for item in world.pickups:
		if float(item.x)<camera_x-80. or float(item.x)>camera_x+scene_w+80.:continue
		if world.taken.has(str(item.id)): continue
		if item.has("secret") and not world.discovered.has(str(item.secret)):continue
		var p := Vector2(float(item.x),float(item.y))
		if str(item.kind).begins_with("fruit_"):
			var fruit: int=int(str(item.kind).trim_prefix("fruit_"))%8
			existing("pickups",int(fruit/6),fruit%6,p)
		else:
			# Every actual special weapon/support has its own original silhouette.
			# This is a registered static drawing, not a fabricated animation count.
			draw_pose(item_bank.pose(str(item.kind)),p)
	for e in world.enemies:
		if float(e.x)<camera_x-210. or float(e.x)>camera_x+scene_w+210.:continue
		if bool(e.defeated) and float(e.get("dead_age",0.))>.65: continue
		var p := Vector2(float(e.x),float(e.y))
		var direction: int=enemy_draw_direction(str(e.kind),int(e.facing))
		var tint := Color.WHITE
		if bool(e.defeated): tint.a = maxf(0.,1.-maxf(0.,float(e.get("dead_age",0.))-.45)/.2)
		var attack: bool = float(e.windup)>0. or float(e.get("flash",0.))>0. or float(e.get("dash",0.))>0. or float(e.get("dive",0.))>0.
		var frame: int = posmod(int(float(e.age)*9.),6)
		if bool(e.defeated):frame=clampi(int(float(e.get("dead_age",0.))/.65*6.),0,5)
		elif float(e.windup)>0.:frame=clampi(int((1.-float(e.windup)/(.85 if bool(e.mini) else .65))*3.),0,2)
		elif float(e.get("flash",0.))>0.:frame=clampi(3+int((.24-float(e.flash))/.24*3.),3,5)
		if CampaignContent.NEW_ENEMIES.has(str(e.kind)):
			var spec: Dictionary=CampaignContent.NEW_ENEMIES[str(e.kind)]
			var phase: int=3 if bool(e.defeated) else (1 if float(e.windup)>0. else (2 if float(e.get("flash",0.))>0. else 0))
			if CampaignEnemies.hidden(e):phase=1
			draw_pose(catalogue.pose(str(spec.atlas),int(spec.row)+phase,frame),p,direction,1.,tint)
		elif str(e.kind) in CampaignContent.HEAVIES and catalogue.DATA.data.atlases.has("heavy-machines"):
			var phase: int=3 if bool(e.defeated) else (1 if float(e.windup)>0. else (2 if float(e.get("flash",0.))>0. else 0))
			draw_pose(catalogue.pose("heavy-machines",CampaignContent.HEAVIES.find(str(e.kind))*4+phase,frame),p,direction,1.,tint)
		elif bool(e.mini) and catalogue.DATA.data.atlases.has("mini-bosses"):
			var phase: int=3 if bool(e.defeated) else (1 if float(e.windup)>0. else (2 if float(e.get("flash",0.))>0. else 0))
			var row: int=["current_guard","terrace_guard","drill_guard"].find(str(e.get("mini_role","current_guard")))*4+phase
			draw_pose(catalogue.pose("mini-bosses",row,frame),p,direction,1.,tint)
		elif str(e.kind) in ["drone","seed","warden"]:
			var row: int = {"drone":0,"seed":2,"warden":6}[str(e.kind)]+int(attack)
			draw_pose(art.pose(row,frame),p,direction,1.,tint)
		elif e.kind=="gnome": existing("enemies",4 if attack else 3,frame,p,direction,1.,tint)
		elif e.kind=="crow": existing("enemies",1 if attack else 0,frame,p,direction,1.,tint)
		else:
			var row: int = {"moth":0,"slime":1,"beetle":2,"wisp":3}.get(str(e.kind),0)
			existing("creatures",row,frame,p,direction,1.,tint)
		if attack:
			var point := at(p+Vector2(0,-70))
			draw_circle(point,5,Color("f7bb70")); caption("!",point+Vector2(-3,-10),20)
		if (bool(e.mini) or bool(e.get("heavy",false))) and not bool(e.defeated):small_health(at(p+Vector2(-35,-130)),70,float(e.hp)/float(e.max_hp))
	if bool(world.boss.active) or world.completed:
		var phase: int=2 if world.completed else clampi(int(world.boss.phase)-1,0,2)
		var row: int=phase*4+(3 if world.completed else (1 if float(world.boss.windup)>0. else (2 if float(world.boss.wait)>.8 else 0)))
		var frame: int=clampi(int(world.victory_time/1.2*6),0,5) if world.completed else posmod(int(float(world.boss.clock)*8),6)
		if not host.motion_enabled or host.options.reduced_motion:frame=3
		draw_pose(catalogue.pose("root-engine",row,frame),Vector2(float(world.boss.x),float(world.boss.y)))
		if not world.completed and not world.boss_vulnerable():
			var core:=at(Vector2(float(world.boss.x),float(world.boss.y)-75.))
			draw_arc(core,48.,0.,TAU,24,Color("efd58a"),3.);caption(host.t("shield"),core+Vector2(-28,-56),16)
		if float(world.boss.windup)>0.: caption(host.t("arc_boss_warning"),at(Vector2(float(world.boss.x)-130.,-215.)),19)
	if (bool(world.mount.available) and int(world.mount.hp)>0) or (int(world.mount.hp)<=0 and float(world.mount.get("wreck_age",9.))<.8 and world.floor_at(float(world.mount.x))==0.):
		var p: Vector2=vehicle_draw_position()
		var firing: bool=world.shot_flash>0. and bool(world.mount.ridden)
		var spec: Dictionary=world.vehicle_art_spec()
		var frame: int=int(spec.frame)
		var type: String=CampaignVehicles.kind(world)
		var phase: int=3 if int(world.mount.hp)<=0 else int(spec.phase)
		var machine: Dictionary=vehicle_pose(type,phase,frame)
		draw_pose(machine,p,vehicle_draw_facing(),float(machine.vehicle_growth))
		if bool(world.mount.ridden) and (absf(world.aim_direction.y)>.15 or world.aim_direction.x*world.facing<0.):draw_vehicle_barrel(machine,p)
		if bool(world.mount.ridden) and world.character=="sheep" and world.flock>1:
			draw_set_transform(at(p),0.,Vector2(vehicle_draw_facing(),1.))
			draw_rect(Rect2(-66,-30,59,5),Color("b89461"));draw_rect(Rect2(-66,-25,59,3),Color("634b3a"))
			draw_line(Vector2(-62,-22),Vector2(-35,-11),Color("9e8058"),4.)
			draw_set_transform(Vector2.ZERO)
	var pose: Dictionary = hero_pose(world.character,absf(world.velocity.x)>1.,not world.grounded(),world.walk_distance)
	var tint := Color.WHITE
	if world.invulnerable>0.: tint=Color("ffd9ca")
	if not bool(world.mount.ridden) and world.mount_transition.is_empty():
		draw_pose(pose,world.player,int(world.armed_art_spec().get("mirror",world.facing)),1.,tint)
	if not world.mount_transition.is_empty():
		draw_embark()
	elif not bool(world.mount.ridden) and world.state=="playing" and world.rescue_time<=0. and world.melee_time<=0. and world.weapon!="pistol":
		draw_special_weapon()
	hero_marker={"anchor":[world.player.x,world.player.y],"facing":world.facing,"source":pose.get("source_key","campaign-melee"),"row":pose.get("source_row",0),"frame":pose.get("source_frame",0),"floor":world.floor_at(world.player.x),"muzzle":[world.player.x+world.muzzle_offset().x,world.player.y+world.muzzle_offset().y]}
	if not bool(world.mount.ridden) and not bool(pose.get("gun_embedded",false)) and world.mount_transition.is_empty() and (not world.grounded() or world.charging or (world.character=="wolf" and world.boost_held)) and world.melee_time<=0. and world.rescue_time<=0.: held_gun(world.character,world.player,world.facing)
	if world.character=="sheep":
		for i in world.flock-1:
			if bool(world.mount.ridden):
				existing("runner-sheep",0,0,vehicle_draw_position()+Vector2(-vehicle_draw_facing()*(28.+i*24.),-30.),vehicle_draw_facing(),.55)
				continue
			var sample: Dictionary = {"p":world.player-Vector2((i+1)*52,0),"facing":world.facing}
			for old in world.trail:
				if float(old.time)<=world.time-float(i+1)*.27: sample=old
			var p: Vector2=sample.p
			existing("runner-sheep",2 if p.y<-.1 else 1,posmod(int(world.walk_distance/24.),frames.count("runner-sheep",1)),p,int(sample.facing),.67)
	if world.charging: small_health(at(world.player+Vector2(-28,-112)),56,world.charge_ratio())
	for b in world.bullets:
		var p := at(b.p)
		var color := Color(str(b.get("colour","e1f5e7"))) if b.owner=="hero" else Color("eeb079")
		if b.kind=="arc": color=Color("89dbec")
		if b.kind=="wave": draw_rect(Rect2(p-Vector2(20,9),Vector2(40,18)),color)
		elif b.kind=="beam":draw_line(p,p-Vector2(b.v).normalized()*140.,color,6.)
		elif b.kind=="disc":draw_arc(p,9.,world.time*8.,world.time*8.+PI*1.8,10,color,3.)
		elif b.kind=="trap":draw_rect(Rect2(p-Vector2(11,4),Vector2(22,8)),color);draw_circle(p-Vector2(0,6),3.,Color("ffe8b0"))
		else: draw_line(p,p-Vector2(b.v).normalized()*(25. if b.kind=="harpoon" else 12.),color,4.)
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

func draw_vehicle_barrel(machine: Dictionary,p: Vector2) -> void:
	# A real rotating attachment, with its tip shared by projectile physics.
	# The fixed hull nozzle stays a neutral intake, never a false forward flash.
	var gun: Dictionary=item_bank.pose("pistol")
	var width: float=machine.barrel_length
	var dimensions: Vector2=gun.size*(width/maxf(1.,float(gun.size.x)))
	var pivot: Vector2=p+Vector2(float(machine.pivot_local.x)*world.facing,float(machine.pivot_local.y))
	draw_set_transform(at(pivot),world.aim_direction.angle(),Vector2.ONE)
	draw_texture_rect(gun.texture,Rect2(Vector2(0.,-dimensions.y*.5),dimensions),false)
	draw_set_transform(Vector2.ZERO)

func draw_special_weapon() -> void:
	# A modular weapon attachment uses the same measured muzzle as hit physics.
	# These are twenty registered item drawings, not extra hero animation frames.
	var gun: Dictionary=item_bank.pose(world.weapon)
	var dimensions: Vector2=gun.size
	dimensions*=minf(1.,42./maxf(1.,dimensions.x))
	var muzzle: Vector2=at(world.player+world.armed_muzzle())
	var aim: Vector2=world.aim_direction.normalized()
	draw_set_transform(muzzle,aim.angle(),Vector2.ONE)
	draw_texture_rect(gun.texture,Rect2(Vector2(-dimensions.x,-dimensions.y*.5),dimensions),false)
	draw_set_transform(Vector2.ZERO)

func draw_embark() -> void:
	var progress: float=clampf(world.mount_transition_time/.45,0.,1.)
	if world.mount_transition=="exit":progress=1.-progress
	var frame: int=clampi(int(progress*6.),0,5)
	var pose: Dictionary=forge_art.embark(world.character,frame)
	var foot:=Vector2(float(world.mount.x),0.)
	# A deliberate climb into the roof hatch, not a physics offset to mask drift.
	var visual: Vector2=world.player+Vector2(0.,-sin(progress*PI)*hero_reference_height()*.75)
	if progress<.5:
		var approach: float=world.mount_transition_from.x if world.mount_transition=="enter" else world.mount_transition_to.x
		if absf(approach-foot.x)<hero_reference_height()*1.3:approach=foot.x-world.facing*hero_reference_height()*1.6
		visual.x=lerpf(approach,foot.x,progress*2.)
	if progress>.5:visual=foot+Vector2(0.,lerpf(-100.,-28.,inverse_lerp(.5,1.,progress)))
	draw_pose(pose,visual,world.facing)
	# Foreground lower hull occludes the legs/torso as they descend into the hatch.
	var spec: Dictionary=world.vehicle_art_spec()
	var machine: Dictionary=vehicle_pose(CampaignVehicles.kind(world),int(spec.phase),int(spec.frame))
	var growth: float=machine.vehicle_growth
	var dimensions: Vector2=machine.size*growth
	var offset: Vector2=Vector2(machine.offset)*growth
	var tex: Texture2D=machine.texture
	var cut: float=.35
	var top_left: Vector2=offset+Vector2(0.,dimensions.y*cut)
	if progress>=.25:
		draw_set_transform(at(foot),0.,Vector2(world.facing,1.))
		draw_texture_rect_region(tex,Rect2(top_left,Vector2(dimensions.x,dimensions.y*(1.-cut))),Rect2(0.,tex.get_height()*cut,tex.get_width(),tex.get_height()*(1.-cut)))
		draw_set_transform(Vector2.ZERO)

func caption(value: String,p: Vector2,size: int) -> void:
	if font!=null: draw_string(font,p,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color("fff2d4"))

func small_health(p: Vector2,width: float,ratio: float) -> void:
	draw_rect(Rect2(p,Vector2(width,7)),Color("332638"))
	draw_rect(Rect2(p+Vector2(1,1),Vector2((width-2.)*clampf(ratio,0,1),5)),Color("e9ba7e"))
