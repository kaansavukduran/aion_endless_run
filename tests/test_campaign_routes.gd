extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+message)
func fresh(hero: String="aion") -> AionCampaignWorld:
	var w:=AionCampaignWorld.new();w.begin(hero);w.load_section("fork_one")
	return w
func _initialize() -> void:call_deferred("run")
func travel(w,upper: bool) -> Dictionary:
	# Isolated route geometry fixture: sentries are excluded explicitly so this
	# measures path reachability, not a claim of a full normal-input mission.
	w.enemies.clear()
	var count:=0
	var crawled:=false
	while w.state=="playing" and count<2400:
		# Lower route: crouch only once in the channel (the crawlway needs it),
		# and keep firing in the canopy yard to break the hatch lock.
		var in_channel: bool=CampaignRoutes.foot(w).y>1.
		w.move_axis=Vector2(1.,1. if (not upper and in_channel and w.section=="fork_one" and w.player.x<1200.) else 0.)
		if not upper and w.section=="fork_two" and not CampaignRoutes.hatch_open(w):
			if not w.fire_held:w.attack_press()
		elif w.fire_held:w.attack_release()
		if upper and w.grounded() and w.player.x<1000.:
			w.jump_press();w.jump_release()
		w.step(1./60.);count+=1
		if CampaignRoutes.low_ceiling(w):crawled=true
	return {"frames":count,"state":w.state,"target":w.travel_target,"foot":CampaignRoutes.foot(w),"crawled":crawled}

func middle_travel(w: AionCampaignWorld,drained: bool) -> void:
	# Isolated geometry fixture. Every jump and crawl uses the existing world
	# input methods and movement tick, not a forced destination or menu.
	w.enemies.clear()
	if drained:w.activated[CampaignRoutes.PUMP_ID]=true
	for frame in 1800:
		if w.state!="playing":return
		var foot:=CampaignRoutes.foot(w)
		w.move_axis=Vector2(1.,1. if foot.y>1. and foot.x<1204. else 0.)
		if w.grounded() and foot.x>=1204. and foot.x<1450. and foot.y>CampaignRoutes.MIDDLE_FLOOR:
			w.jump_press();w.jump_release()
		w.step(1./60.)

func auto_travel(game: AionCampaignGame,source: String,destination: String,reduced: bool=false,mounted: bool=false) -> void:
	game.presentation_stage="";game.menu_kind="";game.fade=-1.;game.application_active=true
	game.options.reduced_motion=reduced;game.world.load_section(source)
	game.world.enemies.clear();game.world.npcs.clear();game.world.gates.clear();game.world.pits.clear()
	game.world.score=1234;game.world.weapon="arc";game.world.ammunition=37
	if source=="fork_two":game.world.activated[CampaignRoutes.HATCH_ID]=true
	var gift: Dictionary={"id":"shore:keeper:supply","kind":"heavy","x":4000.,"y":-25.,"rescue_id":"shore:keeper","role":"keeper","from_bag":true}
	game.world.gift_drops["shore:keeper"]=gift.duplicate(true)
	game.world.mount={"available":mounted,"ridden":mounted,"x":1490.,"hp":1,"type":"skimmer"}
	var exit_y:=0.
	if CampaignRoutes.is_fork(source):
		exit_y=CampaignRoutes.UPPER_FLOOR if destination in ["canopy","terrace"] else (CampaignRoutes.MIDDLE_FLOOR if destination=="causeway" else CampaignRoutes.LOWER_FLOOR)
	game.world.player=Vector2(1490. if CampaignRoutes.is_fork(source) else game.world.length()-120.,exit_y-(42. if mounted else 0.))
	game.world.velocity=Vector2.ZERO
	game.set_action("attack","route-test",true)
	game.world.step(.001)
	check(game.world.state=="travel" and game.world.travel_target==destination,"Ordinary exit contact enters auto travel: "+source)
	var clock: float=game.world.time;var shots: int=game.world.shots;var ammunition: int=game.world.ammunition
	game.build_ui();game._process(.01)
	check(game.menu_kind=="" and game.buttons.is_empty(),"Travel never opens a Next or route-choice dialog: "+source)
	check(not game.world.fire_held and Dictionary(game.held.get("attack",{})).is_empty(),"Exit cancels a previously held attack")
	var button:=InputEventJoypadButton.new();button.button_index=game.pad.bindings.shoot;button.pressed=true;game._input(button)
	var key:=InputEventKey.new();key.keycode=KEY_SPACE;key.physical_keycode=KEY_SPACE;key.pressed=true;game._unhandled_input(key)
	game.set_action("attack","late-ui-press",true)
	check(not game.world.fire_held and not game.world.jump_held and game.held.is_empty(),"Input during fade cannot become a held action in the next section")
	var elapsed:=.01
	var exit_animation:=game.world.mount_transition=="exit"
	if mounted:
		var saved_exit:=AionCampaignWorld.new()
		check(saved_exit.restore(game.world.snapshot()) and saved_exit.mount_transition=="exit","A save during the dismount restores the same animation")
		for frame in 60:
			if saved_exit.advance_exit(.025):break
		saved_exit.finish_travel()
		check(saved_exit.section==destination and not saved_exit.mount.ridden,"A restored exit finishes once, on foot")
	var walked:=false
	var stood_on_exit_floor:=true
	var previous_x:=game.world.player.x
	while game.world.section==source and game.fade<0. and elapsed<1.4:
		game._process(.01);elapsed+=.01
		if game.world.mount_transition=="exit":exit_animation=true
		elif game.world.velocity.x>1.:
			walked=walked or (game.world.player.x>previous_x and M1CombatArt.body_spec(game.world).action=="walk")
			stood_on_exit_floor=stood_on_exit_floor and game.world.grounded() and is_equal_approx(game.world.player.y,exit_y)
		previous_x=game.world.player.x
	check(exit_animation==mounted and not game.world.mount.ridden,"Only a rider uses the visible vehicle exit animation: "+source)
	check(walked and stood_on_exit_floor and game.world.facing==1,"Hero walks right on the chosen lane before the fade: "+source)
	if mounted:check(float(game.world.mount.x)<game.world.player.x and int(game.world.mount.hp)==1,"The working vehicle is parked behind the walking hero")
	var fade_elapsed:=game.fade
	while game.fade>=0. and elapsed<1.8:
		game._process(.01);elapsed+=.01;fade_elapsed+=.01
	check(game.world.section==destination and game.world.state=="playing" and game.fade<0.,"Section actually opens automatically without a confirm press: "+destination)
	check(absf(fade_elapsed-(.1 if reduced else .36))<.025,"The fade still uses its short duration, including reduced motion")
	check(game.world.time==clock and game.world.shots==shots,"Fade advances neither gameplay time nor queued fire")
	check(game.world.score==1234 and game.world.weapon=="arc" and game.world.ammunition==ammunition,"Live combat inventory and score survive automatic travel")
	check(game.world.gift_drops.get("shore:keeper",{})==gift and not game.world.awarded.has("shore:keeper:gift"),"Unclaimed bag gift is preserved without an invisible award")
	check(not game.world.mount.ridden and game.world.player.y==game.world.floor_at(game.world.player.x),"New scene starts on foot")
	check(str(game.saved.get("checkpoint",""))==destination and Dictionary(game.saved.get("gift_drops",{})).has("shore:keeper"),"Destination checkpoint includes persistent unclaimed-drop state")
	check(game.held.is_empty() and not game.world.fire_held and not game.world.jump_held,"No source remains latched when the fade completes")
func route_structures() -> void:
	# fork_one: a standing body meets the pier wall; a crouched one crawls under it.
	var w:=fresh();w.enemies.clear();w.player=Vector2(700.,90.);w.velocity=Vector2.ZERO
	for frame in 90:w.move_axis=Vector2.RIGHT;w.step(1./60.)
	check(absf(w.player.x-(CampaignRoutes.PIER.position.x-CampaignRoutes.BODY_HALF_WIDTH))<.5,"A standing hero cannot walk into the low crawlway")
	check(w.notice=="arc_crawl_hint","Pressing into the crawl mouth shows the crouch hint")
	for frame in 60:w.move_axis=Vector2(1,1);w.step(1./60.)
	check(CampaignRoutes.low_ceiling(w) and w.crouching(),"Crouching enters the crawlway under its real ceiling")
	w.move_axis=Vector2.ZERO;w.step(1./60.)
	check(w.crouching() and absf(w.player.y-90.)<.1,"Releasing Down under the ceiling keeps the hero crouched instead of standing into it")
	var before_y: float=w.player.y;w.jump_press();w.jump_release();w.step(1./60.)
	check(absf(w.player.y-before_y)<.1 and w.velocity.y>=0.,"Jumping under the crawl ceiling is refused")
	check(w.player_hit_center().y>CampaignRoutes.CRAWL_CEILING,"The crouched hit centre fits below the ceiling")
	var frames:=0
	while CampaignRoutes.low_ceiling(w) and frames<900:w.move_axis=Vector2.RIGHT;w.step(1./60.);frames+=1
	w.move_axis=Vector2.ZERO;w.step(1./60.)
	check(not CampaignRoutes.low_ceiling(w) and not w.crouching() and w.player.x>CampaignRoutes.PIER.end.x,"Holding only Right crawls out and stands up once the ceiling ends")
	var back:=fresh();back.enemies.clear();back.player=Vector2(1250.,90.)
	for frame in 30:back.move_axis=Vector2.LEFT;back.step(1./60.)
	check(back.player.x>=CampaignRoutes.PIER.end.x+CampaignRoutes.BODY_HALF_WIDTH-.5,"The crawlway is a wall from the far side for a standing body, too")
	var rider:=fresh();rider.enemies.clear();rider.mount={"available":true,"ridden":true,"x":700.,"hp":1,"type":"skimmer"};rider.player=Vector2(700.,48.)
	for frame in 90:rider.move_axis=Vector2(1,1);rider.step(1./60.)
	check(rider.player.x<=CampaignRoutes.PIER.position.x-CampaignRoutes.BODY_HALF_WIDTH+.5,"A vehicle cannot enter the crawlway")
	var roof:=fresh();roof.enemies.clear();roof.player=Vector2(980.,-195.);roof.move_axis=Vector2(0,1);roof.jump_press();roof.jump_release()
	for frame in 90:roof.step(1./60.)
	check(absf(roof.player.y+195.)<.1 and roof.grounded(),"Down+Jump on the pier roof cannot fall through into the crawlway")
	var shot:=fresh();shot.enemies.clear();shot.bullets=[{"p":Vector2(760.,70.),"v":Vector2(-800.,-1200.),"owner":"enemy","age":0.,"kind":"seed","damage":1,"pierce":0,"hit":[],"life":2.}]
	shot.bullets[0].p=Vector2(990.,10.);shot.step(1./60.)
	check(shot.bullets.is_empty(),"The pier house blocks a shot inside its solid body")
	# fork_two: a closed hatch yard, a breakable lock and a failing service span.
	var yard:=fresh();yard.load_section("fork_two");yard.enemies.clear();yard.player=Vector2(1300.,0.)
	for frame in 60:yard.move_axis=Vector2.RIGHT;yard.step(1./60.)
	check(yard.player.x<=CampaignRoutes.YARD_END_X+.5 and CampaignRoutes.choice_at(yard)=="","The closed hatch yard ends at its fence without choosing a route")
	var lock: Dictionary=yard.objects.filter(func(o):return str(o.id)==CampaignRoutes.HATCH_ID)[0]
	for hit in 4:CampaignContent.hit_object(yard,Vector2(CampaignRoutes.HATCH_LOCK_X,-35.),1)
	check(bool(lock.active) and CampaignRoutes.hatch_open(yard) and yard.floor_at(1000.)==90.,"Breaking the root lock opens the hatch floor")
	for frame in 90:yard.move_axis=Vector2.ZERO;yard.step(1./60.)
	check(yard.grounded() and absf(yard.player.y-90.)<.1,"Standing over the opened hatch drops into the root channel")
	var restored:=AionCampaignWorld.new();restored.restore(yard.snapshot());restored.load_section("fork_two")
	check(CampaignRoutes.hatch_open(restored),"An opened hatch stays open after checkpoint restore")
	var span:=fresh();span.load_section("fork_two");span.enemies.clear();span.player=Vector2(620.,-140.);span.velocity=Vector2.ZERO
	span.step(1./60.);check(span.bridge_timers.has(CampaignRoutes.SERVICE_BRIDGE_X),"Stepping on the service span starts its visible collapse timer")
	for frame in 220:span.move_axis=Vector2.ZERO;span.step(1./60.)
	check(span.player.y>-1. and span.disabled_platforms.has(CampaignRoutes.SERVICE_BRIDGE_X),"Waiting on the failing span drops the hero to the yard, not into a pit")
	var recovery:=fresh("sheep");recovery.load_section("fork_two");recovery.enemies.clear()
	recovery.bridge_timers[CampaignRoutes.SERVICE_BRIDGE_X]=0.
	recovery.player=Vector2(605.,0.);recovery.step(.01)
	recovery.jump_press();recovery.jump_release()
	for frame in 70:recovery.step(1./60.)
	check(recovery.grounded() and absf(recovery.player.y+98.)<.1,"An ordinary jump lands on the exposed support after a collapsed span")
	recovery.jump_press();recovery.jump_release();recovery.move_axis=Vector2.RIGHT
	for frame in 48:recovery.step(1./60.)
	check(recovery.grounded() and absf(recovery.player.y+195.)<.1,"A second ordinary jump recovers the upper route without a charged ability")

func hatch_landmarks_and_rewards() -> void:
	var w:=fresh()
	check(CampaignRoutes.exit_flag_positions(w).size()==3 and Vector2(CampaignRoutes.EXIT_X,0.) in CampaignRoutes.exit_flag_positions(w),"All three physical coast exits have a flag on their actual elevation")
	check(Vector2(550.,CampaignRoutes.WALKWAYS[1].position.y) in CampaignRoutes.lantern_positions(w),"The coast lantern stays on its original step")
	w.load_section("fork_two");w.enemies.clear()
	var x:=CampaignRoutes.SERVICE_SUPPORT.get_center().x
	check(Vector2(x,CampaignRoutes.SERVICE_WALKWAYS[1].position.y) in CampaignRoutes.lantern_positions(w),"The approach lantern rests on the intact service span")
	w.bridge_timers[CampaignRoutes.SERVICE_BRIDGE_X]=0.
	w.step(.02)
	check(Vector2(x,CampaignRoutes.SERVICE_SUPPORT.position.y) in CampaignRoutes.lantern_positions(w),"The approach lantern follows the real support after collapse")
	check(CampaignRoutes.exit_flag_positions(w).size()==1 and CampaignRoutes.lantern_positions(w).size()==3,"The closed hatch hides the lower flag and its lantern")
	var fruit: Dictionary=w.pickups.filter(func(item):return item.id=="fork_two:route-fruit:8")[0]
	var supply: Dictionary=w.pickups.filter(func(item):return item.id=="fork_two:passage-supply")[0]
	check(not CampaignRoutes.pickup_exposed(w,fruit) and not CampaignRoutes.pickup_exposed(w,supply),"The closed hatch hides the lower fruit and supply")
	w.player=Vector2(float(supply.x),0.)
	check(not w.touches_pickup(supply),"The closed hatch prevents collecting its supply through solid ground")
	w.player=Vector2(float(fruit.x),0.)
	check(not w.touches_pickup(fruit),"The closed hatch prevents collecting its fruit through solid ground")
	var fruit_y:=float(fruit.y)
	w.buffs.magnet=1.
	w.step(.02)
	check(float(fruit.y)==fruit_y and not w.taken.has(fruit.id),"A magnet cannot pull lower fruit through the closed hatch")
	w.buffs.clear()
	for hit in 4:CampaignContent.hit_object(w,Vector2(CampaignRoutes.HATCH_LOCK_X,-35.),1)
	check(Vector2(CampaignRoutes.EXIT_X,CampaignRoutes.LOWER_FLOOR) in CampaignRoutes.exit_flag_positions(w),"Opening the hatch reveals the lower flag on the actual floor")
	check(Vector2(1530.,CampaignRoutes.LOWER_FLOOR) in CampaignRoutes.lantern_positions(w),"Opening the hatch places the lower lantern on its floor")
	check(CampaignRoutes.pickup_exposed(w,fruit) and CampaignRoutes.pickup_exposed(w,supply),"Opening the hatch reveals the same fruit and supply")
	var restored:=AionCampaignWorld.new()
	check(restored.restore(w.snapshot()) and CampaignRoutes.exit_flag_positions(restored).size()==2 and CampaignRoutes.pickup_exposed(restored,fruit),"An open checkpoint restores the exposed passage markers and rewards")
	w.player=Vector2(float(fruit.x),w.floor_at(float(fruit.x)))
	w.step(.02)
	check(w.taken.has(fruit.id),"The same fruit is collectible when the open hatch exposes its floor")
	w.player=Vector2(float(supply.x),w.floor_at(float(supply.x)))
	w.step(.02)
	check(w.taken.has(supply.id),"The open lower passage still grants its supply")

func pump_and_cage() -> void:
	var w:=fresh()
	w.enemies.clear()
	check(CampaignRoutes.DRY_CACHE_DECK not in w.platforms and not w.pickups.any(func(item):return item.id==CampaignRoutes.DRY_CACHE_ID),"The service shelf and cache are absent before draining")
	var cage: Dictionary=w.objects.filter(func(o):return str(o.id)==CampaignRoutes.TECHNICIAN_CAGE_ID)[0]
	var keeper: Dictionary=w.npcs.filter(func(n):return str(n.id)==CampaignRoutes.TECHNICIAN_ID)[0]
	w.player=Vector2(1224.,90.)
	check(not w.interact() and not bool(cage.active),"The occupied closed cage cannot be mistaken for a trap")
	w.attack_press();w.attack_release()
	for frame in 32:w.step(1./60.)
	check(bool(cage.active),"An ordinary gun press opens the technician's cage")
	w.attack_press()
	check(w.rescue_target==CampaignRoutes.TECHNICIAN_ID,"Normal close rescue action reaches the technician behind the open cage")
	w.attack_release()
	for frame in 45:w.step(1./60.)
	check(bool(keeper.freed),"The technician is freed after the normal rescue timing")
	for frame in 160:w.step(1./60.)
	var gift: Dictionary=w.gift_drops.get(CampaignRoutes.TECHNICIAN_ID,{})
	check(w.activated.has(CampaignRoutes.PUMP_PART_ID) or (not gift.is_empty() and gift.kind=="relay_part"),"The ordinary bag handover produces a real relay part")
	if not gift.is_empty():
		w.player=Vector2(float(gift.x),w.floor_at(float(gift.x)))
		w.step(.05)
	check(w.activated.has(CampaignRoutes.PUMP_PART_ID) and w.taken.has(CampaignRoutes.TECHNICIAN_ID+":supply"),"Touching the named gift records its part and one-time collection")
	w.player=Vector2(CampaignRoutes.PUMP_X,90.)
	check(CampaignRoutes.context_action(w)=="arc_run_pump" and w.interact() and CampaignRoutes.pump_open(w),"The context action activates the lower pump after collecting its part")
	check(w.floor_at(CampaignRoutes.DRY_START+5.)==CampaignRoutes.DRY_FLOOR,"The open pump reveals the deeper supported dry floor")
	check(Vector2(CampaignRoutes.DRY_EXIT_X,CampaignRoutes.DRY_FLOOR) in CampaignRoutes.exit_flag_positions(w),"The lower route flag moves behind the drained alcove")
	w.player=Vector2(CampaignRoutes.EXIT_X+10.,CampaignRoutes.DRY_FLOOR)
	check(CampaignRoutes.choice_at(w).is_empty(),"The wet exit does not skip the open service room")
	w.player=Vector2(1588.,CampaignRoutes.DRY_CACHE_DECK.position.y)
	var cache_score:=w.score
	w.step(1./60.)
	check(w.grounded() and w.taken.has(CampaignRoutes.DRY_CACHE_ID) and w.score==cache_score+500,"Landing on the dry shelf collects its points by contact")
	w.player=Vector2(CampaignRoutes.DRY_EXIT_X+10.,CampaignRoutes.DRY_FLOOR)
	check(CampaignRoutes.choice_at(w)=="water","The drained passage still leads onward to the water route")
	check(not w.interact(),"An already running pump cannot award a second interaction")
	w.player=Vector2(float(cage.x)+35.,90.)
	check(CampaignRoutes.context_action(w)=="arc_arm_cage" and w.interact(),"The freed cage accepts one visible trap setup")
	w.spawn_enemy("gnome",float(cage.x)+29.,90.,910)
	w.spawn_enemy("gnome",float(cage.x)+30.,90.,911)
	w.step(.02)
	check(w.enemies[0].defeated and not w.enemies[1].defeated and w.activated.has(CampaignRoutes.TECHNICIAN_CAGE_ID+":trap-spent"),"The cage catches one eligible ground enemy and is spent")
	var restored:=AionCampaignWorld.new()
	check(restored.restore(w.snapshot()) and CampaignRoutes.pump_open(restored) and restored.activated.has(CampaignRoutes.TECHNICIAN_CAGE_ID+":trap-spent"),"Pump and spent cage survive actual snapshot restore")
	check(CampaignRoutes.DRY_CACHE_DECK in restored.platforms and restored.taken.has(CampaignRoutes.DRY_CACHE_ID) and not restored.pickups.any(func(item):return item.id==CampaignRoutes.DRY_CACHE_ID),"The dry shelf survives restoration and its claimed cache stays claimed")
	var old:=fresh()
	for deck in CampaignRoutes.MIDDLE_WALKWAYS:old.platforms.erase(deck)
	old.npcs.clear()
	old.objects.erase(old.objects.filter(func(o):return str(o.id)==CampaignRoutes.TECHNICIAN_CAGE_ID)[0])
	check(restored.restore(old.snapshot()) and CampaignRoutes.MIDDLE_WALKWAYS.all(func(deck):return deck in restored.platforms) and restored.npcs.size()==1,"An exact older fork encounter restores the new walkways and single named technician")
	var causeway:=fresh();causeway.load_section("causeway")
	var vacant: Dictionary=causeway.objects.filter(func(o):return o.id=="causeway:tactic:0")[0]
	check(bool(vacant.active) and vacant.x==990. and causeway.npcs.all(func(n):return n.get("cage","")!=vacant.id),"An authored empty cage stays beside its Causeway approach and holds no NPC")
	causeway.player=Vector2(958.,causeway.floor_at(958.))
	check(causeway.interact() and causeway.activated.has(vacant.id+":trap-set"),"The empty Causeway cage can be set by the ordinary action while grounded in the basin")

func junction_rewards() -> void:
	var w:=fresh()
	w.enemies.clear()
	w.ammunition=5
	w.grenades=1
	w.player=Vector2(930.,CampaignRoutes.UPPER_FLOOR)
	w.step(1./60.)
	w.player=Vector2(1280.,CampaignRoutes.UPPER_FLOOR)
	w.step(1./60.)
	check(w.ammunition>5 and w.grenades>1 and CampaignRoutes.UPPER_SUPPLY.all(func(item):return w.taken.has(item.id)),"The upper deck pays out real ammunition and grenades on contact")
	var restored:=AionCampaignWorld.new()
	check(restored.restore(w.snapshot()) and CampaignRoutes.UPPER_SUPPLY.all(func(item):return restored.taken.has(item.id)),"Upper supply claims persist through Continue")
	check(not restored.pickups.any(func(item):return item.id.begins_with("fork_one:upper:")),"The upper supplies do not reappear after claiming them")
	w.load_section("causeway")
	var patrol: Array=w.encounters.filter(func(encounter):return encounter.role==CampaignRoutes.CAUSEWAY_PATROL)[0].enemies
	w.gates.append({"x":3020.,"ids":patrol})
	check(restored.restore(w.snapshot()) and restored.gates.is_empty(),"Continuing an old Causeway encounter removes its former fight lock")
	var members: Array=restored.enemies.filter(func(enemy):return enemy.id in patrol)
	for i in members.size():
		var enemy: Dictionary=members[i]
		for hit in int(enemy.armour)+1:restored.damage_enemy(enemy,999)
		check(restored.awarded.has(CampaignRoutes.CAUSEWAY_REWARD_ID)==(i==members.size()-1),"Causeway bonus requires all patrol members")
	var score:=restored.score
	CampaignRoutes.reward_causeway_patrol(restored,str(members[-1].id))
	check(restored.score==score and restored.notice=="arc_route_patrol_clear","The patrol bonus appears once with clear feedback")
	check(restored.restore(restored.snapshot()) and restored.awarded.has(CampaignRoutes.CAUSEWAY_REWARD_ID),"Causeway bonus ownership survives save/continue")
	w.gates.clear()
	w.player=Vector2(w.length()-220.,w.floor_at(w.length()-220.))
	w.invulnerable=10.
	w.move_axis=Vector2.RIGHT
	for frame in 80:
		if w.state!="playing":break
		w.step(1./60.)
	check(w.travel_target=="relay" and w.enemies.any(func(enemy):return enemy.id in patrol and not enemy.defeated),"The Causeway can be crossed with the optional patrol still active")

func shelter_route() -> void:
	var w:=fresh();w.load_section("shore")
	w.enemies.clear()
	w.player=Vector2(1074.,w.floor_at(1074.))
	w.invulnerable=0.
	w.spawn_enemy("crow",1074.,-185.,941)
	var crow: Dictionary=w.enemies.front()
	var roof: Rect2=CampaignRoutes.SHELTERS.shore[0]
	check(w.platforms.has(roof) and CampaignRoutes.crow_sheltered(w,w.player),"The cover art is anchored to a real shore platform and protects the standing lane")
	check(CampaignRoutes.crow_roof_hit(w,Vector2(1074.,-185.),Vector2(1074.,-25.)),"A fast descending segment intersects the cover roof before it reaches the player")
	check(not CampaignRoutes.crow_roof_hit(w,Vector2(1210.,-185.),Vector2(1210.,-25.)) and not CampaignRoutes.crow_sheltered(w,Vector2(1210.,0.)),"The physical cover leaves the adjacent exposed lane vulnerable")
	w.enemy_shot(crow)
	for frame in 35:w.step_enemies(1./60.)
	check(w.hp==1 and is_zero_approx(float(crow.dive)) and float(crow.y)<roof.position.y,"An actual shore crow attack stops its dive above the roof")
func run() -> void:
	for section in CampaignRoutes.FORKS:
		var w:=fresh();w.load_section(section)
		check(w.state=="playing","Fork starts as live physics, not a choice state: "+section)
		check(w.platforms.size()==(5 if section=="fork_one" else 3) and w.pits.is_empty(),"Junction has authored reachable stairs and a real lower floor")
		for surface in w.platforms:
			check(surface.size.x>=130. and surface.size.y>0.,"Route decks are actual one-way collision geometry")
		if section=="fork_one":check(w.floor_at(500.)==0. and w.floor_at(900.)==90.,"Material step matches actual floor heights")
		else:check(w.floor_at(500.)==0. and w.floor_at(1000.)==0.,"The canopy yard floor is closed until its hatch opens")
		for high in [false,true]:
			w=fresh();w.load_section(section)
			var result:=travel(w,high)
			var expected: String=("canopy" if high else "water") if section=="fork_one" else ("terrace" if high else "roots")
			check(result.state=="travel" and result.target==expected,"Actual movement chooses "+expected+" without a modal")
			if not high and section=="fork_one":check(result.crawled,"The water route is entered by actually crawling under the pier")
			if not high and section=="fork_two":check(CampaignRoutes.hatch_open(w),"The roots route opened its hatch by breaking the lock")
			check(w.route.has(expected),"Crossing exit records the real route once")
			w.finish_travel();check(w.section==expected and w.state=="playing","Physical route loads its actual destination")
	for hero in AionCampaignWorld.HEROES:
		for drained in [false,true]:
			var middle:=fresh(hero);middle_travel(middle,drained)
			check(middle.travel_target=="causeway","A sequence of normal jumps reaches the middle causeway for "+hero+" / drained "+str(drained))
		for section in CampaignRoutes.FORKS:
			for high in [true,false]:
				var w:=fresh(hero);w.load_section(section);var result:=travel(w,high)
				var expected: String=("canopy" if high else "water") if section=="fork_one" else ("terrace" if high else "roots")
				check(result.target==expected,"Every current hero completes "+expected+" by ordinary movement: "+hero)
	var w:=fresh();w.enemies.clear();w.player=Vector2(1550.,-300.);w.velocity=Vector2.ZERO
	check(CampaignRoutes.choice_at(w)=="","Flying across a doorway cannot choose a path before landing")
	w.player=Vector2(1550.,-195.);check(w.grounded() and CampaignRoutes.choice_at(w)=="canopy","Upper exit is activated by actual feet on its deck")
	w=fresh();w.player=Vector2(1550.,90.);check(w.grounded() and CampaignRoutes.choice_at(w)=="water","Lower exit uses the lower collision floor")
	var dropper:=fresh();dropper.enemies.clear();dropper.player=Vector2(1300.,-195.);dropper.move_axis=Vector2(1,1)
	dropper.step(.05);check(absf(dropper.player.y+195.)<.1 and dropper.crouching(),"Down alone crawls on the upper deck without silently choosing the lower path")
	dropper.move_axis=Vector2(0,1);dropper.jump_press();dropper.jump_release()
	for frame in 90:dropper.step(1./60.)
	check(dropper.grounded() and absf(dropper.player.y-44.)<.1,"Down+Jump drops from the upper bridge to the real middle step")
	dropper.jump_press();dropper.jump_release()
	for frame in 55:dropper.step(1./60.)
	check(dropper.grounded() and absf(dropper.player.y-90.)<.1,"A second Down+Jump descends from the middle step to the lower channel")
	check(dropper.state=="playing" and CampaignRoutes.choice_at(dropper)=="","Dropping between lanes does not secretly select a route before its exit")
	check(CampaignRoutes.camera_y(w,0.)==90.,"Lower channel camera follows its real foot height instead of hiding the hero under controls")
	var high_camera:=fresh();high_camera.player=Vector2(1300.,CampaignRoutes.UPPER_FLOOR)
	check(CampaignRoutes.camera_y(high_camera,0.)< -130.,"Camera climbs to frame the actual upper passage")
	var lip_camera:=fresh();lip_camera.player=Vector2(635.,0.)
	check(CampaignRoutes.camera_y(lip_camera,0.)>10.,"Camera starts showing the lower landing before the entry ledge")
	w.mount.ridden=true;w.player.y=48.;check(CampaignRoutes.camera_y(w,0.)==90.,"Rider camera follows vehicle contact feet, not a different mounted offset")
	w.mount.ridden=false;w.player.y=90.
	for mounted in [false,true]:
		var ledge:=fresh();ledge.enemies.clear();ledge.player=Vector2(651.,48. if mounted else 90.)
		ledge.mount={"available":mounted,"ridden":mounted,"x":651.,"hp":1,"type":"skimmer"}
		ledge.move_axis=Vector2.LEFT;ledge.step(.05)
		check(ledge.player.x>=CampaignRoutes.DROP_X and absf(CampaignRoutes.foot(ledge).y-90.)<.1,"Walking back into the ledge cannot teleport actor or vehicle up90 pixels")
		if not mounted:
			ledge.jump_press();ledge.jump_release()
			for frame in 42:ledge.move_axis=Vector2.LEFT;ledge.step(1./60.)
			check(ledge.player.x<CampaignRoutes.DROP_X and absf(ledge.player.y)<.1,"The lower ledge remains physically climbable by jumping back")
	var diver:=fresh();diver.mount={"available":true,"ridden":true,"x":1490.,"hp":1,"type":"shell","dive":.5};diver.player=Vector2(1490.,72.)
	check(diver.grounded() and CampaignRoutes.choice_at(diver)=="water","A diving shell uses the same contact feet for route selection and physics")
	for deck in [90.,-195.]:
		var rider:=fresh();rider.enemies.clear();rider.mount={"available":true,"ridden":true,"x":1200.,"hp":1,"type":"skimmer"};rider.player=Vector2(1200.,deck-42.);rider.velocity=Vector2.ZERO
		var exited: bool=rider.interact()
		check(exited,"Vehicle can actually exit on fork support height "+str(deck))
		if exited:
			for frame in 32:rider.step(1./60.)
			check(rider.grounded() and absf(rider.player.y-deck)<.1,"Exit ends on the actual fork deck, not Y0")
			var view:=AionCampaignView.new();view.world=rider
			check(absf(view.vehicle_draw_position().y-deck)<.1,"Unridden vehicle rests on the same actual support as its rider")
			view.free()
			check(rider.interact(),"Parked fork vehicle can be boarded again at the same height")
			for frame in 32:rider.step(1./60.)
			check(rider.mount.ridden and absf(rider.player.y+42.-deck)<.1,"Reboarding preserves the real hull floor")
	route_structures()
	hatch_landmarks_and_rewards()
	pump_and_cage()
	junction_rewards()
	shelter_route()
	var snap:=w.snapshot();var restored:=AionCampaignWorld.new();check(restored.restore(snap) and restored.section=="fork_one" and restored.state=="playing","A junction checkpoint restores into gameplay")
	var game:=AionCampaignGame.new();root.add_child(game);await process_frame;game.set_process(false)
	game.world.load_section("fork_one");game.menu_kind="";game.build_ui();await process_frame;await process_frame
	check(not game.ui.find_children("Route_*","Button",true,false).size(),"No route-choice button exists in the live junction UI")
	for pair in [["shore","quay"],["quay","fork_one"],["fork_one","causeway"],["causeway","relay"],["canopy","fork_two"],["roots","relay"],["relay","arena"]]:auto_travel(game,str(pair[0]),str(pair[1]))
	auto_travel(game,"fork_one","water",false,true)
	auto_travel(game,"fork_one","canopy",false,true)
	auto_travel(game,"quay","fork_one",false,true)
	auto_travel(game,"fork_two","roots",true)
	game.world.load_section("fork_one");game.world.player=Vector2(1490.,90.);game.world.velocity=Vector2.ZERO;CampaignRoutes.step(game.world)
	game.fade=-1.;game.application_active=false
	var frozen_position:=game.world.player
	game._process(.05)
	check(game.fade<0. and game.world.section=="fork_one" and game.world.player==frozen_position,"Focus loss freezes the walk before the fade")
	game.application_active=true
	for tick in 120:
		game._process(.01)
		if game.world.section=="water" and game.fade<0.:break
	check(game.world.section=="water" and game.fade<0.,"Focused travel resumes safely from the same route contact")
	game.queue_free();await process_frame
	print("RESULT: ",checks," physical route checks, ",failures," failures");quit(1 if failures else 0)
