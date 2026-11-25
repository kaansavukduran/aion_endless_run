class_name M1DamageArt
extends RefCounted

## Ayça's own elemental/collapse drawings; archived male rabbit art stays intact.
const DATA=preload("res://assets/M1-DAMAGE-PROVENANCE.json")
const ACTIONS := ["freeze","fire","impact","faceplant"]
var source: Image
var cache: Dictionary={}

static func has(hero: String) -> bool:
	return hero=="rabbit"

static func metrics(hero: String,action: String,frame: int=0) -> Dictionary:
	assert(has(hero),"Unregistered damage hero: "+hero)
	assert(action in ACTIONS,"Unregistered damage action: "+action)
	var row: int=ACTIONS.find(action);frame=clampi(frame,0,5)
	var atlas: Dictionary=DATA.data.atlas
	var f: Dictionary=atlas.frames[row][frame];var b: Array=f.bounds
	var factor: float=f.scale
	var origin:=Vector2(f.origin[0],f.origin[1])
	var face:=Vector2(f.face_landmark[0],f.face_landmark[1]) if f.face_visible else origin
	return {"offset":(Vector2(float(b[0])-2.,float(b[1])-2.)-origin)*factor,"size":Vector2(float(b[2]-b[0])+4.,float(b[3]-b[1])+4.)*factor,"height":float(f.body_bounds[3]-f.body_bounds[1])*factor,"source_scale":factor,"source_key":"m1-damage-ayca","source_row":row,"source_frame":frame,"face_local":(face-origin)*factor,"face_visible":bool(f.face_visible),"head_size":float(atlas.calibration.world_head_size) if f.face_visible else 0.,"ground_contact":bool(f.ground_contact),"gun_embedded":false}

func pose(hero: String,action: String,frame: int=0) -> Dictionary:
	var result: Dictionary=metrics(hero,action,frame)
	var row: int=result.source_row;frame=int(result.source_frame)
	var key:=str(row)+":"+str(frame)
	if cache.has(key):return cache[key]
	var atlas: Dictionary=DATA.data.atlas
	if source==null:
		source=RunnerSourcePixels.sheet("res://"+str(atlas.path))
	var f: Dictionary=atlas.frames[row][frame];var b: Array=f.bounds
	var isolated:=Image.create_empty(int(b[2]-b[0])+4,int(b[3]-b[1])+4,false,Image.FORMAT_RGBA8)
	for run in f.runs:
		isolated.blit_rect(source,Rect2i(int(f.rect[0])+int(run[1]),int(f.rect[1])+int(run[0]),int(run[2]),1),Vector2i(int(run[1])-int(b[0])+2,int(run[0])-int(b[1])+2))
	result.texture=ImageTexture.create_from_image(isolated)
	cache[key]=result
	return cache[key]
