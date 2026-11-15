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
	while w.state=="playing" and count<1800:
		w.move_axis=Vector2.RIGHT
		if upper and w.grounded() and w.player.x<1000.:
			w.jump_press();w.jump_release()
		w.step(1./60.);count+=1
	return {"frames":count,"state":w.state,"target":w.travel_target,"foot":CampaignRoutes.foot(w)}

func auto_travel(game: AionCampaignGame,source: String,destination: String,reduced: bool=false,mounted: bool=false) -> void:
	game.presentation_stage="";game.menu_kind="";game.fade=-1.;game.application_active=true
	game.options.reduced_motion=reduced;game.world.load_section(source)
	game.world.enemies.clear();game.world.npcs.clear();game.world.gates.clear();game.world.pits.clear()
	game.world.score=1234;game.world.weapon="arc";game.world.ammunition=37
	var gift: Dictionary={"id":"shore:keeper:supply","kind":"heavy","x":4000.,"y":-25.,"rescue_id":"shore:keeper","role":"keeper","from_bag":true}
	game.world.gift_drops["shore:keeper"]=gift.duplicate(true)
	game.world.mount={"available":mounted,"ridden":mounted,"x":1490.,"hp":2,"type":"skimmer"}
	var exit_y: float=90. if CampaignRoutes.is_fork(source) else 0.
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
	while game.fade>=0. and elapsed<.6:
		game._process(.01);elapsed+=.01
	check(game.world.section==destination and game.world.state=="playing" and game.fade<0.,"Section actually opens automatically without a confirm press: "+destination)
	check(absf(elapsed-(.1 if reduced else .36))<.025,"Auto travel has a short bounded duration, including reduced motion")
	check(game.world.time==clock and game.world.shots==shots,"Fade advances neither gameplay time nor queued fire")
	check(game.world.score==1234 and game.world.weapon=="arc" and game.world.ammunition==ammunition,"Live combat inventory and score survive automatic travel")
	check(game.world.gift_drops.get("shore:keeper",{})==gift and not game.world.awarded.has("shore:keeper:gift"),"Unclaimed bag gift is preserved without an invisible award")
	check(game.world.mount.ridden==mounted and (not mounted or game.world.mount.hp==2),"Automatic travel carries the actual damaged vehicle")
	check(str(game.saved.get("checkpoint",""))==destination and Dictionary(game.saved.get("gift_drops",{})).has("shore:keeper"),"Destination checkpoint includes persistent unclaimed-drop state")
	check(game.held.is_empty() and not game.world.fire_held and not game.world.jump_held,"No source remains latched when the fade completes")
func run() -> void:
	for section in CampaignRoutes.FORKS:
		var w:=fresh();w.load_section(section)
		check(w.state=="playing","Fork starts as live physics, not a choice state: "+section)
		check(w.platforms.size()==3 and w.pits.is_empty(),"Junction has authored reachable stairs and a real lower floor")
		for surface in w.platforms:
			check(surface.size.x>=200. and surface.size.y>0.,"Upper route is actual one-way collision geometry")
		check(w.floor_at(500.)==0. and w.floor_at(900.)==90.,"Material step matches actual floor heights")
		for high in [false,true]:
			w=fresh();w.load_section(section)
			var result:=travel(w,high)
			var expected: String=("canopy" if high else "water") if section=="fork_one" else ("terrace" if high else "roots")
			check(result.state=="travel" and result.target==expected,"Actual movement chooses "+expected+" without a modal")
			check(w.route.has(expected),"Crossing exit records the real route once")
			w.finish_travel();check(w.section==expected and w.state=="playing","Physical route loads its actual destination")
	for hero in AionCampaignWorld.HEROES:
		var w:=fresh(hero);var result:=travel(w,true)
		check(result.target=="canopy","Every current hero can climb the upper stairs: "+hero)
	var w:=fresh();w.enemies.clear();w.player=Vector2(1550.,-300.);w.velocity=Vector2.ZERO
	check(CampaignRoutes.choice_at(w)=="","Flying across a doorway cannot choose a path before landing")
	w.player=Vector2(1550.,-195.);check(w.grounded() and CampaignRoutes.choice_at(w)=="canopy","Upper exit is activated by actual feet on its deck")
	w=fresh();w.player=Vector2(1550.,90.);check(w.grounded() and CampaignRoutes.choice_at(w)=="water","Lower exit uses the lower collision floor")
	var dropper:=fresh();dropper.enemies.clear();dropper.player=Vector2(1000.,-195.);dropper.move_axis=Vector2(1,1)
	dropper.step(.05);check(absf(dropper.player.y+195.)<.1 and dropper.crouching(),"Down alone crawls on the upper deck without silently choosing the lower path")
	dropper.move_axis=Vector2(0,1);dropper.jump_press();dropper.jump_release()
	for frame in 90:dropper.step(1./60.)
	check(dropper.grounded() and absf(dropper.player.y-90.)<.1,"Down+Jump physically drops from the bridge to the lower channel")
	check(dropper.state=="playing" and CampaignRoutes.choice_at(dropper)=="","Dropping between lanes does not secretly select a route before its exit")
	check(CampaignRoutes.camera_y(w,0.)==90.,"Lower channel camera follows its real foot height instead of hiding the hero under controls")
	w.mount.ridden=true;w.player.y=48.;check(CampaignRoutes.camera_y(w,0.)==90.,"Rider camera follows vehicle contact feet, not a different mounted offset")
	w.mount.ridden=false;w.player.y=90.
	for mounted in [false,true]:
		var ledge:=fresh();ledge.enemies.clear();ledge.player=Vector2(651.,48. if mounted else 90.)
		ledge.mount={"available":mounted,"ridden":mounted,"x":651.,"hp":3,"type":"skimmer"}
		ledge.move_axis=Vector2.LEFT;ledge.step(.05)
		check(ledge.player.x>=CampaignRoutes.DROP_X and absf(CampaignRoutes.foot(ledge).y-90.)<.1,"Walking back into the ledge cannot teleport actor or vehicle up90 pixels")
		if not mounted:
			ledge.jump_press();ledge.jump_release()
			for frame in 42:ledge.move_axis=Vector2.LEFT;ledge.step(1./60.)
			check(ledge.player.x<CampaignRoutes.DROP_X and absf(ledge.player.y)<.1,"The lower ledge remains physically climbable by jumping back")
	var diver:=fresh();diver.mount={"available":true,"ridden":true,"x":1490.,"hp":3,"type":"shell","dive":.5};diver.player=Vector2(1490.,72.)
	check(diver.grounded() and CampaignRoutes.choice_at(diver)=="water","A diving shell uses the same contact feet for route selection and physics")
	for deck in [90.,-195.]:
		var rider:=fresh();rider.enemies.clear();rider.mount={"available":true,"ridden":true,"x":1200.,"hp":3,"type":"skimmer"};rider.player=Vector2(1200.,deck-42.);rider.velocity=Vector2.ZERO
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
	var snap:=w.snapshot();var restored:=AionCampaignWorld.new();check(restored.restore(snap) and restored.section=="fork_one" and restored.state=="playing","A junction checkpoint restores into gameplay")
	var game:=AionCampaignGame.new();root.add_child(game);await process_frame;game.set_process(false)
	game.world.load_section("fork_one");game.menu_kind="";game.build_ui();await process_frame;await process_frame
	check(not game.ui.find_children("Route_*","Button",true,false).size(),"No route-choice button exists in the live junction UI")
	for pair in [["shore","quay"],["quay","fork_one"],["canopy","fork_two"],["roots","relay"],["relay","arena"]]:auto_travel(game,str(pair[0]),str(pair[1]))
	auto_travel(game,"fork_one","water",false,true)
	auto_travel(game,"fork_two","roots",true)
	game.world.load_section("fork_one");game.world.player=Vector2(1490.,90.);game.world.velocity=Vector2.ZERO;CampaignRoutes.step(game.world)
	game.start_travel();game.application_active=false
	game.advance_travel(.05)
	check(game.fade==0. and game.world.section=="fork_one","Focus loss cannot silently complete travel in the background")
	game.application_active=true
	for tick in 12:game.advance_travel(.01)
	check(game.world.section=="water" and game.fade<0.,"Focused travel resumes safely from the same route contact")
	game.queue_free();await process_frame
	print("RESULT: ",checks," physical route checks, ",failures," failures");quit(1 if failures else 0)
