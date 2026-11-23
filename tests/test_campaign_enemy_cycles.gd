extends SceneTree

var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func fresh() -> AionCampaignWorld:
	var w := AionCampaignWorld.new()
	w.begin("aion")
	w.enemies.clear();w.objects.clear();w.hazards.clear();w.zones.clear()
	w.gates.clear();w.npcs.clear();w.crates.clear();w.pickups.clear()
	w.platforms.clear();w.pits.clear()
	w.state = "playing"
	return w

func active_time(e: Dictionary) -> float:
	return maxf(float(e.get("lunge",0.)),maxf(float(e.get("leap",0.)),float(e.get("sweep",0.))))

func enemy_cycle(kind: String, duration: float) -> void:
	var w := fresh()
	w.player = Vector2(380.,-500.)
	w.spawn_enemy(kind,500.,0.,0)
	var e: Dictionary = w.enemies[0]
	e.age=1.5;e.windup=.02;e.wait=0.
	w.step_enemies(.01)
	check(int(e.attacks)==0,"Telegraph precedes active attack: "+kind)
	w.step_enemies(.01)
	check(int(e.attacks)==1 and is_equal_approx(active_time(e),duration),"Telegraph releases role-specific active duration: "+kind)
	var attack_wait: float = e.wait
	var elapsed := 0.
	while elapsed < duration-.00001:
		var dt := minf(.01,duration-elapsed)
		w.step_enemies(dt)
		elapsed += dt
	var recovery: float = CampaignEnemies.timing_for(e).recover
	check(active_time(e)<.00001 and absf(float(e.get("recover",0.))-recovery)<.015,"Full recovery remains AFTER active movement: "+kind)
	check(is_equal_approx(float(e.wait),attack_wait),"Active attack does not consume reposition wait: "+kind)
	var x: float = e.x
	var no_damage := true
	var no_motion := true
	var no_attack := true
	# Spend almost the entire actual punish interval touching the enemy.
	# Reset invulnerability every tick so repeat contacts cannot hide behind it.
	for tick in int((recovery-.03)/.01):
		w.player=Vector2(float(e.x),0.);w.invulnerable=0.
		w.step_enemies(.01)
		no_damage = no_damage and w.hp==w.max_hp
		no_motion = no_motion and is_equal_approx(float(e.x),x)
		no_attack = no_attack and int(e.attacks)==1 and float(e.windup)==0.
	check(no_damage and no_motion and no_attack,"Whole punish interval suppresses contact, movement and reattack: "+kind)
	# A real hero projectile still defeats ordinary roles during the opening.
	if not bool(e.heavy):
		w.bullets.append({"p":Vector2(float(e.x)-50.,float(e.y)-30.),"v":Vector2(1000.,0.),"owner":"hero","age":0.,"kind":"pistol","damage":1,"pierce":0,"hit":[]})
		w.step_bullets(.05)
		check(bool(e.defeated),"Punish window preserves one-hit ordinary target: "+kind)
	else:
		while float(e.get("recover",0.))>.00001:w.step_enemies(.01)
		w.player=Vector2(float(e.x)-300.,-500.)
		w.step_enemies(.01)
		check(float(e.x)<x,"Heavy resumes repositioning after recovery: "+kind)

func boss_cycles() -> void:
	var w := fresh()
	w.load_section("arena");w.enemies.clear()
	w.boss.active=true;w.boss.engaged=true;w.boss.phase=3;w.boss.hp=20
	w.boss.attack=5;w.boss.windup=.01;w.boss.wait=0.
	w.player=Vector2(float(w.boss.x)-350.,-120.)
	w.step_boss(.01)
	check(float(w.boss.get("dash",0.))>.9,"Real fifth-pattern windup starts final dash")
	check(float(w.boss.get("beam_warning",0.))==0.,"Dash does not queue a frozen overlapping beam warning")
	var elapsed := 0.
	while elapsed<.95-.00001:
		var dt := minf(.01,.95-elapsed)
		w.step_boss(dt);elapsed+=dt
	check(float(w.boss.get("dash",0.))<.00001 and float(w.boss.get("recover",0.))>.63,"Dash movement finishes before full boss recovery")
	var x: float = w.boss.x
	var wait_before: float = w.boss.wait
	var attacks_before: int = w.boss.attack
	for tick in 60:
		w.player=Vector2(float(w.boss.x),0.);w.invulnerable=0.
		w.step_boss(.01)
	check(w.hp==w.max_hp and is_equal_approx(float(w.boss.x),x),"Boss punish window has no dash/contact damage")
	check(is_equal_approx(float(w.boss.wait),wait_before) and int(w.boss.attack)==attacks_before and float(w.boss.windup)==0.,"Boss recovery owns update and freezes next-attack clock")
	# A direct phase jump can interrupt an in-flight attack (including saved state).
	w.boss.phase=1;w.boss.hp=20;w.boss.dash=.6;w.boss.recover=.4
	w.boss.windup=.4;w.boss.beam_warning=.4;w.boss.wait=0.
	w.step_boss(.01)
	check(int(w.boss.phase)==3 and float(w.boss.get("shift_pause",0.))>0.,"Crossing two thresholds produces one visible transition")
	check(float(w.boss.get("dash",0.))==0. and float(w.boss.get("recover",0.))==0. and float(w.boss.windup)==0. and float(w.boss.beam_warning)==0.,"Phase transition cancels interrupted dash/recovery/windup/beam")
	x=w.boss.x
	for tick in 76:w.step_boss(.01)
	check(is_equal_approx(float(w.boss.x),x) and float(w.boss.get("dash",0.))==0.,"Old dash never resumes after phase pause")
	check(float(w.boss.windup)==0. and float(w.boss.wait)>.9,"New phase requires a fresh reposition wait and telegraph")

func boundary_cycles() -> void:
	for dt in [1./60.,1./30.,.05]:
		var w := fresh()
		w.player=Vector2(380.,-500.);w.spawn_enemy("leech",500.,0.,0)
		var e: Dictionary=w.enemies[0]
		e.age=1.5;e.lunge=.007;e.recover=.55;e.wait=.75
		w.step_enemies(dt)
		check(absf(float(e.x)-(500.-230.*.007))<.0001,"Boundary tick moves only remaining active time at dt="+str(dt))
		check(absf(float(e.recover)-(.55-(dt-.007)))<.0001,"Boundary tick spends remaining time in recovery exactly once at dt="+str(dt))
		var x: float=e.x
		var safe := true
		while float(e.recover)>0.:
			w.player=Vector2(float(e.x),0.);w.invulnerable=0.
			w.step_enemies(dt)
			safe=safe and w.hp==w.max_hp and is_equal_approx(float(e.x),x) and float(e.windup)==0.
		check(safe and is_equal_approx(float(e.wait),.75),"Recovery expiry tick still belongs to punish interval at dt="+str(dt))
		w.player=Vector2(x-300.,-500.);w.step_enemies(dt)
		check(float(e.x)<x and float(e.wait)<.75,"Reposition resumes on the next tick at dt="+str(dt))

func mini_recovery_projectile() -> void:
	var w := fresh()
	w.spawn_enemy("seed",500.,0.,0,true)
	var e: Dictionary=w.enemies[0]
	e.age=2.;e.flash=0.;e.recover=.5;e.lunge=.2
	for active in [true,false]:
		e.lunge=.2 if active else 0.
		w.bullets.append({"p":Vector2(float(e.x)-50.,-30.),"v":Vector2(1000.,0.),"owner":"hero","age":0.,"kind":"pistol","damage":1,"pierce":0,"hit":[]})
		w.step_bullets(.05)
		check(int(e.hp)==(12 if active else 11),"Mini projectile shield respects active attack before reserved recovery" if active else "Mini projectile hits true recovery after flash expires")

func leap_continuity() -> void:
	for role in [["hopper",.8],["mimic",.6]]:
		var w:=fresh()
		var kind: String=role[0]
		var duration: float=role[1]
		w.player=Vector2(500.,0.);w.spawn_enemy(kind,500.,0.,0)
		var e: Dictionary=w.enemies[0];e.age=2.;w.invulnerable=0.
		CampaignEnemies.attack(w,e)
		w.step_enemies(.01)
		check(float(e.y)<0. and float(e.y)>-7.,"First leap tick leaves floor continuously: "+kind)
		check(w.hp==w.max_hp-1,"Leap contact follows actual low body at takeoff: "+kind)
		var elapsed:=.01
		while elapsed<duration*.5-.00001:
			var dt:=minf(.01,duration*.5-elapsed);w.step_enemies(dt);elapsed+=dt
		check(absf(float(e.y)+100.)<.001,"Leap reaches actual apex at half active time: "+kind)
		w.hp=w.max_hp;w.invulnerable=0.
		w.step_enemies(.001);elapsed+=.001
		check(w.hp==w.max_hp,"Actual elevated leap body clears grounded player: "+kind)
		while elapsed<duration-.01-.00001:
			var dt:=minf(.01,duration-.01-elapsed);w.step_enemies(dt);elapsed+=dt
		check(float(e.y)<0. and float(e.y)>-7. and active_time(e)>.009,"Last active leap tick approaches floor continuously: "+kind)
		w.hp=w.max_hp;w.invulnerable=0.
		w.step_enemies(.01)
		check(absf(float(e.y))<.001 and active_time(e)<.00001 and float(e.recover)>.49,"Landing ends leap before full recovery begins: "+kind)
		check(w.hp==w.max_hp,"Landing recovery disables contact damage: "+kind)

func beam_expiration() -> void:
	for sample in [{"warning":.01,"steps":[.05]},{"warning":.01,"steps":[.004,.006,.05]},{"warning":.9,"steps":[.2,.2,.2,.2,.2]}]:
		var w:=fresh();w.load_section("arena")
		w.boss.active=true;w.boss.engaged=true;w.boss.hp=55;w.boss.phase=2
		w.boss.windup=0.;w.boss.wait=2.;w.boss.beam_x=2180.;w.boss.beam_warning=sample.warning
		w.player=Vector2(2180.,0.);w.invulnerable=0.
		var elapsed:=0.
		var never_early:=true
		for dt in sample.steps:
			w.step_boss(float(dt));elapsed+=float(dt)
			if elapsed<float(sample.warning)-.000001:never_early=never_early and w.hp==w.max_hp and w.blasts.is_empty()
		check(never_early,"Beam respects complete warning across frame partition: "+str(sample.steps))
		check(w.hp==w.max_hp-1 and w.blasts.size()==1 and float(w.boss.beam_warning)==0.,"Phase2 beam expires with one impact even when coarse tick crosses zero: "+str(sample.steps))
		w.invulnerable=0.;w.step_boss(.05);w.step_boss(.05)
		check(w.hp==w.max_hp-1 and w.blasts.size()==1,"Expired beam never fires a second impact: "+str(sample.steps))

func late_burrow_commitment() -> void:
	var w:=fresh();w.spawn_enemy("burrow",5000.,0.,0)
	var e: Dictionary=w.enemies[0]
	# Remain outside attack range until the end of its normal surface cycle.
	for tick in 370:
		w.player=Vector2(float(e.x)-400.,0.);w.step_enemies(.01)
	w.player=Vector2(float(e.x)-100.,0.);w.step_enemies(.01)
	check(float(e.windup)>.6 and not CampaignEnemies.hidden(e),"Late player approach commits a visible burrow windup")
	var visible_windup:=true
	while float(e.windup)>0.:
		w.step_enemies(.01);visible_windup=visible_windup and not CampaignEnemies.hidden(e)
	check(visible_windup,"Burrow cannot hide in the middle of its announced attack")
	var visible_active:=true
	while active_time(e)>.00001:
		w.step_enemies(.01);visible_active=visible_active and not CampaignEnemies.hidden(e)
	check(visible_active and float(e.recover)>.54,"Burrow active motion finishes visibly before full recovery")
	var clone: Dictionary=e.duplicate(true)
	w.bullets.append({"p":Vector2(float(e.x)-50.,-30.),"v":Vector2(1000.,0.),"owner":"hero","age":0.,"kind":"pistol","damage":1,"pierce":0,"hit":[]})
	w.step_bullets(.05)
	check(bool(e.defeated),"Actual counterfire can hit late-cycle burrow recovery")
	w=fresh();w.enemies.append(clone)
	var visible_recovery:=true
	while float(clone.recover)>0.:
		w.player=Vector2(float(clone.x)-400.,0.);w.step_enemies(.01)
		visible_recovery=visible_recovery and not CampaignEnemies.hidden(clone)
	check(visible_recovery,"Complete committed recovery stays visible through hide-clock boundary")
	while float(clone.age)<8.1:
		w.player=Vector2(float(clone.x)-400.,0.);w.step_enemies(.01)
	check(CampaignEnemies.hidden(clone) and int(clone.attacks)==1,"Uncommitted next cycle preserves original underground ambush")

func _initialize() -> void:
	for role in [["leech",.65],["hopper",.80],["burrow",.55],["mimic",.60],["borer",.90]]:
		enemy_cycle(str(role[0]),float(role[1]))
	boss_cycles()
	boundary_cycles()
	mini_recovery_projectile()
	leap_continuity()
	beam_expiration()
	late_burrow_commitment()
	print("RESULT: %d enemy/boss cycle checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
