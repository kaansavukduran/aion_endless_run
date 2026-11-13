extends SceneTree
const World = preload("res://scripts/world.gd")
var checks := 0
var failures := 0
func check(value: bool,message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: "+message)
func _initialize() -> void: call_deferred("run")
func arena() -> RunnerWorld:
	var w := World.new()
	w.reset()
	w.obstacle_wait = 9999
	w.adventure.item_wait = 9999
	w.frontier.plant_wait = 9999
	return w
func advance(w,seconds: float) -> void:
	for i in int(ceil(seconds*120)): w.step(1.0/120)
func pad(index: int) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = index
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame
func settle() -> void:
	for i in 5: await process_frame
func find_button(game,text: String) -> Button:
	for b in game.menu_layer.find_children("*","Button",true,false):
		if b.text == text: return b
	return null
func run() -> void:
	var w := arena()
	w.character = "sheep"
	w.sheep_count = 3
	w.frontier.request_boss(10)
	advance(w,1.8)
	w.jump()
	advance(w,0.01)
	check(w.sheep_count==3 and w.flock_pose(0).y==0 and w.flock_pose(1).y==0,"Boss entry preserves all sheep and the spatially delayed takeoff")
	advance(w,0.30)
	check(w.flock_pose(0).y<0 and w.flock_pose(1).y==0,"First small sheep follows later along actual chase travel")
	advance(w,0.30)
	check(w.flock_pose(1).y<0,"Second small sheep follows after the first in the boss chase")
	var d := w.distance
	check(w.distance==d and w.frontier.chase_distance>d,"Chase travel advances without normal level progress")
	var pose: Dictionary = w.flock_pose(0)
	w.frontier.finish(w)
	check(is_equal_approx(float(w.flock_pose(0).y),float(pose.y)),"Returning from the chase rebases history without teleporting a follower")
	for kind in 3:
		w = arena()
		w.frontier.request_boss((kind+1)*10)
		advance(w,1.7)
		check(w.frontier.boss_kind==kind,"Tenth-level milestones select a different boss: "+str(kind))
		w.invulnerable = 999
		var patterns := {}
		var xs := []
		var ys := []
		for i in 2400:
			w.step(1.0/120)
			patterns[w.frontier.pattern] = true
			xs.append(w.frontier.boss_x)
			ys.append(w.frontier.boss_y)
		check(patterns.size()>=3 and w.frontier.attacks_cast>=3,"Each boss actually casts at least three distinct scheduled patterns: "+str(kind))
		check(xs.max()-xs.min()>60 and ys.max()-ys.min()>40,"Each boss really changes horizontal and vertical position: "+str(kind))
		w.frontier.hp = w.frontier.max_hp/2
		w.step(0.01)
		check(w.frontier.rage,"Each boss enters a faster second phase at half health: "+str(kind))
		w.frontier.shoot_held = true
		for tick in 6000:
			if w.frontier.ammo==0:w.frontier.reload(w)
			if kind==1 and w.y>=0:w.jump()
			w.step(.01)
			if w.frontier.wins>0:break
		check(w.frontier.wins==1,"Real timed hero bolts can defeat the moving boss: "+str(kind))
	w = arena()
	w.character = "sheep"
	w.frontier.request_boss(10)
	advance(w,1.7)
	check(w.frontier.fire(w) and w.frontier.projectiles.is_empty(),"Trigger begins the anticipation pose, without a premature projectile")
	advance(w,0.09)
	var bullet: Dictionary = w.frontier.projectiles.filter(func(p):return p.owner=="hero")[0]
	check(w.frontier.shots_fired==1 and bullet.x>World.PLAYER_X+40,"The shot leaves the measured front muzzle at the flash phase")
	advance(w,0.25)
	check(w.frontier.shot_flash==0 and w.frontier.shots_fired==1,"A released trigger finishes recoil without inventing another shot")
	for cause in ["bonk","enemy","projectile"]:
		w = arena()
		w.y = -100
		w.take_hit("bonk",cause)
		advance(w,0.6)
		check(w.death_cause==cause and w.y==0,"Fatal impact reaches the actual ground and preserves its cause: "+cause)
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await settle()
	game.set_physics_process(false)
	game.main_menu()
	await settle()
	await pad(JOY_BUTTON_A)
	check(game.world.state=="running" and game.page=="","Real mapped A/Cross starts the focused main-menu action")
	await pad(JOY_BUTTON_START)
	await settle()
	check(game.page=="paused","Start/Options opens the real pause menu")
	await pad(JOY_BUTTON_DPAD_DOWN)
	check(game.get_viewport().gui_get_focus_owner().text==game.text("menu"),"D-pad moves from Resume to Main menu")
	await pad(JOY_BUTTON_X)
	await settle()
	check(game.page=="main","X/Square activates the focused Main menu button")
	game.start_run()
	game.world.state = "bonk"
	game.world.death_cause = "enemy"
	game.show_page("finished")
	await settle()
	await pad(JOY_BUTTON_A)
	check(game.page=="" and game.world.state=="running","A/Cross activates Run again on the actual result menu")
	game.world.state = "bonk"
	game.show_page("finished")
	await settle()
	find_button(game,game.text("settings")).grab_focus()
	await pad(JOY_BUTTON_X)
	await settle()
	check(game.page=="settings","X/Square activates Settings from the actual result menu")
	await pad(JOY_BUTTON_B)
	await settle()
	check(game.page=="finished","B/Circle returns from Settings to the result menu")
	await pad(JOY_BUTTON_DPAD_DOWN)
	await pad(JOY_BUTTON_A)
	await settle()
	check(game.page=="main","D-pad and A also activate Main menu after a failed run")
	game.character = "sheep"
	game.start_boss_practice(1)
	advance(game.world,1.8)
	game.update_friend()
	check(game.followers[0].visible and game.followers[1].visible,"Actual sheep sprites remain visible with the gun and boss active")
	var old_best: int = game.best
	game.world.adventure.bonus_score = old_best+10000
	game.world.recompute_score()
	game.save_settings()
	check(game.best==old_best,"Practice never changes the saved normal-run record")
	game.world.frontier.shot_flash = 0.19
	game.update_friend()
	check(game.friend_sprite.get_meta("pose_key")=="gun-fire" and game.friend_sprite.get_meta("source_row")==8,"The actual sheep uses its own two-hoof firing row")
	game.world.frontier.shot_flash = 0
	game.update_friend()
	check(game.friend_sprite.get_meta("pose_key")=="gun-run","Aiming resumes the complete gun-running cycle")
	game.world.state = "bonk"
	game.world.death_cause = "enemy"
	game.world.hit_time = 1.3
	game.update_friend()
	check(game.friend_sprite.get_meta("pose_key")=="deaths" and game.friend_sprite.get_meta("source_row")==10,"An enemy faceplant overrides the held gun even in a lost boss fight")
	game.world.death_cause = "bonk"
	game.update_friend()
	check(game.friend_sprite.get_meta("source_row")==9,"Obstacle impact uses a different settling animation")
	for hero in 4:
		for key in ["gun-run","gun-fire"]:
			var scale := -1.0
			var unique := {}
			for frame in game.frames.count(key,hero):
				var f: Dictionary = game.frames.pose(key,hero,frame)
				unique[hash(f.texture.get_image().get_data())] = true
				if scale<0: scale=f.scale
				check(is_equal_approx(scale,f.scale),"Gun frame preserves one body scale: "+str(hero)+key+str(frame))
			check(unique.size()==(7 if hero in [0,2] else 8),"All actual gun poses are independently drawn: "+str(hero)+key)
	game.queue_free()
	await process_frame
	print("RESULT: %d encounter/gamepad checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
