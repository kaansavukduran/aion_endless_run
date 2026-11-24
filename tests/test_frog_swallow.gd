extends SceneTree

var checks:=0
var failures:=0

func check(condition: bool,message: String) -> void:
	checks+=1
	if not condition:
		failures+=1
		printerr("FAIL: "+message)

func make_world() -> AionCampaignWorld:
	var w:=AionCampaignWorld.new()
	w.begin("frog")
	w.enemies.clear();w.gates.clear();w.objects.clear();w.platforms.clear()
	w.pits.clear();w.hazards.clear();w.npcs.clear();w.crates.clear();w.pickups.clear()
	w.player=Vector2(150.,w.floor_at(150.))
	w.state="playing"
	return w

func spawn(w: AionCampaignWorld,kind: String,x: float,y:=0.,mini:=false) -> Dictionary:
	w.spawn_enemy(kind,x,y,w.enemies.size(),mini)
	var e: Dictionary=w.enemies.back()
	e.wait=100.
	return e

func advance(w: AionCampaignWorld,seconds: float) -> void:
	for i in roundi(seconds*100.):w.step(.01)

func _initialize() -> void:
	for kind in MissionHeroAbilities.SWALLOWABLE:
		var w:=make_world()
		var e:=spawn(w,kind,250.,-25. if kind=="crow" else 0.)
		check(w.interact(),"Ordinary skill command activates the tongue "+kind)
		advance(w,.7)
		check(e.defeated and bool(e.get("swallowed",false)) and w.frog_meal.get("kind")==kind,"Small enemy swallowed by the tongue "+kind)
		check(w.awarded.has(str(e.id)) and w.kills==1,"Captured enemy resolves its reward once "+kind)
		check(w.frog_cooldown>9. and MissionHeroAbilities.context(w).ready and MissionHeroAbilities.context(w).label_key=="skill_spit","Spit is ready during the swallow cooldown")
		var resume:=AionCampaignWorld.new()
		check(resume.restore(w.snapshot()) and resume.frog_meal==w.frog_meal and is_equal_approx(resume.frog_cooldown,w.frog_cooldown),"Loaded target and ten-second clock survive saving")
		var front:=spawn(w,"seed",440.)
		var neighbor:=spawn(w,"seed",521.)
		var far:=spawn(w,"seed",730.)
		check(w.interact() and not w.interact() and w.frog_meal.is_empty(),"Same input spits and repeated input cannot duplicate it")
		check(w.bullets.size()==1 and w.bullets[0].creature==kind,"Projectile represents the correct defeated creature")
		advance(w,.7)
		check(front.defeated and neighbor.defeated and not far.defeated,"Impact resolves direct and nearby targets but misses beyond radius")
		check(not w.interact(),"Cooldown blocks another tongue after spitting")
		var remaining:=w.frog_cooldown
		w.state="paused";advance(w,.5);w.state="playing"
		check(w.frog_cooldown==remaining,"Paused time does not run down the ten-second cooldown")
		advance(w,remaining+.04)
		check(w.interact(),"Tongue is available again after the ten seconds")
	var heavy_world:=make_world()
	var heavy:=spawn(heavy_world,"warden",280.,0.,true)
	heavy_world.interact();advance(heavy_world,.65)
	check(heavy.hp==10 and heavy_world.frog_meal.is_empty(),"Guardian takes a tongue hit and cannot be swallowed")
	var gate_world:=make_world()
	var locked:=spawn(gate_world,"gnome",240.)
	var gate: Dictionary={"x":320.,"ids":[locked.id]}
	gate_world.gates.append(gate)
	check(gate_world.gate_closed(gate),"The roster of enemies really locks its gate")
	gate_world.interact();advance(gate_world,.72)
	check(not gate_world.gate_closed(gate) and float(gate.open_age)>0.,"Swallowing the last opponent opens the gate and animates the bulkhead")
	print("RESULT: ",checks," Frog swallow and spit checks, ",failures," failures")
	quit(1 if failures else 0)
