extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+message)
func fresh(hero: String="aion") -> AionCampaignWorld:
	var w:=AionCampaignWorld.new()
	w.begin(hero);w.state="playing";w.enemies.clear();w.npcs.clear();w.gates.clear();w.objects.clear();w.hazards.clear();w.pickups.clear();w.crates.clear()
	return w
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var dirs: Array[Vector2]=[
		Vector2.RIGHT,Vector2(1.,-1.).normalized(),Vector2.UP,
		Vector2(-1.,-1.).normalized(),Vector2.LEFT,
		Vector2(-1.,1.).normalized(),Vector2.DOWN,Vector2(1.,1.).normalized()]
	for hero in AionCampaignWorld.HEROES:
		for direction in dirs:
			var w:=fresh(hero);w.aim_direction=direction
			# Exercise an unobstructed straight-down vector from the air. At the
			# lower new-hero hands the real pistol barrel reaches the solid floor;
			# the separate grounded cases below verify that clearance rule.
			if direction==Vector2.DOWN:w.player.y=-150.;w.air_time=.2
			w.attack_press()
			check(w.bullets.size()>0,"Projectile fires for "+hero+" / "+str(direction))
			if not w.bullets.is_empty():
				var projectile: Dictionary=w.bullets[0]
				check(Vector2(projectile.v).normalized().distance_to(direction)<.001,"Actual projectile follows aim vector "+hero+" / "+str(direction))
				check(is_equal_approx(Vector2(projectile.v).length(),760.),"Diagonal velocity does not exceed straight velocity "+hero)
				check(Vector2(projectile.p).y<0.,"Muzzle begins above the actual floor")
			check(w.shots==1,"Eight-way shoot counts once, no duplicate event")
	# Keep grounded DOWN coverage too: derive the requested barrel position
	# from the registered body hand and weapon bore, independently of placement.
	# A genuine floor intersection must produce the same safe rendered shot;
	# a clear barrel must preserve DOWN. Neither case may move the held grip.
	for hero in AionCampaignWorld.HEROES:
		var w:=fresh(hero);w.aim_direction=Vector2.DOWN
		var body:=M1CombatArt.metrics(w);var spec:=M1CombatArt.body_spec(w)
		var face: int=int(spec.mirror);var weapon:=M1CombatArt.weapon_metrics("pistol")
		var grip: Vector2=Vector2(body.grip_local)*Vector2(face,1.)
		var bore: Vector2=Vector2(weapon.muzzle)*Vector2(1.,face)
		var requested_muzzle: Vector2=w.player+grip+bore.rotated(PI*.5)
		var floor: float=w.floor_at(requested_muzzle.x)
		var obstructed: bool=requested_muzzle.y>=floor-1.
		var expected_aim:=Vector2(face,0.) if obstructed else Vector2.DOWN
		var expected_muzzle: Vector2=w.player+grip+bore.rotated(expected_aim.angle())
		w.attack_press()
		check(w.bullets.size()==1 and w.shots==1,"Grounded DOWN fires exactly once for "+hero)
		if not w.bullets.is_empty():
			var projectile: Dictionary=w.bullets[0]
			check(Vector2(projectile.v).normalized().distance_to(expected_aim)<.001,"Grounded DOWN preserves a clear vector or uses the real floor-intersection fallback: "+hero)
			check(is_equal_approx(Vector2(projectile.v).length(),760.),"Grounded floor clearance preserves pistol speed: "+hero)
			check(Vector2(projectile.p).distance_to(expected_muzzle)<.001 and (w.player+w.armed_muzzle()).distance_to(expected_muzzle)<.001,"Grounded projectile and actual rendered barrel share the unchanged registered hand/bore: "+hero)
			check(expected_muzzle.y<w.floor_at(expected_muzzle.x),"Grounded barrel remains above real solid support: "+hero)
	for name in CampaignWeapons.SPECIAL:
		for direction in [Vector2.UP,Vector2(1.,-1.).normalized(),Vector2.DOWN]:
			var w:=fresh()
			w.collect({"id":"special","kind":name})
			# A low grounded actor cannot point a long barrel through the floor.
			# Measure true downward vectors in the valid airborne context instead.
			if direction.y>.1:w.player.y=-150.;w.air_time=.2
			w.aim_direction=direction;w.attack_press()
			check(not w.bullets.is_empty(),"Special weapon fires in aim direction: "+name)
			if not w.bullets.is_empty():
				var projectile: Dictionary=w.bullets[0]
				check(Vector2(projectile.v).normalized().dot(direction)>.55,"Spread rotates to vertical and diagonal aim: "+name)
				check(w.ammunition==int(CampaignWeapons.SPECS[name].ammo)-1,"Aimed special costs the same one shot: "+name)
	for direction in [Vector2.UP,Vector2.DOWN]:
		var w:=fresh();w.npcs=[{"id":"target","x":220.,"y":0.,"freed":false,"secret":"","gift":"points","role":"keeper","free_age":0.,"variant":0}];w.player=Vector2(155.,0.);w.aim_direction=direction
		w.attack_press()
		check(w.rescue_time==0. and w.shots==1,"Aiming vertically never auto-cuts a tied NPC")
	for hero in AionCampaignWorld.HEROES:
		var w:=fresh(hero);w.aim_direction=Vector2.UP
		w.spawn_enemy("gnome",w.player.x+55.,0.,99)
		w.attack_press()
		check(w.shots==1 and w.melee_time==0.,"Up-aim overrides nearby automatic melee for "+hero)
	# The same real fire action must work in every current body state. Body
	# identity/scale is supplied by M1HeroArt, not the retired eight-way redraw.
	for hero in AionCampaignWorld.HEROES:
		for posture in ["idle","walk","crouch","air"]:
			var w:=fresh(hero)
			if posture=="walk":w.move_axis=Vector2.LEFT;w.velocity.x=-235.
			elif posture=="crouch":w.move_axis=Vector2(1,1);w.velocity.x=98.7
			elif posture=="air":w.player.y=-150.;w.air_time=.2
			w.aim_direction=Vector2.RIGHT
			var body_before: Dictionary=M1CombatArt.body_spec(w)
			var expected_body_key: String="mission-hero" if hero in ["armadillo","frog"] else "m1-body"
			check(str(body_before.hero)==hero and str(body_before.key)==expected_body_key,"Current authored hero and its exact body provider remain selected: "+hero+"/"+posture)
			check(int(body_before.mirror)==1,"Body yaw follows independent aim while movement may face left")
			w.attack_press()
			check(w.bullets.size()==1 and Vector2(w.bullets[0].v).normalized().is_equal_approx(Vector2.RIGHT),"Idle/walk/crouch/air fire produces a real forward shot: "+hero+"/"+posture)
			var shot: Vector2=w.bullets[0].p
			check(shot.distance_to(w.player+w.armed_muzzle())<.01,"Actual shot starts at the currently held weapon muzzle: "+hero+"/"+posture)
			var root_before:=w.player
			w.step(.02)
			if posture in ["walk","crouch"]:check(absf(w.player.x-root_before.x)>0.,"Firing does not freeze locomotion: "+hero+"/"+posture)
			elif posture=="idle":check(w.player.is_equal_approx(root_before),"Idle fire does not invent body root motion")
			else:check(w.player.y<0.,"Air fire remains airborne rather than snapping to the floor")
	# Validate actual pixel-atlas reference sizing. Animations keep the idle
	# reference multiplier rather than changing height on each frame.
	var view:=AionCampaignView.new()
	var aion_height: float=view.hero_reference_height()
	for row in 8:
		var npc_height: float=view.npc_reference_height(row)
		check(is_equal_approx(npc_height*view.npc_growth(row),2.*aion_height),"Rescue girl standing pixel height is twice Aion: "+str(row))
		for frame in 8:
			var pose: Dictionary=view.catalogue.pose("rescue-npcs",row,frame)
			check(is_equal_approx(view.npc_growth(row),2.*aion_height/npc_height) and pose.texture!=null,"Every real NPC frame shares its standing reference scale: "+str(row)+"/"+str(frame))
	view.free()
	print("RESULT: %d directional and NPC-size checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
