class_name ForgeVehicleArt
extends RefCounted

const DATA = preload("res://assets/FORGE-VEHICLES-PROVENANCE.json")
var images: Dictionary = {}
var cache: Dictionary = {}

static func anchors(kind: String, phase: int = 0, frame: int = 0, target_height: float = 0.) -> Dictionary:
	var data: Dictionary = DATA.data.types[kind]
	phase = phase if phase < data.frames.size() else 0
	frame = clampi(frame, 0, data.frames[phase].size() - 1)
	var f: Dictionary = data.frames[phase][frame]
	var factor: float = float(data.scale) * (target_height / float(data.target_height) if target_height > 0. else 1.)
	var origin := Vector2(float(f.origin[0]), float(f.origin[1]))
	var pivot := Vector2(float(f.barrel_pivot[0]), float(f.barrel_pivot[1]))
	var muzzle := Vector2(float(f.muzzle[0]), float(f.muzzle[1]))
	return {"pivot_local": (pivot - origin) * factor, "muzzle_local": (muzzle - origin) * factor, "barrel_length": pivot.distance_to(muzzle) * factor, "scale": factor, "phase": phase, "frame": frame, "can_fire": phase < 3}

func pose(kind: String, phase: int, frame: int, target_height: float = 0.) -> Dictionary:
	var data: Dictionary = DATA.data.types[kind]
	var metrics := anchors(kind, phase, frame, target_height)
	phase = int(metrics.phase); frame = int(metrics.frame)
	var key := kind + ":" + str(phase) + ":" + str(frame) + ":" + str(target_height)
	if cache.has(key): return cache[key]
	if not images.has(kind):
		var texture: Texture2D = load("res://" + str(data.path))
		var image := texture.get_image()
		if image.is_compressed(): image.decompress()
		image.convert(Image.FORMAT_RGBA8)
		images[kind] = image
	var f: Dictionary = data.frames[phase][frame]
	var b: Array = f.bounds
	var result := Image.create_empty(int(b[2]) - int(b[0]) + 4, int(b[3]) - int(b[1]) + 4, false, Image.FORMAT_RGBA8)
	for run in f.runs:
		result.blit_rect(images[kind], Rect2i(int(f.rect[0]) + int(run[1]), int(f.rect[1]) + int(run[0]), int(run[2]), 1), Vector2i(int(run[1]) - int(b[0]) + 2, int(run[0]) - int(b[1]) + 2))
	var factor: float = metrics.scale
	cache[key] = {"texture": ImageTexture.create_from_image(result), "offset": Vector2(float(b[0]) - float(f.origin[0]) - 2., float(b[1]) - float(f.origin[1]) - 2.) * factor, "size": result.get_size() * factor, "muzzle_local": metrics.muzzle_local, "pivot_local": metrics.pivot_local, "barrel_length": metrics.barrel_length, "vehicle_growth": 1., "source_key": "forge-vehicle-" + kind, "source_phase": phase, "source_frame": frame}
	return cache[key]
