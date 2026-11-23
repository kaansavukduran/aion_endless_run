class_name CampaignGround
extends RefCounted

const VOID_HEIGHT := 1000.
const REVISION := 1
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
	"water":[Vector2(5020.,0.),Vector2(5520.,88.),Vector2(5840.,208.),
		Vector2(6100.,208.),Vector2(6350.,132.),Vector2(6600.,0.)],
	"terrace":[Vector2(7250.,0.),Vector2(7530.,-58.),Vector2(7810.,-58.),
		Vector2(8100.,-114.),Vector2(8340.,-114.),Vector2(8680.,0.)],
	"roots":[Vector2(7480.,0.),Vector2(7740.,76.),Vector2(7920.,76.),
		Vector2(8180.,-36.),Vector2(8400.,-36.),Vector2(8780.,0.)],
	"relay":[Vector2(3780.,0.),Vector2(4050.,-48.),Vector2(4230.,-48.),
		Vector2(4480.,22.),Vector2(4660.,22.),Vector2(4860.,-42.),Vector2(5120.,0.)]
}

static func height(section: String,x: float) -> float:
	var points: Array=PROFILES.get(section,[])
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
		if not CampaignContent.flying(str(enemy.kind)) and absf(float(enemy.y))<.01:
			var floor: float=w.floor_at(float(enemy.x))
			if has_floor(floor):enemy.y=floor;enemy.home=Vector2(float(enemy.x),floor)
	for list in [w.crates,w.objects]:
		for obj in list:
			if absf(float(obj.y))>.01:continue
			var floor: float=w.floor_at(float(obj.x))
			if has_floor(floor):obj.y=floor
	for item in w.pickups:
		if item.has("rescue_id") or float(item.y)<-56.:continue
		var floor: float=w.floor_at(float(item.x))
		if has_floor(floor):item.y=float(item.y)+floor

static func lift_flat_save(w) -> void:
	if not PROFILES.has(w.section):return
	align_world(w)
	for npc in w.npcs:
		if str(npc.get("secret","")).is_empty() and absf(float(npc.y))<.01:
			var floor: float=w.floor_at(float(npc.x))
			if has_floor(floor):npc.y=floor
	var support: float=w.floor_at(w.player.x)
	var saddle: float=42. if bool(w.mount.ridden) else 0.
	if has_floor(support) and (absf(w.player.y+saddle)<.1 or w.player.y+saddle>support):
		w.player.y=support-saddle
