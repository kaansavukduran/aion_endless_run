class_name CampaignForgePropArt
extends RefCounted

## Original Mission 1 integer-pixel props. The atlas is deliberately lazy:
## importing this class with main.tscn does not load another PNG at boot.
const ATLAS_PATH := "res://assets/m1-forge-props.png"
const CELL := Vector2(64., 48.)
const ORIGIN := Vector2(32., 46.)
const PIXEL_SCALE := 2.
const ENTRIES := {
	"relay_cover": [0, 4, Vector2(96, 36)],
	"copper_grate": [1, 4, Vector2(96, 80)],
	"ammo_cache": [2, 4, Vector2(64, 48)],
	"shore_signal": [3, 4, Vector2(48, 72)],
	"route_water": [4, 2, Vector2(88, 40)],
	"route_terrace": [5, 2, Vector2(88, 40)],
	"route_roots": [6, 2, Vector2(88, 40)],
	"route_root_secret": [7, 2, Vector2(88, 40)],
	"water_pump": [8, 4, Vector2(88, 80)],
	"wind_pennant": [9, 4, Vector2(56, 88)],
}
const ALIASES := {
	"signal_cabinet": "shore_signal",
	"route_upper": "route_terrace",
	"route_root": "route_roots",
}
static var _atlas: Texture2D

static func resolve(kind: String) -> String:
	return str(ALIASES.get(kind, kind))

static func frame_count(kind: String) -> int:
	var key := resolve(kind)
	return int(ENTRIES[key][1]) if ENTRIES.has(key) else 0

static func dimensions(kind: String) -> Vector2:
	var key := resolve(kind)
	return Vector2(ENTRIES[key][2]) if ENTRIES.has(key) else Vector2.ZERO

static func anchor(kind: String) -> Vector2:
	# The pole base, rather than the waving flag's silhouette centre, is fixed.
	return Vector2(24., 46.) if resolve(kind) == "wind_pennant" else ORIGIN

static func texture() -> Texture2D:
	if _atlas == null:
		_atlas = load(ATLAS_PATH) as Texture2D
	return _atlas

static func draw(view: CanvasItem, kind: String, foot: Vector2, frame: int = 0) -> void:
	var key := resolve(kind)
	assert(ENTRIES.has(key), "Unknown Mission 1 forge prop: " + kind)
	if not ENTRIES.has(key): return
	var entry: Array = ENTRIES[key]
	var source := Rect2(Vector2(clampi(frame, 0, int(entry[1]) - 1) * CELL.x, int(entry[0]) * CELL.y), CELL)
	var destination := Rect2((foot - anchor(key) * PIXEL_SCALE).round(), CELL * PIXEL_SCALE)
	view.draw_texture_rect_region(texture(), destination, source)
