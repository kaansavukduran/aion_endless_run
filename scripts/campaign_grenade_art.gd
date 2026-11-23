class_name CampaignGrenadeArt
extends RefCounted

## Original sheet: one grenade and seven authored ignition/fire/smoke cels.
## A bounded process-wide cache; visual playback never changes fuse or damage.
const SHEET: Texture2D=preload('res://assets/m1_grenade_fx.png')
const LIFE := .72
const OBJECT_CELL_SIZE := CampaignGrenade.PROP_DISPLAY_CELL
const GRENADE_PIVOT := CampaignGrenade.PROP_CENTER_PIXEL/CampaignGrenade.PROP_SOURCE_CELL
const CEL_ENDS := [.045,.095,.18,.28,.41,.56,.72]
static var cells: Dictionary={}

static func _cell(index: int) -> AtlasTexture:
 if cells.has(index):return cells[index]
 var texture:=AtlasTexture.new();texture.atlas=SHEET
 var side: float=float(SHEET.get_width())/4.
 texture.region=Rect2(Vector2(index%4,index/4)*side,Vector2(side,side))
 texture.filter_clip=true;cells[index]=texture;return texture

static func draw_bomb(view,bomb: Dictionary) -> void:
 var p: Vector2=view.at(Vector2(bomb.p))
 var reduced: bool=view.host.options.reduced_motion or not view.host.motion_enabled
 var angle: float=0. if reduced else float(bomb.get('angle',0.))
 # The same held/flying dimensions prevent a size pop at release.
 view.draw_set_transform(p,angle,Vector2.ONE)
 view.draw_texture_rect(_cell(0),Rect2(-GRENADE_PIVOT*OBJECT_CELL_SIZE,Vector2.ONE*OBJECT_CELL_SIZE),false)
 view.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 for contact in bomb.get('contacts',[]):
  if Vector2(contact.normal)!=Vector2.UP:continue
  var age: float=float(contact.age);var fade: float=1.-age/.24
  var center: Vector2=view.at(Vector2(contact.p))
  # Grounded chips spread only from an observed physical floor contact.
  for i in 5:
   var side: float=-1. if i%2 else 1.
   var offset:=Vector2(side*(4.+float(i)*2.+age*35.),-4.-sin(age/.24*PI)*(3.+i))
   view.draw_rect(Rect2((center+offset).round(),Vector2(3,2)),Color(.67,.60,.49,fade*.7))

static func draw_held(view) -> void:
 var w=view.world
 if w.grenade_throw.is_empty() or bool(w.grenade_throw.get('released',false)):return
 if M1HeroArt.has(str(w.character)):
  var metrics: Dictionary=M1CombatArt.metrics(w)
  if bool(metrics.get('grenade_embedded',false)):return
 # Same anchor feeds this image and the simulation release object.
 var p: Vector2=view.at(Vector2(w.player)+CampaignGrenade.hand_offset(w))
 view.draw_texture_rect(_cell(0),Rect2(p-GRENADE_PIVOT*OBJECT_CELL_SIZE,Vector2.ONE*OBJECT_CELL_SIZE),false)

static func draw_blast(view,blast: Dictionary) -> void:
 var age: float=float(blast.age)
 var cel:=6
 for i in CEL_ENDS.size():
  if age<float(CEL_ENDS[i]):cel=i;break
 var reduced: bool=view.host.options.reduced_motion or not view.host.motion_enabled
 # Remain a recognizable impact and smoke cue with less brightness/motion.
 # Fire reads as an impact; smoke must leave threats and support legible.
 var opacity: float=[1.,.95,.80,.52,.40,.28,.18][cel]
 var tint:=Color(1,1,1,opacity*(.68 if reduced else 1.))
 var size:=Vector2(320,320)
 view.draw_texture_rect(_cell(cel+1),Rect2(view.at(Vector2(blast.p))-size*.5,size),false,tint)
