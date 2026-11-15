## Actual main.tscn selector fixtures; authored state/timing, not browser inputs.
extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+message)
func pixels_match(sprite: Sprite2D,pose: Dictionary) -> bool:
	return sprite.texture.get_image().get_data()==pose.texture.get_image().get_data()
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var game=load("res://main.tscn").instantiate();root.add_child(game);await process_frame
	game.set_physics_process(false);game.touch_tutorial_done=true;game.interface_options.reduced_motion=false
	var body:=M1HeroArt.new();var damage:=M1DamageArt.new()
	for hero in game.FRIENDS:
		for animated in [true,false]:
			game.main_menu();game.select_character(hero);game.start_run();game.motion=animated
			game.world.sheep_count=3;game.world.frontier.request_boss(5);game.world.step(.01)
			check(game.world.frontier.storytelling(),"A real boss request enters the actual scene cinematic: "+hero)
			for beat in 3:
				var first_probe_x:=INF
				for seconds in [0.,.6,1.8,2.4]:
					game.world.frontier.story_time=seconds;game.update_friend()
					var item: Sprite2D=game.friend_sprite
					var expected: Dictionary
					if hero=="rabbit":
						expected=damage.pose(hero,"freeze",0) if beat==1 else body.pose(hero,"idle_fire",0)
						check(item.get_meta("source_key")==expected.source_key and pixels_match(item,expected),"Ayça keeps her own bow/skirt alert or idle instead of the old male rabbit: "+str(beat))
						check(is_equal_approx(item.scale.x,float(expected.source_scale)*game.visual_size),"Ayça cinematic uses her one registered source scale")
					else:
						var frame: int=maxi(1,game.frames.progress("boss-story-reactions",game.COMBAT_ROWS[hero],seconds/2.4)) if beat==1 and animated else (4 if beat==1 else 1)
						expected=game.frames.pose("boss-story-reactions",game.COMBAT_ROWS[hero],frame)
						check(item.get_meta("source_key")=="boss-story-reactions" and pixels_match(item,expected),"The actual scene retains the authored story reaction, not a walk/fire overwrite: "+hero+"/"+str(beat))
						check(is_equal_approx(item.scale.x,float(expected.scale)*game.visual_size),"Original cinematic body scale stays fixed across its authored cels: "+hero)
					var probe: Vector2=item.get_meta("head_probe_world")
					if is_inf(first_probe_x):first_probe_x=probe.x
					check(absf(probe.x-first_probe_x)<.001,"Cinematic face has no unintended horizontal frame drift: "+hero)
					check(absf(float(item.get_meta("foot_world").y)-game.ground)<=.501 and absf(item.position.x-game.world.PLAYER_X)<.501,"Cinematic actor and connected feet remain on the fixed road origin: "+hero)
					if beat==2:
						var gift: Dictionary=game.frames.pose("boss-story-reactions",6,0)
						check(game.gun_echo.visible and game.gun_echo.get_meta("source_key")=="boss-story-reactions" and int(game.gun_echo.get_meta("source_row"))==6 and pixels_match(game.gun_echo,gift),"The existing red-gun handoff remains visibly drawn at its own cinematic beat: "+hero)
						var offer: float=smoothstep(0.,1.2,seconds) if game.decorative_motion() else 1.
						check(game.gun_echo.position.distance_to(Vector2(game.world.PLAYER_X+74.-offer*35.,game.ground-30.).round())<.001,"Visible offered gun keeps its actual authored handoff position")
					else:check(not game.gun_echo.visible,"Normal pistol stays hidden before the cinematic gift beat")
					if hero=="sheep":check_followers(game)
				game.world.frontier.next_story(game.world)
			check(game.world.frontier.phase=="intro" and game.world.frontier.red_weapon,"Completing the visible gift still reaches the same real armed boss entrance")
			# Enter an actual tenth-level hug through the model's level transition.
			game.main_menu();game.select_character(hero);game.start_run();game.motion=animated;game.world.sheep_count=3
			game.world.adventure.level=9;game.world.adventure.level_elapsed=15.;game.world.adventure.celebrations_enabled=true;game.world.adventure.update_level(game.world)
			check(game.world.adventure.hugging(),"Tenth-level transition starts the real hug: "+hero)
			for seconds in [0.,.3,.6]:
				game.world.time=seconds;game.update_friend()
				# The preserved legacy motion-off selector intentionally freezes at
				# neutral idle0; animated hugs retain their authored happy idle4.
				var expected: Dictionary=body.pose(hero,"idle_fire",0) if hero=="rabbit" else game.frames.pose("runner-"+hero,0,4 if animated else 0)
				check(pixels_match(game.friend_sprite,expected),"Actual hug selects its stationary identity-faithful idle instead of M1 walk: "+hero)
				check(not game.gun_echo.visible,"Hug does not draw an unsolicited ordinary pistol")
				check(absf(float(game.friend_sprite.get_meta("foot_world").y)-game.ground)<=.501,"Hug feet stay on the real floor")
				if hero=="sheep":check_followers(game)
	game.queue_free();await process_frame
	print("RESULT: %d cinematic hero scene checks, %d failures"%[checks,failures]);quit(1 if failures else 0)

func check_followers(game) -> void:
	for follower in game.followers:
		check(follower.visible and follower.get_meta("source_key")=="m1-body-sheep" and follower.get_meta("pose_action")=="idle_fire" and int(follower.get_meta("source_frame"))==0,"Both sheep followers retain current bipedal standing idle during cinematics")
		var neutral: Dictionary=M1HeroArt.metrics("sheep","idle_fire",0)
		check(is_equal_approx(follower.scale.x,float(neutral.source_scale)*game.FOLLOWER_RATIO) and absf(float(follower.get_meta("foot_world").y)-game.ground)<=.501,"Cinematic sheep followers keep their .72 size and grounded contact")
