class_name RunnerSourcePixels
extends RefCounted
# Sprite banks copy registered silhouette runs out of whole source sheets.
# Texture2D.get_image() on the Web/mobile GL Compatibility renderer uploads the
# sheet to the GPU and then reads it back with glReadPixels (a synchronous GPU
# stall). The lossless import already stores the exact pixels inside the .ctex,
# so decode those bytes directly. Any other storage falls back to get_image().

const DATA_FORMAT_PNG := 1
const DATA_FORMAT_WEBP := 2

static func image(path: String) -> Image:
	var decoded := decode(path)
	if decoded != null: return decoded
	var texture: Texture2D = load(path)
	return texture.get_image()

static func decode(path: String) -> Image:
	var import_file := ConfigFile.new()
	if import_file.load(path + ".import") != OK: return null
	var remap := str(import_file.get_value("remap", "path", ""))
	if not remap.ends_with(".ctex"): return null
	var file := FileAccess.open(remap, FileAccess.READ)
	if file == null: return null
	if file.get_buffer(4).get_string_from_ascii() != "GST2" or file.get_32() > 1: return null
	file.seek(36)
	var data_format := file.get_32()
	file.get_16(); file.get_16()
	var mipmaps := file.get_32()
	var format := file.get_32()
	if mipmaps != 0 or data_format not in [DATA_FORMAT_PNG, DATA_FORMAT_WEBP]: return null
	var size := file.get_32()
	var bytes := file.get_buffer(size)
	if bytes.size() != size: return null
	var result := Image.new()
	var error := result.load_webp_from_buffer(bytes) if data_format == DATA_FORMAT_WEBP else result.load_png_from_buffer(bytes)
	if error != OK or result.is_empty() or result.is_compressed(): return null
	if result.get_format() != format: result.convert(format)
	return result

## Shared, bounded cache of decoded RGBA8 source sheets. Banks copy frame runs
## out of a sheet only when a frame is first needed, so they no longer keep
## their own full-sheet copies: one decode per sheet, at most SHEET_LIMIT
## sheets resident (least recently used is released and decoded again later).
## Sheets are read-only for every caller.
const SHEET_LIMIT := 8
static var sheets: Dictionary = {}
static var recent: Array[String] = []
static var section_paths: Dictionary = {}
static var current_section := ""
static var decodes := 0

static func sheet(path: String) -> Image:
	if sheets.has(path):
		recent.erase(path);recent.append(path)
	else:
		var decoded := image(path)
		if decoded.is_compressed():decoded.decompress()
		decoded.convert(Image.FORMAT_RGBA8)
		sheets[path]=decoded;recent.append(path);decodes+=1
		while recent.size()>SHEET_LIMIT:sheets.erase(recent.pop_front())
	if current_section!="":
		if not section_paths.has(current_section):section_paths[current_section]={}
		section_paths[current_section][path]=true
	return sheets[path]

## Called while a section loads behind the travel fade: decode the sheets this
## section used before (retry, Continue, replay) so play does not hitch on them.
static func enter_section(id: String) -> void:
	current_section=id
	var used: Dictionary=section_paths.get(id,{})
	var warm: Array=used.keys().slice(maxi(0,used.size()-SHEET_LIMIT))
	for path in warm:sheet(path)

static func resident_bytes() -> int:
	var total:=0
	for decoded in sheets.values():total+=decoded.get_data_size()
	return total
