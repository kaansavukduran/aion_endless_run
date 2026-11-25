class_name CampaignEffectsArt
extends RefCounted
const DATA=preload('res://assets/CAMPAIGN-EFFECTS.json')
const LEGACY=['crow','gnome','moth','slime','beetle','wisp','drone','seed','warden']
# 0.41.0: Process-wide shared effects & legacy death cache.
static var images: Dictionary={}
static var cache: Dictionary={}
func pose(key: String,row: int,frame: int) -> Dictionary:
 var id:=key+str(row)+str(frame)
 if cache.has(id):return cache[id]
 var bank: Dictionary=DATA.data.banks[key];var f: Dictionary=bank.frames[row][frame];var b: Array=f.bounds
 var sheet_image: Image=RunnerSourcePixels.sheet('res://'+str(bank.path))
 var result:=Image.create_empty(int(b[2])-int(b[0])+4,int(b[3])-int(b[1])+4,false,Image.FORMAT_RGBA8)
 for run in f.runs:result.blit_rect(sheet_image,Rect2i(int(f.rect[0])+int(run[1]),int(f.rect[1])+int(run[0]),int(run[2]),1),Vector2i(int(run[1])-int(b[0])+2,int(run[0])-int(b[1])+2))
 var scale: float=bank.scales[row]
 cache[id]={'texture':ImageTexture.create_from_image(result),'offset':Vector2(float(b[0])-float(f.origin[0])-2.,float(b[1])-float(f.origin[1])-2.)*scale,'size':result.get_size()*scale,'source_key':key,'source_row':row,'source_frame':frame}
 return cache[id]
func flag(frame: int) -> Dictionary:return pose('checkpoint-flags',0,posmod(frame,4))
func death(kind: String,frame: int) -> Dictionary:return pose('legacy-deaths',LEGACY.find(kind),clampi(frame,0,5))
