class_name M1SupportArt
extends RefCounted
const DATA=preload('res://assets/M1-SUPPORT-PROVENANCE.json')
var image: Image
var cache: Dictionary={}
func pose(key: String,frame: int=0) -> Dictionary:
 var id: String=key+':'+str(posmod(frame,6) if key in ['spider-walk','spider-burst'] else 0)
 assert(DATA.data.frames.has(id),'Unknown support art: '+id)
 if cache.has(id):return cache[id]
 if image==null:
  image=load('res://'+str(DATA.data.path)).get_image()
  if image.is_compressed():image.decompress()
 var f: Dictionary=DATA.data.frames[id];var b: Array=f.bounds
 var isolated:=Image.create_empty(int(b[2])-int(b[0])+4,int(b[3])-int(b[1])+4,false,Image.FORMAT_RGBA8)
 for run in f.runs:isolated.blit_rect(image,Rect2i(int(f.rect[0])+int(run[1]),int(f.rect[1])+int(run[0]),int(run[2]),1),Vector2i(int(run[1])-int(b[0])+2,int(run[0])-int(b[1])+2))
 var scale: float=f.scale
 cache[id]={'texture':ImageTexture.create_from_image(isolated),'offset':Vector2(float(b[0])-float(f.origin[0])-2.,float(b[1])-float(f.origin[1])-2.)*scale,'size':isolated.get_size()*scale,'source_key':'m1-support','source_frame':frame,'source_row':key}
 return cache[id]
