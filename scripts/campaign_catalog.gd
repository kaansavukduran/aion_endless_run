class_name CampaignCatalog
extends RefCounted
const DATA=preload("res://assets/CAMPAIGN-EXPANSION-PROVENANCE.json")
const KEEPERS_WALK=preload("res://assets/KEEPERS-WALK-PROVENANCE.json")
# 0.39.0: Process-wide shared caches prevent duplicate WebAssembly RAM/CPU spikes on retries & scene switches.
static var images: Dictionary={}
static var cache: Dictionary={}
func pose(key: String,row: int,frame: int) -> Dictionary:
	var a: Dictionary=DATA.data.atlases[key]
	var walking:=key=="rescue-npcs" and frame>=6
	if walking:a=KEEPERS_WALK.data
	var source_frame: int=posmod(frame-6,6) if walking else clampi(frame,0,a.frames[row].size()-1)
	var image_key: String="keepers-walk" if walking else key
	var id:=key+":"+str(row)+":"+str(frame)
	if cache.has(id):return cache[id]
	var sheet_image: Image=RunnerSourcePixels.sheet("res://"+str(a.path))
	var f: Dictionary=a.frames[row][source_frame];var b: Array=f.bounds
	var result:=Image.create_empty(int(b[2])-int(b[0])+4,int(b[3])-int(b[1])+4,false,Image.FORMAT_RGBA8)
	for run in f.runs:result.blit_rect(sheet_image,Rect2i(int(f.rect[0])+int(run[1]),int(f.rect[1])+int(run[0]),int(run[2]),1),Vector2i(int(run[1])-int(b[0])+2,int(run[0])-int(b[1])+2))
	var scale: float=a.scales[row]
	cache[id]={"texture":ImageTexture.create_from_image(result),"offset":Vector2(float(b[0])-float(f.origin[0])-2.,float(b[1])-float(f.origin[1])-2.)*scale,"size":result.get_size()*scale,"source_key":key,"source_row":row,"source_frame":frame}
	return cache[id]
