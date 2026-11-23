extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,label: String):
 checks+=1
 if not ok:failures+=1;printerr('FAIL: '+label)
func _initialize():call_deferred('run')
func run():
 var items:=ForgeItemBank.new()
 var pickup_bytes: Dictionary={}
 for kind in M1CombatArt.SOCKETS:
  var source_kind: String=M1CombatArt.display_source(kind)
  pickup_bytes[source_kind]=items.pose(source_kind).texture.get_image().get_data().duplicate()
 for kind in M1CombatArt.SOCKETS:
  var m:=M1CombatArt.weapon_metrics(kind)
  var held: Image=M1CombatArt.weapon_texture(items,kind).get_image()
  var registration: Dictionary=M1HeldWeaponBank.registration(kind)
  var variant: bool=registration.has('path')
  var raw: Image=RunnerSourcePixels.image('res://'+str(registration.path)) if variant else null
  var source: Image=items.pose(str(m.display_source)).texture.get_image()
  if variant:
   check(held.get_size()==Vector2i(int(registration.canvas_size[0]),int(registration.canvas_size[1])),'Dedicated held canvas matches registered source: '+kind)
   check(FileAccess.get_sha256('res://'+str(registration.path))==str(registration.source_sha256),'Dedicated source PNG matches recorded SHA exactly')
   check(str(m.held_source)==str(registration.path),'Measured source is the actual dedicated held variant')
  else:check(held.get_size()==source.get_size(),'Held cleanup retains full registered canvas: '+kind)
  check(str(m.display_source)==str(registration.display_source),'Drawn source and measured source match: '+kind)
  var grip: Vector2=m.grip_pixel;var tip: Vector2=m.muzzle_pixel
  check(held.get_pixelv(Vector2i(grip.round())).a>.78,'Actual hand grip is physical opaque handle/stock: '+kind)
  check(held.get_pixelv(Vector2i(tip.round())).a>.78,'Actual emitter nose/aperture is opaque: '+kind)
  var ink:=0;var source_ink:=0;var unchanged:=true
  for y in held.get_height():
   for x in held.get_width():
    var pixel:=held.get_pixel(x,y)
    if pixel.a>0.:
     ink+=1
     if variant:
      var bounds: Array=registration.bounds
      unchanged=unchanged and pixel==raw.get_pixel(x+int(bounds[0])-2,y+int(bounds[1])-2)
     else:unchanged=unchanged and pixel==source.get_pixel(held.get_width()-1-x if int(registration.source_facing)<0 else x,y)
    if not variant and source.get_pixel(x,y).a>0.:source_ink+=1
  check(unchanged,'Held art uses only the exact registered source RGBA, with no runtime painted replacements: '+kind)
  if variant:
   check(ink>1000 and tip.x>grip.x+held.get_width()*.6 and tip.y<grip.y,'Dedicated pistol has a clear forward emitter and angled lower handle')
  elif kind in ['scatter','disc','spore']:
   check(source_ink-ink>1000,'Pickup-only ammo/projectile/example plume is removed while held: '+kind)
  else:check(source_ink==ink,'Uncontaminated original weapon keeps every source pixel: '+kind)
  check(source.get_data()==pickup_bytes[str(m.display_source)],'Cleaning/flipping a held weapon never mutates cached pickup illustration: '+kind)
 check(M1HeldWeaponBank.VARIANTS.data.weapons.size()==1 and M1HeldWeaponBank.VARIANTS.data.weapons.has('pistol'),'Only pistol receives a dedicated variant; other ten weapon registrations stay intact')
 check(M1CombatArt.display_source('trap')=='seeker','Walking spider uses actual launcher body, not a puck posing as a gun')
 check(M1CombatArt.weapon_metrics('trap').size==M1CombatArt.weapon_metrics('seeker').size,'Spider launcher dimensions follow actual displayed weapon')
 check(FileAccess.get_sha256('res://assets/forge-items.png')==str(M1HeldWeaponBank.DATA.data.source_sha256),'Original source PNG remains byte-for-byte unchanged')
 print('RESULT: ',checks,' held weapon art checks, ',failures,' failures');quit(1 if failures else 0)
