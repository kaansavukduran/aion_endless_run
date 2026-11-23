class_name CampaignWeapons
extends RefCounted

## All ten special weapons use the existing fire action. No reload mechanic.
const SPECS := {
	"pistol":{"interval":.32,"ammo":0,"speed":760.,"damage":1,"life":1.3,"pierce":0,"colour":"fff2d4"},
	"heavy":{"interval":.10,"ammo":90,"speed":920.,"damage":1,"life":1.2,"pierce":0,"colour":"f2c66e"},
	"scatter":{"interval":.35,"ammo":30,"speed":980.,"damage":1,"life":1.15,"pierce":0,"colour":"f4dbad"},
	"arc":{"interval":.22,"ammo":36,"speed":900.,"damage":1,"life":1.1,"pierce":2,"colour":"85def2"},
	"beam":{"interval":.5,"ammo":18,"speed":1900.,"damage":2,"life":.5,"pierce":20,"colour":"f5ef9b"},
	"disc":{"interval":.48,"ammo":24,"speed":520.,"damage":1,"life":3.,"pierce":2,"colour":"e5aa83"},
	"harpoon":{"interval":.6,"ammo":20,"speed":1100.,"damage":2,"life":1.5,"pierce":4,"colour":"a2d8b1"},
	"seeker":{"interval":.65,"ammo":18,"speed":760.,"damage":1,"life":3.3,"pierce":0,"colour":"9ee8d5"},
	"spore":{"interval":.45,"ammo":24,"speed":520.,"damage":1,"life":1.4,"pierce":0,"colour":"d7a0e7"},
	"trap":{"interval":.65,"ammo":12,"speed":120.,"damage":3,"life":5.,"pierce":0,"colour":"f3bc73"},
	"nova":{"interval":.8,"ammo":12,"speed":440.,"damage":3,"life":1.2,"pierce":0,"colour":"f69bac"}
}
const SPECIAL := ["heavy","scatter","arc","beam","disc","harpoon","seeker","spore","trap","nova"]

static func fire(w) -> void:
	var riding: bool=bool(w.mount.ridden)
	if not riding and not w.weapons_used.has(w.weapon):w.weapons_used.append(w.weapon)
	w.last_shot_mounted=riding
	w.shot_weapon=w.weapon
	w.shot_flash=.18 # Use the actual firing-pose muzzle, including the first shot.
	var spec: Dictionary=SPECS.get(w.weapon,SPECS.pistol)
	if riding:spec={"interval":.18,"ammo":0,"speed":780.,"damage":1,"life":1.3,"pierce":0,"colour":"b4eee6"}
	if riding and CampaignVehicles.kind(w)=="drill":spec={"interval":.28,"ammo":0,"speed":420.,"damage":2,"life":.4,"pierce":5,"colour":"d2b4ec"}
	elif riding and CampaignVehicles.kind(w)=="shell":spec={"interval":.25,"ammo":0,"speed":600.,"damage":1,"life":1.5,"pierce":1,"colour":"9ce8e5"}
	var angles: Array=[-.17,0.,.17] if w.weapon=="scatter" else ([-.4,-.2,0.,.2,.4] if w.weapon=="spore" else [0.])
	if w.weapon=="seeker":angles=[-.15,0.,.15]
	if riding:angles=[-.2,0.,.2] if CampaignVehicles.kind(w)=="wind" else [0.,-.30,.30]
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
		var b: Dictionary={"p":origin,"v":aim.rotated(angle)*float(spec.speed),"owner":"hero","age":0.,"kind":"vehicle" if riding else w.weapon,"damage":int(spec.damage)+int(riding)+int(float(w.buffs.get("power",0.))>0.),"pierce":int(spec.pierce),"hit":[],"life":float(spec.life),"colour":str(spec.colour),"target":target,"bounces":0}
		b.start=origin-aim*(maxf(32.,absf(offset.x)) if absf(aim.y)<.15 else 32.)
		if w.weapon=="trap" and not riding:b.gravity=550.;b.spider=true;b.walking=false;b.facing=w.facing
		if riding:b.hit_radius=12.
		b.aim=aim
		w.bullets.append(b);index+=1
	w.shots+=1;w.fire_time=float(spec.interval);w.shot_flash=.18;w.pending_events.append("shot")
	if w.weapon!="pistol" and not riding:
		w.ammunition-=1
		if w.ammunition<=0:w.weapon="pistol";w.ammunition=0

static func blast(w,p: Vector2,radius: float,damage: int,colour: String) -> void:
	w.blasts.append({"p":p,"age":0.,"radius":radius,"color":colour})
	for e in w.enemies:
		if not bool(e.defeated) and p.distance_to(Vector2(float(e.x),float(e.y)-30.))<radius:w.damage_enemy(e,damage)
	if bool(w.boss.active) and p.distance_to(Vector2(float(w.boss.x),float(w.boss.y)-70.))<radius+35.:w.damage_boss(damage)
	CampaignRescue.blast_ropes(w,p,radius)
	w.pending_events.append("blast")

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
	if b.kind=="trap" and b.owner=="hero":
		step_spider(w,b,dt)
		return true # Spider owns age, movement, ground contact and detonation.
	if b.kind=="nova" and float(b.age)>=float(b.life)-dt:
		blast(w,b.p,170.,int(b.damage),str(b.colour));b.age=99.;return true
	return false

## A deployed mine is an actual walking seeker, not a permanent floor trap.
## Its five-second fuse includes flight/landing, so unreachable targets cannot
## leave immortal mines behind. Existing blast damage/armour rules are reused.
static func step_spider(w,b: Dictionary,dt: float) -> void:
	b.age=float(b.age)+dt
	var old: Vector2=b.p
	if not bool(b.get("walking",false)):
		b.v=Vector2(b.v)+Vector2(0.,550.*dt);b.p=Vector2(b.p)+Vector2(b.v)*dt
		var support: float=w.crossing_floor(float(b.p.x),old.y+8.,float(b.p.y)+8.,float(b.v.y))
		if CampaignGround.has_floor(support) and float(b.p.y)+8.>=support and float(b.v.y)>=0.:
			b.p.y=support-8.;b.v=Vector2.ZERO;b.gravity=0.;b.walking=true
	var target:=Vector2.ZERO
	var target_id:=""
	var distance:=INF
	for e in w.enemies:
		if bool(e.defeated) or CampaignEnemies.hidden(e):continue
		var p:=Vector2(float(e.x),float(e.y)-20.)
		var d: float=Vector2(b.p).distance_squared_to(p)
		if d<distance:distance=d;target=p;target_id=str(e.id)
	if bool(w.boss.active) and bool(w.boss.get("engaged",false)):
		var p:=Vector2(float(w.boss.x),float(w.boss.y)-45.)
		var d: float=Vector2(b.p).distance_squared_to(p)
		if d<distance:distance=d;target=p;target_id="boss"
	# When no enemy is nearby, a captive is a meaningful spider destination.
	for n in w.npcs:
		if bool(n.freed) or (str(n.secret)!="" and not w.discovered.has(str(n.secret))):continue
		var p:=Vector2(float(n.x),float(n.y)-45.)
		var d: float=Vector2(b.p).distance_squared_to(p)
		if d<distance:distance=d;target=p;target_id="rope:"+str(n.id)
	b.target=target_id
	if bool(b.get("walking",false)):
		b.v=Vector2.ZERO
		if not target_id.is_empty():
			var direction: float=signf(target.x-float(b.p.x))
			if direction!=0.:b.facing=int(direction)
			var next: float=float(b.p.x)+direction*210.*dt
			var support: float=w.crossing_floor(next,float(b.p.y)+8.,float(b.p.y)+24.,1.)
			if CampaignGround.has_floor(support) and absf(support-(float(b.p.y)+8.))<24.:
				b.p=Vector2(clampf(next,12.,w.length()-12.),support-8.);b.v.x=direction*210.
	if (not target_id.is_empty() and Vector2(b.p).distance_to(target)<65.) or float(b.age)>=5.-.000001:
		var blast_index: int=w.blasts.size()
		blast(w,b.p,145.,int(b.damage),str(b.colour))
		w.blasts[blast_index].kind="spider";b.age=99.
