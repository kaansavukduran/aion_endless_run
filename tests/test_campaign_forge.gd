extends SceneTree

## Isolated real-physics fixtures: no frontend input or physical device claim.
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; printerr("FAIL: " + message)

func fresh(hero: String="aion") -> AionCampaignWorld:
	var w := AionCampaignWorld.new()
	w.begin(hero); w.state="playing"
	w.enemies.clear();w.gates.clear();w.objects.clear();w.hazards.clear();w.pickups.clear();w.crates.clear();w.zones.clear();w.platforms.clear();w.pits.clear();w.npcs.clear()
	return w

func tick(w: AionCampaignWorld, seconds: float, hz: int=120) -> void:
	for i in ceili(seconds*hz): w.step(1./hz)

func apex(w: AionCampaignWorld, hz: int) -> float:
	var start := w.player.y
	var peak := start
	for i in hz*3:
		w.step(1./hz);peak=minf(peak,w.player.y)
		if w.velocity.y>=0.:break
	return start-peak

func _initialize() -> void: call_deferred("run")

func run() -> void:
	for hz in [60,120,240]:
		var a := fresh();a.jump_press();a.jump_release()
		var reference := apex(a,hz)
		for hero in ["rabbit","eren","frog"]:
			var low := fresh(hero);low.jump_press();low.jump_release()
			var tap := apex(low,hz)
			check(absf(tap/reference-1.75)<.04,"Actual tap apex is1.75 Aion: %s/%d" % [hero,hz])
			var high := fresh(hero);high.jump_press();tick(high,high.charge_duration()+(high.RABBIT_JUMP_HOLD if hero in high.RABBITS else 0.),hz);high.jump_release()
			var charged := apex(high,hz)
			check(absf(charged/reference-4.)<.12 and charged>tap*2.,"Actual full-charge apex is4 Aion: %s/%d" % [hero,hz])
		# Archived physics is retained for old source/ability consumers; owl is
		# deliberately not selectable, so assign only after begin's migration.
		var owl := fresh();owl.character="owl";owl.player.y=-100.;owl.jumps=1
		for index in 3:
			owl.jump_release();owl.jump_press()
			check(owl.flap_count==index+1,"Fresh airborne press spends exactly one flap")
			owl.jump_press();check(owl.flap_count==index+1,"Held/repeated press cannot synthesize extra flaps")
			var rise := apex(owl,hz)
			check(absf(rise/reference-1.5)<.04,"Actual flap rise is1.50 Aion: %d/%d" % [index,hz])
		owl.jump_release();owl.jump_press();check(owl.flap_count==3,"Fourth fresh press cannot flap")
		tick(owl,.3,hz);check(owl.gliding and owl.velocity.y<=85.,"Held glide resumes after powered ascent")
		owl.jump_release();tick(owl,4.,hz);check(owl.grounded() and owl.flap_count==0,"Landing safely refills all three wingbeats")
	var aion:=fresh()
	for jump_index in 3:
		aion.jump_press();aion.jump_release();tick(aion,.05)
		check(aion.jumps==jump_index+1,"Aion spends a distinct jump on press %d"%(jump_index+1))
	tick(aion,.06)
	var falling_speed:=aion.velocity.y
	aion.jump_press();aion.jump_release()
	check(aion.jumps==3 and aion.velocity.y==falling_speed,"There is no fourth jump boost")
	tick(aion,3.)
	check(aion.grounded() and aion.jumps==0,"Landing restores Aion's whole jump allowance")

	var sheep:=fresh("sheep")
	for i in 3:CampaignRescue.on_gift_collected(sheep,{"rescue_id":"test-"+str(i)})
	check(sheep.flock==2,"New recruits stop at the leader plus one sheep")
	var old_sheep:=sheep.snapshot(false)
	old_sheep.schema=3;old_sheep.flock=3
	old_sheep.rally=CampaignRecovery.capture(sheep,140.);old_sheep.rally.flock=3
	var restored_sheep:=AionCampaignWorld.new()
	check(restored_sheep.restore(old_sheep) and restored_sheep.flock==2,"Legacy saves with two companions reopen with one")

	var frog:=fresh("frog")
	var old_frog:=frog.snapshot();old_frog.frog_cooldown=9.4
	var restored_frog:=AionCampaignWorld.new()
	check(restored_frog.restore(old_frog) and restored_frog.frog_cooldown==5.,"Legacy tongue cooldown migrates without rejecting the save")
	var dirs: Array[Vector2]=[Vector2.RIGHT,Vector2(1,-1).normalized(),Vector2.UP,Vector2(-1,-1).normalized(),Vector2.LEFT,Vector2(-1,1).normalized(),Vector2.DOWN,Vector2(1,1).normalized()]
	for hero in AionCampaignWorld.HEROES:
		for direction in dirs:
			var w := fresh(hero)
			# Downward aim is an airborne action in the real control scheme.
			# A grounded low hand must not push its barrel through the floor.
			if direction.y>.1:w.player.y=-150.;w.air_time=.2
			w.aim_direction=direction;w.attack_press()
			check(w.bullets.size()==1,"Each hero actually fires in eight directions")
			var b: Dictionary=w.bullets[0]
			check(Vector2(b.v).normalized().distance_to(direction)<.001 and absf(Vector2(b.v).length()-760.)<.001,"Direction normalized without diagonal speed bonus: %s %s" % [hero,direction])
			check(float(b.p.y)<0.,"Every initial muzzle remains above the floor")
	for hero in ["armadillo","frog"]:
		var w := fresh(hero);w.aim_direction=Vector2.DOWN;w.attack_press()
		var b: Dictionary=w.bullets[0]
		check(w.grounded() and Vector2(b.v).is_equal_approx(Vector2.RIGHT*760.),"Low grounded hero uses horizontal shot instead of a buried downward barrel: "+hero)
		check(float(b.p.y)<w.floor_at(float(b.p.x)) and (Vector2(b.p)-w.player).distance_to(w.armed_muzzle())<.001,"Grounded floor fallback keeps actual projectile at the visible muzzle: "+hero)
	for weapon in CampaignWeapons.SPECIAL:
		for direction in dirs:
			var w := fresh();w.collect({"id":"special","kind":weapon})
			if direction.y>.1:w.player.y=-150.;w.air_time=.2
			w.aim_direction=direction;w.attack_press()
			var spec: Dictionary=CampaignWeapons.SPECS[weapon]
			for b in w.bullets:
				check(absf(Vector2(b.v).length()-float(spec.speed))<.01,"Special projectile retains its authored speed: "+weapon)
				check(Vector2(b.v).normalized().dot(direction)>.55,"All actual spread/projectile vectors rotate with aim: "+weapon)
			check(w.ammunition==int(spec.ammo)-1,"One directional burst spends one ammo: "+weapon)
	for direction in dirs:
		var w := fresh();w.mount={"available":true,"ridden":false,"x":140.,"hp":1,"type":"wind"};w.interact()
		check(w.mount_transition=="enter" and not w.throw_grenade(),"Boarding blocks combat until the hatch transition finishes")
		w.attack_press();check(w.bullets.is_empty(),"Boarding cannot fire a hidden extra shot")
		tick(w,.46);w.aim_direction=direction;w.attack_press()
		check(w.mount.ridden and w.bullets.size()==1,"Mounted wind craft emits one shot along its continuous aim")
		check(w.vehicles_used==["wind"],"Vehicle report records one completed board")
		for b in w.bullets:check(Vector2(b.v).normalized().dot(direction)>.95,"Vehicle barrel follows aim rather than character facing")
		w.attack_release();check(w.interact(),"Vehicle exit accepted")
		tick(w,.46);check(not w.mount.ridden and w.grounded() and w.mount_transition=="","Exit finishes on supported ground")
	var w := fresh();w.mount={"available":true,"ridden":false,"x":140.,"hp":1,"type":"drill"};w.interact();var frozen:=w.time
	w.invulnerable=0.;w.damage_player();check(w.hp==1 and w.mount.hp==1,"Boarding is protected from damage")
	tick(w,.4);check(w.time==frozen,"World simulation clock pauses during boarding");tick(w,.06)
	w.invulnerable=0.;w.damage_player();tick(w,.1);check(not w.mount.ridden and w.mount_transition=="" and w.velocity.y<0.,"Vehicle destruction cancels transition and ejects safely")
	# Bullet rescue occurs at distance; walking into the freed person, not
	# elapsed time, authorizes the gratitude/gift state.
	w=fresh();CampaignRescue.populate(w);var npc: Dictionary=w.npcs[0]
	w.player=Vector2(float(npc.x)-300.,0.);w.attack_press();tick(w,.5);w.attack_release()
	check(npc.freed and w.rescued.has(str(npc.id)),"Actual ordinary bullet cuts a distant NPC rope")
	check(str(npc.phase)=="free" and not w.awarded.has(str(npc.id)+":gift"),"Freeing remotely does not trigger a thank-you/gift")
	var released_x: float=npc.x;tick(w,2.)
	check(absf(float(npc.x)-released_x)>1. and absf(float(npc.x)-float(npc.home_x))<=90.,"Freed NPC really roams within supported bounds")
	check(not w.awarded.has(str(npc.id)+":gift"),"Elapsed time alone cannot claim a remote gift")
	var pending := w.snapshot();var restored := AionCampaignWorld.new();check(restored.restore(pending),"Unclaimed freed NPC survives save/reload")
	restored.state="playing";tick(restored,1.);check(not restored.awarded.has(str(npc.id)+":gift"),"Reload does not auto-claim a never-contacted freed NPC")
	w.player=Vector2(float(npc.x),float(npc.y));tick(w,.1)
	check(str(npc.phase)=="thanks" and w.greeted.has(str(npc.id)),"Actual body contact triggers gratitude")
	var greeting := w.snapshot();var resumed := AionCampaignWorld.new();check(resumed.restore(greeting),"Pending actual-contact handover is saved")
	resumed.state="playing";tick(resumed,1.2)
	var supplies: Array=resumed.pickups.filter(func(item):return str(item.id)==str(npc.id)+":supply")
	check(supplies.size()==1 and resumed.weapon=="pistol" and not resumed.awarded.has(str(npc.id)+":gift"),"A genuine pending handover resumes as one unclaimed physical bag item")
	if not supplies.is_empty():
		resumed.player=Vector2(float(supplies[0].x),float(supplies[0].y)+25.);resumed.velocity=Vector2.ZERO;tick(resumed,.3)
	check(resumed.awarded.has(str(npc.id)+":gift") and resumed.weapon=="heavy","Only actual dropped-item contact claims the resumed handover")
	resumed.invulnerable=0.;resumed.damage_player();tick(resumed,1.);CampaignLives.start_entry(resumed,Rect2(0,-420,1152,500));tick(resumed,.65)
	check(resumed.score==0 and resumed.life_rescues()==0 and resumed.awarded.has(str(npc.id)+":gift") and resumed.weapon=="pistol","Reserve entry cannot pay an already-claimed NPC twice")
	check(resumed.rescue_roles.has(str(npc.id)),"Actual rescued role survives checkpoint reports")
	# A flying/angled beam still intersects ropes across a large timestep.
	w=fresh();CampaignRescue.populate(w);npc=w.npcs[0];w.player=Vector2(float(npc.x)-500.,0.)
	w.bullets=[{"p":Vector2(float(npc.x)-100.,-60.),"v":Vector2(1900.,0.),"owner":"hero","age":0.,"kind":"beam","damage":2,"pierce":20,"hit":[],"life":.5}]
	w.step(.05);w.step(.05);check(npc.freed,"Fast beam uses segment-vs-rope collision")
	# Structured role/weapon/loss statistics are observations, not UI inventions.
	w=fresh();w.invulnerable=0.;w.damage_player();check(w.losses==1,"Actual HP loss updates report once")
	w.invulnerable=0.;w.damage_player();check(w.losses==1,"Another hit cannot spend an additional life while dying")
	tick(w,1.);CampaignLives.start_entry(w,Rect2(0,-420,1152,500));tick(w,.65)
	w.attack_press();check(w.weapons_used==["pistol"],"Actual first pistol shot is recorded")
	w.collect({"id":"gun","kind":"arc"});check(w.weapons_used.has("arc"),"Real weapon collection updates report")
	var saved := w.snapshot();var copy := AionCampaignWorld.new();check(copy.restore(saved) and copy.losses==1 and copy.weapons_used==w.weapons_used,"Statistics persist without changing old checkpoint semantics")
	print("RESULT: %d campaign forge mechanics checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
