class_name RunnerBrowserSave
extends RefCounted
# Native ConfigFile remains authoritative on native platforms. The browser
# recovery copy bridges the asynchronous IDBFS commit window on quick reloads.
static func restore(cfg: ConfigFile) -> bool:
	if not OS.has_feature("web"):return false
	var api=JavaScriptBridge.get_interface("AionStorage")
	if api==null:return false
	var encoded=api.read()
	if not encoded is String or encoded=="":return false
	var candidate:=ConfigFile.new()
	if candidate.parse(encoded)!=OK:return false
	if int(candidate.get_value("meta","schema",0))!=1:return false
	if int(candidate.get_value("meta","revision",0))<=int(cfg.get_value("meta","revision",0)):return false
	var best:=maxi(int(cfg.get_value("records","best",0)),int(candidate.get_value("records","best",0)))
	var level:=maxi(int(cfg.get_value("records","best_level",1)),int(candidate.get_value("records","best_level",1)))
	var powers: Array=Array(cfg.get_value("progress","powers",[]))
	for id in Array(candidate.get_value("progress","powers",[])):
		if not powers.has(id):powers.append(id)
	cfg.clear()
	if cfg.parse(encoded)!=OK:return false
	cfg.set_value("records","best",best);cfg.set_value("records","best_level",level);cfg.set_value("progress","powers",powers)
	return true
static func persist(cfg: ConfigFile,revision: int) -> bool:
	if not OS.has_feature("web"):return false
	var api=JavaScriptBridge.get_interface("AionStorage")
	return bool(api.write(cfg.encode_to_text(),revision)) if api!=null else false
