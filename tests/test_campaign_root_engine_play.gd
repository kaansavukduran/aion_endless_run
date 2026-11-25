## Start in an arena fixture, then drive the real CampaignGame input paths.
## Ordinary complete route coverage remains in tests/browser_campaign.py.
extends SceneTree

var game: AionCampaignGame
var held := {}
var pointer := Vector2.ZERO
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
	event.position=game.view.get_global_transform_with_canvas()*game.view.at(target-Vector2(0.,game.view.camera_y))
	event.relative=event.position-pointer
	pointer=event.position
	game._input(event)

func run() -> void:
	root.size=Vector2i(1152,648)
	game=AionCampaignGame.new()
	root.add_child(game)
	await process_frame
	game.set_process(false);game.audio_enabled=false
	var hero:=OS.get_environment("AION_ARENA_HERO")
	if hero.is_empty():hero="aion"
	if hero not in AionCampaignWorld.HEROES:
		printerr("Unknown arena fixture hero: "+hero);quit(1);return
	game.selected_hero=hero;game.world.begin(hero)
	# Model an arena replay after its optional rescues were claimed. The boss,
	# hazards and starting pistol remain live, with no special gifts to equip.
	for i in int(CampaignRescue.COUNTS.arena):
		var id:="arena:keeper"+("" if i==0 else ":"+str(i))
		game.world.rescued.append(id)
		game.world.awarded[id+":gift"]=true
	game.world.load_section("arena")
	game.world.player=Vector2(2140.,game.world.floor_at(2140.))
	game.world.move_axis=Vector2.ZERO
	game.menu_kind="";game.fade=-1.;game.boss_announced=false
	var phases:={}
	var last_jump:=0.
	var observed_shots:=false
	var observed_reveal:=false
	var observed_final_core:=false
	var resupplies:=0
	var seeking_ammo:=false
	var previous_supply:=0.
	for frame in 30000:
		var world:=game.world
		if game.presentation_stage=="boss_reveal":observed_reveal=true
		if world.state=="playing" and bool(world.boss.engaged):
			phases[int(world.boss.phase)]=true
			observed_final_core=observed_final_core or (int(world.boss.phase)==3 and CampaignBossPressure.core_exposed(world))
			var supply:=float(world.boss.get("supply_cooldown",0.))
			if supply>previous_supply:
				resupplies+=1
				seeking_ammo=false
			previous_supply=supply
			if CampaignWeapons.sidearm_stock(world)<=3:seeking_ammo=true
			var desired:=float(world.boss.x)-285.
			if seeking_ammo:desired=CampaignBossPressure.SUPPLY_X
			if float(world.boss.get("beam_warning",0.))>0. and absf(world.player.x-float(world.boss.beam_x))<74.:
				desired=float(world.boss.beam_x)-110.
			key(KEY_A,world.player.x>desired+25.)
			key(KEY_D,world.player.x<desired-25.)
			var target:=Vector2(float(world.boss.x),float(world.boss.y)-75.)
			var close_drone:=false
			for enemy in world.enemies:
				if not bool(enemy.defeated) and absf(world.player.x-float(enemy.x))<325.:
					target=Vector2(float(enemy.x),float(enemy.y)-34.);close_drone=true;break
			point_at(target)
			key(KEY_F,not seeking_ammo and (world.boss_vulnerable() or close_drone))
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
		if game.menu_kind=="continue_offer":
			var confirm:=InputEventJoypadButton.new()
			confirm.button_index=JOY_BUTTON_START
			confirm.pressed=true
			game._input(confirm)
			confirm.pressed=false
			game._input(confirm)
		if game.menu_kind in ["outro","complete","dead"]:break
		if frame%12==0:await process_frame
	check(observed_reveal,"Actual arena scene starts its world reveal")
	check(observed_shots and phases=={1:true,2:true,3:true},"Normal aiming and Fire cross all three phases with the starter pistol")
	check(observed_final_core,"Normal movement and firing reach the exposed final core")
	check(resupplies>0 and game.world.weapons_used==["pistol"],"Normal movement collects a bounded arena refill and the fixture uses the starting pistol")
	check(game.world.completed and game.world.awarded.has("mission:1"),"The starter gun wins the local arena fixture through actual input")
	print("Arena input fixture: %s, phases %s, boss HP %d, losses %d, shots %d, resupplies %d"%[hero,phases,int(game.world.boss.hp),game.world.losses,game.world.shots,resupplies])
	var final_score:=game.world.score
	for page in 8:
		if game.menu_kind!="outro":break
		game.buttons.front().pressed.emit()
		await process_frame
	var replay:=game.ui.find_child("CampaignReplay",true,false) as Button
	check(game.menu_kind=="complete" and replay!=null and replay.is_visible_in_tree(),"The actual result offers a visible replay action")
	if replay!=null:
		replay.pressed.emit()
		await process_frame
		check(game.world.section=="shore" and game.world.character==hero and game.world.attempts_remaining==3 and game.world.score==0,"Playing again starts a fresh Mission 1 with the selected hero and all lives")
		check(int(game.saved.get("best_score",-1))>=final_score,"Replay preserves the finished run record")
	game.queue_free();await process_frame
	print("RESULT: %d arena input checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
