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
 for hero in ['aion','sheep']:
  for action in M1HeroActionArt.CONTACT_ACTIONS+M1HeroActionArt.REACTION_ACTIONS+M1HeroActionArt.TUNNEL_ACTIONS:
   var source: String='m1-action-'+hero+('_contact' if action in M1HeroActionArt.CONTACT_ACTIONS else ('_tunnel' if action in M1HeroActionArt.TUNNEL_ACTIONS else '_redraw'))
   var hashes: Dictionary={}
   for frame in 6:
    var pose: Dictionary=bank.pose(hero,action,frame)
    var image: Image=pose.texture.get_image()
    var signature:=image.get_data().hex_encode().sha256_text()
    var used:=image.get_used_rect()
    var bottom: float=pose.offset.y+float(used.end.y)*pose.source_scale
    var grip:=Vector2i(((Vector2(pose.grip_local)-Vector2(pose.offset))/float(pose.source_scale)).round())
    check(pose.source_key==source and pose.source_frame==frame and not hashes.has(signature),'The new action resolves to every distinct authored cel: '+hero+'/'+action)
    check(absf(bottom)<.01 and absf(pose.face_local.x-14.)<.001 and image.get_pixelv(grip).a>.5,'Actual opaque sole and hand pixels use fixed registrations: '+hero+'/'+action)
    if action in M1HeroActionArt.TUNNEL_ACTIONS:
     check(-(pose.offset.y+float(used.position.y)*pose.source_scale)<54.5,'New visible tunnel cel stays below the real ceiling including draw rounding: '+hero)
    hashes[signature]=true
  var w:=AionCampaignWorld.new();w.begin(hero);w.state='playing'
  w.enemies.clear();w.hazards.clear();w.invulnerable=0.
  w.spawn_enemy('gnome',w.player.x+55.,w.player.y,501)
  w.attack_press();w.attack_release()
  check(M1CombatArt.body_spec(w).action=='melee' and not w.enemies[-1].defeated,'Context attack anticipates with the new unarmed sequence: '+hero)
  for tick in 9:w.step(1./60.)
  check(M1CombatArt.body_spec(w).frame==3 and w.enemies[-1].defeated,'The authored strike cel coincides with real close damage: '+hero)
  w.enemies.clear()
  w.npcs=[{'id':'cut-sprite-test','x':w.player.x+72.,'y':w.player.y,'freed':false,'secret':'','variant':0}]
  w.attack_press();w.attack_release()
  check(M1CombatArt.body_spec(w).action=='rescue_cut' and not w.npcs[0].freed,'The normal rescue input selects the dedicated reach: '+hero)
  for tick in 19:w.step(1./60.)
  check(M1CombatArt.body_spec(w).frame==3 and w.npcs[0].freed,'The new knife motion reaches the normal rope contact event: '+hero)
  for tick in 19:w.step(1./60.)
  w.invulnerable=0.
  w.damage_player()
  check(M1CombatArt.body_spec(w).action=='hurt','Real damage selects the redrawn standing reaction: '+hero)
  w.hp=1;w.flock=1;w.invulnerable=0.;w.damage_player()
  check(w.state=='dying' and M1CombatArt.body_spec(w).action=='death','Fatal hit plays the separate collapse sequence: '+hero)
  var seen: Dictionary={}
  for tick in 16:
   var pose:=M1CombatArt.body_spec(w)
   seen[pose.frame]=true
   check(pose.action=='death','Dying hero keeps its own collapse sequence: '+hero)
   w.step(.05)
  check(seen.size()==6 and M1CombatArt.body_spec(w).frame==5,'Collapse reaches every frame, including the final grounded pose: '+hero)
 # The original four keep their precise canonical registration above. The
 # two new animals use their own independently authored source anatomy.
 for hero in MissionHeroArt.HEROES:
  check(ART.has(hero),'New hero enters the shared authoritative body renderer: '+hero)
  var neutral: Dictionary=ART.metrics(hero,'idle_fire',0)
  for action in MissionHeroArt.actions(hero):
   var clip: Dictionary=ART.clip_spec(hero,action)
   var first: Dictionary=ART.metrics(hero,action,0)
   for frame in int(clip.frames):
    var m: Dictionary=ART.metrics(hero,action,frame)
    var direct: Dictionary=MissionHeroArt.metrics(hero,action,frame)
    check(m.source_key==direct.source_key and m.source_row==direct.source_row and m.source_frame==direct.source_frame,'Shared renderer resolves exact new-animal source identity: '+hero+'/'+action)
    check(str(m.source_key).begins_with('mission-hero-'+hero),'New hero never reuses an old hero silhouette or wrong animal: '+hero)
    check(is_equal_approx(float(m.source_scale),float(first.source_scale)),'Every cel keeps fixed authored source scale: '+hero+'/'+action)
    var pose: Dictionary=bank.pose(hero,action,frame)
    check(pose.offset.is_equal_approx(m.offset) and pose.size.is_equal_approx(m.size) and pose.grip_local.is_equal_approx(m.grip_local) and pose.face_local.is_equal_approx(m.face_local),'New hero rendered pixels use the exact physical hand and mouth registration: '+hero)
    var im: Image=pose.texture.get_image();var clean:=true
    for x in im.get_width():clean=clean and im.get_pixel(x,0).a==0. and im.get_pixel(x,im.get_height()-1).a==0.
    for y in im.get_height():clean=clean and im.get_pixel(0,y).a==0. and im.get_pixel(im.get_width()-1,y).a==0.
    check(clean,'New hero has independent transparent texture gutter: '+hero+'/'+action)
    check(Vector2(im.get_size()).is_equal_approx(Vector2(m.size)/float(m.source_scale)),'New hero pixel size and rendered size use one source scale: '+hero)
    var source: Dictionary=MissionHeroArt.DATA.data.atlases[str(m.atlas_key)].rows[int(m.source_row)][int(m.source_frame)]
    if bool(m.ground_contact):check(absf(float(source.rect[1]+source.rect[3])-float(source.origin[1]))<.01,'New hero connected feet share grounded actor baseline: '+hero+'/'+action)
    var grip_pixel:=Vector2i((Vector2(m.grip_local)-Vector2(m.offset))/float(m.source_scale))
    check(grip_pixel.x>=0 and grip_pixel.y>=0 and grip_pixel.x<im.get_width() and grip_pixel.y<im.get_height() and im.get_pixelv(grip_pixel).a>.5,'New hero measured hand is an actual opaque body pixel: '+hero+'/'+action+'/'+str(frame))
  var low: Dictionary=ART.metrics(hero,'crouch_fire',0)
  check(low.height<neutral.height*.80 and low.face_local.y>neutral.face_local.y+12.,'New animal folds legs and lowers head in its own crouch art: '+hero)
 print('RESULT: ',checks,' M1 hero art checks, ',failures,' failures');quit(1 if failures else 0)
