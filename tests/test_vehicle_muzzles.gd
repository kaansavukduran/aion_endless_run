extends SceneTree

## Reconstruct actual isolated cannon pixels and the renderer's transform.
## Controlled fixtures do not claim physical gamepad/native-device testing.
var checks:=0
var failures:=0
var art:=ForgeVehicleArt.new()
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures+=1;printerr('FAIL: '+label)
func fresh(kind: String,hull_facing: int) -> AionCampaignWorld:
 var w:=AionCampaignWorld.new();w.begin('aion');w.state='playing'
 w.enemies.clear();w.npcs.clear();w.gates.clear();w.objects.clear();w.platforms.clear();w.pits.clear()
 w.mount={'available':true,'ridden':true,'x':140.,'hp':3,'type':kind};w.player=Vector2(140.,-42.);w.facing=hull_facing
 return w
func _initialize() -> void:call_deferred('run')

# Use the actual drawn texture rectangle and source tip coordinate, not the
# armed_muzzle()/aim_anchors() output being tested. Image reflection uses the
# continuous texture rectangle; source socket points are geometric positions.
func drawn_barrel(w: AionCampaignWorld,height: float) -> Dictionary:
 var spec:=w.vehicle_art_spec();var kind:=CampaignVehicles.kind(w)
 var split:=art.split_pose(kind,int(spec.phase),int(spec.frame),height)
 var cannon: Dictionary=split.turret;var texture: Texture2D=cannon.texture
 var phase: int=ForgeVehicleArt.mounted_phase(kind,int(spec.phase));var frame: int=spec.frame
 var source: Dictionary=ForgeVehicleArt.DATA.data.types[kind].frames[phase][frame]
 var registered: Dictionary=ForgeVehicleArt.TURRETS.data.types[kind].frames[phase][frame]
 var cut: Rect2i=split.source_cut
 var pixel:=Vector2(float(registered.muzzle[0])-cut.position.x+2.,float(registered.muzzle[1])-cut.position.y+2.)
 if int(registered.source_facing)<0:pixel.x=texture.get_width()-pixel.x
 var factor: float=Vector2(cannon.size).x/texture.get_width()
 var origin:=Vector2(float(source.origin[0]),float(source.origin[1]))
 var pivot: Vector2=(Vector2(float(registered.pivot[0]),float(registered.pivot[1]))-origin)*factor
 pivot.x*=w.facing
 var local: Vector2=Vector2(cannon.offset)+pixel*factor
 var aim: Vector2=w.aim_direction.normalized() if w.aim_direction.length_squared()>.01 else Vector2(w.facing,0.)
 return {'point':pivot+local.rotated(aim.angle()+float(cannon.get("rotation",0.)))+Vector2(0,42),'pixel':pixel,'texture':texture,'pivot':pivot,'local':local,'phase':phase}

func run() -> void:
 var parked:=AionCampaignWorld.new();parked.begin('aion');parked.load_section('quay')
 parked.enemies.clear();parked.npcs.clear()
 parked.attack_press()
 check(parked.shot_flash>0. and parked.vehicle_art_spec().phase==0,'On-foot fire cannot animate the first parked skimmer')
 parked.player=Vector2(360.,0.);check(parked.interact(),'The first skimmer still accepts a normal boarding action')
 check(parked.vehicle_art_spec().phase==0 and not CampaignVehicles.firing(parked),'Boarding clears the previous on-foot shot')
 for tick in 85:parked.step(.01)
 parked.attack_press()
 check(parked.vehicle_art_spec().phase==1 and CampaignVehicles.firing(parked),'The mounted skimmer animates its own actual shot')
 check(parked.interact() and parked.vehicle_art_spec().phase==0,'Dismounting immediately clears the vehicle firing pose')
 var view:=AionCampaignView.new()
 var height: float=view.hero_reference_height()*2.
 var directions: Array[Vector2]=[Vector2.RIGHT,Vector2(1,-1).normalized(),Vector2.UP,Vector2(-1,-1).normalized(),Vector2.LEFT,Vector2(-1,1).normalized(),Vector2.DOWN,Vector2(1,1).normalized()]
 # Off-axis values prove aim is continuous instead of eight snapped keyposes.
 for angle in [.17,.37,1.13,2.34,3.89,4.71,5.49]:directions.append(Vector2.from_angle(angle))
 for kind in CampaignVehicles.TYPES:
  for facing in [-1,1]:
   for aim in directions:
    for frame in 6:
     var w:=fresh(kind,facing);w.aim_direction=aim;w.time=(frame+.1)/8.;w.shot_flash=.18*(1.-(frame+.1)/6.);w.last_shot_mounted=true
     var spec:=w.vehicle_art_spec();var aligned: bool=absf(aim.y)<.005 and aim.x*facing>0.
     check(int(spec.phase)==(1 if aligned else 0),'Forward firing timing is used only along the hull facing')
     check(int(spec.frame)==frame,'Actual vehicle animation frame is shared between view and muzzle')
     var actual:=drawn_barrel(w,height)
     check(int(actual.phase)==0,'Mounted fire draws neutral isolated hull plus one independently rotated barrel')
     check(w.armed_muzzle().distance_to(actual.point)<.001,'Model muzzle equals actual registered source-tip pixel after rendered pivot/rotation/scale')
     var point:=Vector2i(Vector2(actual.pixel).floor())
     var pixels: Image=actual.texture.get_image()
     check(point.x>=0 and point.y>=0 and point.x<pixels.get_width() and point.y<pixels.get_height() and pixels.get_pixelv(point).a>.3,'Actual source tip lies on the original cannon silhouette: '+kind+'/'+str(frame))
     check((Vector2(actual.point)-Vector2(0,42)-Vector2(actual.pivot)).normalized().distance_to(aim)<.001,'Actual barrel has the true continuous surrounding direction')
     w.attack_press()
     var fired:=drawn_barrel(w,height);var fired_end: Vector2=w.player+Vector2(fired.point)
     check(w.bullets.size()==3,'Mounted attack produces the actual weapon volley')
     for b in w.bullets:
      check(Vector2(b.p).distance_to(fired_end)<.001,'Actual emitted projectile begins at current visible source barrel end')
      check(absf(Vector2(b.v).length()-float(420. if kind=='drill' else (600. if kind=='shell' else 780.)))<.001,'Art correction preserves vehicle weapon speed')
     if aligned and kind=='shell' and frame==0:
      check(absf(fired_end.y+50.)<20.,'Shell emits near the visible ground-enemy height instead of guessed136px')
  for hurt in [0.,.2]:
   for frame in 6:
    var w:=fresh(kind,1);w.mount.hurt=hurt;w.time=(frame+.1)/8.;w.aim_direction=Vector2.from_angle(-.73);w.shot_flash=.1
    check(w.vehicle_art_spec().phase==(2 if hurt>0. else 0),'Hurt timing remains explicit even when skimmer reuses its available chassis')
    var actual:=drawn_barrel(w,height)
    check(w.armed_muzzle().distance_to(actual.point)<.001,'Hurt chassis still shares its actual cannon pivot with projectiles')
    var point:=Vector2i(Vector2(actual.pixel).floor())
    check(actual.texture.get_image().get_pixelv(point).a>.3,'Every hurt-frame tip is a real original barrel pixel: '+kind+'/'+str(frame))
 view.free()
 print('RESULT: %d vehicle pose/muzzle checks, %d failures'%[checks,failures]);quit(1 if failures else 0)
