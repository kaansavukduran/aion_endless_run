extends SceneTree
const World=preload("res://scripts/world.gd")
const Bank=preload("res://scripts/frame_bank.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String):
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func _initialize():call_deferred("run")
func arena():
 var w=World.new();w.reset();w.character="rabbit";w.obstacle_wait=999;w.frontier.plant_wait=999;w.adventure.item_wait=999;w.adventure.ambient_gnome_wait=999;w.invulnerable=999;return w
func advance(w,seconds):
 for i in ceili(seconds/.01):w.step(.01)
func run():
 var speeds:=[]
 for duration in [0.0,.2,.6,1.2,2.0]:
  var w=arena();w.jump();advance(w,duration)
  check(w.charging and w.y==0 and w.jumps_used==0,"Holding Jump charges on the ground, never launches early: "+str(duration))
  check(w.charge_ratio()<=1,"Charge caps without forced launch")
  w.release_charged_jump();w.step(.01);speeds.append(absf(w.velocity))
  check(w.y<0 and w.jumps_used==1 and not w.charging,"Release commits exactly one real leap")
  var velocity: float=w.velocity;w.jump();w.release_charged_jump();w.step(.01)
  check(w.jumps_used==1 and w.velocity>velocity,"No airborne second charge/double-jump")
 check(speeds[0]<speeds[1] and speeds[1]<speeds[2] and speeds[2]<speeds[3] and is_equal_approx(speeds[3],speeds[4]),"Longer hold produces monotonically stronger capped launch")
 var w=arena();w.jump();advance(w,.6);w.release_controls();w.release_charged_jump();w.step(.01)
 check(w.y==0 and not w.charging,"Cancellation never launches a latent charged jump")
 w=arena();w.jump();advance(w,.3);w.state="paused";w.step(.02)
 check(is_equal_approx(w.charge_time,.3),"Pause cannot advance the charge clock")
 var bank=Bank.new();var sprite:=Sprite2D.new();sprite.centered=false
 for row in 6:
  check(bank.count("rolls",row)==6,"Six actual bend/rotation/recovery poses for hero "+str(row))
  var first:=bank.pose("gun-run",row,0);var low:=bank.pose("rolls",row,5)
  check(low.height<first.height*.9,"Drawn low pose visibly lowers the body without squashing "+str(row))
  for frame in 6:
   bank.place(sprite,"rolls",row,frame,Vector2(288,500))
   var pose:=bank.pose("rolls",row,frame)
   check(sprite.position==Vector2(288,500) and is_equal_approx(sprite.scale.x,first.scale),"Fixed physical pivot and one uniform scale: "+str(row)+"/"+str(frame))
   check(absf(sprite.position.y+(pose.offset.y+pose.texture.get_height()-2)*pose.scale-500)<.01,"Every pose contacts the actual ground")
 sprite.free()
 for tick in range(20,200):check(w.adventure.roll_pose(tick*.02,0,true)==5 if tick*.02>=.53 else w.adventure.roll_pose(tick*.02,0,true) in [2,3,4,5],"One shoulder roll settles into a low crouch while held")
 check(w.adventure.roll_pose(.8,.14,false)==5 and w.adventure.roll_pose(.92,.02,false)==0,"Release shows authored recovery poses")
 var save_path:="user://save.cfg";var original:=FileAccess.get_file_as_bytes(save_path) if FileAccess.file_exists(save_path) else PackedByteArray()
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.touch_tutorial_done=true
 for dims in [Vector2i(873,393),Vector2i(393,873),Vector2i(1152,648)]:
  root.size=dims;await process_frame;g.touch_mode=true
  for scale_value in [1.0,2.0]:
   g.interface_options.text_scale=scale_value;g.build_theme();g.ui.theme=g.ui_theme
   for lang in ["tr","en"]:
    g.language=lang
    for target in ["main","paused","finished","settings","bosses","characters"]:
     g.page=target;g.world.state="ready";g.rebuild();await process_frame;await process_frame;await process_frame
     var screen:=Rect2(0,0,g.view_w,g.view_h)
     check(g.ui.find_children("*","ScrollContainer",true,false).is_empty(),"No wheel/scroll container anywhere: "+target+lang+str(dims)+str(scale_value))
     var count: int=g.menu_pages.pages.size() if target!="main" else 1
     for n in count:
      if target!="main":g.menu_pages.select(n,false)
      await process_frame;await process_frame
      for control in g.menu_layer.find_children("*","Control",true,false):
       if control.is_visible_in_tree() and control is BaseButton:check(screen.grow(1).encloses(control.get_global_rect()),"Visible page action fits: "+target+str(n)+str(control.name)+str(dims)+str(scale_value))
     if target=="settings":check(g.menu_pages.pages.size()>1,"Long settings use explicit pages")
     if target=="finished":
      for pin in g.menu_layer.find_children("*","Control",true,false):
       if pin.get_meta("menu_pin",false):check(pin.is_visible_in_tree(),"Retry and main/settings actions remain pinned on every results page")
    g.page="main";g.rebuild();await process_frame;g.toggle_language_picker();await process_frame;await process_frame
    for b in g.language_picker.find_children("*","Button",true,false):check(Rect2(0,0,g.view_w,g.view_h).grow(1).encloses(b.get_global_rect()),"All language options fit without scrolling: "+lang+str(dims)+str(scale_value))
    g.language_picker_open=false
 # A wider system font on the CI host exposed clipping at 200% landscape.
 # Keep this separate from the default-font matrix so local font choice cannot
 # silently bypass the regression again.
 for family in ["DejaVu Sans","Liberation Sans"]:
  for dims in [Vector2i(1152,648),Vector2i(873,393),Vector2i(393,873)]:
   root.size=dims;await process_frame;g.interface_options.text_scale=2;g.build_theme()
   var alternate:=SystemFont.new();alternate.font_names=PackedStringArray([family]);alternate.fallbacks=g.interface_options.body_font.fallbacks;g.interface_options.body_font=alternate;g.ui_theme.default_font=alternate;g.ui.theme=g.ui_theme
   for lang in ["tr","en"]:
    g.language=lang;g.page="main";g.language_picker_open=false;g.rebuild();await process_frame;await process_frame;await process_frame
    var screen:=Rect2(0,0,g.view_w,g.view_h)
    var tiles: Array=g.menu_layer.find_children("StartSelect_*","Button",true,false)
    var panel: Control=g.menu_layer.get_node("PagePanel")
    check(tiles.size()==6,"All six heroes remain visible with the actual wider system font")
    for tile in tiles:
     check(screen.grow(1).encloses(tile.get_global_rect()),"200% hero card fits "+family+lang+str(dims)+str(tile.name))
     check(tile.get_global_rect().grow(1).encloses(tile.get_child(0).get_global_rect()),"200% hero title/image fits its actual card")
     check(not panel.get_global_rect().intersects(tile.get_global_rect()),"Large-text main actions never overlap hero cards")
    g.toggle_language_picker();await process_frame;await process_frame
    var languages: Array=g.language_picker.find_children("*","Button",true,false)
    check(languages.size()==12,"System plus eleven languages remain individually reachable")
    for option in languages:check(screen.grow(1).encloses(option.get_global_rect()),"200% language fits "+family+lang+str(dims)+str(option.name))
    g.language_picker_open=false
 g.build_theme();g.ui.theme=g.ui_theme
 g.interface_options.text_scale=1;g.main_menu();g.select_character("rabbit");g.start_run();g.press_jump("key");advance(g.world,.5);g.release_jump("key");g.world.step(.01)
 check(g.world.y<0,"Actual scene key press/release routes into charged leap")
 g.main_menu();g.start_run();g.press_jump("touch:1");advance(g.world,.5);g.release_jump("touch:1",false);g.world.step(.01)
 check(g.world.y==0 and not g.world.charging,"A cancelled real touch binding does not release a jump")
 g.main_menu();g.start_run();g.press_jump("touch:1");advance(g.world,.4);g.press_shoot("touch:2");g.release_jump("touch:2",false)
 check(g.world.charging,"Releasing a different finger never cancels the owned charge")
 g.press_duck("key");check(not g.world.charging and g.world.adventure.ducking(g.world),"Rolling cancels charge and uses the actual low-roll state")
 g.release_jump("touch:1");g.world.step(.01);check(g.world.y==0,"A cancelled charge cannot launch when its old finger finally lifts")
 g.queue_free();await process_frame
 if original.is_empty():DirAccess.remove_absolute(save_path)
 else:
  var file:=FileAccess.open(save_path,FileAccess.WRITE);file.store_buffer(original);file.close()
 print("RESULT: %d charge/roll/paged UI checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
