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
	# Shared sheet cache: exact pixels, one decode per sheet, bounded residency, warm-up.
	RunnerSourcePixels.sheets.clear();RunnerSourcePixels.recent.clear();RunnerSourcePixels.section_paths.clear();RunnerSourcePixels.current_section=""
	var paths:=[]
	for name in DirAccess.get_files_at("res://assets"):
		if name.ends_with(".png"):paths.append("res://assets/"+name)
	var direct:=RunnerSourcePixels.image(paths[0]);direct.convert(Image.FORMAT_RGBA8)
	var first:=RunnerSourcePixels.sheet(paths[0]);var decodes:=RunnerSourcePixels.decodes
	check(first.get_data()==direct.get_data(),"A shared sheet has exactly the directly decoded pixels")
	check(RunnerSourcePixels.sheet(paths[0])==first and RunnerSourcePixels.decodes==decodes,"A resident sheet is reused without decoding again")
	RunnerSourcePixels.enter_section("test_a")
	var used:=mini(paths.size()-1,RunnerSourcePixels.SHEET_LIMIT+2)
	var within:=true
	for i in range(1,used+1):
		RunnerSourcePixels.sheet(paths[i])
		within=within and RunnerSourcePixels.resident_bytes()<=RunnerSourcePixels.SHEET_BUDGET and RunnerSourcePixels.sheets.size()<=RunnerSourcePixels.SHEET_LIMIT
	check(within,"Resident sheets never exceed the byte budget or the count ceiling")
	check(not RunnerSourcePixels.sheets.has(paths[0]),"The least recently used sheet is released")
	check(RunnerSourcePixels.sheets.has(paths[used]) and RunnerSourcePixels.sheets.has(paths[used-1]),"The most recently used sheets stay resident")
	var small:="res://assets/campaign-row-sheets/legacy-deaths-01.png";var big:="res://assets/polish-enemies.png"
	check(RunnerSourcePixels.sheet_bytes(small)*5<RunnerSourcePixels.sheet_bytes(big),"A row strip costs its own bytes, not a full sheet's slot")
	RunnerSourcePixels.enter_section("test_b");RunnerSourcePixels.sheets.clear();RunnerSourcePixels.recent.clear()
	RunnerSourcePixels.enter_section("test_a")
	check(RunnerSourcePixels.sheets.has(paths[used]) and RunnerSourcePixels.resident_bytes()<=RunnerSourcePixels.SHEET_BUDGET,"Entering a known section pre-decodes its most recent sheets within the budget")
	# Generated section list: real files, within the limit, hero art excluded, warmed on entry.
	var listed: Dictionary=load("res://assets/SECTION-SHEETS.json").data.sections
	for section in AionCampaignWorld.STAGES:
		check(listed.has(section),"Every Mission 1 section has a warm-up list: "+section)
		var entries: Array=listed.get(section,[])
		check(entries.size()<=RunnerSourcePixels.SHEET_LIMIT and entries.reduce(func(t,p):return t+RunnerSourcePixels.sheet_bytes(str(p)),0)<=RunnerSourcePixels.SHEET_BUDGET,"A section's warm-up list fits the resident budget: "+section)
		for path in entries:check(ResourceLoader.exists(str(path)) and not RunnerSourcePixels.hero_sheet(str(path)),"Listed sheet exists and is world art: "+str(path))
	RunnerSourcePixels.sheets.clear();RunnerSourcePixels.recent.clear();RunnerSourcePixels.section_paths.clear();RunnerSourcePixels.known_sections={}
	RunnerSourcePixels.enter_section("water")
	check(listed.water.all(func(path):return RunnerSourcePixels.sheets.has(str(path))),"Entering water pre-decodes every listed water sheet")
	check(RunnerSourcePixels.hero_sheet("res://assets/m1-redraw-aion.png") and not RunnerSourcePixels.hero_sheet("res://assets/aionverse-flora.png"),"Hero art is recognised without catching world art named after Aion")
	RunnerSourcePixels.current_section=""
	# Prewarm: after a section load, its first kill, knife, rescue cut and
	# captive frames are already cut, so drawing them decodes no sheet.
	for section in ["shore","fork_one"]:
		w=world(section)
		var decodes_before:=RunnerSourcePixels.decodes
		var effects:=CampaignEffectsArt.new();var catalogue:=CampaignCatalog.new()
		for e in w.enemies:
			if not bool(e.mini) and str(e.kind) in CampaignEffectsArt.LEGACY:
				for frame in 6:effects.death(str(e.kind),frame)
		for captive in w.npcs:
			for frame in 12:catalogue.pose("rescue-npcs",int(captive.get("variant",0)),frame)
		var actions: Array=M1HeroActionArt.CONTACT_ACTIONS+(M1HeroActionArt.TUNNEL_ACTIONS if section=="fork_one" else [])
		for action in actions:
			if M1HeroActionArt.supports("aion",action):
				for frame in int(M1HeroActionArt.clip_spec("aion",action).frames):M1HeroActionArt.pose("aion",action,frame)
		check(RunnerSourcePixels.decodes==decodes_before,"Section %s: death, knife, rescue and captive frames need no in-play decode"%section)
	RunnerSourcePixels.current_section=""
	# Loose budget: generous for slower CI runners; catches a return of per-frame scans.
	w=world("water");w.player.x=w.length()*.8
	for i in 60:w.move_axis=Vector2.RIGHT;w.fire_held=true;w.step(1./60.);w.pending_events.clear()
	var start:=Time.get_ticks_usec()
	for i in 300:w.move_axis=Vector2.RIGHT;w.fire_held=i%3!=0;w.step(1./60.);w.pending_events.clear()
	var avg:=(Time.get_ticks_usec()-start)/300.
	check(avg<2500.,"Dense water frame stays under a loose 2.5 ms logic budget: "+str(snapped(avg,1))+" us")
	print("RESULT: %d hot path checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
