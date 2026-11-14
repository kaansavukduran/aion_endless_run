class_name CampaignWeapons
extends RefCounted

## All ten special weapons use the existing fire action. No reload mechanic.
const SPECS := {
	"pistol":{"interval":.32,"ammo":0,"speed":760.,"damage":1,"life":1.3,"pierce":0,"colour":"fff2d4"},
	"heavy":{"interval":.10,"ammo":90,"speed":920.,"damage":1,"life":1.2,"pierce":0,"colour":"f2c66e"},
	"scatter":{"interval":.35,"ammo":30,"speed":680.,"damage":1,"life":.65,"pierce":0,"colour":"f4dbad"},
	"arc":{"interval":.22,"ammo":36,"speed":900.,"damage":1,"life":1.1,"pierce":2,"colour":"85def2"},
	"beam":{"interval":.5,"ammo":18,"speed":1900.,"damage":2,"life":.5,"pierce":20,"colour":"f5ef9b"},
	"disc":{"interval":.48,"ammo":24,"speed":520.,"damage":1,"life":3.,"pierce":2,"colour":"e5aa83"},
	"harpoon":{"interval":.6,"ammo":20,"speed":1100.,"damage":2,"life":1.5,"pierce":4,"colour":"a2d8b1"},
	"seeker":{"interval":.65,"ammo":18,"speed":460.,"damage":1,"life":2.5,"pierce":0,"colour":"9ee8d5"},
	"spore":{"interval":.45,"ammo":24,"speed":260.,"damage":1,"life":.85,"pierce":0,"colour":"d7a0e7"},
	"trap":{"interval":.65,"ammo":12,"speed":120.,"damage":3,"life":6.,"pierce":0,"colour":"f3bc73"},
	"nova":{"interval":.8,"ammo":12,"speed":440.,"damage":3,"life":1.2,"pierce":0,"colour":"f69bac"}
}
const SPECIAL := ["heavy","scatter","arc","beam","disc","harpoon","seeker","spore","trap","nova"]

static func fire(w) -> void:
	if not bool(w.mount.ridden) and not w.weapons_used.has(w.weapon):w.weapons_used.append(w.weapon)
	w.shot_flash=.18 # Use the actual firing-pose muzzle, including the first shot.
	var spec: Dictionary=SPECS.get(w.weapon,SPECS.pistol)
	var riding: bool=bool(w.mount.ridden)
	if riding:spec={"interval":.18,"ammo":0,"speed":780.,"damage":1,"life":1.3,"pierce":0,"colour":"b4eee6"}
	if riding and CampaignVehicles.kind(w)=="drill":spec={"interval":.28,"ammo":0,"speed":420.,"damage":2,"life":.4,"pierce":5,"colour":"d2b4ec"}
	elif riding and CampaignVehicles.kind(w)=="shell":spec={"interval":.25,"ammo":0,"speed":600.,"damage":1,"life":1.5,"pierce":1,"colour":"9ce8e5"}
	var angles: Array=[-.17,0.,.17] if w.weapon=="scatter" else ([-.4,-.2,0.,.2,.4] if w.weapon=="spore" else [0.])
	if w.weapon=="seeker":angles=[-.15,0.,.15]
	if riding:angles=[-.2,0.,.2] if CampaignVehicles.kind(w)=="wind" else [0.]
	var aim: Vector2=Vector2(w.aim_direction)
	if aim.length_squared()<.01:aim=Vector2(w.facing,0.)
	aim=aim.normalized()
	var offset: Vector2=w.armed_muzzle()
	var origin: Vector2=w.player+offset
	# Authored downward keyposes already place their muzzle above the floor.
	# Only a genuinely buried muzzle is clamped, never an arbitrary aim guess.
	var floor: float=w.floor_at(origin.x)
	if origin.y>=floor:origin.y=floor-.5

	var index:=0
	for angle in angles:
		var target: String=""
		var eligible: Array=w.enemies.filter(func(e):return not bool(e.defeated) and absf(float(e.x)-w.player.x)<900.)
		eligible.sort_custom(func(a,b):return absf(float(a.x)-w.player.x)<absf(float(b.x)-w.player.x))
		if w.weapon=="seeker" and not eligible.is_empty():target=str(eligible[mini(index,eligible.size()-1)].id)
		var b: Dictionary={"p":origin,"v":aim.rotated(angle)*float(spec.speed),"owner":"hero","age":0.,"kind":"vehicle" if riding else w.weapon,"damage":int(spec.damage)+int(riding)+int(float(w.buffs.get("power",0.))>0.),"pierce":int(spec.pierce),"hit":[],"life":float(spec.life),"colour":str(spec.colour),"target":target,"bounces":0}
		b.start=origin-aim*(maxf(32.,absf(offset.x)) if absf(aim.y)<.15 else 32.)
		if w.weapon=="trap":b.gravity=550.
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
	if bool(w.boss.active) and p.distance_to(Vector2(float(w.boss.x),-70.))<radius+35.:w.damage_boss(damage)
	w.pending_events.append("blast")

static func step(w,b: Dictionary,dt: float) -> bool:
	if b.kind=="seeker" and b.owner=="hero":
		for e in w.enemies:
			if str(e.id)==str(b.get("target","")) and not bool(e.defeated):
				var desired: Vector2=(Vector2(float(e.x),float(e.y)-30.)-Vector2(b.p)).normalized()*460.
				b.v=Vector2(b.v).lerp(desired,minf(1.,dt*5.));break
	if b.kind=="disc":
		if float(b.p.y)>-8. or float(b.p.x)<20. or float(b.p.x)>w.length()-20.:
			if int(b.bounces)>=2:b.age=99.;return true
			b.bounces=int(b.bounces)+1;b.v=Vector2(-float(b.v.x),-absf(float(b.v.y))-90.);b.p.y=minf(-10.,float(b.p.y));b.hit=[]
	if b.kind=="trap":
		if float(b.p.y)>-8.:b.p.y=-8.;b.v=Vector2.ZERO;b.gravity=0.
		var boss_near: bool=bool(w.boss.active) and bool(w.boss.get("engaged",false)) and Vector2(b.p).distance_to(Vector2(float(w.boss.x),-30.))<110.
		if boss_near or w.enemies.any(func(e):return not bool(e.defeated) and Vector2(b.p).distance_to(Vector2(float(e.x),float(e.y)-20.))<65.):
			blast(w,b.p,130.,int(b.damage),str(b.colour));b.age=99.;return true
	if b.kind=="nova" and float(b.age)>=float(b.life)-dt:
		blast(w,b.p,170.,int(b.damage),str(b.colour));b.age=99.;return true
	return false
