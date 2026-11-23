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
var qa_pose_bounds: Dictionary = {}
var npc_growth_cache: Dictionary = {}
var item_bank := ForgeItemBank.new()
var vehicle_art := ForgeVehicleArt.new()
var forge_art := ForgeHeroArt.new()
var support_art := M1SupportArt.new()
var projectile_art := CampaignProjectileArt.new()
var effects_art := CampaignEffectsArt.new()
var m1_heroes := M1HeroArt.new()

# World facing (-1 = left) must be relative to each source drawing.
# Original drone/seed machine rows face right; other enemy sheets face left.
static func enemy_draw_direction(kind: String, facing: int) -> int:
	var source_facing: int=1 if kind in ["drone","seed"] else -1
	return source_facing*(-1 if facing<0 else 1)

static func npc_draw_direction(facing: int) -> int:
	# Freed walk/departure sources face left. World velocity never changes
	# to compensate for a sprite flip.
	return -1 if facing>0 else 1

func draw_flag(position: Vector2,growth: float=1.) -> void:
	var frame: int=posmod(int(world.time*5.),4) if host.motion_enabled and not host.options.reduced_motion else 0
	draw_pose(effects_art.flag(frame),position,1,growth)

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
	return Vector2(float(world.mount.x),world.player.y+42. if bool(world.mount.ridden) and world.mount_transition!="enter" else float(world.mount.get("floor_y",world.floor_at(float(world.mount.x)))))

func vehicle_draw_facing() -> int:
	return world.facing if bool(world.mount.ridden) or not world.mount_transition.is_empty() else int(world.mount.get("facing",1))

func existing(key: String,row: int,frame: int,p: Vector2,direction: int=1,growth: float=1.,tint: Color=Color.WHITE) -> void:
	draw_pose(frames.pose(key,row,clampi(frame,0,frames.count(key,row)-1)),p,direction,growth,tint)

func hero_pose(hero: String, moving: bool, airborne: bool, clock: float) -> Dictionary:
	if M1HeroArt.has(hero):
		var s: Dictionary=M1CombatArt.body_spec(world)
		return m1_heroes.pose(hero,str(s.action),int(s.frame))
	return frames.pose("gun-run",frames.hero_row(hero),0)

func follower_render_spec(index: int) -> Dictionary:
	# Feet on an elevated walkway are grounded too. Sample the actual recorded
	# support/crouch/stride instead of treating every negative Y as a jump.
	if bool(world.mount.ridden):
		return {"pose":m1_heroes.pose("sheep","idle_fire",0),"p":vehicle_draw_position()+Vector2(-vehicle_draw_facing()*(28.+index*24.),-30.),"facing":vehicle_draw_facing(),"growth":.55,"action":"idle_fire","frame":0}
	var sample:=CampaignLives.follower_sample(world,index)
	var action: String="idle_fire"
	var frame:=0
	var travel: float=float(sample.get("walk_distance",world.walk_distance))
	if not bool(sample.get("grounded",true)):
		action="air_fire";frame=RunnerWorld.flight_frame_for(float(sample.get("velocity_y",0.)),float(sample.get("air_time",0.)),6)
	elif bool(sample.get("crouched",false)):
		action="crouch_walk" if bool(sample.get("moving",false)) else "crouch_fire"
		if action=="crouch_walk":frame=posmod(int(travel/110.*6.),6)
	elif bool(sample.get("moving",false)):
		action="walk";frame=posmod(int(travel/174.*6.),6)
	if not host.motion_enabled or host.options.reduced_motion:frame=0
	return {"pose":m1_heroes.pose("sheep",action,frame),"p":Vector2(sample.p),"facing":int(sample.facing),"growth":.67,"action":action,"frame":frame}

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

func draw_boss_port(point: Vector2,hp: int) -> void:
	# Stepped bronze casing around a dark vent; lit slats track actual port HP.
	var edge:=PackedVector2Array([Vector2(-9,-14),Vector2(9,-14),Vector2(9,-10),Vector2(14,-10),Vector2(14,10),Vector2(9,10),Vector2(9,14),Vector2(-9,14),Vector2(-9,10),Vector2(-14,10),Vector2(-14,-10),Vector2(-9,-10)])
	var points:=PackedVector2Array()
	for p in edge:points.append(point+p)
	draw_colored_polygon(points,Color("342c2a"))
	draw_rect(Rect2(point-Vector2(9,12),Vector2(18,24)),Color("8b6946"))
	draw_rect(Rect2(point-Vector2(7,10),Vector2(14,20)),Color("393b2d"))
	draw_rect(Rect2(point-Vector2(9,12),Vector2(18,2)),Color("d0a86b"))
	for i in 3:
		draw_rect(Rect2(point+Vector2(-5,-8+i*6),Vector2(10,3)),Color("edbd72") if i<hp else Color("594631"))
	for side in [-1.,1.]:draw_rect(Rect2(point+Vector2(side*11.-1.,-1.),Vector2(2,2)),Color("bc9d68"))

func draw_world() -> void:
	terrain.draw_campaign_bank(self,world.biome(),world,camera_x)
	# Ground props share the exact collision groundline. They are decorative,
	# never platforms or invisible obstacles.
	for i in range(floori(camera_x/390.)-1,ceili((camera_x+scene_w)/390.)+1):
		var x: float = i*390.+160.
		var floor: float=world.floor_at(x)
		if not CampaignGround.has_floor(floor):continue
		existing("flora",world.biome(),0 if host.options.reduced_motion or not host.motion_enabled else posmod(int(world.time/.7)+i,3),Vector2(x,floor),1,.74)
	if not CampaignRoutes.draw_floor(self):terrain.draw_campaign_floor(self,world.biome(),world,camera_x)
	CampaignEnvironmentView.draw(self)
	for pit in world.pits:
		if pit.y<camera_x or pit.x>camera_x+scene_w:continue
		var left:=at(Vector2(pit.x,world.floor_at(pit.x)))
		var right:=at(Vector2(pit.y,world.floor_at(pit.y)))
		draw_colored_polygon(PackedVector2Array([left,right,Vector2(right.x,scene_h),Vector2(left.x,scene_h)]),Color("131d26"))
		for side in [left-Vector2(8.,0.),right]:
			for y in range(0,120,12):
				draw_rect(Rect2(side+Vector2(0.,y),Vector2(8.,9.)),Color("536345"))
	for platform in world.platforms:
		if platform.end.x<camera_x-50. or platform.position.x>camera_x+scene_w+50.:continue
		if world.disabled_platforms.has(platform.position.x):continue
		CampaignTimberArt.walkway(self,platform)
		if world.section=="arena" and platform.position.x==2020. and int(world.boss.phase)==2 and int(world.boss.attack)%3==1 and float(world.boss.windup)>0.:
			for x in range(6,int(platform.size.x),14):
				draw_rect(Rect2(at(platform.position+Vector2(x,0.)),Vector2(7.,3.)),Color("ffb36b"))
		if world.bridge_timers.has(platform.position.x) and float(world.bridge_timers[platform.position.x])<1.4:
			draw_rect(Rect2(at(platform.position),Vector2(platform.size.x,3)),Color("e8a36c"))
	for x in CampaignRecovery.points(world):
		if x<camera_x-80. or x>camera_x+scene_w+80.:continue
		draw_flag(Vector2(x,world.floor_at(x)),.55)
	CampaignRoutes.draw_landmarks(self)
	for gate in world.gates:
		if float(gate.x)<camera_x-100. or float(gate.x)>camera_x+scene_w+100.:continue
		if not world.gate_closed(gate): continue
		var p := at(Vector2(float(gate.x),world.floor_at(float(gate.x))))
		draw_rect(Rect2(p-Vector2(6,155),Vector2(12,155)),Color("44445f"))
		for y in range(8,151,18): draw_rect(Rect2(p-Vector2(3,y),Vector2(6,9)),Color("f2bf77"))
		var blockers: Array=world.enemies.filter(func(e):return str(e.id) in gate.ids and not bool(e.defeated))
		caption(host.t("gate_remaining")%blockers.size(),p+Vector2(-100,-168),14)
		if absf(world.player.x-float(gate.x))<180.:
			blockers.sort_custom(func(a,b):return absf(float(a.x)-world.player.x)<absf(float(b.x)-world.player.x))
			for enemy in blockers.slice(0,3):
				var target: Vector2=at(Vector2(float(enemy.x),float(enemy.y)-75.))
				var arrow: String="◀" if target.x<16. else ("▶" if target.x>scene_w-24. else "▼")
				target.x=clampf(target.x,16.,scene_w-24.);target.y=maxf(target.y,host.hud_panel.strip_height+55.)
				caption(arrow,target+Vector2(-5,0),16)
	draw_npcs(false)
	for crate in world.crates:
		if float(crate.x)<camera_x-80. or float(crate.x)>camera_x+scene_w+80.:continue
		if int(crate.hp)<=0: continue
		CampaignTimberArt.crate(self,Vector2(float(crate.x),float(crate.y)))
	for item in world.pickups:
		if float(item.x)<camera_x-80. or float(item.x)>camera_x+scene_w+80.:continue
		if world.taken.has(str(item.id)): continue
		if item.has("secret") and not world.discovered.has(str(item.secret)):continue
		var p := Vector2(float(item.x),float(item.y))
		if str(item.kind).begins_with("fruit_"):
			var fruit: int=int(str(item.kind).trim_prefix("fruit_"))%8
			existing("pickups",int(fruit/6),fruit%6,p)
		elif str(item.kind) in ["owl_feather","wolf_charm"]:
			draw_pose(support_art.pose(str(item.kind)),p)
		else:
			# Every actual special weapon/support has its own original silhouette.
			# This is a registered static drawing, not a fabricated animation count.
			var pickup_art: String={"heal":"grenade","repair":"grenade","shield":"power"}.get(str(item.kind),str(item.kind))
			draw_pose(item_bank.pose(pickup_art),p)
			if str(item.kind) in ["heal","repair"]:
				caption("+1" if item.kind=="heal" else "+2",at(p)+Vector2(-9.,-24.),14)
	for e in world.enemies:
		if float(e.x)<camera_x-210. or float(e.x)>camera_x+scene_w+210.:continue
		if bool(e.defeated) and float(e.get("dead_age",0.))>1.: continue
		var p := Vector2(float(e.x),float(e.y))
		if CampaignGroundShooters.has(str(e.kind)):
			CampaignGroundShooters.draw(self,e,p)
			continue
		var direction: int=enemy_draw_direction(str(e.kind),int(e.facing))
		if bool(e.defeated) and not bool(e.mini) and str(e.kind) in CampaignEffectsArt.LEGACY:
			var f: int=clampi(int(float(e.get("dead_age",0.))/.65*6.),0,5)
			if not host.motion_enabled or host.options.reduced_motion:f=5
			if CampaignContent.flying(str(e.kind)):
				var support: float=world.floor_at(p.x)
				if CampaignGround.has_floor(support):p.y=minf(support,p.y+float(CampaignEffectsArt.DATA.data.references[str(e.kind)].foot)+float(e.get("dead_age",0.))*float(e.get("dead_age",0.))*700.)
			else:
				p.y+=minf(0.,float(CampaignEffectsArt.DATA.data.references[str(e.kind)].foot)+float(e.get("dead_age",0.))*float(e.get("dead_age",0.))*700.)
			var source_facing: int=CampaignEffectsArt.DATA.data.references[str(e.kind)].facing
			draw_pose(effects_art.death(str(e.kind),f),p,source_facing*(-1 if int(e.facing)<0 else 1))
			continue
		var recovering: bool = float(e.get("recover",0.))>0. and CampaignEnemies.active_time(e)<=0.
		var tint := Color("cbd8e8") if recovering and not bool(e.defeated) else Color.WHITE
		var attack: bool = enemy_attacking(e)
		var frame: int = posmod(int(float(e.age)*9.),6)
		if bool(e.defeated):frame=clampi(int(float(e.get("dead_age",0.))/.65*6.),0,5)
		elif float(e.windup)>0.:frame=clampi(int((1.-float(e.windup)/(.85 if bool(e.mini) else .65))*3.),0,2)
		elif float(e.get("flash",0.))>0.:frame=clampi(3+int((.24-float(e.flash))/.24*3.),3,5)
		if CampaignContent.NEW_ENEMIES.has(str(e.kind)):
			var spec: Dictionary=CampaignContent.NEW_ENEMIES[str(e.kind)]
			var phase: int=3 if bool(e.defeated) else (1 if float(e.windup)>0. else (2 if attack and not recovering else 0))
			if CampaignEnemies.hidden(e):phase=1
			draw_pose(catalogue.pose(str(spec.atlas),int(spec.row)+phase,frame),p,direction,1.,tint)
		elif str(e.kind) in CampaignContent.HEAVIES and catalogue.DATA.data.atlases.has("heavy-machines"):
			var phase: int=3 if bool(e.defeated) else (1 if float(e.windup)>0. else (2 if attack and not recovering else 0))
			draw_pose(catalogue.pose("heavy-machines",CampaignContent.HEAVIES.find(str(e.kind))*4+phase,frame),p,direction,1.,tint)
		elif bool(e.mini) and catalogue.DATA.data.atlases.has("mini-bosses"):
			var phase: int=3 if bool(e.defeated) else (1 if float(e.windup)>0. else (2 if attack and not recovering else 0))
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
		if (bool(e.mini) or bool(e.get("heavy",false))) and not bool(e.defeated):small_health(at(p+Vector2(-35,-130)),70,float(e.hp)/float(e.max_hp))
	if bool(world.boss.active) or world.completed:
		var phase: int=2 if world.completed else clampi(int(world.boss.phase)-1,0,2)
		var row: int=phase*4+(3 if world.completed else (1 if float(world.boss.windup)>0. else (2 if float(world.boss.wait)>.8 else 0)))
		var frame: int=clampi(int(world.victory_time/1.2*6),0,5) if world.completed else posmod(int(float(world.boss.clock)*8),6)
		if not host.motion_enabled or host.options.reduced_motion:frame=3
		var pivot:=Vector2(float(world.boss.x),float(world.boss.y))
		var drawing: Dictionary=catalogue.pose("root-engine",row,frame)
		if not world.completed and not bool(world.boss.engaged):
			draw_root_reveal(drawing,pivot)
		else:
			draw_pose(drawing,pivot)
		if bool(world.boss.engaged) and not world.completed and not world.boss_vulnerable():
			var core:=at(Vector2(float(world.boss.x),float(world.boss.y)-75.))
			draw_arc(core,48.,0.,TAU,24,Color("efd58a"),3.);caption(host.t("shield"),core+Vector2(-28,-56),16)
		if bool(world.boss.engaged) and not world.completed and int(world.boss.phase)==1:
			for i in 2:
				if int(world.boss.get("ports",[3,3])[i])<=0:continue
				draw_boss_port(at(CampaignBossPressure.port_point(world,i)),int(world.boss.get("ports",[3,3])[i]))
		elif not world.completed and int(world.boss.phase)==2 and world.boss_vulnerable():
			var core: Vector2=at(pivot+Vector2(0.,-75.))
			for side in [-1.,1.]:
				draw_rect(Rect2(core+Vector2(side*23.-2.,-15.),Vector2(4,30)),Color("f1c681"))
				draw_rect(Rect2(core+Vector2(-15.,side*23.-2.),Vector2(30,4)),Color("f1c681"))
	if CampaignVehicles.stunned(world) or (bool(world.mount.available) and int(world.mount.hp)>0) or (int(world.mount.hp)<=0 and float(world.mount.get("wreck_age",9.))<.8 and CampaignGround.has_floor(float(world.mount.get("floor_y",world.floor_at(float(world.mount.x)))))):
		var p: Vector2=vehicle_draw_position()
		var spec: Dictionary=world.vehicle_art_spec()
		var frame: int=int(spec.frame)
		var type: String=CampaignVehicles.kind(world)
		var phase: int=2 if CampaignVehicles.stunned(world) else (3 if int(world.mount.hp)<=0 else int(spec.phase))
		var machine: Dictionary=vehicle_art.hull_pose(type,phase,frame,hero_reference_height()*2.) if bool(world.mount.ridden) else vehicle_pose(type,phase,frame)
		draw_pose(machine,p,vehicle_draw_facing(),float(machine.vehicle_growth))
		if CampaignVehicles.stunned(world):
			var spark: Vector2=at(p-Vector2(0.,70.))
			for offset in [Vector2(-22,-21),Vector2(16,-31),Vector2(30,4)]:
				draw_line(spark+offset*.7,spark+offset,Color("ffe0a2"),3.)
		elif bool(world.mount.ridden):draw_vehicle_barrel(machine,p)
		if bool(world.mount.ridden) and world.character=="sheep" and world.flock>1:
			draw_set_transform(at(p),0.,Vector2(vehicle_draw_facing(),1.))
			draw_rect(Rect2(-66,-30,59,5),Color("b89461"));draw_rect(Rect2(-66,-25,59,3),Color("634b3a"))
			draw_line(Vector2(-62,-22),Vector2(-35,-11),Color("9e8058"),4.)
			draw_set_transform(Vector2.ZERO)
	var pose: Dictionary = hero_pose(world.character,absf(world.velocity.x)>1.,not world.grounded(),world.walk_distance)
	var tint := Color.WHITE
	if world.invulnerable>0.: tint=Color("ffd9ca")
	if world.state=="respawn":
		var landing: Vector2=at(world.entry_to)
		draw_rect(Rect2(landing-Vector2(22.,3.),Vector2(44.,5.)),Color("211b2599"))
		draw_rect(Rect2(landing-Vector2(28.,1.),Vector2(56.,2.)),Color("e9ba7e"))
	if host.motion_enabled and not host.options.reduced_motion:
		MissionHeroArt.draw_shell_contacts(self)
	if not bool(world.mount.ridden) and world.mount_transition.is_empty():
		draw_pose(pose,world.player,int(M1CombatArt.body_spec(world).mirror),1.,tint)
	if not world.mount_transition.is_empty():
		draw_embark()
	elif not bool(world.mount.ridden) and world.state in ["playing","briefing","paused"]:
		draw_hero_weapon()
		CampaignGrenadeArt.draw_held(self)
	MissionHeroArt.draw_tongue(self)

	hero_marker={"anchor":[world.player.x,world.player.y],"facing":world.facing,"source":pose.get("source_key","campaign-melee"),"row":pose.get("source_row",0),"frame":pose.get("source_frame",0),"floor":world.floor_at(world.player.x),"muzzle":[world.player.x+world.muzzle_offset().x,world.player.y+world.muzzle_offset().y]}
	# Passive QA evidence follows the exact visible cel and drawing transform.
	# Texture alpha bounds are measured once per cel, only in explicit QA mode.
	if host.get("web_qa")==true:
		var selected: Dictionary=M1CombatArt.body_spec(world)
		hero_marker.world_time=world.time
		hero_marker.skill_phase_at_draw=str(world.hero_skill.get("phase",""))
		hero_marker.skill_clock_at_draw=float(world.hero_skill.get("clock",0.))
		hero_marker.grounded_at_draw=world.grounded()
		hero_marker.render_process_frame=Engine.get_process_frames()
		hero_marker.physics_velocity=[world.velocity.x,world.velocity.y]
		var drawn_anchor: Vector2=at(world.player)
		hero_marker.rendered_anchor=[drawn_anchor.x+camera_x,drawn_anchor.y-ground]
		hero_marker.body_action=str(selected.action)
		hero_marker.body_frame=int(selected.frame)
		hero_marker.body_mirror=int(selected.mirror)
		hero_marker.ground_contact=bool(pose.get("ground_contact",false))
		hero_marker.hand_layers_visible=world.state in ["playing","briefing","paused"] and not bool(world.mount.ridden) and world.mount_transition.is_empty()
		hero_marker.gun_visible=hero_marker.hand_layers_visible and hero_weapon_visible() and world.melee_time<=0. and world.rescue_time<=0.
		hero_marker.weapon_visible=hero_marker.gun_visible
		hero_marker.melee_at_draw=world.melee_time
		hero_marker.rescue_at_draw=world.rescue_time
		hero_marker.attack_mode_at_draw="hidden"
		if hero_marker.hand_layers_visible:
			hero_marker.attack_mode_at_draw="grenade" if not world.grenade_throw.is_empty() else ("rescue" if world.rescue_time>0. else ("melee" if world.melee_time>0. else ("gun" if hero_marker.gun_visible else "hidden")))
		var cache_key: String=str(pose.get("source_key",""))+":"+str(pose.get("source_row",0))+":"+str(pose.get("source_frame",0))
		if not qa_pose_bounds.has(cache_key):
			var pixels: Image=pose.texture.get_image()
			if pixels.is_compressed():pixels.decompress()
			qa_pose_bounds[cache_key]=pixels.get_used_rect()
		var used: Rect2i=qa_pose_bounds[cache_key]
		var factor: float=float(pose.get("scale",1.))
		var size: Vector2=pose.get("size",pose.texture.get_size()*factor)
		var local_origin: Vector2=(Vector2(pose.offset)*factor).round()
		hero_marker.visible_bottom_y=world.player.y+local_origin.y+float(used.end.y)*size.y/pose.texture.get_height()
		hero_marker.rendered_muzzle=null
		if hero_marker.weapon_visible:
			var gun: Dictionary=M1CombatArt.placement(world)
			var pixel: Vector2=gun.weapon.muzzle_pixel
			var barrel: Vector2=Vector2(gun.grip)+((Vector2(gun.weapon.offset)+pixel*float(gun.weapon.factor))*Vector2(1.,float(gun.mirror_y))).rotated(float(gun.angle))
			hero_marker.rendered_muzzle=[world.player.x+barrel.x,world.player.y+barrel.y]


	if world.character=="sheep":
		for i in world.flock-1:
			var follower: Dictionary=follower_render_spec(i)
			draw_pose(follower.pose,follower.p,int(follower.facing),float(follower.growth))
	if world.state=="dying":
		var key: String={"pit":"downed_pit","shot":"downed_shot","hazard":"downed_hazard","beam":"downed_hazard","explosion":"downed_hazard"}.get(world.death_cause,"downed_impact")
		var cause: String=host.t(key)
		var point: int=host.font_size(17)
		var text_width:=font.get_string_size(cause,HORIZONTAL_ALIGNMENT_LEFT,-1,point).x
		var pos:=at(world.player)+Vector2(-text_width*.5,-111.)
		pos.x=clampf(pos.x,22.,scene_w-text_width-22.)
		pos.y=clampf(pos.y,102.,ground+31.)
		draw_rect(Rect2(pos+Vector2(-8.,-point),Vector2(text_width+16.,point+10.)),Color("261f2a"))
		draw_string(font,pos,cause,HORIZONTAL_ALIGNMENT_LEFT,-1,point,Color("f3c893"))
	if world.charging: small_health(at(world.player+Vector2(-28,-112)),56,world.charge_ratio())
	draw_npcs(true) # Keep the thank-you and bag visible in front of a contacted hull.
	for b in world.bullets:
		var p := at(b.p)
		if b.kind=="lob_seed":
			draw_rect(Rect2(p-Vector2(5.,3.),Vector2(10.,6.)),Color("586644"))
			draw_rect(Rect2(p-Vector2(3.,5.),Vector2(6.,10.)),Color("cde295"))
			draw_rect(Rect2(p-Vector2(2.,3.),Vector2(4.,3.)),Color("fff0c2"))
			continue
		if b.kind=="scout_bolt":
			var tail:=p-Vector2(b.v).normalized()*22.
			draw_line(tail,p,Color("6c5039"),6.)
			draw_line(tail,p,Color("f5c986"),3.)
			draw_rect(Rect2(p-Vector2(3.,3.),Vector2(6.,6.)),Color("fff1bf"))
			continue
		var color := Color(str(b.get("colour","e1f5e7"))) if b.owner=="hero" else Color("eeb079")
		if b.kind=="arc": color=Color("89dbec")
		if b.kind=="wave":
			var crests: Array=[2,4,7,10,8,5,3,2]
			for i in crests.size():
				var h: float=crests[i]
				var at_x: float=p.x+(i-4)*5.*signf(float(b.v.x))
				draw_rect(Rect2(at_x,p.y-h,5.,h*2.),Color("352d49"))
				draw_rect(Rect2(at_x+1.,p.y-h+2.,3.,maxf(1.,h*2.-4.)),color)
				if h>4:draw_rect(Rect2(at_x+1.,p.y-h+2.,2.,2.),Color("fff1d6"))
		elif b.kind=="beam":
			var tail: Vector2=p-Vector2(b.v).normalized()*140.
			draw_line(p,tail,Color("352d49"),8.);draw_line(p,tail,color,5.);draw_line(p,tail,Color("fff6d9"),2.)
		elif b.kind=="trap":draw_pose(support_art.pose("spider-walk",int(world.time*12.)%6),Vector2(b.p)+Vector2(0,8),int(b.get("facing",-1 if float(b.v.x)<0. else 1)))
		else:
			var phase: int=posmod(int(float(b.age)*18.),2) if host.motion_enabled and not host.options.reduced_motion else 0
			var shot: Dictionary=projectile_art.pose(str(b.kind),str(b.get("colour","e1f5e7")),phase)
			draw_set_transform(p,Vector2(b.v).angle(),Vector2.ONE)
			draw_texture(shot.texture,shot.offset)
			draw_set_transform(Vector2.ZERO,0.,Vector2.ONE)
	for bomb in world.bombs:
		CampaignGrenadeArt.draw_bomb(self,bomb)
	for blast in world.blasts:
		if str(blast.get("kind",""))=="grenade":
			CampaignGrenadeArt.draw_blast(self,blast)
			continue
		var phase: float=float(blast.age)/.5
		if str(blast.get("kind",""))=="spider":draw_pose(support_art.pose("spider-burst",clampi(int(phase*6.),0,5)),Vector2(blast.p))
		var color := Color(str(blast.color));color.a=(1.-phase)*.8
		draw_arc(at(blast.p),float(blast.radius)*phase,0,TAU,24,color,6.)
		for i in 8: draw_rect(Rect2(at(blast.p)+Vector2.from_angle(i*TAU/8.)*float(blast.radius)*phase-Vector2(3,3),Vector2(6,6)),color)
	for popup in world.score_popups:
		caption(host.t("chain_bonus")%[int(popup.bonus),int(popup.chain)],at(Vector2(popup.p)-Vector2(0,float(popup.age)*24.)),13)
	draw_assists()
	draw_combat_cues()
	if world.section!="arena" and not CampaignRoutes.is_fork(world.section):
		var p := at(Vector2(world.length()-140.,0))
		draw_flag(Vector2(world.length()-140.,0))

func draw_root_reveal(drawing: Dictionary,pivot: Vector2) -> void:
	var entering: bool=host.presentation_stage=="boss_reveal"
	var progress: float=clampf(float(host.presentation_time)/1.25,0.,1.) if entering else 0.
	if entering and (host.options.reduced_motion or not host.motion_enabled):progress=1.
	var size: Vector2=drawing.size
	var offset: Vector2=drawing.offset
	var shown:=roundf(lerpf(64.,size.y,smoothstep(0.,1.,progress)))
	var source: Vector2=drawing.texture.get_size()
	var foot:=at(pivot)
	var tint:=Color("938987").lerp(Color.WHITE,progress)
	draw_texture_rect_region(drawing.texture,Rect2(foot+Vector2(offset.x,-shown),Vector2(size.x,shown)),Rect2(Vector2.ZERO,Vector2(source.x,source.y*shown/size.y)),tint)
	if entering:
		caption(host.t("arena"),Vector2(scene_w*.12,scene_h*.22),24)
		if not host.options.reduced_motion and host.motion_enabled:
			for i in 9:
				var root:=Vector2(pivot.x+(i-4)*25.,0.)
				root.y=world.floor_at(root.x)
				var dust:=at(root)+Vector2(signf(i-4)*progress*18.,-sin(progress*PI)*float(10+i%3*7))
				draw_rect(Rect2(dust,Vector2(4.+i%3*3.,4.)),Color(0.82,.65,.44,(1.-progress)*.82))

func enemy_attacking(e: Dictionary) -> bool:
	var recovering: bool=float(e.get("recover",0.))>0. and CampaignEnemies.active_time(e)<=0.
	return float(e.windup)>0. or (not recovering and (float(e.get("flash",0.))>0. or CampaignEnemies.active_time(e)>0. or float(e.get("dash",0.))>0. or float(e.get("dive",0.))>0.))

func draw_combat_cues() -> void:
	# Critical intent stays above smoke and impacts; FX never owns attack timing.
	if world.section=="arena" and float(world.boss.get("beam_warning",0.))>0.:
		var x: float=world.boss.beam_x
		var p: Vector2=at(Vector2(x,world.floor_at(x)))
		draw_rect(Rect2(p-Vector2(36,350),Vector2(72,350)),Color(1.,.7,.3,.18))
		draw_line(p-Vector2(0,330),p,Color("ebc37f"),3.)
	for e in world.enemies:
		if bool(e.defeated) or float(e.x)<camera_x-210. or float(e.x)>camera_x+scene_w+210.:continue
		var p:=Vector2(float(e.x),float(e.y))
		var attack: bool=enemy_attacking(e)
		if not bool(e.defeated) and bool(e.get("emerge_warn",false)):
			var gp := at(Vector2(float(e.x),0.))
			var r: float = 16. if host.options.reduced_motion else 12.+absf(sin(world.time*14.))*10.
			draw_arc(gp,r,PI,TAU,14,Color("e8a36c"),3.)
			caption("!",gp+Vector2(-3,-22),16)
		if not bool(e.defeated) and float(e.get("buff_pulse",0.))>0.:
			var pr: float = (1.-float(e.buff_pulse)/.5)*90.
			draw_arc(at(p+Vector2(0,-35)),maxf(14.,pr),0.,TAU,20,Color("f5d27a"),2.)
		if not bool(e.defeated) and str(e.kind)=="mirror" and float(e.windup)>0.:
			var mp := at(p+Vector2(int(e.facing)*20.,-34.))
			draw_arc(mp,24.,-PI*.45 if int(e.facing)>0 else PI*.55,PI*.45 if int(e.facing)>0 else PI*1.45,12,Color("9be5f5"),3.)
		if attack and not bool(e.defeated):
			var point := at(p+Vector2(0,-70))
			draw_circle(point,5,Color("f7bb70")); caption("!",point+Vector2(-3,-10),20)
			if e.has("shot_lane"):caption(host.t("high_lane" if str(e.shot_lane)=="high" else "low_lane"),point+Vector2(-14,-25),11)
	if bool(world.boss.active) and not world.completed:
		if not world.completed and float(world.boss.get("shift_pause",0.))>0.:
			var sc := at(Vector2(float(world.boss.x),float(world.boss.y)-80.))
			var sr: float = 72. if host.options.reduced_motion else 54.+(1.-float(world.boss.shift_pause)/.75)*58.
			draw_arc(sc,sr,0.,TAU,28,Color("ffcf8c"),4.)
		if not world.completed and float(world.boss.get("recover",0.))>0.:
			var rc := at(Vector2(float(world.boss.x),float(world.boss.y)-75.))
			draw_arc(rc,34.,0.,TAU,18,Color("9fe3c8"),3.)
		if float(world.boss.windup)>0.:
			var pattern:=int(world.boss.attack)%3
			if pattern==1 or (pattern==2 and int(world.boss.phase)==3):
				var dir: float=-1. if world.player.x<float(world.boss.x) else 1.
				var steps:=11 if pattern==1 else 17
				for step in range(2,steps):
					var x:=float(world.boss.x)+dir*float(step*22)
					var y:=world.floor_at(x)-7.
					draw_rect(Rect2(at(Vector2(x,y)),Vector2(10.,3.)),Color("f28c6b"))

func hero_weapon_visible() -> bool:
	# The authored throw includes release and follow-through with an open hand.
	# Re-equipping waits for the complete action, matching World's fire gate.
	return world.grenade_throw.is_empty() and not MissionHeroAbilities.compact(world)

func draw_hero_weapon() -> void:
	if not hero_weapon_visible():return
	var body := M1CombatArt.body_spec(world)
	if body.action=="melee":return # The fist/hoof is drawn in the actual cel.
	var transform: Dictionary=M1CombatArt.placement(world)
	var point: Vector2=world.player+Vector2(transform.grip)
	if body.action=="rescue_cut":
		var cut_angle: float=[-.24,-.52,-.1,.64,.38,0.][int(body.frame)]
		draw_set_transform(at(point),cut_angle*int(body.mirror),Vector2(int(body.mirror),1))
	else:
		draw_set_transform(at(point),float(transform.angle),Vector2(1,int(transform.mirror_y)))
	if world.rescue_time>0.:
		draw_rect(Rect2(-3,-2,6,5),Color("87583f"))
		draw_polygon(PackedVector2Array([Vector2(1,-2),Vector2(20,-2),Vector2(24,0),Vector2(1,2)]),PackedColorArray([Color("d7e9e8")]))
	elif world.melee_time>0.:
		draw_rect(Rect2(0,-4,9,8),Color("f5d0bd"));draw_rect(Rect2(6,-3,4,6),Color("d99791"))
	else:
		var weapon: Dictionary=transform.weapon
		draw_texture_rect(M1CombatArt.weapon_texture(item_bank,str(weapon.kind)),Rect2(Vector2(weapon.offset),Vector2(weapon.size)),false)
	draw_set_transform(Vector2.ZERO)
	if world.shot_flash>.09 and world.melee_time<=0. and world.rescue_time<=0.:
		var end: Vector2=at(world.player+Vector2(transform.muzzle))
		draw_rect(Rect2(end-Vector2(2,2),Vector2(4,4)),Color("fff0bf"))

func draw_assists() -> void:
	var animated: bool=host.motion_enabled and not host.options.reduced_motion
	for a in world.assists:
		if float(a.age)<18.:
			draw_pose(CampaignAssistArt.pose(a,animated),Vector2(float(a.x),float(a.y)),int(a.facing))
		for rock in a.stones:draw_pose(support_art.pose('owl_stone'),Vector2(float(rock.x),float(rock.y)))


func draw_vehicle_barrel(machine: Dictionary,p: Vector2) -> void:
	var spec: Dictionary=world.vehicle_art_spec()
	var type: String=CampaignVehicles.kind(world)
	var metrics: Dictionary=ForgeVehicleArt.aim_anchors(type,int(spec.phase),int(spec.frame),hero_reference_height()*2.)
	var turret: Dictionary=vehicle_art.turret_pose(type,int(spec.phase),int(spec.frame),hero_reference_height()*2.)
	if turret.is_empty():return
	var pivot: Vector2=p+Vector2(float(metrics.pivot_local.x)*world.facing,float(metrics.pivot_local.y))
	draw_set_transform(at(pivot),world.aim_direction.angle()+float(turret.get("rotation",0.)),Vector2.ONE)
	draw_texture_rect(turret.texture,Rect2(Vector2(turret.offset),Vector2(turret.size)),false)
	draw_set_transform(Vector2.ZERO)
	if CampaignVehicles.firing(world) and world.shot_flash>.1:
		var muzzle: Vector2=at(world.player+world.armed_muzzle())
		draw_circle(muzzle,3.,Color("fff0bf"))

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
	var pose: Dictionary=m1_heroes.pose(world.character,"air_fire" if progress<.5 else "crouch_fire",frame)
	var foot:=vehicle_draw_position()
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

func draw_npcs(mounted_front: bool) -> void:
	var cut_id: String=CampaignRescue.cut_target(world).get("id","") if not mounted_front else ""
	for npc in world.npcs:
		if float(npc.x)<camera_x-150. or float(npc.x)>camera_x+scene_w+150.:continue
		if str(npc.secret)!="" and not world.discovered.has(str(npc.secret)):continue
		var phase: String=str(npc.get("phase","free" if bool(npc.freed) else "bound"))
		if (bool(world.mount.ridden) and phase=="thanks")!=mounted_front:continue
		var age: float=float(npc.get("thank_age",0.))
		if phase=="departed" and age>4.8:continue
		var animated: bool=host.motion_enabled and not host.options.reduced_motion
		var frame: int=posmod(int(world.time*2.),2) if animated else 0
		if phase in ["free","departed"]:frame=6+posmod(int(world.time*6.),6 if int(npc.variant)==7 else 2) if animated else 6
		elif phase=="thanks":frame=2 if age<.45 else 3
		var npc_pose: Dictionary=catalogue.pose("rescue-npcs",int(npc.variant),frame)
		var growth: float=npc_growth(int(npc.variant))
		var npc_direction: int=npc_draw_direction(int(npc.get("facing",-1))) if phase!="bound" else 1
		draw_pose(npc_pose,Vector2(float(npc.x),float(npc.y)),npc_direction,growth)
		if phase=="thanks":
			var bag_at:=Vector2(float(npc.x)+float(npc.facing)*22.,float(npc.y)-52.)
			draw_pose(support_art.pose("satchel"),bag_at)
			if age>=.45 and age<.9:
				draw_pose(item_bank.pose(str(npc.gift)),bag_at+Vector2(float(npc.facing)*10.,-(age-.45)*80.),1,.6)
		var p := at(Vector2(float(npc.x),float(npc.y)))
		var label_top: float=maxf(46.,p.y+minf(-90.,float(npc_pose.offset.y)*growth-12.))
		if phase=="bound" and npc.id==cut_id and font!=null and p.x>=0. and p.x<=scene_w:
			var hint: String=host.t("cut")
			var width: float=font.get_string_size(hint,HORIZONTAL_ALIGNMENT_LEFT,-1,17).x
			var label_at:=Vector2(clampf(p.x-width*.5,12.,scene_w-width-12.),label_top)
			draw_rect(Rect2(label_at-Vector2(6.,17.),Vector2(width+12.,23.)),Color("312534"))
			caption(hint,label_at,17)
		elif phase=="thanks" and age<2.4:
			caption(host.t("thanks"),Vector2(clampf(p.x-48.,8.,scene_w-200.),label_top),17)
			if age>.9:caption(host.t(str(npc.gift)),Vector2(clampf(p.x-48.,8.,scene_w-200.),label_top+20.),16)
