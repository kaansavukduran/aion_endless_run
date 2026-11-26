class_name CampaignGround
extends RefCounted

const VOID_HEIGHT := 1000.
const REVISION := 3
const ARENA_WALKWAYS := [Rect2(1840.,-55.,130.,20.),Rect2(2020.,-125.,160.,20.)]
const RELAY_WALKWAYS := [Rect2(4214.,-102.,145.,18.),Rect2(4385.,-132.,120.,18.),
	Rect2(4530.,-145.,175.,18.),Rect2(4745.,-88.,185.,18.)]
const RELAY_AMMO := "relay:roof:ammo"
const RELAY_FRUIT := {"relay:arc-fruit:1:0":Vector2(4430.,-170.),
	"relay:arc-fruit:1:1":Vector2(4666.,-183.),"relay:arc-fruit:1:2":Vector2(4540.,58.)}
const BRANCH_WALKWAYS := {
	"water":[Rect2(5350.,38.,190.,18.),Rect2(5590.,12.,220.,18.),Rect2(5860.,32.,220.,18.),
		Rect2(6130.,62.,180.,18.),Rect2(6360.,20.,150.,18.)],
	"terrace":[Rect2(7490.,-117.,190.,18.),Rect2(7730.,-175.,200.,18.),
		Rect2(7980.,-199.,210.,18.),Rect2(8240.,-165.,180.,18.)],
	"roots":[Rect2(7460.,-54.,190.,18.),Rect2(7700.,-96.,195.,18.),
		Rect2(7940.,-125.,190.,18.),Rect2(8170.,-82.,155.,18.)],
}
const BRANCH_ZONES := {
	"terrace":{"id":"terrace:garden-draft","kind":"updraft","x":7490.,"width":390.,"ceiling":-255.},
	"roots":{"id":"roots:hollow-shade","kind":"dark","x":7740.,"width":410.,"ground_only":true},
}
const BRANCH_SUPPLIES := {
	"water":{"id":"water:basin:points","x":6005.,"y":176.,"kind":"points"},
	"terrace":{"id":"terrace:roof:grenade","x":8070.,"y":-231.,"kind":"grenade"},
	"roots":{"id":"roots:hollow:ammo","x":7830.,"y":44.,"kind":"pistol_ammo"},
}
const OLD_RELAY := [Vector2(3780.,0.),Vector2(4050.,-48.),Vector2(4230.,-48.),
	Vector2(4480.,22.),Vector2(4660.,22.),Vector2(4860.,-42.),Vector2(5120.,0.)]
# Heights are foot coordinates in the existing Godot world, increasing down.
# This section lowers the approach under the lantern bridge, then rises to
# an exposed firing shelf. The original one-way decks remain higher routes.
const PROFILES := {
	"shore":[Vector2(2780.,0.),Vector2(3040.,56.),Vector2(3230.,56.),
		Vector2(3500.,-58.),Vector2(3670.,-58.),Vector2(3920.,24.),
		Vector2(4010.,24.),Vector2(4180.,0.)],
	"quay":[Vector2(3720.,0.),Vector2(4010.,-62.),Vector2(4260.,-62.),
		Vector2(4560.,38.),Vector2(4790.,38.),Vector2(5110.,0.)],
	"canopy":[Vector2(1840.,0.),Vector2(2080.,-56.),Vector2(2280.,-56.),
		Vector2(2460.,-96.),Vector2(2660.,-96.),Vector2(2970.,0.)],
	"causeway":[Vector2(625.,0.),Vector2(800.,70.),Vector2(1000.,70.),
		Vector2(1260.,-20.),Vector2(1410.,-20.),Vector2(1610.,0.),
		Vector2(2100.,0.),Vector2(2250.,-54.),Vector2(2480.,-54.),
		Vector2(2600.,-16.),Vector2(2840.,50.),Vector2(3000.,50.),Vector2(3250.,0.)],
	"water":[Vector2(5020.,0.),Vector2(5520.,88.),Vector2(5840.,208.),
		Vector2(6100.,208.),Vector2(6350.,132.),Vector2(6600.,0.)],
	"terrace":[Vector2(7250.,0.),Vector2(7530.,-58.),Vector2(7810.,-58.),
		Vector2(8100.,-114.),Vector2(8340.,-114.),Vector2(8680.,0.)],
	"roots":[Vector2(7480.,0.),Vector2(7740.,76.),Vector2(7920.,76.),
		Vector2(8180.,-36.),Vector2(8400.,-36.),Vector2(8780.,0.)],
	"relay":[Vector2(3780.,0.),Vector2(4050.,-48.),Vector2(4230.,-48.),
		Vector2(4480.,96.),Vector2(4660.,96.),Vector2(4860.,-42.),Vector2(5120.,0.)],
	"arena":[Vector2(1520.,0.),Vector2(1700.,26.),Vector2(1850.,26.),
		Vector2(2040.,-40.),Vector2(2200.,-40.),Vector2(2370.,0.),
		Vector2(2580.,0.),Vector2(2710.,-26.),Vector2(2850.,-26.),Vector2(2980.,0.)]
}

static func height(section: String,x: float) -> float:
	return profile_height(PROFILES.get(section,[]),x)

static func profile_height(points: Array,x: float) -> float:
	if points.is_empty() or x<points.front().x or x>points.back().x:return 0.
	for i in range(1,points.size()):
		var a: Vector2=points[i-1]
		var b: Vector2=points[i]
		if x<=b.x:return lerpf(a.y,b.y,inverse_lerp(a.x,b.x,x))
	return 0.

static func has_floor(value: float) -> bool:
	return value<VOID_HEIGHT

static func fell_into_pit(w,point: Vector2) -> bool:
	if has_floor(w.floor_at(point.x,point.y)):return false
	var lip:=0.
	for pit in w.pits:
		if point.x>pit.x and point.x<pit.y:
			lip=maxf(w.floor_at(pit.x),w.floor_at(pit.y))
			break
	return point.y>lip+180.

static func normal(w,x: float) -> Vector2:
	var left: float=w.floor_at(x-3.)
	var right: float=w.floor_at(x+3.)
	if not has_floor(left) or not has_floor(right):return Vector2.UP
	return Vector2(right-left,-6.).normalized()

static func touches_ground(w,from: Vector2,to: Vector2) -> bool:
	# Keep the established flat-lane shot behavior outside authored profiles.
	# Within a profile, sample the full swept segment so a fast beam or pellet
	# cannot pass through the intervening raised shelf.
	var points: Array=PROFILES.get(w.section,[])
	if points.is_empty() or maxf(from.x,to.x)<points.front().x or minf(from.x,to.x)>points.back().x:return false
	var steps:=maxi(1,ceili(from.distance_to(to)/8.))
	for i in range(1,steps+1):
		var point:=from.lerp(to,float(i)/steps)
		var floor: float=w.floor_at(point.x,point.y)
		if has_floor(floor) and point.y>floor+.5:return true
	return false

static func align_world(w) -> void:
	if not PROFILES.has(w.section):return
	for enemy in w.enemies:
		var floor: float=w.floor_at(float(enemy.x))
		if not has_floor(floor):continue
		if CampaignContent.flying(str(enemy.kind)):
			enemy.y=float(enemy.y)+floor
			var home: Vector2=enemy.home
			enemy.home=Vector2(home.x,home.y+floor)
		elif absf(float(enemy.y))<.01:
			enemy.y=floor;enemy.home=Vector2(float(enemy.x),floor)
	# Lower existing walkways and their higher loot toward a deep basin.
	# Secret rooms and the shore's original failing bridge are outside it.
	for i in w.platforms.size():
		var deck: Rect2=w.platforms[i]
		if deck.position.y> -8. or CampaignRoutes.is_shelter(w.section,deck):continue
		var floor: float=w.floor_at(deck.get_center().x)
		if has_floor(floor) and floor>45.:
			deck.position.y+=floor*.60
			w.platforms[i]=deck
	for list in [w.crates,w.objects]:
		for obj in list:
			if absf(float(obj.y))>.01:continue
			var floor: float=w.floor_at(float(obj.x))
			if has_floor(floor):obj.y=floor
	for item in w.pickups:
		if item.has("rescue_id") or item.has("secret"):continue
		var floor: float=w.floor_at(float(item.x))
		if not has_floor(floor):continue
		if float(item.y)>=-56.:item.y=float(item.y)+floor
		elif floor>45.:item.y=float(item.y)+floor*.60

static func lift_flat_save(w) -> void:
	if not PROFILES.has(w.section):return
	align_world(w)
	for npc in w.npcs:
		if str(npc.get("secret","")).is_empty() and absf(float(npc.y))<.01:
			var floor: float=w.floor_at(float(npc.x))
			if has_floor(floor):npc.y=floor
	for item in w.pickups:
		if not item.has("rescue_id") or float(item.y)<-72.:continue
		var floor: float=w.floor_at(float(item.x))
		if has_floor(floor):
			item.y=float(item.y)+floor
			if w.gift_drops.has(str(item.rescue_id)):w.gift_drops[str(item.rescue_id)].y=item.y
	var support: float=w.floor_at(w.player.x)
	var saddle: float=42. if bool(w.mount.ridden) else 0.
	if has_floor(support) and (absf(w.player.y+saddle)<.1 or w.player.y+saddle>support):
		w.player.y=support-saddle

static func restore_revision(w,revision: int) -> void:
	if revision<1 or (revision<2 and w.section=="arena"):lift_flat_save(w)
	if revision<2 and w.section=="arena":
		for deck in ARENA_WALKWAYS:
			if deck not in w.platforms:w.platforms.append(deck)
		w.boss.y=w.floor_at(float(w.boss.x))
	if revision>=REVISION:return
	if w.section=="relay" and revision>=1:migrate_relay_support(w)
	install_walkways(w)
	# Unclaimed legacy drops used an absolute Y. The saved object keeps their identity.
	for item in w.pickups:
		if item.kind!="points" or not str(item.id).ends_with(":gift"):continue
		for o in w.objects:
			if str(o.id)+":gift"==item.id and o.kind in ["surprise","planks","rock"]:
				item.y=float(o.y)-35.
				break

static func install_walkways(w) -> void:
	var decks: Array=RELAY_WALKWAYS if w.section=="relay" else BRANCH_WALKWAYS.get(w.section,[])
	if decks.is_empty():return
	for deck in decks:
		if deck not in w.platforms:w.platforms.append(deck)
	if w.section=="relay":
		for item in w.pickups:
			if RELAY_FRUIT.has(item.id):
				var point: Vector2=RELAY_FRUIT[item.id]
				item.x=point.x;item.y=point.y
	var supply: Dictionary={"id":RELAY_AMMO,"x":4608.,"y":-177.,"kind":"pistol_ammo"} if w.section=="relay" else BRANCH_SUPPLIES[w.section]
	CampaignRoutes.install_pickup(w,supply)
	var zone: Dictionary=BRANCH_ZONES.get(w.section,{})
	if not zone.is_empty() and not w.zones.any(func(existing):return existing.id==zone.id):
		w.zones.append(zone.duplicate())

static func descent_preview(w,desired_y: float,portrait: bool) -> float:
	if not portrait or (w.section!="relay" and not BRANCH_WALKWAYS.has(w.section)) or absf(w.velocity.x)<1. or not w.grounded():return desired_y
	var foot: Vector2=CampaignRoutes.foot(w)
	var floor: float=w.floor_at(foot.x)
	if absf(foot.y-floor)>.1:return desired_y
	var ahead: float=w.floor_at(foot.x+signf(w.velocity.x)*110.)
	if has_floor(ahead) and ahead>floor+10.:return maxf(desired_y,maxf(0.,ahead)*.68)
	return desired_y

static func migrate_relay_support(w) -> void:
	var foot: Vector2=CampaignRoutes.foot(w)
	var old_floor:=profile_height(OLD_RELAY,foot.x)
	var new_floor: float=w.floor_at(foot.x)
	if has_floor(new_floor) and (absf(foot.y-old_floor)<.1 or foot.y>new_floor):
		w.player.y+=new_floor-foot.y
	for actors in [w.enemies,w.npcs,w.crates,w.objects]:
		for actor in actors:
			var x:=float(actor.x)
			var floor: float=w.floor_at(x)
			if has_floor(floor) and absf(float(actor.y)-profile_height(OLD_RELAY,x))<.1:actor.y=floor
	for item in w.pickups:
		var x:=float(item.x)
		var old_support:=profile_height(OLD_RELAY,x)
		var floor: float=w.floor_at(x)
		if has_floor(floor) and float(item.y)>=old_support-56.:item.y=float(item.y)+floor-old_support
	if w.mount.has("floor_y"):
		var x:=float(w.mount.x)
		if absf(float(w.mount.floor_y)-profile_height(OLD_RELAY,x))<.1:w.mount.floor_y=w.floor_at(x)
