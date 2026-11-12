class_name RunnerOrchard
extends RefCounted

const KINDS := ["banana","apple","pear","apricot","grapes","orange","cherries","peach"]
var wait_distance := 280.0
var last_kind := "apple"
var bag: Array[String] = []
var sequence := 0

func reset() -> void:
	wait_distance=280.0
	last_kind="apple"
	bag.clear()
	sequence=0

# Only ground-level ribbons: every hero can collect them without flying or
# crossing a carrier's upper collision shapes. Reject actual dangerous geometry.
func safe(world, x: float, y: float) -> bool:
	if y < -68 or y > -24:return false
	for obstacle in world.obstacles:
		var kind: String=obstacle.kind
		if kind=="gate" or kind.begins_with("arch") or kind.begins_with("carrier"):continue
		var margin: float=float(obstacle.get("width",150))*.5+110 if kind.begins_with("pit") else 135.0
		if absf(x-float(obstacle.x))<margin:return false
	for enemy in world.adventure.enemies:
		if int(enemy.hp)>0 and not world.adventure.flying(str(enemy.kind)) and absf(x-float(enemy.x))<110:return false
	for plant in world.frontier.plants:
		if absf(x-float(plant.x))<140:return false
	return true

func next_kind(world) -> String:
	if bag.is_empty():
		bag.assign(KINDS)
		# Use the run RNG, never global random state or a nondeterministic shuffle.
		for i in range(bag.size()-1,0,-1):
			var j: int=world.rng.randi_range(0,i)
			var swap: String=bag[i];bag[i]=bag[j];bag[j]=swap
	return bag.pop_back()

func step(world, movement: float) -> void:
	# Future encounters may enter a previously empty ribbon; revalidate before
	# rendering/collecting, rather than leaving bait inside a newly spawned hazard.
	world.pickups=world.pickups.filter(func(p):return not p.get("orchard",false) or safe(world,float(p.x),float(p.y)))
	wait_distance-=movement
	if wait_distance>0:return
	wait_distance=world.rng.randf_range(650.0,1050.0)
	var count: int=world.rng.randi_range(3,5)
	var x0: float=world.field_width+100
	for i in count:
		var x: float=x0+i*68.0
		var y: float=-32.0-8.0*sin(float(i)*PI/maxf(1,count-1))
		if not safe(world,x,y):continue
		sequence+=1
		world.pickups.append({"id":sequence,"kind":next_kind(world),"x":x,"y":y,"taken":false,"orchard":true})
