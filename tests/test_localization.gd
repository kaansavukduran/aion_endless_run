extends SceneTree
const Words = preload("res://scripts/text.gd")
var checks := 0
var failures := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	for pair in [["tr-TR","tr"],["TR_tr","tr"],["en-GB","en"],["cs-CZ","en"],["CS_cz","en"],["de-DE","en"],["fr","en"],["ja-JP","en"],["ko_KR","en"],["zh-Hant-TW","en"],["az-AZ","en"],["es-ES","en"],["it-IT","en"],["cz","en"],["","en"]]:
		check(Words.language_for_locale(pair[0]) == pair[1], "Current TR/EN locale selection: " + pair[0])
	check(Words.LANGUAGES==["tr","en"],"Only the explicitly requested Turkish and English are selectable")
	var names := {"tr":["Aion","Kutsanmış","Ayça","Eren","Armadillo","Kurbağa"],"en":["Aion","Kutsanmış","Ayça","Eren","Armadillo","Frog"]}
	for lang in Words.LANGUAGES:
		var table: Dictionary = Words.EXTRA[lang].data if Words.EXTRA.has(lang) else Words.STRINGS[lang]
		var complete: bool = table.size() == Words.STRINGS.en.size()
		for key in Words.STRINGS.en:
			complete = complete and table.has(key) and not Words.get_text(lang,key).is_empty() and Words.get_text(lang,key).count("%d") == Words.get_text("en",key).count("%d")
		check(complete, "Complete localized UI with matching numeric placeholders: " + lang)
		var actual: Array[String] = []
		for id in AionCampaignWorld.HEROES: actual.append(Words.get_text(lang,"name_"+id))
		check(actual == names[lang] if names.has(lang) else actual.size()==6 and actual[0]=="Aion", "Exact character names: " + lang)
	check(Words.get_text("xx","play") == "Start running", "Unsupported lookup falls back to English")
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.set_process(false)
	check(game.ui.find_children("StartSelect_*", "Button", true, false).size() == 6, "All six current playable tiles exist before play")
	game.select_character("eren")
	game.set_language("tr")
	check(game.character_name("rabbit") == "Ayça" and game.language_override, "Manual Turkish selection localizes the current roster and overrides the default")
	game.start_run()
	game.select_character("owl")
	check(game.character == "eren", "Changing character during a run is rejected")
	game.pause_run()
	game.open_subpage("characters")
	game.show_page("characters")
	game.select_character("sheep")
	check(game.page == "paused" and game.character == "eren", "Pause cannot expose or bypass character selection")
	game.world.state = "bonk"
	game.show_page("finished")
	game.select_character("aion")
	check(game.character == "eren", "Result screen requires returning to the starting screen to choose")
	game.main_menu()
	game.select_character("sheep")
	check(game.character == "sheep", "A new pre-run selection is allowed")
	# Archived six-row sources remain anatomically valid even when two heroes
	# are no longer playable. Current M1 bodies have separate live-state tests.
	# Head/ear span remains anatomically constant when poses lean or extend.
	# Whole-pose height intentionally varies with bent knees and outstretched wings.
	for id in ["owl","wolf","sheep"]:
		var expected: float={"owl":57.434599,"wolf":52.380228,"sheep":64.109091}[id]
		var sizes_ok := true
		for row in [0,1,2,6,7]:
			for frame in 6:
				game.place_companion(game.friend_sprite,id,row,frame,Vector2.ZERO)
				sizes_ok = sizes_ok and is_equal_approx(float(game.friend_sprite.get_meta("head_size")),expected) and not game.friend_sprite.region_enabled
		for frame in 6:
			game.place_companion(game.friend_sprite,id,6,frame,Vector2.ZERO,0.62,true)
			sizes_ok = sizes_ok and is_equal_approx(float(game.friend_sprite.get_meta("head_size")),expected)
		check(sizes_ok,"Run/jump/glide/updraft/dash use one anatomical head span across independent frames: " + id)
	game.world.state = "running"
	game.world.character = "sheep"
	game.world.sheep_count = 3
	game.world.y = 0.0
	game.update_friend()
	var leader_pose: Dictionary=M1HeroArt.metrics("sheep","walk",int(game.friend_sprite.get_meta("source_frame")))
	var leader_atlas: Dictionary=M1HeroArt.DATA.data.atlases[str(leader_pose.source_key).trim_prefix("m1-body-")]
	var expected_head: float=float(leader_atlas.calibration.sheep.face_patch[2])*float(leader_pose.source_scale)
	check(is_equal_approx(float(game.friend_sprite.get_meta("head_size")),expected_head) and str(game.friend_sprite.get_meta("source_key")).begins_with("m1-body-"),"Leader sheep uses the current calibrated M1 anatomical size")
	for item in game.followers:
		check(is_equal_approx(float(item.get_meta("head_size")),expected_head*0.72),"Each following sheep is 72 percent of normal anatomical size")
	game.place_companion(game.friend_sprite,"owl",6,2,Vector2.ZERO,0.62*1.65,true)
	check(is_equal_approx(float(game.friend_sprite.get_meta("head_size")),57.434599*1.65),"Explicit mushroom growth remains independent of pose")
	game.set_language("tr")
	game.save_settings()
	var restored = load("res://main.tscn").instantiate()
	root.add_child(restored)
	await process_frame
	check(restored.language == "tr" and restored.language_override and restored.character == "sheep", "Turkish override and pre-run character survive a new instance")
	game.queue_free()
	restored.queue_free()
	await process_frame
	print("RESULT: %d localization/registration checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
