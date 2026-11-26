extends SceneTree

var checks:=0
var failures:=0

func check(value: bool,label: String) -> void:
	checks+=1
	if not value:failures+=1;printerr("FAIL: "+label)

func fresh() -> AionCampaignWorld:
	var w:=AionCampaignWorld.new()
	w.begin("aion");w.state="playing"
	w.enemies.clear();w.gates.clear();w.objects.clear();w.hazards.clear()
	return w

func _initialize() -> void:call_deferred("run")

func walk_to(w: AionCampaignWorld,x: float, ticks: int=500) -> void:
	for tick in ticks:
		if absf(w.player.x-x)<2.:break
		w.move_axis=Vector2(signf(x-w.player.x),0.)
		w.step(1./120.)
	w.move_axis=Vector2.ZERO

func relay_travel() -> void:
	for hero in AionCampaignWorld.HEROES:
		for direction in [-1,1]:
			var w:=fresh()
			w.begin(hero);w.load_section("relay")
			w.enemies.clear();w.gates.clear();w.objects.clear()
			var start:=4115. if direction==1 else 5000.
			var finish:=5150. if direction==1 else 4070.
			w.player=Vector2(start,w.floor_at(start))
			walk_to(w,4550.)
			check(w.grounded() and absf(w.player.y-96.)<.1,"Main lane reaches the basin from either side: "+hero)
			walk_to(w,finish,850)
			check(absf(w.player.x-finish)<2. and w.grounded() and w.hp==1,"Main lane climbs out without an ability: "+hero)
			var decks:=CampaignGround.RELAY_WALKWAYS.duplicate()
			if direction<0:decks.reverse()
			w.player=Vector2(start,w.floor_at(start))
			w.velocity=Vector2.ZERO
			var every_deck:=true
			for deck: Rect2 in decks:
				var target:=deck.position.x+30. if direction==1 else deck.end.x-30.
				w.jump_press();w.jump_release()
				walk_to(w,target,100)
				for tick in 130:
					if w.grounded():break
					w.step(1./120.)
				every_deck=every_deck and w.grounded() and is_equal_approx(w.player.y,deck.position.y)
				walk_to(w,deck.end.x-18. if direction==1 else deck.position.x+18.)
			check(every_deck and w.taken.has(CampaignGround.RELAY_AMMO),"Normal uncharged jumps travel every roof deck and reach its kit: "+hero)
			walk_to(w,finish)
			for tick in 150:
				if w.grounded():break
				w.step(1./120.)
			check(w.grounded() and absf(w.player.x-finish)<2.,"Roof rejoins the walking lane: "+hero)
			w.player=Vector2(4608.,-145.);w.move_axis=Vector2.DOWN;w.velocity=Vector2.ZERO
			w.jump_press();w.jump_release()
			for tick in 150:w.step(1./120.)
			check(is_equal_approx(w.player.y,96.),"Down and jump drops from the upper deck to the basin: "+hero)

func terrain_regressions() -> void:
	var w:=fresh()
	for stage in ["shore","causeway"]:
		w.load_section(stage)
		var matches:=w.objects.filter(func(o):return o.kind in ["surprise","planks","rock"] and float(o.y)>45.)
		check(not matches.is_empty(),"Actual basin holds a breakable prop: "+stage)
		if matches.is_empty():continue
		var prop: Dictionary=matches[0]
		CampaignContent.hit_object(w,Vector2(float(prop.x),float(prop.y)-35.),100)
		var gift: Dictionary=w.pickups.filter(func(p):return p.id==str(prop.id)+":gift")[0]
		w.player=Vector2(float(prop.x),float(prop.y))
		check(w.touches_pickup(gift),"Nearby hero can touch the actual broken prop reward: "+stage)
		gift.y=-35.
		var older:=w.snapshot();older.ground_revision=2
		var restored:=AionCampaignWorld.new()
		check(restored.restore(older) and restored.pickups.any(func(p):return p.id==gift.id and restored.touches_pickup(p)),"An unclaimed old drop migrates in place: "+stage)
	for base in [0.,-114.,76.]:
		for offset in [0.,-100.]:
			w=fresh();w.load_section("terrace");w.enemies.clear()
			w.invulnerable=0.;w.shield_charge=0.
			w.player=Vector2(8240.,base+offset)
			w.spawn_enemy("vine",8190.,base,9999)
			CampaignEnemies.attack(w,w.enemies[0])
			check((w.state=="dying")==is_zero_approx(offset),"Same-height sweep hits and elevated player evades at world Y "+str(base))
	for direction in [-1,1]:
		w=fresh();w.load_section("water");w.enemies.clear()
		var x:=5660.
		w.player=Vector2(x+300.*direction,w.floor_at(x+300.*direction))
		w.spawn_enemy("leech",x,w.floor_at(x),9999)
		var leech:=w.enemies[0];leech.lunge=.04;leech.recover=.35
		for tick in 6:
			CampaignEnemies.step(w,leech,1./60.)
			check(is_equal_approx(float(leech.y),w.floor_at(float(leech.x))),"Lunge and recovery stay on their final support")
	w=fresh();w.load_section("relay")
	w.player=Vector2(4470.,CampaignGround.profile_height(CampaignGround.OLD_RELAY,4470.))
	w.platforms.erase(CampaignGround.RELAY_WALKWAYS[1]);w.platforms.erase(CampaignGround.RELAY_WALKWAYS[3])
	w.taken[CampaignGround.RELAY_AMMO]=true;w.ammunition=9
	w.awarded["relay:enemy:314"]=true;w.rally.x=4300.
	var old:=w.snapshot();old.ground_revision=2
	var migrated:=AionCampaignWorld.new()
	check(migrated.restore(old) and is_equal_approx(migrated.player.y,migrated.floor_at(4470.)),"A revision-2 save keeps its X and moves to actual basin support")
	check(migrated.ammunition==9 and migrated.rally.x==4300. and migrated.awarded.has("relay:enemy:314"),"Basin migration preserves ammo, checkpoint and claims")
	check(CampaignGround.RELAY_WALKWAYS.all(func(deck):return deck in migrated.platforms) and not migrated.pickups.any(func(p):return p.id==CampaignGround.RELAY_AMMO),"Saved roof is complete and claimed ammunition stays claimed")
	w.player=Vector2(4310.,w.floor_at(4310.));w.velocity=Vector2.RIGHT*235.
	check(CampaignGround.descent_preview(w,0.,true)>0. and CampaignGround.descent_preview(w,0.,false)==0.,"Portrait camera previews basin descent when approaching on foot")
	w.player=Vector2(4400.,-132.08);w.velocity=Vector2(0.,80.)
	check(not w.grounded(),"An airborne foot within tolerance does not land before colliding")

func authored_branch_routes() -> void:
	var w:=fresh()
	for stage in CampaignGround.BRANCH_WALKWAYS:
		w.load_section(stage)
		var decks: Array=CampaignGround.BRANCH_WALKWAYS[stage]
		var supply: Dictionary=CampaignGround.BRANCH_SUPPLIES[stage]
		var zone: Dictionary=CampaignGround.BRANCH_ZONES.get(stage,{})
		check(decks.all(func(deck):return deck in w.platforms),"Every authored branch deck has collision support: "+stage)
		var actual: Array=w.pickups.filter(func(item):return item.id==supply.id)
		check(actual.size()==1 and actual[0].y==supply.y,"Branch reward is placed once at its authored height: "+stage)
		for index in range(1,decks.size()):
			var a: Rect2=decks[index-1]
			var b: Rect2=decks[index]
			check(b.position.x-a.end.x<=150. and absf(b.position.y-a.position.y)<=60.,"Ordinary jump envelope across every route deck: "+stage)
		for deck in decks:w.platforms.erase(deck)
		w.pickups.assign(w.pickups.filter(func(item):return item.id!=supply.id))
		if not zone.is_empty():w.zones.assign(w.zones.filter(func(item):return item.id!=zone.id))
		var older:=w.snapshot();older.ground_revision=2
		var restored:=AionCampaignWorld.new()
		check(restored.restore(older) and decks.all(func(deck):return deck in restored.platforms),"Older branch save gets new geometry: "+stage)
		if not zone.is_empty():check(restored.zones.any(func(item):return item.id==zone.id),"Older branch save gets its terrain effect: "+stage)
	w.load_section("water")
	w.player=Vector2(6000.,32.)
	CampaignContent.push_current(w,5.)
	check(w.player==Vector2(6000.,32.),"Bridge above current has no conveyor force")
	w.player=Vector2(5999.,w.floor_at(5999.))
	CampaignContent.push_current(w,5.)
	check(w.player==Vector2(6004.,w.floor_at(6004.)),"Current moves the actor along the supported lower lane")
	w.load_section("relay")
	var scout: Dictionary=w.enemies.filter(func(e):return e.id==CampaignContent.RELAY_SCOUT)[0]
	var drone: Dictionary=w.enemies.filter(func(e):return e.id==CampaignContent.RELAY_DRONE)[0]
	check(scout.kind=="lantern_scout" and bool(scout.roof_perch) and CampaignGround.RELAY_WALKWAYS[-1].has_point(Vector2(float(scout.x),float(scout.y))),"Relay scout stands on the actual final roof deck")
	drone.windup=.2
	check(CampaignContent.relay_opening_blocked(w,scout),"The scout waits while the nearby drone prepares its initial shot")
	drone.windup=0.;drone.flash=.2
	check(CampaignContent.relay_opening_blocked(w,scout),"The other attack cannot start in the release window")
	drone.flash=0.
	check(not CampaignContent.relay_opening_blocked(w,scout),"Player gets an ordinary roof encounter after the release window")

func run() -> void:
	var w:=fresh()
	check(w.floor_at(3140.)==56. and w.floor_at(3570.)==-58. and w.floor_at(4200.)==0.,"One walking lane contains a sheltered basin and a raised shelf")
	check(not CampaignGround.has_floor(w.floor_at(6000.)),"The collapsing bridge keeps its real underlying void")
	for type in ["foot","skimmer","shell","wind","drill"]:
		w=fresh()
		var saddle:=0. if type=="foot" else 42.
		if type!="foot":w.mount={"available":true,"ridden":true,"hp":1,"type":type,"x":2750.}
		w.player=Vector2(2750.,-saddle)
		w.move_axis=Vector2.RIGHT
		var error:=0.
		for tick in 950:
			w.step(1./120.)
			error=maxf(error,absf(w.player.y+saddle-w.floor_at(w.player.x)))
			if w.player.x>=4190.:break
		check(w.player.x>=4190. and w.hp==1,"Normal movement traverses both grades without a jump or death: "+type)
		check(error<.1,"The real body or saddle stays planted at the shared height: "+type)
	w=fresh()
	w.player=Vector2(3060.,56.)
	w.spawn_enemy("gnome",3435.,w.floor_at(3435.),800);var e:=w.enemies[0];e.wait=999.
	for tick in 50:w.step_enemies(.01)
	check(float(e.x)<3435. and absf(float(e.y)-w.floor_at(float(e.x)))<.01,"A ground enemy follows the grade while approaching")
	w=fresh();var npc: Dictionary=w.npcs[1]
	check(absf(float(npc.y)-w.floor_at(float(npc.x)))<.01,"A bound NPC stands on its real sloped surface")
	w.rescue(npc);w.player=Vector2(2800.,0.)
	var initial_x:=float(npc.x)
	for tick in 40:CampaignRescue.step(w,.01)
	check(absf(float(npc.x)-initial_x)>1. and absf(float(npc.y)-w.floor_at(float(npc.x)))<.01,"Freed NPC feet stay on the grade while roaming")
	w.player=Vector2(float(npc.x),float(npc.y))
	for tick in 130:CampaignRescue.step(w,.01)
	var dropped: Dictionary=w.gift_drops.get(str(npc.id),{})
	check(not dropped.is_empty() and absf(float(dropped.get("y",0.))+25.-w.floor_at(float(dropped.get("x",0.))))<.01,"The handover lands within reach on uneven ground")
	var section:=Rect2(2950.,-430.,1152.,625.)
	var landing:=CampaignLives.landing(w,section)
	check(CampaignLives.landing_clear(w,landing) and landing.x>=section.position.x and landing.x<section.end.x,"Reserve return has a safe local terrain pocket")
	w=fresh()
	w.bullets=[{"p":Vector2(3280.,25.),"v":Vector2(2200.,0.),"age":0.,"owner":"hero","kind":"pistol","pierce":0,"damage":1,"hit":[]}]
	w.step_bullets(.1)
	check(w.bullets.is_empty(),"A projectile crossing a raised slope is physically stopped")
	w=fresh()
	w.platforms.clear();w.player=Vector2(3345.,w.floor_at(3345.));w.throw_grenade()
	var contact:=Vector2.ZERO
	for tick in 160:
		w.step(.01)
		for bomb in w.bombs:
			if not bomb.contacts.is_empty():contact=bomb.contacts[-1].p
		if contact!=Vector2.ZERO:break
	check(contact!=Vector2.ZERO,"A normal grenade throw contacts the actual terrain")
	if contact!=Vector2.ZERO:
		var support: float=w.crossing_floor(contact.x,contact.y-3.,contact.y+3.,1.)
		check(absf(contact.y-support)<4.,"Grenade impact cue sits on the physical surface: %s / %.2f"%[str(contact),support])
	w=fresh()
	w.player=Vector2(3540.,0.);w.attempts_remaining=2;w.awarded["shore:old-claim"]=true
	var flat_save:=w.snapshot();flat_save.erase("ground_revision")
	var restored:=AionCampaignWorld.new()
	check(restored.restore(flat_save) and restored.player==Vector2(3540.,-58.) and restored.attempts_remaining==2 and restored.awarded.has("shore:old-claim"),"An earlier flat save adapts its feet without renewing lives or claims")
	for key in CampaignGround.PROFILES:
		if key=="shore":continue
		w=fresh();w.load_section(key)
		w.enemies.clear();w.gates.clear();w.objects.clear();w.hazards.clear();w.zones.clear();w.platforms.clear();w.pits.clear()
		var points: Array=CampaignGround.PROFILES[key]
		var exit_x:=minf(float(points.back().x),w.length()-90.)
		w.player=points.front()
		w.move_axis=Vector2.RIGHT
		var low:=0.
		var high:=0.
		var footing:=true
		for tick in 2400:
			w.step(1./120.)
			high=minf(high,w.player.y);low=maxf(low,w.player.y)
			footing=footing and absf(w.player.y-w.floor_at(w.player.x))<.1
			if w.player.x>=exit_x:break
		check(footing and high-low< -20. and w.player.x>=exit_x and w.attempts_remaining==3,"Each authored profile retains real supported traversal and changes elevation: "+key)
	w=fresh();w.load_section("water");w.pits.assign([Vector2(5940.,6010.)])
	check(not CampaignGround.fell_into_pit(w,Vector2(5960.,214.)) and CampaignGround.fell_into_pit(w,Vector2(5960.,400.)),"A real pit at the deep basin uses its local lips to measure falling")
	w=fresh();w.load_section("water");w.enemies.clear()
	w.spawn_enemy("siphon",5980.,-130.,802)
	CampaignGround.align_world(w)
	var supported_flyer: Dictionary=w.enemies[0]
	check(absf(float(supported_flyer.y)-w.floor_at(float(supported_flyer.x))+130.)<.01 and is_equal_approx(float(supported_flyer.home.y),float(supported_flyer.y)),"An attack flyer preserves its planned height above the playable deep basin")
	w=fresh();w.load_section("arena");w.player=Vector2(2120.,0.)
	w.boss.engaged=true;w.boss.phase=2;w.boss.max_hp=90;w.boss.hp=43;w.boss.x=2730.;w.boss.y=0.
	for deck in CampaignGround.ARENA_WALKWAYS:w.platforms.erase(deck)
	var earlier_arena:=w.snapshot();earlier_arena.ground_revision=1
	restored=AionCampaignWorld.new()
	check(restored.restore(earlier_arena) and restored.boss.max_hp==270 and restored.boss.hp==129 and restored.boss.phase==2 and restored.boss.engaged,"Arena refinement keeps an already engaged boss and scales old health without changing its phase")
	check(restored.player.y==-40. and float(restored.boss.y)==-26. and restored.platforms.has(CampaignGround.ARENA_WALKWAYS[1]),"The old arena save gains the actual hero, boss and support elevations")
	restored.boss.attack=1;restored.boss.windup=.02
	restored.step_boss(.025)
	check(float(restored.platform_timers[2020.])>2. and restored.bullets.any(func(b):return b.kind=="wave"),"The phase two root wave affects the platform in the active arena")
	restored.step_bullets(.06)
	for wave in restored.bullets:
		if wave.kind=="wave":check(is_equal_approx(float(wave.p.y),restored.floor_at(float(wave.p.x))-16.),"The root wave remains near the actual ground")
	terrain_regressions()
	relay_travel()
	authored_branch_routes()
	print("RESULT: %d campaign terrain checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
