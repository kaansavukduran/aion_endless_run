## 0.57.3 hot-path optimizations keep their exact rules, plus a loose frame budget.
extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+label)
func world(section: String) -> AionCampaignWorld:
	var w:=AionCampaignWorld.new();w.begin("aion");w.run_seed=7719;w.load_section(section);w.invulnerable=999.
	return w
func _initialize() -> void:call_deferred("run")
func run() -> void:
	# Gates: the shared live-enemy set answers exactly like the per-gate scan.
	var w:=world("water")
	var rng:=RandomNumberGenerator.new();rng.seed=11
	for round in 6:
		for e in w.enemies:
			if rng.randf()<.35:e.defeated=true
		var alive:=w.alive_enemy_ids()
		for gate in w.gates:check(w.gate_closed(gate)==(w.gate_closed(gate,alive) if not alive.is_empty() else false),"Gate state is identical with the shared live set")
	# Ropes: a far shot never frees; a crossing shot frees; cage and secrecy still protect.
	w=world("water");w.objects.clear()
	var npc: Dictionary=w.npcs[0];npc.freed=false;npc.secret="";npc.erase("cage")
	var rope_mid:=Vector2(float(npc.x),float(npc.y)-70.)
	check(not CampaignRescue.hit_rope(w,rope_mid+Vector2(400,0),rope_mid+Vector2(413,0)),"A distant shot does not cut a rope")
	w.objects.append({"id":"test:cage","kind":"cage","x":npc.x,"y":0.,"hp":2,"active":false,"secret":""});npc.cage="test:cage"
	check(not CampaignRescue.hit_rope(w,rope_mid-Vector2(30,0),rope_mid+Vector2(30,0)) and not bool(npc.freed),"A closed cage still protects its captive")
	npc.secret="test:hidden";w.objects[-1].active=true
	check(not CampaignRescue.hit_rope(w,rope_mid-Vector2(30,0),rope_mid+Vector2(30,0)) and not bool(npc.freed),"An undiscovered secret captive is still protected")
	w.discovered["test:hidden"]=true
	check(CampaignRescue.hit_rope(w,rope_mid-Vector2(30,0),rope_mid+Vector2(30,0)) and bool(npc.freed),"A crossing shot frees an open, discovered captive")
	# Objects: a distant shot misses; a shot through the target still damages it.
	w=world("shore");w.objects=[{"id":"test:lamp","kind":"lamp","x":900.,"y":0.,"hp":2,"active":false,"secret":""}]
	check(not CampaignContent.hit_object(w,Vector2(1100.,-35.),1,Vector2(1090.,-35.)),"A shot 190px away does not hit an object")
	check(CampaignContent.hit_object(w,Vector2(905.,-35.),1,Vector2(880.,-35.)) and int(w.objects[0].hp)==1,"A shot through the object still damages it")
	# Pickups: contact distance unchanged; far items keep ageing.
	w=world("shore");w.enemies.clear();w.pickups=[{"id":"test:near","kind":"points","x":w.player.x+50.,"y":w.player.y},{"id":"test:far","kind":"points","x":w.player.x+900.,"y":w.player.y}]
	w.move_axis=Vector2.ZERO;w.step(1./60.)
	check(w.taken.has("test:near") and not w.taken.has("test:far"),"Near pickup is collected, far pickup is not")
	var far: Array=w.pickups.filter(func(p):return str(p.id)=="test:far")
	check(not far.is_empty() and float(far[0].age)>0.,"A far pickup still ages every frame")
	# Loose budget: generous for slower CI runners; catches a return of per-frame scans.
	w=world("water");w.player.x=w.length()*.8
	for i in 60:w.move_axis=Vector2.RIGHT;w.fire_held=true;w.step(1./60.);w.pending_events.clear()
	var start:=Time.get_ticks_usec()
	for i in 300:w.move_axis=Vector2.RIGHT;w.fire_held=i%3!=0;w.step(1./60.);w.pending_events.clear()
	var avg:=(Time.get_ticks_usec()-start)/300.
	check(avg<2500.,"Dense water frame stays under a loose 2.5 ms logic budget: "+str(snapped(avg,1))+" us")
	print("RESULT: %d hot path checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
