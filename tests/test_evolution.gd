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
	w.adventure.gnome_wait = 9999
	w.adventure.ambient_gnome_wait = 9999
	w.adventure.weather_wait = 9999
	w.adventure.tempo_wait = 9999
	return w
func advance(w: RunnerWorld,seconds: float) -> void:
	for i in int(seconds*120): w.step(1.0/120)
func run() -> void:
	var w := arena()
	check(w.adventure.request_attack(w),"A fresh press starts one attack")
	advance(w,2.0)
	check(w.adventure.swing_id == 1 and w.adventure.attack_time == 0,"Holding a press never auto-repeats after cooldown")
	check(not w.adventure.request_attack(w),"A duplicate held source cannot trigger a second swing")
	w.adventure.attack_held = false
	w.adventure.request_attack(w)
	check(w.adventure.swing_id == 2 and w.adventure.attack_variant == 1,"The next press uses the alternate move")
	advance(w,0.35)
	w.adventure.attack_held = false
	w.adventure.request_attack(w)
	check(w.adventure.pending_attack,"A fresh late-cooldown press can buffer one strike")
	advance(w,1.0)
	check(w.adventure.swing_id == 3 and not w.adventure.pending_attack,"Buffered input runs once and cannot turn into autofire")
	w = arena()
	w.adventure.press_roll(w)
	w.adventure.duck_held = false
	advance(w,0.20)
	check(w.adventure.ducking(w) and w.adventure.roll_elapsed > 0,"A brief press completes a timed physical roll")
	var first_frame := w.adventure.roll_frame()
	advance(w,0.12)
	check(first_frame != w.adventure.roll_frame(),"The roll advances drawn rotation frames")
	check(not w.adventure.attack(w),"Roll defense cannot show a misleading standing punch")
	advance(w,0.5)
	check(not w.adventure.ducking(w),"A released roll ends after its minimum duration")
	w.adventure.press_roll(w)
	advance(w,1.2)
	check(w.adventure.ducking(w),"Holding the roll control continues the roll loop")
	for kind in ["carrier_pipe","carrier_plank"]:
		w = arena()
		w.obstacles = [{"x":World.PLAYER_X,"kind":kind,"counted":false}]
		w.adventure.press_roll(w)
		w.step(0.01)
		check(w.state == "running","A natural round roll clears the overhead variant: "+kind)
		w = arena()
		w.obstacles = [{"x":World.PLAYER_X,"kind":kind,"counted":false}]
		w.step(0.01)
		check(w.state == "bonk","Standing remains blocked by the overhead variant: "+kind)
	w = arena()
	w.adventure.mushroom_chance = 1.0
	w.time = 10
	var intro_none := true
	for i in 100: intro_none = intro_none and w.adventure.choose_power(w) != "mushroom"
	check(intro_none,"First 20 seconds cannot force a mushroom")
	w.time = 21
	check(w.adventure.choose_power(w) == "mushroom","An explicitly configured 100 percent chance works after the intro")
	check(w.adventure.choose_power(w) != "mushroom","Even 100 percent respects the cooldown")
	w.time = 67
	check(w.adventure.choose_power(w) == "mushroom","The chance becomes eligible again after the cooldown")
	w.adventure.mushroom_chance = 0
	w.time = 10000
	var none := true
	for i in 500: none = none and w.adventure.choose_power(w) != "mushroom"
	check(none,"Zero percent genuinely disables random mushrooms")
	w = arena()
	w.adventure.mushroom_chance = 0.02
	w.rng.seed = 727
	var rare := 0
	for i in 10000:
		w.time = 100.0 + i*46
		if w.adventure.choose_power(w) == "mushroom": rare += 1
	check(rare >= 140 and rare <= 260,"A seeded large sample matches the low two-percent chance")
	w = arena()
	w.adventure.item_wait = 0.01
	w.step(0.02)
	check(w.adventure.items.size() == 1 and w.adventure.items[0].kind != "mushroom","The first normal item is no longer a mandatory nearby mushroom")
	w = arena()
	var girls := {}
	var styles := {}
	var no_repeat := true
	var last := -1
	var previous_style := -1
	for n in range(2,10):
		w.distance = (n-1)*w.adventure.LEVEL_DISTANCE
		w.adventure.level_elapsed = 30.0
		w.adventure.update_level(w)
		girls[w.adventure.girl_index] = true
		styles[w.adventure.celebration_style] = true
		no_repeat = no_repeat and w.adventure.girl_index != last and w.adventure.celebration_style != previous_style
		last = w.adventure.girl_index
		previous_style = w.adventure.celebration_style
	check(girls.size() == 8 and no_repeat,"Eight level-ups use eight identities with no consecutive repeated girl or effect")
	check(styles.size() >= 3,"Celebrations vary between multiple particle styles")
	w.distance = 9*w.adventure.LEVEL_DISTANCE
	w.adventure.level = 9
	w.adventure.level_elapsed = 30.0
	w.adventure.update_level(w)
	check(w.adventure.level == 10 and w.adventure.hugging() and w.adventure.hug_count == 1,"Level ten starts exactly one one-second hug")
	w.adventure.powers.shield = 8
	w.adventure.spawn_enemy(w,"crow",World.PLAYER_X+150,-86)
	w.obstacles = [{"x":World.PLAYER_X+300,"kind":"fire","counted":false}]
	var enemy_x: float = w.adventure.enemies[0].x
	var obstacle_x: float = w.obstacles[0].x
	var distance := w.distance
	var clock := w.time
	w.jump()
	w.adventure.request_attack(w)
	w.adventure.press_roll(w)
	advance(w,0.5)
	check(w.distance == distance and w.time == clock and w.adventure.enemies[0].x == enemy_x and w.obstacles[0].x == obstacle_x,"Hug freezes actual travel, enemies, hazards and gameplay time")
	check(w.adventure.powers.shield == 8 and w.y == 0 and w.adventure.swing_id == 0 and not w.adventure.ducking(w),"Hug freezes power timers and rejects jump/attack/roll input")
	w.state = "paused"
	var hug_left: float = w.adventure.hug_time
	advance(w,0.3)
	check(w.adventure.hug_time == hug_left,"Esc/focus pause also freezes the hug itself")
	w.state = "running"
	advance(w,0.55)
	check(not w.adventure.hugging() and w.adventure.heart_time > 1 and w.frontier.active() and w.invulnerable > 0,"After one second, hearts and grace transition into the requested boss handoff")
	w.adventure.update_level(w)
	check(w.adventure.hug_count == 1,"Repeated level checks cannot duplicate a milestone hug")
	w = arena()
	w.y = -90
	w.distance = 9*w.adventure.LEVEL_DISTANCE
	w.adventure.level = 9
	w.adventure.level_elapsed = 30.0
	w.adventure.update_level(w)
	check(not w.adventure.hugging() and w.adventure.hug_pending,"An airborne milestone waits for a real landing")
	w.distance = 19*w.adventure.LEVEL_DISTANCE
	w.adventure.level = 19
	w.adventure.level_elapsed = 30.0
	w.adventure.update_level(w)
	w.y = 0
	w.adventure.update_level(w)
	check(w.adventure.hug_level == 10 and w.adventure.hug_queue.size() == 1,"Queued airborne milestones retain the earlier ten-level hug")
	w = arena()
	w.adventure.celebrations_enabled = false
	w.distance = 9*w.adventure.LEVEL_DISTANCE
	w.adventure.level = 9
	w.adventure.level_elapsed = 30.0
	w.adventure.update_level(w)
	check(w.adventure.level == 10 and not w.adventure.hugging(),"Cosmetic celebration setting never blocks real level progress")
	w = arena()
	w.adventure.collect(w,"mushroom")
	w.invulnerable = 999
	w.adventure.gnome_wait = 0
	w.rng.seed = 77
	var counts := {}
	for i in 300:
		w.step(0.02)
		counts[w.adventure.enemies.size()] = true
	check(w.adventure.enemy_id > 7 and w.adventure.enemies.size() <= 14 and counts.size()>4,"Giant waves contain more irregularly arriving gnomes")
	w = arena()
	w.adventure.level = 4
	w.adventure.ambient_gnome_wait = 0
	w.step(0.01)
	check(w.adventure.enemies.any(func(e): return e.kind == "gnome") and not w.adventure.giant(),"Later levels can spawn an occasional gnome without a mushroom")
	w = arena()
	w.character = "owl"
	w.y = -100
	w.jump_held = true
	w.gliding = true
	w.velocity = 100
	w.gusts = [{"x":World.PLAYER_X+100,"width":360,"kind":"forward"}]
	var base_speed := w.speed()
	advance(w,0.12)
	check(w.riding_gust and w.wind_push > 0 and w.speed() > base_speed,"A real forward gust increases actual forward travel")
	w = arena()
	w.character = "owl"
	w.y = -100
	w.jump_held = true
	w.gliding = true
	w.velocity = 100
	w.gusts = [{"x":World.PLAYER_X+100,"width":360,"kind":"up"}]
	advance(w,0.2)
	check(w.velocity < 0 and w.wind_push == 0,"An upward gust lifts instead of silently granting forward speed")
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	for id in game.FRIENDS:
		for variant in 2:
			game.world.adventure.attack_variant = variant
			for frame in 6:
				game.place_combat(game.friend_sprite,id,0,frame,Vector2.ZERO,1.0,false)
				check(game.friend_sprite.scale.x == game.friend_sprite.scale.y and not game.friend_sprite.region_enabled and game.friend_sprite.texture.get_width() > 4,"A cropped alternate strike uses a uniform scale: "+id+"/"+str(variant)+"/"+str(frame))
		for frame in range(1,6):
			game.place_combat(game.friend_sprite,id,4,frame,Vector2.ZERO,1.0,true)
			check(game.friend_sprite.get_meta("pose_key") == "rolls" and game.friend_sprite.scale.x == game.friend_sprite.scale.y,"Roll is drawn rotation, never a vertically squashed pose: "+id+"/"+str(frame))
	game.queue_free()
	await process_frame
	print("RESULT: %d evolution checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
