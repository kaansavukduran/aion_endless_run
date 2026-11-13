extends SceneTree
const Bank = preload("res://scripts/frame_bank.gd")
var checks := 0
var failures := 0
func check(value: bool,message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  printerr("FAIL: "+message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var bank := Bank.new()
 for hero in ["aion","owl","sheep","wolf"]:
  var d: Dictionary = bank.CANONICAL.data.atlases["canonical-"+hero]
  var scale: float = d.scale[0]
  for row in [0,1,2,3,4,7,8]:
   for column in d.frames[row].size():
    var f: Dictionary = d.frames[row][column]
    check(f.eye != null,"Actual iris or blink registration exists: "+hero+str(row)+":"+str(column))
    var eye: Vector2 = (Vector2(f.eye[0],f.eye[1])-Vector2(f.origin[0],f.origin[1]))*float(d.scale[row])
    if hero=="sheep" and row==4:
     check(absf((float(f.turn_center_x)-float(f.origin[0]))*scale-float(f.turn_target_x))<0.01 and is_equal_approx(scale,float(d.scale[row])),"The turning kick anchors its body while the head naturally turns away")
    else:
     check(eye.distance_to(Vector2(d.target_eye[0],d.target_eye[1]))<0.01 and is_equal_approx(scale,float(d.scale[row])),"Head registration has no position or scale pop: "+hero+str(row)+":"+str(column))
    check(f.body_bounds[3]-f.body_bounds[1]>d.height/14*.35,"A row boundary does not crop through the face: "+hero+str(row)+":"+str(column))
 var roll: Dictionary = bank.CANONICAL.data.atlases["canonical-rolls"]
 for row in 4:
  check(bank.count("rolls",row)==12,"Each low roll has twelve actual bend/rotation/recovery poses; the old eight-angle sheet remains archived")
  for col in 8:
   var f: Dictionary = roll.frames[row][col]
   check(f.source_column==col and f.clockwise_degrees==col*45,"Visually reviewed clockwise source order is retained")
   var b: Array = f.bounds
   var center: Vector2 = (Vector2((b[0]+b[2])/2.0,(b[1]+b[3])/2.0)-Vector2(f.origin[0],f.origin[1]))*float(roll.scale[row])
   check(center.distance_to(Vector2(0,-32))<0.01,"Tucked roll center stays fixed above the road")
 var path := "user://save.cfg"
 var original: PackedByteArray = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else PackedByteArray()
 if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
 var game = load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_physics_process(false)
 check(game.motion and game.effects_enabled and game.audio_enabled and game.world.adventure.celebrations_enabled,"A fresh installation defaults all four requested options ON")
 game.motion=false
 game.effects_enabled=false
 game.audio_enabled=false
 game.world.adventure.celebrations_enabled=false
 game.save_settings()
 game.motion=true
 game.effects_enabled=true
 game.audio_enabled=true
 game.world.adventure.celebrations_enabled=true
 game.load_settings()
 check(not game.motion and not game.effects_enabled and not game.audio_enabled and not game.world.adventure.celebrations_enabled,"Explicit saved OFF preferences survive reloading")
 game.queue_free()
 await process_frame
 if original.is_empty(): DirAccess.remove_absolute(path)
 else:
  var file := FileAccess.open(path,FileAccess.WRITE)
  file.store_buffer(original)
  file.close()
 print("RESULT: %d fidelity checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
