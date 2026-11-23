extends SceneTree

var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;printerr('FAIL: '+message)
func _initialize() -> void:call_deferred('run')
func fresh() -> AionCampaignWorld:
 var w:=AionCampaignWorld.new();w.begin('aion');w.state='playing';w.player=Vector2(400,0)
 w.enemies.clear();w.npcs.clear();w.objects.clear();w.gates.clear();w.crates.clear();w.platforms.clear();w.pits.clear();w.pending_events.clear();w.invulnerable=999.
 return w
func advance(w,seconds: float) -> void:
 for i in int(ceil(seconds/.01)):w.step(minf(.01,seconds-i*.01))
func bomb_at(w,p: Vector2,v: Vector2) -> Dictionary:
 var b: Dictionary={'kind':'grenade','p':p,'v':v,'age':0.,'color':'ef86b7','angle':0.,'spin':7.,'contacts':[],'contact_wait':0.,'exploded':false}
 w.bombs.append(b);return b
func event_count(w,key: String) -> int:return w.pending_events.count(key)
func run() -> void:
 # Ordinary public input and World.step prove the animation isn't the owner.
 var w:=fresh()
 check(w.throw_grenade(),'One press accepts the approved grenade action')
 check(w.grenades==5 and w.bombs.is_empty(),'Windup holds the object; inventory is unchanged until release')
 check(not w.throw_grenade(),'Repeated held press cannot enqueue a second throw')
 advance(w,.15);check(w.bombs.is_empty() and w.grenades==5,'No object or ammo spend before release')
 advance(w,.02);check(w.bombs.size()==1 and w.grenades==4 and event_count(w,'grenade')==1,'Crossing release emits exactly one object, consumption and release sound')
 var p: Vector2=w.bombs[0].p
 check(p.distance_to(w.player+CampaignGrenade.hand_offset(w))<10.,'Standing bomb leaves the measured release hand without an anchor jump')
 advance(w,.31);check(w.grenade_throw.is_empty() and w.bombs.size()==1,'Throw recovers while independent grenade continues')
 advance(w,1.);check(w.bombs.is_empty() and event_count(w,'grenade_blast')==1,'Fuse detonates once and cleans up projectile')
 check(event_count(w,'blast')==0,'Grenade uses its one scoped explosion sound')
 advance(w,1.);check(w.blasts.is_empty() and event_count(w,'grenade_blast')==1,'Smoke expires without repeated damage or sound')
 # Pause is absence of simulation; action/fuse resume on the same clock.
 w=fresh();w.throw_grenade();advance(w,.08)
 var elapsed: float=w.grenade_throw.elapsed;w.state='paused';w.step(.05)
 check(float(w.grenade_throw.elapsed)==elapsed and w.grenades==5,'Paused windup does not advance or consume')
 w.state='playing';advance(w,.1);var fuse: float=w.bombs[0].age;w.state='paused';w.step(.05)
 check(float(w.bombs[0].age)==fuse,'Paused independent fuse is frozen')
 w.state='playing';CampaignGrenade.cancel(w)
 check(w.bombs.size()==1 and w.grenades==4,'Cancel after release preserves the spent independent object')
 w=fresh();w.throw_grenade();advance(w,.1);CampaignGrenade.cancel(w);advance(w,.2)
 check(w.bombs.is_empty() and w.grenades==5,'Focus cancellation before release neither queues nor spends a grenade')
 # Scene fixture deliberately jumps an animation interval, not ordinary input.
 w=fresh();w.throw_grenade();CampaignGrenade.step(w,1.4)
 check(w.grenade_throw.is_empty() and w.bombs.is_empty() and w.grenades==4,'A coarse helper update crossing release and fuse cannot lose or duplicate an object')
 check(event_count(w,'grenade')==1 and event_count(w,'grenade_blast')==1 and w.blasts.size()==1,'Release/fuse in one interval produces one explosion')
 # Root step caps dt at .05: a long real frame advances the same bounded clock.
 w=fresh();w.throw_grenade();w.step(2.)
 check(w.bombs.is_empty() and float(w.grenade_throw.elapsed)<=.050001,'Ordinary long frame respects existing World dt policy')
 # Facing is captured; walking the opposite way cannot mirror the release.
 w=fresh();w.aim_direction=Vector2.LEFT;w.facing=1;w.throw_grenade();w.aim_direction=Vector2.RIGHT;w.move_axis=Vector2.RIGHT;advance(w,.17)
 check(w.bombs.size()==1 and w.bombs[0].v.x<0. and w.bombs[0].p.x<w.player.x,'Backwalking and aim change preserve the accepted throw side')
 # Simulation collision fixtures isolate actual geometry, not a rendered ring.
 w=fresh();w.platforms=[Rect2(450,-100,200,20)];var b:=bomb_at(w,Vector2(500,-145),Vector2(0,310));advance(w,.12)
 check(b.p.y<=-109. and b.v.y<0. and event_count(w,'grenade_bounce')==1,'Falling grenade bounces on real elevated support with one contact sound')
 check(not b.contacts.is_empty() and Vector2(b.contacts[0].normal)==Vector2.UP,'Floor dust is attached to a real upward contact normal')
 w=fresh();w.platforms=[Rect2(450,-100,200,20)];b=bomb_at(w,Vector2(500,-50),Vector2(0,-350));advance(w,.1)
 check(b.p.y>=-71. and b.v.y>0. and event_count(w,'grenade_bounce')==1,'Ceiling underside bounces rather than passing through')
 check(Vector2(b.contacts[0].normal)==Vector2.DOWN,'Ceiling contact cannot emit floor dust')
 w=fresh();w.section='fork_one';b=bomb_at(w,Vector2(750,-80),Vector2(420,0));advance(w,.12)
 check(b.p.x<CampaignRoutes.PIER.position.x-9. and b.v.x<0. and event_count(w,'grenade_bounce')==1,'Solid pier wall reflects grenade once')
 w=fresh();w.pits=[Vector2(300,800)];b=bomb_at(w,Vector2(500,-15),Vector2(0,150));advance(w,.15)
 check(b.p.y>0. and event_count(w,'grenade_bounce')==0 and b.contacts.is_empty(),'Pit has no invisible floor or airborne dust')
 w=fresh();w.load_section('fork_one');w.state='playing';w.enemies.clear();w.npcs.clear();w.objects.clear();w.pending_events.clear();w.player=Vector2(880,90);w.move_axis=Vector2.DOWN
 w.throw_grenade();advance(w,.17)
 check(w.bombs.size()==1 and w.bombs[0].p.y>44. and w.bombs[0].p.y<81.,'Crouched release stays inside real crawlway below its ceiling')
 w=fresh();w.throw_grenade();advance(w,.08);w.hp=1;w.invulnerable=0.;w.damage_player();advance(w,.3)
 check(w.grenades==5 and w.bombs.is_empty() and w.grenade_throw.is_empty(),'Death before release cancels without delayed object or ammunition spend')
 w=fresh();w.throw_grenade();advance(w,.2);w.retry()
 check(w.grenade_throw.is_empty() and w.bombs.is_empty() and w.blasts.is_empty(),'Retry clears scene-local throw, projectile and effect state')
 # Damage is still the existing single World.explode result, independently of drawing.
 w=fresh();w.boss.active=true;w.boss.engaged=true;w.boss.x=600.;w.boss.y=0.;w.boss.hp=90
 b=bomb_at(w,Vector2(600,-70),Vector2.ZERO);b.age=1.14;CampaignGrenade.step(w,.02)
 check(int(w.boss.hp)==82 and w.blasts.size()==1 and w.blasts[0].kind=='grenade','Detonation preserves exactly the existing eight boss damage and tags one effect')
 CampaignGrenade.step(w,.3)
 check(int(w.boss.hp)==82 and event_count(w,'grenade_blast')==1,'Subsequent simulation cannot damage the target twice')
 w=fresh();w.throw_grenade();advance(w,.08);w.invulnerable=0.;w.damage_player()
 check(w.hp==2 and w.grenades==5 and w.grenade_throw.is_empty(),'Nonfatal damage interrupts an unspent throw without losing ammo')
 w=fresh();w.throw_grenade();advance(w,.2);w.invulnerable=0.;w.damage_player();advance(w,1.2)
 check(w.hp==2 and w.grenades==4 and w.bombs.is_empty() and event_count(w,'grenade_blast')==1,'Nonfatal damage after release preserves independent fuse and one explosion')
 w=fresh();w.mount={'available':true,'ridden':false,'x':400.,'hp':3};w.throw_grenade();advance(w,.08)
 check(w.interact() and w.grenade_throw.is_empty() and w.grenades==5,'Boarding cancels the held throw instead of queueing it through transition')
 w=fresh();w.mount={'available':true,'ridden':true,'x':400.,'hp':3};w.player.y=-42.;w.throw_grenade();advance(w,.08);CampaignVehicles.eject(w)
 check(w.grenade_throw.is_empty() and w.grenades==5,'Forced ejection cancels unspent grenade without a delayed release')
 w=fresh();w.grenades=0;check(not w.throw_grenade() and w.grenade_throw.is_empty(),'Empty inventory cannot start a throw')
 # All current playable identities share exact release semantics and their own
 # measured hand in both directions; no render callback participates.
 for hero in AionCampaignWorld.HEROES:
  for side in [-1,1]:
   for posture in ['stand','crouch','air']:
    w=fresh();w.character=hero;w.facing=side;w.aim_direction=Vector2(side,0)
    if posture=='crouch':w.move_axis=Vector2(0,1)
    elif posture=='air':w.player.y=-120.
    w.throw_grenade();advance(w,.17)
    check(w.grenades==4 and w.bombs.size()==1 and w.pending_events.count('grenade')==1,'One measured release '+hero+'/'+str(side)+'/'+posture)
    if not w.bombs.is_empty():check(Vector2(w.bombs[0].p).distance_to(w.player+CampaignGrenade.hand_offset(w))<16.,'Release stays attached to drawn hand '+hero+'/'+str(side)+'/'+posture)
 for hero in AionCampaignWorld.HEROES:
  for low in [false,true]:
   w=fresh();w.character=hero;w.pose_motion_enabled=false
   if low:w.move_axis=Vector2.DOWN
   w.throw_grenade();advance(w,.17)
   var pose: Dictionary=M1CombatArt.body_spec(w)
   check(int(pose.frame)==3 and str(pose.action)==('crouch_grenade_throw' if low else 'grenade_throw'),'Reduced motion retains the physical release cel '+hero+'/'+str(low))
 # Real View's draw entry uses this predicate, so release/follow-through
 # cannot accidentally re-equip a gun in the open throwing hand.
 var view:=AionCampaignView.new()
 for hero in AionCampaignWorld.HEROES:
  w=fresh();w.character=hero;view.world=w;w.throw_grenade()
  var weapon_elapsed:=0.
  for stamp in [0.,.06,.12,.17,.27,.37]:
   advance(w,float(stamp)-weapon_elapsed);weapon_elapsed=float(stamp)
   check(not view.hero_weapon_visible(),'Weapon layer hidden through throw cel '+hero+'/'+str(CampaignGrenade.frame_at(weapon_elapsed)))
  advance(w,.08);check(view.hero_weapon_visible(),'Weapon returns only after complete throw '+hero)
 view.free()
 w=fresh();w.throw_grenade();advance(w,.2);w.begin('aion');w.state='playing'
 check(w.grenade_time==0. and w.throw_grenade(),'A new run clears the previous run grenade cooldown')
 w=fresh();w.throw_grenade();advance(w,.2);w.retry();w.state='playing'
 check(w.grenade_time==0. and w.throw_grenade(),'Checkpoint retry clears stale grenade cooldown as well as its objects')
 # The actual common input latch must not turn a rejected press into a
 # delayed throw, and the game's real touch button mirrors that eligibility.
 var game:=AionCampaignGame.new();root.add_child(game);await process_frame;game.set_process(false)
 game.menu_kind='';game.presentation_stage='';game.fade=-1.;game.touch_mode=true
 for blocker in ['hurt_time','rescue_time','melee_time']:
  game.world=fresh();game.view.world=game.world;game.world.set(blocker,.2);game.release_all();game.build_ui();game.update_hud()
  check(not CampaignGrenade.can_press(game.world) and game.actions.grenade.disabled,'Touch feedback reflects blocked grenade during '+blocker)
  game.set_action('grenade','blocked-test',true)
  check(game.world.grenade_throw.is_empty() and game.world.grenades==5,'Blocked common input does not start or consume a grenade '+blocker)
  game.world.set(blocker,0.);game.update_hud();game.set_action('grenade','blocked-test',true)
  check(not game.actions.grenade.disabled and game.world.grenade_throw.is_empty(),'Recovered availability never buffers a held failed press '+blocker)
  game.set_action('grenade','blocked-test',false);game.set_action('grenade','blocked-test',true)
  check(not game.world.grenade_throw.is_empty(),'A fresh press after recovery starts exactly one action '+blocker)
  game.update_hud();check(game.actions.grenade.disabled,'Active throw disables its real touch button '+blocker)
 game.queue_free();await process_frame
 # Registered rigid-prop geometry is shared by the actual selected lower-floor
 # palm, the held sprite grip pixel, and the released physics object.
 var registered_pixels: Image=RunnerSourcePixels.image('res://assets/m1_grenade_fx.png')
 check(registered_pixels.get_pixelv(Vector2i(CampaignGrenade.PROP_GRIP_PIXEL)).a>.9,'Registered shell grasp is an actual opaque source pixel')
 var shell_bottom: float=(338.-CampaignGrenade.PROP_CENTER_PIXEL.y)/CampaignGrenade.PROP_SOURCE_CELL*CampaignGrenade.PROP_DISPLAY_CELL
 for grasp_hero in AionCampaignWorld.HEROES:
  for grasp_side in [-1,1]:
   w=fresh();w.character=grasp_hero;w.load_section('fork_one');w.state='playing';w.player=Vector2(940,90);w.aim_direction=Vector2(grasp_side,0);w.facing=grasp_side;w.move_axis=Vector2.DOWN
   check(w.throw_grenade(),'Lower-floor throw is available '+grasp_hero+'/'+str(grasp_side))
   for grasp_stamp in [0.,.06,.12,.17,.27,.37]:
    w.grenade_throw.elapsed=grasp_stamp;w.grenade_throw.released=float(grasp_stamp)>=CampaignGrenade.WINDUP
    var grasp_spec: Dictionary=M1CombatArt.body_spec(w)
    var grasp_body: Dictionary=M1HeroArt.metrics(grasp_hero,str(grasp_spec.action),int(grasp_spec.frame))
    var grasp_palm: Vector2=Vector2(grasp_body.get('grenade_hand_local',grasp_body.grip_local))*Vector2(grasp_side,1)
    var grasp_center: Vector2=CampaignGrenade.hand_offset(w)
    var grasp_back_to_palm: Vector2=grasp_center+(CampaignGrenade.PROP_GRIP_PIXEL-CampaignGrenade.PROP_CENTER_PIXEL)/CampaignGrenade.PROP_SOURCE_CELL*CampaignGrenade.PROP_DISPLAY_CELL*Vector2(grasp_side,1)
    check(grasp_center.is_equal_approx(grasp_palm+CampaignGrenade.PALM_TO_CENTER*Vector2(grasp_side,1)) and grasp_back_to_palm.is_equal_approx(grasp_palm),'Exact mirrored palm/center/sprite-grip registration '+grasp_hero+'/'+str(grasp_side)+'/'+str(grasp_stamp))
    check(w.player.y+grasp_center.y+shell_bottom<=CampaignRoutes.LOWER_FLOOR+.5,'Opaque held shell clears actual lower floor '+grasp_hero+'/'+str(grasp_side)+'/'+str(grasp_stamp))
   CampaignGrenade.cancel(w);w.grenade_time=0.;w.throw_grenade();CampaignGrenade.step(w,CampaignGrenade.WINDUP)
   check(w.bombs.size()==1 and Vector2(w.bombs[0].p).is_equal_approx(w.player+CampaignGrenade.hand_offset(w)) and float(w.bombs[0].age)==0.,'Release uses the identical registered physical center '+grasp_hero+'/'+str(grasp_side))
 # Pause goes through the real Game/menu path, including the second input
 # release during menu/settings rebuild. Voluntary inputs never come back.
 var pause_game:=AionCampaignGame.new();root.add_child(pause_game);await process_frame;pause_game.set_process(false)
 pause_game.presentation_stage='';pause_game.fade=-1.
 for pause_hero in AionCampaignWorld.HEROES:
  for pause_age in [.12,.20]:
   for pause_in_tunnel in [false,true]:
    var pause_world:=fresh();pause_world.character=pause_hero
    if pause_in_tunnel:
     pause_world.load_section('fork_one');pause_world.state='playing';pause_world.player=Vector2(940,90);pause_world.enemies.clear();pause_world.objects.clear();pause_world.npcs.clear()
    pause_world.move_axis=Vector2.DOWN;pause_world.aim_direction=Vector2(-1,-1).normalized();pause_world.facing=-1
    pause_game.world=pause_world;pause_game.view.world=pause_world;pause_game.menu_kind='';pause_game.down_down=true
    pause_game.set_action('grenade','pause-test',true);advance(pause_world,pause_age)
    var pause_before: Dictionary=M1CombatArt.body_spec(pause_world)
    var pause_center: Vector2=CampaignGrenade.hand_offset(pause_world)
    var pause_aim: Vector2=pause_world.aim_direction
    var pause_elapsed: float=pause_world.grenade_throw.elapsed
    var pause_fuse: float=float(pause_world.bombs[0].age) if not pause_world.bombs.is_empty() else -1.
    var pause_stock: int=pause_world.grenades
    pause_game.toggle_pause()
    check(pause_world.state=='paused' and pause_world.crouching(),'Actual Game pause preserves crouched presentation '+pause_hero+'/'+str(pause_age)+'/'+str(pause_in_tunnel))
    check(M1CombatArt.body_spec(pause_world)==pause_before and CampaignGrenade.hand_offset(pause_world).is_equal_approx(pause_center),'Pause preserves selected source/cel/mirror and exact prop center '+pause_hero)
    check(pause_world.aim_direction.is_equal_approx(pause_aim),'Pause preserves diagonal visible aim '+pause_hero)
    pause_world.step(.05);pause_game.build_ui()
    check(float(pause_world.grenade_throw.elapsed)==pause_elapsed and pause_world.grenades==pause_stock and (pause_fuse<0. or float(pause_world.bombs[0].age)==pause_fuse),'Pause/menu rebuild freezes release and fuse without spending ammo '+pause_hero)
    pause_game.menu_kind='settings';pause_game.build_ui()
    check(M1CombatArt.body_spec(pause_world)==pause_before and CampaignGrenade.hand_offset(pause_world).is_equal_approx(pause_center) and pause_world.aim_direction.is_equal_approx(pause_aim),'Paused settings rebuild preserves source/grasp/aim '+pause_hero)
    pause_game.menu_kind='paused';pause_game.close_menu()
    check(pause_world.state=='playing' and not pause_world.paused_crouch and pause_game.held.is_empty() and not pause_game.down_down and pause_world.move_axis==Vector2.ZERO and not pause_world.fire_held,'Resume clears cached stance and held sources without restoring controls '+pause_hero)
    check(pause_world.crouching()==pause_in_tunnel,'Resume crouches only when current geometry requires it '+pause_hero)
    pause_world.step(.01)
    check(float(pause_world.grenade_throw.elapsed)>pause_elapsed and pause_world.grenades==pause_stock and (pause_fuse<0. or float(pause_world.bombs[0].age)>pause_fuse),'Resume advances the existing action/fuse once '+pause_hero)
    pause_world.paused_crouch=true;pause_world.load_section('shore')
    check(not pause_world.paused_crouch,'Section/retry/new-run load clears transient pause stance '+pause_hero)
 # An already extended crouched tongue remains anchored during explicit pause.
 var tongue_world:=fresh();tongue_world.character='frog';tongue_world.move_axis=Vector2.DOWN;pause_game.world=tongue_world;pause_game.view.world=tongue_world;pause_game.menu_kind=''
 check(MissionHeroAbilities.press(tongue_world),'Frog tongue begins for actual pause regression')
 advance(tongue_world,.23)
 var paused_mouth: Vector2=MissionHeroAbilities.mouth(tongue_world);var paused_tip: Vector2=MissionHeroAbilities.tongue_tip(tongue_world);var paused_extent: float=tongue_world.hero_skill.extent
 pause_game.toggle_pause();tongue_world.step(.05)
 check(paused_extent>0. and float(tongue_world.hero_skill.extent)==paused_extent and MissionHeroAbilities.mouth(tongue_world).is_equal_approx(paused_mouth) and MissionHeroAbilities.tongue_tip(tongue_world).is_equal_approx(paused_tip),'Actual Game pause freezes the same crouched tongue body/mouth/tip')
 pause_game.close_menu();check(not tongue_world.paused_crouch and tongue_world.move_axis==Vector2.ZERO,'Tongue resume does not restore the crouch input')
 var paused_gun_world:=fresh();paused_gun_world.move_axis=Vector2.DOWN;paused_gun_world.aim_direction=Vector2(-1,-1).normalized();paused_gun_world.facing=-1;pause_game.world=paused_gun_world;pause_game.view.world=paused_gun_world;pause_game.menu_kind=''
 var paused_gun_before: Dictionary=M1CombatArt.placement(paused_gun_world)
 pause_game.toggle_pause();var paused_gun_after: Dictionary=M1CombatArt.placement(paused_gun_world)
 check(pause_game.view.hero_weapon_visible() and Vector2(paused_gun_before.grip).is_equal_approx(Vector2(paused_gun_after.grip)) and Vector2(paused_gun_before.muzzle).is_equal_approx(Vector2(paused_gun_after.muzzle)) and is_equal_approx(float(paused_gun_before.angle),float(paused_gun_after.angle)),'Paused crouched gun preserves its actual grip/barrel/angle')
 pause_game.queue_free();await process_frame
 print('RESULT: %d grenade checks, %d failures'%[checks,failures]);quit(1 if failures else 0)
