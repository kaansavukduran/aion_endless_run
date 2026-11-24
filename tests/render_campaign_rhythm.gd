## Staged native visual fixtures; ordinary-input traversal is a separate test.
extends SceneTree
var game: AionCampaignGame
var output: String
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+label)
func _initialize() -> void:call_deferred("run")
func snap(name: String) -> void:
	game.build_ui();game.resize();game.view.queue_redraw();game.update_hud()
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	var image: Image=root.get_texture().get_image()
	check(image.get_size()==root.size,"Native viewport dimensions: "+name)
	check(image.save_png(output+"/"+name+".png")==OK,"Actual PNG saved: "+name)
func run() -> void:
	output=OS.get_environment("AION_RHYTHM_REVIEW")
	if output.is_empty():output="res://build/rhythm-review"
	DirAccess.make_dir_recursive_absolute(output);root.size=Vector2i(1280,720)
	game=AionCampaignGame.new();root.add_child(game);await process_frame
	game.set_process(false);game.world.begin("aion");game.world.state="playing";game.menu_kind="";game.presentation_stage="";game.language="tr"
	game.options.theme_mode="dark";game.options.resolve_theme();game.ui.theme=game.options.theme(game.FONT);game.touch_mode=true
	var w=game.world
	w.weapon="heavy";w.ammunition=45;w.player=Vector2(900.,0.);game.view.camera_x=600.
	w.pickups.append({"id":"offer-review","kind":"arc","x":920.,"y":-35.})
	await snap("weapon-offer")
	check(game.actions.context.visible and game.actions.context.caption==game.t("context_swap_short"),"Actual context button offers gun choice")
	w.enemies.clear();w.gates.clear();w.player=Vector2(2610.,0.);CampaignRecovery.step(w);w.invulnerable=0.;w.damage_player();game.view.camera_x=2350.
	for tick in 60:w.step(.02)
	CampaignLives.start_entry(w,Rect2(2350.,-420.,1152.,600.));w.step(.05)
	await snap("rally-return")
	check(w.state=="respawn" and w.player.x>=2350. and w.attempts_remaining==2,"Drawn entry arrives from the current view with one spent life")
	w.load_section("shore");w.enemies.clear();w.player=Vector2(5940.,-40.);game.view.camera_x=5460.
	for tick in 220:w.step(1./60.)
	await snap("shore-bridge")
	check(w.grounded() and w.crossing_floor(6220.,-42.,-39.,10.)==-40.,"Both visible bridge decks still support the player after the old collapse delay")
	w.load_section("arena");w.boss.active=true;w.boss.engaged=true;w.player=Vector2(2150.,0.);game.view.camera_x=1850.
	w.boss.phase=1;w.boss.hp=90;w.boss.ports=[3,3]
	await snap("boss-ports")
	w.boss.phase=2;w.boss.hp=55;w.boss.windup=.5;w.boss.wait=1.5
	await snap("boss-core")
	w.boss.phase=3;w.boss.hp=29;w.boss.attack=2;w.boss.windup=.7
	await snap("boss-charge-warning")
	root.size=Vector2i(393,873);await process_frame
	w.load_section("shore");w.weapon="heavy";w.ammunition=45;w.player=Vector2(900.,0.);game.view.camera_x=600.;w.pickups.append({"id":"offer-review","kind":"arc","x":920.,"y":-35.})
	await snap("portrait-offer")
	check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(root.get_final_transform()*game.screen_transform*game.actions.context.get_global_rect()),"Portrait gun choice target is inside viewport: raw="+str(root.size)+" control="+str(game.actions.context.get_global_rect())+" transform="+str(game.screen_transform)+" final="+str(root.get_final_transform()))
	game.options.text_scale=2.;game.ui.theme=game.options.theme(game.FONT)
	await snap("portrait-offer-large")
	check(not game.actions.context.get_global_rect().intersects(game.actions.attack.get_global_rect()),"200 percent actual gun choice stays separate from Fire")
	print("RESULT: %d rhythm render checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
