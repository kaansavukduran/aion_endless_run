## Exported builds pack silhouette runs into binary blobs; every frame must read
## back exactly the registered runs, and nothing else in the JSON may change.
extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+label)
func same(a,b,file: String,trail: String) -> bool:
	if a is Dictionary:
		if not b is Dictionary or a.keys()!=b.keys():return false
		for key in a:
			if key=="runs" and a[key] is Array:
				var got: Array=RunnerSourcePixels.runs(b);var want: Array=a[key]
				if got.size()!=want.size():return false
				for i in want.size():
					for j in 3:
						if int(got[i][j])!=int(want[i][j]):return false
			elif not same(a[key],b[key],file,trail+"/"+str(key)):return false
		return true
	if a is Array:
		if not b is Array or a.size()!=b.size():return false
		for i in a.size():
			if not same(a[i],b[i],file,trail):return false
		return true
	if not (typeof(a)==typeof(b) and a==b):printerr(file+trail+" ",var_to_str(a)," vs ",var_to_str(b))
	return typeof(a)==typeof(b) and a==b
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var files:=0;var source_chars:=0;var packed_chars:=0
	for name in DirAccess.get_files_at("res://assets"):
		if not name.ends_with(".json"):continue
		var text:=FileAccess.get_file_as_string("res://assets/"+name)
		if not text.contains("\"runs\""):continue
		files+=1
		var original=JSON.parse_string(text)
		var packed:=RunnerSourcePixels.pack_runs(text,name)
		var shipped: String=packed.text
		source_chars+=text.length();packed_chars+=shipped.length()
		check(not packed.blob.is_empty() and not shipped.contains("\"runs\":["),"Runs leave the shipped JSON: "+name)
		RunnerSourcePixels.run_blobs[name]=packed.blob
		check(same(original,JSON.parse_string(shipped),name,""),"Packed JSON reads back identically, runs included: "+name)
	RunnerSourcePixels.run_blobs.clear()
	check(files>=25,"Every runs provenance file is covered: "+str(files))
	check(RunnerSourcePixels.runs({"runs":[[1,2,3]]})==[[1,2,3]],"Source-tree runs are used as registered")
	check(packed_chars*4<source_chars,"Shipped JSON is under a quarter of the source text: %d -> %d"%[source_chars,packed_chars])
	print("RESULT: %d runs pack checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
