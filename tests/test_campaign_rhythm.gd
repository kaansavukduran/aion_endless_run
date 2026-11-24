extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+message)
func fresh() -> AionCampaignWorld:
	var w:=AionCampaignWorld.new();w.begin("aion")
	w.enemies.clear();w.objects.clear();w.hazards.clear();w.zones.clear();w.gates.clear();w.npcs.clear();w.crates.clear();w.pickups.clear();w.platforms.clear();w.pits.clear()
	w.state="playing";return w
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var w:=fresh()
	w.collect({"id":"heavy-first","kind":"heavy"})
	w.pickups.append({"id":"choice","kind":"arc","x":w.player.x,"y":-35.})
	w.step(.01)
	check(w.weapon=="heavy" and not w.taken.has("choice"),"Walking into a different special preserves the held gun")
	check(str(CampaignRhythm.offer(w).get("id",""))=="choice","Reachable gun offers the shared contextual interaction")
	check(w.interact() and w.weapon=="arc" and w.taken.has("choice"),"Actual interact deliberately claims the selected gun")
	w.ammunition=10;w.collect({"id":"arc-refill","kind":"arc"})
	check(w.ammunition==46,"Matching supply adds ammunition instead of deleting remaining stock")
	w.collect({"id":"arc-refill","kind":"arc"});check(w.ammunition==46,"Same supply cannot refill twice")
	w.collect({"id":"arc-cap","kind":"arc"});check(w.ammunition==72,"Matching ammo has a finite two-magazine cap")
	w.mount={"ridden":true,"available":true,"hp":3,"x":w.player.x};w.player.y=-42.
	w.pickups.append({"id":"mounted","kind":"beam","x":w.player.x+30.,"y":-35.});w.step(.01)
	check(w.weapon=="beam" and w.taken.has("mounted"),"Vehicle-contact supply collection remains available")
	w=fresh();w.weapon="heavy";w.ammunition=38;w.player=Vector2(2610.,0.)
	w.score=123;CampaignRecovery.step(w)
	check(float(w.rally.get("x",0.))==2600. and int(w.rally.ammunition)==38,"Grounded rally point captures real position and stock")
	w.weapon="disc";w.ammunition=3;w.awarded["already-paid"]=true;w.taken["already-claimed"]=true
	w.hp=1;w.invulnerable=0.;w.damage_player();w.retry()
	check(w.hp==3 and w.player==Vector2(2600.,0.) and w.weapon=="heavy" and w.ammunition==38,"Actual death/retry restores rally stock and a short segment")
	check(w.score==123 and w.awarded.has("already-paid") and w.taken.has("already-claimed"),"Recovery never rolls back one-time score or claims")
	var saved: Dictionary=w.snapshot();var restored:=AionCampaignWorld.new()
	check(restored.restore(saved) and restored.player.x==2600. and restored.weapon=="heavy" and restored.ammunition==38,"Save/Continue reopens the actual rally inventory")
	w.mount={"available":false,"ridden":false,"type":"skimmer","hp":0,"x":2600.};w.rally=CampaignRecovery.capture(w,2600.);w.retry()
	check(int(w.mount.hp)==0 and not bool(w.mount.available),"Recovery does not manufacture a vehicle destroyed before its rally snapshot")
	var old: Dictionary=saved.duplicate(true);old.erase("rally");old.erase("retry_count");old.erase("best_chain")
	var legacy:=AionCampaignWorld.new();check(legacy.restore(old) and legacy.player.x==140. and legacy.taken.has("already-claimed"),"Old schema3 checkpoint retains its safe section-start fallback")
	for bad in [NAN,INF,-1.,99999999.]:
		var invalid: Dictionary=saved.duplicate(true);invalid.rally.x=bad
		check(not AionCampaignWorld.new().restore(invalid),"Malformed rally coordinates are rejected before restore")
	var invalid: Dictionary=saved.duplicate(true);invalid.rally.mount={"available":true,"ridden":true,"hp":3,"x":"nan"}
	check(not AionCampaignWorld.new().restore(invalid),"Malformed nested vehicle numbers cannot enter recovery")
	w=fresh();w.retry();var kit: Dictionary=w.pickups.filter(func(p):return p.get("retry_kit",false))[0];var score:=w.score
	w.pickups.assign([kit]) # Isolate the supply from adjacent authored fruit.
	w.player=Vector2(float(kit.x),0.);w.step(.01)
	check(w.weapon=="heavy" and w.score==score,"Pistol retry receives a physical zero-score safety supply")
	w.retry();check(w.pickups.any(func(p):return p.get("retry_kit",false) and str(p.id)!=str(kit.id)),"A later retry can receive supplies without reopening an authored crate")
	w=fresh()
	for i in 3:
		w.spawn_enemy("gnome",450.+i*40.,0.,i);w.damage_enemy(w.enemies[-1],1)
	check(w.kills==3 and w.chain==3 and w.best_chain==3 and w.score==375,"Distinct quick defeats award base score and bounded chain bonuses")
	var earned: int=w.score;w.damage_enemy(w.enemies[0],1);check(w.score==earned and w.chain==3,"A defeated ID never extends or pays a chain twice")
	var clock: float=w.chain_time;w.state="paused";w.step(2.);check(w.chain_time==clock,"Pause does not consume the chain window")
	w.state="playing";CampaignStyle.step(w,4.1);check(w.chain==0 and w.score==earned,"Chain expiry keeps earned base score")
	w.chain=4;w.chain_time=3.;w.invulnerable=0.;w.damage_player();check(w.chain==0 and w.score==earned,"Damage resets only the temporary chain")
	for section in ["shore","water","terrace","roots"]:
		w=AionCampaignWorld.new();w.begin("aion");w.run_seed=7719;w.load_section(section)
		check(w.enemies.all(func(e):return bool(e.mini) or bool(e.heavy) or int(e.hp)==1),"Normal enemies retain one hit: "+section)
		check(w.encounters.all(func(e):return int(e.variant)>=0 and int(e.variant)<=2),"Authored groups use bounded spacing variants: "+section)
		if section!="shore":check(w.encounters.size()==8,"Long routes have eight closer tactical groups: "+section)
		for x in CampaignRecovery.points(w):check(x>0. and w.floor_at(x)==0.,"Recovery flag has real floor support: "+section)
	w=fresh();w.load_section("shore");w.enemies.clear();w.gates.clear();w.npcs.clear();w.objects.clear()
	w.player=Vector2(5920.,-40.);w.velocity=Vector2.ZERO;CampaignRhythm.step(w)
	check(w.bridge_timers.has(5800.) and not w.disabled_platforms.has(5800.),"Bridge contact starts a warning, not an immediate fall")
	CampaignContent.step(w,1.);check(not w.disabled_platforms.has(5800.),"Bridge deck remains load-bearing during its warning")
	CampaignContent.step(w,1.5);check(w.disabled_platforms.has(5800.),"Warned deck really collapses after the countdown")
	w.retry();check(w.bridge_timers.is_empty() and not w.disabled_platforms.has(5800.),"Retry rebuilds the bridge for another fair attempt")
	for hero in AionCampaignWorld.HEROES:
		w=fresh();w.character=hero;w.load_section("shore");w.enemies.clear();w.objects.clear();w.npcs.clear();w.gates.clear();w.pickups.clear();w.player=Vector2(5700.,0.)
		var jumped:=false
		for tick in 330:
			w.move_axis=Vector2.RIGHT
			if w.grounded() and (not jumped or (w.player.x>6090. and w.player.x<6250.)):
				w.jump_press();w.jump_release();jumped=true
			w.step(1./60.)
			if w.player.x>6500.:break
		check(w.player.x>6470. and w.hp==3,"Actual move/jump rules cross the setpiece: "+hero)
	w=fresh();w.load_section("arena");w.enemies.clear();w.boss.active=true;w.boss.engaged=true;w.boss.phase=1
	var target:=Vector2(float(w.boss.x)-65.,-95.)
	w.bullets=[{"p":target-Vector2(100,0),"v":Vector2(760,0),"owner":"hero","kind":"pistol","damage":1,"pierce":0,"age":0.,"life":1.,"hit":[]}]
	w.step_bullets(.2)
	check(w.boss.hp==88 and int(w.boss.ports[0])==2,"Real projectile can damage a visible destructible boss port")
	w.boss.hp=50;w.boss.phase=2;w.boss.windup=.5;w.boss.wait=1.5
	var core:=Vector2(float(w.boss.x),-75.)
	check(CampaignBossPressure.core_damage(w,{"damage":1},core-Vector2(80,0),core+Vector2(80,0))==2,"Exposed-core aim earns an actual damage advantage")
	w.boss.hp=29;w.boss.phase=3;w.boss.attack=2;w.boss.wait=0.;w.boss.windup=0.;w.step_boss(.01)
	# 0.31.0: entering a phase first plays its announced stagger; the dash comes after it.
	check(float(w.boss.get("stagger",0.))>0. and float(w.boss.get("dash",0.))==0.,"Entering phase three staggers before any dash")
	w.boss.stagger=0.;w.boss.attack=2;w.boss.wait=0.;w.boss.windup=0.;w.step_boss(.01)
	check(float(w.boss.windup)>.9 and float(w.boss.get("dash",0.))==0.,"Final dash is telegraphed before motion or contact damage")
	w.boss.windup=.01;w.step_boss(.02);var before_x: float=w.boss.x
	w.player=Vector2(before_x-40.,-110.);w.invulnerable=0.;CampaignBossPressure.motion(w,.1)
	check(absf(float(w.boss.x)-before_x)>35. and w.boss.y==0. and w.hp==3,"Final boss really moves; a high jump avoids the charge")
	var game:=AionCampaignGame.new();root.add_child(game);await process_frame;game.set_process(false)
	game.presentation_stage="";game.menu_kind="";game.fade=-1.;game.application_active=true;game.audio_enabled=true;game.options.reduced_motion=false;game.world.state="playing"
	game.world.pending_events.append("enemy");game._process(.001)
	check(game.sound_cache.has("enemy") and game.impact_hold>0.,"Actual Game event path consumes defeat audio and bounded hit-stop: cache="+str(game.sound_cache.has("enemy"))+" hold="+str(game.impact_hold)+" motion="+str(game.motion_enabled)+" reduced="+str(game.options.reduced_motion))
	game.options.reduced_motion=true;game.impact_hold=0.;game.impact_cooldown=0.;game.world.pending_events.append("enemy");game._process(.01)
	check(game.impact_hold==0.,"Reduced motion disables hit-stop while the world remains playable")
	game.audio_enabled=false;game.sound_cache.erase("armour_hit");game.sound("armour_hit")
	check(not game.sound_cache.has("armour_hit"),"Audio-off also suppresses the new armour feedback")
	for locale in ["tr","en"]:
		for key in ["rally","bridge_warning","swap_weapon","gate_remaining","chain_bonus","boss_core","boss_dash"]:
			check(AionCampaignText.word(locale,key)!=key,"New gameplay feedback is translated: "+locale+"/"+key)
	game.touch_mode=true;game.menu_kind="";game.world.begin("aion");game.world.state="playing";game.world.weapon="heavy";game.language="tr"
	game.world.pickups.assign([{"id":"scale-offer","kind":"arc","x":140.,"y":-35.}])
	for dimensions in [Vector2i(320,568),Vector2i(393,873),Vector2i(844,390),Vector2i(1280,720)]:
		root.size=dimensions;await process_frame
		for scale in [1.,1.5,2.]:
			game.options.text_scale=scale;game.ui.theme=game.options.theme(game.FONT);game.resize();game.update_hud();await process_frame;await process_frame
			var context_rect: Rect2=game.ride_button.get_global_rect()
			var label: String=str(dimensions)+"/"+str(scale)
			check(game.ride_button.visible and game.ride_button.text==game.t("swap_weapon"),"Actual gun choice is laid out after its translated text: "+label)
			check(Rect2(Vector2.ZERO,Vector2(game.view_w,game.view_h)).encloses(context_rect),"Context touch action fits: "+label)
			for key in game.actions:
				check(not context_rect.intersects(game.actions[key].get_global_rect()),"Context action never overlaps manual touch routing: "+label+"/"+key)
			check(not context_rect.intersects(game.stick.get_global_rect()),"Context action stays clear of the joystick: "+label)
	game.queue_free();await process_frame
	print("RESULT: %d campaign rhythm checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
