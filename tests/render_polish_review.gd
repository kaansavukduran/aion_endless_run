## Explicit visual fixtures, separate from ordinary-input browser evidence.
extends SceneTree
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(1152,648)
 var game=load("res://main.tscn").instantiate();root.add_child(game);await process_frame
 game.set_physics_process(false);game.touch_tutorial_done=true;game.language="tr";game.interface_options.text_scale=1.;game.interface_options.touch_layout="split";game.build_theme();game.ui.theme=game.ui_theme
 DirAccess.make_dir_recursive_absolute("res://build/polish-scenes")
 for hero in game.FRIENDS:
  game.main_menu();game.select_character(hero);game.start_run();game.set_physics_process(false)
  game.world.frontier.plant_wait=999;game.world.adventure.enemies.clear();game.world.obstacles.clear();game.world.pickups.clear()
  for n in 6:
   game.world.time=n/6.;game.world.distance=n*174./6;game.update_friend();game.update_hud();game.queue_redraw()
   await process_frame;await process_frame;await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://build/polish-scenes/%s-run-%d.png"%[hero,n])
  for n in 6:
   game.world.adventure.duck_held=true;game.world.adventure.roll_elapsed=(n+.1)/6*.62;game.world.adventure.roll_time=.1;game.update_friend();game.update_hud();game.queue_redraw()
   await process_frame;await process_frame;await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://build/polish-scenes/%s-roll-%d.png"%[hero,n])
  game.world.adventure.duck_held=false;game.world.adventure.roll_time=0
 game.main_menu();game.select_character("eren");game.start_run();game.set_physics_process(false)
 for charge in [true,false]:
  game.world.charging=charge;game.world.charge_time=1.2;game.world.y=0 if charge else -90;game.world.velocity=-150;game.world.air_time=.2
  game.update_friend();game.update_hud();game.queue_redraw();await process_frame;await process_frame;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://build/polish-scenes/eren-grip-%s.png"%str(charge))
 for biome in 6:
  game.main_menu();game.select_character("aion");game.start_run();game.set_physics_process(false);game.world.distance=biome*6500.;game.world.adventure.enemies.clear();game.world.obstacles.clear();game.world.pickups.clear();game.world.adventure.items.clear()
  for i in game.frames.POLISH.data.pickup_order.size():
   var kind: String=game.frames.POLISH.data.pickup_order[i]
   game.world.adventure.items.append({"kind":kind,"x":140.+(i%9)*100,"y":-100.-(i/9)*90.,"id":i})
  game.update_friend();game.update_hud();game.queue_redraw();
  for layer in game.find_children("*","Node2D",true,false):layer.queue_redraw()
  await process_frame;await process_frame;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://build/polish-scenes/biome-%d.png"%biome)
 game.queue_free();await process_frame;print("Captured80 explicit real-rendered pixel scenes");quit()
