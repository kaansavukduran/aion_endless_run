## Mission aim: keyboard keeps eight directions; sticks and the mouse aim freely.
extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+label)
func settle() -> void:
	for i in 3:await process_frame
func steer(game,frames: int=40) -> void:
	for i in frames:game.update_arcade_aim(1./60.)
func hand_origin(game) -> Vector2:
	var hand: Vector2=game.world.player+Vector2(M1CombatArt.placement(game.world).grip)
	return game.view.get_global_transform_with_canvas()*game.view.at(hand)
func pointer_check(game,angle: float) -> float:
	game.mouse_aim=true;game.mouse_point=hand_origin(game)+Vector2.from_angle(angle)*180.
	game.update_arcade_aim(1./60.);game.update_arcade_aim(1./60.)
	return game.world.aim_direction.distance_to((game.mouse_point-hand_origin(game)).normalized())
func primary(v: Vector2) -> bool:
	return absf(v.x)<.02 or absf(v.y)<.02 or absf(absf(v.x)-absf(v.y))<.02
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var game=AionCampaignGame.new();game.world.begin("aion");game.world.state="playing"
	game.world.player.y=-200.
	game.right_down=true;game.up_down=true;steer(game)
	check(game.world.aim_direction.is_equal_approx(Vector2(1,-1).normalized()),"Keyboard W+D still aims exactly up-right")
	game.up_down=false;steer(game)
	check(game.world.aim_direction.is_equal_approx(Vector2.RIGHT),"Keyboard D alone aims straight ahead")
	game.right_down=false
	var target:=Vector2(.9,-.35).normalized()
	game.pad_axis=Vector2(.9,-.35);steer(game)
	check(game.world.aim_direction.distance_to(target)<.001 and not primary(game.world.aim_direction),"An analog stick aims at its actual angle between the eight directions")
	game.pad_axis=Vector2(.95,.03);steer(game)
	check(game.world.aim_direction.is_equal_approx(Vector2.RIGHT),"A nearly level stick push stays a clean level shot")
	game.pad_axis=Vector2.ZERO;game.pad_look=Vector2.from_angle(-2.4);steer(game)
	check(game.world.aim_direction.distance_to(Vector2.from_angle(-2.4))<.001,"The right stick aims through the full circle on foot")
	game.pad_look=Vector2.ZERO
	game.free();game=AionCampaignGame.new();game.selected_hero="aion"
	root.add_child(game);await settle()
	game.world.state="playing";game.world.player.y=-200.;game.view.queue_redraw();await settle()
	for angle in [-.4,-1.1,.3,2.6,-2.9]:
		check(pointer_check(game,angle)<.001,"The gun aims from the actual hand at the mouse pointer: "+str(angle))
	check(game.world.aim_direction.x<0.,"Aiming behind turns the hero toward the pointer")
	pointer_check(game,-.4);game.up_down=true;steer(game)
	check(game.world.aim_direction.is_equal_approx(Vector2.UP),"Holding W overrides mouse aim with the keyboard direction")
	game.up_down=false;game.mouse_aim=true;game.pad_axis=Vector2(-.6,-.8);steer(game)
	check(game.world.aim_direction.distance_to(Vector2(-.6,-.8))<.001,"A gamepad stick takes priority over a resting mouse")
	game.pad_axis=Vector2.ZERO
	var touch:=InputEventScreenTouch.new();touch.pressed=false;touch.index=7;game._input(touch)
	check(not game.mouse_aim,"Touch input turns pointer aim off")
	var before: int=game.world.shots;pointer_check(game,-.7)
	var wanted: Vector2=(game.mouse_point-hand_origin(game)).normalized()
	game.world.fire_time=0.;CampaignWeapons.fire(game.world)
	var shot: Dictionary=game.world.bullets[-1]
	check(game.world.shots==before+1 and Vector2(shot.v).normalized().distance_to(wanted)<.001 and not primary(wanted),"The real projectile flies toward the mouse at a free angle")
	print("RESULT: %d free aim checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
