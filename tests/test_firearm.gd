extends SceneTree
const World=preload("res://scripts/world.gd")
const Words=preload("res://scripts/text.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+label)
func arena():
 var w=World.new();w.reset();w.obstacle_wait=999;w.frontier.plant_wait=999;w.adventure.item_wait=999;w.adventure.ambient_gnome_wait=999;return w
func advance(w,seconds):
 for i in ceili(seconds/.01):w.step(.01)
func _initialize():call_deferred("run")
func run():
 for id in ["aion","owl","wolf","sheep","rabbit","eren"]:
  var w=arena();w.character=id;w.frontier.shoot_held=true
  var times:=[]
  for i in 250:
   var before: int=w.frontier.shots_fired;w.step(.01)
   if w.frontier.shots_fired>before:times.append(i*.01)
  check(w.frontier.shots_fired>5,"Continuous fire passes five bullets with no reload: "+id)
  for i in range(1,times.size()):check(absf(times[i]-times[i-1]-.32)<.011,"The original0.32s cadence stays unchanged: "+id)
  check(w.frontier.projectiles.all(func(p):return p.owner!="hero" or p.vy==0),"Every hero projectile stays straight: "+id)
 var w=arena();w.frontier.shoot_held=true;advance(w,.14);var shots: int=w.frontier.shots_fired;var remaining: float=w.frontier.shot_cooldown;w.state="paused";w.step(.02)
 check(w.frontier.shots_fired==shots and w.frontier.shot_cooldown==remaining,"Pause freezes continuous firearm cadence")
 w.state="running";w.adventure.hug_time=.5;w.step(.02);check(w.frontier.shots_fired==shots,"Hug pauses the weapon without introducing a reload")
 w=arena();var e=w.adventure.spawn_enemy(w,"slime",World.PLAYER_X+230);w.frontier.fire(w);advance(w,.22)
 check(e.hp==0 and w.adventure.run_xp==10,"A real normal-run bullet defeats the ground enemy and earns XP")
 var names={"aion":"Aion","sheep":"Kutsanmış","wolf":"Melun","owl":"Ömer","rabbit":"Emre","eren":"Eren"}
 for lang in Words.LANGUAGES:
  for id in names:check(Words.get_text(lang,"name_"+id)==names[id],"Proper name stays exact: "+lang+"/"+id)
 var save_path:="user://save.cfg";var original:=FileAccess.get_file_as_bytes(save_path) if FileAccess.file_exists(save_path) else PackedByteArray()
 for lang in Words.LANGUAGES:
  check(Words.get_text(lang,"motion_help")==Words.get_text(lang,"help") and Words.get_text(lang,"motion_help").contains("15"),"Secondary help matches the current fifteen-second firearm controls: "+lang)
 for lang in Words.LANGUAGES:
  var table: Dictionary=Words.EXTRA[lang].data if Words.EXTRA.has(lang) else Words.STRINGS[lang]
  check(not table.has("ammo") and not table.has("reloading") and Words.get_text(lang,"touch_hint")==Words.get_text(lang,"touch_boss_hint"),"All normal/boss touch hints use current actions without removed magazine strings: "+lang)
 for lang in Words.LANGUAGES:
  check(Words.get_text(lang,"gamepad_help").contains("X/□ "+Words.get_text(lang,"control_attack")),"Gamepad help describes the retained alternate Fire binding: "+lang)
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.set_physics_process(false);g.touch_tutorial_done=true;g.select_character("aion");g.start_run();g.press_shoot("key");g.world.step(.02);g.update_friend();g.update_hud()
 check(g.world.frontier.shot_flash>0 and g.world.adventure.attack_time==0 and g.friend_sprite.get_meta("pose_key")=="gun-fire","Normal input and actual sprite use pistol, never punch")
 g.release_shoot("key");g.press_attack("key");check(g.world.frontier.shoot_held and g.world.adventure.attack_time==0,"Saved alternate binding also fires, with no melee or reload")
 check(not g.level_progress.visible and not g.xp_progress.visible,"Long level and XP bars are removed from the rendered HUD")
 g.main_menu()
 for dims in [Vector2i(873,393),Vector2i(2048,1024),Vector2i(393,873),Vector2i(768,1024)]:
  root.size=dims;await process_frame;g.touch_mode=true
  for scale_value in [1.0,2.0]:
   g.interface_options.text_scale=scale_value;g.build_theme();g.ui.theme=g.ui_theme;g.rebuild();await process_frame;await process_frame
   var screen:=Rect2(0,0,g.view_w,g.view_h)
   check(g.menu_layer.find_children("*","ScrollContainer",true,false).is_empty(),"Main menu needs no scroll: "+str(dims)+"/"+str(scale_value))
   for button in g.menu_layer.find_children("*","Button",true,false):check(screen.encloses(button.get_global_rect()),"Every main action/card stays visible: "+str(button.name)+str(dims)+"/"+str(scale_value))
   check(g.interface_options.text_scale==scale_value,"Requested text setting is preserved")
   check(not g.menu_layer.get_node("StartChooser").visible or not g.menu_layer.get_node("PagePanel").get_global_rect().intersects(g.menu_layer.get_node("StartChooser").get_global_rect()),"Menu actions do not overlap character heading")
 g.queue_free();await process_frame
 if original.is_empty():DirAccess.remove_absolute(save_path)
 else:
  var file:=FileAccess.open(save_path,FileAccess.WRITE);file.store_buffer(original);file.close()
 print("RESULT: %d firearm/menu checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
