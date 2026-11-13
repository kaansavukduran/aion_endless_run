## Explicit deterministic scene fixtures; browser tests cover normal input separately.
extends SceneTree
const World=preload("res://scripts/world.gd")
const Words=preload("res://scripts/text.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+message)
func _initialize():call_deferred("run")
func arena():
	var w=World.new();w.reset();w.obstacle_wait=999;w.adventure.item_wait=999;w.adventure.ambient_gnome_wait=999;w.frontier.plant_wait=999;return w
func run():
	for milestone in [5,10,15,20,25,30,35,100,200,300]:
		for celebrations in [true,false]:
			var w=arena();w.adventure.celebrations_enabled=celebrations;w.adventure.level=milestone-1;w.adventure.level_elapsed=15;w.adventure.update_level(w)
			for i in 105:w.step(.01)
			check(w.frontier.storytelling() and w.frontier.milestone==milestone,"Every fifth level enters one cinematic, with/without tenth-level hug: "+str(milestone)+str(celebrations))
			check(w.frontier.boss_kind==posmod(milestone/5-1,3),"All three boss types rotate beyond the first cycle")
	var w=arena();w.frontier.request_boss(5);w.step(.01)
	var t: float=w.time;var distance: float=w.distance;var level: float=w.adventure.level_elapsed;var travel: float=w.travel_distance();var hp: int=w.frontier.hp
	w.jump();w.frontier.shoot_held=true
	for i in 200:w.step(.01)
	check(w.time==t and w.distance==distance and w.adventure.level_elapsed==level and w.travel_distance()==travel and w.y==0,"Cinematic freezes gameplay, chase travel, physics and level clocks")
	check(w.frontier.hp==hp and w.frontier.shots_fired==0,"Story inputs cannot damage a boss or fire behind a dialogue")
	var old: float=w.frontier.story_time;w.state="paused";w.step(.02)
	check(w.frontier.story_time==old,"Pause freezes cinematic time and preserves beat")
	w.state="running"
	for i in 205:w.step(.01)
	check(w.frontier.story_index==0,"Dialogue waits for deliberate Continue rather than rushing the reader")
	w.frontier.next_story(w)
	check(w.frontier.story_index==1,"Continue advances to the shocked hero")
	w.frontier.next_story(w)
	check(w.frontier.story_index==2 and not w.frontier.red_weapon,"Ally handoff is a separate visible beat")
	w.frontier.next_story(w)
	check(w.frontier.phase=="intro" and w.frontier.red_weapon and not w.frontier.shoot_held,"Completing the handoff grants a red gun and clears the trigger")
	for i in 165:w.step(.01)
	check(w.frontier.phase=="fight","Chase begins after a smooth entrance, not during the story")
	w.frontier.fire(w)
	for i in 10:w.step(.01)
	check(w.frontier.projectiles.any(func(p):return p.owner=="hero" and p.red and p.damage==2),"Upgraded shots are real red projectiles carrying twice boss damage")
	w.frontier.projectiles.assign([{"owner":"hero","kind":"energy","x":w.frontier.boss_x,"y":w.frontier.boss_y,"vx":0.,"vy":0.,"r":8.,"red":true,"damage":2}]);hp=w.frontier.hp;w.frontier.update_projectiles(w,.01)
	check(w.frontier.hp==hp-2,"Collision consumes one red projectile and deals exactly two HP")
	w.frontier.finish(w);check(w.frontier.red_weapon,"Red pistol remains available after a boss")
	w.reset();check(not w.frontier.red_weapon,"A new run resets the upgrade")
	for skip_at in 3:
		w=arena();w.frontier.request_boss(5);w.step(.01)
		for i in skip_at:w.frontier.next_story(w)
		w.frontier.next_story(w,true)
		check(w.frontier.phase=="intro" and w.frontier.red_weapon,"Skip at any beat reaches the same armed playable state")
	for lang in Words.LANGUAGES:
		var lines:={}
		check(Words.get_text(lang,"boss_fight")==Words.get_text(lang,"firearm_hint"),"Boss instructions never resurrect the removed reload mechanic: "+lang)
		for kind in 3:
			var line:=Words.get_text(lang,"story_taunt_"+str(kind));lines[line]=true
			check(not line.begins_with("story_"),"Real translated boss taunt: "+lang)
		check(lines.size()==3,"Each boss has distinct dialogue in "+lang)
	var game=load("res://main.tscn").instantiate();root.add_child(game);await process_frame;game.set_physics_process(false);game.touch_tutorial_done=true
	for dims in [Vector2i(1152,648),Vector2i(393,873),Vector2i(873,393)]:
		root.size=dims;await process_frame
		for scale_value in [1.,2.]:
			game.touch_mode=true;game.interface_options.text_scale=scale_value;game.build_theme();game.ui.theme=game.ui_theme
			for lang in Words.LANGUAGES:
				game.language=lang;game.start_run();game.update_hud()
				var band: Control=game.hud.get_node("ScoreBand")
				var stats: Control=game.hud.get_node("ScoreStats")
				await process_frame;await process_frame
				check(band.size.y<=76 and stats.get_global_rect().end.x+4<=game.pause_button.position.x,"Compact score and readable Pause fit without overlap "+lang+str(dims)+str(scale_value))
				game.world.frontier.request_boss(5);game.world.step(.01);game.rebuild()
				for beat in 3:
					game.world.frontier.story_index=beat;game.update_friend();game.update_hud();await process_frame;await process_frame
					var screen:=Rect2(0,0,game.view_w,game.view_h)
					check(screen.encloses(game.story_ui.panel.get_global_rect()),"Translated story fits viewport at chosen text scale "+lang+str(dims)+str(scale_value)+str(beat))
					for item in [game.story_ui.next_button,game.story_ui.skip_button]:check(item.is_visible_in_tree() and screen.encloses(item.get_global_rect()),"Cinematic action remains visible and reachable")
					check(game.world.y==0 and absf(game.friend_sprite.get_meta("foot_world").y-game.ground)<=.501,"Cinematic hero stays on the real ground")
	game.language="en";game.main_menu();game.start_run();game.world.frontier.request_boss(5);game.world.step(.01);game.update_hud()
	game.press_shoot("key");game.press_jump("key");game.press_duck("key")
	check(game.shoot_sources.is_empty() and game.jump_sources.is_empty() and game.duck_sources.is_empty(),"Shared gameplay routes cannot latch held input behind the cinematic")
	game.story_ui.next_button.grab_focus();var button:=InputEventJoypadButton.new();button.button_index=JOY_BUTTON_A;button.pressed=true;game.gamepad.handle(button)
	check(game.world.frontier.story_index==1,"Gamepad A activates the actual focused cinematic Continue button")
	game.story_ui.skip();check(game.world.frontier.phase=="intro" and game.shoot_sources.is_empty(),"Actual Skip action safely returns control")
	game.queue_free();await process_frame
	print("RESULT: %d boss story checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
