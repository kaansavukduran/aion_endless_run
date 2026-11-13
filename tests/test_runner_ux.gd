extends SceneTree
const World = preload("res://scripts/world.gd")
const Bank = preload("res://scripts/frame_bank.gd")
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures+=1;printerr("FAIL: "+message)
func _initialize() -> void:call_deferred("run")
func touch(game,index: int,p: Vector2,down: bool,cancel: bool=false) -> void:
	var e:=InputEventScreenTouch.new();e.index=index;e.position=game.screen_transform*p;e.pressed=down;e.canceled=cancel;game._input(e)
func drag(game,index: int,p: Vector2) -> void:
	var e:=InputEventScreenDrag.new();e.index=index;e.position=game.screen_transform*p;game._input(e)
func button_center(game,id: String) -> Vector2:return game.action_buttons[id].get_global_rect().get_center()
func arena() -> RunnerWorld:
	var w:=World.new();w.reset();w.obstacle_wait=99999;w.adventure.item_wait=99999;w.adventure.tempo_wait=99999;w.frontier.plant_wait=99999;w.invulnerable=99999;return w
func legacy_wave(w,dt: float) -> void:
	w.adventure.gnome_wait-=dt
	if w.adventure.gnome_wait<=0:
		var alive: int=w.adventure.enemies.size()
		var count: int=mini(14-alive,w.rng.randi_range(1,3))
		for i in count:w.adventure.spawn_enemy(w,"gnome",w.field_width+60+i*w.rng.randf_range(85,220)).wave=true
		w.adventure.gnome_wait=w.rng.randf_range(.18,1.30)
func population_tests() -> void:
	var rows:=[];var before:=0;var after:=0
	for seed_value in 128:
		var old:=arena();var now:=arena();old.rng.seed=seed_value+1;now.rng.seed=seed_value+1
		for tick in 500:
			legacy_wave(old,.02);now.adventure.update_mushroom_wave(now,.02)
			for w in [old,now]:
				for e in w.adventure.enemies:e.x-=8.0
				w.adventure.enemies=w.adventure.enemies.filter(func(e):return e.x>-100)
		before+=old.adventure.enemy_id;after+=now.adventure.enemy_id
		rows.append({"seed":seed_value+1,"legacy_total":old.adventure.enemy_id,"new_total":now.adventure.enemy_id})
	var ratio:=float(after)/before
	print("MUSHROOM_TOTALS old=%d new=%d ratio=%.4f (128 seeds, 10s, 400px/s)" % [before,after,ratio])
	check(ratio>=.40 and ratio<=.60,"Total actual mushroom spawns are approximately half across fixed seeds, not merely the alive cap")
	var file:=FileAccess.open("user://mushroom-comparison.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"seconds":10,"speed":400,"before":before,"after":after,"ratio":ratio,"seeds":rows},"  "));file.close()
	var w:=arena();w.adventure.level=4;w.adventure.ambient_gnome_wait=0;w.adventure.after_step(w,.01,0,0)
	check(w.adventure.enemies.size()==1 and not w.adventure.enemies[0].wave,"Ambient gnomes remain a separate unthinned source")
func model_tests() -> void:
	for dt in [.01,.02,1.0/30]:
		var w:=arena();w.adventure.level_elapsed=0
		for i in roundi(15.0/dt):
			w.adventure.before_step(w,dt);w.adventure.update_level(w)
		check(w.adventure.level==2,"Fifteen active seconds produce a level at different step rates")
		check(w.adventure.level_elapsed<.04 and w.distance==0,"Distance does not delay the new timer or add a catch-up level")
	var w:=arena();w.adventure.level_elapsed=19;w.state="paused";w.step(.02)
	check(w.adventure.level_elapsed==19,"Pause freezes level time")
	w.state="running";w.step(40)
	check(w.adventure.level_elapsed==19 and w.adventure.level==1,"A long background-tab frame cannot create catch-up levels")
	w.adventure.hug_time=1;w.step(.02)
	check(w.adventure.level_elapsed==19,"Hug freezes normal level time")
	w=arena();w.frontier.request_boss(100);w.step(.02)
	check(w.adventure.level_elapsed==0,"Boss introduction freezes normal level time")
	for milestone in [10,20,30,40,100,200,300]:
		w=arena();w.frontier.request_boss(milestone);w.frontier.begin(w)
		check(w.frontier.boss_kind==posmod(milestone/10-1,3),"Boss designs keep rotating after the first three milestones")
	w=arena();w.adventure.level=99;w.adventure.offer_fragaria(w,90)
	check(w.adventure.items.is_empty(),"No rare strawberry before a hundred-level threshold")
	w.adventure.level=100;w.adventure.offer_fragaria(w,100);w.adventure.offer_fragaria(w,110)
	check(w.adventure.items.size()==1 and w.adventure.items[0].kind=="fragaria","The first eligible boss offers exactly one strawberry per threshold")
	w.adventure.level=200;w.adventure.offer_fragaria(w,200)
	check(w.adventure.items.size()==2 and w.adventure.fragaria_next_level==300,"Next hundred-level threshold can offer another strawberry")
	var powers: Dictionary=w.adventure.powers.duplicate();var score: int=w.adventure.bonus_score;var collected: int=w.adventure.items_collected;var gems: int=w.gems
	w.adventure.collect(w,"fragaria")
	check(w.adventure.fragaria_time>0 and w.adventure.fragaria_found==1,"Collecting Fragaria starts its short celebration")
	check(w.adventure.powers==powers and w.adventure.bonus_score==score and w.adventure.items_collected==collected and w.gems==gems and not w.adventure.discoveries.has("fragaria"),"Fragaria gives no buff, score, crystal, goal progress or power discovery")
	w=arena();w.practice=true;w.adventure.level=100;w.adventure.offer_fragaria(w,100)
	check(w.adventure.items.is_empty(),"Boss training cannot manufacture the rare collectible")
func registration_tests() -> void:
	# Independent, visually reviewed near-iris samples. These catch selecting
	# a different body part even if metadata's own alignment math is consistent.
	var golden:={"aion":[[109,40],[98,40],[99,40],[99,42],[98,41],[99,41],[100,41]],"owl":[[96,54],[90,54],[88,54],[87,55],[92,55],[88,55],[89,55]],"sheep":[[83,67],[70,69],[70,68],[73,66],[71,64],[73,66],[72,67]],"wolf":[[77,58],[74,57],[75,58],[75,57],[74,57],[74,58],[75,57],[73,58]]}
	var bank:=Bank.new()
	var idle: Array=bank.CANONICAL.data.atlases["canonical-owl"].frames[0]
	check(idle[3].blink and idle[4].blink and absf(float(idle[3].eye[0])-84)<3 and absf(float(idle[4].eye[0])-85)<3,"Closed owl eyes interpolate the near iris across real atlas gutters, never the beak or chin")
	for hero in golden:
		var d: Dictionary=bank.CANONICAL.data.atlases["canonical-"+hero]
		var item:=Sprite2D.new();item.centered=false
		for frame in golden[hero].size():
			var f: Dictionary=d.frames[1][frame]
			check(Vector2(f.eye[0],f.eye[1]).distance_to(Vector2(golden[hero][frame][0],golden[hero][frame][1]))<2,"Correct near iris, not far eye, gill, halo or beak: "+hero+str(frame))
			bank.place(item,"runner-"+hero,1,frame,Vector2(288,500))
			check(is_equal_approx(item.position.x,288) and is_equal_approx(item.scale.x,d.scale[1]),"Sprite physics anchor and per-hero scale stay constant through the full run loop")
		item.free()
func scene_tests() -> void:
	var save_path:="user://save.cfg";var original:=FileAccess.get_file_as_bytes(save_path) if FileAccess.file_exists(save_path) else PackedByteArray()
	var game=load("res://main.tscn").instantiate();root.add_child(game);await process_frame;game.set_physics_process(false)
	game.touch_mode=true;game.touch_tutorial_done=false;game.motion=true;game.main_menu();game.select_character("aion");game.start_run()
	check(game.tutorial_waiting(),"The first phone run shows its short skippable tutorial")
	for i in 250:game._physics_process(.02)
	check(game.world.time==0 and game.world.adventure.level_elapsed==0 and game.world.obstacles.is_empty(),"Reading the first tutorial cannot advance levels or kill an idle player")
	game.press_shoot("key")
	check(not game.tutorial_waiting() and game.world.frontier.ammo==4,"The first real gameplay action dismisses the tutorial and starts normally")
	game.release_shoot("key");game.main_menu();game.start_run();game.world.obstacle_wait=99999;game.world.adventure.item_wait=99999;game.world.frontier.plant_wait=99999
	var p: Vector2=button_center(game,"shoot")
	touch(game,0,p,true)
	check(game.world.frontier.ammo==4 and game.world.adventure.attack_time==0,"Actual touch Fire button spends one round")
	for i in 80:game.world.step(.02);game.touch_controls.step(.02)
	check(game.world.frontier.shots_fired==5 and game.world.frontier.ammo==0,"Holding Fire stops after exactly five rounds")
	touch(game,0,p,false);touch(game,0,p,true)
	check(game.world.frontier.ammo==0,"A fresh trigger cannot fire an empty magazine")
	drag(game,0,p+Vector2(160,0));touch(game,0,p+Vector2(160,0),false)
	check(game.attack_sources.is_empty() and game.touch_controls.fingers.is_empty(),"Sliding off and releasing cannot leave attack held")
	game.start_run();game.world.obstacle_wait=99999
	p=Vector2(450,280);touch(game,1,p,true);drag(game,1,p+Vector2(4,72));touch(game,1,p+Vector2(4,72),false);game.world.step(.01)
	check(game.world.adventure.ducking(game.world) and game.world.y==0 and game.world.jumps_used==0,"A downward swipe rolls once with no accidental jump or strike")
	check(game.touch_controls.swipe_count==1 and game.touch_controls.fingers.is_empty() and not game.world.adventure.duck_held,"One completed swipe produces one timed roll and releases the finger")
	game.start_run();touch(game,1,p,true);drag(game,1,p+Vector2(100,8));touch(game,1,p+Vector2(100,8),false);game.world.step(.01)
	check(game.world.y==0 and game.world.adventure.roll_time==0,"Horizontal movement is neither a downward roll nor a tap jump")
	p=button_center(game,"jump");touch(game,0,p,true);touch(game,2,button_center(game,"shoot"),true);game.world.step(.02)
	check(game.world.y<0 and game.world.frontier.ammo==4,"Independent jump and attack fingers work together")
	touch(game,0,p,false,true);touch(game,2,button_center(game,"shoot"),false,true)
	check(not game.world.jump_held and not game.world.adventure.attack_held and game.touch_controls.fingers.is_empty(),"Touch cancellation clears every held action")
	game.start_run();game.action_buttons.attack.disabled=true
	touch(game,0,button_center(game,"attack"),true);touch(game,0,button_center(game,"attack"),false);game.world.step(.01)
	check(game.world.y==0 and game.world.adventure.swing_id==0,"A disabled action circle consumes its touch without leaking a world-tap jump")
	game.action_buttons.attack.disabled=false;touch(game,0,button_center(game,"attack"),true);game.world.state="bonk";touch(game,0,button_center(game,"attack"),false)
	check(game.attack_sources.is_empty() and game.touch_controls.fingers.is_empty(),"Releasing a finger after defeat cannot leave a held attack")
	game.start_run();var enemy: Dictionary=game.world.adventure.spawn_enemy(game.world,"crow",World.PLAYER_X+85,-40)
	touch(game,0,button_center(game,"shoot"),true)
	for i in 18:game.world.step(.01)
	check(enemy.hp==0 and game.world.adventure.kills==1,"A normal touch shot reaches actual crow damage, not only its animation")
	touch(game,0,button_center(game,"attack"),false)
	for lang in ["tr","en","cs"]:
		game.language=lang;game.main_menu()
		for key in ["touch_hint","touch_skip","touch_ability_aion","touch_ability_owl","touch_ability_wolf","touch_ability_sheep","fragaria_found","fragaria_note"]:check(game.text(key)!=key,"New player-facing copy is translated: "+lang+"/"+key)
		for target in ["main","paused","finished","settings","characters","bosses"]:
			game.page=target;game.rebuild();await process_frame;await process_frame
			var scrolls: Array=game.menu_layer.find_children("*","ScrollContainer",true,false)
			check(scrolls.size()==(1 if target=="settings" else 0),"Only long settings use scrolling: "+lang+"/"+target)
			if target=="settings":
				scrolls[0].scroll_vertical=100000
				await process_frame;await process_frame
				var back_button: Button=scrolls[0].find_children("*","VBoxContainer",false,false)[0].get_children()[-1]
				check(scrolls[0].get_global_rect().encloses(back_button.get_global_rect()),"The last settings action is reachable by real scrolling")
			for control in game.menu_layer.find_children("*","Button",true,false):
				if target!="settings" and control.is_visible_in_tree():check(Rect2(Vector2.ZERO,Vector2(game.view_w,game.view_h)).encloses(control.get_global_rect()),"Menu action fits on screen: "+lang+"/"+target+"/"+str(control.name))
	game.queue_free();await process_frame
	if original.is_empty():DirAccess.remove_absolute(save_path)
	else:
		var file:=FileAccess.open(save_path,FileAccess.WRITE);file.store_buffer(original);file.close()
func run() -> void:
	registration_tests();model_tests();population_tests();await scene_tests()
	print("RESULT: %d runner UX checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
