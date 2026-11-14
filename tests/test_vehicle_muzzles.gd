extends SceneTree

## Compare actual image pose anchors and world projectile origins. These are
## controlled fixtures, not a physical gamepad or native-device test.
var checks:=0
var failures:=0
var art:=preload("res://scripts/forge_vehicle_art.gd").new()
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+label)
func fresh(kind: String,hull_facing: int) -> AionCampaignWorld:
	var w:=AionCampaignWorld.new();w.begin("aion");w.state="playing"
	w.enemies.clear();w.npcs.clear();w.gates.clear();w.objects.clear();w.platforms.clear();w.pits.clear()
	w.mount={"available":true,"ridden":true,"x":140.,"hp":4,"type":kind};w.player=Vector2(140.,-42.);w.facing=hull_facing
	return w
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var directions: Array[Vector2]=[Vector2.RIGHT,Vector2(1,-1).normalized(),Vector2.UP,Vector2(-1,-1).normalized(),Vector2.LEFT,Vector2(-1,1).normalized(),Vector2.DOWN,Vector2(1,1).normalized()]
	for kind in CampaignVehicles.TYPES:
		for facing in [-1,1]:
			for aim in directions:
				for frame in 6:
					var w:=fresh(kind,facing);w.aim_direction=aim;w.time=(frame+.1)/8.;w.shot_flash=.18*(1.-(frame+.1)/6.)
					var spec:=w.vehicle_art_spec()
					var aligned: bool=absf(aim.y)<.15 and aim.x*facing>0.
					check(int(spec.phase)==(1 if aligned else 0),"Baked forward firing poses are never used for another aim direction")
					check(int(spec.frame)==frame,"Actual vehicle animation frame is shared between view and muzzle")
					var pose:=art.pose(kind,int(spec.phase),int(spec.frame))
					var pivot: Vector2=Vector2(pose.pivot_local)*Vector2(facing,1.)
					var barrel: float=pose.barrel_length
					var expected:=pivot+aim*barrel+Vector2(0,42)
					check(w.armed_muzzle().distance_to(expected)<.001,"All four vehicle muzzle origins match the actual drawn pivot and barrel")
					check((w.armed_muzzle()-Vector2(0,42)-pivot).normalized().distance_to(aim)<.001,"Rotated vehicle barrel has the true normalized direction")
					if aligned:
						check(w.armed_muzzle().distance_to(Vector2(pose.muzzle_local)*Vector2(facing,1.)+Vector2(0,42))<.001,"Forward projectile exits actual image endcap after hull flip")
					w.attack_press()
					var fired_spec:=w.vehicle_art_spec()
					var fired_pose:=art.pose(kind,int(fired_spec.phase),int(fired_spec.frame))
					var fired_pivot: Vector2=Vector2(fired_pose.pivot_local)*Vector2(facing,1.)
					var fired_end:=w.player+fired_pivot+aim*float(fired_pose.barrel_length)+Vector2(0,42)
					for b in w.bullets:
						check(Vector2(b.p).distance_to(fired_end)<.001,"Actual emitted projectile begins at the current rendered barrel end")
						check(absf(Vector2(b.v).length()-float(420. if kind=="drill" else (600. if kind=="shell" else 780.)))<.001,"Art correction does not alter vehicle weapon speed")
					# A shallow ground-level endcap still reaches real ground enemies;
					# the former hardcoded -136px muzzle passed above these targets.
					if aligned and kind=="shell" and frame==0:
						check(absf(fired_end.y+50.)<20.,"Shell barrel is measured near its visible 50px height, not guessed136px")
		for hurt in [0.,.2]:
			var w:=fresh(kind,1);w.mount.hurt=hurt;w.time=.3;w.aim_direction=Vector2.UP;w.shot_flash=.1
			check(w.vehicle_art_spec().phase==(2 if hurt>0. else 0),"Hurt pose wins over firing without a false forward flash")
	print("RESULT: %d vehicle pose/muzzle checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
