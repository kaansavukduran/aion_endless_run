extends SceneTree

const DT := 1. / 120.

class TestHost:
	var motion_enabled := true
	var options := RunnerInterfaceOptions.new()

class CueView:
	var host := TestHost.new()
	var world: AionCampaignWorld
	var camera_x := 0.
	var scene_w := 3000.
	var marks: Array[Rect2] = []
	func draw_pose(_pose: Dictionary, _body: Vector2, _facing: int) -> void: pass
	func draw_rect(mark: Rect2, _ink: Color) -> void: marks.append(mark)
	func at(point: Vector2) -> Vector2: return point

var checks:=0
var failures:=0

func _initialize() -> void:call_deferred("run")

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL: "+label)

func stage(section: String) -> AionCampaignWorld:
	var w:=AionCampaignWorld.new()
	w.begin("aion")
	w.load_section(section)
	return w

func frames(w: AionCampaignWorld,ticks: int) -> void:
	for i in ticks:w.step(1./120.)

func find_grate(w: AionCampaignWorld) -> Dictionary:
	for object in w.objects:
		if object.id==CampaignContent.RELAY_GRATE:return object
	return {}

func lower_lane() -> void:
	var w:=stage("relay")
	var grate:=find_grate(w)
	check(not grate.is_empty() and grate.y==w.floor_at(grate.x) and not grate.active,"The lower grate is flush with the actual basin")
	check(not w.pickups.any(func(item):return item.id==CampaignContent.RELAY_GRATE_AMMO),"Unbroken grate conceals the cache")
	for cover: Rect2 in CampaignContent.RELAY_COVERS:
		var chest:=cover.get_center()
		var from:=Vector2(cover.position.x-15.,chest.y)
		var to:=Vector2(cover.end.x+15.,chest.y)
		check(CampaignContent.cover_contact(w,from,to).is_equal_approx(Vector2(cover.position.x,chest.y)),"Stone catches a swept shot even when both endpoints are outside")
		check(CampaignContent.cover_contact(w,to,from).is_equal_approx(Vector2(cover.end.x,chest.y)),"Stone protects the other side as well")
		check(not CampaignContent.cover_contact(w,from-Vector2(0.,30.),to-Vector2(0.,30.)).is_finite(),"Clear air above the stone remains shootable")
		w.bullets.assign([{"p":from,"v":(to-from)*30.,"owner":"enemy","age":0.,"kind":"seed","damage":1,"pierce":0,"hit":[]}])
		w.step_bullets(1./30.)
		check(w.bullets.is_empty(),"Actual enemy ballistics stop at the rendered stone")
	w.objects.erase(grate)
	var old:=w.snapshot()
	w.objects.append(grate)
	var restored:=AionCampaignWorld.new()
	check(restored.restore(JSON.parse_string(JSON.stringify(old))) and find_grate(restored).get("hp")==2,"An old exact Relay save acquires the optional grate")
	w.enemies.clear();w.gates.clear();w.hazards.clear()
	w.player=Vector2(float(grate.x)-44.,float(grate.y))
	w.velocity=Vector2.ZERO
	w.ammunition=0
	w.aim_direction=Vector2.RIGHT
	for attempt in 2:
		w.attack_press();frames(w,22);w.attack_release();frames(w,22)
		check(int(grate.hp)==1-attempt,"Empty-hand punch advances the copper break once")
	check(grate.active and w.activated.has(CampaignContent.RELAY_GRATE),"Opened grate is part of the normal campaign checkpoint")
	w.move_axis=Vector2.RIGHT;frames(w,36);w.move_axis=Vector2.ZERO
	check(w.ammunition==CampaignWeapons.PISTOL_REFILL and w.taken.has(CampaignContent.RELAY_GRATE_AMMO),"Walking into the exposed cache gives one pistol refill")
	check(restored.restore(JSON.parse_string(JSON.stringify(w.snapshot()))) and find_grate(restored).active,"Continue keeps the grate open")
	check(not restored.pickups.any(func(item):return item.id==CampaignContent.RELAY_GRATE_AMMO),"Continue cannot duplicate a claimed cache")

func roof_lane() -> void:
	var w:=stage("relay")
	var scout: Dictionary=w.enemies.filter(func(e):return e.id==CampaignContent.RELAY_SCOUT)[0]
	var drone: Dictionary=w.enemies.filter(func(e):return e.id==CampaignContent.RELAY_DRONE)[0]
	w.player=Vector2(4430.,-132.)
	scout.x=CampaignContent.RELAY_COVERS[1].position.x+CampaignGroundShooters.ROOF_PEEK_INSET
	scout.facing=-1
	scout.windup=.004
	scout.attacks=3
	scout.burst_pending=true
	drone.attacks=3
	check(CampaignContent.relay_opening_blocked(w,drone),"A later scout windup owns the shared firing lane")
	CampaignGroundShooters.step(w,scout,1./120.)
	for tick in 28:
		if w.bullets.size()>=2:break
		CampaignGroundShooters.step(w,scout,1./120.)
	check(w.bullets.size()==2 and float(scout.recover)>=.75,"Two real roof releases precede a readable full recovery")
	check(CampaignContent.relay_opening_blocked(w,drone),"Drone waits through the answering window")
	for tick in 124:
		if float(scout.recover)<=0.:break
		CampaignGroundShooters.step(w,scout,1./120.)
	check(not CampaignContent.relay_opening_blocked(w,drone),"The next turn becomes available after recovery")

func flow_and_respawn() -> void:
	var w:=stage("water")
	w.player=Vector2(6020.,w.floor_at(6020.));w.velocity=Vector2.ZERO
	CampaignContent.step(w,.05)
	check(w.player.x>=6023.,"Lower water floor gets the swift current")
	w.player=Vector2(6020.,32.)
	CampaignContent.step(w,.05)
	check(w.player.x==6020.,"Water current leaves the supported upper deck in place")
	check(not CampaignGround.garden_draft_active(.2) and CampaignGround.garden_draft_active(.8) and not CampaignGround.garden_draft_active(2.2),"Garden wind has a warning, lift and quiet beat")
	for starting in [0,3]:
		w=stage("shore");w.ammunition=starting;w.invulnerable=0.
		w.damage_player("shot")
		check(w.state=="dying" and w.ammunition==(6 if starting==0 else 3),"Reserve life carries only the emergency floor or the existing stock")
	w=stage("shore")
	CampaignWeapons.equip(w,"heavy");w.pistol_reserve=0;w.invulnerable=0.
	w.damage_player("shot")
	check(w.weapon=="pistol" and w.ammunition==0,"A spent sidearm with loaded special weapon follows the normal loss rule")
	w=stage("shore");w.ammunition=0;w.attempts_remaining=1;w.invulnerable=0.
	w.damage_player("shot")
	check(w.ammunition==0,"The final life does not mint a reserve refill")

func open_quay() -> void:
	var w:=stage("quay")
	check(w.gates.is_empty() and not w.objects.any(func(o):return o.kind=="gate"),"The Quay has no leftover scenery gate")
	var x:=7068.
	w.objects.append({"id":"quay:object:4","kind":"gate","x":x,"y":w.floor_at(x),"hp":2,"active":false,"secret":""})
	w.enemies.clear();w.hazards.clear()
	w.player=Vector2(x-80.,w.floor_at(x-80.))
	var restored:=AionCampaignWorld.new()
	check(restored.restore(w.snapshot()),"Earlier exact snapshot before the redundant gate can Continue")
	restored.move_axis=Vector2.RIGHT;frames(restored,100)
	check(restored.player.x>x+45.,"Normal walking can pass the old scenery gate after Continue")

func guard_only_relay() -> AionCampaignWorld:
	var w := AionCampaignWorld.new()
	w.begin("aion")
	w.load_section("relay")
	w.enemies.assign(w.enemies.filter(func(e): return e.id == CampaignContent.RELAY_SCOUT))
	return w

func wait_for_shot(w: AionCampaignWorld, limit: int = 730) -> bool:
	for tick in limit:
		w.step_enemies(DT)
		if not w.bullets.is_empty(): return true
	return false

func verify_peek() -> void:
	for side: int in [-1, 1]:
		var w := guard_only_relay()
		var scout: Dictionary = w.enemies[0]
		var authored_start := Vector2(float(scout.x), float(scout.y))
		var player_x := 4430. if side < 0 else 5060.
		w.player = Vector2(player_x, -132. if side < 0 else w.floor_at(player_x))
		var warned := false
		var warned_at := 0
		var start := Vector2.ZERO
		for tick in 730:
			w.step_enemies(DT)
			if not warned and float(scout.windup)>0.:
				warned = true
				warned_at = tick
				start = CampaignGroundShooters.origin(scout)
				var cue := CueView.new()
				cue.world = w
				cue.camera_x = player_x-400.
				CampaignGroundShooters.draw(cue,scout,Vector2(float(scout.x),float(scout.y)))
				check(cue.marks.any(func(mark): return absf(mark.position.x-start.x)>=28. and is_equal_approx(mark.position.y,start.y)), "Standing warning draws some of the real open shot path on side " + str(side))
				check(float(scout.x)!=authored_start.x and scout.facing==side and is_equal_approx(float(scout.y),authored_start.y), "Scout walks to the reachable deck edge before the locked warning on side " + str(side))
			if w.bullets.is_empty(): continue
			check(warned and float(tick-warned_at)*DT>=.60, "Floor/roof player sees at least 0.60 seconds of committed warning on side " + str(side))
			var bolt: Dictionary = w.bullets[0]
			check(Vector2(bolt.p).is_equal_approx(start) and signf(float(bolt.v.x))==side and is_zero_approx(float(bolt.v.y)), "Visible release socket and actual horizontal bolt agree on side " + str(side))
			for i in 20: w.step_bullets(DT)
			check(not w.bullets.is_empty() and absf(float(bolt.p.x)-start.x)>55., "Actual bolt passes open cover edge instead of disappearing at its own muzzle on side " + str(side))
			break
		check(warned and int(scout.attacks)==1, "Actual guarded peek produces one complete attack on side " + str(side))
	var covered := guard_only_relay()
	var cover: Rect2 = CampaignContent.RELAY_COVERS[1]
	covered.player = Vector2(cover.get_center().x, cover.end.y)
	check(not wait_for_shot(covered, 520) and is_zero_approx(float(covered.enemies[0].windup)), "Staying on the deck behind the solid cover suppresses a new roof burst")
	var route_contact := CampaignContent.cover_contact(covered,Vector2(cover.position.x-34.,cover.get_center().y),Vector2(cover.end.x+45.,cover.get_center().y))
	check(route_contact.is_finite() and is_equal_approx(route_contact.x,cover.position.x), "The original upper cover still blocks a low traversing shot using actual geometry")
	var saved := guard_only_relay()
	var previous: Dictionary = saved.enemies[0]
	saved.player = Vector2(4430., -132.)
	previous.facing = -1
	previous.windup = .06
	var restored := AionCampaignWorld.new()
	check(restored.restore(saved.snapshot()), "Pre-peek checkpoint with loaded blocked windup still opens")
	restored.enemies.assign(restored.enemies.filter(func(e): return e.id==CampaignContent.RELAY_SCOUT))
	for tick in 12: restored.step_enemies(DT)
	check(restored.bullets.is_empty() and int(restored.enemies[0].attacks)==0, "Legacy blocked windup cancels silently before spending the first volley")
	check(wait_for_shot(restored) and float(restored.enemies[0].x)<4820., "The resumed scout can complete a new supported left peek without resetting its stable ID")
	var standard := AionCampaignWorld.new()
	standard.begin("aion")
	standard.state = "playing"
	standard.enemies.clear()
	standard.player = Vector2(2100.,0.)
	standard.invulnerable = 0.
	standard.spawn_enemy("lantern_scout",2530.,0.,996)
	var ground: Dictionary = standard.enemies[0]
	ground.age = 1.
	ground.wait = 0.
	standard.step_enemies(DT)
	var cue := CueView.new()
	cue.world = standard
	CampaignGroundShooters.draw(cue,ground,Vector2(2530.,0.))
	var source := CampaignGroundShooters.origin(ground)
	check(cue.marks.any(func(mark): return absf(mark.position.x-standard.player.x)<28. and is_equal_approx(mark.position.y,source.y)), "A ground scout's warning reaches the actual player beyond the old 308-pixel mark limit")
	check(wait_for_shot(standard), "The long-range ground scout emits the advertised trajectory")
	for tick in 180: standard.step_bullets(DT)
	check(standard.hp==0, "The actual shot can reach the marked long-range lane")

func run() -> void:
	lower_lane();roof_lane();flow_and_respawn();open_quay();verify_peek()
	print("RESULT: %d Forge Relay checks, %d failures"%[checks,failures])
	quit(1 if failures>0 else 0)
