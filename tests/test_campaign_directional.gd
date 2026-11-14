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
			w.attack_press()
			check(w.bullets.size()>0,"Projectile fires for "+hero+" / "+str(direction))
			if not w.bullets.is_empty():
				var projectile: Dictionary=w.bullets[0]
				check(Vector2(projectile.v).normalized().distance_to(direction)<.001,"Actual projectile follows aim vector "+hero+" / "+str(direction))
				check(is_equal_approx(Vector2(projectile.v).length(),760.),"Diagonal velocity does not exceed straight velocity "+hero)
				check(Vector2(projectile.p).y<0.,"Muzzle begins above the actual floor")
			check(w.shots==1,"Eight-way shoot counts once, no duplicate event")
	for name in CampaignWeapons.SPECIAL:
		for direction in [Vector2.UP,Vector2(1.,-1.).normalized(),Vector2.DOWN]:
			var w:=fresh()
			w.collect({"id":"special","kind":name})
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
	# Validate actual pixel-atlas reference sizing. Animations keep the idle
	# reference multiplier rather than changing height on each frame.
	var view:=AionCampaignView.new()
	var aion_height: float=view.hero_reference_height()
	for row in 8:
		var npc_height: float=view.npc_reference_height(row)
		check(is_equal_approx(npc_height*view.npc_growth(row),2.*aion_height),"Rescue girl standing pixel height is twice Aion: "+str(row))
		check(is_equal_approx(view.npc_growth(row),view.npc_growth(row)),"Growth is stable for every animation frame: "+str(row))
	view.free()
	print("RESULT: %d directional and NPC-size checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
