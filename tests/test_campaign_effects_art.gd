extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,message: String):
 checks+=1
 if not ok:failures+=1;printerr('FAIL: '+message)
func _initialize():call_deferred('run')
func run():
 var bank:=CampaignEffectsArt.new();var shots:=CampaignProjectileArt.new()
 for row in CampaignEffectsArt.LEGACY.size():
  var kind: String=CampaignEffectsArt.LEGACY[row];var scale: float=bank.DATA.data.banks['legacy-deaths'].scales[row];var hashes:={}
  for frame in 6:
   var pose:=bank.death(kind,frame);var image: Image=pose.texture.get_image();hashes[hash(image.get_data())]=true
   check(image.get_used_rect().size.x>3 and image.get_used_rect().size.y>3,'Each actual death cel retains visible body/debris '+kind)
   check(is_equal_approx(pose.size.x/image.get_width(),scale),'Fixed source scale through collapse '+kind)
   check(pose.source_row==row and pose.source_frame==frame,'Each enemy uses its own real registered death row')
  check(hashes.size()==6,'Six distinct death drawings, not duplicate/faded poses '+kind)
 var originals:=AionCampaignArt.new()
 for pair in [['drone',0],['seed',2],['warden',6]]:
  var original: Dictionary=originals.pose(int(pair[1]),0);var pixels: Image=original.texture.get_image();var used: Rect2i=pixels.get_used_rect();var factor: float=original.size.y/pixels.get_height()
  var reference: Dictionary=bank.DATA.data.references[str(pair[0])]
  check(absf(float(reference.height)-used.size.y*factor)<.001,'Death registration uses actual rendered robot height, not source pixels '+str(pair[0]))
  check(absf(float(reference.foot)-(float(original.offset.y)+used.end.y*factor))<.001,'Robot reference uses world offset and scaled source feet '+str(pair[0]))
 for frame in 4:
  var f:=bank.flag(frame);check(f.texture.get_image().get_pixel(0,0).a==0.,'Flag has transparent gutter')
  check(f.texture.get_image().get_used_rect().size.y>60,'Flag contains full pole, cloth and base')
  check(absf(f.offset.y+f.size.y-2.*bank.DATA.data.banks['checkpoint-flags'].scales[0])<.01,'Flag base stays on actual ground')
 for kind in CampaignWeapons.SPECS:
  if kind=='trap':continue
  var p:=shots.pose(kind,str(CampaignWeapons.SPECS[kind].colour),0);var pixels: Image=p.texture.get_image();var colours:={}
  for y in pixels.get_height():
   for x in pixels.get_width():
    var c:=pixels.get_pixel(x,y)
    if c.a>.9:colours[c.to_html()]=true
  check(colours.size()>=4,'Projectile has readable outline/core/material colours '+kind)
  check(shots.pose(kind,str(CampaignWeapons.SPECS[kind].colour),0).texture==p.texture,'Projectile art is cached, no per-frame pixel reconstruction')
 print('RESULT: %d campaign effects art checks, %d failures'%[checks,failures]);quit(1 if failures else 0)
