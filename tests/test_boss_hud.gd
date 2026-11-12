extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+message)
func _initialize() -> void:call_deferred("run")
func longest_key(strings: Dictionary,prefix: String) -> String:
	var best:=""
	for key in strings:
		if str(key).begins_with(prefix) and str(strings[key]).length()>best.length():best=str(strings[key])
	return best
func run() -> void:
	var save_path:="user://save.cfg"
	var original:=FileAccess.get_file_as_bytes(save_path) if FileAccess.file_exists(save_path) else PackedByteArray()
	var game=load("res://main.tscn").instantiate();root.add_child(game);await process_frame;game.set_physics_process(false);game.touch_mode=true
	for dimensions in [Vector2i(540,1200),Vector2i(1200,540)]:
		root.size=dimensions;await process_frame
		for language in ["tr","en","cs"]:
			game.language=language;game.start_boss_practice(0)
			for tick in 250:game.world.step(.01)
			check(game.world.frontier.active(),"Real boss phase is active before HUD assertions")
			game.rebuild();await process_frame;await process_frame;game.update_hud()
			game.boss_label.text+=" · "+longest_key(game.Words.STRINGS[language],"boss_pattern_")+" · "+longest_key(game.Words.STRINGS[language],"boss_dodge_")
			game.handle_event("boss_fight");game.update_hud();game.boss_label.text+=" · "+longest_key(game.Words.STRINGS[language],"boss_pattern_")+" · "+longest_key(game.Words.STRINGS[language],"boss_dodge_")
			await process_frame;await process_frame
			var status: Rect2=game.boss_label.get_global_rect();var notice: Rect2=game.notice_label.get_global_rect();var screen:=Rect2(Vector2.ZERO,Vector2(game.view_w,game.view_h))
			check(screen.encloses(status) and game.boss_label.get_minimum_size().y<=status.size.y,"Longest localized boss status fits "+language+"/"+str(dimensions))
			check(status.end.y+4<=game.boss_bar.position.y,"Wrapped status does not overlap HP bar "+language)
			check(screen.encloses(notice) and game.notice_label.get_minimum_size().y<=notice.size.y and notice.position.y>game.boss_bar.position.y+12,"Phone boss instruction fits below HP bar "+language)
			check(game.notice_label.text=="" and game.footer_label.text==game.text("touch_boss_hint") and not game.ability_label.visible,"Boss help uses actual phone input once "+language)
	game.queue_free();await process_frame
	if original.is_empty():DirAccess.remove_absolute(save_path)
	else:
		var file:=FileAccess.open(save_path,FileAccess.WRITE);file.store_buffer(original);file.close()
	print("RESULT: %d boss HUD checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
