extends SceneTree
var failures:=0
var game
func _initialize():call_deferred("run")
func settle():
 await process_frame
 await process_frame
 await RenderingServer.frame_post_draw
func capture(name: String):
 await settle()
 # Physics is deliberately disabled in this authored fixture. Recompute the
 # presentation pose after reflow, as the real physics loop does every frame.
 game.apply_scene_transform();game.update_friend()
 await RenderingServer.frame_post_draw
 var image: Image=root.get_texture().get_image()
 var result: Error=image.save_png("res://build/front-presentation/"+name+".png")
 if result!=OK:failures+=1;printerr("FAIL: Render capture "+name+" error "+str(result))
func run():
 DirAccess.make_dir_recursive_absolute("res://build/front-presentation")
 root.size=Vector2i(1152,648)
 game=load("res://scripts/game.gd").new();root.add_child(game);await settle()
 game.set_physics_process(false)
 for i in 180:game.front.step(1./60.)
 await capture("opening-desktop")
 game.front.skip_intro();await capture("menu-desktop")
 game.open_subpage("characters");await capture("characters-desktop")
 game.open_subpage("help");await capture("help-desktop")
 game.show_page("main");game.front.start_demo();for i in 120:game.front.step(1./60.)
 await capture("actual-engine-demo");game.front.stop_demo()
 root.size=Vector2i(393,873);game.touch_mode=true;game.interface_options.text_scale=2.;game.build_theme();game.ui.theme=game.ui_theme;game.rebuild();await capture("menu-portrait-200")
 game.open_subpage("characters");await settle();game.menu_pages.select(1,false);await capture("characters-portrait-200")
 root.size=Vector2i(873,393);game.rebuild();await settle();game.menu_pages.select(1,false);await capture("characters-landscape-200")
 game.queue_free();await settle()
 print("RESULT: 8 authored front render fixtures, %d failures"%failures)
 quit(1 if failures else 0)
