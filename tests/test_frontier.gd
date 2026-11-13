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
	var w = World.new()
	w.reset()
	# Combat-only fixtures bypass the separately tested cinematic.
	w.practice = true
	w.obstacle_wait = 999
	w.adventure.item_wait = 999
	w.adventure.ambient_gnome_wait = 999
	w.frontier.plant_wait = 999
	return w
func advance(w,seconds: float) -> void:
	for i in int(ceil(seconds/0.01)): w.step(0.01)
func run() -> void:
	var w := arena()
	for n in 8:
		w.distance = n*World.BIOME_DISTANCE+10
		check(w.biome() == n%World.BIOME_NAMES.size(),"The six biomes cycle without losing the first two: "+str(n))
	for kind in ["pit","pit_city"]:
		w = arena()
		w.obstacles.assign([{"x":World.PLAYER_X,"width":150,"kind":kind,"counted":false}])
		w.step(0.01)
		check(w.state == "fall","A grounded hero falls into an actual gap: "+kind)
		var y: float = w.y
		advance(w,0.2)
		check(w.y > y+40,"Pit failure animates falling instead of walking across a painted hole")
		w = arena()
		w.y = -90
		w.velocity = -100
		w.obstacles.assign([{"x":World.PLAYER_X,"width":150,"kind":kind,"counted":false}])
		w.step(0.01)
		check(w.state == "running","A genuinely airborne hero clears the gap")
	w = arena()
	w.adventure.powers.shield = 10
	w.obstacles.assign([{"x":World.PLAYER_X,"width":150,"kind":"pit","counted":false}])
	w.step(0.01)
	check(w.state == "running" and w.velocity < -400 and w.y < 0,"A saved pit life gives an actual rescue leap")
	w = arena()
	w.frontier.plant_wait = 0
	w.step(0.01)
	check(w.frontier.plants.size() == 1 and w.frontier.plant_wait >= 35,"Plants are spaced by long randomized waits")
	w.frontier.plants[0].x = World.PLAYER_X+650
	w.step(0.01)
	check(w.frontier.plants[0].shot and w.frontier.projectiles.is_empty(),"A plant visibly winds up before its first fireball")
	advance(w,0.95)
	check(w.frontier.projectiles.size() == 1 and w.frontier.projectiles[0].owner == "plant","The mouth creates a real traveling fire projectile")
	advance(w,0.2)
	check(w.frontier.projectiles.size() <= 1,"One plant telegraph never duplicates a continuous fire stream")
	w = arena()
	w.frontier.plant_wait = 0
	w.obstacles.assign([{"x":w.field_width,"kind":"fire","counted":false}])
	w.step(0.01)
	check(w.frontier.plants.is_empty() and w.frontier.plant_wait < 2,"A plant defers spawning when the reserved lane is crowded")
	w = arena()
	w.frontier.plants.assign([{"x":World.PLAYER_X+45,"age":2.0,"shot":true,"hp":2,"hurt":0.0,"last_swing":-1}])
	w.adventure.attack_time = 0.25
	w.adventure.swing_id = 1
	w.step(0.01)
	check(w.frontier.plants.is_empty() and w.adventure.kills == 1 and w.adventure.run_xp==10,"One real melee contact defeats and scores a fire plant")
	advance(w,0.05)
	check(w.adventure.kills == 1 and w.adventure.run_xp==10,"The same swing cannot award a defeated plant twice")

	w = arena()
	w.adventure.level = 9
	w.adventure.level_elapsed = 30
	w.distance = w.adventure.LEVEL_DISTANCE
	w.adventure.update_level(w)
	check(w.adventure.hugging() and not w.frontier.active(),"The tenth level hugs before combat begins")
	advance(w,1.05)
	check(w.frontier.phase == "intro" and w.frontier.milestone == 10,"Hug completion enters the weapon handoff and boss introduction")
	w = arena()
	w.adventure.celebrations_enabled = false
	w.adventure.level = 9
	w.adventure.level_elapsed = 30
	w.distance = w.adventure.LEVEL_DISTANCE
	w.adventure.update_level(w)
	w.step(0.01)
	check(w.frontier.active() and not w.adventure.hugging(),"Turning off cosmetic celebrations does not disable boss gameplay")
	w = arena()
	w.adventure.powers.shield = 9
	w.obstacles.assign([{"x":600,"kind":"fire","counted":false}])
	w.adventure.spawn_enemy(w,"gnome",800)
	w.adventure.spawn_item(w,"mushroom",900)
	w.frontier.plants.assign([{"x":1000}])
	w.adventure.attack_time = 0.3
	w.adventure.roll_time = 0.5
	w.frontier.request_boss(10)
	w.step(0.01)
	check(w.adventure.attack_time == 0.0 and w.adventure.roll_time == 0.0,"The handoff clears carried melee and rolling poses")
	check(w.obstacles.is_empty() and w.adventure.enemies.is_empty() and w.adventure.items.is_empty() and w.frontier.plants.is_empty(),"Arena transition removes parkour, gnomes, items and plants")
	check(w.frontier.saved_powers.shield == 9 and w.adventure.powers.shield == 0,"Normal powers are suspended, not consumed or oversized during the boss")
	var d: float = w.distance
	advance(w,1.7)
	check(w.frontier.phase == "fight" and w.distance == d and w.frontier.chase_distance > d,"A moving chase does not secretly advance normal levels")
	check(w.adventure.enemies.is_empty() and w.obstacles.is_empty() and w.adventure.items.is_empty(),"The isolated chase cannot spawn ordinary encounters")
	w.frontier.shoot_held = true
	advance(w,0.6)
	check(w.frontier.shots_fired >= 2 and w.frontier.projectiles.any(func(p):return p.owner == "hero" and p.vx > 0),"Held fire launches real forward energy bolts at a limited cadence")
	var hp: int = w.frontier.hp
	advance(w,1.1)
	check(w.frontier.hp < hp and w.frontier.hits > 0,"Projectile collision actually reduces boss health")
	w.state = "paused"
	var clock: float = w.frontier.clock
	var shots: int = w.frontier.shots_fired
	advance(w,0.4)
	check(w.frontier.clock == clock and w.frontier.shots_fired == shots,"Pause freezes the entire chase and its fire cadence")
	w.state = "running"
	w.release_controls()
	check(not w.frontier.shoot_held,"Control release clears held shooting")
	check(not w.adventure.request_attack(w),"Hidden normal melee cannot run behind boss shooting poses")
	w.frontier.projectiles.clear()
	w.y = 0
	w.adventure.press_roll(w)
	w.frontier.projectiles.assign([{"owner":"boss","kind":"bolt","x":World.PLAYER_X+1,"y":-82.0,"vx":-1.0,"vy":0.0,"r":12.0}])
	w.invulnerable = 0
	w.frontier.update_projectiles(w,0.01)
	check(w.frontier.player_hp == 3,"Rolling truly clears a high boss shot")
	w.frontier.projectiles.assign([{"owner":"boss","kind":"ember","x":World.PLAYER_X+1,"y":-14.0,"vx":-1.0,"vy":0.0,"r":12.0}])
	w.frontier.update_projectiles(w,0.01)
	check(w.frontier.player_hp == 2 and w.invulnerable > 0,"A low orb hits a grounded rolling hero and grants brief grace")
	w.y = -100
	w.invulnerable = 0
	w.frontier.projectiles.assign([{"owner":"boss","kind":"ember","x":World.PLAYER_X+1,"y":-14.0,"vx":-1.0,"vy":0.0,"r":12.0}])
	w.frontier.update_projectiles(w,0.01)
	check(w.frontier.player_hp == 2,"A jump genuinely clears the low boss orb")
	w.frontier.hp = 1
	w.frontier.projectiles.assign([{"owner":"hero","kind":"energy","x":w.frontier.boss_x,"y":w.frontier.boss_y,"vx":1.0,"vy":0.0,"r":8.0}])
	w.frontier.update_projectiles(w,0.01)
	check(w.frontier.phase == "victory" and w.frontier.wins == 1 and w.adventure.bonus_score == 600 and w.adventure.run_xp==100,"The final hit wins exactly once and grants score plus 100 boss XP")
	advance(w,3.0)
	check(not w.frontier.active() and w.frontier.projectiles.is_empty() and w.adventure.powers.shield > 8.8,"Victory restores the suspended powers and clears combat")
	check(w.obstacle_wait > 2 and w.invulnerable > 1 and w.trail.size() < 120,"Return has a safe runway and preserves bounded continuous chase follower history")
	w = arena()
	w.frontier.request_boss(10)
	w.step(0.01)
	advance(w,1.7)
	w.frontier.player_hp = 1
	w.invulnerable = 0
	w.frontier.hit_player(w)
	check(w.state == "bonk" and w.frontier.player_hp == 0,"Losing the third boss health point ends the run")
	w = arena()
	w.frontier.request_boss(20)
	w.step(0.01)
	check(w.frontier.max_hp > 36 and w.frontier.player_hp == 3,"A later original robot battle scales without enlarging the hero")
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	for id in game.FRIENDS:
		var legacy_target: float=84.0*game.frames.EREN.data.atlas.scale[0] if id=="eren" else (53.2 if id=="rabbit" else (70.0 if id == "aion" else 65.0))
		var target: float={"aion":60.859375,"owl":57.434599,"sheep":63.076923,"wolf":52.380228,"rabbit":36.923077,"eren":53.004115}[id]
		for row in ([0,1,2] if id == "aion" else [0,1,2,6,7]):
			for frame in 6:
				game.place_companion(game.friend_sprite,id,row,frame,Vector2.ZERO)
				check(is_equal_approx(float(game.friend_sprite.get_meta("head_size")),target) and not game.friend_sprite.region_enabled,"Anatomical calibration and isolated texture: "+id+"/"+str(row)+"/"+str(frame))
		for variant in 2:
			game.world.adventure.attack_variant = variant
			for frame in 6:
				game.place_combat(game.friend_sprite,id,0,frame,Vector2.ZERO,1,false)
				var image: Image = game.friend_sprite.texture.get_image()
				var edges_clear := true
				for x in image.get_width(): edges_clear = edges_clear and image.get_pixel(x,0).a == 0 and image.get_pixel(x,image.get_height()-1).a == 0
				for y in image.get_height(): edges_clear = edges_clear and image.get_pixel(0,y).a == 0 and image.get_pixel(image.get_width()-1,y).a == 0
				check(edges_clear and is_equal_approx(float(game.friend_sprite.get_meta("head_size")),legacy_target),"Both strikes have padded independent texture edges and stable anatomy: "+id+"/"+str(variant)+"/"+str(frame))
		for frame in 6:
			game.frames.place(game.friend_sprite,"heroes",game.COMBAT_ROWS[id],frame,Vector2.ZERO)
			check(is_equal_approx(float(game.friend_sprite.get_meta("head_size")),target),"Gun poses retain the running character head size: "+id+"/"+str(frame))
	game.start_run()
	game.world.adventure.level = 9
	game.world.adventure.level_elapsed = 30
	game.world.distance = game.world.adventure.LEVEL_DISTANCE
	game.world.adventure.update_level(game.world)
	game.pause_run()
	game.open_subpage("settings")
	for toggle in game.ui.find_children("*","CheckButton",true,false):
		if toggle.text == game.text("celebrations"): toggle.button_pressed = false
	check(game.world.frontier.pending_level == 10 and not game.world.adventure.hugging(),"Disabling celebrations in a paused hug still preserves its boss transition")
	game.queue_free()
	await process_frame
	print("RESULT: %d frontier checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
