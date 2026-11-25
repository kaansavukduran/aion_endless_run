extends SceneTree

var checks:=0
var failures:=0

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+label)

func _initialize() -> void:call_deferred("run")

func clock(w: AionCampaignWorld,seconds: float) -> void:
	for tick in ceili(seconds*120.):w.step(1./120.)

func roundtrip(w: AionCampaignWorld) -> AionCampaignWorld:
	var result:=AionCampaignWorld.new()
	check(result.restore(JSON.parse_string(JSON.stringify(w.snapshot()))),"Serialized live encounter opens through the real loader")
	return result

func test_lives() -> void:
	var w:=AionCampaignWorld.new();w.begin("sheep");w.load_section("arena")
	w.boss.engaged=true;w.boss.hp=123;w.boss.phase=2;w.boss.ports=[0,3]
	w.player=Vector2(2240.,0.);w.flock=AionCampaignWorld.MAX_FLOCK;w.grenades=2
	CampaignWeapons.equip(w,"heavy");w.ammunition=6
	w.spawn_enemy("gnome",2100.,0.,1337);w.enemies.back().defeated=true
	w.activated["arena:gate"]=true;w.taken["arena:reward"]=true;w.awarded["arena:reward"]=true;w.rescued.append("arena:keeper")
	var area:=Rect2(1728.,-420.,1152.,500.)
	check(w.hp==1 and w.attempts_remaining==3,"One active body and two reserve lives")
	for death in 3:
		var sidearm_before:=CampaignWeapons.sidearm_stock(w)
		w.invulnerable=0.
		w.damage_player("shot");w.damage_player("pit");w.damage_player("impact")
		check(w.hp==0 and w.attempts_remaining==2-death and w.losses==death+1,"Concurrent damage spends exactly one body and one life")
		check(w.flock==AionCampaignWorld.MAX_FLOCK and w.death_cause=="shot","The flock never absorbs a hit or changes the chosen cause")
		check(w.grenades==2 and w.weapon=="pistol" and w.ammunition==sidearm_before,"Reserve spawn returns to the stored sidearm without refilling spent rounds or grenades")
		w=roundtrip(w)
		check(w.boss.hp==123 and w.boss.phase==2 and w.boss.ports==[0,3] and w.enemies.back().defeated,"Save preserves boss and defeated enemies")
		check(w.activated.has("arena:gate") and w.rescued.has("arena:keeper") and w.awarded.has("arena:reward") and w.taken.has("arena:reward"),"Gates, rescues and unique claims survive death")
		if death<2:
			check(w.state=="respawn_pending","Reopening on a death with reserve lives schedules the same hero")
			CampaignLives.start_entry(w,area)
			check(w.player.x<area.position.x+100. and w.player.y<area.position.y+110.,"Re-entry starts inside the current view's upper left")
			var sim:=w.time
			clock(w,.65)
			check(w.state=="playing" and w.hp==1 and w.grounded() and w.time-sim<.05,"Clear landing freezes combat until the body returns")
			w.damage_player()
			check(w.hp==1 and w.entry_guard,"Visible entry grace protects a fresh body")
			w.attack_press()
			check(w.entry_guard and w.invulnerable>2.9,"Firing keeps the full landing grace")
	check(w.state=="continue_offer" and w.continue_remaining==10.,"Last life opens a ten-second offer")
	CampaignLives.tick_offer(w,3.4)
	w=roundtrip(w)
	check(is_equal_approx(w.continue_remaining,6.6),"Reload keeps unspent time")
	w.continue_hero="frog"
	var legacy_picker:=w.snapshot();legacy_picker.phase="continue_pick"
	check(w.restore(legacy_picker) and w.state=="continue_offer","Previous picker save loads into the live Continue")
	w=roundtrip(w)
	var old_clock: float=w.boss.clock
	var old_position:=w.player
	clock(w,1.)
	check(w.continue_hero=="frog" and is_equal_approx(w.continue_remaining,5.6) and w.attempts_remaining==0,"Browsing keeps the hero without stopping the countdown")
	check(float(w.boss.clock)>old_clock+.9 and w.boss.hp==123 and w.player==old_position and w.hp==0 and w.score==0,"The same boss battle runs behind the selection while the fallen hero cannot act or be hit")
	check(CampaignLives.confirm(w,"frog") and not CampaignLives.confirm(w,"eren"),"A confirmation spends exactly one Continue and changes hero once")
	w=roundtrip(w)
	check(w.character=="frog" and w.continues_used==1 and w.attempts_remaining==3 and w.grenades==5 and w.ammunition==CampaignWeapons.PISTOL_START and w.boss.hp==123,"New credit is durable, with one starter loadout and preserved battle")
	w.attempts_remaining=0;w.state="continue_offer";w.continue_remaining=.1
	CampaignLives.tick_offer(w,.12)
	check(w.continue_remaining==0. and not CampaignLives.confirm(w,"aion"),"An expired Continue cannot be purchased")
	check(w.state=="dead" and roundtrip(w).state=="dead","Expired run cannot respawn through a saved checkpoint")

func test_legacy() -> void:
	var old:={"schema":3,"character":"eren","checkpoint":"quay","score":375,"losses":8,"taken":{"quay:fruit:3":true},"awarded":{"quay:fruit:3":true},"rescued":[],"route":[]}
	var w:=AionCampaignWorld.new()
	check(w.restore(old) and w.hp==1 and w.attempts_remaining==3 and w.score==375 and w.character=="eren","Legacy record gains one documented initial stock")
	w.invulnerable=0.;w.damage_player();w=roundtrip(w)
	check(w.attempts_remaining==2 and w.taken.has("quay:fruit:3"),"Reopening new schema never repeats legacy stock")
	var invalid:=w.snapshot();invalid.encounter=invalid.encounter.substr(1)
	check(not AionCampaignWorld.new().restore(invalid),"Truncated encounter cannot replace valid progress")

func test_protection() -> void:
	var w:=AionCampaignWorld.new()
	w.begin("aion");w.load_section("shore")
	w.enemies.clear();w.npcs.clear();w.objects.clear();w.hazards.clear();w.gates.clear();w.pickups.clear()
	w.invulnerable=0.
	w.damage_player("shot");clock(w,.9)
	CampaignLives.start_entry(w,Rect2(0.,-420.,1152.,500.));clock(w,.625)
	check(w.state=="playing" and w.hp==1 and w.invulnerable==3. and w.shield_charge==0.,"One HP returns with a fresh three-second guard and an empty shield")
	w.attack_press();w.attack_release()
	check(w.shots==1 and w.throw_grenade() and w.invulnerable==3.,"Fire and grenade work without shortening the guard")
	w.state="paused";clock(w,.5);w.state="playing"
	check(w.invulnerable==3.,"Pause does not spend respawn protection")
	clock(w,2.95);w.damage_player("beam")
	check(w.hp==1 and w.entry_guard and w.shield_charge==0.,"Late damage is ignored during respawn grace")
	w=roundtrip(w)
	check(w.entry_guard and w.invulnerable>.04,"Resume keeps the remaining grace")
	clock(w,.05)
	check(not w.entry_guard and is_zero_approx(w.invulnerable),"The full respawn protection expires at three active seconds")
	clock(w,2.)
	check(is_equal_approx(w.shield_charge,2.) and not w.shield_ready(),"Two damage-free seconds charge half a shield")
	w=roundtrip(w)
	w.state="paused";clock(w,1.);w.state="playing"
	check(is_equal_approx(w.shield_charge,2.),"The shield's partial charge survives reload and pause")
	w.load_section("quay")
	check(is_equal_approx(w.shield_charge,2.),"An ordinary region change carries the partial charge")
	w.enemies.clear();w.npcs.clear();w.objects.clear();w.hazards.clear();w.gates.clear();w.pickups.clear()
	w.invulnerable=0.;clock(w,2.)
	check(w.shield_ready() and w.hp==1,"Four unprotected seconds arm one shield without adding HP")
	var full_save:=w.snapshot()
	var previous_timing:=full_save.duplicate(true);previous_timing.shield_charge=8.
	var migrated:=AionCampaignWorld.new()
	check(migrated.restore(previous_timing) and migrated.shield_charge==4. and migrated.shield_ready(),"An eight-second-era charged save remains usable under the four-second rule")
	var old_save:=full_save.duplicate(true);old_save.erase("shield_charge")
	var old:=AionCampaignWorld.new()
	check(old.restore(old_save) and old.shield_charge==0.,"Earlier schema-four saves still load with an empty shield")
	var invalid:=full_save.duplicate(true);invalid.shield_charge=9.
	check(not AionCampaignWorld.new().restore(invalid),"Resume rejects impossibly charged shields")
	var rider:=AionCampaignWorld.new()
	check(rider.restore(full_save),"A ready shield round-trips alongside the live encounter")
	rider.mount={"available":true,"ridden":true,"hp":1,"x":rider.player.x,"type":"shell"}
	rider.damage_player("shot")
	check(CampaignVehicles.stunned(rider) and rider.shield_ready(),"The vehicle takes its own hit without spending the pilot's shield")
	var lives:=w.attempts_remaining
	w.bullets.append({"p":w.player_hit_center(),"v":Vector2.ZERO,"owner":"enemy","age":0.,"kind":"seed"})
	w.step_bullets(.01)
	w.damage_player("impact")
	check(w.hp==1 and w.attempts_remaining==lives and w.shield_charge==0. and w.pending_events.count("shield_hit")==1,"A real projectile consumes the shield once and staggered collisions cannot double-hit")
	w=roundtrip(w)
	check(not w.shield_ready() and w.invulnerable>0.,"A spent shield stays spent across reload")
	clock(w,.5);w.damage_player("shot")
	check(w.hp==0 and w.attempts_remaining==lives-1 and w.shield_charge==0.,"The next unprotected hit spends the original one life and resets the charge")
	w=roundtrip(w)
	check(w.restore(full_save),"A ready shield snapshot remains usable")
	w.damage_player("pit")
	check(w.hp==0 and w.death_cause=="pit","The shield cannot keep the actor suspended in a lethal pit")

func test_arena_reentry() -> void:
	for width in [520.,1152.]:
		var w:=AionCampaignWorld.new();w.begin("eren");w.load_section("arena")
		w.boss.engaged=true;w.boss.hp=201;w.boss.ports=[0,3];w.player=Vector2(2115.,-40.)
		for death in 6:
			var previous_camera:=maxf(0.,w.player.x-width*.34)
			w.invulnerable=0.;w.damage_player("shot");clock(w,.9)
			if w.state=="continue_offer":
				CampaignLives.confirm(w,"eren")
			CampaignLives.start_entry(w,Rect2(previous_camera,-420.,width,500.))
			check(is_equal_approx(w.entry_from.x,w.recovery_view.position.x+36.),"Arena entry still starts left of its actual camera")
			clock(w,.65)
			check(w.player.x>float(w.boss.x)-width*.75 and w.grounded(),"Consecutive boss deaths cannot drift out of the fight")
			check(w.boss.hp==201 and w.boss.ports==[0,3],"Boss pressure and broken ports persist across the same encounter")

func test_crow_reentry() -> void:
	var w:=AionCampaignWorld.new();w.begin("aion");w.load_section("shore");w.state="playing"
	w.enemies.clear();w.gates.clear();w.hazards.clear();w.objects.clear();w.platforms.clear();w.pits.clear()
	w.player=Vector2(850.,w.floor_at(850.));w.invulnerable=0.
	w.spawn_enemy("crow",945.,-155.,1)
	w.enemy_shot(w.enemies[0])
	var death_point:=w.player
	check(CampaignLives.crow_danger(w,death_point),"A crow's actual dive corridor marks the exposed position")
	w.damage_player("impact");clock(w,.9)
	CampaignLives.start_entry(w,Rect2(700.,-370.,410.,460.))
	check(CampaignLives.landing_clear(w,w.entry_to) and not CampaignLives.crow_danger(w,w.entry_to),"Respawn selects supported land outside the active dive")
	check(w.entry_to.distance_to(death_point)>150. and w.recovery_view.has_point(w.entry_to),"Narrow camera follows the safer re-entry rather than dropping onto the crow")
	clock(w,.65)
	check(w.hp==1 and w.entry_guard and w.grounded(),"A live crow encounter leaves a grounded, guarded hero")

func test_arena_drones() -> void:
	var w:=AionCampaignWorld.new();w.begin("aion");w.load_section("arena")
	w.boss.engaged=true
	for attack in [2,5,8]:
		w.boss.attack=attack;w.boss.windup=.01;w.step_boss(.02)
		check(w.enemies.filter(func(e):return e.kind=="drone" and not e.defeated).size()==2,"The active reinforcement wave cannot stack")
	var drone: Dictionary=w.enemies.filter(func(e):return e.kind=="drone").front()
	w.damage_enemy(drone,100)
	w.boss.attack=11;w.boss.windup=.01;w.step_boss(.02)
	check(w.enemies.filter(func(e):return e.kind=="drone" and not e.defeated).size()==2,"The next wave replaces only the defeated drone")

func test_turret() -> void:
	var w:=AionCampaignWorld.new();w.begin("aion");w.load_section("shore")
	w.enemies.clear();w.pickups.clear();w.hazards.clear();w.objects.clear();w.platforms.clear()
	var x:=400.
	var cannon: Dictionary={"kind":"turret","id":"test-cannon","x":x,"y":w.floor_at(x),"active":false,"clock":2.99}
	w.objects.append(cannon)
	w.player=Vector2(x,w.floor_at(x));w.invulnerable=0.
	clock(w,3.5)
	check(w.hp==1 and w.bullets.is_empty() and not CampaignContent.turret_warning(cannon),"Standing on an armed cannon cancels the shot and cannot spend a life")
	w.player=Vector2(x+235.,w.floor_at(x+235.))
	clock(w,2.5)
	check(CampaignContent.turret_warning(cannon) and w.bullets.is_empty(),"The rearmed cannon shows its windup before shooting")
	clock(w,.52)
	check(w.bullets.size()==1 and Vector2(w.bullets[0].p).distance_to(CampaignContent.turret_muzzle(cannon))<12. and w.hp==1,"The round leaves the visible muzzle with travel time")
	clock(w,1.)
	check(w.hp==1 and not w.shield_ready() and w.pending_events.count("shield_hit")==1,"The visible cannon round spends the charged shield")
	clock(w,3.1)
	check(w.hp==0 and w.death_cause=="shot","The next cannon round takes the single life before the shield recharges")
	w.state="playing";w.hp=1;w.invulnerable=0.;w.bullets.clear();cannon.clock=2.99
	w.player=Vector2(x-235.,w.floor_at(x-235.));w.step(.02)
	check(int(cannon.facing)==-1 and w.bullets.size()==1 and float(w.bullets[0].v.x)<0. and float(w.bullets[0].p.x)<x-38.,"Left-facing cannon fires from its mirrored muzzle")

func test_vehicles() -> void:
	for type in CampaignVehicles.TYPES:
		for hz in [30.,60.,120.]:
			var w:=AionCampaignWorld.new();w.begin("aion");w.load_section("shore")
			w.mount={"available":true,"ridden":true,"hp":1,"x":400.,"type":type}
			w.player=Vector2(400.,-42.);w.invulnerable=0.
			w.damage_player();w.damage_player()
			check(CampaignVehicles.stunned(w) and w.mount.hp==0 and w.hp==1 and w.attempts_remaining==3,"One hit starts a zero-HP vehicle impact without costing a life")
			check(not w.interact() and not w.throw_grenade(),"Stunned vehicle cannot interact or fire")
			w=roundtrip(w)
			var advance: int=roundi(.1*hz)
			for frame in advance-1:w.step(1./hz)
			check(CampaignVehicles.stunned(w) and w.time>0.,"Only the vehicle is immobilized for the impact window")
			w.step(1./hz)
			check(not w.mount.ridden and not w.mount.available and w.mount.hp==0 and w.invulnerable>0.,"Impact ends in one protected pilot ejection")
			check(w.pending_events.count("vehicle_wreck")==1,"One vehicle destruction event is emitted")
			w.collect({"id":"repair-compensation","kind":"repair"})
			check(w.mount.hp==0 and w.grenades==7,"Repair pickup is useful without reviving a wreck")

func test_clearance_and_support() -> void:
	var w:=AionCampaignWorld.new();w.begin("aion");w.load_section("fork_one")
	w.player=Vector2(990.,90.)
	var landing:=CampaignLives.landing(w,Rect2(750.,-340.,600.,480.))
	check(CampaignLives.landing_clear(w,landing) and not CampaignRoutes.solid_at(w,landing+Vector2(0.,-74.)),"Under-pier defeat next uses a supported landing with standing clearance")
	for type in CampaignVehicles.TYPES:
		w.begin("aion");w.load_section("shore")
		w.enemies.clear();w.gates.clear();w.hazards.clear();w.objects.clear();w.platforms.clear();w.pits.assign([Vector2(350.,450.)])
		w.mount={"available":true,"ridden":true,"hp":1,"x":400.,"type":type}
		w.player=Vector2(400.,-225.);w.invulnerable=0.
		w.damage_player();clock(w,.10)
		check(w.player.y< -225. and absf(w.player.x-400.)<10.,"Ejection begins at the actual airframe instead of teleporting down to a surface: "+type)
		clock(w,.9)
		check(w.hp==1 and w.grounded() and CampaignLives.landing_clear(w,w.player),"Ejection crosses the pit and lands on real supported ground: "+type)
		check(w.attempts_remaining==3 and w.pending_events.count("vehicle_wreck")==1,"Lateral rescue does not consume a life or duplicate the blast: "+type)
	w.begin("sheep");w.state="playing";w.flock=2;w.enemies.clear();w.pickups.clear()
	w.player=Vector2(400.,0.)
	w.pickups.append({"id":"flock-fruit","kind":"fruit_0","x":314.,"y":-20.})
	w.step(.01)
	check(w.taken.has("flock-fruit"),"The visible follower collects fruit outside its leader's reach")

func run() -> void:
	test_lives()
	test_legacy()
	test_protection()
	test_arena_reentry()
	test_crow_reentry()
	test_arena_drones()
	test_turret()
	test_vehicles()
	test_clearance_and_support()
	print("RESULT: %d arcade life and vehicle checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
