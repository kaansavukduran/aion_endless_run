extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+message)
func _initialize() -> void:call_deferred("run")
func joy(button: int) -> InputEventJoypadButton:
	var value:=InputEventJoypadButton.new();value.button_index=button;value.pressed=true;return value
func run() -> void:
	var game:=AionCampaignGame.new();root.add_child(game);await process_frame;game.set_process(false);game.audio_enabled=false
	for locale in GameText.LANGUAGES:
		for key in AionCampaignText.UI.data.en:
			check(AionCampaignText.UI.data.has(locale) and AionCampaignText.UI.data[locale].has(key) and AionCampaignText.word(locale,key)!=key,"UI copy is present in actual locale: "+locale+"/"+key)
	game.world.begin("aion");game.intro_pending=true;game.menu_kind="help";game.help_step=0
	game.finish_help();check(game.presentation_stage=="intro" and game.world.state=="story","Tutorial exit enters real skippable mission presentation")
	var hp: int=game.world.hp;var time: float=game.world.time
	game.world.damage_player();game._process(.5)
	check(game.world.hp==hp and game.world.time==time,"Intro freezes simulation and protects health")
	var intro_time: float=game.presentation_time
	root.size=Vector2i(393,873);await process_frame;game.resize()
	check(game.presentation_stage=="intro" and game.presentation_time==intro_time,"Rotation does not restart the presentation")
	game._input(joy(JOY_BUTTON_A))
	check(game.presentation_stage=="" and game.world.state=="playing","Gamepad confirmation really skips to playable mission")
	game.begin_new();check(game.menu_kind=="" and game.presentation_stage=="intro","A learned tutorial is not forced again on a new mission")
	game.skip_presentation()
	game.world.weapon="heavy";game.world.ammunition=7;game.world.hp=2;game.world.shield=1;game.world.rescued.append("shore:keeper")
	game.update_hud()
	check(game.hud_panel.summary.contains("7") and game.hud_panel.summary.contains("2/3") and game.hud_panel.summary.contains("1"),"HUD responds to actual weapon, health, rescue and shield values")
	game.world.mount.ridden=true;game.world.mount.type="shell";game.update_hud();await process_frame
	check(game.hud_panel.summary.contains("∞") and not game.hud_panel.summary.contains(game.t("heavy")),"Mounted HUD shows the actual unlimited vehicle weapon rather than stowed hero ammunition")
	game.world.mount.ridden=false
	for viewport in [Vector2i(393,873),Vector2i(873,393),Vector2i(1152,648)]:
		root.size=viewport;await process_frame
		for text_scale in [1.,1.5,2.]:
			game.options.text_scale=text_scale
			for locale in GameText.LANGUAGES:
				game.language=locale;game.resize();game.world.state="paused"
				for kind in ["paused","settings","complete","result_details","help"]:
					game.menu_kind=kind;game.build_ui();await process_frame;await process_frame
					var area:=Rect2(Vector2.ZERO,Vector2(game.view_w,game.view_h))
					check(area.encloses(game.menu.get_global_rect()),"Complete menu fits: "+str(viewport)+" "+str(text_scale)+" "+locale+" "+kind)
					for button in game.buttons:check(area.encloses(button.get_global_rect()),"Actual action fits: "+button.text)
	# Junctions share the real HUD rather than presenting a choice dialog.
	for section in CampaignRoutes.FORKS:
		game.world.load_section(section);game.menu_kind="";game.presentation_stage="";game.build_ui();await process_frame;await process_frame
		check(game.menu==null and game.world.state=="playing","Physical junction has no blocking presentation: "+section)
		check(game.ui.find_children("Route_*","Button",true,false).is_empty(),"Route labels cannot become gameplay choice buttons")
	# A long real inventory must remain readable as separate report facts.
	game.world.weapons_used.assign(CampaignWeapons.SPECIAL);game.world.vehicles_used.assign(["wind","shell","drill"])
	game.options.text_scale=2.;game.language="en";root.size=Vector2i(873,393);await process_frame;game.resize();game.menu_kind="result_details"
	var pages: int=game.report_lines().size()
	for index in pages:
		game.detail_page=index;game.build_ui();await process_frame;await process_frame
		check(Rect2(Vector2.ZERO,Vector2(game.view_w,game.view_h)).encloses(game.menu.get_global_rect()),"Full weapon inventory page fits large English text: "+str(index))
	game.options.text_scale=1.;game.language="en";game.menu_kind="";game.presentation_stage="";game.world.completed=true;game.world.boss.active=false;game.world.state="victory";game.world.victory_time=1.19
	game._process(.05)
	check(game.presentation_stage=="victory" and game.world.state=="complete","Victory presentation begins only after the real boss death interval")
	game._input(joy(JOY_BUTTON_START))
	check(game.presentation_stage=="" and game.menu_kind=="outro","Start skips victory into the genuine mission conclusion")
	game.world.weapons_used.assign(["heavy"]);game.world.vehicles_used.assign(["shell"]);game.world.losses=2;game.world.kills=17;game.world.time=91.;game.world.rescue_roles={"shore:keeper":"keeper"}
	var lines:=game.report_lines()
	check(" ".join(lines).contains("17") and " ".join(lines).contains("01:31"),"Report reads actual kill count and active completion time")
	game.save_checkpoint();check(game.save_ok and game.saved.performance.has("hero:aion"),"Completed actual metrics persist by hero without changing Endless save")
	var best:=JSON.stringify(game.saved.performance);game.save_checkpoint()
	check(JSON.stringify(game.saved.performance)==best,"Repeated saving never manufactures a higher personal best")
	game.queue_free();await process_frame
	print("RESULT: %d campaign presentation checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
