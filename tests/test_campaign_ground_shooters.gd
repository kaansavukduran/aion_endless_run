extends SceneTree

var checks:=0
var failures:=0

func check(value: bool,label: String) -> void:
	checks+=1
	if not value:failures+=1;printerr("FAIL: "+label)

func _initialize() -> void:call_deferred("run")

func actor(kind: String,x: float=400.) -> AionCampaignWorld:
	var w:=AionCampaignWorld.new()
	w.begin("aion");w.state="playing";w.invulnerable=0.
	w.enemies.clear();w.gates.clear();w.objects.clear();w.hazards.clear();w.bullets.clear()
	w.player=Vector2(140.,0.)
	w.spawn_enemy(kind,x,0.,88)
	w.enemies[0].wait=0.
	return w

func run() -> void:
	for kind in CampaignGroundShooters.ROLES:
		var spec: Dictionary=CampaignGroundShooters.ROLES[kind]
		var w:=actor(kind);var e:=w.enemies[0]
		w.recovery_view=Rect2(0.,-420.,190.,620.)
		for tick in 60:w.step_enemies(.01)
		check(w.bullets.is_empty() and float(e.windup)==0. and w.hp==1,"Offscreen enemy must neither shoot nor spend a first-frame hit: "+kind)
		w.recovery_view=Rect2(0.,-420.,960.,620.)
		w.step_enemies(.01)
		check(is_equal_approx(float(e.windup),float(spec.windup)) and w.bullets.is_empty(),"Entering the readable view starts the full warning: "+kind)
		var first_pose:=CampaignGroundShooters.pose(e,false)
		for tick in floori(float(spec.windup)*100.)-2:w.step_enemies(.01)
		var second_pose:=CampaignGroundShooters.pose(e,false)
		check(first_pose.texture!=second_pose.texture and w.bullets.is_empty(),"Two registered anticipation poses precede an actual attack: "+kind)
		for tick in 4:
			if w.bullets.is_empty():w.step_enemies(.01)
		check(w.bullets.size()==1 and int(e.attacks)==1,"The warning releases only one hostile projectile: "+kind)
		var bullet: Dictionary=w.bullets[0]
		check(Vector2(bullet.p).is_equal_approx(CampaignGroundShooters.origin(e)),"Projectile begins at the visible release socket: "+kind)
		if kind=="lantern_scout":
			check(float(bullet.v.y)==0. and float(bullet.v.x)<0.,"Scout threatens a horizontal lane while facing left")
		else:
			var t:=CampaignGroundShooters.ARC_SECONDS
			var predicted: Vector2=Vector2(bullet.p)+Vector2(bullet.v)*t+Vector2(0.,.5*float(bullet.gravity)*t*t)
			check(float(bullet.v.y)<0. and predicted.distance_to(Vector2(e.throw_target))<.01,"Lobber targets one learnable spot along a real arc")
		var after_release:=CampaignGroundShooters.pose(e,false)
		var distance:=float(e.x)
		for tick in floori(float(spec.recover)*100.)-2:w.step_enemies(.01)
		check(w.bullets.size()==1 and float(e.windup)==0. and float(e.x)==distance and float(e.recover)>0.,"Recovery has its own no-movement and no-attack interval: "+kind)
		check(after_release.texture!=CampaignGroundShooters.pose(e,false).texture,"Recoil settles into a distinct recovery drawing: "+kind)
		w.damage_enemy(e,1)
		check(bool(e.defeated) and w.kills==1 and CampaignGroundShooters.pose(e,false).texture!=after_release.texture,"One hit switches to the role's own visible defeat pose: "+kind)
		var falling:=CampaignGroundShooters.pose(e,false)
		e.dead_age=.15;var low:=CampaignGroundShooters.pose(e,false)
		e.dead_age=.30;var grounded:=CampaignGroundShooters.pose(e,false)
		check(falling.texture!=low.texture and low.texture!=grounded.texture and grounded.texture==CampaignGroundShooters.pose(e,true).texture,"Three own-source fall cels have a reduced-motion final pose: "+kind)
		w=actor(kind,3510.)
		e=w.enemies[0];e.y=w.floor_at(float(e.x));e.home=Vector2(float(e.x),float(e.y));w.player=Vector2(2750.,0.)
		for tick in 45:w.step_enemies(.01)
		check(float(e.x)<3510. and absf(float(e.y)-w.floor_at(float(e.x)))<.01 and int(e.facing)==-1,"Approach keeps moving feet, facing and real incline in agreement: "+kind)
		var authored:=AionCampaignWorld.new();authored.begin("aion")
		check(authored.enemies.any(func(item):return item.kind==kind),"The normal mission spawns this authored role: "+kind)
	var w:=actor("lantern_scout");var scout:=w.enemies[0];scout.attacks=1;scout.age=1.
	w.step_enemies(.01)
	check(bool(scout.burst_pending) and scout.windup>0. and w.bullets.is_empty(),"The second attack explicitly prepares its marked double shot")
	for tick in 100:
		if w.bullets.size()==1:break
		w.step_enemies(.01)
	check(w.bullets.size()==1 and bool(scout.burst_pending),"The first bolt leaves before the second")
	for tick in 25:w.step_enemies(.01)
	check(w.bullets.size()==2 and scout.recover>.35 and not bool(scout.burst_pending),"A spaced second bolt leaves an exposed recovery window")
	for tick in 100:
		if scout.windup>0.:break
		w.step_enemies(.01)
	check(int(scout.attacks)==2 and scout.windup>0. and bool(scout.burst_pending),"The third telegraph also visibly warns of a second bolt")
	for section in CampaignRhythm.GROUND_PATROLS:
		w.load_section(section)
		var patrols:=w.enemies.filter(func(e):return int(str(e.id).get_slice(":",2)) in [910,911])
		check(patrols.size()==CampaignRhythm.GROUND_PATROLS[section].size() and patrols.all(func(e):return not CampaignContent.flying(e.kind) and float(e.y)==w.floor_at(float(e.x))),"New patrols only use supported ground roles: "+section)
		check(CampaignRhythm.SIDE_DECKS[section].all(func(deck):return deck in w.platforms),"Side route uses real walkable platforms: "+section)
	w=actor("seed")
	w.enemy_shot(w.enemies[0])
	check(is_equal_approx(Vector2(w.bullets[0].v).length(),210.),"Opening ground shot keeps its original speed")
	w.section="relay";w.bullets.clear()
	w.enemy_shot(w.enemies[0])
	check(is_equal_approx(Vector2(w.bullets[0].v).length(),228.),"Later ground shots add pressure without changing the warning")
	print("RESULT: %d ground shooter checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
