extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+message)
func settle() -> void:
	for i in 4:await process_frame
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var game=load("res://scripts/game.gd").new();root.add_child(game);await settle();game.set_physics_process(false);game.front.skip_intro()
	for dimensions in [Vector2i(1152,648),Vector2i(393,873),Vector2i(873,393)]:
		root.size=dimensions;game.touch_mode=true
		for language in GameText.LANGUAGES:
			game.language=language;game.interface_options.text_scale=2.;game.build_theme();game.ui.theme=game.ui_theme;game.start_run();game.pause_run();await settle()
			var screen:=Rect2(0,0,game.view_w,game.view_h)
			var seen:={}
			for page_index in game.menu_pages.pages.size():
				game.menu_pages.select(page_index,false);await settle()
				for key in ["resume","menu"]:
					var found: Button
					for item in game.menu_layer.find_children("*","Button",true,false):
						if item.text==game.text(key):found=item;break
					check(found!=null and found.is_visible_in_tree(),"Pause "+key+" visible on page "+str(page_index)+" "+language+str(dimensions))
					if found!=null and found.is_visible_in_tree():check(screen.grow(1).encloses(found.get_global_rect()),"Pause primary action fits "+key+language+str(dimensions))
					if page_index==0 and found!=null and found.is_visible_in_tree():seen[key]=true
			check(seen.size()==2,"First pause page contains both essential actions "+language+str(dimensions))
	game.queue_free();await settle()
	print("RESULT: %d pinned pause checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
