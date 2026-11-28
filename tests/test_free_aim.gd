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
func click_attack(game: AionCampaignGame, toward: int) -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = hand_origin(game) + Vector2(250. * toward, 0.)
	game._unhandled_input(click)

func face_before_click(game: AionCampaignGame, direction: int) -> void:
	game.release_all()
	game.world.facing = direction
	game.world.aim_direction = Vector2(direction, 0.)
	game.world.enemies.clear()
	game.world.bullets.clear()
	game.world.fire_time = 0.
	game.world.melee_time = 0.
	game.world.shots = 0

func check_fast_reversal(game: AionCampaignGame) -> void:
	game.set_process(false)
	game.world.prewarm_art = false
	game.begin_new()
	game.world.player = Vector2(420., 0.)
	game.world.npcs.clear()
	game.view.camera_x = 0.
	game.view.camera_y = 0.
	for initial in [-1, 1]:
		face_before_click(game, initial)
		game.world.spawn_enemy("gnome", 420. + initial * 60., 0., 901)
		click_attack(game, -initial)
		check(game.world.shots == 1 and game.world.melee_time == 0. and not game.world.bullets.is_empty() and float(game.world.bullets[0].v.x) * initial < 0., "A same-frame turn and click fires past the enemy behind the new aim")
		face_before_click(game, initial)
		game.world.spawn_enemy("gnome", 420. - initial * 60., 0., 902)
		click_attack(game, -initial)
		check(game.world.shots == 0 and game.world.melee_target == "shore:enemy:902" and game.world.melee_time > 0., "A same-frame turn and click strikes the enemy in the new aim direction")
		face_before_click(game, initial)
		game.world.npcs = [{"id":"captive","x":420. - initial * 60.,"y":0.,"freed":false,"secret":""}]
		click_attack(game, -initial)
		check(game.world.shots == 0 and game.world.rescue_target == "captive" and game.world.rescue_time > 0., "A same-frame turn and click cuts the rope in the new aim direction")
		game.world.rescue_time = 0.
		game.world.rescue_target = ""
		game.world.npcs.clear()

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
	check_fast_reversal(game)
	print("RESULT: %d free aim checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
