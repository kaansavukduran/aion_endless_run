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
	w.boss.engaged=true;w.boss.hp=41;w.boss.phase=2;w.boss.ports=[0,3]
	w.player=Vector2(2240.,0.);w.flock=AionCampaignWorld.MAX_FLOCK;w.grenades=2;w.weapon="heavy";w.ammunition=6
	w.spawn_enemy("gnome",2100.,0.,1337);w.enemies.back().defeated=true
	w.activated["arena:gate"]=true;w.taken["arena:reward"]=true;w.awarded["arena:reward"]=true;w.rescued.append("arena:keeper")
	var area:=Rect2(1728.,-420.,1152.,500.)
	check(w.hp==1 and w.attempts_remaining==3,"One active body and two reserve lives")
	for death in 3:
		w.invulnerable=0.
		w.damage_player("shot");w.damage_player("pit");w.damage_player("impact")
		check(w.hp==0 and w.attempts_remaining==2-death and w.losses==death+1,"Concurrent damage spends exactly one body and one life")
		check(w.flock==AionCampaignWorld.MAX_FLOCK and w.death_cause=="shot","The flock never absorbs a hit or changes the chosen cause")
		check(w.grenades==2 and w.weapon=="pistol","Reserve spawn drops the current weapon without refilling grenades")
		w=roundtrip(w)
		check(w.boss.hp==41 and w.boss.phase==2 and w.boss.ports==[0,3] and w.enemies.back().defeated,"Save preserves boss and defeated enemies")
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
			check(not w.entry_guard and w.invulnerable==0.,"The first fresh attack ends landing grace")
	check(w.state=="continue_offer" and w.continue_remaining==10.,"Last life opens a ten-second offer")
	CampaignLives.tick_offer(w,3.4)
	w=roundtrip(w)
	check(is_equal_approx(w.continue_remaining,6.6),"Reload keeps unspent time")
	check(CampaignLives.open_picker(w),"One fresh confirmation enters hero selection")
	w.continue_hero="frog";w=roundtrip(w);CampaignLives.tick_offer(w,6.)
	check(w.continue_hero=="frog" and is_equal_approx(w.continue_remaining,6.6) and w.attempts_remaining==0,"Saved picker keeps its hero and freezes the offer")
	check(CampaignLives.cancel_picker(w) and is_equal_approx(w.continue_remaining,6.6),"Back returns to the same remaining time")
	CampaignLives.open_picker(w)
	check(CampaignLives.confirm(w,"frog") and not CampaignLives.confirm(w,"eren"),"A confirmation spends exactly one Continue and changes hero once")
	w=roundtrip(w)
	check(w.character=="frog" and w.continues_used==1 and w.attempts_remaining==3 and w.grenades==5 and w.boss.hp==41,"New credit is durable, with one starter loadout and preserved battle")
	w.attempts_remaining=0;w.state="continue_offer";w.continue_remaining=.1
	CampaignLives.tick_offer(w,.12)
	check(w.continue_remaining==0. and not CampaignLives.open_picker(w),"Zero is shown without leaving an accept window")
	CampaignLives.tick_offer(w,.01)
	check(w.state=="dead" and roundtrip(w).state=="dead","Expired run cannot respawn through a saved checkpoint")

func test_legacy() -> void:
	var old:={"schema":3,"character":"eren","checkpoint":"quay","score":375,"losses":8,"taken":{"quay:fruit:3":true},"awarded":{"quay:fruit:3":true},"rescued":[],"route":[]}
	var w:=AionCampaignWorld.new()
	check(w.restore(old) and w.hp==1 and w.attempts_remaining==3 and w.score==375 and w.character=="eren","Legacy record gains one documented initial stock")
	w.invulnerable=0.;w.damage_player();w=roundtrip(w)
	check(w.attempts_remaining==2 and w.taken.has("quay:fruit:3"),"Reopening new schema never repeats legacy stock")
	var invalid:=w.snapshot();invalid.encounter=invalid.encounter.substr(1)
	check(not AionCampaignWorld.new().restore(invalid),"Truncated encounter cannot replace valid progress")

func test_arena_reentry() -> void:
	for width in [520.,1152.]:
		var w:=AionCampaignWorld.new();w.begin("eren");w.load_section("arena")
		w.boss.engaged=true;w.boss.hp=67;w.boss.ports=[0,3];w.player=Vector2(2115.,-40.)
		for death in 6:
			var previous_camera:=maxf(0.,w.player.x-width*.34)
			w.invulnerable=0.;w.damage_player("shot");clock(w,.9)
			if w.state=="continue_offer":
				CampaignLives.open_picker(w);CampaignLives.confirm(w,"eren")
			CampaignLives.start_entry(w,Rect2(previous_camera,-420.,width,500.))
			check(is_equal_approx(w.entry_from.x,w.recovery_view.position.x+36.),"Arena entry still starts left of its actual camera")
			clock(w,.65)
			check(w.player.x>float(w.boss.x)-width*.75 and w.grounded(),"Consecutive boss deaths cannot drift out of the fight")
			check(w.boss.hp==67 and w.boss.ports==[0,3],"Boss pressure and broken ports persist across the same encounter")

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
	test_arena_reentry()
	test_arena_drones()
	test_vehicles()
	test_clearance_and_support()
	print("RESULT: %d arcade life and vehicle checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
