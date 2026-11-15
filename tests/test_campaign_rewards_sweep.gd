extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;printerr('FAIL: '+message)
func fresh() -> AionCampaignWorld:
 var w:=AionCampaignWorld.new();w.begin('aion');w.state='playing';w.player=Vector2(400,0);w.enemies.clear();w.npcs.clear();w.objects.clear();w.gates.clear();w.crates.clear();w.pickups.clear();w.platforms.clear();w.pits.clear();w.hazards.clear();w.zones.clear();w.encounters.clear();return w
func _initialize():call_deferred('run')
func run():
 for type in CampaignVehicles.TYPES:
  var w:=fresh();w.mount={'available':true,'ridden':true,'type':type,'x':400.,'hp':2};w.player.y=-42.
  var n: Dictionary={'id':'gift-'+type,'x':495.,'home_x':495.,'y':0.,'freed':true,'phase':'free','free_age':.3,'thank_age':0.,'variant':7,'roam_clock':0.,'facing':-1,'gift':'heavy','role':'technician','secret':''}
  w.npcs=[n];CampaignRescue.step(w,.01)
  check(n.phase=='thanks' and w.greeted.has(n.id),'Actual mounted hull contact starts same thank-you clip '+type)
  check(not w.awarded.has(str(n.id)+':gift'),'Contact does not remotely award item')
  w.player.x=150.;CampaignRescue.step(w,1.)
  check(w.pickups.size()==1 and w.gift_drops.has(n.id),'Bag produces real item while hero stays mounted')
  for i in 40:w.step(1./120.)
  check(not w.awarded.has(str(n.id)+':gift'),'Distant vehicle does not collect dropped item')
  w.player=Vector2(float(w.pickups[0].x),-42.);w.step(.01)
  check(w.awarded.has(str(n.id)+':gift') and w.weapon=='heavy','Vehicle overlap collects actual power-up '+type)
  check(w.mount.hp==3,'Technician gift repairs mounted vehicle normally')
  var grenades: int=w.grenades;w.step(.01);check(w.grenades==grenades,'Reward cannot repeat while vehicle overlaps')
  w.player=Vector2(495.,-260.);check(not w.touches_npc(n),'High airborne vehicle cannot greet ground NPC')
 var w:=fresh();var near: Dictionary={'x':470.,'y':0.};check(not w.touches_npc(near),'On-foot contact retains original reach')
 for hero in AionCampaignWorld.HEROES:
  w=fresh();w.character=hero;w.move_axis=Vector2.RIGHT;w.step(.01);var speed: float=w.velocity.x;w.boost_held=true;w.step(.01)
  check(is_equal_approx(w.velocity.x,speed*1.55),'Every playable character sprints '+hero)
 for mirrored in [false,true]:
  w=fresh();w.player.y=-240.;w.weapon='pistol';w.fire_held=true;w.fire_time=.30;w.aim_direction=Vector2(-1 if mirrored else 1,-1).normalized()
  var target:=Vector2(-1 if mirrored else 1,1).normalized();var between:=false;var shots:=0
  for i in 24:
   w.steer_aim(target,1./120.);w.step(1./120.)
   if w.shots>shots:
    for bullet in w.bullets:
     var a: float=absf(w.aim_direction.angle())
     if absf(w.aim_direction.y)>.05 and absf(absf(w.aim_direction.y)-absf(w.aim_direction.x))>.05:between=true
     check(Vector2(bullet.aim).distance_to(Vector2(bullet.v).normalized())<.001,'Actual projectile follows current swept gun angle')
    shots=w.shots
  check(between,'Held pistol emits a real intermediate-angle shot on either facing')
  check(w.aim_direction.distance_to(target)<.001,'Sweep reaches the requested exact eight-way target')
  check(w.shots<=3,'Turn window is bounded; no unbounded extra firing')
 var game:=AionCampaignGame.new();root.add_child(game);await process_frame;game.set_process(false);game.menu_kind='';game.world=fresh()
 var ev:=InputEventMouseButton.new();ev.button_index=MOUSE_BUTTON_RIGHT;ev.pressed=true;game._input(ev)
 check(game.world.bombs.size()==1,'Actual right mouse event throws grenade')
 game._input(ev);check(game.world.bombs.size()==1,'Repeated held right click cannot throw a second grenade')
 ev.pressed=false;game._input(ev);game.world.grenade_time=0.;ev.pressed=true;game._input(ev);check(game.world.bombs.size()==2,'Right click works again after release and cooldown')
 var shift:=InputEventKey.new();shift.physical_keycode=KEY_SHIFT;shift.pressed=true;game._unhandled_input(shift)
 check(game.world.boost_held,'Actual Shift key event starts sprint')
 shift.pressed=false;game._unhandled_input(shift);check(not game.world.boost_held,'Shift release clears sprint')
 ev.pressed=false;game._input(ev) # Release the real mouse source before a distinct controller press.
 game.world.grenade_time=0.;var pad:=InputEventJoypadButton.new();pad.button_index=JOY_BUTTON_B;pad.pressed=true;game._input(pad)
 check(game.world.bombs.size()==3,'Actual Xbox B mapped action throws grenade')
 pad.pressed=false;game._input(pad);pad.button_index=JOY_BUTTON_LEFT_SHOULDER;pad.pressed=true;game._input(pad)
 check(game.world.boost_held,'Actual gamepad LB starts the common sprint action')
 pad.pressed=false;game._input(pad);check(not game.world.boost_held,'Gamepad LB release clears sprint')
 pad.button_index=JOY_BUTTON_A;pad.pressed=true;game._input(pad);check(game.world.velocity.y<0.,'Actual Xbox A routes to Jump')
 pad.pressed=false;game._input(pad)
 game.release_all();check(not game.world.boost_held and game.held.is_empty(),'Focus/menu cleanup releases every input')
 game.queue_free();await process_frame
 print('RESULT: %d reward and aim sweep checks, %d failures'%[checks,failures]);quit(1 if failures else 0)
