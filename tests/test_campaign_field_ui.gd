extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	checks+=1
	if condition:return
	failures+=1
	printerr("FAIL: "+description)

func activate(game: AionCampaignGame, target: String) -> void:
	var button: Button=game.menu.find_child(target,true,false)
	check(is_instance_valid(button) and button.is_visible_in_tree() and not button.disabled,"Available field menu action "+target)
	if not is_instance_valid(button) or button.disabled:return
	button.grab_focus()
	var event:=InputEventJoypadButton.new()
	event.button_index=JOY_BUTTON_A
	event.pressed=true
	game._input(event)
	event.pressed=false
	game._input(event)
	await process_frame
	await process_frame

func check_layout(game: AionCampaignGame, description: String) -> void:
	var area:=Rect2(Vector2.ZERO,Vector2(game.view_w,game.view_h))
	check(area.encloses(game.menu.get_global_rect()),description+" "+str(game.menu.get_global_rect())+" / "+str(area))
	for button in game.buttons:
		check(area.encloses(button.get_global_rect()),description+" button "+button.name+" "+str(button.get_global_rect()))

func run() -> void:
	var game:=AionCampaignGame.new()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.audio_enabled=false
	game.begin_new()
	game.world.load_section("fork_one")
	game.world.player=Vector2(1430.,CampaignRoutes.UPPER_FLOOR)
	game.world.activated["fork_one:technician:relay_part"]=true
	game.world.discovered[CampaignStory.clue_id("story_pump")]=true
	game.world.discovered["map:section:canopy"]=true
	game.world.rally["x"]=500.
	game.toggle_pause()
	await process_frame
	await process_frame
	check(game.menu_kind=="paused" and game.world.state=="paused","Normal pause opens field navigation")
	await activate(game,"CampaignMap")
	check(game.menu_kind=="map" and game.world.state=="paused","Gamepad opens map without advancing the encounter")
	check(CampaignFieldUI.layer_key(game.world)=="upper","Map derives upper deck from real feet")
	check(CampaignFieldUI.visited(game.world).has("canopy"),"Previously seen map sections remain visited")
	check(CampaignFieldUI.goal_key(game.world)=="pump_hint","Actual part provides the next pump goal")
	check(CampaignFieldUI.checkpoint(game).contains(CampaignFieldUI.text(game,"checkpoint_flag")),"Last checkpoint reads real supply flag")
	await activate(game,"CampaignMapPassages")
	check(CampaignFieldUI.screen_summary(game).contains(CampaignFieldUI.text(game,"visited")),"Map branch status has a textual equivalent")
	check(CampaignFieldUI.screen_summary(game).contains(CampaignStory.latest_note(game.world,game.language)),"Discovered story clue has a textual equivalent")
	game.world.player.y=CampaignRoutes.LOWER_FLOOR+72.
	game.world.activated["fork_one:pump"]=true
	check(CampaignFieldUI.layer_key(game.world)=="dry","Map follows the actor into the drained channel")
	check(CampaignFieldUI.map_routes(game).any(func(line):return line.contains(CampaignFieldUI.text(game,"dry"))),"The real pump appears as drained in route notes")
	var restored:=AionCampaignWorld.new()
	check(restored.restore(game.world.snapshot()),"Map and mechanism progress loads using existing save path")
	check(restored.discovered.has("map:section:canopy") and restored.activated.has("fork_one:pump"),"Visited and opened state survive continue")

	await activate(game,"CampaignMapBack")
	await activate(game,"CampaignEquipment")
	game.world.ammunition=0
	game.hud_panel.refresh()
	check(game.hud_panel.summary.contains(CampaignFieldUI.text(game,"fists")),"Empty visible stock identifies fists")
	game.world.ammunition=4
	game.world.grenades=0
	game.hud_panel.refresh()
	check(game.hud_panel.summary.contains(" · 4") and game.hud_panel.summary.contains(game.t("grenade")+" 0"),"HUD shows actual rounds and zero grenades")
	await activate(game,"CampaignEquipmentPage")
	check(not CampaignUpgrades.available(game.world),"Unrescued run cannot choose a spend")
	check(game.menu.find_child("CampaignUpgrade_guard",true,false).disabled,"Locked upgrade uses a real disabled action")
	game.world.rescued.append("shore:keeper")
	game.build_ui()
	await process_frame
	await process_frame
	await activate(game,"CampaignUpgrade_guard")
	check(CampaignUpgrades.selected(game.world,"guard") and not CampaignUpgrades.available(game.world),"A rescue unlocks a single saved choice")
	check(not CampaignUpgrades.choose(game.world,"insight"),"A second activation cannot spend the same rescue")
	var shield_world:=AionCampaignWorld.new()
	check(shield_world.restore(game.world.snapshot()) and CampaignUpgrades.selected(shield_world,"guard"),"Selected upgrade survives save/load")
	shield_world.invulnerable=0.
	shield_world.shield_charge=0.
	for _frame in 32:CampaignLives.step_protection(shield_world,.1)
	check(shield_world.shield_ready(),"Resistance speeds the real shield recharge")
	var frog:=AionCampaignWorld.new()
	frog.begin("frog");frog.state="paused";frog.rescued.append("shore:keeper")
	check(CampaignUpgrades.choose(frog,"spark"),"Magic can be activated in the real encounter state")
	frog.state="playing";frog.frog_cooldown=5.
	MissionHeroAbilities.step(frog,.4)
	check(is_equal_approx(frog.frog_cooldown,4.5) and is_equal_approx(float(MissionHeroAbilities.context(frog).remaining),3.6),"Magic affects the actual cooldown and its visible time")

	game.world.weapon="rocket";game.world.ammunition=8
	game.world.buffs={"haste":12.,"power":12.,"magnet":12.,"reveal":12.}
	for viewport in [Vector2i(393,873),Vector2i(873,393),Vector2i(700,701),Vector2i(1152,648)]:
		root.size=viewport
		await process_frame
		for locale in ["tr","en"]:
			game.language=locale
			for scale in [1.,2.]:
				game.options.text_scale=scale
				game.resize(false)
				game.menu_kind=""
				game.world.state="playing"
				game.build_ui()
				await process_frame
				var objective:=game.subtitle.get_global_rect()
				var bounds:=Rect2(Vector2.ZERO,Vector2(game.view_w,game.view_h))
				var line_height:=game.subtitle.get_theme_font("font").get_height(game.subtitle.get_theme_font_size("font_size"))
				check(game.subtitle.visible and bounds.encloses(objective) and objective.position.y>=game.hud_panel.strip_height and objective.size.y<5.*line_height,"Visible %s %.1f objective stays within the playable mobile region"%[locale,scale])
				check(not objective.intersects(game.pause_button.get_global_rect()),"Objective stays clear of Pause")
				check(game.subtitle.get_theme_stylebox("normal") is StyleBoxFlat,"Objective text has a theme-aware backing")
				game.world.state="paused"
				for kind in ["paused","map","equipment"]:
					var pages: Array=[0] if kind=="paused" else ([0,1,2] if CampaignFieldUI.compact_panel(game) else [0,1])
					for index in pages:
						game.menu_kind=kind
						game.set_meta("field_page",index)
						game.build_ui()
						await process_frame
						await process_frame
						check_layout(game,"%s %s %.1f %s %d"%[viewport,locale,scale,kind,index])
	game.queue_free()
	await process_frame
	print("RESULT: %d campaign field UI checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
