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
const SHEET_LIMIT := 12
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

const SECTION_SHEETS := "res://assets/SECTION-SHEETS.json"
static var known_sections: Dictionary = {}

## Hero art is drawn every frame, so it stays resident without warm-up.
static func hero_sheet(path: String) -> bool:
	var file: String=path.get_file()
	return file.begins_with("m1-redraw-") or file.begins_with("m1-body-") or file.begins_with("m1-actions-") or file in ["polish-aion.png","polish-sheep.png"]

## Called while a section loads behind the travel fade: decode the world sheets
## the section is known to draw (generated list) plus any it used earlier in
## this session, so the first appearance of an enemy or prop does not hitch.
static func enter_section(id: String) -> void:
	current_section=id
	if known_sections.is_empty() and ResourceLoader.exists(SECTION_SHEETS):
		var data=load(SECTION_SHEETS).data
		if data is Dictionary and data.get("sections") is Dictionary:known_sections=data.sections
	var warm: Array=[]
	for path in known_sections.get(id,[]):
		if ResourceLoader.exists(str(path)):warm.append(str(path))
	for path in section_paths.get(id,{}):
		if not path in warm:warm.append(path)
	for path in warm.slice(maxi(0,warm.size()-SHEET_LIMIT)):sheet(path)

static func resident_bytes() -> int:
	var total:=0
	for decoded in sheets.values():total+=decoded.get_data_size()
	return total

## Silhouette runs. In the source tree every frame stores its runs as a JSON
## list of [y, x, length] triples (the registered, reviewable form). Exported
## builds store them packed: the export plugin (addons/aion_runs_pack) moves
## every list into one little-endian uint16 blob per JSON file and leaves a
## short "FILE.json:offset:count" reference, so startup parses ~9x less JSON.
## Banks call runs() at the moment a frame is first cut, in either form.
const RUNS_DIR := "res://assets/"
const RUNS_SUFFIX := ".runs"
static var run_blobs: Dictionary = {}

static func runs(frame: Dictionary) -> Array:
	var value=frame.runs
	if value is Array:return value
	var parts: PackedStringArray=str(value).split(":")
	var file: String=parts[0]
	if not run_blobs.has(file):run_blobs[file]=FileAccess.get_file_as_bytes(RUNS_DIR+file+RUNS_SUFFIX)
	var blob: PackedByteArray=run_blobs[file]
	var at:=int(parts[1]);var result: Array=[];result.resize(int(parts[2]))
	for i in result.size():
		var o:=at+i*6;result[i]=[blob.decode_u16(o),blob.decode_u16(o+2),blob.decode_u16(o+4)]
	return result

## Export-time packing shared by the export plugin and the exactness test.
## Works on the source text: each "runs" list is cut out and replaced by its
## reference, every other byte of the file is kept exactly as registered.
## Returns {"text": shipped JSON text, "blob": PackedByteArray}.
static func pack_runs(text: String, file: String) -> Dictionary:
	var blob:=PackedByteArray();var parts:=PackedStringArray();var from:=0
	while true:
		var key:=text.find("\"runs\"",from)
		if key<0:break
		var open:=key+6
		while open<text.length() and text[open] in [" ",":","\n","\r","\t"]:open+=1
		if open>=text.length() or text[open]!="[":
			parts.append(text.substr(from,open-from));from=open;continue
		var depth:=0;var close:=open
		while close<text.length():
			var c:=text[close]
			if c=="[":depth+=1
			elif c=="]":
				depth-=1
				if depth==0:break
			close+=1
		var list=JSON.parse_string(text.substr(open,close-open+1))
		var at:=blob.size();blob.resize(at+list.size()*6)
		for i in list.size():
			for j in 3:blob.encode_u16(at+i*6+j*2,int(list[i][j]))
		parts.append(text.substr(from,open-from));parts.append("\"%s:%d:%d\""%[file,at,list.size()])
		from=close+1
	parts.append(text.substr(from))
	return {"text":"".join(parts),"blob":blob}
