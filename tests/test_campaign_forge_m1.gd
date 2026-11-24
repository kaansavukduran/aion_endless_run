extends SceneTree
var checks:=0
var failures:=0

func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+message)

func clean(hero: String="aion") -> AionCampaignWorld:
	var w:=AionCampaignWorld.new();w.begin(hero)
	w.enemies.clear();w.objects.clear();w.hazards.clear();w.zones.clear();w.encounters.clear();w.gates.clear();w.npcs.clear();w.crates.clear();w.pickups.clear();w.platforms.clear();w.pits.clear()
	w.state="playing";w.invulnerable=0.;return w

func _initialize() -> void:call_deferred("run")

func run() -> void:
	# 1. Compressed leaf routes & authored LEAF_PLANS
	for leaf in ["water","terrace","roots"]:
		var w:=AionCampaignWorld.new();w.begin("aion");w.load_section(leaf)
		check(w.length()<=16000.,"Leaf route is compressed to eliminate dead walks: "+leaf)
		check(w.encounters.size()==8,"Leaf route keeps 8 authored encounters: "+leaf)
		check(w.encounters.all(func(e):return not str(e.get("role","")).is_empty()),"Every leaf encounter has an authored role: "+leaf)
		check(w.zones.size()==2 and w.hazards.size()==3,"Leaf route has dual environmental zones and 3 hazards: "+leaf)
		check(w.rooms.size()==2,"Leaf route keeps 2 optional secret rooms: "+leaf)

	# 2. Authored MAIN_PLANS & shore bridge preservation
	for pair in [["shore",4],["quay",4],["canopy",2],["relay",4]]:
		var sec: String=str(pair[0])
		var w:=AionCampaignWorld.new();w.begin("aion");w.load_section(sec)
		check(w.encounters.size()==int(pair[1]),"Main section keeps authored encounter count: "+sec)
		check(w.encounters.all(func(e):return not str(e.get("role","")).is_empty()),"Main section encounters have authored roles: "+sec)
		if sec=="shore":
			check(w.pits.any(func(p):return is_equal_approx(p.x,5840.) and is_equal_approx(p.y,6440.)),"Shore crumbling bridge setpiece remains intact")

	# 3. Enemy 4-stage readability: burrow emerge_warn, spawn contact fairness, recovery pause, assist hidden skip
	var w:=clean()
	w.spawn_enemy("burrow",500.,0.,1)
	var b: Dictionary=w.enemies[0];b.age=1.1;b.active=true
	CampaignEnemies.step(w,b,.05)
	check(bool(b.get("emerge_warn",false)) and CampaignEnemies.hidden(b),"Burrow telegraphs emerge_warn before surfacing")
	CampaignAssists.summon(w,"owl_feather")
	check(CampaignAssists.target(w,w.assists[0]).is_empty(),"Assists do not waste attacks targeting hidden burrow enemies")

	w=clean();w.player=Vector2(400.,0.);w.spawn_enemy("leech",410.,0.,2)
	var l: Dictionary=w.enemies[0];l.age=0.1;l.active=true
	CampaignEnemies.step(w,l,.05)
	check(w.hp==1 and w.attempts_remaining==3,"Freshly activated enemy does not deal instant spawn-frame contact damage")
	l.age=1.0;CampaignEnemies.attack(w,l)
	check(float(l.get("recover",0.))>0.,"Enemy attack enters an explicit recovery punish window")

	# 4. Kok Motoru phase shift, Phase 3 post-dash recovery, and victory cleanup
	w=clean();w.load_section("arena");w.boss.active=true;w.boss.engaged=true;w.boss.clock=1.0;w.boss.hp=55;w.boss.phase=1;w.boss.beam_warning=0.8
	w.step_boss(.05)
	check(int(w.boss.phase)==2 and float(w.boss.get("shift_pause",0.))>0. and float(w.boss.beam_warning)==0.,"Boss phase shift triggers shift_pause and clears stale beam warning")

	w.boss.phase=3;w.boss.hp=20;w.boss.shift_pause=0.;w.boss.dash=0.04;w.boss.dash_direction=-1.
	CampaignBossPressure.motion(w,.05)
	check(float(w.boss.get("recover",0.))>0.,"Phase 3 dash ends with a clear recovery punish window")

	w.bullets.append({"p":Vector2(300.,-30.),"v":Vector2(-100.,0.),"owner":"enemy","age":0.,"kind":"seed","damage":1,"pierce":0,"hit":[]})
	w.hazards.append({"id":"arena:haz","kind":"vines","x":400.,"clock":1.,"phase":1.,"warn":false})
	w.spawn_enemy("drone",600.,-120.,50)
	w.damage_boss(50)
	check(w.state=="victory" and w.completed and w.hazards.is_empty() and w.bullets.is_empty() and w.enemies[0].defeated,"Boss defeat clears enemy bullets, hazards and summoned drones cleanly")

	# 5. Coyote time & jump buffer (and strict low_ceiling guard)
	w=clean("aion");w.platforms.append(Rect2(100.,-80.,200.,20.));w.player=Vector2(298.,-80.);w.velocity=Vector2.ZERO
	w.step(.016) # Grounded on platform -> arms coyote_timer
	w.player.x=320. # Walk off platform ledge
	w.step(.04) # Still within 0.09s coyote window
	w.jump_press()
	check(w.velocity.y<0. and w.jumps==1,"Coyote time grants a reliable grounded jump just after leaving a ledge")

	w=clean("aion");w.player=Vector2(400.,-25.);w.velocity=Vector2(0.,450.);w.jumps=AionCampaignWorld.AION_JUMPS
	w.jump_press() # Buffer jump right before landing
	check(w.jump_buffer_timer>0.,"Pre-landing jump press arms jump_buffer_timer")
	w.step(.05);w.step(.05)
	check(w.velocity.y<0. and w.jumps==1,"Buffered jump launches cleanly upon touchdown")

	w=clean("aion");w.load_section("fork_one");w.enemies.clear();w.player=Vector2(950.,90.);w.velocity=Vector2.ZERO
	w.step(.016);w.jump_press()
	check(w.velocity.y==0. and w.jump_buffer_timer==0.,"Low ceiling strictly blocks coyote and buffered jumps")

	# 6. HUD combat-priority order & dirty-state caching
	var game:=AionCampaignGame.new();game.language="en";root.add_child(game);await process_frame;game.set_process(false)
	game.world.begin("aion");game.world.state="playing";game.hud_panel.refresh()
	var sig1: String=game.hud_panel.last_signature
	check(game.hud_panel.summary.begins_with(game.t("reserve_lives")),"HUD places combat-critical reserve first in hierarchy")
	game.hud_panel.refresh()
	check(game.hud_panel.last_signature==sig1,"HUD dirty-state cache stays stable when world state is unchanged")
	game.world.hp=2;game.hud_panel.refresh()
	check(game.hud_panel.last_signature!=sig1,"HUD dirty-state cache invalidates immediately on HP change")
	game.queue_free();await process_frame

	# 7. fork_two locked/unlocked hatch, common-area authored tactics & NPC rescue clips/anti-dup
	w=clean("aion");w.load_section("fork_two")
	check(not CampaignRoutes.hatch_open(w) and is_equal_approx(w.floor_at(980.),0.),"Locked fork_two hatch holds upper floor before unlock")
	check(CampaignRoutes.clamp_horizontal(w,980.,CampaignRoutes.EXIT_X)<=CampaignRoutes.YARD_END_X,"Locked fork_two hatch blocks lower passage")
	for _hit in 4:CampaignContent.hit_object(w,Vector2(CampaignRoutes.HATCH_LOCK_X,-35.),1)
	w.player=Vector2(980.,w.floor_at(980.));w.velocity=Vector2.ZERO
	check(CampaignRoutes.hatch_open(w) and is_equal_approx(w.player.y,CampaignRoutes.LOWER_FLOOR) and w.grounded(),"Unlocked fork_two hatch supports grounded lower channel")

	for sec in ["shore","quay","canopy","relay"]:
		w=clean("aion");w.load_section(sec)
		check(w.objects.any(func(o):return str(o.id).begins_with(sec+":tactic:")),"Authored common-area tactical prop exists in "+sec)
		check(not w.pickups.any(func(p):return str(p.id).begins_with(sec+":fruit:")),"Uniform fruit grid wallpaper removed from "+sec)

	w=clean("aion");w.load_section("shore");w.enemies.clear();w.gates.clear()
	var npc: Dictionary=w.npcs[0];var nid: String=str(npc.id)
	check(str(npc.get("clip",""))=="idle_bound","Bound NPC starts in idle_bound clip")
	w.rescue(npc);CampaignRescue.step(w,.05)
	check(str(npc.get("clip",""))=="rescue_react","Newly freed NPC enters rescue_react clip")
	CampaignRescue.step(w,.4)
	check(str(npc.get("clip",""))=="free_roam","Freed NPC transitions to free_roam clip")
	w.player=Vector2(float(npc.x),float(npc.y));CampaignRescue.step(w,.05)
	check(str(npc.get("clip",""))=="salute_thanks","Contacted NPC enters salute_thanks clip")
	CampaignRescue.step(w,.95)
	check(str(npc.get("clip",""))=="drop_gift" and w.gift_drops.has(nid),"NPC transitions to drop_gift and spawns supply")
	w.taken[nid+":supply"]=true;w.gift_drops.erase(nid)
	w.load_section("shore")
	check(not w.gift_drops.has(nid) and not w.pickups.any(func(p):return str(p.id)==nid+":supply"),"Reloading section never duplicates already-taken NPC gift")

	# 8. Character-select preview states & pause/step/guides diagnostic hooks
	var prev:=RunnerHeroPreview.new()
	check(prev.PLAYABLE_HEROES==["aion","sheep","rabbit","eren"],"Preview preserves exact 4-hero playable roster")
	for st in ["idle","focus","select","launch"]:
		prev.set_select_state(st)
		check(prev.select_state==st,"Hero preview accepts select state: "+st)
	prev.set_paused(true)
	var f1: int=prev.step_frame(1);var f2: int=prev.step_frame(1);var f0: int=prev.step_frame(-2)
	check(prev.paused and f1==1 and f2==2 and f0==0,"Hero preview pauses and steps frames deterministically")
	prev.show_guides=true
	check(prev.show_guides,"Hero preview diagnostic pivot/hitbox overlay toggles cleanly")
	prev.free()

	# 9. Unified gamepad B / Esc submenu back navigation
	var g2:=AionCampaignGame.new();g2.language="tr";root.add_child(g2);await process_frame;g2.set_process(false)
	g2.menu_previous="paused";g2.menu_kind="settings";g2.build_ui()
	check(g2.menu_back() and g2.menu_kind=="paused","Back from settings returns to paused menu")
	g2.menu_kind="result_details";g2.build_ui()
	check(g2.menu_back() and g2.menu_kind=="complete","Back from result_details returns to complete summary")
	g2.queue_free();await process_frame

	print("RESULT: %d forge M1 checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
