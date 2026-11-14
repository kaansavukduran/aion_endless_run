extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+message)
func _initialize() -> void:call_deferred("run")
func event(button: int,down: bool=true) -> InputEventJoypadButton:
	var input:=InputEventJoypadButton.new();input.button_index=button;input.pressed=down;return input
func run() -> void:
	var game:=AionCampaignGame.new();game.language="tr";root.add_child(game);await process_frame;game.set_process(false)
	game.touch_mode=true
	for viewport in [Vector2i(320,568),Vector2i(393,873),Vector2i(844,390),Vector2i(1280,720)]:
		root.size=viewport;await process_frame
		for scale in [1.,1.5,2.]:
			game.options.text_scale=scale;game.ui.theme=game.options.theme(game.FONT)
			for language in GameText.LANGUAGES:
				game.language=language;game.resize()
				for kind in ["briefing","help","paused","fork_one","fork_two","boss","dead","outro","complete"]:
					game.menu_kind=kind;game.build_ui();await process_frame;await process_frame
					var view:=Rect2(0,0,game.view_w,game.view_h)
					check(view.encloses(game.menu.get_global_rect()),"Whole dialog fits without scrolling: "+str(viewport)+" "+str(scale)+" "+language+" "+kind+" "+str(game.menu.get_global_rect()))
					for button in game.buttons:check(view.encloses(button.get_global_rect()),"Dialog action is visible and reachable")
	game.options.text_scale=1.;game.language="tr";game.menu_kind="briefing";game.build_ui();await process_frame;await process_frame
	game._input(event(JOY_BUTTON_A));await process_frame
	check(game.menu_kind=="help","Xbox A / PS Cross activates actual briefing button")
	game._input(event(JOY_BUTTON_X));await process_frame
	check(game.help_step==1,"Xbox X / PS Square activates actual tutorial next button")
	game.close_menu();game._input(event(JOY_BUTTON_START));await process_frame
	check(game.menu_kind=="paused" and game.world.state=="paused","Controller Start pauses actual mission")
	game._input(event(JOY_BUTTON_A));await process_frame
	check(game.menu_kind=="" and game.world.state=="playing","Controller confirm really resumes actual mission")
	game.menu_kind="outro";game.outro_step=0;game.world.state="complete";game.build_ui();await process_frame;await process_frame
	game._input(event(JOY_BUTTON_A));await process_frame;check(game.outro_step==1,"Victory continuation activates its actual first button")
	game.close_menu()
	for pair in [["fork_one","canopy",0],["fork_one","water",1],["fork_two","terrace",0],["fork_two","roots",1]]:
		game.world.state=pair[0];game.menu_kind=pair[0];game.build_ui();await process_frame;await process_frame
		game.buttons[int(pair[2])].pressed.emit();check(game.world.travel_target==pair[1],"Actual route button chooses its own branch, not the last captured loop variable: "+str(pair[1]))
	game.fade=-1.;game.world.load_section("shore");game.close_menu()
	game.world.load_section("shore");game.world.enemies.clear();game.world.gates.clear();game.world.player.x=140.;game.world.move_axis=Vector2.ZERO
	game._input(event(game.pad.bindings.shoot));game.world.step(.05)
	check(game.world.shots>0,"Mapped shoulder input reaches real projectile creation")
	game._input(event(game.pad.bindings.shoot,false));var shots:=game.world.shots;game.world.step(.05);check(not game.world.fire_held and game.world.shots==shots,"Controller release really stops fire")
	var grenade:=game.world.grenades;game._input(event(game.pad.bindings.duck));check(game.world.grenades==grenade-1,"Campaign B / Circle throws grenade, no roll")
	game.world.stop_inputs();game.touch_mode=true;game.resize();game.menu_kind="";game.build_ui()
	var rect: Rect2=game.actions.jump.get_global_rect();var touch:=InputEventScreenTouch.new();touch.index=1;touch.position=game.screen_transform*rect.get_center();touch.pressed=true;game._input(touch)
	check(game.world.jump_held and game.world.velocity.y<0.,"Real touch handler reaches common jump action")
	touch.pressed=false;touch.canceled=true;game._input(touch);check(not game.world.jump_held and game.touch_actions.is_empty(),"Touch cancellation releases captured action")
	game.world.begin("eren");game.world.state="playing";touch.index=2;touch.pressed=true;touch.canceled=false;game._input(touch);game.world.step(.05)
	check(game.world.charging,"Rabbit touch really starts a charge")
	touch.pressed=false;touch.canceled=true;game._input(touch);check(not game.world.charging and game.world.velocity.y==0.,"Canceled rabbit touch discards charge without launching an unintended jump")
	game.queue_free();await process_frame
	print("RESULT: %d campaign UI checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
