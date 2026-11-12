extends SceneTree
const World=preload("res://scripts/world.gd")
const Bank=preload("res://scripts/frame_bank.gd")
const Words=preload("res://scripts/text.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+label)
func arena():
	var w=World.new();w.reset();w.obstacle_wait=999;w.frontier.plant_wait=999;w.adventure.item_wait=999;w.adventure.ambient_gnome_wait=999;return w
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var w=arena()
	for kind in ["fire","ice","block_crate","block_log","pit","pit_city"]:
		w.obstacles.assign([{"kind":kind,"x":600.0,"width":180.0,"counted":false}])
		check(not w.orchard.safe(w,600,-32) and w.orchard.safe(w,1000,-32),"Fruit reserves safe clearance around "+kind)
	w.obstacles.assign([{"kind":"carrier_pipe","x":600.0,"width":180.0,"counted":false}])
	check(w.orchard.safe(w,600,-32) and not w.orchard.safe(w,600,-112),"Carrier trails stay on reachable ground, never above the flying beam")
	w.obstacles.clear();w.adventure.spawn_enemy(w,"slime",600)
	check(not w.orchard.safe(w,600,-32),"Ground-enemy hitboxes are not filled with fruit")
	w.adventure.enemies.clear();w.frontier.plants.assign([{"x":600.0}]);check(not w.orchard.safe(w,600,-32),"Fire-plant mouths are not fruit targets")
	w=arena();w.pickups.assign([{"id":1,"kind":"apple","orchard":true,"x":600.0,"y":-32.0,"taken":false}]);w.obstacles.assign([{"kind":"fire","x":600.0}]);w.orchard.step(w,0)
	check(w.pickups.is_empty(),"A later hazard revalidates and removes unsafe fruit before drawing")
	var kinds:={};var spawned:=0;var baseline:=0
	for seed_value in 32:
		w=arena();w.rng.seed=seed_value
		for n in 12:
			w.pickups.clear();w.orchard.wait_distance=0;w.orchard.step(w,1)
			baseline+=1
			for fruit in w.pickups:
				spawned+=1;kinds[fruit.kind]=true
				check(fruit.y>=-40.1 and fruit.y<=-31.9 and absf(fruit.y+35)<43,"Every generated fruit is collectible from the ground by every hero")
	check(kinds.size()==8 and spawned>=baseline*3 and spawned<=baseline*5,"Eight common fruits replace single encounter crystals with3–5-item ribbons")
	w=arena();w.pickups.assign([{"x":World.PLAYER_X,"y":-35.0,"kind":"pear","taken":false}]);w.step(.01);var score: int=w.score;w.step(.01)
	check(w.gems==1 and w.orchard.last_kind=="pear" and w.score==score and score>=25,"Collecting a fruit awards25 once and records its real kind")
	w=arena();w.orchard.wait_distance=123;w.state="paused";w.step(.02);check(w.orchard.wait_distance==123,"Pause freezes fruit scheduling")
	w.state="running";w.frontier.request_boss(10);w.step(.02);var wait_distance: float=w.orchard.wait_distance;w.step(.02)
	check(w.orchard.wait_distance==wait_distance and w.pickups.is_empty(),"Boss arenas do not spawn normal fruit ribbons")
	w=arena();w.character="rabbit";w.jump();w.step(.016);var emre_speed: float=w.velocity;w.jump();w.step(.016)
	check(w.jumps_used==1 and emre_speed<World.JUMP_SPEED,"Emre has one powerful leap and cannot double-jump")
	var bank=Bank.new();var scale_values:={}
	for key in ["emre-movement","emre-encounters"]:
		for row in 6:
			check(bank.count(key,row)==12,"Twelve actual drawn poses: "+key+"/"+str(row))
			var gaze: Array[float]=[]
			for col in 12:
				var pose: Dictionary=bank.pose(key,row,col);scale_values[pose.scale]=true
				check(pose.texture.get_image().get_pixel(0,0).a==0,"Emre frames have independent transparent padding")
				if row<2:gaze.append((pose.offset.x+pose.eye_local.x)*pose.scale)
			if row<2:check(gaze.max()-gaze.min()<.001,"Emre's complete idle/run/weapon cycle has stable horizontal gaze")
	check(scale_values.size()==1,"One Emre scale is shared by all144 movement, combat and defeat poses")
	for row in 2:
		for col in 4:
			var pose: Dictionary=bank.pose("fruits",row,col)
			check(pose.texture.get_width()>20 and pose.texture.get_image().get_pixel(0,0).a==0,"Detailed fruit art has isolated transparent margins")
	for lang in Words.LANGUAGES:
		check(Words.get_text(lang,"name_rabbit")!="name_rabbit" and Words.get_text(lang,"pad_ability_rabbit").count("%s")==1,"Emre's name and input help are localized: "+lang)
		for kind in w.orchard.KINDS:check(Words.get_text(lang,"fruit_"+kind)!="fruit_"+kind,"Fruit translated: "+lang+"/"+kind)
	var game=load("res://main.tscn").instantiate();root.add_child(game);await process_frame;game.set_physics_process(false);game.set_process(false)
	game.main_menu();game.select_character("rabbit");check(game.character=="rabbit" and game.character_name("rabbit")==Words.get_text(game.language,"name_rabbit"),"Fifth hero can be selected through the real existing menu action")
	game.start_run();game.touch_tutorial_done=true;game.begin_playing();game.world.adventure.attack(game.world);game.update_friend();check(game.friend_sprite.get_meta("source_key")=="emre-movement" and game.friend_sprite.get_meta("source_row")==3,"Actual Emre punch uses its own sprite frames")
	game.world.adventure.attack_time=0;game.world.adventure.attack_cooldown=0;game.world.adventure.attack_held=false;game.world.adventure.attack(game.world);game.update_friend();check(game.friend_sprite.get_meta("source_row")==4,"Second Emre strike uses the distinct rabbit kick")
	game.start_boss_practice(0)
	for n in 120:game.world.step(1.0/60)
	game.world.frontier.fire(game.world)
	for n in 8:game.world.step(1.0/60)
	game.update_friend();check(game.world.frontier.shots_fired>0 and game.friend_sprite.get_meta("source_key")=="emre-encounters","Emre's real boss pistol uses measured muzzle and dedicated weapon frames")
	game.queue_free();await process_frame
	print("RESULT: %d orchard/Emre checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
