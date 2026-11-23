class_name CampaignRhythm
extends RefCounted

## Authored role combinations with seeded spacing variants. All decisions
## remain physical play; no wave timers spawn threats behind the camera.
const SHORE_BRIDGE := [Rect2(5800.,-40.,310.,20.),Rect2(6110.,-40.,360.,20.)]

static func crate_kind(section: String,index: int) -> String:
	var stock: Dictionary={
		"shore":["heavy","grenade","shield","heal","arc","points","grenade","heavy","heal"],
		"quay":["scatter","repair","grenade","shield","scatter","seeker","heal","grenade","heavy","repair","points"],
		"water":["arc","shield","grenade","harpoon","heal","repair","spore","points"],
		"terrace":["seeker","shield","grenade","disc","heal","repair","heavy","points"],
		"roots":["trap","shield","grenade","nova","heal","repair","beam","points"]}
	var options: Array=stock.get(section,["heavy","grenade","heal","beam","shield","points"])
	return str(options[posmod(index,options.size())])

static func populate(w) -> void:
	if CampaignRoutes.is_fork(w.section) or w.section=="arena":return
	for i in w.crates.size():w.crates[i].kind=crate_kind(w.section,i)
	for i in w.enemies.size():
		var enemy: Dictionary=w.enemies[i]
		if enemy.kind=="seed":
			enemy.shot_lane="high" if i%2==0 else "low"
			if w.section in ["shore","quay"] and i%2==0:
				var x: float=float(enemy.x)
				if CampaignGround.has_floor(w.floor_at(x)):
					w.platforms.append(Rect2(x-55.,-70.,110.,20.));enemy.y=-70.;enemy.home=Vector2(x,-70.)
	# Optional fruit arcs teach the existing jump/platform routes. Ground
	# fruit still supports a direct route; these are distinct one-time IDs.
	for surface in w.platforms:
		if surface.position.x>2100.:break
		for j in 3:
			var id: String=w.section+":skill-fruit:"+str(int(surface.position.x))+":"+str(j)
			if not w.taken.has(id):w.pickups.append({"id":id,"kind":"fruit_"+str((j+3)%8),"x":surface.position.x+25.+j*45.,"y":surface.position.y-42.})
	if w.section!="shore":return
	# This crossing is required on every route. Both decks stay in place.
	w.platforms=w.platforms.filter(func(p):return p.end.x<5800. or p.position.x>6470.)
	w.pits.append(Vector2(5840.,6440.))
	w.platforms.append_array(SHORE_BRIDGE)
	for enemy in w.enemies:
		if not CampaignContent.flying(str(enemy.kind)) and float(enemy.x)>5780. and float(enemy.x)<6490.:
			enemy.x=6500.+posmod(int(enemy.home.x),3)*65.;enemy.y=0.;enemy.home=Vector2(enemy.x,0.)
	for item in w.pickups:
		if float(item.x)>5840. and float(item.x)<6440.:item.y=-82.
	for crate in w.crates:
		if float(crate.x)>5780. and float(crate.x)<6490.:crate.x=6530.
	for i in 4:
		var id: String="shore:bridge-fruit:"+str(i)
		if not w.taken.has(id):w.pickups.append({"id":id,"kind":"fruit_"+str(i),"x":5860.+i*150.,"y":-100.})

static func restore_shore_bridge(w) -> void:
	if w.section!="shore":return
	var had_collapse_state:=false
	for deck in SHORE_BRIDGE:
		had_collapse_state=w.bridge_timers.erase(deck.position.x) or had_collapse_state
		had_collapse_state=w.disabled_platforms.erase(deck.position.x) or had_collapse_state
		w.platform_timers.erase(deck.position.x)
	# A legacy save taken during a fall may already be below the restored deck.
	if not had_collapse_state or w.state!="playing" or CampaignGround.has_floor(w.floor_at(w.player.x)):return
	var foot:=CampaignRoutes.foot(w)
	for deck in SHORE_BRIDGE:
		if foot.x>=deck.position.x and foot.x<=deck.end.x and foot.y>deck.position.y:
			w.player.y+=deck.position.y-foot.y
			w.velocity.y=0.;w.drop_through_time=0.
			return

static func can_auto_collect(w,item: Dictionary) -> bool:
	var kind: String=str(item.kind)
	return kind not in CampaignWeapons.SPECIAL or w.weapon=="pistol" or w.weapon==kind or bool(w.mount.ridden)

static func offer(w) -> Dictionary:
	if bool(w.mount.ridden) or w.mount_transition!="":return {}
	var nearest: Dictionary={};var distance:=INF
	for item in w.pickups:
		if str(item.kind) not in CampaignWeapons.SPECIAL or w.taken.has(str(item.id)) or can_auto_collect(w,item):continue
		if item.has("secret") and not w.discovered.has(str(item.secret)):continue
		if item.has("rescue_id") and float(item.get("age",0.))<.25:continue
		if not w.touches_pickup(item):continue
		var d: float=w.player_hit_center().distance_to(Vector2(float(item.x),float(item.y)))
		if d<distance:distance=d;nearest=item
	return nearest

static func lane_shot(w,e: Dictionary) -> bool:
	if not e.has("shot_lane"):return false
	var origin:=Vector2(float(e.x),float(e.y)-32.)
	var target: Vector2=w.player+Vector2(0.,-56. if str(e.shot_lane)=="high" else -12.)
	var direction: Vector2=(target-origin).normalized()
	w.bullets.append({"p":origin,"v":direction*210.,"owner":"enemy","age":0.,"kind":"seed","damage":1,"pierce":0,"hit":[]})
	return true
