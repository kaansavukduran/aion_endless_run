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
	for pair in [["tr-TR","tr"],["en-GB","en"],["cs-CZ","cs"],["CS_cz","cs"],["de-DE","en"],["fr","en"],["cz","en"],["","en"]]:
		check(Words.language_for_locale(pair[0]) == pair[1], "Locale selection: " + pair[0])
	var names := {"tr":["Aion","Baykuş Ömer","Melun Bilge Kurt","Kutsanmış Cahil Koyun"],"en":["Aion","Omar the Owl","Accursed Wise Wolf","Blessed Ignorant Sheep"],"cs":["Aion","Sova Omar","Prokletý moudrý vlk","Požehnaná nevědomá ovečka"]}
	for lang in Words.LANGUAGES:
		var complete: bool = Words.STRINGS[lang].size() == Words.STRINGS.en.size()
		for key in Words.STRINGS.en:
			complete = complete and Words.STRINGS[lang].has(key) and not Words.get_text(lang,key).is_empty() and Words.get_text(lang,key).count("%d") == Words.get_text("en",key).count("%d")
		check(complete, "Complete localized UI with matching numeric placeholders: " + lang)
		var actual: Array[String] = []
		for id in ["aion","owl","wolf","sheep"]: actual.append(Words.get_text(lang,"name_"+id))
		check(actual == names[lang], "Exact character names: " + lang)
	check(Words.get_text("xx","play") == "Start running", "Unsupported lookup falls back to English")
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.set_process(false)
	check(game.ui.find_children("StartSelect_*", "Button", true, false).size() == 4, "All four selectable character tiles exist before play")
	game.select_character("wolf")
	game.set_language("cs")
	check(game.character_name("owl") == "Sova Omar" and game.language_override, "Manual Czech selection localizes names and overrides the default")
	game.start_run()
	game.select_character("owl")
	check(game.character == "wolf", "Changing character during a run is rejected")
	game.pause_run()
	game.open_subpage("characters")
	game.show_page("characters")
	game.select_character("sheep")
	check(game.page == "paused" and game.character == "wolf", "Pause cannot expose or bypass character selection")
	game.world.state = "bonk"
	game.show_page("finished")
	game.select_character("aion")
	check(game.character == "wolf", "Result screen requires returning to the starting screen to choose")
	game.main_menu()
	game.select_character("sheep")
	check(game.character == "sheep", "A new pre-run selection is allowed")
	# Test actual source opacity registration across every moving atlas frame,
	# including crossings between normal and separate action sheets.
	for id in ["owl","wolf","sheep"]:
		var sizes_ok := true
		for row in [0,1,2,6,7]:
			for frame in 6:
				game.place_companion(game.friend_sprite,id,row,frame,Vector2.ZERO)
				var b: Array = game.REGISTRATION.data.runner[id].bounds[row][frame]
				sizes_ok = sizes_ok and is_equal_approx((b[3]-b[1])*game.friend_sprite.scale.y,90.0)
		for frame in 6:
			game.place_companion(game.friend_sprite,id,6,frame,Vector2.ZERO,0.62,true)
			var row: int = game.ACTION_DATA.data.characters[id].row
			var b: Array = game.REGISTRATION.data.actions.bounds[row][frame]
			sizes_ok = sizes_ok and is_equal_approx((b[3]-b[1])*game.friend_sprite.scale.y,90.0)
		check(sizes_ok,"Run/jump/glide/updraft/dash opacity heights stay fixed across sheets: " + id)
	game.world.state = "running"
	game.world.character = "sheep"
	game.world.sheep_count = 3
	game.world.y = 0.0
	game.update_friend()
	var b: Array = game.REGISTRATION.data.runner.sheep.bounds[1][game.friend_frame]
	check(is_equal_approx((b[3]-b[1])*game.friend_sprite.scale.y,90.0), "Leader sheep remains normal size")
	for item in game.followers:
		var frame := int(item.region_rect.position.x / 181.0)
		b = game.REGISTRATION.data.runner.sheep.bounds[1][frame]
		check(is_equal_approx((b[3]-b[1])*item.scale.y,64.8), "Each following sheep is 72 percent of normal size")
	game.place_companion(game.friend_sprite,"owl",6,2,Vector2.ZERO,0.62*1.65,true)
	b = game.REGISTRATION.data.actions.bounds[1][2]
	check(is_equal_approx((b[3]-b[1])*game.friend_sprite.scale.y,148.5), "Explicit mushroom growth remains intentional and independent of pose")
	game.set_language("cs")
	game.save_settings()
	var restored = load("res://main.tscn").instantiate()
	root.add_child(restored)
	await process_frame
	check(restored.language == "cs" and restored.language_override and restored.character == "sheep", "Czech override and pre-run character survive a new instance")
	game.queue_free()
	restored.queue_free()
	await process_frame
	print("RESULT: %d localization/registration checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
