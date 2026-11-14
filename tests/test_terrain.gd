extends SceneTree
const Terrain = preload("res://scripts/terrain_view.gd")
var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var terrain := Terrain.new()
	seed(7719)
	var expected_random := randi()
	seed(7719)
	for kind in 6:
		var image: Image = terrain.tile(kind, 0).get_image()
		var cap: Color = terrain.palette(kind)[0]
		var deep: Color = terrain.palette(kind)[6]
		var solid := true
		var level_cap := true
		var quiet_bottom := true
		for x in image.get_width():
			level_cap = level_cap and image.get_pixel(x, 0).is_equal_approx(cap)
			quiet_bottom = quiet_bottom and image.get_pixel(x, image.get_height() - 1).is_equal_approx(deep)
			for y in image.get_height(): solid = solid and image.get_pixel(x, y).a == 1.0
		check(solid, "No transparent holes expose the background beneath biome " + str(kind))
		check(level_cap, "The real drawn walking edge is level across the whole strip: " + str(kind))
		check(quiet_bottom, "Deep ground meets the control-area fill without a hard seam: " + str(kind))
		check(terrain.tile(kind, 0) == terrain.tile(kind, 0), "Scrolling reuses the existing GPU texture: " + str(kind))
	check(randi() == expected_random, "Decorative material generation leaves gameplay randomness untouched")
	for width in [393., 960., 1280., 2048.]:
		for scroll in [-2049., -1., 0., 1., 511.9, 1023.9, 2047.9, 2048., 2049., 999999.]:
			var strips: Array[Dictionary] = terrain.strips(width, scroll)
			check(strips.front().x <= 0 and strips.back().x + strips.back().width >= width, "Ground covers viewport across negative/wrapped/large scroll")
			var joined := true
			for i in range(1, strips.size()): joined = joined and strips[i - 1].x + strips[i - 1].width == strips[i].x
			check(joined, "Adjacent draw rectangles share an exact boundary at every viewport size")
			check(fposmod(float(strips.front().x), Terrain.PIXEL) == 0., "Movement remains on the authored pixel grid")
	var before: Array[Dictionary] = terrain.strips(1280., 2046.)
	var after: Array[Dictionary] = terrain.strips(1280., 2048.)
	check(before[1].x - 2. == after[0].x, "Wrapping advances two pixels without a texture-position reset")
	print("RESULT: %d terrain checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
