class_name M1HeroActionArt
extends RefCounted

## Additional drawn cels. Approved base sheets remain immutable.
const DATA=preload('res://assets/M1-HERO-ACTIONS.json')
const ACTIONS := ['walk_back','crouch_walk_back','grenade_throw','crouch_grenade_throw']
const TUNNEL_ACTIONS := ['tunnel_walk_back','tunnel_walk','tunnel_throw','tunnel_idle']
const REACTION_ACTIONS := ['hurt','death']
const CONTACT_ACTIONS := ['melee','rescue_cut']
static var images: Dictionary={}
static var cache: Dictionary={}

static func supports(hero: String,action: String='walk_back') -> bool:
 if action in CONTACT_ACTIONS:return DATA.data.atlases.has(hero+'_contact')
 if action in REACTION_ACTIONS:return DATA.data.atlases.has(hero+'_redraw')
 return DATA.data.atlases.has(hero+'_tunnel') if action in TUNNEL_ACTIONS else DATA.data.atlases.has(hero) and action in ACTIONS

static func clip_spec(_hero: String,action: String) -> Dictionary:
 var clip: Dictionary=DATA.data.playback[action]
 return {'frames':int(clip.frames),'fps':float(clip.frames)/float(clip.get('seconds',.66)),'loop':bool(clip.loop),'world_distance':float(clip.get('world_distance',0.))}

static func _atlas_key(hero: String,action: String,frame: int) -> String:
 if action in TUNNEL_ACTIONS:return hero+'_tunnel'
 if action in CONTACT_ACTIONS:return hero+'_contact'
 if DATA.data.atlases.has(hero+'_redraw'):return hero+'_redraw'
 if action=='grenade_throw' and frame in [1,2]:return hero+'_empty'
 return hero+'_crouch' if action in ['crouch_walk_back','crouch_grenade_throw'] else hero

static func _source_row(key: String,action: String) -> int:
 if action in TUNNEL_ACTIONS:return TUNNEL_ACTIONS.find(action)
 if action in CONTACT_ACTIONS:return CONTACT_ACTIONS.find(action)
 if key.ends_with('_redraw'):return int(DATA.data.redraw_rows[action])
 if action in ['crouch_walk_back','crouch_grenade_throw']:return 1 if action=='crouch_grenade_throw' else 0
 return ACTIONS.find(action)

static func metrics(hero: String,action: String,frame: int=0) -> Dictionary:
 assert(supports(hero,action),'Unknown additional hero action')
 var key: String=_atlas_key(hero,action,frame)
 var row: int=_source_row(key,action);frame=clampi(frame,0,5)
 var f: Dictionary=DATA.data.atlases[key].frames[row][frame]
 var scale: float=f.scale;var origin:=Vector2(float(f.origin[0]),float(f.origin[1]));var b: Array=f.bounds
 var hand: Vector2=(Vector2(float(f.grip[0]),float(f.grip[1]))-origin)*scale
 var face_width: float = float(f.face_reference_width) if f.has('face_reference_width') else float(f.face_patch[2])
 return {'offset':(Vector2(float(b[0])-2.,float(b[1])-2.)-origin)*scale,'size':Vector2(float(b[2]-b[0])+4.,float(b[3]-b[1])+4.)*scale,'grip_local':hand,'grenade_hand_local':hand,'grenade_embedded':bool(f.grenade_embedded),'face_local':(Vector2(float(f.face_landmark[0]),float(f.face_landmark[1]))-origin)*scale,'height':float(f.body_bounds[3]-f.body_bounds[1])*scale,'source_key':'m1-action-'+key,'source_row':row,'source_frame':frame,'source_scale':scale,'ground_contact':true,'gun_embedded':false,'body_only':true,'head_size':face_width*scale,'face_foreground':M1HeroArt.face_foreground(f) if hero=='aion' else Rect2()}

static func pose(hero: String,action: String,frame: int=0) -> Dictionary:
 var key: String=_atlas_key(hero,action,frame)
 var row: int=_source_row(key,action);frame=clampi(frame,0,5)
 var id:=hero+':'+action+':'+str(frame)
 if cache.has(id):return cache[id]
 var atlas: Dictionary=DATA.data.atlases[key]
 var sheet_image: Image=RunnerSourcePixels.sheet('res://'+str(atlas.path))
 var f: Dictionary=atlas.frames[row][frame];var b: Array=f.bounds
 var cel:=Image.create_empty(int(b[2])-int(b[0])+4,int(b[3])-int(b[1])+4,false,Image.FORMAT_RGBA8)
 for run in RunnerSourcePixels.runs(f):
  cel.blit_rect(sheet_image,Rect2i(int(f.rect[0])+int(run[1]),int(f.rect[1])+int(run[0]),int(run[2]),1),Vector2i(int(run[1])-int(b[0])+2,int(run[0])-int(b[1])+2))
 var result:=metrics(hero,action,frame);result.texture=ImageTexture.create_from_image(cel);cache[id]=result
 return result
