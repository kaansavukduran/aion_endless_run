extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,message: String):
 checks+=1
 if not ok:failures+=1;printerr('FAIL: '+message)
func _initialize():call_deferred('run')
func run():
 var bank=ForgeVehicleArt.new()
 var known: Dictionary=ForgeVehicleArt.DATA.data
 for kind in known.types:
  check(FileAccess.get_sha256('res://'+str(known.types[kind].path))==str(known.types[kind].sha256),'Original source pixels unchanged: '+kind)
  for phase in known.types[kind].frames.size():
   for frame in known.types[kind].frames[phase].size():
    var split:=bank.split_pose(kind,phase,frame)
    var metrics:=ForgeVehicleArt.aim_anchors(kind,phase,frame)
    var normalized: int=ForgeVehicleArt.mounted_phase(kind,phase)
    var old:=bank.pose(kind,normalized,frame)
    check(split.hull.size==old.size and split.hull.offset==old.offset,'Removing baked barrel never renormalizes hull or moves its root')
    if not bool(metrics.can_fire):
     check(split.turret.is_empty(),'Wrecks do not invent a functional cannon');continue
    check(int(split.hull.source_phase)==normalized and (phase!=1 or normalized==0),'Firing reuses neutral chassis instead of a second fixed horizontal flash')
    var cannon: Image=split.turret.texture.get_image()
    var count:=0
    for y in cannon.get_height():
     for x in cannon.get_width():
      if cannon.get_pixel(x,y).a>0.:count+=1
    check(count>25,'Rotating cannon contains actual original barrel pixels')
    var restored: Image=split.hull.texture.get_image().duplicate()
    var gun: Image=cannon.duplicate()
    if int(split.source_facing)<0:gun.flip_x()
    var f: Dictionary=known.types[kind].frames[normalized][frame]
    var cut: Rect2i=split.source_cut
    var offset:=Vector2i(int(f.bounds[0])-2,int(f.bounds[1])-2)
    var empty:=true
    for y in cut.size.y:
     for x in cut.size.x:
      var source_pixel:=cut.position+Vector2i(x,y)
      if not Geometry2D.is_point_in_polygon(Vector2(source_pixel)+Vector2(.5,.5),split.source_polygon):continue
      var at:=source_pixel-offset
      if at.x<0 or at.y<0 or at.x>=restored.get_width() or at.y>=restored.get_height():continue
      empty=empty and restored.get_pixelv(at).a==0.
      restored.set_pixelv(at,gun.get_pixel(x+2,y+2))
    check(empty,'Hull omits every extracted cannon pixel: '+kind+'/'+str(phase)+'/'+str(frame))
    check(restored.get_data()==old.texture.get_image().get_data(),'Hull plus original cannon reconstruct exact original RGBA, with no painted replacement')
    check(split.turret.offset.is_finite() and split.turret.size.x>1. and split.turret.size.y>1.,'Cannon has a finite pivot-relative rectangle')
    check((Vector2(split.turret.muzzle_local)-Vector2(float(metrics.barrel_length),0.)).length()<.001,'Canonical texture muzzle lies on positive-X barrel axis')
    for facing in [-1,1]:
     var pivot:=Vector2(metrics.pivot_local.x*facing,metrics.pivot_local.y)
     for n in 17:
      var aim:=Vector2.from_angle(n*TAU/17.)
      var tip: Vector2=pivot+Vector2(split.turret.muzzle_local).rotated(aim.angle())
      check((tip-(pivot+aim*float(metrics.barrel_length))).length()<.001,'Free continuous turret rotation matches the actual projectile endpoint')
 var skimmer:=ForgeVehicleArt.aim_anchors('skimmer')
 check(skimmer.pivot_local.x<0. and skimmer.muzzle_local.y< -90.,'Skimmer uses its actual rear cannon instead of the lower front lantern')
 check(ForgeVehicleArt.anchors('skimmer').pivot_local.x>0.,'Legacy unmounted registration contract remains unchanged')
 var skimmer_split:=bank.split_pose('skimmer',0,0)
 var skimmer_source: Dictionary=known.types.skimmer.frames[0][0]
 var collar_pixel:=Vector2i(61-int(skimmer_source.bounds[0])+2,74-int(skimmer_source.bounds[1])+2)
 check(skimmer_split.hull.texture.get_image().get_pixelv(collar_pixel).a>.5,'Skimmer retains its original brass mounting collar on the hull')
 check(not Geometry2D.is_point_in_polygon(Vector2(61.5,74.5),skimmer_split.source_polygon),'Rotating tube does not remove the fixed mounting collar')
 check(absf(float(skimmer.barrel_length)-32.*float(skimmer.scale))<.001,'Measured skimmer tube pivots inside its collar at58,74 and ends at26,74')
 var shell:=bank.pose('shell',0,0);var high:=bank.hull_pose('shell',0,0,200.)
 check(absf(float(high.size.y)/float(shell.size.y)-200./float(known.target_height))<.001,'Explicit target-height scaling remains shared with hull and muzzle')
 print('RESULT: ',checks,' original turret checks, ',failures,' failures');quit(1 if failures else 0)
