extends SceneTree
const World = preload("res://scripts/world.gd")
const Bank = preload("res://scripts/frame_bank.gd")
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
	w.adventure.weather_wait = 9999
	w.adventure.tempo_wait = 9999
	w.adventure.ambient_gnome_wait = 9999
	w.frontier.plant_wait = 9999
	return w
func run() -> void:
	var w := arena()
	w.distance = 1000000
	w.adventure.level_elapsed = 29.99
	w.adventure.update_level(w)
	check(w.adventure.level == 1,"Even extreme travel cannot level before thirty active seconds")
	w.adventure.level_elapsed = 30
	w.adventure.update_level(w)
	check(w.adventure.level == 2 and w.adventure.level_elapsed == 0,"Thirty seconds and required travel advance exactly one level")
	w.adventure.update_level(w)
	check(w.adventure.level == 2,"Excess distance cannot create a burst of catch-up levels")
	w.adventure.level_elapsed = 100
	w.adventure.update_level(w)
	check(w.adventure.level == 2,"Time alone cannot replace required new travel")
	w.distance += w.adventure.LEVEL_DISTANCE
	w.adventure.update_level(w)
	check(w.adventure.level == 3,"Each subsequent level needs a new distance segment")
	var x: float = w.adventure.celebration_x(w)
	w.distance += 200
	check(is_equal_approx(w.adventure.celebration_x(w),x-90),"The background spectator scrolls left with world travel")
	w.state = "paused"
	var elapsed: float = w.adventure.level_elapsed
	w.step(0.1)
	check(w.adventure.level_elapsed == elapsed,"Pause never earns level time")
	w = arena()
	w.adventure.hug_time = 1
	w.step(0.1)
	check(w.adventure.level_elapsed == 0,"The milestone hug does not earn level time")
	w = arena()
	w.frontier.request_boss(10)
	w.step(0.01)
	var boss_elapsed: float = w.adventure.level_elapsed
	for i in 200: w.step(0.01)
	check(w.adventure.level_elapsed == boss_elapsed,"Boss introduction and chase do not earn normal level time")
	for kind in ["gate","arch","arch_ice"]:
		w = arena()
		var base := w.speed()
		w.obstacles.assign([{"x":World.PLAYER_X,"kind":kind,"counted":false}])
		w.step(0.01)
		check(w.state == "running" and w.adventure.rush_time > 3 and w.speed()>base*1.17,"A grounded pad grants actual speed with no collision: "+kind)
		var passed: int = w.passed
		w.step(0.01)
		check(w.passed == passed,"Crossing a pad cannot award or refresh twice: "+kind)
	w = arena()
	w.y = -100
	w.obstacles.assign([{"x":World.PLAYER_X,"kind":"gate","counted":false}])
	w.step(0.01)
	check(w.adventure.rush_time == 0,"Jumping above a ground speed pad skips its boost")
	for kind in ["carrier_pipe","carrier_plank"]:
		w = arena()
		w.obstacles.assign([{"x":World.PLAYER_X,"kind":kind,"counted":false}])
		w.step(0.01)
		check(w.state == "bonk","The supported overhead load has real collision: "+kind)
		w = arena()
		w.adventure.press_roll(w)
		w.obstacles.assign([{"x":World.PLAYER_X,"kind":kind,"counted":false}])
		w.step(0.01)
		check(w.state == "running","A tucked roll clears the actual load: "+kind)
	w = arena()
	w.character = "owl"
	w.y = -70
	w.adventure.attack(w)
	check(w.adventure.attack_airborne,"An airborne owl starts the dedicated beak strike")
	w.adventure.attack_time = 0.25
	w.obstacles.assign([{"x":World.PLAYER_X+65,"kind":"carrier_pipe","counted":false}])
	w.step(0.01)
	check(w.adventure.kills == 1 and w.obstacles.is_empty(),"The forward beak can really break the crow-carried load")
	w = arena()
	w.character = "owl"
	w.adventure.attack(w)
	check(not w.adventure.attack_airborne,"A grounded owl keeps alternating wing strikes")
	w = arena()
	var kinds := {}
	for i in 500:
		w.adventure.spawn_encounter(w)
		kinds[w.adventure.last_encounter] = true
	check(kinds.has("gate") and kinds.has("carrier_pipe") and kinds.has("carrier_plank"),"Real encounter selection includes pads and both supported loads")
	check(not kinds.has("arch") and not kinds.has("arch_ice") and not kinds.has("arch_stone") and not kinds.has("arch_cap"),"No inverted-U obstacle can be selected")
	var bank := Bank.new()
	var physical_frames := 0
	for atlas_key in bank.MOTION.data.atlases:
		if not str(atlas_key).begins_with("motion-"): continue
		var atlas: Dictionary = bank.MOTION.data.atlases[atlas_key]
		check(int(atlas.columns)>=10,"All new animation atlases contain at least ten actually drawn intermediate frames")
		physical_frames += int(atlas.columns)*int(atlas.rows)
	check(physical_frames == 997,"The ten original new sheets register exactly 997 physical frames")
	for hero in ["aion","owl","sheep","wolf"]:
		var hero_index: int = ["aion","owl","sheep","wolf"].find(hero)
		for key_row in [["runner-"+hero,1],["runner-"+hero,2],["strikes",hero_index*2],["strikes",hero_index*2+1],["heroes",hero_index],["rolls",hero_index]]:
			var key: String = key_row[0]
			var row: int = key_row[1]
			check(bank.count(key,row) == (8 if key=="rolls" or hero=="wolf" or (hero=="owl" and key in ["heroes","strikes"]) else 7),"Every animation uses its observed drawn poses: "+hero+"/"+key+"/"+str(row))
			var scale := -1.0
			var textures := {}
			for column in bank.count(key,row):
				var pose: Dictionary = bank.pose(key,row,column)
				textures[hash(pose.texture.get_image().get_data())] = true
				if scale < 0: scale = pose.scale
				check(is_equal_approx(scale,pose.scale) and pose.source_frame==column,"Pose geometry uses a common scale without changing atlas frames: "+hero+"/"+key+"/"+str(column))
				var image: Image = pose.texture.get_image()
				var clear := true
				for px in image.get_width(): clear = clear and image.get_pixel(px,0).a == 0 and image.get_pixel(px,image.get_height()-1).a == 0
				for py in image.get_height(): clear = clear and image.get_pixel(0,py).a == 0 and image.get_pixel(image.get_width()-1,py).a == 0
				check(clear,"Each drawn frame has independent transparent boundaries: "+hero+"/"+key+"/"+str(column))
			check(textures.size() == bank.count(key,row),"All registered poses are distinct artwork: "+hero+"/"+key+"/"+str(row))
	check(bank.pose("heroes",3,5).source_key == "canonical-wolf" and bank.pose("heroes",3,5).source_row == 7,"The wolf gun animation uses its own bare-fur sheet")
	check(bank.count("owl-peck") == 8 and bank.pose("owl-peck",0,5).source_row == 3,"Airborne beak attacks use their own eight-pose row")
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_physics_process(false)
	game.world.character = "owl"
	game.world.adventure.attack_airborne = true
	game.place_combat(game.friend_sprite,"owl",0,5,Vector2.ZERO,1,false)
	check(game.friend_sprite.get_meta("source_key") == "agility-owl" and game.friend_sprite.get_meta("source_row") == 3,"The actual renderer selects beak artwork for the airborne owl")
	game.queue_free()
	await process_frame
	print("RESULT: %d motion checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
