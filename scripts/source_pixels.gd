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
