extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,message: String):
 checks+=1
 if not ok:failures+=1;printerr('FAIL: '+message)
func settle():
 await process_frame;await process_frame;await process_frame
func _initialize():call_deferred('run')
func run():
 var game=load('res://scripts/game.gd').new();root.add_child(game);await settle();game.set_physics_process(false);game.set_process(false);game.front.skip_intro();game.main_menu();game.select_character('sheep');game.start_run()
 game.motion=true;game.interface_options.reduced_motion=false
 var w=game.world;w.sheep_count=3;w.obstacle_wait=99999;w.adventure.item_wait=99999;w.frontier.plant_wait=99999;w.invulnerable=99999
 for frame in 6:
  w.distance=174.*(frame+.1)/6.;game.update_friend()
  var leader_head: float=game.friend_sprite.get_meta('head_size')
  for i in 2:
   var item: Sprite2D=game.followers[i]
   check(item.visible and item.get_meta('pose_key')=='m1-body' and item.get_meta('pose_action')=='walk','Both visible followers use current biped M1 walk body')
   check(is_equal_approx(float(item.get_meta('head_size')),leader_head*.72),'Follower head span is .72 of the same current M1 leader design')
   check(is_equal_approx(item.position.x,w.PLAYER_X-w.FLOCK_GAP*(i+1)) and is_equal_approx(item.position.y,game.ground),'Follower soles and spatial gap match their actual ground position')
   check(not item.get_meta('gun_embedded') and not item.region_enabled,'Follower body has no baked legacy gun or atlas clipping')
   var phase: int=posmod(int((w.travel_distance()-w.FLOCK_GAP*(i+1))/174.*6.),6)
   check(int(item.get_meta('source_frame'))==phase,'Stride follows actual delayed travel distance '+str(item.get_meta('source_frame'))+' expected '+str(phase)+' motion '+str(w.pose_motion_enabled))
 w.reset();w.character='sheep';w.sheep_count=3;w.obstacle_wait=99999;w.adventure.item_wait=99999;w.frontier.plant_wait=99999;w.invulnerable=99999;w.jump();w.step(.02);game.update_friend()
 check(game.friend_sprite.get_meta('pose_action')=='air_fire' and game.followers[0].get_meta('pose_action')=='walk','Leader takeoff does not jump the following sheep early')
 var first_delayed:=false;var second_delayed:=false
 for tick in 150:
  w.step(.01);game.update_friend()
  for i in 2:
   var p: Dictionary=w.flock_pose(i);var item: Sprite2D=game.followers[i]
   check(is_equal_approx(item.position.y,game.ground+float(p.y)),'Follower sprite follows actual sampled jump height')
   if float(p.y)<-.01:
    check(item.get_meta('pose_action')=='air_fire','Delayed airborne follower uses the matching current flight body')
  if w.flock_pose(0).y<-.01 and w.flock_pose(1).y==0.:first_delayed=true
  if w.flock_pose(1).y<-.01:second_delayed=true
 check(first_delayed and second_delayed,'Follower1 then follower2 visually take off at separate actual times')
 w.practice=true;w.frontier.request_boss(5)
 for tick in 180:w.step(.01)
 w.jump()
 for tick in 60:w.step(.01)
 game.update_friend()
 check(w.frontier.active() and game.followers[0].visible and game.followers[1].visible,'Boss chase keeps both current-art followers visible')
 for i in 2:
  check(str(game.followers[i].get_meta('source_key')).begins_with('m1-body-') and is_equal_approx(game.followers[i].position.y,game.ground+float(w.flock_pose(i).y)),'Boss follower shares current M1 art and actual delayed chase height')
 game.interface_options.reduced_motion=true;game.update_friend()
 for item in game.followers:check(int(item.get_meta('source_frame'))==0,'Reduced motion freezes the current follower artwork without removing followers')
 game.interface_options.reduced_motion=false
 w.y=0.;w.trail.clear();w.trail.append({'distance':w.travel_distance(),'y':0.,'velocity':0.,'air_time':0.,'landing_time':0.,'duck':1.,'roll_phase':.31,'roll_remaining':.4,'roll_held':true});game.update_friend()
 for item in game.followers:
  check(item.get_meta('pose_action')=='crouch_walk' and int(item.get_meta('source_frame'))==w.adventure.roll_pose(.31,.4,true,6),'Followers use sampled low posture and their own delayed roll phase')
  check(is_equal_approx(Vector2(item.get_meta('foot_world')).y,game.ground),'Low follower body keeps its soles on actual ground')
 var texture=game.followers[0].texture;w.state='paused';game.update_friend();check(game.followers[0].texture==texture,'Pause preserves the exact delayed follower pose')
 w.state='bonk';game.update_friend();check(not game.followers[0].visible and not game.followers[1].visible,'Fatal-state follower visibility remains unchanged')
 game.queue_free();await settle();campaign_checks();print('RESULT: ',checks,' M1 follower checks, ',failures,' failures');quit(1 if failures else 0)

func campaign_checks():
 var cw=AionCampaignWorld.new();cw.begin('sheep');cw.flock=3
 var view=AionCampaignView.new();view.world=cw;view.host={'motion_enabled':true,'options':{'reduced_motion':false}}
 for deck in [0.,-195.,90.]:
  cw.load_section('fork_one');cw.enemies.clear();cw.player=Vector2(350. if deck==0. else 900.,deck);cw.move_axis=Vector2(1,1);cw.invulnerable=99999
  for tick in 60:cw.step(.01)
  check(not cw.trail.is_empty() and bool(cw.trail[-1].grounded) and bool(cw.trail[-1].crouched),'Actual trail records support and low posture on floor '+str(deck))
  for i in 2:
   var sample: Dictionary={}
   for recorded in cw.trail:
    if float(recorded.time)<=cw.time-float(i+1)*.27:sample=recorded
   var spec: Dictionary=view.follower_render_spec(i)
   check(spec.action=='crouch_walk' and str(spec.pose.source_key).begins_with('m1-body-'),'Campaign followers use current biped low body on elevated and lower floors')
   check(Vector2(spec.p)==Vector2(sample.p) and is_equal_approx(float(spec.p.y),deck),'Campaign follower soles use actual delayed floor sample')
   check(int(spec.frame)==posmod(int(float(sample.walk_distance)/110.*6.),6),'Campaign low stride uses delayed distance rather than leader current phase')
   check(int(spec.facing)==int(sample.facing) and is_equal_approx(float(spec.growth),.67),'Campaign follower keeps actual recorded facing and existing .67 size')
 cw.load_section('shore');cw.enemies.clear();cw.pits.clear();cw.gates.clear();cw.player=Vector2(400,0);cw.invulnerable=99999;cw.move_axis=Vector2.RIGHT
 for tick in 80:cw.step(.01)
 cw.jump_press();cw.jump_release()
 for tick in 36:cw.step(.01)
 var flight: Dictionary=view.follower_render_spec(0)
 check(flight.action=='air_fire' and float(flight.p.y)<0.,'Actual delayed campaign jump uses the matching M1 airborne body')
 var before: Dictionary=view.follower_render_spec(0);cw.state='paused';cw.step(.1);var after: Dictionary=view.follower_render_spec(0)
 check(before.p==after.p and before.frame==after.frame and before.action==after.action,'Campaign pause freezes delayed follower position and phase')
 cw.state='playing';cw.mount.available=true;cw.mount.ridden=true;cw.mount.hp=3;cw.player=Vector2(900,-42.);cw.facing=-1
 for i in 2:
  var spec: Dictionary=view.follower_render_spec(i)
  check(str(spec.pose.source_key).begins_with('m1-body-') and spec.action=='idle_fire' and is_equal_approx(float(spec.growth),.55),'Vehicle follower uses matching current body and original .55 seating scale')
  check(spec.p==view.vehicle_draw_position()+Vector2(28.+i*24.,-30.) and int(spec.facing)==-1,'Seated followers stay on actual mirrored vehicle bench')
 cw.mount.ridden=false;view.host.options.reduced_motion=true
 for i in 2:check(int(view.follower_render_spec(i).frame)==0,'Campaign reduced-motion mode freezes follower frames without changing the sampled path')
 var hud=CampaignHUD.new();hud.host={'view':view,'world':cw}
 for hero in ['aion','sheep','rabbit','eren']:
  cw.character=hero
  var avatar: Dictionary=hud.avatar_pose()
  check(str(avatar.source_key)=='m1-body-'+hero and int(avatar.source_row)==1,'HUD portrait uses the current playable identity rather than a retired gun atlas: '+hero)
 hud.free();view.free()
