extends SceneTree

var checks:=0
var failures:=0

func check(value: bool,label: String) -> void:
	checks+=1
	if not value:failures+=1;printerr("FAIL: "+label)

func fresh() -> AionCampaignWorld:
	var w:=AionCampaignWorld.new()
	w.begin("aion");w.state="playing"
	w.enemies.clear();w.gates.clear();w.objects.clear();w.hazards.clear()
	return w

func _initialize() -> void:call_deferred("run")

func run() -> void:
	var w:=fresh()
	check(w.floor_at(3140.)==56. and w.floor_at(3570.)==-58. and w.floor_at(4200.)==0.,"One walking lane contains a sheltered basin and a raised shelf")
	check(not CampaignGround.has_floor(w.floor_at(6000.)),"The collapsing bridge keeps its real underlying void")
	for type in ["foot","skimmer","shell","wind","drill"]:
		w=fresh()
		var saddle:=0. if type=="foot" else 42.
		if type!="foot":w.mount={"available":true,"ridden":true,"hp":1,"type":type,"x":2750.}
		w.player=Vector2(2750.,-saddle)
		w.move_axis=Vector2.RIGHT
		var error:=0.
		for tick in 950:
			w.step(1./120.)
			error=maxf(error,absf(w.player.y+saddle-w.floor_at(w.player.x)))
			if w.player.x>=4190.:break
		check(w.player.x>=4190. and w.hp==1,"Normal movement traverses both grades without a jump or death: "+type)
		check(error<.1,"The real body or saddle stays planted at the shared height: "+type)
	w=fresh()
	w.player=Vector2(3060.,56.)
	w.spawn_enemy("gnome",3435.,w.floor_at(3435.),800);var e:=w.enemies[0];e.wait=999.
	for tick in 50:w.step_enemies(.01)
	check(float(e.x)<3435. and absf(float(e.y)-w.floor_at(float(e.x)))<.01,"A ground enemy follows the grade while approaching")
	w=fresh();var npc: Dictionary=w.npcs[1]
	check(absf(float(npc.y)-w.floor_at(float(npc.x)))<.01,"A bound NPC stands on its real sloped surface")
	w.rescue(npc);w.player=Vector2(2800.,0.)
	var initial_x:=float(npc.x)
	for tick in 40:CampaignRescue.step(w,.01)
	check(absf(float(npc.x)-initial_x)>1. and absf(float(npc.y)-w.floor_at(float(npc.x)))<.01,"Freed NPC feet stay on the grade while roaming")
	w.player=Vector2(float(npc.x),float(npc.y))
	for tick in 130:CampaignRescue.step(w,.01)
	var dropped: Dictionary=w.gift_drops.get(str(npc.id),{})
	check(not dropped.is_empty() and absf(float(dropped.get("y",0.))+25.-w.floor_at(float(dropped.get("x",0.))))<.01,"The handover lands within reach on uneven ground")
	var section:=Rect2(2950.,-430.,1152.,625.)
	var landing:=CampaignLives.landing(w,section)
	check(CampaignLives.landing_clear(w,landing) and landing.x>=section.position.x and landing.x<section.end.x,"Reserve return has a safe local terrain pocket")
	w=fresh()
	w.bullets=[{"p":Vector2(3280.,25.),"v":Vector2(2200.,0.),"age":0.,"owner":"hero","kind":"pistol","pierce":0,"damage":1,"hit":[]}]
	w.step_bullets(.1)
	check(w.bullets.is_empty(),"A projectile crossing a raised slope is physically stopped")
	w=fresh()
	w.platforms.clear();w.player=Vector2(3345.,w.floor_at(3345.));w.throw_grenade()
	var contact:=Vector2.ZERO
	for tick in 160:
		w.step(.01)
		for bomb in w.bombs:
			if not bomb.contacts.is_empty():contact=bomb.contacts[-1].p
		if contact!=Vector2.ZERO:break
	check(contact!=Vector2.ZERO,"A normal grenade throw contacts the actual terrain")
	if contact!=Vector2.ZERO:
		var support: float=w.crossing_floor(contact.x,contact.y-3.,contact.y+3.,1.)
		check(absf(contact.y-support)<4.,"Grenade impact cue sits on the physical surface: %s / %.2f"%[str(contact),support])
	w=fresh()
	w.player=Vector2(3540.,0.);w.attempts_remaining=2;w.awarded["shore:old-claim"]=true
	var flat_save:=w.snapshot();flat_save.erase("ground_revision")
	var restored:=AionCampaignWorld.new()
	check(restored.restore(flat_save) and restored.player==Vector2(3540.,-58.) and restored.attempts_remaining==2 and restored.awarded.has("shore:old-claim"),"An earlier flat save adapts its feet without renewing lives or claims")
	for key in CampaignGround.PROFILES:
		if key=="shore":continue
		w=fresh();w.load_section(key)
		w.enemies.clear();w.gates.clear();w.objects.clear();w.hazards.clear();w.zones.clear();w.platforms.clear();w.pits.clear()
		var points: Array=CampaignGround.PROFILES[key]
		w.player=points.front()
		w.move_axis=Vector2.RIGHT
		var low:=0.
		var high:=0.
		var footing:=true
		for tick in 2400:
			w.step(1./120.)
			high=minf(high,w.player.y);low=maxf(low,w.player.y)
			footing=footing and absf(w.player.y-w.floor_at(w.player.x))<.1
			if w.player.x>=points.back().x:break
		check(footing and high-low< -20. and w.player.x>=points.back().x and w.attempts_remaining==3,"Each authored profile retains real supported traversal and changes elevation: "+key)
	w=fresh();w.load_section("water");w.pits.assign([Vector2(5940.,6010.)])
	check(not CampaignGround.fell_into_pit(w,Vector2(5960.,214.)) and CampaignGround.fell_into_pit(w,Vector2(5960.,400.)),"A real pit at the deep basin uses its local lips to measure falling")
	print("RESULT: %d campaign terrain checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
