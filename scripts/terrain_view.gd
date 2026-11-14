class_name RunnerTerrainView
extends RefCounted

## Authored pixel materials, cached once per tile. No gameplay RNG, height offsets,
## texture stretching or new collision surfaces. One source pixel = two world pixels.
const TILE_SIZE := Vector2i(1024, 96)
const PIXEL := 2
const VARIANTS := 1
const PALETTES := [
	["e1b185", "c49472", "926750", "745042", "654539", "4c3535", "392b32", "ab7b59", "775347"],
	["e6f5f4", "b9d5df", "6f9cab", "497080", "3b596d", "2d4358", "243448", "6b8797", "3c5e75"],
	["a3b972", "788f55", "4e6750", "43594b", "35473f", "2d3c36", "25302f", "66725d", "3e5149"],
	["c2b3aa", "938b89", "635f6d", "514956", "443c49", "37303d", "2d2735", "81747e", "4d4353"],
	["adc77d", "7c995d", "536a46", "5b5141", "4b4238", "3a3432", "292a2d", "786e55", "4c4b3f"],
	["d6a084", "9c7166", "634c54", "57414b", "473540", "392e3a", "2c2733", "83646b", "4a3b49"]
]
var textures: Dictionary = {}

func palette(kind: int) -> Array[Color]:
	var colors: Array[Color] = []
	for hex in PALETTES[posmod(kind, PALETTES.size())]: colors.append(Color(hex))
	return colors

func patch(image: Image, x: int, y: int, width: int, height: int, color: Color) -> void:
	# Wrap details too, so stones/roots that cross a tile edge are not cut off.
	for offset in [-TILE_SIZE.x, 0, TILE_SIZE.x]:
		var area := Rect2i(x + offset, y, width, height).intersection(Rect2i(Vector2i.ZERO, TILE_SIZE))
		if area.has_area(): image.fill_rect(area, color)

func stroke(image: Image, from: Vector2i, to: Vector2i, color: Color) -> void:
	var delta := to - from
	var steps: int = maxi(absi(delta.x), absi(delta.y))
	for i in steps + 1:
		var point := Vector2(from).lerp(Vector2(to), float(i) / maxi(1, steps)).round()
		patch(image, int(point.x), int(point.y), 1, 1, color)

func stone(image: Image, x: int, y: int, width: int, height: int, colors: Array[Color], light: bool = true) -> void:
	patch(image, x + 1, y + 1, width, height, colors[5])
	patch(image, x + 1, y, width - 2, height, colors[8])
	patch(image, x, y + 1, width, maxi(1, height - 2), colors[7])
	patch(image, x + 2, y, maxi(1, width - 4), 1, colors[2] if light else colors[8])
	if width > 9: patch(image, x + width - 3, y + 2, 2, maxi(1, height - 3), colors[8])

func make_tile(kind: int, variant: int) -> Image:
	var c := palette(kind)
	var image := Image.create(TILE_SIZE.x, TILE_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(c[6])
	image.fill_rect(Rect2i(0, 0, TILE_SIZE.x, 48), c[5])
	image.fill_rect(Rect2i(0, 0, TILE_SIZE.x, 25), c[3])
	image.fill_rect(Rect2i(0, 0, TILE_SIZE.x, 9), c[2])
	image.fill_rect(Rect2i(0, 0, TILE_SIZE.x, 4), c[1])
	image.fill_rect(Rect2i(0, 0, TILE_SIZE.x, 1), c[0])
	# Broken shelves interlock instead of forming long horizontal stripes.
	for i in 46:
		var x: int = i * 23 + variant * 13
		var shelf: int = 14 + posmod(i * 7 + variant * 11, 15)
		patch(image, x, 9, 18 + i % 6, shelf - 8, c[4] if i % 3 == 0 else c[3])
		patch(image, x + 3, shelf, 18, 2 + i % 3, c[4])
		var lower: int = 34 + posmod(i * 11, 14)
		patch(image, x - 4, lower + 1, 18, 3 + i % 4, c[4].lerp(c[5], .45))
		patch(image, x - 1, lower, 11, 2, c[4].lerp(c[5], .45))
		patch(image, x + 3, 47 + i % 3 * 4, 15, 4 + i % 4, c[5])
	# Sparse embedded stones form deliberate clusters, not uniformly sprinkled noise.
	for group in 19:
		var x: int = group * 57 + variant * 31
		var y: int = 17 + posmod(group * 11 + variant * 7, 18)
		stone(image, x, y, 11 + group % 3 * 3, 5 + group % 3, c)
		stone(image, x + 18, y + 6, 5, 3, c, false)
		patch(image, x + 8, y + 11, 3, 2, c[4])
	for i in 55:
		var x: int = i * 19 + variant * 17
		patch(image, x, 3 + i % 3, 5 + i % 5, 1, c[0] if kind == 1 else c[1])
		patch(image, x + 3, 7 + i % 4, 3, 2, c[2])
	match kind:
		0: # Packed sand, sediment ledges and buried sandstone.
			for i in 26:
				var x: int = i * 41 + variant * 19
				var y: int = 12 + i % 3 * 6
				stroke(image, Vector2i(x, y), Vector2i(x + 22, y + 3), c[7])
				stroke(image, Vector2i(x + 4, y + 5), Vector2i(x + 16, y + 7), c[4])
		1: # Snow lip with hanging ice facets over cold slate.
			for i in 37:
				var x: int = i * 29 + variant * 11
				patch(image, x, 2, 16, 3 + i % 3, c[0])
				patch(image, x + 4, 5, 7, 4 + i % 6, c[1])
				patch(image, x + 5, 5, 2, 3 + i % 5, c[0])
				stroke(image, Vector2i(x + 10, 14), Vector2i(x + 20, 23), c[7])
		2, 4: # Moss over damp earth, with continuous branching roots.
			for i in 14:
				var x: int = i * 79 + posmod(i * 37, 31)
				patch(image, x, 3, 13, 3 + i % 3, c[1])
				patch(image, x + 2, 6, 7, 2 + i % 5, c[2])
				var root_color := c[7].darkened(.18)
				var bend: int = 2 + i % 3 * 2
				var end: int = 25 + i % 4 * 3
				stroke(image, Vector2i(x + 4, 9), Vector2i(x + 2, 15), c[5])
				stroke(image, Vector2i(x + 2, 15), Vector2i(x + bend + 3, 22), c[5])
				stroke(image, Vector2i(x + bend + 3, 22), Vector2i(x + bend + 1, end), c[5])
				stroke(image, Vector2i(x + 3, 9), Vector2i(x + 1, 15), root_color)
				stroke(image, Vector2i(x + 1, 15), Vector2i(x + bend + 2, 22), root_color)
				stroke(image, Vector2i(x + bend + 2, 22), Vector2i(x + bend, end - 1), root_color)
				if i % 2 == 0: stroke(image, Vector2i(x + bend + 1, 20), Vector2i(x + 14, 24), root_color)
		3: # Small, worn stone pavers; staggered masonry below the walking edge.
			for row in 3:
				for i in 33:
					var x: int = i * 33 + row % 2 * 16 + variant * 7
					var y: int = 3 + row * 8
					patch(image, x, y, 29, 6, c[7] if row == 0 else c[8])
					patch(image, x + 2, y, 23, 1, c[1] if row == 0 else c[7])
					patch(image, x + 26, y + 2, 3, 4, c[4])
		5: # Basalt plates with a few warm mineral seams, never a hazard glow.
			for i in 23:
				var x: int = i * 47 + variant * 29
				stroke(image, Vector2i(x, 9), Vector2i(x + 7, 19), c[5])
				stroke(image, Vector2i(x + 7, 19), Vector2i(x + 20, 24), c[5])
				stroke(image, Vector2i(x + 2, 12), Vector2i(x + 6, 18), Color("b17c67"))
				patch(image, x + 8, 20, 4, 1, Color("c58d6a"))
	return image

func tile(kind: int, variant: int) -> Texture2D:
	var key := Vector2i(kind, posmod(variant, VARIANTS))
	if not textures.has(key): textures[key] = ImageTexture.create_from_image(make_tile(key.x, key.y))
	return textures[key]

func strips(width: float, scroll: float) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var span: int = TILE_SIZE.x * PIXEL
	var travel: float = floor(scroll / PIXEL) * PIXEL
	var start: int = floori(travel / span)
	var offset: float = fposmod(travel, span)
	for n in range(-1, ceili(width / span) + 1):
		result.append({"x": float(n * span) - offset, "width": span, "variant": posmod(start + n, VARIANTS)})
	return result

func draw_layer(host, kind: int, scroll: float, night: float, opacity: float) -> void:
	var colors := palette(kind)
	var tint := Color.WHITE.lerp(Color("7e86a4"), night * .32)
	var depth: float = maxf(0, host.scene_h - host.ground)
	var height: float = minf(depth, TILE_SIZE.y * PIXEL)
	var fill := colors[6] * tint
	fill.a = opacity
	# A translucent biome is composited once, not over its own translucent fill.
	# The texture already supplies every pixel above this quiet deep-ground area.
	if depth > height: host.draw_rect(Rect2(0, host.ground + height, host.scene_w, depth - height), fill)
	tint.a = opacity
	for strip in strips(host.scene_w, scroll):
		host.draw_texture_rect_region(tile(kind, strip.variant), Rect2(strip.x, host.ground, strip.width, height), Rect2(0, 0, TILE_SIZE.x, height / PIXEL), tint, false)

func draw(host, kind: int, previous: int, blend: float, scroll: float, night: float) -> void:
	if blend < 1.0: draw_layer(host, previous, scroll, night, 1.0)
	draw_layer(host, kind, scroll, night, blend)
