extends SceneTree
const ART=preload('res://scripts/m1_hero_art.gd')
var checks:=0
var failures:=0
func check(ok: bool,message: String):
 checks+=1
 if not ok:failures+=1;printerr('FAIL: '+message)
func _initialize():call_deferred('run')
func run():
 var bank=ART.new()
 for hero in ART.HEROES:
  for action in ART.ACTIONS:
   var first: Dictionary=ART.metrics(hero,action,0)
   var map: Array=ART.DATA.data.runtime_rows[hero][action]
   var raw: Dictionary=ART.DATA.data.atlases[map[0]].frames[map[1]][0]
   var base_map: Array=ART.DATA.data.runtime_rows[hero]['idle_fire']
   var base_raw: Dictionary=ART.DATA.data.atlases[base_map[0]].frames[base_map[1]][0]
   check(absf(float(raw.face_patch[2])*float(raw.scale)-float(base_raw.face_patch[2])*float(base_raw.scale))<.5,'Alternate source uses the same calibrated whole-face physical scale')
   var hashes: Array=[]
   for frame in 6:
    var m: Dictionary=ART.metrics(hero,action,frame)
    if checks<2:check(bank.images.is_empty(),'Physics metrics never load PNG or allocate GPU textures before pose')
    check(absf(m.face_local.x-14.)<.0001,'Whole anatomical face stays at the same actor-relative X')
    check(absf(m.source_scale-first.source_scale)<.000001,'Source scale is constant throughout the actual clip')
    check(m.grip_local.x>0. and m.grip_local.y<0.,'Measured empty-hand grip is in front of the right-facing body and above sole')
    check(m.size.x>20. and m.size.y>20. and m.height>20.,'Complete readable body, not a blank replacement')
    var pose: Dictionary=bank.pose(hero,action,frame)
    check(pose.offset.is_equal_approx(m.offset) and pose.size.is_equal_approx(m.size) and pose.grip_local.is_equal_approx(m.grip_local),'Rendered pose uses exactly the physics metrics')
    var im: Image=pose.texture.get_image();var clean:=true
    for x in im.get_width():clean=clean and im.get_pixel(x,0).a==0. and im.get_pixel(x,im.get_height()-1).a==0.
    for y in im.get_height():clean=clean and im.get_pixel(0,y).a==0. and im.get_pixel(im.get_width()-1,y).a==0.
    check(clean,'Independent two-pixel texture gutter prevents neighboring-frame bleed')
    if m.ground_contact:
     var a: Array=ART.DATA.data.runtime_rows[hero][action]
     var f: Dictionary=ART.DATA.data.atlases[a[0]].frames[a[1]][frame]
     check(absf(float(f.body_bounds[3]-f.origin[1])*float(f.scale))<.0001,'Actual connected feet are on the common floor')
    else:
     var neutral: Dictionary=ART.metrics(hero,'idle_fire',0)
     check(absf(m.face_local.y-neutral.face_local.y)<.0001,'Air body uses the same head/body reference without artificial bob')
    var hash: String=im.get_data().hex_encode().sha256_text();check(not hashes.has(hash),'Each sequential cel is independently drawn, not a copied duplicate');hashes.append(hash)
  var stand: Dictionary=ART.metrics(hero,'idle_fire',0)
  var crouch: Dictionary=ART.metrics(hero,'crouch_fire',0)
  check(crouch.height<stand.height*.80,'Crouch lowers visible anatomy rather than merely changing a collider')
  check(crouch.face_local.y>stand.face_local.y+12.,'Crouched head is physically lower while the face scale stays registered')
 check(not ART.has('wolf') and not ART.has('owl'),'Assist characters are not assigned playable body layers')
 print('RESULT: ',checks,' M1 hero art checks, ',failures,' failures');quit(1 if failures else 0)
