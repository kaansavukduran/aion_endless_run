extends SceneTree

var checks := 0
var failures := 0
var art := ForgeHeroArt.new()
class MouthHost:
	extends RefCounted
	var motion_enabled:=true
	var options:=RunnerInterfaceOptions.new()

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+label)
func fresh(hero: String) -> AionCampaignWorld:
	var w:=AionCampaignWorld.new();w.begin(hero);w.state="playing"
	w.enemies.clear();w.npcs.clear();w.gates.clear();w.objects.clear();w.platforms.clear();w.pits.clear()
	return w
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var directions: Array[Vector2]=[Vector2.RIGHT,Vector2(1,-1).normalized(),Vector2.UP,Vector2(-1,-1).normalized(),Vector2.LEFT,Vector2(-1,1).normalized(),Vector2.DOWN,Vector2(1,1).normalized()]
	for hero in AionCampaignWorld.HEROES:
		for direction in directions:
			for moving in [-1,0,1]:
				for airborne in [false,true]:
					var w:=fresh(hero);w.aim_direction=direction;w.facing=1 if moving>=0 else -1;w.velocity.x=moving*235.;w.walk_distance=75.;w.time=.43
					if airborne:w.player.y=-125.;w.jumps=1
					w.attack_press()
					check(w.bullets.size()==1,"Six heroes × eight directions emit one actual pistol shot")
					var spec:=w.armed_art_spec()
					if not spec.is_empty():
						var pose:=art.pose(str(spec.key),int(spec.row),int(spec.frame))
						var expected: Vector2=Vector2(pose.muzzle_local)*Vector2(float(spec.mirror),1.)
						check(w.armed_muzzle().distance_to(expected)<.001,"Projectile muzzle matches actual rendered pose/flip: "+hero)
						if spec.key in ["eightway","mouth-aim"]:check(spec.mirror==1,"Absolute left/up/down poses are not mirrored twice")
					var projectile: Dictionary=w.bullets[0]
					check(Vector2(projectile.p).distance_to(w.player+w.armed_muzzle())<.001,"Actual bullet starts at the drawn barrel: "+hero)
					check(Vector2(projectile.v).normalized().distance_to(direction)<.001,"Moving opposite independent aim never reverses the projectile")
					if moving!=0 and direction.x*float(moving)<0.:
						check(not spec.is_empty(),"Independent opposite horizontal/diagonal aiming has a real facing pose")
	# Step every source frame to catch a barrel drifting away from its attachment.
	for hero in ["owl","wolf"]:
		for row_phase in 2:
			for frame in 6:
				for mirror in [-1,1]:
					var w:=fresh(hero);w.aim_direction=Vector2(mirror,0.);w.facing=-mirror
					if hero=="owl":w.player.y=-100.;w.time=(frame+.1)/6.;w.flap_time=.3*(1.-(frame+.1)/6.) if row_phase==1 else 0.
					else:w.velocity.x=235.;w.walk_distance=180.*(frame+.1)/6.;w.shot_flash=.18*(1.-(frame+.1)/6.) if row_phase==1 else 0.
					var spec:=w.armed_art_spec();check(spec.key=="mouth-carry" and int(spec.frame)==frame,"Mouth carry selects the actual authored frame")
					var pose:=art.pose(str(spec.key),int(spec.row),int(spec.frame))
					check(w.armed_muzzle().distance_to(Vector2(pose.muzzle_local)*Vector2(mirror,1))<.001,"Every mouth cycle/frame keeps rendering and physics aligned")
	for hero in ["owl","wolf"]:
		var runner:=RunnerWorld.new();runner.reset();runner.character=hero;runner.state="running";runner.time=.4;runner.distance=90.
		if hero=="owl":runner.y=-100.;runner.owl_flap_time=.17
		for firing in [false,true]:
			runner.frontier.shot_flash=.15 if firing else 0.
			var row: int=(1 if runner.owl_flap_time>0. else 0) if hero=="owl" else (3 if firing else 2)
			var frame: int=clampi(int((1.-runner.owl_flap_time/runner.OWL_FLAP_DURATION)*6.),0,5) if hero=="owl" else (runner.frontier.gun_frame(6) if firing else posmod(int(runner.travel_distance()/174.*6.),6))
			var pose:=art.pose("mouth-carry",row,frame)
			check(runner.frontier.weapon_muzzle(runner).distance_to(pose.muzzle_local)<.001,"Endless mouth gun uses the same authored barrel frame")
	check_motion_contract()
	print("RESULT: %d actual pose/muzzle checks, %d failures" % [checks,failures]);quit(1 if failures else 0)

func check_motion_contract() -> void:
	var view:=AionCampaignView.new()
	var host:=MouthHost.new();view.host=host
	var bank:=RunnerFrameBank.new()
	for hero in ["owl","wolf"]:
		for clip in 2:
			for source_frame in 6:
				for motion_options in [[true,false],[false,false],[true,true]]:
					var w:=fresh(hero);w.aim_direction=Vector2.RIGHT;w.velocity.x=235.;w.time=(source_frame+.1)/6.;w.walk_distance=180.*(source_frame+.1)/6.
					if hero=="owl":w.player.y=-100.;w.flap_time=.3*(1.-(source_frame+.1)/6.) if clip==1 else 0.
					else:w.shot_flash=.18*(1.-(source_frame+.1)/6.) if clip==1 else 0.
					host.motion_enabled=motion_options[0];host.options.reduced_motion=motion_options[1]
					w.pose_motion_enabled=host.motion_enabled and not host.options.reduced_motion
					view.world=w
					var rendered: Dictionary=view.hero_pose(hero,true,hero=="owl",w.walk_distance)
					var target_frame: int=source_frame if w.pose_motion_enabled else 0
					check(int(rendered.source_frame)==target_frame,"Actual Arcade renderer uses requested animated/static mouth frame")
					check(int(w.armed_art_spec().frame)==target_frame,"Shared Arcade selection holds the identical frame when animation is off")
					check(w.armed_muzzle().distance_to(rendered.muzzle_local)<.001,"Arcade static/reduced-motion muzzle matches actual drawn pose")
					check(not w.snapshot().has("pose_motion_enabled"),"Pose preference is ephemeral and cannot overwrite checkpoint data")
				for enabled in [true,false]:
					var runner:=RunnerWorld.new();runner.reset();runner.character=hero;runner.state="running";runner.pose_motion_enabled=enabled
					runner.time=(source_frame+.1)/6.;runner.distance=174.*(source_frame+.1)/6.
					if hero=="owl":runner.y=-100.;runner.owl_flap_time=.3*(1.-(source_frame+.1)/6.) if clip==1 else 0.
					else:runner.frontier.shot_flash=runner.frontier.SHOT_DURATION*(1.-(source_frame+.1)/6.) if clip==1 else 0.
					var target_frame: int=source_frame if enabled else 0
					var key: String=("owl-flap" if clip==1 else "runner-owl") if hero=="owl" else ("gun-fire" if clip==1 else "gun-run")
					var row: int=(0 if clip==1 else 6) if hero=="owl" else bank.hero_row("wolf")
					var rendered: Dictionary=bank.pose(key,row,target_frame)
					check(int(rendered.source_frame)==target_frame,"Actual Endless frame bank resolves static and normal mouth pose")
					check(runner.frontier.weapon_muzzle(runner).distance_to(rendered.muzzle_local)<.001,"Endless static/normal muzzle matches actual displayed source frame: %s clip%d frame%d enabled%s actual%s expected%s" % [hero,clip,source_frame,str(enabled),str(runner.frontier.weapon_muzzle(runner)),str(rendered.muzzle_local)])
	view.free()
