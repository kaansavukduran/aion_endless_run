extends SceneTree
var game
var output: String
var captures:=0
var failures:=0
func _initialize():call_deferred('run')
func capture(name: String):
 await process_frame;await process_frame;await process_frame
 game.apply_scene_transform();game.update_friend();await RenderingServer.frame_post_draw
 var err=root.get_texture().get_image().save_png(output+'/'+name+'.png')
 captures+=1
 if err!=OK:failures+=1;printerr('FAIL: '+name)
func run():
 output=OS.get_environment('AION_MENU_REVIEW')
 if output.is_empty():output='res://build/arcade-menu-review'
 DirAccess.make_dir_recursive_absolute(output)
 root.size=Vector2i(1152,648);game=load('res://scripts/game.gd').new();root.add_child(game)
 await process_frame;await process_frame;game.set_physics_process(false);game.front.skip_intro()
 for dimensions in [Vector2i(1152,648),Vector2i(873,393),Vector2i(393,873)]:
  root.size=dimensions;await process_frame
  for scale_value in [1.,2.]:
   game.touch_mode=dimensions.x<1000;game.language='tr' if scale_value==1. else 'en';game.interface_options.text_scale=scale_value;game.build_theme();game.ui.theme=game.ui_theme;game.rebuild()
   await capture('menu-'+str(dimensions.x)+'x'+str(dimensions.y)+'-'+str(int(scale_value*100)))
 game.interface_options.text_scale=1.;game.help_step=5;game.show_page('help');await capture('help-rescue')
 game.show_page('main')
 var saved=AionCampaignWorld.new();saved.begin('aion');saved.state='playing'
 var file=FileAccess.open('user://campaign.json',FileAccess.WRITE);file.store_string(JSON.stringify(saved.snapshot()));file.close()
 for dimensions in [Vector2i(1152,648),Vector2i(393,873)]:
  root.size=dimensions;await process_frame;game.interface_options.text_scale=2.;game.rebuild();await capture('continue-'+str(dimensions.x)+'x'+str(dimensions.y)+'-200')
 game.queue_free();await process_frame
 print('RESULT: ',captures,' arcade menu render states, ',failures,' failures');quit(1 if failures else 0)
