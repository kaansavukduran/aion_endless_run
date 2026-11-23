class_name ForgeHeroArt
extends RefCounted

## Source art is immutable; each crop has its own transparent sampling gutter.
const DATA = preload("res://assets/FORGE-HEROES-PROVENANCE.json")
const HEROES := ["aion", "wolf", "sheep", "owl", "rabbit", "eren"]
# 0.40.0: Process-wide shared hero forge atlas & crop cache.
static var images: Dictionary = {}
static var cache: Dictionary = {}

func pose(key: String, row: int, frame: int) -> Dictionary:
	var atlas: Dictionary = DATA.data.atlases[key]
	frame = clampi(frame, 0, atlas.frames[row].size() - 1)
	var id := key + ":" + str(row) + ":" + str(frame)
	if cache.has(id): return cache[id]
	if not images.has(key):
		var pixels := RunnerSourcePixels.image("res://" + str(atlas.path))
		if pixels.is_compressed(): pixels.decompress()
		pixels.convert(Image.FORMAT_RGBA8)
		images[key] = pixels
	var f: Dictionary = atlas.frames[row][frame]
	var b: Array = f.bounds
	var image := Image.create_empty(int(b[2]) - int(b[0]) + 4, int(b[3]) - int(b[1]) + 4, false, Image.FORMAT_RGBA8)
	for run in f.runs:
		image.blit_rect(images[key], Rect2i(int(f.rect[0]) + int(run[1]), int(f.rect[1]) + int(run[0]), int(run[2]), 1), Vector2i(int(run[1]) - int(b[0]) + 2, int(run[0]) - int(b[1]) + 2))
	var factor: float = atlas.scales[row]
	cache[id] = {"texture": ImageTexture.create_from_image(image), "offset": Vector2(float(b[0]) - float(f.origin[0]) - 2., float(b[1]) - float(f.origin[1]) - 2.) * factor, "size": image.get_size() * factor, "source_key": "forge-" + key, "source_row": row, "source_frame": frame, "gun_embedded": key != "embark"}
	if f.has("muzzle"):
		cache[id].muzzle_local = (Vector2(float(f.muzzle[0]), float(f.muzzle[1])) - Vector2(float(f.origin[0]), float(f.origin[1]))) * factor
	return cache[id]

func mouth(hero: String, frame: int, flapping: bool = false, firing: bool = false) -> Dictionary:
	var row := (1 if flapping else 0) if hero == "owl" else (3 if firing else 2)
	return pose("mouth-carry", row, posmod(frame, 6))

func aim(hero: String, direction_index: int) -> Dictionary:
	return pose("eightway", HEROES.find(hero), posmod(direction_index, 8))

func mouth_aim(hero: String, direction_index: int) -> Dictionary:
	return pose("mouth-aim", 0 if hero == "owl" else 1, posmod(direction_index, 8))

func embark(hero: String, frame: int) -> Dictionary:
	return pose("embark", HEROES.find(hero), frame)
