extends SceneTree

var checks:=0
var failures:=0

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL: "+label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var w:=AionCampaignWorld.new()
	w.begin("aion")
	var npc: Dictionary=w.npcs[0]
	w.rescue(npc)
	check(w.life_rescues()==1 and w.score>0,"Rescue awards this life before death")
	var score:=w.score
	var snapshot:=w.snapshot()
	check(w.restore(snapshot) and w.score==score and w.life_rescues()==1,"A same-life reload preserves its rescue and score")
	w.state="playing";w.invulnerable=0.;w.damage_player("shot")
	check(w.score==0 and w.life_rescues()==0 and w.rescued.size()==1,"Fatal damage immediately clears only the life tally")
	var fallen:=w.snapshot()
	check(w.restore(fallen) and w.score==0 and w.life_rescues()==0,"The life tally remains clear across offline Continue")
	w.state="playing"
	var next: Dictionary=w.npcs[1]
	w.rescue(next)
	check(w.life_rescues()==1 and w.rescued.size()==2,"A new life can rescue a new NPC without replaying the previous gift")
	w.boss.active=true;w.boss.engaged=true;w.boss.hp=1;w.boss.phase=3;w.boss.wait=1.8
	var field_score:=w.score
	w.damage_boss(1)
	check(w.completed and w.score==field_score+3300,"Only the finishing life's rescue earns the completion bonus")

	var catalog:=CampaignCatalog.new()
	for i in 8:
		var last: float=-1.
		var hashes: Dictionary={}
		for j in 6:
			var pose: Dictionary=catalog.pose("rescue-npcs",i,6+j)
			var cell: Image=pose.texture.get_image()
			var footprint: Rect2i=cell.get_used_rect()
			var foot: float=pose.offset.y+float(footprint.end.y)*pose.size.y/float(cell.get_height())
			check(absf(foot)<.01,"Keeper sole remains on the physics origin: %d/%d"%[i,j])
			hashes[cell.get_data().hex_encode().sha256_text()]=true
			var index:=CampaignRescue.walk_frame({"stride_distance":float(j)*8.+.1},true)
			check(float(index)>last,"Distance exposes the ordered walk frames")
			last=index
		check(hashes.size()==6,"Keeper has six different actual rendered textures: %d"%i)
		check(CampaignRescue.walk_frame({"stride_distance":48.},true)==6,"Walking repeats at the original contact")
	for action in ["walk_back","crouch_walk_back","tunnel_walk_back"]:
		for frame in 6:check(M1CombatArt.backstep_frame(action,frame)==5-frame,"Backpedal runs the registered stride in reverse")

	for section in CampaignHive.SECTIONS:
		w.begin("aion");w.load_section(section);w.state="playing"
		var candidates:=w.enemies.filter(func(e):return e.kind==CampaignHive.KIND)
		check(candidates.size()==1,"Optional hive lives in "+section)
		var hive: Dictionary=candidates[0]
		w.enemies.assign(candidates);w.bullets.clear();w.invulnerable=0.
		w.player=Vector2(float(hive.x)-170.,w.floor_at(float(hive.x)-170.))
		hive.wait=0.
		w.step_enemies(.01)
		check(hive.windup==CampaignHive.WINDUP and w.bullets.is_empty(),"Hive telegraphs before dropping anything")
		for tick in 170:w.step_enemies(.01)
		check(w.bullets.size()==3,"Hive emits exactly three sequential bombs on the first pass")
		check(absf(float(w.bullets.front().p.x)-float(w.bullets.back().p.x))>120.,"The pass bombards three distinct parts of the lane")
		for b in w.bullets:
			check(b.kind=="honeycomb" and b.v.y>0.,"Bombs travel downward without auto-aim")
		var at_x: float=w.player.x
		var floor: float=w.floor_at(at_x)
		var comb: Dictionary={"p":Vector2(at_x,floor-50.),"v":Vector2(0.,250.),"age":0.}
		CampaignHive.step_comb(w,comb,.01)
		check(float(comb.age)<99.,"A comb remains in flight before touching the surface")
		for tick in 25:
			if float(comb.age)>=99.:break
			CampaignHive.step_comb(w,comb,.01)
		check(w.blasts.any(func(b):return b.get("kind")=="honeycomb" and is_equal_approx(b.p.y,floor)),"A bomb splashes on actual support")
		check(w.hp==0,"Standing in the honey blast causes real damage")
		w.state="playing";w.hp=1;w.invulnerable=0.;w.bullets.clear()
		w.enemies.assign(candidates);w.platforms.clear();w.objects.clear()
		var shot_x: float=hive.x
		w.player=Vector2(shot_x,w.floor_at(shot_x))
		w.aim_direction=Vector2.UP
		w.fire_time=0.
		CampaignWeapons.fire(w)
		for tick in 45:w.step_bullets(.01)
		check(hive.hp==CampaignHive.HP-1,"A real upward pistol shot hits the hive's visible body")

	print("RESULT: %d hive, keeper and tally checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
