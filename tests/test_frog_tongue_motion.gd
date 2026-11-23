extends SceneTree
## Staged CampaignGame E/move handlers and real World ticks; not Mission1 arrival.
var checks:=0
var failures:=0
var game: AionCampaignGame

func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+message)

func key(code: int,pressed: bool) -> void:
	var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=pressed
	game._unhandled_input(event)

func stage(low: bool=false) -> void:
	var w=game.world;w.begin("frog");w.load_section("fork_one" if low else "shore");w.state="playing"
	w.enemies.clear();w.npcs.clear();w.objects.clear();w.hazards.clear();w.gates.clear();w.pickups.clear();w.crates.clear();w.platforms.clear();w.pits.clear()
	w.player=Vector2(980.,90.) if low else Vector2(1500.,0.);w.invulnerable=0.;w.pose_motion_enabled=true
	game.menu_kind="";game.fade=-1.;game.presentation_stage="";game.left_down=false;game.right_down=false;game.down_down=false;game.pad_axis=Vector2.ZERO;game.pad_look=Vector2.ZERO;game.mouse_aim=false

func _initialize() -> void:call_deferred("run")

func run() -> void:
	game=AionCampaignGame.new();root.add_child(game);await process_frame;game.set_process(false)
	for low in [false,true]:
		for face in [-1,1]:
			for backward in [false,true]:
				stage(low);var w=game.world;w.facing=face;w.aim_direction=Vector2(face,0.)
				var move: int=-face if backward else face
				if low:key(KEY_S,true)
				game.update_arcade_aim(0.);w.aim_direction=Vector2(face,0.)
				key(KEY_E,true);key(KEY_E,false)
				check(not w.hero_skill.is_empty(),"real E handler begins Frog tongue before movement")
				key(KEY_D if move>0 else KEY_A,true)
				var observed: Dictionary={};var phases: Dictionary={};var root_start: Vector2=w.player
				for tick in 66:
					game.update_arcade_aim(1./60.);w.step(1./60.)
					if not MissionHeroAbilities.active(w):continue
					var spec:=MissionHeroArt.body_spec(w);var phase: String=str(w.hero_skill.phase)
					phases[phase]=true
					var prefix: String="crouch_walk" if low else "walk"
					var gait: String=prefix+"_back" if backward else prefix
					var expected_action: String="tongue_"+gait if phase in ["extend","retract"] else gait
					check(str(spec.action)==expected_action,"skill retains correct forward/back stance gait in actual phase: "+phase+"/"+gait)
					check(int(spec.frame)==posmod(int(w.walk_distance/(110. if low else 174.)*6.),6),"tongue locomotion frame follows actual travel, not fixed jaw/skill clock")
					check(Vector2(w.hero_skill.direction)==Vector2(face,0.),"movement never changes this tongue launch direction")
					# World reports realised dx/dt from float32 positions. At x1500,
					# 60Hz rounding is .0025px/s; .01 still rejects any speed change.
					check(absf(absf(w.velocity.x)-235.*(.42 if low else 1.))<.01,"tongue art does not lock or slow ordinary movement")
					var pose:=MissionHeroArt.metrics("frog",str(spec.action),int(spec.frame))
					var expected_mouth: Vector2=w.player+Vector2(pose.face_local)*Vector2(spec.mirror,1.)
					check(MissionHeroAbilities.mouth(w).distance_to(expected_mouth)<.001,"rendered current gait mouth and tongue collision origin are identical")
					check(MissionHeroAbilities.mouth(w).distance_to(MissionHeroAbilities.tongue_tip(w))<=MissionHeroAbilities.TONGUE_REACH+.001,"moving-mouth tongue remains inside unchanged finite reach")
					if phase in ["extend","retract"]:observed[spec.frame]=true
					if low:check(w.player.y+Vector2(pose.offset).y+2.*float(pose.source_scale)>=CampaignRoutes.CRAWL_CEILING,"open-mouth moving body fits actual pier roof")
				check(observed.size()>=2,"real moving E attack changes feet instead of sliding one planted cel")
				check(phases.has("windup") and phases.has("extend") and phases.has("retract") and phases.has("recover"),"new art preserves full existing skill phase sequence")
				check(absf(w.player.x-root_start.x)>100.,"actual World movement continues through attack and recovery")
				key(KEY_D if move>0 else KEY_A,false);key(KEY_S,false)

	stage();var w=game.world;w.aim_direction=Vector2.RIGHT
	key(KEY_SPACE,true);w.step(1./60.);key(KEY_SPACE,false);key(KEY_E,true);key(KEY_E,false);key(KEY_D,true)
	var airborne:=false
	for tick in 32:
		game.update_arcade_aim(1./60.);w.step(1./60.)
		if not MissionHeroAbilities.active(w) or w.hero_skill.phase not in ["extend","retract"]:continue
		var spec:=MissionHeroArt.body_spec(w)
		check(not w.grounded() and spec.action=="tongue_air","real jump+E uses authored open-mouth flight anatomy")
		check(int(spec.frame)==RunnerWorld.flight_frame_for(w.velocity.y,w.air_time,6),"airborne tongue follows existing flight phase")
		airborne=true
	check(airborne,"real jump produces observable active airborne tongue phase")
	for pair in [["tongue_walk","tongue_walk_back"],["tongue_crouch_walk","tongue_crouch_walk_back"]]:
		var forward:=MissionHeroArt.metrics("frog",pair[0],0);var backward:=MissionHeroArt.metrics("frog",pair[1],0)
		check(forward.source_row!=backward.source_row,"open-mouth backward action has separately drawn source row")
		for action in pair:
			var hashes: Array=[]
			for frame in 6:
				var pose:=MissionHeroArt.pose("frog",action,frame)
				check(is_equal_approx(float(pose.source_scale),.5),"all tongue locomotion cels retain existing fixed Frog source scale")
				check(absf(pose.offset.y+pose.size.y-2.*float(pose.source_scale))<.001,"ground tongue gait feet stay at common physical floor")
				var hash: String=pose.texture.get_image().get_data().hex_encode().sha256_text()
				check(not hashes.has(hash),"each open-mouth gait cel has separately drawn leg motion")
				hashes.append(hash)
				if action.begins_with("tongue_crouch"):check(pose.offset.y+2.*float(pose.source_scale)>=-55.,"all six low tongue gait cels fit55px roof at fixed scale")
	game.queue_free();await process_frame
	print("RESULT: ",checks," Frog tongue locomotion checks, ",failures," failures")
	quit(1 if failures else 0)
