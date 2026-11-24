extends SceneTree

var checks := 0
var failures := 0
var bodies := M1HeroArt.new()
var items := ForgeItemBank.new()
class RenderHost:
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

# Reconstruct the muzzle from the actual isolated texture, its pixel socket,
# and the renderer's affine transform. This does not call armed_muzzle().
func drawn_barrel(w: AionCampaignWorld) -> Vector2:
	var p:=M1CombatArt.placement(w)
	var texture: Texture2D=M1CombatArt.weapon_texture(items,str(p.weapon.kind))
	var pixel: Vector2=p.weapon.muzzle_pixel
	assert(pixel.x>=0. and pixel.x<texture.get_width() and pixel.y>=0. and pixel.y<texture.get_height())
	var local: Vector2=Vector2(p.weapon.offset)+pixel*float(p.weapon.factor)
	return Vector2(p.grip)+(local*Vector2(1.,float(p.mirror_y))).rotated(float(p.angle))

func run() -> void:
	check(AionCampaignWorld.HEROES==["aion","sheep","rabbit","eren","armadillo","frog"],"Six current playable bodies preserve the original four identities and order")
	var directions: Array[Vector2]=[Vector2.RIGHT,Vector2(1,-1).normalized(),Vector2.UP,Vector2(-1,-1).normalized(),Vector2.LEFT,Vector2(-1,1).normalized(),Vector2.DOWN,Vector2(1,1).normalized()]
	for hero in AionCampaignWorld.HEROES:
		for direction in directions:
			for moving in [-1,0,1]:
				for stance in ["ground","air","crouch"]:
					var w:=fresh(hero);w.aim_direction=direction;w.facing=1 if moving>=0 else -1;w.velocity.x=moving*235.;w.walk_distance=75.;w.time=.43
					if stance=="air":w.player.y=-125.;w.jumps=1
					if stance=="crouch":w.move_axis=Vector2(moving,1.)
					w.attack_press()
					check(w.bullets.size()==1,"Current hero fires once while idle/walking/airborne/crouching: "+hero+"/"+stance)
					var spec:=w.armed_art_spec()
					var pose: Dictionary=bodies.pose(hero,str(spec.action),int(spec.frame))
					var expected_key: String="mission-hero" if hero in MissionHeroArt.HEROES else "m1-body"
					check(spec.key==expected_key and pose.body_only and not pose.gun_embedded,"Correct authoritative hero provider keeps body distinct from weapon: "+hero)
					check(w.armed_muzzle().distance_to(drawn_barrel(w))<.001,"Actual isolated weapon barrel equals physics muzzle: "+hero+"/"+stance)
					check(Vector2(w.bullets[0].p).distance_to(w.player+drawn_barrel(w))<.001,"Actual bullet starts at rendered barrel after mirror/rotation/floor clearance")
					var attachment:=M1CombatArt.placement(w)
					check(Vector2(attachment.grip).distance_to(Vector2(pose.grip_local)*Vector2(int(spec.mirror),1.))<.001,"Gun handle remains at the actual measured hand even during low downward aim")
					var emitted: Vector2=Vector2(w.bullets[0].v).normalized()
					if emitted.distance_to(direction)<.001:
						check(true,"Independent eight-direction aim survives movement opposite the shot")
					else:
						check(w.grounded() and direction.y>0. and emitted.distance_to(Vector2(int(spec.mirror),0.))<.001 and (w.player+drawn_barrel(w)).y<w.floor_at((w.player+drawn_barrel(w)).x),"Only a grounded shot into supporting floor becomes horizontal; hand and actual barrel stay above support")
					if stance=="crouch":check(str(spec.action).begins_with("crouch_"),"Down input selects genuinely lower body art while firing")
					if moving!=0 and direction.x*float(moving)<0.:
						check(int(spec.mirror)==(-1 if direction.x<0. else 1),"Aiming backward faces the gun and body toward the actual shot")
	for kind in M1CombatArt.SOCKETS:
		var texture: Texture2D=M1CombatArt.weapon_texture(items,kind)
		var pixels: Image=texture.get_image()
		var metrics: Dictionary=M1CombatArt.weapon_metrics(kind)
		var point:=Vector2i(metrics.muzzle_pixel)
		check(point.x>=0 and point.y>=0 and point.x<pixels.get_width() and point.y<pixels.get_height(),"Actual weapon muzzle pixel is within isolated texture: "+kind)
		check(pixels.get_pixelv(point).a>.5,"Registered barrel is an opaque canonical held-source pixel, not transparent background: "+kind)
		check(pixels.get_pixelv(Vector2i(metrics.grip_pixel)).a>.5,"Registered grip is on the actual held weapon instead of empty canvas: "+kind)
		check(Vector2(metrics.size).is_equal_approx(Vector2(texture.get_size())*float(metrics.factor)),"Actual held canvas agrees with drawing size, including trap launcher substitution: "+kind)
	check_last_special_shot()
	check_motion_contract()
	print("RESULT: %d actual pose/muzzle checks, %d failures" % [checks,failures]);quit(1 if failures else 0)

func check_motion_contract() -> void:
	var view:=AionCampaignView.new();var host:=RenderHost.new();view.host=host
	for hero in AionCampaignWorld.HEROES:
		for clip in ["walk","idle_fire","air_fire","crouch_walk","crouch_fire"]:
			for frame in 6:
				for enabled in [true,false]:
					var w:=fresh(hero);w.aim_direction=Vector2.RIGHT;w.pose_motion_enabled=enabled;w.walk_distance=174.*(frame+.1)/6.
					if clip=="walk":w.velocity.x=235.
					if clip=="air_fire":
						w.player.y=-100.;w.air_time=.15
						if hero=="armadillo":w.velocity.y=lerpf(-650.,650.,float(frame)/5.)
					if clip.begins_with("crouch_"):
						w.move_axis.y=1.
						if clip=="crouch_walk":w.velocity.x=100.;w.walk_distance=110.*(frame+.1)/6.
					if clip.ends_with("fire"):w.shot_flash=.18*(1.-(frame+.1)/6.)
					view.world=w
					var pose: Dictionary=view.hero_pose(hero,true,clip=="air_fire",w.walk_distance)
					var source_prefix: String="mission-hero-" if hero in MissionHeroArt.HEROES else "m1-body-"
					check(str(pose.source_key).begins_with(source_prefix),"Actual renderer consumes this hero's current body provider instead of archived gun sheets: "+hero)
					var expected_frame:=frame if enabled else 0
					if enabled and hero=="armadillo" and clip=="air_fire":expected_frame=RunnerWorld.flight_frame_for(w.velocity.y,w.air_time,6)
					var expected: Dictionary=M1HeroArt.metrics(hero,clip,expected_frame)
					check(pose.source_key==expected.source_key and int(pose.source_row)==int(expected.source_row) and int(pose.source_frame)==int(expected.source_frame),"Actual renderer honors the same animated/static authored source, including explicit held cels: "+hero+"/"+clip)
					check(w.armed_muzzle().distance_to(drawn_barrel(w))<.001,"Animation preference keeps physical and rendered weapon aligned")
					check(not w.snapshot().has("pose_motion_enabled"),"Pose preference stays ephemeral and cannot overwrite checkpoint data")
	# Historical mouth-carry sheets are archived assets, not playable owl/wolf
	# states. Retain their independent isolation/registration coverage directly.
	var archive:=ForgeHeroArt.new()
	for row in 4:
		for frame in 6:
			var old: Dictionary=archive.pose("mouth-carry",row,frame)
			check(old.texture.get_width()>10 and Vector2(old.muzzle_local).x>0.,"Archived mouth-carry source remains available without reintroducing removed heroes")
	view.free()


func check_last_special_shot() -> void:
	for kind in CampaignWeapons.SPECIAL:
		for stance in ["idle","walk","air","crouch"]:
			var w:=fresh("aion");w.weapon=kind;w.ammunition=1
			if stance=="walk":w.move_axis.x=1.;w.velocity.x=235.;w.walk_distance=75.
			if stance=="air":w.player.y=-125.;w.jumps=1;w.aim_direction=Vector2(1.,-1.).normalized()
			if stance=="crouch":w.move_axis=Vector2(1.,1.);w.velocity.x=90.;w.walk_distance=45.
			w.attack_press();w.attack_release()
			check(w.shots==1 and w.weapon=="pistol" and w.ammunition==0,"Final special ammunition is consumed once and logical inventory falls back: "+kind+"/"+stance)
			var pose:=M1CombatArt.placement(w)
			check(str(pose.weapon.kind)==kind,"First visible flash keeps the actual last-fired weapon: "+kind+"/"+stance)
			check(not w.bullets.is_empty() and Vector2(w.bullets[0].p).distance_to(w.player+drawn_barrel(w))<.001,"Last-ammunition projectile matches the actually displayed special barrel")
			for i in 2:w.step(.01)
			check(w.shot_flash>0. and str(M1CombatArt.placement(w).weapon.kind)==kind,"Actual early simulation frames retain the special gun through its flash")
			for i in 20:w.step(.01)
			check(w.shot_flash==0. and str(M1CombatArt.placement(w).weapon.kind)=="pistol","Real flash expiry returns the visible weapon to the logical fallback")
			check(not w.snapshot().has("shot_weapon"),"Last-shot presentation latch cannot become stale checkpoint inventory")
			for i in 80:w.step(.01)
			var shots: int=w.shots;w.attack_press();w.attack_release()
			check(w.shots==shots+1 and str(M1CombatArt.placement(w).weapon.kind)=="pistol","Next ordinary fire actually emits and displays the fallback pistol")

	var restarted:=fresh("aion");restarted.weapon="beam";restarted.ammunition=1
	restarted.attack_press();restarted.begin("sheep");restarted.state="playing"
	check(restarted.shot_flash==0. and str(M1CombatArt.placement(restarted).weapon.kind)=="pistol","A real new run clears the previous actor's last-shot presentation")
