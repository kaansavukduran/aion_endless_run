@tool
extends EditorExportPlugin
# Replaces every frame's JSON runs list with a reference into a packed uint16
# blob (see RunnerSourcePixels.runs). Source files are never modified.

func _get_name() -> String:
	return "AionRunsPack"

func _export_file(path: String, type: String, features: PackedStringArray) -> void:
	if not path.begins_with(RunnerSourcePixels.RUNS_DIR) or not path.ends_with(".json") or path.get_base_dir()+"/"!=RunnerSourcePixels.RUNS_DIR:return
	var text:=FileAccess.get_file_as_string(path)
	if not text.contains("\"runs\""):return
	var file:=path.get_file()
	var packed:=RunnerSourcePixels.pack_runs(text,file)
	if packed.blob.is_empty():return
	skip()
	add_file(path,str(packed.text).to_utf8_buffer(),false)
	add_file(RunnerSourcePixels.RUNS_DIR+file+RunnerSourcePixels.RUNS_SUFFIX,packed.blob,false)
