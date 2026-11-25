class_name M1HeroArt
extends RefCounted

## Immutable body layers. Weapon position comes from the same measured grip.
const DATA=preload("res://assets/M1-HEROES-PROVENANCE.json")
const HEROES := ["aion","sheep","rabbit","eren"]
const ACTIONS := ["walk","idle_fire","air_fire","crouch_walk","crouch_fire"]
# 0.40.0: Process-wide shared cache avoids re-decompressing hero atlases per view/preview.
static var images: Dictionary={}
static var cache: Dictionary={}

const EXTRA_ACTIONS := ['walk_back','crouch_walk_back','grenade_throw','crouch_grenade_throw']
static var mission_provider: Script

static func _provider() -> Script:
	if mission_provider==null and ResourceLoader.exists('res://scripts/mission_hero_art.gd'):
		mission_provider=load('res://scripts/mission_hero_art.gd')
	return mission_provider

static func has(hero: String) -> bool:
	if hero in HEROES:return true
	var provider:=_provider()
	return provider!=null and provider.owns(hero)

static func clip_spec(hero: String,action: String) -> Dictionary:
	if hero not in HEROES:return _provider().clip_spec(hero,action)
	if M1HeroActionArt.supports(hero,action):return M1HeroActionArt.clip_spec(hero,action)
	var clip: Dictionary=DATA.data.playback[action]
	return {'frames':int(clip.frames),'fps':float(clip.frames)/float(clip.get('seconds',.75)),'loop':bool(clip.get('loop',false))}

static func face_foreground(frame: Dictionary) -> Rect2:
	if not frame.has("face_patch"):return Rect2()
	var patch: Array=frame.face_patch
	var bounds: Array=frame.bounds
	# The tracked patch ends above the chin. Include the jaw and its outline
	# while staying above the hand that grips the weapon on the front layer.
	return Rect2(float(patch[0])-float(bounds[0])-2.,float(patch[1])-float(bounds[1])-1.,float(patch[2])+12.,float(patch[3])+12.)

static func metrics(hero: String, action: String, frame: int=0) -> Dictionary:
	if hero not in HEROES:return _provider().metrics(hero,action,frame)
	if M1HeroActionArt.supports(hero,action):return M1HeroActionArt.metrics(hero,action,frame)
	assert(has(hero),"Unknown playable body: "+hero)
	assert(action in ACTIONS,"Unsupported body action: "+action)
	var spec: Array=DATA.data.runtime_rows[hero][action]
	var key: String=str(spec[0]);var row: int=int(spec[1]);frame=clampi(frame,0,5)
	var f: Dictionary=DATA.data.atlases[key].frames[row][frame]
	var scale: float=f.scale;var origin:=Vector2(float(f.origin[0]),float(f.origin[1]));var b: Array=f.bounds
	return {"offset":(Vector2(float(b[0])-2.,float(b[1])-2.)-origin)*scale,"size":Vector2(float(b[2]-b[0])+4.,float(b[3]-b[1])+4.)*scale,"grip_local":(Vector2(float(f.grip[0]),float(f.grip[1]))-origin)*scale,"face_local":(Vector2(float(f.face_landmark[0]),float(f.face_landmark[1]))-origin)*scale,"height":float(f.body_bounds[3]-f.body_bounds[1])*scale,"source_key":"m1-body-"+key,"source_row":row,"source_frame":frame,"source_scale":scale,"ground_contact":bool(f.ground_contact),"gun_embedded":false,"body_only":true,"face_foreground":face_foreground(f) if hero=="aion" else Rect2()}

func pose(hero: String, action: String, frame: int=0) -> Dictionary:
	if hero not in HEROES:return _provider().pose(hero,action,frame)
	if M1HeroActionArt.supports(hero,action):return M1HeroActionArt.pose(hero,action,frame)
	assert(has(hero),"Unknown playable body: "+hero)
	assert(action in ACTIONS,"Unsupported body action: "+action)
	var spec: Array=DATA.data.runtime_rows[hero][action]
	var key: String=str(spec[0]);var row: int=int(spec[1])
	frame=clampi(frame,0,5)
	var id:=key+":"+str(row)+":"+str(frame)
	if cache.has(id):return cache[id]
	var atlas: Dictionary=DATA.data.atlases[key]
	var sheet_image: Image=RunnerSourcePixels.sheet("res://"+str(atlas.path))
	var f: Dictionary=atlas.frames[row][frame];var b: Array=f.bounds
	var image:=Image.create_empty(int(b[2])-int(b[0])+4,int(b[3])-int(b[1])+4,false,Image.FORMAT_RGBA8)
	for run in f.runs:
		image.blit_rect(sheet_image,Rect2i(int(f.rect[0])+int(run[1]),int(f.rect[1])+int(run[0]),int(run[2]),1),Vector2i(int(run[1])-int(b[0])+2,int(run[0])-int(b[1])+2))
	var result: Dictionary=metrics(hero,action,frame)
	result.texture=ImageTexture.create_from_image(image)
	cache[id]=result
	return cache[id]
