extends SceneTree

var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+message)

func clean(g: AionCampaignGame, hero: String) -> void:
	g.release_all();g.world.begin(hero)
	var w:=g.world
	w.enemies.clear();w.objects.clear();w.hazards.clear();w.zones.clear();w.gates.clear()
	w.npcs.clear();w.crates.clear();w.pickups.clear();w.platforms.clear();w.pits.clear()
	w.mount.available=false;w.player=Vector2(400.,0.);w.velocity=Vector2.ZERO;w.state="playing"
	g.menu_kind="";g.presentation_stage="";g.fade=-1.;g.application_active=true
	g.build_ui();g.update_arcade_aim();g.update_hud()

func context_routes(g: AionCampaignGame) -> void:
	g.touch_mode=true;g.resize()
	for hero in ["armadillo","frog"]:
		clean(g,hero)
		check(g.actions.context.visible,"Skill context remains discoverable: "+hero)
		check(not g.actions.context.disabled,"Ready skill context permits activation: "+hero)
		for locale in ["tr","en"]:
			g.language=locale;g.update_hud()
			check(g.actions.context.caption==g.t("skill_roll" if hero=="armadillo" else "skill_tongue"),"Context label uses selected language: "+hero+" "+locale)
		tap_context(g)
		check(not g.world.hero_skill.is_empty(),"Visible context button starts skill: "+hero)
		var starts: int=g.world.pending_events.count("hero_windup")
		tap_context(g)
		check(g.world.pending_events.count("hero_windup")==starts,"Repeated context activation does not restart skill: "+hero)
		g.update_hud()
		var info: Dictionary=MissionHeroAbilities.context(g.world)
		check(g.actions.context.disabled and float(info.remaining)>0. and g.actions.context.cooldown>0. and g.actions.context.accessibility_description.contains(g.t(str(info.status_key))),"Active skill exposes real phase and remaining time: "+hero)
		for source in ["keyboard","gamepad"]:
			g.touch_mode=false;clean(g,hero)
			check(not g.actions.has("context"),"Desktop has no floating interaction control: "+source)
			if source=="keyboard":
				var e:=InputEventKey.new();e.physical_keycode=KEY_E;e.keycode=KEY_E;e.pressed=true;g._unhandled_input(e)
			else:
				var e:=InputEventJoypadButton.new();e.button_index=g.interact_binding();e.pressed=true;g._input(e)
			check(not g.world.hero_skill.is_empty(),"Existing contextual input starts skill: "+hero+" "+source)
		g.touch_mode=true
	clean(g,"frog")
	g.world.weapon="arc";g.world.ammunition=10
	g.world.pickups.append({"id":"context-heavy","kind":"heavy","x":g.world.player.x+30.,"y":-35.})
	g.update_hud();tap_context(g)
	check(g.world.weapon=="heavy" and g.world.hero_skill.is_empty(),"Nearby weapon interaction takes priority over skill")
	clean(g,"frog")
	g.world.mount.available=true;g.world.mount.x=g.world.player.x;g.world.mount.floor_y=0.;g.world.mount.hp=3
	g.update_hud();tap_context(g)
	check(g.world.mount_transition=="enter" and g.world.hero_skill.is_empty(),"Boarding interaction takes priority over skill")
	for tick in 45:g.world.step(.01)
	g.update_hud()
	check(g.actions.context.action=="exit_vehicle" and g.actions.context.visible,"Board becomes Exit in the same mobile slot")
	tap_context(g)
	check(g.world.mount_transition=="exit" and not g.world.mount.ridden,"Exit button starts real dismount")
	clean(g,"frog");g.world.frog_meal={"id":"test-food","kind":"gnome"}
	g.update_hud()
	check(g.actions.context.action=="skill_spit" and not g.actions.context.disabled,"Loaded frog shows a distinct Spit action")
	tap_context(g)
	check(g.world.frog_meal.is_empty() and g.world.bullets.size()==1,"Spit fires from the same action slot")

	clean(g,"aion");g.update_hud()
	check(not g.actions.context.visible,"Original hero has no unrelated skill control")

func stable_armadillo_aim(g: AionCampaignGame) -> void:
	clean(g,"armadillo");g.world.player.y=-100.
	g.mouse_point=g.view.get_global_transform_with_canvas()*g.view.at(g.world.player+Vector2(8.,-130.))
	g.world.aim_direction=Vector2.LEFT;g.world.facing=-1
	var facing_left:=g.pointer_aim()
	g.world.aim_direction=Vector2.RIGHT;g.world.facing=1
	var facing_right:=g.pointer_aim()
	check(facing_left.x>0. and facing_right.x>0. and facing_left.is_equal_approx(facing_right),"Airborne aim stays on the same side when the registered hand mirrors")

func compact_inputs(g: AionCampaignGame) -> void:
	clean(g,"armadillo");g.down_down=true;g.update_arcade_aim()
	g.set_action("attack","held-before-roll",true)
	check(g.world.fire_held,"Gun input begins normally before compact action")
	check(g.activate_context(),"Crouched context begins Armadillo roll")
	var shots: int=g.world.shots
	var grenades: int=g.world.grenades
	for action in ["attack","jump","grenade"]:g.set_action(action,"pressed-during-roll",true)
	check(not g.held.has("attack") and not g.held.has("jump") and not g.held.has("grenade"),"Compact action discards old and rejects queued input sources")
	g.set_action("boost","sprint",true)
	check(g.world.boost_held,"Existing sprint binding remains independent")
	for tick in 210:g.world.step(.01)
	check(g.world.hero_skill.is_empty() and g.world.shots==shots and g.world.grenades==grenades and g.world.jump_buffer_timer==0.,"Opening shell never fires, jumps or throws a rejected input")
	g.set_action("attack","fresh-press",true)
	check(g.world.shots==shots+1,"Fresh post-recovery gun press still works")

func rescue_context(g: AionCampaignGame) -> void:
	g.touch_mode=true;g.resize();clean(g,"aion")
	var w:=g.world
	var near: Dictionary={"id":"near","x":w.player.x+32.,"y":0.,"freed":false,"secret":"","cage":"closed"}
	var farther: Dictionary={"id":"farther","x":w.player.x+77.,"y":0.,"freed":false,"secret":""}
	w.npcs.append_array([farther,near])
	w.aim_direction=Vector2.RIGHT
	g.update_hud()
	check(CampaignRescue.cut_target(w)==near and g.actions.attack.action=="cut","Cut cue chooses the nearest reachable rope, independent of NPC ordering")
	w.aim_direction=Vector2.UP
	g.update_hud()
	check(CampaignRescue.cut_target(w).is_empty() and g.actions.attack.action=="shoot","Upward aiming gives no false cut cue")
	w.aim_direction=Vector2.RIGHT
	w.objects.append({"id":"closed","active":false,"kind":"cage"})
	check(CampaignRescue.cut_target(w)==farther,"A closed cage cannot be offered for a knife cut")
	w.enemies.append({"x":w.player.x+50.,"y":0.,"defeated":false})
	g.update_hud()
	check(CampaignRescue.cut_target(w).is_empty() and g.actions.attack.action=="melee","Close combat takes priority over the rescue cue")
	w.enemies.clear();w.objects.clear()
	w.attack_press()
	check(w.rescue_target=="near" and w.shots==0,"The normal attack actually cuts the same rope indicated by the cue")

func interruptions(g: AionCampaignGame) -> void:
	clean(g,"frog")
	g.set_action("grenade","test",true);g.world.step(.05)
	var clock: float=g.world.grenade_throw.elapsed
	g.toggle_pause();g.world.step(.25)
	check(not g.world.grenade_throw.is_empty() and is_equal_approx(float(g.world.grenade_throw.elapsed),clock),"Explicit pause freezes unspent grenade choreography")
	g.close_menu();g._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(g.world.grenade_throw.is_empty() and g.world.grenades==5 and g.world.bombs.is_empty(),"Focus loss cancels unspent grenade without spending inventory")
	clean(g,"frog");g.activate_context();g.world.step(.05)
	clock=g.world.hero_skill.clock
	g.toggle_pause();g.world.step(.25)
	check(not g.world.hero_skill.is_empty() and is_equal_approx(float(g.world.hero_skill.clock),clock),"Explicit pause freezes skill choreography")
	g.close_menu();g.on_web_page_hidden([])
	check(g.world.hero_skill.is_empty() and g.world.state=="paused","Hidden tab cancels skill and pauses normal gameplay")
	clean(g,"frog");g.world.throw_grenade()
	for tick in 4:g.world.step(.05)
	check(g.world.bombs.size()==1 and g.world.grenades==4,"Throw reaches actual release before focus interruption")
	g._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	check(g.world.grenade_throw.is_empty() and g.world.bombs.size()==1 and g.world.grenades==4,"Focus loss preserves already released physical bomb")

func audio_events(g: AionCampaignGame) -> void:
	clean(g,"aion");g.audio_enabled=true
	for event in ["grenade","grenade_bounce","grenade_blast","hero_roll","hero_tongue","hero_contact"]:
		g.world.pending_events.append(event);g._process(.001)
		check(g.sound_cache.has(event) and g.sound_cache[event]==g.GRENADE_SOUNDS[event],"Real event dispatch uses authored WAV: "+event)
	check(g.voices.size()==6,"Authored sounds preserve six-voice allocation")
	g.audio_enabled=false;var previous: int=g.sound_cache.size();g.sound("muted-test")
	check(g.sound_cache.size()==previous,"Mute still suppresses sound work")

func finger(g: AionCampaignGame,index: int,point: Vector2,pressed: bool,canceled: bool=false) -> void:
	var e:=InputEventScreenTouch.new();e.index=index;e.position=g.screen_transform*point;e.pressed=pressed;e.canceled=canceled
	g._input(e)

func tap_context(g: AionCampaignGame) -> void:
	var point: Vector2=g.actions.context.get_global_rect().get_center()
	finger(g,0,point,true)
	finger(g,0,point,false)

func touch_context(g: AionCampaignGame) -> void:
	g.touch_mode=true
	for size in [Vector2i(1152,648),Vector2i(393,873)]:
		root.size=size;g.resize()
		clean(g,"armadillo")
		g.world.player.y=-80.;g.update_hud()
		check(g.actions.context.disabled and g.actions.context.caption==g.t("skill_land"),"Airborne Armadillo shows a disabled land state")
		var disabled_point: Vector2=g.actions.context.global_position+g.actions.context.size*.5
		finger(g,2,disabled_point,true)
		g.world.player.y=0.;g.update_hud();finger(g,2,disabled_point,true)
		check(g.world.hero_skill.is_empty() and g.touch_actions.get(2,"")=="context","A finger held on a disabled context never queues activation when it becomes ready")
		finger(g,2,disabled_point,false);clean(g,"armadillo")
		var down: Vector2=g.stick.position+g.stick.size*Vector2(.86,.73)
		finger(g,7,down,true);g.update_arcade_aim();g.update_hud()
		check(not g.world.crouching() and g.stick_touch==7 and g.world.move_axis.x>.4,"Shallow touch diagonal keeps Armadillo upright at "+str(size))
		var point: Vector2=g.actions.context.global_position+g.actions.context.size*.5
		finger(g,23,point,true)
		check(not g.world.hero_skill.is_empty(),"Second finger activates the visible context at "+str(size))
		check(g.touch_actions.get(23,"")=="context" and g.stick_touch==7,"Context finger has its own one-shot owner without releasing the stick")
		for tick in 210:g.world.step(.01)
		finger(g,23,point,true)
		check(g.world.hero_skill.is_empty(),"A held/duplicate context finger cannot restart after cooldown")
		var drag:=InputEventScreenDrag.new();drag.index=23;drag.position=g.screen_transform*(g.actions.attack.position+g.actions.attack.size*.5);g._input(drag)
		check(g.world.shots==0 and not g.world.fire_held,"Dragging the context finger over Fire cannot create another action")
		finger(g,23,point,false,true);g.update_arcade_aim()
		check(not g.touch_actions.has(23) and g.stick_touch==7 and g.world.move_axis.x>.4,"Canceled context releases only its own finger")
		finger(g,7,down,false);g.update_arcade_aim()
		check(g.stick_touch==-1 and g.world.move_axis==Vector2.ZERO,"Releasing both fingers leaves no held direction")
		clean(g,"frog");g.world.weapon="arc";g.world.ammunition=10
		g.world.pickups.append({"id":"touch-heavy","kind":"heavy","x":g.world.player.x+30.,"y":-35.});g.update_hud()
		point=g.actions.context.global_position+g.actions.context.size*.5
		finger(g,0,point,true);finger(g,0,point,true)
		check(g.world.weapon=="heavy" and g.world.hero_skill.is_empty(),"One context touch swaps only once and cannot become an extra skill press")
		finger(g,0,point,false);g.update_hud();finger(g,0,point,true)
		check(not g.world.hero_skill.is_empty(),"A fresh context touch still activates Frog after the weapon swap")
		g.release_all()
		check(g.touch_actions.is_empty() and g.stick_touch==-1,"Focus/menu input release clears context ownership too")
	root.size=Vector2i(1152,648);g.resize()

func _initialize() -> void:call_deferred("run")

func run() -> void:
	var g:=AionCampaignGame.new();root.add_child(g);await process_frame;g.set_process(false)
	context_routes(g);stable_armadillo_aim(g);compact_inputs(g);rescue_context(g);interruptions(g);audio_events(g);touch_context(g)
	g.queue_free();await process_frame
	print("RESULT: %d campaign context checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
