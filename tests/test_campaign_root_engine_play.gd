## Start in an arena fixture, then drive the real CampaignGame input paths.
## Ordinary complete route coverage remains in tests/browser_campaign.py.
extends SceneTree

var game: AionCampaignGame
var held := {}
var checks := 0
var failures := 0

func _initialize() -> void:call_deferred("run")

func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+message)

func key(code: Key,down: bool) -> void:
	if bool(held.get(code,false))==down:return
	held[code]=down
	var event:=InputEventKey.new()
	event.keycode=code;event.physical_keycode=code;event.pressed=down
	game._input(event)
	game._unhandled_input(event)

func point_at(target: Vector2) -> void:
	var event:=InputEventMouseMotion.new()
	event.position=game.view.get_global_transform_with_canvas()*game.view.at(target)
	game._input(event)

func run() -> void:
	root.size=Vector2i(1152,648)
	game=AionCampaignGame.new()
	root.add_child(game)
	await process_frame
	game.set_process(false);game.audio_enabled=false
	game.world.begin("aion");game.world.load_section("arena")
	game.world.player=Vector2(2140.,game.world.floor_at(2140.))
	game.world.move_axis=Vector2.ZERO
	game.menu_kind="";game.fade=-1.;game.boss_announced=false
	var phases:={}
	var last_jump:=0.
	var observed_shots:=false
	var observed_reveal:=false
	for frame in 12000:
		var world:=game.world
		if game.presentation_stage=="boss_reveal":observed_reveal=true
		if world.state=="playing" and bool(world.boss.engaged):
			phases[int(world.boss.phase)]=true
			var desired:=float(world.boss.x)-285.
			if float(world.boss.get("beam_warning",0.))>0. and absf(world.player.x-float(world.boss.beam_x))<74.:
				desired=float(world.boss.beam_x)-110.
			key(KEY_A,world.player.x>desired+25.)
			key(KEY_D,world.player.x<desired-25.)
			var target:=Vector2(float(world.boss.x),float(world.boss.y)-75.)
			for enemy in world.enemies:
				if not bool(enemy.defeated) and absf(world.player.x-float(enemy.x))<325.:
					target=Vector2(float(enemy.x),float(enemy.y)-34.);break
			point_at(target)
			key(KEY_F,true)
			observed_shots=observed_shots or world.shots>0
			var wave:=false
			var lane:=false
			for bullet in world.bullets:
				if bullet.owner!="enemy" or absf(world.player.x-float(bullet.p.x))>140.:continue
				if bullet.kind=="wave":wave=true
				elif absf(world.player_hit_center().y-float(bullet.p.y))<25.:lane=true
			key(KEY_S,lane and not wave)
			var dash: bool=float(world.boss.get("dash",0.))>0. and absf(world.player.x-float(world.boss.x))<215.
			if (wave or dash) and world.grounded() and world.time-last_jump>.65:
				key(KEY_SPACE,true);last_jump=world.time
			else:key(KEY_SPACE,false)
		else:
			for code in held.keys():key(code,false)
		game._process(1./120.)
		if game.menu_kind=="continue_offer":game.open_continue()
		if game.menu_kind=="continue_pick" and game.life_menu_delay<=0.:game.confirm_continue()
		if game.menu_kind in ["outro","complete","dead"]:break
		if frame%12==0:await process_frame
	check(observed_reveal,"Actual arena scene starts its world reveal")
	check(observed_shots and phases=={1:true,2:true,3:true},"Normal aiming and Fire cross all three phases with the starter pistol")
	check(game.world.completed and game.world.awarded.has("mission:1"),"The starter gun wins the local arena fixture through actual input")
	print("Arena input fixture: phases %s, boss HP %d, losses %d, shots %d"%[phases,int(game.world.boss.hp),game.world.losses,game.world.shots])
	game.queue_free();await process_frame
	print("RESULT: %d arena input checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
