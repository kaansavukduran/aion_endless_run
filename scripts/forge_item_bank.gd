class_name ForgeItemBank
extends RefCounted
const DATA=preload("res://assets/FORGE-ITEMS-PROVENANCE.json")
const SUPPLIES=preload("res://assets/campaign-field-supplies.png")
const SUPPLY_CELLS := {"heal":0,"repair":1,"shield":2}
static var cache: Dictionary={}

func pose(kind: String) -> Dictionary:
	if cache.has(kind):return cache[kind]
	if SUPPLY_CELLS.has(kind):
		var cel:=AtlasTexture.new()
		cel.atlas=SUPPLIES
		cel.region=Rect2(float(SUPPLY_CELLS[kind])*32.,0.,32.,32.)
		cel.filter_clip=true
		cache[kind]={"texture":cel,"offset":Vector2(-24.,-24.),"size":Vector2(48.,48.),"source_key":"campaign-field-supplies","kind":kind}
		return cache[kind]
	assert(DATA.data.frames.has(kind),"Unknown actual item: "+kind)
	var source:=RunnerSourcePixels.sheet("res://assets/forge-items.png")
	var f: Dictionary=DATA.data.frames[kind]
	var b: Array=f.bounds
	var isolated:=Image.create_empty(int(b[2]-b[0])+4,int(b[3]-b[1])+4,false,Image.FORMAT_RGBA8)
	for run in f.runs:
		isolated.blit_rect(source,Rect2i(int(f.rect[0]+run[1]),int(f.rect[1]+run[0]),int(run[2]),1),Vector2i(int(run[1]-b[0])+2,int(run[0]-b[1])+2))
	var factor: float=f.scale
	cache[kind]={"texture":ImageTexture.create_from_image(isolated),"offset":-Vector2(isolated.get_size())*.5*factor,"size":isolated.get_size()*factor,"source_key":"forge-items","kind":kind}
	return cache[kind]
