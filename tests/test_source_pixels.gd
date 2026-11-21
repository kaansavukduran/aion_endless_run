## Source sheets decoded from the pack must equal the engine's own texture image.
extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var count:=0
	for name in DirAccess.get_files_at("res://assets"):
		if not name.ends_with(".png"):continue
		var path:="res://assets/"+name
		var decoded:=RunnerSourcePixels.decode(path)
		check(decoded!=null,"Lossless pack bytes decode without a GPU texture: "+name)
		if decoded==null:continue
		var texture: Texture2D=load(path)
		var reference:=texture.get_image()
		if reference.is_compressed():reference.decompress()
		check(decoded.get_size()==reference.get_size(),"Decoded size equals the imported texture: "+name)
		check(decoded.get_format()==reference.get_format(),"Decoded format equals the imported texture: "+name)
		var a:=decoded.duplicate();a.convert(Image.FORMAT_RGBA8)
		var b:=reference.duplicate();b.convert(Image.FORMAT_RGBA8)
		check(a.get_data()==b.get_data(),"Every decoded RGBA byte equals the engine texture image: "+name)
		count+=1
	check(count>=90,"All project sheets were compared")
	check(RunnerSourcePixels.decode("res://assets/missing-sheet.png")==null,"A missing import falls back instead of failing")
	var fallback:=RunnerSourcePixels.image("res://assets/icon.svg")
	check(fallback!=null and not fallback.is_empty(),"The project icon also yields its exact image")
	print("RESULT: %d source pixel checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
