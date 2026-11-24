## Root Engine phases change real behaviour; the final hit resolves once.
extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+label)
func arena() -> AionCampaignWorld:
	var w:=AionCampaignWorld.new();w.begin("aion");w.load_section("arena")
	w.enemies.clear();w.boss.engaged=true;w.player=Vector2(600.,0.);w.invulnerable=999.
	return w
func run_until(w: AionCampaignWorld,predicate: Callable,limit: float=8.) -> bool:
	var t:=0.
	while t<limit:
		if predicate.call():return true
		w.step(1./60.);t+=1./60.
	return predicate.call()
func waves(w: AionCampaignWorld) -> int:
	return w.bullets.filter(func(b):return b.owner=="enemy" and str(b.kind)=="wave").size()
func core_shot(w: AionCampaignWorld) -> int:
	var core:=Vector2(float(w.boss.x),-75.)
	return CampaignBossPressure.core_damage(w,{"damage":1},core-Vector2(40,0),core+Vector2(40,0))
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var w:=arena()
	check(core_shot(w)==1,"Phase one core takes normal damage while it is closed")
	w.boss.attack=1;w.boss.wait=0.
	check(run_until(w,func():return waves(w)>0),"Phase one throws its ground slam")
	check(float(w.boss.core_open)>0. and core_shot(w)==2,"The core opens after the slam and takes double damage")
	check(run_until(w,func():return float(w.boss.core_open)==0.,3.),"The core window closes again")
	w.spawn_enemy("drone",900.,-130.,201)
	w.bullets.append({"p":Vector2(800.,-60.),"v":Vector2(-200,0),"owner":"enemy","age":0.,"kind":"seed","damage":1,"pierce":0,"hit":[]})
	w.boss.hp=59;w.step(1./60.)
	check(int(w.boss.phase)==2 and float(w.boss.stagger)>0.,"Crossing into phase two starts a visible stagger")
	check(w.bullets.filter(func(b):return b.owner=="enemy").is_empty() and w.enemies.all(func(e):return bool(e.defeated)),"The phase change clears enemy shots and summoned drones")
	check(w.notice=="arc_boss_phase_2" and int(w.boss.arm)==CampaignBossPressure.ARM_HP,"Phase two announces itself and grows the breakable root arm")
	var attacked:=false
	for i in 60:
		w.step(1./60.)
		if float(w.boss.windup)>0. or not w.bullets.filter(func(b):return b.owner=="enemy").is_empty():attacked=true
	check(not attacked,"The stagger is a real pause without attacks")
	w.bullets.clear();w.boss.attack=1;w.boss.wait=0.;w.boss.stagger=0.
	check(run_until(w,func():return waves(w)>0),"Phase two slams")
	check(waves(w)==2,"A living root arm adds a second, later wave")
	var spacing: float=absf(w.bullets[-1].p.x-w.bullets[-2].p.x)
	check(spacing>=120.,"The two waves are spaced to be jumped one after another")
	var arm:=CampaignBossPressure.arm_point(w)
	for i in CampaignBossPressure.ARM_HP:CampaignBossPressure.hit(w,{"damage":1},arm-Vector2(40,0),arm+Vector2(40,0))
	check(int(w.boss.arm)==0 and w.notice=="arc_boss_arm_broken","Breaking the arm is acknowledged")
	w.bullets.clear();w.boss.attack=1;w.boss.wait=0.;w.boss.windup=0.
	check(run_until(w,func():return waves(w)>0),"Phase two still slams after the arm breaks")
	check(waves(w)==1,"Targeting the arm really reduces the pressure")
	w.bullets.clear();w.boss.hp=29;w.step(1./60.)
	check(int(w.boss.phase)==3 and w.notice=="arc_boss_phase_3","Phase three announces the climax")
	w.boss.stagger=0.;w.boss.attack=2;w.boss.wait=0.
	check(run_until(w,func():return float(w.boss.get("dash",0.))>0.),"Phase three charges across the arena")
	var score_before: int=w.score
	w.boss.beam_warning=.5
	w.bullets.append({"p":Vector2(800.,-60.),"v":Vector2(-200,0),"owner":"enemy","age":0.,"kind":"seed","damage":1,"pierce":0,"hit":[]})
	w.damage_boss(99)
	check(w.state=="victory" and w.completed,"The last hit wins the mission")
	check(w.bullets.filter(func(b):return b.owner=="enemy").is_empty() and float(w.boss.dash)==0. and float(w.boss.beam_warning)==0.,"Victory clears shots, the dash and the beam")
	var won_score: int=w.score;w.damage_boss(50);w.invulnerable=0.;var hp: int=w.hp;w.damage_player()
	check(w.score==won_score and won_score>score_before and w.hp==hp,"The final hit pays once and the hero cannot be hurt afterwards")
	check(str(AionCampaignWorld.STAGES["arena"].next)=="complete","Mission one ends in its own result, not Mission two")
	print("RESULT: %d root engine checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
