extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var bank := ForgeHeroArt.new()
	var data: Dictionary = ForgeHeroArt.DATA.data
	var hashes: Dictionary = {}
	var count := 0
	for key in data.atlases:
		var atlas: Dictionary = data.atlases[key]
		check(FileAccess.get_sha256("res://" + str(atlas.path)) == str(atlas.sha256), "Immutable original source agrees with registration: " + key)
		for row in atlas.rows:
			for frame in atlas.frames[row].size():
				var f: Dictionary = atlas.frames[row][frame]
				var p := bank.pose(key, row, frame)
				var image: Image = p.texture.get_image()
				var gutter := true
				for x in image.get_width(): gutter = gutter and image.get_pixel(x, 0).a == 0. and image.get_pixel(x, image.get_height() - 1).a == 0.
				for y in image.get_height(): gutter = gutter and image.get_pixel(0, y).a == 0. and image.get_pixel(image.get_width() - 1, y).a == 0.
				check(gutter, "Isolated sampling gutter: %s/%d/%d" % [key, row, frame])
				var hash := HashingContext.new()
				hash.start(HashingContext.HASH_SHA256); hash.update(image.get_data()); hashes[hash.finish().hex_encode()] = true; count += 1
				check(bool(p.gun_embedded) == (key != "embark"), "Gun is embedded only in armed source, never duplicated: " + key)
				if key != "embark": check(p.has("muzzle_local") and p.muzzle_local.is_finite(), "Registered real muzzle exists: %s/%d/%d" % [key, row, frame])
				if key == "mouth-carry":
					var factor: float = atlas.scales[row]
					var landmark := Vector2(float(f.face_landmark[0]), float(f.face_landmark[1]))
					var origin := Vector2(float(f.origin[0]), float(f.origin[1]))
					var actual := (landmark - origin) * factor
					check(absf(actual.x - 14.) < .001, "Whole-face landmark stays fixed horizontally: %d/%d" % [row, frame])
					if row < 2: check(absf(actual.y + 49.82278481012658) < .001, "Owl glide/flap body has one shared vertical anchor")
					else: check(absf(float(f.body_bounds[3]) - float(f.origin[1])) < .001, "Wolf anatomical feet contact floor")
				if key == "eightway":
					var factor: float = atlas.scales[row]
					var actual_x: float = (float(f.face_landmark[0]) - float(f.origin[0])) * factor
					var expected := 0. if frame == 6 else (-14. if frame in [3, 4, 5] else 14.)
					check(absf(actual_x - expected) < .001, "Aim origin uses face, never gun/halo bbox centre: %d/%d" % [row, frame])
				if key == "embark":
					var neutral: Dictionary = atlas.frames[row][0]
					var expected_x: float = float(neutral.rect[0]) + float(neutral.origin[0]) + frame * float(atlas.dimensions[0]) / 6.
					check(absf(float(f.rect[0]) + float(f.origin[0]) - expected_x) < .001, "Hatch origin is fixed authored atlas root, independent of gutter crop")
	check(count == 124 and hashes.size() == 124, "124 actual distinct drawings, not repeated filler or rotated stills")
	check(is_equal_approx(float(data.atlases["mouth-carry"].scales[0]), float(data.atlases["mouth-carry"].scales[1])), "Owl glide/flap share one source scale")
	check(is_equal_approx(float(data.atlases["mouth-carry"].scales[2]), float(data.atlases["mouth-carry"].scales[3])), "Wolf gallop/fire share one source scale")
	print("RESULT: %d forge hero art checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
