extends SceneTree
var checks:=0
var failures:=0

func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+message)

func clean(hero: String) -> AionCampaignWorld:
	var w:=AionCampaignWorld.new();w.begin(hero)
	w.enemies.clear();w.objects.clear();w.hazards.clear();w.zones.clear();w.encounters.clear();w.gates.clear();w.npcs.clear();w.crates.clear();w.pickups.clear();w.platforms.clear();w.pits.clear()
	w.state="playing";w.invulnerable=0.;return w

func advance(w,seconds: float) -> void:
	for i in int(ceil(seconds/.01)):w.step(.01)

func target(w,x: float,hp: int=10) -> Dictionary:
	w.spawn_enemy("seed",x,0.,w.enemies.size())
	var e: Dictionary=w.enemies.back();e.hp=hp;e.max_hp=hp;e.wait=100.;e.armour=0
	return e

func _initialize() -> void:call_deferred("run")

func run() -> void:
	for hero in ["armadillo","frog"]:
		var w:=clean(hero)
		check(w.character==hero,"new hero begins by stable identity: "+hero)
		var save:=w.snapshot();var restored:=AionCampaignWorld.new()
		check(restored.restore(save) and restored.character==hero,"checkpoint preserves new hero identity: "+hero)
		for action in MissionHeroArt.actions(hero):
			var clip:=MissionHeroArt.clip_spec(hero,action)
			check(int(clip.frames)==6,"authored six-frame clip exists: "+hero+":"+action)
			for frame in int(clip.frames):
				var pose:=MissionHeroArt.pose(hero,action,frame)
				check(pose.texture!=null and pose.size.x>0. and pose.size.y>0.,"runtime texture extracts: "+hero+":"+action+":"+str(frame))
				check(is_equal_approx(float(pose.source_scale),float(MissionHeroArt.DATA.data.atlases[hero].scale)),"fixed source scale: "+hero+":"+action)
				if bool(pose.ground_contact):check(absf(pose.offset.y+pose.size.y-2.*float(pose.source_scale))<.01,"authored grounded frame shares actual foot baseline: "+hero+":"+action)
		w.boost_held=true;w.move_axis=Vector2.RIGHT;w.step(.01)
		check(is_equal_approx(w.velocity.x,235.*1.55),"Shift/LB sprint retained: "+hero)
		w.aim_direction=Vector2.LEFT;w.walk_distance=45.
		check(MissionHeroArt.body_spec(w).action=="walk_back","actual backwards velocity selects authored backwalk: "+hero)
		check(MissionHeroArt.metrics(hero,"walk_back",1).source_row!=MissionHeroArt.metrics(hero,"walk",1).source_row,"backwalk is distinct authored row: "+hero)
		var low_forward:=MissionHeroArt.metrics(hero,"crouch_walk",0);var low_back:=MissionHeroArt.metrics(hero,"crouch_walk_back",0)
		check(low_forward.source_key!=low_back.source_key or low_forward.source_row!=low_back.source_row,"low backwalk uses separately drawn cels, never reversed forward row: "+hero)
		w=clean(hero);w.time=1.03
		for frame in 6:
			w.melee_time=.28*(1.-(float(frame)+.1)/6.);w.rescue_time=0.
			var melee_spec:=MissionHeroArt.body_spec(w)
			check(melee_spec.action=="idle_fire" and int(melee_spec.frame)==frame,"real knife clock selects correct shared body phase: "+hero+"/"+str(frame))
			w.melee_time=0.;w.rescue_time=.6*(1.-(float(frame)+.1)/6.)
			var rescue_spec:=MissionHeroArt.body_spec(w)
			check(rescue_spec.action=="idle_fire" and int(rescue_spec.frame)==frame,"real rescue clock selects correct shared body phase: "+hero+"/"+str(frame))
		w.melee_time=0.;w.rescue_time=0.;w.move_axis=Vector2.DOWN
		for frame in 6:
			w.shot_flash=.18*(1.-(float(frame)+.1)/6.)
			var crouch_spec:=MissionHeroArt.body_spec(w)
			check(crouch_spec.action=="crouch_fire" and int(crouch_spec.frame)==frame,"stationary crouch fire uses shot phase rather than idle clock: "+hero+"/"+str(frame))
		for low_action in ["crouch_fire","crouch_walk","crouch_walk_back","crouch_grenade_throw","skill" if hero=="armadillo" else "skill_crouch"]:
			for frame in 6:
				var folded:=MissionHeroArt.metrics(hero,low_action,frame)
				check(float(folded.offset.y)+2.*float(folded.source_scale)>=-55.,"every low action cel physically fits the real pier clearance: "+hero+"/"+low_action+"/"+str(frame))
		w=clean(hero);w.pose_motion_enabled=false
		check(w.throw_grenade(),"new hero starts authored grenade throw: "+hero)
		advance(w,.17)
		var throw_pose:=MissionHeroArt.body_spec(w)
		check(throw_pose.action=="grenade_throw" and int(throw_pose.frame)==3,"reduced motion retains physical release cel: "+hero)
		check(not MissionHeroArt.metrics(hero,"grenade_throw",3).grenade_embedded,"empty authored hand requires one event-owned grenade: "+hero)
		check(w.grenades==4 and w.bombs.size()==1,"new hero consumes/releases one grenade: "+hero)
		w=clean(hero);w.load_section("fork_one");w.enemies.clear();w.player=Vector2(950.,90.);w.move_axis=Vector2.DOWN
		check(w.throw_grenade(),"low sidearm throw begins inside real pier crawlway: "+hero)
		for phase_time in [.01,.04,.10,.16,.25,.34]:
			while float(w.grenade_throw.get("elapsed",1.))<phase_time:w.step(.01)
			var low_spec:=MissionHeroArt.body_spec(w);var low_pose:=MissionHeroArt.metrics(hero,str(low_spec.action),int(low_spec.frame))
			check(low_spec.action=="crouch_grenade_throw","real crawlway uses authored low throw rather than standing cels: "+hero)
			check(w.player.y+low_pose.offset.y+2.*float(low_pose.source_scale)>=CampaignRoutes.CRAWL_CEILING,"whole low throw silhouette stays below actual55px pier ceiling: "+hero+"/"+str(low_spec.frame))
		w=clean(hero);w.load_section("fork_one");w.enemies.clear();w.player=Vector2(950.,90.);w.invulnerable=0.;w.move_axis=Vector2.ZERO
		w.damage_player()
		check(w.hp==2 and w.crouching(),"actual pier hit preserves real constrained physical posture: "+hero)
		for i in 5:
			var hurt_spec:=MissionHeroArt.body_spec(w);var hurt_pose:=MissionHeroArt.metrics(hero,str(hurt_spec.action),int(hurt_spec.frame))
			check(hurt_spec.action=="crouch_fire" and w.player.y+hurt_pose.offset.y+2.*float(hurt_pose.source_scale)>=CampaignRoutes.CRAWL_CEILING,"underpier damage uses safe existing low flinch/blink adaptation: "+hero+"/"+str(i))
			w.step(.05)
		w.hp=1;w.invulnerable=0.;w.damage_player()
		check(w.state=="dying","actual lethal hit enters death under pier: "+hero)
		var previous_death_frame: int=-1
		for i in 14:
			var death_spec:=MissionHeroArt.body_spec(w);var death_pose:=MissionHeroArt.metrics(hero,str(death_spec.action),int(death_spec.frame))
			check(death_spec.action=="death" and int(death_spec.frame)>=3 and int(death_spec.frame)>=previous_death_frame,"confined death advances through genuine collapsed own-source cels: "+hero+"/"+str(i))
			check(w.player.y+death_pose.offset.y+2.*float(death_pose.source_scale)>=CampaignRoutes.CRAWL_CEILING,"confined death never rises into real pier roof at fixed scale: "+hero+"/"+str(i))
			previous_death_frame=int(death_spec.frame);w.step(.05)

	var w:=clean("armadillo");w.move_axis=Vector2.DOWN
	advance(w,.10)
	check(w.hero_skill.is_empty(),"crouch alone never starts roll")
	w.attack_press();advance(w,.10);w.attack_release()
	check(w.hero_skill.is_empty() and w.shots>0,"crouch+Fire shoots and never rolls")
	w.move_axis=Vector2.ZERO
	check(not w.interact() and w.hero_skill.is_empty(),"standing skill does not unexpectedly launch roll")
	w.move_axis=Vector2.DOWN
	check(w.interact() and str(w.hero_skill.phase)=="windup","crouch+context skill begins visible shell windup")
	check(not w.interact(),"held/repeated skill cannot restart an active roll")
	var start:=w.player
	advance(w,.18)
	check(MissionHeroAbilities.rolling(w) and w.player.x>start.x,"roll follows world movement after windup")
	w.aim_direction=Vector2.LEFT
	check(MissionHeroAbilities.movement_speed(w,-100.)>0.,"roll launch direction remains locked when aim changes")
	advance(w,.38)
	check(str(w.hero_skill.phase)=="brake","active roll enters brake before recovery")
	advance(w,.15)
	check(str(w.hero_skill.phase)=="recover" and float(w.hero_skill.clock)<.05,"recovery starts after active and brake finish")
	advance(w,.16)
	check(str(w.hero_skill.phase)=="recover","real post-active recovery remains observable")
	advance(w,.70)
	check(w.hero_skill.is_empty(),"bounded skill cooldown returns to ready")

	w=clean("armadillo");w.move_axis=Vector2.DOWN
	var e:=target(w,245.)
	w.interact();advance(w,.65)
	check(int(e.hp)==7,"roll swept contact damages one target once per rush")
	check(w.invulnerable<=0.,"shell roll does not grant immunity")
	w=clean("armadillo");w.load_section("fork_one");w.enemies.clear();w.player=Vector2(850.,90.);w.move_axis=Vector2.DOWN
	w.interact();advance(w,.85);w.move_axis=Vector2.ZERO
	check(w.crouching() and is_equal_approx(w.player.y,90.),"roll recovery stays safely low under real crawlway ceiling")

	w=clean("frog");w.player=Vector2(140.,0.);w.aim_direction=Vector2.RIGHT
	var front:=target(w,280.);var behind:=target(w,330.)
	check(w.interact(),"frog tongue is available from start through existing context skill")
	advance(w,.13);w.aim_direction=Vector2.LEFT;w.move_axis=Vector2.LEFT
	var before:=MissionHeroAbilities.mouth(w);w.step(.01)
	check(MissionHeroAbilities.mouth(w).x<before.x,"tongue mouth follows moving body")
	check(Vector2(w.hero_skill.direction)==Vector2.RIGHT,"tongue aim stays locked throughout this attack")
	advance(w,.55)
	check(int(front.hp)==8 and int(behind.hp)==10,"tongue hits first enemy once, without piercing or retract damage")
	advance(w,.7)
	check(w.hero_skill.is_empty(),"tongue miss/contact/retract sequence returns to ready")

	w=clean("frog");var far:=target(w,600.)
	w.interact();advance(w,.25)
	check(float(w.hero_skill.get("extent",0.))<=MissionHeroAbilities.TONGUE_REACH,"tongue has finite reach")
	advance(w,.9);check(int(far.hp)==10,"out-of-range enemy never takes tongue damage")
	w=clean("frog");var blocked:=target(w,330.)
	w.objects.append({"id":"fixture:rock","kind":"rock","x":245.,"y":0.,"hp":9,"active":false,"secret":""})
	w.interact();advance(w,.6)
	check(int(blocked.hp)==10 and int(w.objects[0].hp)==7,"first obstacle consumes impact and shields enemy behind")
	w=clean("frog");w.load_section("fork_one");w.enemies.clear();w.player=Vector2(730.,0.)
	w.aim_direction=Vector2.RIGHT;w.interact();advance(w,.35)
	check(MissionHeroAbilities.tongue_tip(w).x<=CampaignRoutes.PIER.position.x+.01,"tongue cannot tunnel through route pier")
	w=clean("frog");w.interact();advance(w,.20)
	var phase: String=str(w.hero_skill.phase);var clock: float=float(w.hero_skill.clock);w.state="paused";w.step(.5)
	check(str(w.hero_skill.phase)==phase and float(w.hero_skill.clock)==clock,"pause freezes the same skill phase and clock")
	w.state="playing";w.invulnerable=0.;w.damage_player();w.step(.01)
	check(w.hero_skill.is_empty(),"damage clears active tongue safely")
	w.hurt_time=0.;w.interact();w.stop_inputs()
	check(not w.hero_skill.is_empty(),"input reset preserves skill so pause can resume exact choreography")
	w.load_section("quay")
	check(w.hero_skill.is_empty(),"section transition clears active skill hitbox")
	print("RESULT: ",checks," new hero checks, ",failures," failures")
	quit(1 if failures else 0)
