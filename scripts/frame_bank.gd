class_name RunnerFrameBank
extends RefCounted

const META = preload("res://assets/FRONTIER-PROVENANCE.json")
const MOTION = preload("res://assets/MOTION-PROVENANCE.json")
const ENCOUNTERS = preload("res://assets/ENCOUNTERS-PROVENANCE.json")
const CANONICAL = preload("res://assets/CANONICAL-PROVENANCE.json")
const AGILITY = preload("res://assets/AGILITY-PROVENANCE.json")
const CREATURES = preload("res://assets/CREATURES-PROVENANCE.json")
const EMRE = preload("res://assets/EMRE-PROVENANCE.json")
const FLORA=preload("res://assets/FLORA-PROVENANCE.json")
const LOW_ROLLS=preload("res://assets/LOW-ROLLS-PROVENANCE.json")
const SHOULDERS=preload("res://assets/SHOULDER-POSES-PROVENANCE.json")
const EREN=preload("res://assets/EREN-PROVENANCE.json")
const ORCHARD = preload("res://assets/ORCHARD-PROVENANCE.json")
var images := {}
var frames := {}

func descriptor(key: String,row: int) -> Dictionary:
	if key=="rolls":
		return {"key":"eren-animations","row":5,"data":EREN.data.atlas} if row==5 else {"key":"shoulder-rolls","row":row,"data":SHOULDERS.data.atlas}
	if key=="runner-eren":return {"key":"eren-animations","row":[0,1,2,7,8,9,2,2][clampi(row,0,7)],"data":EREN.data.atlas}
	if key in ["gun-run","gun-fire","heroes"] and row==5:return {"key":"eren-animations","row":4 if key=="gun-fire" else 3,"data":EREN.data.atlas}
	if key=="deaths" and row in [10,11]:return {"key":"eren-animations","row":6,"data":EREN.data.atlas}
	if key=="strikes" and row in [10,11]:return {"key":"eren-animations","row":4,"data":EREN.data.atlas}
	if key=="flora":return {"key":key,"row":row,"data":FLORA.data.atlas}
	if key=="fruits":return {"key":key,"row":row,"data":ORCHARD.data.atlas}
	if EMRE.data.atlases.has(key):return {"key":key,"row":row,"data":EMRE.data.atlases[key]}
	var emre_row := -1
	var emre_key := "emre-movement"
	if key=="runner-rabbit":
		emre_row=[0,1,2,3,4,5,2,2][clampi(row,0,7)]
		if row in [3,4,5]:emre_key="emre-encounters"
	elif key=="rolls" and row==4:emre_row=5
	elif key=="strikes" and row in [8,9]:emre_row=3+row-8
	elif key in ["gun-run","gun-fire","heroes"] and row==4:
		emre_key="emre-encounters";emre_row=0 if key=="gun-run" else 1
	elif key=="deaths" and row in [8,9]:emre_key="emre-encounters";emre_row=2
	if emre_row>=0:return {"key":emre_key,"row":emre_row,"data":EMRE.data.atlases[emre_key]}
	if key=="creatures":return {"key":key,"row":row,"data":CREATURES.data.atlas}
	if AGILITY.data.aliases.has(key) and AGILITY.data.aliases[key][row] != null:
		var alias: Dictionary = AGILITY.data.aliases[key][row]
		return {"key":alias.atlas,"row":int(alias.row),"data":AGILITY.data.atlases[alias.atlas]}
	if CANONICAL.data.aliases.has(key):
		var alias: Dictionary = CANONICAL.data.aliases[key][row]
		return {"key":alias.atlas,"row":int(alias.row),"data":CANONICAL.data.atlases[alias.atlas]}
	if ENCOUNTERS.data.aliases.has(key):
		var alias: Dictionary = ENCOUNTERS.data.aliases[key][row]
		return {"key":alias.atlas,"row":int(alias.row),"data":ENCOUNTERS.data.atlases[alias.atlas]}
	if MOTION.data.aliases.has(key):
		var alias: Dictionary = MOTION.data.aliases[key][row]
		return {"key":alias.atlas,"row":int(alias.row),"data":MOTION.data.atlases[alias.atlas]}
	return {"key":key,"row":row,"data":META.data.atlases[key]}

func count(key: String,row: int = 0) -> int:
	var spec := descriptor(key,row)
	return spec.data.frames[int(spec.row)].size()

func cycle(key: String,row: int,clock: float,seconds: float) -> int:
	return posmod(int(clock/maxf(0.01,seconds)*count(key,row)),count(key,row))

func progress(key: String,row: int,phase: float) -> int:
	return clampi(int(clampf(phase,0.0,1.0)*count(key,row)),0,count(key,row)-1)

func pose(key: String, row: int, column: int) -> Dictionary:
	var spec := descriptor(key,row)
	key = str(spec.key)
	row = int(spec.row)
	var d: Dictionary = spec.data
	column = clampi(column,0,d.frames[row].size()-1)
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
	var result := {"texture":ImageTexture.create_from_image(isolated),"offset":Vector2(float(b[0])-float(f.get("anchor_x",d.anchor_x[row]))-2.0,float(b[1])-float(b[3])-2.0),"scale":factor,"height":float(b[3]-b[1])*factor,"head":float(d.head_spans[row])*factor if d.has("head_spans") else 0.0,"source_key":key,"source_row":row,"source_frame":column,"cell_width":float(d.width)/float(d.columns),"cell_height":float(d.height)/float(d.rows),"center_y":float(f.get("anchor_y",float(d.height)/float(d.rows)*0.5)),"top":float(b[1]),"left":float(b[0]),"baseline":float(d.baselines[row]) if d.has("baselines") else float(b[3])}
	if f.has("origin"):
		result.offset = Vector2(float(b[0])-float(f.origin[0])-2.0,float(b[1])-float(f.origin[1])-2.0)
		result["registration"] = "head" if f.eye != null and row not in [5,9,10,12,13] else ("roll-center" if key=="canonical-rolls" or row==5 else "floor")
		if f.has("registration"): result["registration"] = f.registration
		result["source_column"] = int(f.source_column)
		if f.eye != null: result["eye_local"] = Vector2(float(f.eye[0]-b[0])+2,float(f.eye[1]-b[1])+2)
	if f.has("head_probe"):
		result["probe_local"] = Vector2(float(f.head_probe[0]-b[0])+2,float(f.head_probe[1]-b[1])+2)
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
	for marker in ["eye_world","head_probe_world"]:
		if item.has_meta(marker): item.remove_meta(marker)
	if f.has("eye_local"): item.set_meta("eye_world",item.position+(f.offset+f.eye_local)*float(f.scale)*growth)
	if f.has("probe_local"): item.set_meta("head_probe_world",item.position+(f.offset+f.probe_local)*float(f.scale)*growth)
