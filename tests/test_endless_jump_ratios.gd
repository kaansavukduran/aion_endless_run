extends SceneTree

## Isolated real-physics fixtures. No enemies/collectibles are part of this
## measurement; the normal world's step method integrates every launch/apex.
const World = preload("res://scripts/world.gd")
var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func _initialize() -> void: call_deferred("run")

func arena(hero: String) -> RunnerWorld:
	var w := World.new()
	w.character = hero
	w.adventure.enabled = false
	w.reset()
	# Owl is retired from selection. Explicitly exercise its archived physics
	# after reset migrates inaccessible selected IDs to Aion.
	w.character = hero
	w.obstacle_wait = 999.
	w.frontier.plant_wait = 999.
	w.gust_wait = 999999.
	w.invulnerable = 999.
	return w

func apex(w: RunnerWorld, dt: float) -> float:
	var top := w.y
	for i in 1200:
		w.step(dt)
		top = minf(top, w.y)
		if w.velocity >= 0. and w.y < 0.: break
	return -top

func run() -> void:
	for dt in [1./60., 1./120., 1./240.]:
		var control := arena("aion")
		control.jump()
		var base := apex(control, dt)
		check(base > 115. and base < 125., "Measured Aion unbuffed apex remains unchanged")
		for hero in World.CHARGE_HEROES:
			var heights: Array[float] = []
			for hold in [0., .6, 1.2, 2.]:
				var w := arena(hero)
				w.jump()
				for frame in roundi(hold/dt): w.step(dt)
				check(w.charging and w.y == 0., "Charge waits for release: " + hero)
				w.release_charged_jump()
				var h := apex(w,dt)
				heights.append(h)
				var target := lerpf(1.75,4.,clampf(hold/1.2,0.,1.))
				check(absf(h/base-target) < target*.025, "Actual rabbit apex ratio %s hold %.1f: %.4f" % [hero,hold,h/base])
				check(w.jumps_used == 1 and not w.charging, "Single release launches one jump")
			check(heights[0] < heights[1] and heights[1] < heights[2] and is_equal_approx(heights[2],heights[3]), "Height rises with charge and caps consistently")
			print("RABBIT_APEX dt=%.6f hero=%s aion=%.4f tap=%.4f half=%.4f full=%.4f" % [dt,hero,base,heights[0],heights[1],heights[2]])
		var owl := arena("owl")
		owl.jump_held = true
		owl.jump()
		apex(owl,dt)
		for charge in 3:
			var start := owl.y
			owl.jump_held = false
			owl.jump_held = true
			owl.jump()
			var top := apex(owl,dt)
			var rise := top + start
			check(absf(rise/base-1.5) < .038, "Actual fresh wingbeat gains 1.5x Aion height")
			check(owl.owl_flaps_used == charge+1, "Exactly one flap resource per fresh press")
			check(owl.gliding and owl.velocity <= World.GLIDE_FALL_SPEED, "Held wingbeat returns to glide at apex")
			print("OWL_RISE dt=%.6f flap=%d rise=%.4f ratio=%.4f y=%.4f" % [dt,charge+1,rise,rise/base,owl.y])
		var old_v := owl.velocity
		owl.jump()
		check(owl.owl_flaps_used == 3 and owl.velocity == old_v, "Fourth airborne wingbeat refused")
		check(owl.y < World.WIND_CEILING-200., "Three powered wingbeats are not clipped by environmental wind ceiling")
		var used := owl.owl_flaps_used
		for frame in 30: owl.step(dt)
		check(owl.owl_flaps_used == used, "Holding never spends additional flap charges")
		owl.release_controls()
		for frame in 1200:
			owl.step(dt)
			if owl.y == 0.: break
		check(owl.y == 0. and owl.owl_flaps_used == 0, "Landing restores the three wingbeats")
	print("RESULT: %d Endless jump ratio checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
