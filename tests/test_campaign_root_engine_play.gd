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

func check_attack_timing() -> void:
	var world:=AionCampaignWorld.new()
	world.begin("aion");world.load_section("arena");world.boss.engaged=true
	check(CampaignBossPressure.core_exposed(world) and CampaignBossPressure.hud_cue(world)=="boss_core","The first recovery shows and teaches the real open core")
	world.boss.wait=.4
	check(not CampaignBossPressure.core_exposed(world) and CampaignBossPressure.vulnerable(world),"A closed first-phase core has no bonus, while body shots still count")
	world.damage_boss(92)
	check(world.boss.phase==2 and world.boss.ports==[0,0],"A burst cannot skip Phase 2 and the two attack sockets fail visibly")
	var plate_health:=int(world.boss.hp)
	world.damage_boss(8)
	check(int(world.boss.hp)==plate_health and world.boss.shield_side==-1. and "armour_hit" in world.pending_events,"A protected plate deflects the blast and flashes on the incoming side")
	world.boss.shift_pause=0.;world.boss.wait=1.3
	world.player=Vector2(2240.,world.floor_at(2240.));world.invulnerable=0.;world.shield_charge=0.
	CampaignBossPressure.arm_eruption(world)
	var marked_x:=float(world.boss.beam_x)
	CampaignBossPressure.step_eruption(world,CampaignBossPressure.ERUPTION_WARNING-.01)
	check(world.hp==1 and CampaignBossPressure.hud_cue(world)=="boss_beam_move","The marked ground cannot damage before the full warning")
	var saved:=AionCampaignWorld.new()
	check(saved.restore(world.snapshot()) and is_equal_approx(float(saved.boss.beam_x),marked_x) and float(saved.boss.beam_warning)>0.,"A persisted eruption warning keeps its locked target and remaining delay")
	world.player.x=marked_x-CampaignBossPressure.ERUPTION_RADIUS-1.
	world.player.y=world.floor_at(world.player.x)
	CampaignBossPressure.step_eruption(world,.02)
	check(world.hp==1 and "boss_eruption" in world.pending_events,"Leaving the locked floor area avoids the eruption even on the ground")
	world.player=Vector2(marked_x,world.floor_at(marked_x))
	CampaignBossPressure.step_eruption(world,.02)
	check(world.hp==0 and world.state=="dying","Entering the visible live eruption damages once")
	world.state="playing";world.hp=1;world.invulnerable=0.;world.pending_events.clear()
	CampaignBossPressure.step_eruption(world,.02)
	check(world.hp==1,"The same active eruption cannot take another layer of protection")
	world.damage_boss(91)
	world.boss.shift_pause=0.;world.boss.lane_direction=-1.
	CampaignBossPressure.fire_wave(world)
	CampaignBossPressure.step_echo(world,CampaignBossPressure.ECHO_DELAY-.01)
	check(world.bullets.size()==1 and world.bullets[0].get("echo")==false and "boss_wave" in world.pending_events and not "boss_wave_echo" in world.pending_events,"The first wave launches separately and the echo stays delayed")
	CampaignBossPressure.step_echo(world,.02)
	check(world.bullets.size()==2 and world.bullets[1].get("echo")==true and world.bullets[0].v.x==world.bullets[1].v.x and "boss_wave_echo" in world.pending_events,"The second travelling wave uses the committed lane and its own cue")
	world.boss.x=CampaignBossPressure.DASH_MIN_X
	world.player.x=float(world.boss.x)-60.
	world.boss.attack=2
	CampaignBossPressure.arm_warning(world)
	var direction:=CampaignBossPressure.lane_direction(world)
	check(direction==1. and CampaignBossPressure.sprite_facing(world)==-1 and CampaignBossPressure.dash_warning(world),"The arena edge forces a full escape lane and the sprite turns at the warning")
	world.player.x=float(world.boss.x)+140.
	world.player.y=world.floor_at(world.player.x)-150.
	world.boss.windup=.01
	world.step_boss(.02)
	for i in 20:world.step_boss(.05)
	check(world.hp==1 and float(world.boss.recover)>.95 and CampaignBossPressure.core_exposed(world) and "boss_core_open" in world.pending_events,"A high jump escapes the real directional charge and leaves an exposed recovery window")
	world.damage_boss(100)
	check(world.state=="victory" and float(world.boss.get("eruption",0.))==0. and float(world.boss.echo_wait)==0.,"Victory clears all active arena attacks")
	var relights:=0
	for i in 24:
		world.pending_events.clear()
		world.step(.05)
		if world.pending_events.has("boss_lantern"):relights+=1
	check(relights==3 and world.state=="complete","Three world lantern cues finish before results become eligible")

func check_cue_audio() -> void:
	game.audio_enabled=true
	var cues:=["boss_wave","boss_wave_echo","boss_eruption","boss_core_open","boss_lantern"]
	var clips: Array[AudioStreamWAV]=[]
	for cue in cues:
		game.sound(cue)
		var clip:=game.sound_cache.get(cue) as AudioStreamWAV
		if clip!=null and not clip.data.is_empty():clips.append(clip)
	check(clips.size()==cues.size() and clips[0].data!=clips[1].data,"World events load the five original clips and the echo has a distinct waveform")
	game.audio_enabled=false

func run() -> void:
	check_attack_timing()
	root.size=Vector2i(1152,648)
	game=AionCampaignGame.new()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	check_cue_audio()
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
	var observed_opening:=false
	var observed_eruption:=false
	var observed_echo:=false
	var observed_lanterns:=false
	var resupplies:=0
	var seeking_ammo:=false
	var previous_supply:=0.
	for frame in 30000:
		var world:=game.world
		if game.presentation_stage=="boss_reveal":observed_reveal=true
		if world.state=="victory" and world.victory_time>=.74:observed_lanterns=true
		if world.state=="playing" and bool(world.boss.engaged):
			phases[int(world.boss.phase)]=true
			observed_opening=observed_opening or (int(world.boss.phase)==1 and CampaignBossPressure.core_exposed(world))
			observed_eruption=observed_eruption or float(world.boss.get("eruption",0.))>0.
			observed_echo=observed_echo or world.bullets.any(func(b):return b.get("echo",false))
			observed_final_core=observed_final_core or (int(world.boss.phase)==3 and CampaignBossPressure.core_exposed(world))
			var supply:=float(world.boss.get("supply_cooldown",0.))
			if supply>previous_supply:
				resupplies+=1
				seeking_ammo=false
			previous_supply=supply
			if CampaignWeapons.sidearm_stock(world)<=3:seeking_ammo=true
			var desired:=float(world.boss.x)-285.
			if seeking_ammo:desired=CampaignBossPressure.SUPPLY_X
			if float(world.boss.get("beam_warning",0.))>0. or float(world.boss.get("eruption",0.))>0.:
				var mark:=float(world.boss.beam_x)
				if absf(world.player.x-mark)<CampaignBossPressure.ERUPTION_RADIUS+55.:
					desired=mark-CampaignBossPressure.ERUPTION_RADIUS-59.
			key(KEY_A,world.player.x>desired+25.)
			key(KEY_D,world.player.x<desired-25.)
			var target:=CampaignBossPressure.core_point(world)
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
	check(observed_opening and observed_eruption and observed_echo,"The live fight presents its opening core, marked ground eruption and separate echo")
	check(observed_final_core,"Normal movement and firing reach the exposed final core")
	check(resupplies>0 and game.world.weapons_used==["pistol"],"Normal movement collects a bounded arena refill and the fixture uses the starting pistol")
	check(game.world.completed and game.world.awarded.has("mission:1"),"The starter gun wins the local arena fixture through actual input")
	check(observed_lanterns,"World lanterns ignite before the normal results UI")
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
