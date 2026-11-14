## Explicit deterministic ability/render fixtures. Browser proof uses ordinary inputs.
extends SceneTree
const World=preload("res://scripts/world.gd")
const Bank=preload("res://scripts/frame_bank.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func _initialize():call_deferred("run")
func arena(hero: String):
 var w=World.new();w.character=hero;w.reset();w.obstacle_wait=999;w.frontier.plant_wait=999;w.adventure.item_wait=999;w.adventure.ambient_gnome_wait=999;w.gust_wait=999999;w.invulnerable=999;return w
func advance(w,seconds: float):
 for i in ceili(seconds/.01):w.step(.01)
func run():
 for hero in ["rabbit","eren"]:
  var speeds:=[]
  for hold in [0.,.2,.6,1.2,2.]:
   var w=arena(hero);w.jump();advance(w,hold)
   check(w.charging and w.y==0 and w.jumps_used==0,"Hold charges without early launch "+hero)
   w.release_charged_jump();w.step(.01);speeds.append(-w.velocity)
   check(w.y<0 and w.jumps_used==1 and not w.charging,"Release launches once "+hero)
  check(speeds[0]<speeds[1] and speeds[1]<speeds[2] and speeds[2]<speeds[3] and is_equal_approx(speeds[3],speeds[4]),"Higher charge produces stronger capped leap "+hero)
  var w=arena(hero);w.jump();advance(w,.5);w.release_controls();w.release_charged_jump();w.step(.01)
  check(w.y==0 and not w.charging,"Cancellation never launches "+hero)
 var w=arena("owl");w.jump_held=true;w.jump();advance(w,.42)
 check(w.gliding and w.owl_flaps_used==0 and w.jumps_used==1,"Initial takeoff/held glide costs no flap")
 for n in 3:
  w.jump_held=false;w.step(.01);var before: float=w.y
  w.jump_held=true;w.jump();w.step(.01)
  check(w.owl_flaps_used==n+1 and w.velocity<0 and w.owl_flap_time>0,"Fresh press creates upward flap "+str(n))
  advance(w,.2);check(w.y<before,"Each flap gains actual altitude "+str(n))
  var remaining: int=w.owl_flaps_used;advance(w,.1);check(w.owl_flaps_used==remaining,"Holding never spends repeated flap charges")
 var used: int=w.owl_flaps_used;w.jump();check(w.owl_flaps_used==used,"Fourth flap is refused")
 w.state="paused";var saved: float=w.y;advance(w,.5);check(w.y==saved and w.owl_flaps_used==3,"Pause freezes altitude and flap resource")
 w.state="running";w.release_controls();advance(w,2);check(w.y==0 and w.owl_flaps_used==0,"Landing refills all three flaps")
 var sheep=arena("sheep");sheep.frontier.shot_flash=.3
 var barrel: Vector2=sheep.frontier.weapon_muzzle(sheep)
 check(barrel.y> -45 and barrel.y< -30,"Sheep projectile is below the muzzle/face, at the actual short cyan pistol barrel")
 var bank=Bank.new();var sprite=Sprite2D.new();sprite.centered=false
 for clip in ["owl-flap","runner-owl","runner-eren"]:
  var row: int=0 if clip=="owl-flap" else 6
  var x: float=-9999;var scale_value: float=0
  for col in 6:
   bank.place(sprite,clip,row,col,Vector2(288,500));var p: Vector2=sprite.get_meta("head_probe_world")
   if col==0:x=p.x;scale_value=sprite.scale.x
   check(absf(p.x-x)<.001 and is_equal_approx(sprite.scale.x,scale_value) and sprite.position==Vector2(288,500),"Anatomical horizontal registration and fixed actor "+clip+str(col))
   if clip=="runner-eren":check(absf(sprite.get_meta("foot_world").y-500)<.001,"Eren charge shoes plant on the road")
 for kind in bank.POLISH.data.pickup_order:
  var p=bank.pickup_pose(kind);check(p.source_key=="polish-pickups" and p.texture.get_width()>4 and p.scale>0,"Actual distinct collectible is registered "+kind)
 for row in 6:
  for col in 3:
   var p=bank.pose("flora",row,col)
   check(absf((p.offset.y+p.foot_local.y)*p.scale)<.001,"Opaque connected root contacts its support plane")
 sprite.free()
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.touch_tutorial_done=true
 for hero in ["rabbit","eren"]:
  g.main_menu();g.select_character(hero);g.start_run();g.press_jump("touch:1");advance(g.world,.45);g.press_jump("touch:2");g.release_jump("touch:2",false)
  check(g.world.charging,"Unrelated finger cannot cancel owned charge "+hero)
  g.release_jump("touch:1",false);g.world.step(.01);check(g.world.y==0 and not g.world.charging,"Touch cancellation does not launch "+hero)
 g.main_menu();g.select_character("owl");g.start_run();g.press_jump("key");advance(g.world,.42)
 for n in 3:
  g.release_jump("key");g.press_jump("key");g.world.step(.01);g.update_friend()
  check(g.world.owl_flaps_used==n+1 and g.friend_sprite.get_meta("pose_key")=="owl-flap","Shared input selects real airborne flap drawing")
  g.press_jump("key");check(g.world.owl_flaps_used==n+1,"Duplicate held source is ignored")
  advance(g.world,.31)
 # Explicit weapon/grip fixtures, separate from ordinary browser input proof.
 g.main_menu();g.select_character("eren");g.start_run()
 for charge in [true,false]:
  for n in 6:
   g.world.charging=charge;g.world.charge_time=n/5.*g.world.CHARGE_SECONDS;g.world.y=0 if charge else -90;g.world.air_time=0 if n==0 else .2;g.world.velocity=-650+n*260.;g.world.frontier.shot_flash=.12;g.update_friend()
   var column: int=g.frames.progress("runner-eren",6,g.world.charge_ratio()) if charge else g.flight_frame(g.world.velocity,g.world.air_time,6)
   var atlas: Dictionary=g.frames.POLISH.data.atlases["polish-abilities"];var row: int=2 if charge else 3;var f: Dictionary=atlas.frames[row][column]
   var hand: Vector2=(Vector2(f.weapon_grip[0],f.weapon_grip[1])-Vector2(f.origin[0],f.origin[1]))*float(atlas.scale[row])
   var muzzle: Vector2=g.world.frontier.weapon_muzzle(g.world)
   check(muzzle.distance_to(hand+Vector2(23,-5))<.001,"Air/charge pistol attaches to the reviewed skin-colored hand landmark")
   var gun_frame: int=g.world.frontier.gun_frame(6);var original: Array=g.frames.PIXEL.data.atlases["pixel-eren"].frames[4][gun_frame].muzzle
   var drawn: Vector2=g.gun_echo.position+Vector2(original[0],original[1])
   check(drawn.distance_to(Vector2(g.world.PLAYER_X,g.ground+g.world.y)+muzzle)<.51,"Rendered barrel and emitted projectile share the actual hand-bound muzzle")
   g.world.frontier.emit_hero_shot(g.world);var shot: Dictionary=g.world.frontier.projectiles[-1]
   check(Vector2(shot.x-g.world.PLAYER_X,shot.y-g.world.y).distance_to(muzzle)<.001,"Bullet starts at the same registered barrel, never the previous sheet position")
 g.queue_free();await process_frame
 print("RESULT: %d polish/ability checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
