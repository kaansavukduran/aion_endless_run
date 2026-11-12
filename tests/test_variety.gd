extends SceneTree
const World=preload("res://scripts/world.gd")
const Words=preload("res://scripts/text.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1;printerr("FAIL: "+label)
func arena():
	var w=World.new();w.reset();w.obstacle_wait=999;w.frontier.plant_wait=999;w.adventure.item_wait=999;w.adventure.ambient_gnome_wait=999;return w
func _initialize() -> void:call_deferred("run")
func run() -> void:
	for kind in ["crow","gnome","bat","wisp","slime","beetle"]:
		for stomp in [false,true]:
			var w=arena();var enemy=w.adventure.spawn_enemy(w,kind,500)
			check(enemy.hp==1 and enemy.max_hp==1,"One HP: "+kind)
			w.adventure.hit_enemy(w,enemy,1,stomp)
			check(enemy.hp<=0 and w.adventure.kills==1 and w.adventure.run_xp==(15 if stomp else 10),"One contact grants correct XP: "+kind)
			w.adventure.hit_enemy(w,enemy,1,stomp)
			check(w.adventure.kills==1 and w.adventure.run_xp==(15 if stomp else 10),"No duplicate kill/XP: "+kind)
	var w=arena();w.adventure.collect(w,"lightning")
	var near=w.adventure.spawn_enemy(w,"slime",World.PLAYER_X+260)
	var far=w.adventure.spawn_enemy(w,"bat",World.PLAYER_X+1250,-110)
	var above=w.adventure.spawn_enemy(w,"crow",World.PLAYER_X+500,-230)
	var behind=w.adventure.spawn_enemy(w,"gnome",World.PLAYER_X-80)
	var beyond=w.adventure.spawn_enemy(w,"gnome",World.PLAYER_X+1700)
	w.frontier.plants.assign([{"x":World.PLAYER_X+800,"hp":1,"age":1.0,"shot":true,"hurt":0.0,"last_swing":-1}])
	w.adventure.attack(w)
	check(w.adventure.lightning_charges==2,"Melee never spends lightning")
	check(w.adventure.cast_lightning(w),"Manual bolt casts")
	check(near.hp==0 and far.hp==0 and w.frontier.plants[0].hp==0 and w.adventure.run_xp==30,"1500-step area hits near/far/plant targets")
	check(above.hp==1 and behind.hp==1 and beyond.hp==1,"Corridor respects height, direction and range")
	check(not w.adventure.cast_lightning(w) and w.adventure.lightning_charges==1,"Bolt cooldown cannot spend a second charge")
	w.state="paused";w.step(.02)
	check(w.adventure.lightning_cooldown==w.adventure.LIGHTNING_COOLDOWN,"Pause freezes bolt cooldown")
	w=arena();var wave=w.adventure.spawn_enemy(w,"gnome",700);wave.wave=true;w.adventure.end_wave(w)
	check(w.adventure.run_xp==0 and w.adventure.kills==0,"Wave cleanup awards no XP or kill")
	w.adventure.collect(w,"fragaria")
	check(w.adventure.run_xp==0 and w.adventure.bonus_score==0,"Fragaria remains cosmetic")
	w=arena();w.adventure.run_xp=100
	check(w.adventure.mastery_rank()==2 and w.adventure.level==1,"XP mastery does not silently change timed levels")
	w.adventure.collect(w,"spring");w.jump();w.step(.01)
	check(w.velocity < -World.JUMP_SPEED*-1 and w.adventure.size_multiplier()==1,"Spring increases jump impulse without resizing")
	w=arena();w.adventure.collect(w,"fortune");w.pickups.assign([{"x":World.PLAYER_X,"y":-35.0,"taken":false}]);w.step(.01)
	check(w.gems==1 and w.adventure.bonus_score==40,"Fortune grants another 25 per crystal, plus normal item pickup")
	w=arena();var control=arena();w.adventure.collect(w,"frost")
	var cold=w.adventure.spawn_enemy(w,"beetle",World.PLAYER_X+250)
	var normal=control.adventure.spawn_enemy(control,"beetle",World.PLAYER_X+250)
	w.step(.01);control.step(.01)
	check(cold.x>normal.x and is_equal_approx(w.distance,control.distance),"Frost slows an approaching enemy, not the runner or obstacles")
	for kind in ["spring","fortune","frost"]:
		w=arena();w.adventure.collect(w,kind);w.adventure.powers[kind]=.001;w.step(.01)
		check(w.adventure.powers[kind]==0,"New buff expires: "+kind)
	for milestone in [10,20,30,40,100]:
		w=arena();w.character="sheep";w.sheep_count=3;w.distance=1250;w.frontier.request_boss(milestone);w.step(.01)
		w.frontier.phase="victory";w.frontier.hp=0;w.frontier.stage_time=1.59
		var normal_distance: float=w.distance
		var old_travel: float=w.travel_distance();var continuous:=true;var frozen:=true;var seen_return:=false
		for n in 160:
			w.step(.01)
			var jump: float=w.travel_distance()-old_travel
			continuous=continuous and jump>=0 and jump<8
			old_travel=w.travel_distance()
			if w.frontier.active():frozen=frozen and w.distance==normal_distance and w.adventure.level_elapsed==0
			seen_return=seen_return or w.frontier.phase=="return"
		check(continuous and seen_return and not w.frontier.active(),"Smooth monotonic exit including return phase: "+str(milestone))
		check(frozen and w.sheep_count==3 and w.trail.size()<150,"Boss freezes normal progression, retains flock: "+str(milestone))
		check(w.obstacles.is_empty() and w.adventure.enemies.is_empty(),"Safe clear runway after boss: "+str(milestone))
	w=arena();w.adventure.powers.haste=.02;w.frontier.request_boss(10);w.step(.01)
	w.frontier.phase="victory";w.frontier.hp=0;w.frontier.stage_time=1.59;w.step(.02);w.step(.04)
	check(w.frontier.phase=="return" and is_equal_approx(w.adventure.powers.haste,.02),"A nearly expired haste stays frozen through return, avoiding an expire/restore speed bounce")
	while w.frontier.active(): w.step(.01)
	w.step(.03)
	check(w.adventure.powers.haste==0,"Restored buff expiry resumes only after normal play returns")
	var seen:={};var repeats:=0;var prior:=""
	w=arena();w.rng.seed=829141;w.adventure.level=6
	for n in 400:
		w.distance=n*2000;w.adventure.spawn_encounter(w)
		seen[w.adventure.last_encounter]=true
		repeats+=1 if prior==w.adventure.last_encounter else 0
		prior=w.adventure.last_encounter
		check(w.adventure.spawn_gap>=680,"Encounter spacing keeps reaction room")
		w.obstacles.clear();w.pickups.clear();w.adventure.enemies.clear()
	check(seen.size()>=17,"Seeded encounters include new creatures and varied parkour")
	for index in 18:
		w.distance=index*World.BIOME_DISTANCE
		check(w.biome()==index%6,"All six biomes cycle: "+str(index))
	var game=load("res://main.tscn").instantiate();root.add_child(game);await process_frame;game.set_physics_process(false);game.set_process(false)
	for lang in Words.LANGUAGES:
		game.set_language(lang);await process_frame
		var complete:=true
		for key in Words.STRINGS.en:
			var value: String=game.text(key)
			complete=complete and value!=key and not value.is_empty() and value.count("%d")==Words.STRINGS.en[key].count("%d") and value.count("%s")==Words.STRINGS.en[key].count("%s")
		check(complete,"All 208 strings and format slots: "+lang)
		var font: Font=game.interface_options.body_font
		for sample in {"az":"ƏəĞğŞşİı","ja":"日本語跳躍森","ko":"한국어번개양","zh":"中文闪电跳跃"}.get(lang,""):
			check(font.has_char(sample.unicode_at(0)),"Offline glyph "+lang+" "+sample)
		game.toggle_language_picker();await process_frame;await process_frame
		await process_frame;await process_frame
		var selected: Control=game.language_picker.find_child("Language_"+lang,true,false)
		var clip: Control=game.language_picker.find_child("LanguageScroll",true,false)
		check(clip.get_global_rect().grow(2).encloses(selected.get_global_rect()),"Selected language really scrolls into the touch viewport: "+lang)
		check(game.language_picker.size.y<=game.view_h-90,"Eleven-language picker fits viewport: "+lang)
		game.toggle_language_picker()
	var fill: StyleBoxFlat=game.xp_progress.get_theme_stylebox("fill")
	var background: StyleBoxFlat=game.xp_progress.get_theme_stylebox("background")
	check(absf(fill.bg_color.get_luminance()-background.bg_color.get_luminance())>0.2,"The earned XP fill visibly differs from its background")
	game.main_menu();game.start_run();game.world.adventure.collect(game.world,"lightning");game.update_hud()
	check(game.action_buttons.shoot.visible and game.action_buttons.attack.visible and game.action_buttons.duck.visible,"Normal mobile layout exposes lightning alongside melee and roll")
	check(not game.action_buttons.shoot.get_global_rect().intersects(game.action_buttons.attack.get_global_rect()),"Bolt and melee touch areas are distinct")
	game.press_shoot("mouse");game.press_shoot("mouse")
	check(game.world.adventure.lightning_charges==1,"Holding right click casts once")
	game.release_shoot("mouse");game.world.adventure.lightning_cooldown=0;game.press_shoot("pad")
	check(game.world.adventure.lightning_charges==0,"A fresh gamepad edge uses the same bolt action")
	game.queue_free();await process_frame
	print("RESULT: %d variety/transition/locale checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
