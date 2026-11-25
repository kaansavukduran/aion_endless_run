class_name CampaignWeapons
extends RefCounted

const PISTOL_START := 36
const PISTOL_LIMIT := 72
const PISTOL_REFILL := 18
const ROCKET_RADIUS := 126.
const SPIDER_COUNT := 5
const SPIDER_SPACING := .30
const SPIDER_SPEED := 166.
const SPIDER_DISPLAY_TIME := 8.
const SHELL_BEETLES := ["shore:enemy:911","canopy:enemy:910","relay:enemy:911"]
const SHELL_RECOVERY := .86
const FIELD_REFILLS := {
	"shore":[.22,.48,.74,.93],"quay":[.15,.40,.63,.85],"canopy":[.23,.69],
	"causeway":[.21,.54,.88],"water":[.12,.30,.50,.69,.88],
	"terrace":[.13,.32,.52,.72,.90],"roots":[.13,.33,.53,.74,.92],"relay":[.14,.35,.57,.79,.94],
}

## Shots spend active stock. A stored sidearm keeps its own stock while a
## special is equipped. All ranged attacks use the existing fire action.
const SPECS := {
	"pistol":{"interval":.32,"ammo":PISTOL_START,"speed":760.,"damage":1,"life":1.3,"pierce":0,"colour":"fff2d4"},
	"heavy":{"interval":.10,"ammo":90,"speed":920.,"damage":1,"life":1.2,"pierce":0,"colour":"f2c66e"},
	"scatter":{"interval":.35,"ammo":30,"speed":980.,"damage":1,"life":1.15,"pierce":0,"colour":"f4dbad"},
	"arc":{"interval":.22,"ammo":36,"speed":900.,"damage":1,"life":1.1,"pierce":2,"colour":"85def2"},
	"beam":{"interval":.5,"ammo":18,"speed":1900.,"damage":2,"life":.5,"pierce":20,"colour":"f5ef9b"},
	"disc":{"interval":.48,"ammo":24,"speed":520.,"damage":1,"life":3.,"pierce":2,"colour":"e5aa83"},
	"harpoon":{"interval":.6,"ammo":20,"speed":1100.,"damage":2,"life":1.5,"pierce":4,"colour":"a2d8b1"},
	"seeker":{"interval":.65,"ammo":18,"speed":760.,"damage":1,"life":3.3,"pierce":0,"colour":"9ee8d5"},
	"spore":{"interval":.45,"ammo":24,"speed":520.,"damage":1,"life":1.4,"pierce":0,"colour":"d7a0e7"},
	"rocket":{"interval":.76,"ammo":6,"speed":735.,"damage":6,"life":1.9,"pierce":0,"colour":"ecac63"},
	"nova":{"interval":.8,"ammo":12,"speed":440.,"damage":3,"life":1.2,"pierce":0,"colour":"f69bac"}
}
const SPECIAL := ["heavy","scatter","arc","beam","disc","harpoon","seeker","spore","rocket","nova"]

static func canonical_kind(kind: String) -> String:
	return "rocket" if kind=="trap" else kind

static func migrate_stock(stock: Dictionary) -> void:
	var kind:=str(stock.get("weapon","pistol"))
	var old_format:=not stock.has("pistol_reserve")
	stock.weapon=canonical_kind(kind)
	if kind=="trap":stock.ammunition=mini(2*int(SPECS.rocket.ammo),ceili(float(stock.get("ammunition",0))*.5))
	if not old_format:return
	# Zero on an old pistol meant unlimited. A modern explicit zero stays empty.
	stock.pistol_reserve=0 if kind=="pistol" else PISTOL_START
	if kind=="pistol" and int(stock.get("ammunition",0))==0:stock.ammunition=PISTOL_START

static func has_rounds(w) -> bool:
	return bool(w.mount.ridden) or w.ammunition>0

static func melee_environment(w) -> void:
	# An empty sidearm must still be able to reach a physical supply or open an
	# ordinary breakable gate. Damage is applied only on the shared punch cel.
	var glove: Vector2=w.player+Vector2(44.*float(w.facing),-23. if w.crouching() else -34.)
	for crate in w.crates:
		var centre:=Vector2(float(crate.x),float(crate.y)-24.)
		if int(crate.hp)>0 and centre.distance_squared_to(glove)<30.*30.:
			w.open_crate(crate)
			return
	CampaignContent.hit_object(w,glove,1)

static func sidearm_stock(w) -> int:
	return int(w.ammunition) if w.weapon=="pistol" else int(w.pistol_reserve)

static func grant_sidearm(w,amount: int) -> void:
	var stock:=mini(PISTOL_LIMIT,sidearm_stock(w)+maxi(0,amount))
	if w.weapon=="pistol":w.ammunition=stock
	else:w.pistol_reserve=stock

static func populate_sidearm(w) -> void:
	var placement: Array=FIELD_REFILLS.get(w.section,[])
	for index in placement.size():
		var id: String=w.section+":pistol-stock:"+str(index)
		if w.taken.has(id) or w.pickups.any(func(item):return str(item.id)==id):continue
		var centre: float=float(w.length())*float(placement[index])
		for offset in [0.,-95.,95.,-175.,175.]:
			var x:=clampf(centre+offset,200.,w.length()-260.)
			var y: float=w.floor_at(x)
			var p:=Vector2(x,y-32.)
			if not CampaignGround.has_floor(y) or CampaignRoutes.solid_at(w,p):continue
			if w.gates.any(func(gate):return absf(float(gate.x)-x)<74.):continue
			if w.hazards.any(func(hazard):return absf(float(hazard.x)-x)<74.):continue
			w.pickups.append({"id":id,"kind":"pistol_ammo","x":p.x,"y":p.y})
			break

static func switch_to_sidearm(w) -> void:
	if w.weapon=="pistol":return
	w.weapon="pistol";w.ammunition=w.pistol_reserve;w.pistol_reserve=0

static func equip(w,kind: String) -> void:
	if kind not in SPECIAL:return
	var stock: int=SPECS[kind].ammo
	if w.weapon=="pistol":w.pistol_reserve=w.ammunition
	w.ammunition=mini(stock*2,w.ammunition+stock) if w.weapon==kind else stock
	w.weapon=kind
	if not w.weapons_used.has(kind):w.weapons_used.append(kind)

static func fire(w) -> bool:
	if not has_rounds(w):return false
	var riding: bool=bool(w.mount.ridden)
	if not riding and not w.weapons_used.has(w.weapon):w.weapons_used.append(w.weapon)
	w.last_shot_mounted=riding
	w.shot_weapon=w.weapon
	w.shot_flash=.18 # Use the actual firing-pose muzzle, including the first shot.
	var spec: Dictionary=SPECS.get(w.weapon,SPECS.pistol)
	if riding:
		spec={"interval":.13,"speed":920.,"damage":1,"life":1.35,"pierce":0,"colour":"b4eee6"}
		match CampaignVehicles.kind(w):
			"drill":spec.merge({"interval":.16,"speed":790.,"pierce":2,"colour":"d2b4ec"},true)
			"shell":spec.merge({"interval":.15,"pierce":1,"colour":"9ce8e5"},true)
	var angles: Array=[-.17,0.,.17] if w.weapon=="scatter" else ([-.4,-.2,0.,.2,.4] if w.weapon=="spore" else [0.])
	if w.weapon=="seeker":angles=[-.15,0.,.15]
	if riding:angles=[0.]
	var aim: Vector2=Vector2(w.aim_direction)
	if aim.length_squared()<.01:aim=Vector2(w.facing,0.)
	aim=aim.normalized()
	if not riding:aim=Vector2(M1CombatArt.placement(w).aim)
	var offset: Vector2=w.armed_muzzle()
	var origin: Vector2=w.player+offset
	# Authored downward keyposes already place their muzzle above the floor.
	# Only a genuinely buried muzzle is clamped, never an arbitrary aim guess.
	var floor: float=w.floor_at(origin.x)
	if origin.y>=floor:origin.y=floor-.5

	var eligible: Array=[]
	if not riding and w.weapon=="seeker":
		eligible=w.enemies.filter(func(e):return not bool(e.defeated) and not CampaignEnemies.hidden(e) and absf(float(e.x)-w.player.x)<900.)
		eligible.sort_custom(func(a,b):return absf(float(a.x)-w.player.x)<absf(float(b.x)-w.player.x))
	var index:=0
	for angle in angles:
		var target: String=""
		if not eligible.is_empty():target=str(eligible[mini(index,eligible.size()-1)].id)
		var b: Dictionary={"p":origin,"v":aim.rotated(angle)*float(spec.speed),"owner":"hero","age":0.,"kind":"vehicle" if riding else w.weapon,"damage":int(spec.damage)+int(float(w.buffs.get("power",0.))>0.),"pierce":int(spec.pierce),"hit":[],"life":float(spec.life),"colour":str(spec.colour),"target":target,"bounces":0}
		b.start=origin if b.kind=="rocket" else origin-aim*(maxf(32.,absf(offset.x)) if absf(aim.y)<.15 else 32.)
		if riding:b.hit_radius=12.
		b.aim=aim
		w.bullets.append(b);index+=1
	w.shots+=1
	w.fire_time=float(spec.interval)
	w.pending_events.append("shot:"+CampaignVehicles.kind(w) if riding else "shot:"+str(w.shot_weapon))
	if not riding:
		w.ammunition-=1
		if w.ammunition<=0:switch_to_sidearm(w)
	return true

static func blast(w,p: Vector2,radius: float,damage: int,colour: String,kind: String="",affect_boss: bool=true) -> void:
	w.blasts.append({"p":p,"age":0.,"radius":radius,"color":colour,"kind":kind})
	for e in w.enemies:
		if not bool(e.defeated) and p.distance_to(Vector2(float(e.x),float(e.y)-30.))<radius:w.damage_enemy(e,damage)
	if affect_boss and bool(w.boss.active) and p.distance_to(Vector2(float(w.boss.x),float(w.boss.y)-70.))<radius+35.:w.damage_boss(damage)
	CampaignRescue.blast_ropes(w,p,radius)
	w.pending_events.append("rocket_impact" if kind=="rocket" else "blast")

static func rocket_impact(w,b: Dictionary,point: Vector2,affect_boss: bool=true) -> bool:
	if b.kind!="rocket" or b.owner!="hero" or float(b.age)>=99.:return false
	b.age=99.
	blast(w,point,ROCKET_RADIUS,int(b.damage),str(b.colour),"rocket",affect_boss)
	return true

static func rocket_contact(w,from: Vector2,to: Vector2) -> Vector2:
	# Unlike a last-frame endpoint test, this also detects a thin plank or an
	# obstacle passed completely within a slow frame. Sample only active rockets.
	var count:=maxi(1,ceili(from.distance_to(to)/7.))
	for i in range(1,count+1):
		var point:=from.lerp(to,float(i)/float(count))
		if CampaignRoutes.solid_at(w,point):return point
		var floor: float=w.floor_at(point.x,point.y)
		if CampaignGround.has_floor(floor) and point.y>=floor:return Vector2(point.x,floor)
		for surface in w.platforms:
			if surface.has_point(point) and not w.disabled_platforms.has(surface.position.x):return point
	return Vector2.INF

static func shell_beetle(e: Dictionary) -> bool:
	return e.kind=="beetle" and str(e.id) in SHELL_BEETLES

static func step_shell(e: Dictionary,dt: float) -> void:
	if not shell_beetle(e):return
	if float(e.get("dash",0.))>0.:e.shell_recover=SHELL_RECOVERY
	else:e.shell_recover=maxf(0.,float(e.get("shell_recover",0.))-dt)

static func shell_open(e: Dictionary) -> bool:
	return shell_beetle(e) and float(e.get("dash",0.))<=0. and float(e.get("shell_recover",0.))>0.

static func beetle_facing(e: Dictionary,toward: int) -> int:
	if shell_beetle(e) and (float(e.get("dash",0.))>0. or shell_open(e)):
		var side:=int(e.get("dash_direction",0))
		if side!=0:return side
	return toward

static func beetle_blocks(w,e: Dictionary,b: Dictionary,point: Vector2) -> bool:
	if not shell_beetle(e) or shell_open(e) or float(b.v.x)*int(e.facing)>=-20.:return false
	w.blasts.append({"p":point,"age":0.,"life":.19,"radius":13.,"color":"eed19a","kind":"armour_chip"})
	w.pending_events.append("armour_hit")
	return true

static func step(w,b: Dictionary,dt: float) -> bool:
	if b.kind=="seeker" and b.owner=="hero":
		for e in w.enemies:
			if str(e.id)==str(b.get("target","")) and not bool(e.defeated):
				var desired: Vector2=(Vector2(float(e.x),float(e.y)-30.)-Vector2(b.p)).normalized()*float(SPECS.seeker.speed)
				b.v=Vector2(b.v).lerp(desired,minf(1.,dt*5.));break
	if b.kind=="disc":
		var floor: float=w.floor_at(float(b.p.x),float(b.p.y))
		if (CampaignGround.has_floor(floor) and float(b.p.y)>floor-8.) or float(b.p.x)<20. or float(b.p.x)>w.length()-20.:
			if int(b.bounces)>=2:b.age=99.;return true
			b.bounces=int(b.bounces)+1;b.v=Vector2(-float(b.v.x),-absf(float(b.v.y))-90.);b.p.y=minf(floor-10.,float(b.p.y));b.hit=[]
	if b.kind=="nova" and float(b.age)>=float(b.life)-dt:
		blast(w,b.p,170.,int(b.damage),str(b.colour));b.age=99.;return true
	return false

static func start_spider_parade(w,item: Dictionary) -> void:
	if w.spider_parade.has("started") or not item.has("x"):return
	var x: float=float(item.x)-46.
	var y: float=w.floor_at(x)
	if not CampaignGround.has_floor(y):return
	w.spider_parade={"origin":Vector2(x,y),"started":w.time}

static func step_spider_parade(w) -> void:
	if w.spider_parade.has("started") or w.time<float(w.spider_parade.get("scan_after",0.)):return
	w.spider_parade.scan_after=w.time+.15
	# A crate and its eventual pickup share the location. Observation precedes
	# auto-collect and deliberate swaps, so even a player passing by sees it.
	for sources in [w.crates,w.pickups]:
		for item in sources:
			if item.kind=="rocket" and not w.taken.has(str(item.id)) and absf(float(item.x)-w.player.x)<420. and absf(float(item.y)-w.player.y)<145.:
				if item.has("secret") and not w.discovered.has(str(item.secret)):continue
				start_spider_parade(w,item)
				if w.spider_parade.has("started"):return

static func spider_position(w,index: int) -> Vector2:
	if not w.spider_parade.has("started"):return Vector2.INF
	var elapsed: float=w.time-float(w.spider_parade.started)-float(index)*SPIDER_SPACING
	if elapsed<0. or elapsed>=SPIDER_DISPLAY_TIME:return Vector2.INF
	var origin: Vector2=w.spider_parade.origin
	var x:=origin.x+elapsed*SPIDER_SPEED
	if x>=w.length():return Vector2.INF
	var y: float=w.floor_at(x)
	return Vector2(x,y) if CampaignGround.has_floor(y) else Vector2.INF

static func spider_snapshot(w) -> Array:
	var spiders: Array=[]
	if not w.spider_parade.has("started"):return spiders
	for index in SPIDER_COUNT:
		var p:=spider_position(w,index)
		if p.is_finite():
			var age: float=w.time-float(w.spider_parade.started)-float(index)*SPIDER_SPACING
			spiders.append({"p":[p.x,p.y],"age":age,"ambient":true})
	return spiders

static func draw_spider_parade(v) -> void:
	var w=v.world
	if not w.spider_parade.has("started"):return
	var animated: bool=v.host.motion_enabled and not v.host.options.reduced_motion
	for index in SPIDER_COUNT:
		var p:=spider_position(w,index)
		if not p.is_finite() or p.x<v.camera_x-60. or p.x>v.camera_x+v.scene_w+60.:continue
		var frame:=posmod(int((w.time-float(w.spider_parade.started))*12.)+index,6) if animated else 0
		v.draw_pose(v.support_art.pose("spider-walk",frame),p,1)
