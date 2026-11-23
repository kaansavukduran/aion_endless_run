class_name CampaignGrenade
extends RefCounted

## Simulation owns release, fuse, contacts and damage. Drawing never emits events.
const WINDUP := .16
const DURATION := .42
const FUSE := 1.15
const RADIUS := 9.
const GRAVITY := 780.
const PHYSICS_SLICE := 1. / 120.
# First atlas cell source pixels: the palm grasps the lower opaque shell.
# One rigid registration feeds held rendering and the released physics center.
const PROP_SOURCE_CELL := 443.5
const PROP_DISPLAY_CELL := 52.
const PROP_CENTER_PIXEL := Vector2(238.,241.5)
const PROP_GRIP_PIXEL := Vector2(238.,327.)
const PALM_TO_CENTER := (PROP_CENTER_PIXEL-PROP_GRIP_PIXEL)/PROP_SOURCE_CELL*PROP_DISPLAY_CELL

static func can_press(w) -> bool:
 if w.state!='playing' or w.grenades<=0 or w.grenade_time>0. or w.mount_transition!='' or not w.grenade_throw.is_empty():return false
 if w.hurt_time>0. or w.rescue_time>0. or w.melee_time>0.:return false
 return not MissionHeroAbilities.compact(w)

static func press(w) -> bool:
 if not can_press(w):return false
 var direction: int=(-1 if w.aim_direction.x<0. else 1) if absf(w.aim_direction.x)>.15 else int(w.facing)
 w.grenade_throw={'elapsed':0.,'duration':DURATION,'release_at':WINDUP,'phase':'windup','direction':direction,'aim':Vector2(w.aim_direction),'released':false}
 return true

static func cancel(w,clear_projectiles: bool=false) -> void:
 # Unreleased grenades were never consumed. A released object remains independent.
 w.grenade_throw.clear()
 if clear_projectiles:w.bombs.clear()

static func frame_at(elapsed: float) -> int:
 var starts: Array=M1HeroActionArt.DATA.data.playback.grenade_throw.frame_starts
 var frame:=0
 for i in starts.size():
  if elapsed>=starts[i]:frame=i
 return frame

static func hand_offset(w) -> Vector2:
 var throw_state: Dictionary=w.grenade_throw
 var facing: int=int(throw_state.get('direction',w.facing))
 var elapsed: float=float(throw_state.get('elapsed',0.))
 var frame: int=frame_at(elapsed)
 # Shared authored hand anchors; hero metadata can supply the exact body grip.
 var anchors: Array[Vector2]=[Vector2(-13,-53),Vector2(-8,-71),Vector2(26,-65),Vector2(34,-51),Vector2(21,-47),Vector2(21,-47)]
 var offset: Vector2=anchors[frame]
 if M1HeroArt.has(str(w.character)):
  # The actual body selector also owns route-specific low tunnel variants.
  # Physics samples that same pose instead of maintaining a second clip map.
  var spec: Dictionary=M1CombatArt.body_spec(w)
  var body: Dictionary=M1HeroArt.metrics(str(w.character),str(spec.action),int(spec.frame))
  offset=Vector2(body.get('grenade_hand_local',body.grip_local))
 elif w.crouching():offset.y+=28.
 return (offset+PALM_TO_CENTER)*Vector2(facing,1.)

static func step(w,dt: float) -> void:
 if dt<=0. or w.state!='playing':return
 # Existing bombs get this entire tick; a newly released one gets only the
 # portion after release. A coarse update cannot advance its fuse too early.
 for bomb in w.bombs.duplicate():_advance_bomb(w,bomb,dt)
 if not w.bombs.is_empty():w.bombs=w.bombs.filter(func(b):return not bool(b.get('exploded',false)))
 if w.state!='playing':cancel(w);return
 if not w.grenade_throw.is_empty() and MissionHeroAbilities.compact(w):cancel(w)
 if w.grenade_throw.is_empty():return
 var action: Dictionary=w.grenade_throw
 var old_elapsed: float=float(action.elapsed)
 action.elapsed=old_elapsed+dt
 if not bool(action.released) and float(action.elapsed)>=WINDUP:
  if w.grenades<=0:cancel(w);return
  action.released=true
  # Release samples the current actor root, retaining its captured throw side.
  # Force the precise release pose even if this tick skips several visual cels.
  var saved: float=float(action.elapsed);action.elapsed=WINDUP
  var origin: Vector2=Vector2(w.player)+hand_offset(w);action.elapsed=saved
  var direction: int=int(action.direction)
  var bomb: Dictionary={'kind':'grenade','p':origin,'v':Vector2(direction*330.+w.velocity.x*.2,-430.),'age':0.,'color':w.COLORS[w.character],'angle':0.,'spin':direction*7.,'contacts':[],'contact_wait':0.,'exploded':false}
  w.grenades-=1;w.grenade_time=.55;w.bombs.append(bomb);w.pending_events.append('grenade')
  _advance_bomb(w,bomb,maxf(0.,float(action.elapsed)-maxf(old_elapsed,WINDUP)))
  if bool(bomb.exploded):w.bombs.erase(bomb)
 action.phase='windup' if float(action.elapsed)<WINDUP else ('release' if float(action.elapsed)<.24 else 'recover')
 if float(action.elapsed)>=DURATION:w.grenade_throw.clear()

static func _advance_bomb(w,bomb: Dictionary,dt: float) -> void:
 if bool(bomb.get('exploded',false)):return
 var remaining: float=minf(dt,maxf(0.,FUSE-float(bomb.age)))
 while remaining>.000001:
  var tick: float=minf(PHYSICS_SLICE,remaining);remaining-=tick
  bomb.age=float(bomb.age)+tick;bomb.contact_wait=maxf(0.,float(bomb.get('contact_wait',0.))-tick)
  var contacts: Array=bomb.get('contacts',[])
  for contact in contacts:contact.age=float(contact.age)+tick
  bomb.contacts=contacts.filter(func(c):return float(c.age)<.24)
  var old: Vector2=bomb.p
  var velocity: Vector2=Vector2(bomb.v)+Vector2(0,GRAVITY*tick)
  var next: Vector2=old+velocity*tick
  var normal:=Vector2.ZERO
  # Platforms are drawn solid slabs: their underside and sides affect bombs.
  var solids: Array[Rect2]=[]
  for platform in w.platforms:
   if not w.disabled_platforms.has(platform.position.x):solids.append(platform)
  if str(w.section)=='fork_one':solids.append(CampaignRoutes.PIER)
  for rect in solids:
   var grown: Rect2=rect.grow(RADIUS)
   if old.x>grown.position.x+.0001 and old.x<grown.end.x-.0001 and old.y>grown.position.y+.0001 and old.y<grown.end.y-.0001:
    # An extended throw hand can meet a nearby wall. Resolve its nearest
    # solid face instead of letting a just-released bomb cross that wall.
    var distances: Array[float]=[absf(old.x-grown.position.x),absf(old.x-grown.end.x),absf(old.y-grown.position.y),absf(old.y-grown.end.y)]
    var face: int=distances.find(distances.min())
    normal=[Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN][face]
    if face==0:next.x=grown.position.x
    elif face==1:next.x=grown.end.x
    elif face==2:next.y=grown.position.y
    else:next.y=grown.end.y
    break
   if grown.has_point(next):
    if old.y<=grown.position.y:next.y=grown.position.y;normal=Vector2.UP
    elif old.y>=grown.end.y:next.y=grown.end.y;normal=Vector2.DOWN
    elif old.x<=grown.position.x:next.x=grown.position.x;normal=Vector2.LEFT
    else:next.x=grown.end.x;normal=Vector2.RIGHT
    break
  # Real ground support follows route floors, including pits and lower channels.
  if normal==Vector2.ZERO:
   var floor: float=w.floor_at(next.x,old.y+RADIUS)
   var floor_normal:=CampaignGround.normal(w,next.x)
   if CampaignGround.has_floor(floor) and velocity.dot(floor_normal)<0.:
    var previous_floor: float=w.floor_at(old.x,old.y+RADIUS)
    var previous_normal:=CampaignGround.normal(w,old.x)
    var centre_y:=floor+RADIUS/floor_normal.y
    if old.y<=previous_floor+RADIUS/previous_normal.y+.01 and next.y>=centre_y:
     next.y=centre_y;normal=floor_normal
  # Return edge of the lower channel is a real vertical ledge.
  if normal==Vector2.ZERO and CampaignRoutes.is_fork(str(w.section)) and (str(w.section)=='fork_one' or CampaignRoutes.hatch_open(w)):
   var ledge: float=CampaignRoutes.lower_start(w)+RADIUS
   if old.x>=ledge and next.x<ledge and old.y+RADIUS>0.:
    next.x=ledge;normal=Vector2.RIGHT
  if normal!=Vector2.ZERO:
   var impact: float=absf(velocity.dot(normal))
   if velocity.dot(normal)<0.:velocity=velocity.bounce(normal)*.51
   if normal.y<-.7:
    velocity.x*=.76
    if absf(velocity.y)<62.:velocity.y=0.
   bomb.spin=float(bomb.get('spin',7.))*.72
   # Only physical energetic contacts make sound/dust; settling is silent.
   if impact>90. and float(bomb.contact_wait)<=0.:
    bomb.contacts.append({'p':next-normal*RADIUS,'normal':normal,'age':0.,'strength':minf(1.,impact/430.)})
    bomb.contact_wait=.09;w.pending_events.append('grenade_bounce')
  bomb.p=next;bomb.v=velocity;bomb.angle=float(bomb.get('angle',0.))+float(bomb.get('spin',7.))*tick
 if float(bomb.age)>=FUSE-.00001:
  bomb.exploded=true
  var before: int=w.blasts.size()
  w.explode(bomb)
  # Existing explode remains the only damage owner and retains its balance.
  if w.blasts.size()>before:
   var blast: Dictionary=w.blasts[before]
   blast.kind='grenade';blast.life=.72
  if not w.pending_events.is_empty() and w.pending_events.back()=='blast':w.pending_events[w.pending_events.size()-1]='grenade_blast'
