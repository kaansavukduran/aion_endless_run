extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+message)
func fresh(hero: String="aion") -> AionCampaignWorld:
	var w:=AionCampaignWorld.new();w.begin(hero);w.state="playing";w.enemies.clear();w.gates.clear();w.objects.clear();w.hazards.clear();w.pickups.clear();w.crates.clear();return w
func tick(w,seconds: float) -> void:
	for i in ceili(seconds*100.):w.step(.01)
func claim_gift(w,npc: Dictionary) -> bool:
	# A giver's thanks does not award its item. Use the real visible world
	# pickup and normal overlap step; no direct collect()/effect injection.
	var id: String=str(npc.id)+":supply"
	var items: Array=w.pickups.filter(func(p):return str(p.id)==id)
	if items.is_empty():return false
	w.attack_release();w.move_axis=Vector2.ZERO;w.velocity=Vector2.ZERO
	w.player=Vector2(float(items[0].x),float(items[0].y)+25.)
	tick(w,.3)
	var offer: Dictionary=CampaignRhythm.offer(w)
	if str(offer.get("id",""))==id:w.interact()
	return w.taken.has(id) and w.awarded.has(str(npc.id)+":gift")
func _initialize() -> void:call_deferred("run")
func run() -> void:
	for hero in AionCampaignWorld.HEROES:
		var w:=fresh(hero);var n: Dictionary=w.npcs[0];w.player=Vector2(float(n.x)-65.,float(n.y));w.facing=1
		tick(w,.3);check(not n.freed,"Touch alone never frees the captive: "+hero)
		w.attack_press();check(w.rescue_time>.5 and w.shots==0,"Fire context begins one knife action instead of shooting: "+hero)
		var anchor:=w.player;w.move_axis.x=1.;tick(w,.24)
		check(not n.freed and w.player==anchor,"Anticipation keeps feet planted and ropes intact: "+hero)
		tick(w,.10);check(n.freed and w.rescued.has(str(n.id)),"Cut contact frees the correct NPC: "+hero)
		w.move_axis=Vector2.ZERO;w.player=Vector2(float(n.x),float(n.y));tick(w,1.3)
		check(w.weapon=="pistol" and not w.awarded.has(str(n.id)+":gift"),"Gratitude leaves a visible unclaimed item: "+hero)
		check(claim_gift(w,n) and w.weapon=="heavy" and w.ammunition==90,"Touching the extracted bag item grants the real weapon: "+hero)
		var score:=w.score;w.attack_release();w.attack_press();tick(w,.8);check(w.rescued.size()==1 and w.score==score,"Repeated action cannot duplicate rescue or gift: "+hero)
		var saved:=w.snapshot();var copy:=AionCampaignWorld.new();check(copy.restore(saved),"Expanded checkpoint restores")
		var rescued_npc: Dictionary=copy.npcs[0];check(rescued_npc.freed,"Same stable keeper remains free on re-entry")
		copy.state="playing";tick(copy,1.1);check(copy.score==score and copy.weapon==w.weapon and copy.ammunition==w.ammunition and copy.pickups.all(func(p):return p.id!=str(n.id)+":supply"),"Saved encounter keeps the spent supply and exact inventory")
	var w:=fresh();var n: Dictionary=w.npcs[0];w.player=Vector2(float(n.x)-65.,0.);w.attack_press();tick(w,.35)
	var pending:=w.snapshot();var resume:=AionCampaignWorld.new();check(resume.restore(pending),"Save between cut and thanks remains valid");resume.state="playing";resume.player=Vector2(float(resume.npcs[0].x),float(resume.npcs[0].y));tick(resume,1.2);check(resume.weapon=="pistol" and claim_gift(resume,resume.npcs[0]) and resume.weapon=="heavy","Pending supply survives save and needs actual gift contact after handover")
	var legacy:=pending.duplicate(true);legacy.schema=1;legacy.erase("discovered");legacy.erase("activated");var old:=AionCampaignWorld.new();check(old.restore(legacy),"0.23 schema1 saves migrate safely");old.state="playing";tick(old,1.1);check(old.weapon=="pistol","Legacy rescues do not create retroactive free weapons")
	var total:=0;var roles: Dictionary={}
	var rescue_stages: Array=CampaignRescue.COUNTS.keys()
	rescue_stages.append("fork_one")
	for stage in rescue_stages:
		w=fresh();w.load_section(stage);total+=w.npcs.size()
		var ids: Dictionary={}
		for npc in w.npcs:
			check(not ids.has(npc.id),"Every rescue point has a unique stable ID");ids[npc.id]=true;roles[npc.role]=true
			if stage=="arena":
				check(not w.npcs.any(func(other):return other.id!=npc.id and absf(float(other.x)-float(npc.x))<140.),
					"Final arena captives have separate silhouettes and approach space: "+str(npc.id))
	check(total==45 and roles.size()==6,"45 distinct authored rescue opportunities cover six roles including the pump technician")
	w=fresh();n=w.npcs[0];w.player=Vector2(float(n.x)-65.,0.);n.cage="test-cage";w.objects=[{"id":"test-cage","kind":"cage","x":n.x,"y":0.,"hp":2,"active":false,"secret":""}]
	check(CampaignRescue.nearest(w).is_empty(),"A closed cage protects its actual captive")
	w.attack_press();tick(w,.4);w.attack_release()
	check(w.objects[0].active and not n.freed,"The cage consumes the opening shots before its rope can be hit")
	w.attack_press();tick(w,.35);check(n.freed,"Fresh fire after opening the cage cuts the actual ropes")
	for stage in CampaignRescue.COUNTS:
		w=fresh();w.load_section(stage);w.enemies.clear();w.gates.clear();w.objects.clear();w.hazards.clear();w.zones.clear();w.pickups.clear();w.crates.clear()
		for npc in w.npcs:
			if str(npc.secret)!="":w.discovered[str(npc.secret)]=true
			w.player=Vector2(float(npc.x)-60.,float(npc.y));w.velocity=Vector2.ZERO;w.move_axis=Vector2.ZERO;w.facing=1
			w.attack_release();w.fire_time=0.;w.attack_press();tick(w,.65)
			w.player=Vector2(float(npc.x),float(npc.y));tick(w,1.1)
			check(npc.freed and claim_gift(w,npc),"Every authored NPC has a real cut, bag drop and contact collection: "+str(npc.id))
			var claimed:=w.score;var ammo:=w.ammunition;w.rescue(npc);tick(w,.2)
			check(w.score==claimed and w.ammunition==ammo,"Every NPC's repeated rescue cannot duplicate its effect: "+str(npc.id))
	for leaf in ["water","terrace","roots"]:
		w=fresh();w.load_section(leaf)
		check(w.encounters.size()==8 and w.rooms.size()==2,"Every leaf has eight tactical groups and two optional rooms")
		check(w.npcs.size()==int(CampaignRescue.COUNTS[leaf]),"Route rescue count matches authored content")
		for kind in CampaignContent.REGIONS[leaf]:check(w.enemies.any(func(e):return e.kind==kind),"Route really contains its exclusive enemy "+kind)
		var guard: Dictionary=w.enemies.filter(func(e):return bool(e.mini))[0]
		check(guard.max_hp==12 and guard.has("mini_role"),"Distinct guardian keeps its starting12HP")
		var door: Dictionary=w.objects.filter(func(o):return str(o.secret)!="")[0]
		check(not w.discovered.has(str(door.secret)),"Secret begins undiscovered")
		CampaignContent.hit_object(w,Vector2(float(door.x),-35.),2);check(w.discovered.has(str(door.secret)),"Breaking/activating the actual door reveals optional room")
		var reward:=w.score;CampaignContent.hit_object(w,Vector2(float(door.x),-35.),3);check(w.score==reward,"Discovering the same room twice cannot award twice")
	for kind in CampaignContent.NEW_ENEMIES:
		w=fresh();w.spawn_enemy(kind,210.,-110. if CampaignContent.flying(kind) else 0.,0)
		var e: Dictionary=w.enemies[0];check(e.hp==1,"Normal archetype stays oneHP: "+kind)
		CampaignEnemies.attack(w,e);check(e.attacks==1,"New archetype executes an actual behaviour: "+kind)
		w.damage_enemy(e,1);check(e.defeated,"One valid normal hit defeats "+kind)
	for kind in CampaignContent.HEAVIES:
		w=fresh();w.spawn_enemy(kind,250.,0.,0);var e: Dictionary=w.enemies[0]
		w.damage_enemy(e,1);w.damage_enemy(e,1);check(e.armour==0 and e.hp==8,"Heavy plates break separately from its body")
		CampaignEnemies.attack(w,e);check(e.attacks==1,"Heavy has a working separate attack")
	for weapon in CampaignWeapons.SPECIAL:
		w=fresh();w.collect({"id":"supply","kind":weapon});var ammo:=w.ammunition
		w.attack_press();check(w.bullets.size()>0 and w.ammunition==ammo-1,"Special weapon really fires and spends ammunition: "+weapon)
		check(str(w.bullets[0].kind)==weapon,"Projectile carries the actual weapon behaviour")
		w.spawn_enemy("seed",280.,0.,0);tick(w,2.)
		check(w.enemies[0].defeated,"Special weapon's real collision defeats an ordinary target: "+weapon)
		w.ammunition=1;w.fire_time=0.;w.attack_release();w.attack_press();check(w.weapon=="pistol" and w.ammunition==CampaignWeapons.PISTOL_START,"Empty special returns to the stored finite pistol stock")
	w=fresh();w.objects=[{"id":"near-gate","kind":"gate","x":180.,"y":0.,"hp":1,"active":false,"secret":""}];w.attack_press();tick(w,.05)
	check(w.objects[0].active,"A muzzle beyond a close gate cannot skip the object collision")
	w=fresh();w.objects=[{"id":"saved-bridge","kind":"bridge","x":400.,"y":0.,"hp":1,"active":false,"secret":""}]
	CampaignContent.hit_object(w,Vector2(400,-35),1);var bridge:=Rect2(270,-55,260,18)
	check(w.platforms.has(bridge),"Opening a bridge creates its real one-way surface")
	CampaignContent.apply_surface(w,w.objects[0]);check(w.platforms.count(bridge)==1,"Restoring an activated bridge never duplicates the collision surface")
	w=fresh();w.spawn_enemy("gnome",280.,0.,0);w.collect({"id":"beam","kind":"beam"});w.attack_press();w.step(.05);check(w.enemies[0].defeated,"Fast beam uses segment collision instead of tunnelling past a target")
	w=fresh();w.boss=CampaignBossPressure.initial_state(230.);w.boss.active=true;w.boss.engaged=true
	var rocket: Dictionary={"kind":"rocket","owner":"hero","p":Vector2(175,-35),"v":Vector2.RIGHT,"damage":6,"colour":"ffffff","age":.2}
	check(CampaignWeapons.rocket_impact(w,rocket,rocket.p) and w.boss.hp==CampaignBossPressure.MAX_HP-6,"Rocket area impacts can damage the active boss when exposed")
	check(not CampaignWeapons.rocket_impact(w,rocket,rocket.p) and w.boss.hp==CampaignBossPressure.MAX_HP-6,"A spent rocket cannot apply splash twice")
	var nova: Dictionary={"kind":"nova","owner":"hero","p":Vector2(200,-40),"v":Vector2.RIGHT,"damage":3,"colour":"ffffff","age":1.19,"life":1.2}
	check(CampaignWeapons.step(w,nova,.02) and w.boss.hp==CampaignBossPressure.MAX_HP-9 and nova.age==99.,"Timed nova consumes itself after exactly one area burst")
	w=fresh();w.collect({"id":"haste","kind":"haste"});w.move_axis.x=1.;var x:=w.player.x;tick(w,.2);check(w.player.x-x>56.,"Haste changes actual movement speed")
	w=fresh();w.collect({"id":"magnet","kind":"magnet"});w.pickups=[{"id":"apple","x":300.,"y":-30.,"kind":"fruit_0"}];tick(w,.7);check(w.taken.has("apple"),"Magnet pulls and collects reachable loot")
	w=fresh();w.collect({"id":"power","kind":"power"});w.attack_press();check(w.bullets[0].damage==2,"Power buff changes real projectile damage")
	for type in ["shell","wind","drill"]:
		w=fresh();w.mount={"available":true,"ridden":false,"x":140.,"hp":1,"type":type};check(w.interact(),"Vehicle begins boarding: "+type);tick(w,.46)
		w.attack_press();check(w.bullets.size()==1,"Vehicle has its own rapid aimed shot: "+type)
		w.jump_press()
		check(w.velocity.y<0.,"Every mounted vehicle performs a grounded jump")
		w.invulnerable=0.;w.damage_player();tick(w,.1);check(not w.mount.ridden and w.player.y<0. and w.floor_at(w.player.x)==0.,"Destroyed craft safely ejects to supported ground")
		w.load_section("relay");check(not w.mount.ridden,"The common relay starts on foot after riding a "+type)
		w.load_section("arena");check(not w.mount.ridden,"The boss scene starts on foot")
	var atlas: Dictionary=CampaignCatalog.DATA.data
	check(atlas.drawings>=500 and atlas.distinct_crop_hashes==atlas.drawings,"At least500 genuinely distinct usable crops; excluded source defects are not counted")
	check(atlas.animation_groups>=50,"At least50 meaningful authored action rows")
	for lang in GameText.LANGUAGES:
		check(AionCampaignText.EXPANSION.data.has(lang),"Expansion copy exists for "+lang)
		for key in AionCampaignText.EXPANSION.data.en:check(not AionCampaignText.word(lang,key).is_empty() and AionCampaignText.word(lang,key)!=key,"Actual localized expansion label: "+lang+"/"+key)
		var fonts: Array[Font]=[preload("res://assets/fonts/NotoSans-Game.ttf"),preload("res://assets/fonts/NotoSansCJK-Game.otf"),preload("res://assets/fonts/Campaign-CJK.otf"),preload("res://assets/PixelifySans.ttf")]
		var missing: Dictionary={}
		for key in AionCampaignText.EXPANSION.data.en:
			var copy:=AionCampaignText.word(lang,key)
			for index in copy.length():
				var code:=copy.unicode_at(index)
				if code>=32 and not fonts.any(func(font):return font.has_char(code)):missing[code]=true
		check(missing.is_empty(),"Every expansion translation has offline glyphs: "+lang+" "+str(missing.keys()))
	print("RESULT: %d campaign expansion checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
