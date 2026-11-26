## Startup cost guard: every preloaded texture is actually used, and loading
## the main scene does not pull in more textures than it needs.
extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var sources:={}
	for name in DirAccess.get_files_at("res://scripts"):
		if name.ends_with(".gd"):sources[name]=FileAccess.get_file_as_string("res://scripts/"+name)
	var everything:="\n".join(sources.values())
	var declaration:=RegEx.create_from_string("(?m)^const\\s+([A-Z_][A-Z0-9_]*)\\s*(?::\\s*\\w+\\s*)?:?=\\s*preload\\(\"(res://[^\"]+\\.png)\"\\)")
	var word:=RegEx.new()
	for file in sources:
		for found in declaration.search_all(sources[file]):
			var constant: String=found.get_string(1)
			word.compile("\\b"+constant+"\\b")
			check(word.search_all(everything).size()>1,"Preloaded texture constant is used: %s.%s (%s)"%[file,constant,found.get_string(2)])
	load("res://main.tscn")
	var cached:=0
	for name in DirAccess.get_files_at("res://assets"):
		if name.ends_with(".png.import") and ResourceLoader.has_cached("res://assets/"+name.trim_suffix(".import")):cached+=1
	check(cached<=19,"Main scene loads at most 19 textures at startup: "+str(cached))
	print("RESULT: %d boot preload checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
