extends SceneTree

## Actual World movement/fire inputs plus isolated authored-cel registration.
## This is a deterministic simulation regression, not a physical-input test.
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;printerr('FAIL: '+message)
func fresh(hero: String) -> AionCampaignWorld:
 var w:=AionCampaignWorld.new();w.begin(hero);w.state='playing'
 w.enemies.clear();w.npcs.clear();w.objects.clear();w.hazards.clear();w.gates.clear();w.pickups.clear();w.crates.clear()
 return w
func _initialize() -> void:call_deferred('run')
func run() -> void:
 var bank:=M1HeroArt.new()
 for hero in M1HeroArt.HEROES:
  for action in M1HeroArt.EXTRA_ACTIONS:
   var first:=M1HeroArt.metrics(hero,action,0);var hashes: Array=[]
   for frame in 6:
    var pose:=bank.pose(hero,action,frame);var im: Image=pose.texture.get_image()
    check(absf(float(pose.source_scale)-float(first.source_scale))<.000001,'One fixed scale for '+hero+'/'+action)
    check(absf(Vector2(pose.face_local).x-14.)<.00001,'Anatomical face-X registration '+hero+'/'+action)
    check(pose.offset==M1HeroArt.metrics(hero,action,frame).offset,'Physics and drawn source share exact registration')
    var clean:=true
    for x in im.get_width():clean=clean and im.get_pixel(x,0).a==0. and im.get_pixel(x,im.get_height()-1).a==0.
    for y in im.get_height():clean=clean and im.get_pixel(0,y).a==0. and im.get_pixel(im.get_width()-1,y).a==0.
    check(clean,'Independent transparent cel gutter prevents neighbor bleed')
    var hand_pixel: Vector2=(Vector2(pose.grenade_hand_local)-Vector2(pose.offset))/float(pose.source_scale)
    var hand_seen:=false
    for dx in range(-2,3):
     for dy in range(-2,3):
      var point:=Vector2i(hand_pixel.round())+Vector2i(dx,dy)
      if Rect2i(Vector2i.ZERO,im.get_size()).has_point(point):hand_seen=hand_seen or im.get_pixelv(point).a>=.75
    check(hand_seen,'Measured hand socket touches the isolated opaque body '+hero+'/'+action+'/'+str(frame))
    var hash: String=im.get_data().hex_encode().sha256_text();check(not hashes.has(hash),'Six distinct newly drawn poses '+hero+'/'+action);hashes.append(hash)
    if action in ['walk_back','crouch_walk_back']:
     var old:=bank.pose(hero,'crouch_walk' if action=='crouch_walk_back' else 'walk',frame)
     check(hash!=old.texture.get_image().get_data().hex_encode().sha256_text(),'Backstep source is distinct from original forward gait')
   check(M1HeroArt.clip_spec(hero,action).frames==6,'Clip metadata agrees with imported source')
  for side in [-1,1]:
   for crouched in [false,true]:
    var w:=fresh(hero);w.player.x=900.;w.facing=side;w.aim_direction=Vector2(side,0.)
    w.move_axis=Vector2(-side,1. if crouched else 0.)
    var start:=w.player;var visited: Dictionary={};var last_distance: float=w.walk_distance
    for tick in 80:
     w.step(1./60.)
     # Use the actual fire operation repeatedly, including its recoil timer.
     if tick%13==0:w.attack_press()
     var spec:=M1CombatArt.body_spec(w)
     if w.grounded() and absf(w.velocity.x)>1.:
      check(spec.action==('crouch_walk_back' if crouched else 'walk_back'),'Opposed real velocity selects true backstep '+hero)
      check(spec.mirror==side,'Backward motion preserves aimed body side '+hero)
      visited[spec.frame]=true
      check(w.walk_distance>=last_distance,'Distance-driven phase survives firing');last_distance=w.walk_distance
      var placement:=M1CombatArt.placement(w);var metrics:=M1HeroArt.metrics(hero,spec.action,spec.frame)
      check(Vector2(placement.grip).is_equal_approx(Vector2(metrics.grip_local)*Vector2(side,1.)),'Gun grip follows same aimed cel exactly once')
    check(visited.size()==6,'Real backward travel reaches all six cels despite firing '+hero)
    check((w.player.x-start.x)*side< -30.,'Simulation truly travels opposite the aim '+hero)
    # Releasing movement must select stationary pose, not a held backwalk cel.
    w.move_axis=Vector2.ZERO;w.step(.02)
    check(M1CombatArt.body_spec(w).action=='idle_fire','Backwalk transitions back to standing')
  # Near-vertical aim uses the already chosen facing, not tiny noisy X values.
  var w:=fresh(hero);w.velocity.x=-120.;w.facing=1
  for tiny in [-.09,0.,.09]:
   w.aim_direction=Vector2(tiny,-1.).normalized()
   check(M1CombatArt.body_spec(w).action=='walk_back' and M1CombatArt.body_spec(w).mirror==1,'Vertical aim deadzone keeps a stable aim side')
 # Throw timing is shared with the simulation release; no embedded object
 # remains in the release cel even when a long frame skips the final windup.
 for hero in M1HeroArt.HEROES:
  for action in ['grenade_throw','crouch_grenade_throw']:
   check(not M1HeroArt.metrics(hero,action,CampaignGrenade.frame_at(.16)).grenade_embedded,'Release cel has open empty throwing hand')
   check(CampaignGrenade.frame_at(.159)==2 and CampaignGrenade.frame_at(.16)==3,'Visual cel changes at exact projectile release')
 # Every confined-space cel must fit the actual unchanged55px opening.
 for hero in M1HeroArt.HEROES:
  for action in M1HeroActionArt.TUNNEL_ACTIONS:
   var scale: float=M1HeroArt.metrics(hero,action,0).source_scale
   var hashes: Array=[]
   for frame in 6:
    var pose:=bank.pose(hero,action,frame);var im: Image=pose.texture.get_image()
    check(float(pose.source_scale)==scale,'Tunnel clip keeps one fixed source scale')
    var visible_height: float=-(Vector2(pose.offset).y+2.*scale)
    check(visible_height<=CampaignRoutes.LOWER_FLOOR-CampaignRoutes.CRAWL_CEILING,'Complete tunnel silhouette fits real55px opening '+hero+'/'+action+'/'+str(frame))
    var opaque: Rect2i=im.get_used_rect()
    var rounded_top: float=CampaignRoutes.LOWER_FLOOR+Vector2(pose.offset).round().y+float(opaque.position.y)*float(pose.size.y)/float(im.get_height())
    check(rounded_top>=CampaignRoutes.CRAWL_CEILING,'Actual rounded draw offset and first opaque texel clear roof '+hero+'/'+action+'/'+str(frame))
    var hash: String=im.get_data().hex_encode().sha256_text();check(not hashes.has(hash),'Independent compact poses '+hero+'/'+action);hashes.append(hash)
    var hp: Vector2=(Vector2(pose.grenade_hand_local)-Vector2(pose.offset))/scale;var seen:=false
    for dx in range(-2,3):
     for dy in range(-2,3):
      var point:=Vector2i(hp.round())+Vector2i(dx,dy)
      if Rect2i(Vector2i.ZERO,im.get_size()).has_point(point):seen=seen or im.get_pixelv(point).a>=.75
    check(seen,'Compact hand attaches to opaque drawn palm '+hero+'/'+action+'/'+str(frame))
  for side in [-1,1]:
   var w:=fresh(hero);w.load_section('fork_one');w.state='playing';w.player=Vector2(1000.,CampaignRoutes.LOWER_FLOOR);w.aim_direction=Vector2(side,0);w.facing=side
   for mode in ['forward','backward','idle','throw']:
    w.move_axis=Vector2((side if mode=='forward' else -side) if mode in ['forward','backward'] else 0.,1.);w.velocity.x=w.move_axis.x*98.7
    w.grenade_throw.clear()
    if mode=='throw':w.grenade_throw={'elapsed':.16,'direction':side,'released':true}
    var spec:=M1CombatArt.body_spec(w)
    check(spec.action=={'forward':'tunnel_walk','backward':'tunnel_walk_back','idle':'tunnel_idle','throw':'tunnel_throw'}[mode],'Actual underpier selector uses specific compact clip '+hero+'/'+mode)
    check(w.crouching() and w.grounded(),'Compact art is selected on actual90px support')
 # Existing death fallback stays compact under a solid ceiling; this is
 # a pose adaptation, not a newly authored death animation.
 for hero in M1HeroArt.HEROES:
  var w:=fresh(hero);w.load_section('fork_one');w.state='playing';w.player=Vector2(1000.,CampaignRoutes.LOWER_FLOOR)
  w.hp=1;w.flock=1;w.shield=0;w.invulnerable=0.;w.damage_player('enemy')
  check(w.state=='dying','Real fatal damage enters confined death state '+hero)
  for state in ['dying','dead']:
   if state=='dead':
    for tick in 30:w.step(.05)
   check(w.state==state,'Actual death timer reaches expected state '+hero)
   var spec:=M1CombatArt.body_spec(w)
   check(spec.action=='tunnel_idle' and spec.frame==5,'Confined death retains existing compact fallback '+hero)
   var pose:=bank.pose(hero,spec.action,spec.frame);var im: Image=pose.texture.get_image();var opaque:=im.get_used_rect()
   var top: float=w.player.y+Vector2(pose.offset).round().y+float(opaque.position.y)*float(pose.size.y)/float(im.get_height())
   check(w.grounded() and top>=CampaignRoutes.CRAWL_CEILING,'Actual dying/dead opaque body remains on support and below roof '+hero)
 # Resolved zero travel at the world boundary is a stationary body, never a
 # permanently held stride from a nonzero desired input velocity.
 for hero in AionCampaignWorld.HEROES:
  var w:=fresh(hero);w.player.x=35.;w.aim_direction=Vector2.RIGHT;w.move_axis=Vector2.LEFT
  w.step(.05)
  check(is_zero_approx(w.velocity.x) and w.player.x==35.,'Blocked movement reports actual zero travel: '+hero)
  check(M1CombatArt.body_spec(w).action in ['idle','idle_fire'],'Blocked backstep returns to stationary art: '+hero)
 # A contextual close punch must not replace moving legs with a planted
 # idle drawing. Exercise the real attack, anticipation and physics path.
 for hero in AionCampaignWorld.HEROES:
  for airborne in [false,true]:
   var w:=fresh(hero);w.player=Vector2(400.,-70. if airborne else 0.)
   w.aim_direction=Vector2.RIGHT;w.move_axis=Vector2.LEFT
   w.spawn_enemy('crow' if airborne else 'gnome',460.,w.player.y,0)
   w.attack_press();w.step(.05)
   check(w.melee_time>0. and w.velocity.x< -1.,'Actual close attack and backward travel coexist: '+hero)
   check(M1CombatArt.body_spec(w).action==('air_fire' if airborne else 'walk_back'),'Close punch retains actual moving/airborne legs: '+hero)
 print('RESULT: %d backward-walk/action checks, %d failures' % [checks,failures]);quit(1 if failures else 0)
