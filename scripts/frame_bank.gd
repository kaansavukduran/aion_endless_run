class_name RunnerFrameBank
extends RefCounted

const META = preload("res://assets/FRONTIER-PROVENANCE.json")
var images := {}
var frames := {}

func pose(key: String, row: int, column: int) -> Dictionary:
	var cache_key := "%s:%d:%d" % [key,row,column]
	if frames.has(cache_key): return frames[cache_key]
	var d: Dictionary = META.data.atlases[key]
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
	if key == "rolls":
		var largest := 0.0
		for n in range(1,6):
			var bounds: Array = d.frames[row][n].bounds
			largest = maxf(largest,maxf(bounds[2]-bounds[0],bounds[3]-bounds[1]))
		factor = 64.0/largest
	var result := {"texture":ImageTexture.create_from_image(isolated),"offset":Vector2(float(b[0])-float(d.anchor_x[row])-2.0,float(b[1])-float(b[3])-2.0),"scale":factor,"height":float(b[3]-b[1])*factor,"head":float(d.head_spans[row])*factor if d.has("head_spans") else 0.0}
	frames[cache_key] = result
	return result

func place(item: Sprite2D,key: String,row: int,column: int,anchor: Vector2,growth: float = 1.0) -> void:
	var f := pose(key,row,column)
	item.region_enabled = false
	item.texture = f.texture
	item.offset = f.offset
	item.position = anchor.round()
	item.scale = Vector2.ONE * float(f.scale) * growth
	item.set_meta("pose_key",key)
	item.set_meta("pose_row",row)
	item.set_meta("pose_frame",column)
	item.set_meta("pose_height",float(f.height)*growth)
	item.set_meta("head_size",float(f.head)*growth)
