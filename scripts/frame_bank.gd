class_name RunnerFrameBank
extends RefCounted

const META = preload("res://assets/FRONTIER-PROVENANCE.json")
const MOTION = preload("res://assets/MOTION-PROVENANCE.json")
var images := {}
var frames := {}

func descriptor(key: String,row: int) -> Dictionary:
	if MOTION.data.aliases.has(key):
		var alias: Dictionary = MOTION.data.aliases[key][row]
		return {"key":alias.atlas,"row":int(alias.row),"data":MOTION.data.atlases[alias.atlas]}
	return {"key":key,"row":row,"data":META.data.atlases[key]}

func count(key: String,row: int = 0) -> int:
	return int(descriptor(key,row).data.columns)

func cycle(key: String,row: int,clock: float,seconds: float) -> int:
	return posmod(int(clock/maxf(0.01,seconds)*count(key,row)),count(key,row))

func progress(key: String,row: int,phase: float) -> int:
	return clampi(int(clampf(phase,0.0,1.0)*count(key,row)),0,count(key,row)-1)

func pose(key: String, row: int, column: int) -> Dictionary:
	var spec := descriptor(key,row)
	key = str(spec.key)
	row = int(spec.row)
	var d: Dictionary = spec.data
	column = clampi(column,0,int(d.columns)-1)
	var cache_key := "%s:%d:%d" % [key,row,column]
	if frames.has(cache_key): return frames[cache_key]
	var f: Dictionary = d.frames[row][column]
	if not images.has(key):
		var texture: Texture2D = load("res://"+str(d.path))
		var source := texture.get_image()
		if source.is_compressed(): source.decompress()
		source.convert(Image.FORMAT_RGBA8)
		images[key] = source
	var source: Image = images[key]
	var b: Array = f.bounds
	var isolated := Image.create_empty(int(b[2]-b[0])+4,int(b[3]-b[1])+4,false,Image.FORMAT_RGBA8)
	# Copy only registered silhouette spans. Source files stay unchanged. The
	# two transparent pixels around each independent texture prevent ANY atlas
	# sampling, wrapping or foreign fragments, including in custom shaders.
	for run in f.runs:
		isolated.blit_rect(source,Rect2i(int(f.rect[0]+run[1]),int(f.rect[1]+run[0]),int(run[2]),1),Vector2i(int(run[1]-b[0])+2,int(run[0]-b[1])+2))
	var factor: float = d.scale[row] if not d.scale.is_empty() else 1.0
	if key in ["rolls","motion-rolls"]:
		var largest := 0.0
		for n in int(d.columns):
			var bounds: Array = d.frames[row][n].bounds
			largest = maxf(largest,maxf(bounds[2]-bounds[0],bounds[3]-bounds[1]))
		factor = 64.0/largest
	var result := {"texture":ImageTexture.create_from_image(isolated),"offset":Vector2(float(b[0])-float(f.get("anchor_x",d.anchor_x[row]))-2.0,float(b[1])-float(b[3])-2.0),"scale":factor,"height":float(b[3]-b[1])*factor,"head":float(d.head_spans[row])*factor if d.has("head_spans") else 0.0,"source_key":key,"source_row":row,"source_frame":column,"cell_width":float(d.width)/float(d.columns),"cell_height":float(d.height)/float(d.rows),"top":float(b[1]),"left":float(b[0]),"baseline":float(d.baselines[row]) if d.has("baselines") else float(b[3])}
	frames[cache_key] = result
	return result

func place(item: Sprite2D,key: String,row: int,column: int,anchor: Vector2,growth: float = 1.0) -> void:
	var f := pose(key,row,column)
	item.region_enabled = false
	item.texture = f.texture
	item.offset = f.offset
	item.position = anchor.round()
	item.scale = Vector2.ONE * float(f.scale) * growth
	item.set_meta("source_key",f.source_key)
	item.set_meta("source_row",f.source_row)
	item.set_meta("source_frame",f.source_frame)
	item.set_meta("pose_key",key)
	item.set_meta("pose_row",row)
	item.set_meta("pose_frame",column)
	item.set_meta("pose_height",float(f.height)*growth)
	item.set_meta("head_size",float(f.head)*growth)
