class_name CampaignCatalog
extends RefCounted
const DATA=preload("res://assets/CAMPAIGN-EXPANSION-PROVENANCE.json")
var images: Dictionary={}
var cache: Dictionary={}
func pose(key: String,row: int,frame: int) -> Dictionary:
	var a: Dictionary=DATA.data.atlases[key];frame=clampi(frame,0,a.frames[row].size()-1)
	var id:=key+":"+str(row)+":"+str(frame)
	if cache.has(id):return cache[id]
	if not images.has(key):
		var texture: Texture2D=load("res://"+str(a.path));var image:=texture.get_image()
		if image.is_compressed():image.decompress()
		image.convert(Image.FORMAT_RGBA8);images[key]=image
	var f: Dictionary=a.frames[row][frame];var b: Array=f.bounds
	var result:=Image.create_empty(int(b[2])-int(b[0])+4,int(b[3])-int(b[1])+4,false,Image.FORMAT_RGBA8)
	for run in f.runs:result.blit_rect(images[key],Rect2i(int(f.rect[0])+int(run[1]),int(f.rect[1])+int(run[0]),int(run[2]),1),Vector2i(int(run[1])-int(b[0])+2,int(run[0])-int(b[1])+2))
	var scale: float=a.scales[row]
	cache[id]={"texture":ImageTexture.create_from_image(result),"offset":Vector2(float(b[0])-float(f.origin[0])-2.,float(b[1])-float(f.origin[1])-2.)*scale,"size":result.get_size()*scale,"source_key":key,"source_row":row,"source_frame":frame}
	return cache[id]
