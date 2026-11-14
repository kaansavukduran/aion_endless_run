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
	var bank := ForgeVehicleArt.new()
	var all: Dictionary = ForgeVehicleArt.DATA.data
	var references := RunnerFrameBank.new()
	var aion := references.pose("gun-run", references.hero_row("aion"), 0)
	check(absf(float(all.aion_reference_height) - float(aion.height)) < .001, "Vehicle scale references actual standing gun-run Aion anatomy")
	var count := 0
	for kind in all.types:
		var data: Dictionary = all.types[kind]
		check(FileAccess.get_sha256("res://" + str(data.path)) == str(data.sha256), "Original vehicle PNG retained: " + kind)
		check(absf(float(data.source_reference_height) * float(data.scale) - 2. * float(aion.height)) < .001, "Neutral complete body is 2 × Aion, not a per-frame bbox renormalization: " + kind)
		var first: Dictionary = data.frames[0][0]
		var expected_core_x: float = (float(first.body_landmark[0]) - float(first.origin[0])) * float(data.scale)
		for phase in data.frames.size():
			for frame in data.frames[phase].size():
				var f: Dictionary = data.frames[phase][frame]
				var pose := bank.pose(kind, phase, frame)
				var metrics := ForgeVehicleArt.anchors(kind, phase, frame)
				count += 1
				check(is_equal_approx(float(metrics.scale), float(data.scale)), "One fixed body scale across all phases: %s/%d/%d" % [kind, phase, frame])
				check(absf(float(f.body_bounds[3]) - float(f.origin[1])) < .001, "Connected anatomical support meets ground; flash is not the reference: %s/%d/%d" % [kind, phase, frame])
				if phase < 3:
					var core_x: float = (float(f.body_landmark[0]) - float(f.origin[0])) * float(data.scale)
					check(absf(core_x - expected_core_x) < .001, "Wheel/gem/hull core is horizontally registered independently of barrel/flash bbox: %s/%d/%d" % [kind, phase, frame])
				else:
					var expected: float = float(first.origin[0]) + float(first.rect[0]) + frame * (887. / 6.)
					check(absf(float(f.origin[0]) + float(f.rect[0]) - expected) < .001, "Collapsed wreck retains authored cell root rather than centring every debris silhouette")
				check(pose.texture.get_width() > 8 and pose.texture.get_height() > 8, "Actual isolated source texture is present")
				check(metrics.muzzle_local.is_finite() and metrics.pivot_local.is_finite() and float(metrics.barrel_length) > 1., "Measured neutral collar/tip are finite and outside barrel pivot")
				check(absf(metrics.muzzle_local.y - metrics.pivot_local.y) < .001, "Straight neutral barrel axis passes through actual measured muzzle")
				for direction in 8:
					var aim := Vector2.RIGHT.rotated(-direction * PI / 4.)
					var tip: Vector2 = metrics.pivot_local + aim * float(metrics.barrel_length)
					check(absf(tip.distance_to(metrics.pivot_local) - float(metrics.barrel_length)) < .001, "All eight normalized aim vectors retain measured barrel length")
	check(count == 84, "Three 24-frame vehicles and one existing 12-frame skimmer; no invented death drawings")
	check(int(ForgeVehicleArt.anchors("skimmer", 3, 0).phase) == 0, "Legacy missing wreck resolves honestly to existing hover")
	var shell := ForgeVehicleArt.anchors("shell")
	check(shell.muzzle_local.y > -60. and shell.muzzle_local.y < -40., "Regresses previous -136 mounted muzzle: shell gun is approximately 51 world pixels above floor")
	check(absf(float(bank.pose("shell", 0, 0, 200.).size.y) / float(bank.pose("shell", 0, 0).size.y) - 200. / float(all.target_height)) < .001, "An explicit alternate target height scales visuals and anchors together")
	print("RESULT: %d forge vehicle art checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
