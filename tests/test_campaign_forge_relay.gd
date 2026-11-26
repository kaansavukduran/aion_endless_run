extends SceneTree

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
	w.player=Vector2(4770.,-88.)
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

func run() -> void:
	lower_lane();roof_lane();flow_and_respawn()
	print("RESULT: %d Forge Relay checks, %d failures"%[checks,failures])
	quit(1 if failures>0 else 0)
