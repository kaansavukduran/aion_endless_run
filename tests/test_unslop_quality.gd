extends SceneTree
const World=preload("res://scripts/world.gd")
const Bank=preload("res://scripts/frame_bank.gd")
const Heads=preload("res://assets/HEAD-REGISTRATION.json")
const Touch=preload("res://scripts/touch_button.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func _initialize():call_deferred("run")
func run():
 var bank=Bank.new()
 var atlases: Dictionary=bank.CANONICAL.data.atlases.duplicate()
 atlases.merge(bank.AGILITY.data.atlases);atlases.merge(bank.EMRE.data.atlases);atlases["eren-animations"]=bank.EREN.data.atlas
 for clip in Heads.data.clips:
  var atlas: Dictionary={}
  for key in atlases:
   if atlases[key].path==clip.path:atlas=atlases[key]
  check(not atlas.is_empty(),"Measured source atlas exists: "+str(clip.hero))
  var points:=[]
  for f in atlas.frames[int(clip.row)]:
   # Independent nose/cheek/outline probe rectangle, not eye_world or an
   # iris coordinate calculated by the runtime being tested.
   var probe: Array=f.head_probe
   var point: Vector2=(Vector2(probe[0],probe[1])-Vector2(f.origin[0],f.origin[1]))*float(atlas.scale[int(clip.row)])
   points.append(point)
   check(fmod(float(f.eye[0]),1.0)==0 and fmod(float(f.eye[1]),1.0)==0,"All frames share one source pixel phase")
  for point in points:check(point.distance_to(points[0])<.001,"Full rendered face registration stays stable: "+str(clip.hero)+"/"+str(clip.row))
 var sprite:=Sprite2D.new();sprite.centered=false
 for row in 6:
  var n: int=bank.count("rolls",row)
  check(n==(8 if row==5 else 12),"Actual shoulder pose count, no padded duplicates")
  var upright:=bank.pose("rolls",row,0)
  # Eren retains his long ears; measure their actual unsquashed silhouette.
  var low:=bank.pose("rolls",row,2 if row==5 else 3)
  check(low.height<upright.height*(.85 if row==5 else .80),"Visible knee/hand bend lowers the hero: "+str(row))
  for i in n:
   bank.place(sprite,"rolls",row,i,Vector2(288,500))
   check(sprite.position==Vector2(288,500) and is_equal_approx(sprite.scale.x,upright.scale),"No physical-position or per-frame scale workaround")
 var w=World.new();w.reset();w.obstacle_wait=999;w.adventure.item_wait=999;w.frontier.plant_wait=999;w.adventure.ambient_gnome_wait=999;w.adventure.press_roll(w)
 for tick in 100:w.step(.01)
 check(w.adventure.ducking(w) and w.adventure.roll_frame()==3,"One forward shoulder roll settles low; holding never spins a ball")
 check(w.adventure.roll_pose(1.0,.14,false)==9,"Release uses the authored recovery poses")
 sprite.free()
 var g=load("res://main.tscn").instantiate();root.add_child(g);await process_frame;g.set_physics_process(false);g.touch_tutorial_done=true
 for dims in [Vector2i(1152,648),Vector2i(393,873),Vector2i(873,393)]:
  root.size=dims;await process_frame;g.touch_mode=true
  for scale_value in [1.0,2.0]:
   g.interface_options.text_scale=scale_value;g.build_theme();g.ui.theme=g.ui_theme;g.main_menu();await process_frame;await process_frame;await process_frame
   var panel: PanelContainer=g.menu_layer.get_node("PagePanel")
   var content: VBoxContainer=panel.get_child(0)
   var inset: Vector2=panel.get_theme_stylebox("panel").get_minimum_size()
   var measured: float=g.menu_pages.measure(content,panel.size.x-inset.x)
   check(panel.size.y<=measured+inset.y+2,"Main background fits real content without a blank slab "+str(dims)+str(scale_value)+" actual="+str(panel.size.y)+" content="+str(measured)+" minimum="+str(content.get_combined_minimum_size()))
   check(g.menu_layer.find_children("StartSelect_*","Button",true,false).size()==6,"Eren and Emre have separate visible cards")
   for choice in g.menu_layer.find_children("StartSelect_*","Button",true,false):
    check(not g.language_button.get_global_rect().intersects(choice.get_global_rect()),"Compact language control never covers a character card at enlarged text")
   g.select_character("eren");check(g.character_name("eren")=="Eren" and g.character=="eren","Eren selection follows the real menu action")
   g.start_run();g.world.obstacle_wait=999;g.world.frontier.plant_wait=999;g.world.adventure.item_wait=999;g.world.adventure.ambient_gnome_wait=999;g.update_friend();g.update_hud()
   check(not g.action_buttons.has("attack") and not g.ammo_label.visible,"No Reload button or magazine HUD exists")
   g.press_shoot("key")
   for tick in 220:g.world.step(.01)
   check(g.world.frontier.shots_fired>=6,"Normal firearm input continues after five bullets")
   g.release_shoot("key");g.press_jump("key");g.world.step(.01);g.update_friend()
   check(g.world.y<0 and not g.world.charging and g.friend_sprite.get_meta("source_key")=="eren-animations","Eren jumps using his own art, independently of Emre")
   g.release_jump("key");g.main_menu()
 var button=Touch.new();button.size=Vector2(96,96)
 for side in [28,35,48,64]:
  var image: Image=button.skin_image(side);var symmetric:=true
  for y in side:
   for x in side:
    var alpha: float=image.get_pixel(x,y).a
    symmetric=symmetric and alpha==image.get_pixel(side-1-x,y).a and alpha==image.get_pixel(x,side-1-y).a
  check(symmetric,"Exact mirrored control contour at every actual device grid "+str(side))
 button.free();g.queue_free();await process_frame
 print("RESULT: %d Unslop quality checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
