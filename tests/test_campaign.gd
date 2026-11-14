extends SceneTree
var checks:=0
var failures:=0
const World=preload("res://scripts/campaign_world.gd")

func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL "+message)
func fresh(hero: String="aion") -> AionCampaignWorld:
	var w:=World.new();w.begin(hero);w.run_seed=7719;w.state="playing";w.enemies.clear();w.gates.clear();return w
func tick(w: AionCampaignWorld,seconds: float) -> void:
	for i in ceili(seconds*120.):w.step(1./120.)
func _initialize() -> void:call_deferred("run")

func run() -> void:
	var w:=fresh()
	w.time=90.;w.walk_distance=900.;w.begin("aion");w.state="playing";w.enemies.clear();w.gates.clear();check(w.time==0. and w.walk_distance==0.,"New mission resets its own clock and locomotion phase")
	var start:=w.player
	tick(w,1.)
	check(w.player.is_equal_approx(start),"No automatic running or horizontal animation compensation")
	w.move_axis.x=1.;tick(w,.5);check(w.player.x>start.x+100.,"Player moves right through physics")
	w.move_axis.x=-1.;tick(w,.25);check(w.facing==-1 and w.player.x<start.x+90.,"Player moves/faces left")
	w.move_axis=Vector2.ZERO;w.jump_press();tick(w,.12);w.jump_release();w.jump_press()
	check(w.jumps==2 and w.velocity.y<0.,"Aion retains second airborne jump")
	w.jump_release();w.jump_press();check(w.jumps==2,"No third Aion jump")
	for hero in ["rabbit","eren"]:
		var short:=fresh(hero);short.jump_press();tick(short,.05);check(short.grounded(),hero+" stays planted while charging");short.jump_release();var low:=short.velocity.y
		var long:=fresh(hero);long.jump_press();tick(long,1.2);long.jump_release();check(long.velocity.y<low-400.,hero+" release launches proportionally to charge")
		var peaks:=[]
		for hold in [.9,1.2]:
			var charged:=fresh(hero);charged.jump_press();tick(charged,hold);charged.jump_release();var peak:=0.
			for step in 220:charged.step(.01);peak=minf(peak,charged.player.y)
			peaks.append(peak)
		check(float(peaks[1])<float(peaks[0])-50.,hero+" full charge actually travels higher, without an invisible low ceiling")
	w=fresh("owl");w.jump_press();tick(w,.25)
	for i in 3:
		w.jump_release();w.jump_press();check(w.flap_count==i+1,"Owl flap "+str(i+1))
	w.jump_release();w.jump_press();check(w.flap_count==3,"Owl does not get a fourth flap")
	w.jump_held=true;tick(w,.5);check(w.gliding and w.velocity.y<=85.,"Owl hold glides without horizontal swaying")
	w.player=Vector2(140,0);w.velocity=Vector2.ZERO;tick(w,.02);check(w.flap_count==0,"Owl landing recharges wingbeats")
	for hero in World.HEROES:
		var bank:=RunnerFrameBank.new()
		check(bank.descriptor("gun-run",bank.hero_row(hero)).key=="pixel-"+hero,"Hero identity is resolved independently of roster order: "+hero)
		w=fresh(hero);w.spawn_enemy("gnome",200,0,0);w.attack_press()
		check(not w.enemies[0].defeated,"Close attack keeps its anticipation before contact: "+hero);tick(w,.17)
		check(w.enemies[0].defeated,"One close hit defeats an ordinary enemy: "+hero)
		check(w.melee_time>0. and w.shots==0,"Context chooses melee instead of gun: "+hero)
		w.spawn_enemy("gnome",210,0,1);tick(w,.5)
		check(not w.enemies[1].defeated,"Holding close attack does not repeat punches: "+hero)
		w.attack_release();w.attack_press();tick(w,.17);check(w.enemies[1].defeated,"A fresh press attacks the next nearby enemy: "+hero)
		w=fresh(hero);w.spawn_enemy("gnome",300,0,0);w.attack_press();tick(w,.25)
		check(w.enemies[0].defeated and w.shots>=1,"Actual pistol bullet damages enemy: "+hero)
		check(w.grenades==5 and w.throw_grenade() and w.bombs[0].color==World.COLORS[hero],"Grenade uses hero palette: "+hero)
		check(not w.throw_grenade(),"Grenade cooldown prevents duplicate command: "+hero)
	w=fresh();w.spawn_enemy("seed",190,0,0);w.spawn_enemy("beetle",230,0,1)
	w.explode({"p":Vector2(210,-20),"color":"ef86b7"})
	check(w.enemies[0].defeated and w.enemies[1].defeated,"Grenade damages multiple ordinary enemies")
	w=fresh();w.spawn_enemy("gnome",200,0,0);w.player=Vector2(200,-90);w.velocity.y=300.;w.invulnerable=0.;tick(w,.14)
	check(w.enemies[0].defeated and w.velocity.y<0. and w.hp==3,"Descending onto a normal enemy defeats it once and bounces safely")
	for kind in ["gnome","beetle","slime","crow","moth","drone","seed"]:
		w=fresh();w.spawn_enemy(kind,300,-115. if kind in ["crow","moth","drone"] else 0.,0);w.enemy_shot(w.enemies[0])
		if kind in ["gnome","beetle","slime"]:check(w.bullets.is_empty() and w.enemies[0].dash>0.,kind+" telegraphs a physical rush rather than another generic shot")
		elif kind=="crow":check(w.bullets.is_empty() and w.enemies[0].dive>0.,"Crow uses an actual diving trajectory")
		elif kind=="moth":check(w.bullets.size()==1 and w.bullets[0].gravity>0.,"Flying spore attack actually falls")
		elif kind=="drone":check(w.bullets.size()==2,"Scout drone fires a distinct two-shot fan")
		else:check(w.bullets.size()==1,"Seed sentry uses a readable aimed shot")
	w=fresh();w.load_section("water");var layout:=JSON.stringify(w.enemies);w.retry();check(JSON.stringify(w.enemies)==layout,"A checkpoint retry reproduces its seeded enemy layout")
	var restored_layout:=World.new();check(restored_layout.restore(w.snapshot()) and JSON.stringify(restored_layout.enemies)==layout,"The same layout seed survives real checkpoint serialization")
	var alternate:=fresh();alternate.run_seed=7718;alternate.load_section("water");check(JSON.stringify(alternate.enemies)!=layout,"A different mission seed varies spacing and later enemy roles")
	w=fresh();w.grenades=0
	w.grenades=0;check(not w.throw_grenade() and w.bombs.is_empty(),"Empty grenade inventory cannot throw")
	w=fresh();w.attack_press();tick(w,1.1);check(w.shots>=4 and w.weapon=="pistol","Held gun fires at intervals with no reload")
	w.stop_inputs();var shots:=w.shots;tick(w,.6);check(w.shots==shots,"Focus/menu input clearing releases fire")
	w=fresh();w.hp=1;w.invulnerable=0.;w.player.y=-120.;w.damage_player();check(w.state=="dying","Fatal damage begins the existing fall animation before the menu")
	tick(w,1.2);check(w.state=="dead" and w.grounded(),"Airborne defeat falls onto the real floor instead of leaving a corpse floating")
	for state in ["paused","story","fork_one","travel","dead","complete"]:
		w.state=state;var clock:=w.time;var p:=w.player;tick(w,.5);check(w.time==clock and w.player==p,"Non-play state freezes physics: "+state)
	w=fresh("sheep");var keeper: Dictionary=w.npcs[0];w.rescue(keeper);var score:=w.score
	w.rescue(keeper);check(w.rescued.size()==1 and w.score==score and w.flock==2,"Keeper rewards granted once and preserves sheep companion")
	w.retry();w.rescue(w.npcs[0]);check(w.rescued.size()==1 and w.score==score,"Checkpoint retry does not farm rescue rewards")
	w.load_section("quay");w.player.x=360.;check(w.interact() and w.mount.ridden,"Skimmer can be boarded")
	w.invulnerable=0.;var hp:=w.hp;w.damage_player();check(w.hp==hp and w.mount.hp==3,"Skimmer armour takes damage before rider")
	w.jump_press();tick(w,.1);check(w.player.y< -42.,"Mounted jump really leaves the saddle floor")
	check(w.interact() and not w.mount.ridden,"Skimmer can be exited")
	w=fresh();w.state="fork_one";check(w.choose_route("canopy") and w.state=="travel" and w.section=="shore","First route waits for transition fade")
	w.finish_travel();check(w.section=="canopy","First high branch is a real stage")
	w.state="fork_two";check(w.choose_route("roots"),"High path offers a second binary fork");w.finish_travel();check(w.section=="roots" and w.route==["canopy","roots"],"Root leaf records actual two-stage choice")
	for leaf in ["water","terrace","roots"]:
		w=fresh();w.load_section(leaf)
		check(World.STAGES[leaf].next=="relay","All three branches converge: "+leaf)
		check(w.enemies.any(func(e):return e.kind=="warden" and e.max_hp==12),"Each leaf has a guardian: "+leaf)
		for e in w.enemies:
			if e.kind not in ["crow","moth","wisp","drone"]:check(w.floor_at(float(e.x))==0.,"Ground enemy starts on actual floor")
		for crate in w.crates:check(w.floor_at(float(crate.x))==0.,"Supply crate starts on floor")
		for item in w.pickups:
			if w.floor_at(float(item.x))!=0.:check(float(item.y)==-105.,"Gap fruit is above its reachable stepping platform")
	w=fresh();w.load_section("arena");tick(w,2.);w.damage_boss(99);check(w.boss.clock==0. and w.bullets.is_empty() and w.boss.hp==90,"Offscreen boss waits for introduction and cannot be killed before it")
	w.boss.engaged=true;w.boss.hp=90;w.boss.wait=0.;tick(w,1.1);check(w.bullets.size()>=5,"Boss actually fires fan attack")
	w.boss.windup=0.;w.boss.wait=0.;w.boss.attack=1;w.bullets.clear();tick(w,1.1);check(w.bullets.any(func(b):return b.kind=="wave"),"Boss fires jumpable root wave")
	w.boss.windup=0.;w.boss.wait=0.;w.boss.attack=2;tick(w,1.1);check(w.enemies.size()>=2,"Boss deploys drones")
	w.damage_boss(70);w.step(.01);check(w.boss.phase==3,"Boss changes phase with remaining health")
	w.damage_boss(20);check(w.completed and w.state=="victory","Boss defeat settles before the result screen")
	tick(w,1.25);check(w.state=="complete","Finite mission actually ends after victory transition")
	var final_score:=w.score;w.damage_boss(90);check(w.score==final_score,"Boss cannot grant completion reward twice")
	var restore:=World.new();check(restore.restore(w.snapshot()) and restore.completed and restore.state=="complete","Completed campaign survives save/load")
	check(not restore.restore({"schema":9}),"Unsupported save schema rejected")
	check(not restore.restore({"schema":1,"checkpoint":"missing","character":"aion"}),"Unknown checkpoint rejected")
	var damaged:=w.snapshot();damaged.rescued="corrupt";check(not restore.restore(damaged),"Malformed saved list is rejected without a startup script error")
	damaged=w.snapshot();damaged.score="many";check(not restore.restore(damaged),"Malformed saved score is rejected")
	for locale in GameText.LANGUAGES:
		for key in AionCampaignText.EN:
			var translated: bool=locale=="en" or (locale=="tr" and AionCampaignText.TR.has(key)) or (AionCampaignText.LOCAL.has(locale) and AionCampaignText.LOCAL[locale].has(key)) or (AionCampaignText.SUPPLEMENT.data.has(locale) and AionCampaignText.SUPPLEMENT.data[locale].has(key)) or key in ["keys","pad"]
			check(translated and not AionCampaignText.word(locale,key).is_empty(),"Campaign copy has an explicit translation: "+locale+"/"+key)
	var fonts: Array[Font]=[preload("res://assets/fonts/NotoSans-Game.ttf"),preload("res://assets/fonts/NotoSansCJK-Game.otf"),preload("res://assets/fonts/Campaign-CJK.otf"),preload("res://assets/PixelifySans.ttf")]
	var glyphs: Dictionary={}
	for locale in GameText.LANGUAGES:
		for key in AionCampaignText.EN:
			var copy:=AionCampaignText.word(locale,key)
			for index in copy.length():glyphs[copy.unicode_at(index)]=true
	for code in glyphs:
		if int(code)<32:continue
		check(fonts.any(func(font):return font.has_char(int(code))),"All new player-facing characters have a bundled offline glyph: "+String.chr(int(code)))
	print("RESULT: %d campaign checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
