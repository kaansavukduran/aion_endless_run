class_name M1CombatArt
extends RefCounted

# Source grip and bore positions within each isolated original weapon icon.
const SOCKETS := {
 'pistol':[.72,.80,.03,.25], 'heavy':[.20,.70,.98,.45],
 'scatter':[.32,.48,.95,.22], 'arc':[.27,.70,.96,.35],
 'beam':[.22,.72,.95,.38], 'disc':[.30,.67,.69,.43],
 'harpoon':[.13,.73,.98,.30], 'seeker':[.39,.76,.975,.245],
 'spore':[.11,.83,.695,.45], 'trap':[.39,.76,.975,.245], 'nova':[.26,.80,.97,.46]
}
# Source-local pixel/atlas coordinates, semantic grip notes and held-only masks
# are recorded in assets/M1-HELD-WEAPONS.json. A trap is a launcher mode; its
# pickup illustration is a puck, so held art uses the existing seeker chassis.
static func display_source(kind: String) -> String:
 return M1HeldWeaponBank.display_source(kind)
static func body_facing(w) -> int:
 return (-1 if w.aim_direction.x<0. else 1) if absf(w.aim_direction.x)>.1 else int(w.facing)
static func backstep_frame(action: String,frame: int) -> int:
 # A planted foot travels toward the aim side while the body retreats.
 # The registered stride cels run in the opposite order on contact.
 return 5-frame if action in ["walk_back","crouch_walk_back","tunnel_walk_back","tongue_walk_back","tongue_crouch_walk_back"] else frame

static func body_spec(w) -> Dictionary:
 if w.character not in M1HeroArt.HEROES and M1HeroArt.has(w.character):return M1HeroArt._provider().body_spec(w)
 var action: String='idle_fire';var frame:=0
 var crouched: bool=w.crouching() or w.charging
 if crouched:
  action=('crouch_walk_back' if w.velocity.x*body_facing(w)<-1. else 'crouch_walk') if absf(w.velocity.x)>1. and not w.charging else 'crouch_fire'
  frame=posmod(int(w.walk_distance/(94. if action=='crouch_walk_back' else 110.)*6.),6) if action in ['crouch_walk','crouch_walk_back'] else (clampi(int((.18-w.shot_flash)/.18*6.),0,5) if w.shot_flash>0. else 0)
 elif not w.grounded():
  # Repeated shots animate their effects without restarting the jump pose.
  action='air_fire';frame=RunnerWorld.flight_frame_for(w.velocity.y,w.air_time,6)
 elif absf(w.velocity.x)>1.:
  action='walk_back' if w.velocity.x*body_facing(w)<-1. else 'walk';frame=posmod(int(w.walk_distance/(132. if action=='walk_back' else 174.)*6.),6)
 elif w.shot_flash>0.:
  frame=clampi(int((.18-w.shot_flash)/.18*6.),0,5)
 if w.rescue_time>0. or (w.melee_time>0. and absf(w.velocity.x)<=1. and w.grounded()):
  action='crouch_fire' if crouched else 'idle_fire';frame=clampi(int((CampaignRescue.CUT_SECONDS-w.rescue_time)/CampaignRescue.CUT_SECONDS*6.),0,5) if w.rescue_time>0. else clampi(int((.28-w.melee_time)/.28*6.),0,5)
 if not crouched and w.grounded():
  if w.rescue_time>0. and M1HeroActionArt.supports(w.character,'rescue_cut'):
   action='rescue_cut'
  elif w.melee_time>0. and absf(w.velocity.x)<=1. and M1HeroActionArt.supports(w.character,'melee'):
   action='melee';frame=clampi(int((.28-w.melee_time)/.28*6.),0,5)
 var throw_value=w.get('grenade_throw')
 var throw_state: Dictionary=throw_value if throw_value is Dictionary else {}
 var throwing: bool=not throw_state.is_empty()
 if throwing:
  action='crouch_grenade_throw' if crouched else 'grenade_throw';frame=CampaignGrenade.frame_at(float(throw_state.elapsed))
 if CampaignRoutes.low_ceiling(w) and M1HeroActionArt.supports(w.character,'tunnel_idle'):
  if throwing:action='tunnel_throw'
  elif absf(w.velocity.x)>1.:action='tunnel_walk_back' if w.velocity.x*body_facing(w)<-1. else 'tunnel_walk'
  else:action='tunnel_idle'
 elif action=='idle_fire' and w.hurt_time>0. and w.shot_flash<=0. and w.rescue_time<=0. and w.melee_time<=0. and M1HeroActionArt.supports(w.character,'hurt'):
  action='hurt';frame=clampi(int((.3-w.hurt_time)/.3*6.),0,5)
 if w.state in ['dying','dead','respawn_pending','continue_offer']:
  if CampaignRoutes.low_ceiling(w):action='tunnel_idle';frame=5
  elif w.state=='dying' and w.death_time<CampaignLives.impact_duration(w.death_cause) and M1HeroActionArt.supports(w.character,'hurt'):
   action='hurt';frame=clampi(int(w.death_time/CampaignLives.impact_duration(w.death_cause)*4.),0,3)
  elif M1HeroActionArt.supports(w.character,'death'):
   action='death';frame=CampaignLives.collapse_frame(w)
  else:action='crouch_fire';frame=5
 if not w.pose_motion_enabled and not throwing:frame=5 if action=='death' else 0
 else:frame=backstep_frame(action,frame)
 return {'hero':w.character,'action':action,'frame':frame,'mirror':int(throw_state.direction) if throwing else body_facing(w),'key':'m1-body'}
static func metrics(w) -> Dictionary:
 var s:=body_spec(w)
 return M1HeroArt.metrics(str(s.hero),str(s.action),int(s.frame))
static func weapon_metrics(kind: String,crouched: bool=false) -> Dictionary:
 if not SOCKETS.has(kind):kind='pistol'
 var source_kind:=display_source(kind)
 var registration: Dictionary=M1HeldWeaponBank.registration(kind)
 if registration.has('path'):
  var canvas: Array=registration.canvas_size
  var dimensions:=Vector2(float(canvas[0]),float(canvas[1]))
  var factor: float=float(registration.display_width)/dimensions.x
  var grip_pixel:=Vector2(float(registration.grip_pixel[0]),float(registration.grip_pixel[1]))
  var muzzle_pixel:=Vector2(float(registration.muzzle_pixel[0]),float(registration.muzzle_pixel[1]))
  if int(registration.source_facing)<0:
   grip_pixel.x=dimensions.x-1.-grip_pixel.x;muzzle_pixel.x=dimensions.x-1.-muzzle_pixel.x
  var grip:=grip_pixel*factor
  return {'kind':kind,'display_source':source_kind,'held_source':str(registration.path),'size':dimensions*factor,'offset':-grip,'muzzle':muzzle_pixel*factor-grip,'factor':factor,'grip_pixel':grip_pixel,'muzzle_pixel':muzzle_pixel}
 var source: Dictionary=ForgeItemBank.DATA.data.frames[source_kind]
 var b: Array=source.bounds
 var dimensions:=Vector2(float(b[2]-b[0])+4.,float(b[3]-b[1])+4.)
 var width: float=28. if kind=='pistol' else 38.
 var factor: float=width/dimensions.x
 var uv: Array=SOCKETS[kind]
 var grip_pixel:=Vector2(2.+(dimensions.x-4.)*float(uv[0]),2.+(dimensions.y-4.)*float(uv[1]))
 var muzzle_pixel:=Vector2(2.+(dimensions.x-4.)*float(uv[2]),2.+(dimensions.y-4.)*float(uv[3]))
 if int(M1HeldWeaponBank.DATA.data.weapons[kind].source_facing)<0:
  # Pixel indices mirror around width-1. Keep the drawn socket at its actual
  # sampled pixel centre instead of reflecting only the projectile direction.
  grip_pixel.x=dimensions.x-1.-grip_pixel.x;muzzle_pixel.x=dimensions.x-1.-muzzle_pixel.x
 var grip:=grip_pixel*factor
 var muzzle:=muzzle_pixel*factor-grip
 return {'kind':kind,'display_source':source_kind,'size':dimensions*factor,'offset':-grip,'muzzle':muzzle,'factor':factor,'grip_pixel':grip_pixel,'muzzle_pixel':muzzle_pixel}
static func placement(w) -> Dictionary:
 var body:=metrics(w);var spec:=body_spec(w)
 var direction: int=int(spec.mirror)
 var aim: Vector2=Vector2(w.aim_direction).normalized() if Vector2(w.aim_direction).length_squared()>.01 else Vector2(direction,0.)
 var displayed: String=str(w.shot_weapon) if w.shot_flash>0. and not str(w.shot_weapon).is_empty() else str(w.weapon)
 var weapon:=weapon_metrics(displayed,w.crouching())
 var grip: Vector2=Vector2(body.grip_local)*Vector2(direction,1)
 var muzzle: Vector2=grip+(Vector2(weapon.muzzle)*Vector2(1,direction)).rotated(aim.angle())
 # Keep the handle attached to the measured hand. A low grounded actor
 # cannot fire through its supporting floor; use the horizontal crouch shot.
 # Airborne/downward shots off an elevated ledge retain the requested angle.
 var floor: float=w.floor_at(w.player.x+muzzle.x)
 if w.grounded() and is_finite(floor) and w.player.y+muzzle.y>=floor-1.:
  aim=Vector2(direction,0.)
  muzzle=grip+(Vector2(weapon.muzzle)*Vector2(1,direction)).rotated(aim.angle())

 return {'grip':grip,'muzzle':muzzle,'angle':aim.angle(),'mirror_y':direction,'weapon':weapon,'aim':aim}

static func runner_spec(w) -> Dictionary:
 var action: String='walk';var frame: int=posmod(int(w.travel_distance()/174.*6.),6)
 if w.state=='ready':action='idle_fire';frame=0
 elif w.charging:action='crouch_fire';frame=clampi(int(w.charge_ratio()*6.),0,5)
 elif w.adventure.ducking(w):action='crouch_walk';frame=posmod(int(w.time*10.),6)
 elif w.y<0.:
  action='air_fire';frame=RunnerWorld.flight_frame_for(w.velocity,w.air_time,6)
 if w.state in ['ice','fire','bonk','fall','over']:action='crouch_fire';frame=5
 if not w.pose_motion_enabled:frame=0
 return {'hero':w.character,'action':action,'frame':frame}
static func runner_attachment(w) -> Dictionary:
 var s:=runner_spec(w);var body:=M1HeroArt.metrics(w.character,str(s.action),int(s.frame));var weapon:=weapon_metrics('pistol')
 var grip: Vector2=body.grip_local
 return {'grip':grip,'muzzle':grip+Vector2(weapon.muzzle),'weapon':weapon}

static func weapon_texture(items: ForgeItemBank,kind: String) -> Texture2D:
 return M1HeldWeaponBank.texture(items,kind)
