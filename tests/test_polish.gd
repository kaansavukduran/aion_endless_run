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
 var w=World.new();w.character=hero;w.reset()
 # Owl is an archived ability fixture, not a selectable current hero. Reset
 # correctly migrates removed selections; explicitly restore this test actor.
 w.character=hero;w.obstacle_wait=999;w.frontier.plant_wait=999;w.adventure.item_wait=999;w.adventure.ambient_gnome_wait=999;w.gust_wait=999999;w.invulnerable=999;return w
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
 g.main_menu();g.select_character("aion");g.start_run();g.character="owl";g.world.character="owl";g.press_jump("key");advance(g.world,.42)
 for n in 3:
  g.release_jump("key");g.press_jump("key");g.world.step(.01);g.update_friend()
  check(g.world.owl_flaps_used==n+1 and g.friend_sprite.get_meta("pose_key")=="owl-flap","Shared input selects real airborne flap drawing")
  g.press_jump("key");check(g.world.owl_flaps_used==n+1,"Duplicate held source is ignored")
  advance(g.world,.31)
 # Explicit weapon/grip fixtures, separate from ordinary browser input proof.
 # Derive the expected barrel from raw reviewed source coordinates plus the
 # actual rendered weapon transform; do not call runner_attachment as an oracle.
 g.motion=true;g.interface_options.reduced_motion=false
 var registration: Dictionary=M1HeldWeaponBank.registration('pistol')
 var grip_pixel:=Vector2(registration.grip_pixel[0],registration.grip_pixel[1])
 var muzzle_pixel:=Vector2(registration.muzzle_pixel[0],registration.muzzle_pixel[1])
 var canvas_width: float=registration.canvas_size[0]
 if int(registration.source_facing)<0:
  grip_pixel.x=canvas_width-1.-grip_pixel.x;muzzle_pixel.x=canvas_width-1.-muzzle_pixel.x
 for hero in M1HeroArt.HEROES:
  g.main_menu();g.select_character(hero);g.start_run()
  for charge in ([true,false] if hero in ["rabbit","eren"] else [false]):
   for n in 6:
    g.world.charging=charge;g.world.charge_time=n/5.*g.world.CHARGE_SECONDS;g.world.y=0 if charge else -90;g.world.air_time=0 if n==0 else .2;g.world.velocity=-650+n*260.;g.world.frontier.shot_flash=.12;g.update_friend()
    var action: String="crouch_fire" if charge else "air_fire"
    var column: int=clampi(int(g.world.charge_ratio()*6.),0,5) if charge else g.world.frontier.gun_frame(6)
    var source: Array=M1HeroArt.DATA.data.runtime_rows[hero][action]
    var f: Dictionary=M1HeroArt.DATA.data.atlases[source[0]].frames[int(source[1])][column]
    var hand: Vector2=(Vector2(f.grip[0],f.grip[1])-Vector2(f.origin[0],f.origin[1]))*float(f.scale)*g.visual_size
    var muzzle: Vector2=g.world.frontier.weapon_muzzle(g.world)
    check(muzzle.distance_to(hand+(muzzle_pixel-grip_pixel)*(28./canvas_width)*g.visual_size)<.001,"Current air/charge barrel stays attached to its actual reviewed body hand: "+hero)
    var anchor:=Vector2(g.world.PLAYER_X,g.ground+g.world.y)
    var drawn_grip: Vector2=g.gun_echo.position+(g.gun_echo.offset+grip_pixel)*g.gun_echo.scale
    var drawn_muzzle: Vector2=g.gun_echo.position+(g.gun_echo.offset+muzzle_pixel)*g.gun_echo.scale
    var pixels: Image=g.gun_echo.texture.get_image()
    check(pixels.get_pixelv(Vector2i(muzzle_pixel)).a>.5 and pixels.get_pixelv(Vector2i(grip_pixel)).a>.5,"Expected barrel/handle lie on opaque pixels of the actual drawn held pistol: "+hero)
    check(drawn_grip.distance_to(anchor+hand)<.001 and drawn_muzzle.distance_to(anchor+muzzle)<.001,"Rendered hand socket/barrel and physical muzzle share the same actual transform: "+hero)
    g.world.frontier.emit_hero_shot(g.world);var shot: Dictionary=g.world.frontier.projectiles[-1]
    check(Vector2(shot.x-g.world.PLAYER_X,shot.y-g.world.y).distance_to(muzzle)<.001,"Bullet starts at the actual registered barrel, never an archived sheet position: "+hero)
 g.queue_free();await process_frame
 print("RESULT: %d polish/ability checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
