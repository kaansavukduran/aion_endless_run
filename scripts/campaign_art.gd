class_name AionCampaignArt
extends RefCounted
const META = preload("res://assets/ARCADE-MACHINES-PROVENANCE.json")
const SOURCE = preload("res://assets/arcade-machines.png")
var source: Image
var cache: Dictionary = {}
const MELEE = preload("res://assets/CAMPAIGN-MELEE-PROVENANCE.json")
var melee_sources: Dictionary = {}

func melee(hero: String, frame: int) -> Dictionary:
	var key := hero+str(frame)
	if cache.has(key): return cache[key]
	var data: Dictionary = MELEE.data.heroes[hero]
	if not melee_sources.has(hero):
		# Heroes that share one melee sheet share one read-only decoded copy.
		for other in melee_sources:
			if str(MELEE.data.heroes[other].path)==str(data.path):melee_sources[hero]=melee_sources[other];break
	if not melee_sources.has(hero):
		var image := RunnerSourcePixels.image("res://"+str(data.path))
		if image.is_compressed(): image.decompress()
		image.convert(Image.FORMAT_RGBA8); melee_sources[hero] = image
	var f: Dictionary = data.frames[clampi(frame,0,5)]
	var b: Array = f.bounds
	var image := Image.create_empty(int(b[2])-int(b[0])+4,int(b[3])-int(b[1])+4,false,Image.FORMAT_RGBA8)
	for run in f.runs:
		image.blit_rect(melee_sources[hero],Rect2i(int(f.rect[0])+int(run[1]),int(f.rect[1])+int(run[0]),int(run[2]),1),Vector2i(int(run[1])-int(b[0])+2,int(run[0])-int(b[1])+2))
	var factor: float = data.scale
	cache[key] = {"texture":ImageTexture.create_from_image(image),"offset":Vector2(float(b[0])-float(f.origin[0])-2.,float(b[1])-float(f.origin[1])-2.)*factor,"size":image.get_size()*factor}
	return cache[key]

func pose(row: int, frame: int) -> Dictionary:
	frame = posmod(frame,6)
	var key := Vector2i(row,frame)
	if cache.has(key): return cache[key]
	if source == null:
		source = RunnerSourcePixels.image(SOURCE.resource_path)
		if source.is_compressed(): source.decompress()
		source.convert(Image.FORMAT_RGBA8)
	var f: Dictionary = META.data.frames[row][frame]
	var b: Array = f.bounds
	var image := Image.create_empty(int(b[2])-int(b[0])+4,int(b[3])-int(b[1])+4,false,Image.FORMAT_RGBA8)
	for run in f.runs:
		image.blit_rect(source,Rect2i(int(f.rect[0])+int(run[1]),int(f.rect[1])+int(run[0]),int(run[2]),1),Vector2i(int(run[1])-int(b[0])+2,int(run[0])-int(b[1])+2))
	var scale: float = META.data.scales[row]
	cache[key] = {"texture":ImageTexture.create_from_image(image),"offset":Vector2(float(b[0])-float(f.origin[0])-2.,float(b[1])-float(f.origin[1])-2.)*scale,"size":image.get_size()*scale,"source_row":row,"source_frame":frame}
	return cache[key]
