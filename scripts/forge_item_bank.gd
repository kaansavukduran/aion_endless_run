class_name ForgeItemBank
extends RefCounted
const DATA=preload("res://assets/FORGE-ITEMS-PROVENANCE.json")
# 0.40.0: Process-wide shared item atlas & crop cache.
static var source: Image
static var cache: Dictionary={}

func pose(kind: String) -> Dictionary:
	assert(DATA.data.frames.has(kind),"Unknown actual item: "+kind)
	if cache.has(kind):return cache[kind]
	if source==null:
		source=RunnerSourcePixels.image("res://assets/forge-items.png")
		if source.is_compressed():source.decompress()
		source.convert(Image.FORMAT_RGBA8)
	var f: Dictionary=DATA.data.frames[kind]
	var b: Array=f.bounds
	var isolated:=Image.create_empty(int(b[2]-b[0])+4,int(b[3]-b[1])+4,false,Image.FORMAT_RGBA8)
	for run in f.runs:
		isolated.blit_rect(source,Rect2i(int(f.rect[0]+run[1]),int(f.rect[1]+run[0]),int(run[2]),1),Vector2i(int(run[1]-b[0])+2,int(run[0]-b[1])+2))
	var factor: float=f.scale
	cache[kind]={"texture":ImageTexture.create_from_image(isolated),"offset":-Vector2(isolated.get_size())*.5*factor,"size":isolated.get_size()*factor,"source_key":"forge-items","kind":kind}
	return cache[kind]
