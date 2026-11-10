extends SceneTree
const World=preload("res://scripts/world.gd")
var checks:=0
var failures:=0
func check(value: bool,message: String) -> void:
 checks+=1
 if not value:failures+=1;printerr("FAIL: "+message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.set_physics_process(false)
 var bank=game.frames
 for hero in ["wolf","owl"]:
  var a:Dictionary=bank.AGILITY.data.atlases["agility-"+hero]
  var expected_scale:float=a.scale[0]
  for row in 4:
   for col in 8:
    var f:Dictionary=a.frames[row][col]
    var logical_key:String="runner-"+hero if row==0 else ("wolf-dash-bite" if hero=="wolf" and row==3 else "owl-peck" if row==3 else "strikes")
    var logical_row:int=6 if row==0 else (0 if row==3 else (6 if hero=="wolf" else 2)+row-1)
    var pose:Dictionary=bank.pose(logical_key,logical_row,col)
    check(pose.source_key=="agility-"+hero and pose.source_row==row,"Actual pose dispatch uses its own movement or contact row")
    var eye:Vector2=(pose.offset+Vector2(float(f.eye[0]-f.bounds[0])+2,float(f.eye[1]-f.bounds[1])+2))*pose.scale
    check(eye.distance_to(Vector2(a.target_eyes[row][0],a.target_eyes[row][1]))<0.01 and is_equal_approx(pose.scale,expected_scale),"Rendered near-eye stays aligned at one hero scale")
    if hero=="wolf" and row==0:check(float(f.body_bounds[2]-f.body_bounds[0])/float(f.body_bounds[3]-f.body_bounds[1])>1.3,"Four-legged gallop has a low horizontal silhouette")
    if hero=="owl" and row in [0,3]:check(float(f.body_bounds[2]-f.body_bounds[0])/float(f.body_bounds[3]-f.body_bounds[1])>1.3,"Glide and aerial beak strike keep spread airborne wings")
 game.character="wolf"
 game.world.character="wolf"
 game.world.reset()
 game.world.character="wolf"
 game.world.boost_held=true
 check(game.world.adventure.attack(game.world),"Boosting wolf can start a contact attack")
 check(game.world.adventure.attack_sprinting,"Sprint posture is captured at strike start")
 game.world.boost_held=false
 check(game.combat_pose("wolf",false).key=="wolf-dash-bite","Releasing boost mid-strike does not switch the drawn attack")
 game.world.adventure.attack_time=0.2
 check(game.combat_lunge().x>40,"Sprint bite really advances the rendered head")
 check(game.world.adventure.attack_rect(game.world).size.x==142,"Sprint bite collision reach matches the extended contact pose")
 game.world.adventure.powers.mushroom=1.0
 check(is_equal_approx(game.world.adventure.attack_rect(game.world).size.x,142*1.65),"Giant sprint bite retains the mushroom-scaled contact reach")
 game.world.adventure.powers.mushroom=0.0
 game.world.adventure.attack_cooldown=0
 game.world.adventure.attack_time=0
 game.world.adventure.attack(game.world)
 check(not game.world.adventure.attack_sprinting and game.combat_pose("wolf",false).key=="strikes","A later ordinary attack returns to bite/claw alternation")
 game.world.adventure.attack_time=0.2
 check(game.combat_lunge().x>=24,"Ordinary wolf contact attacks also visibly lunge forward")
 game.character="owl"
 game.world.character="owl"
 game.world.adventure.attack_time=0
 game.world.adventure.attack_cooldown=0
 game.world.y=-70
 game.world.adventure.attack(game.world)
 check(game.world.adventure.attack_airborne and game.combat_pose("owl",false).key=="owl-peck","Airborne owl actually selects its flying beak row")
 var attack_count:int=game.world.adventure.swing_id
 check(not game.world.adventure.request_attack(game.world),"Holding a strike cannot bypass its cooldown")
 check(game.world.adventure.swing_id==attack_count,"Held attack never adds another swing")
 game.world.adventure.attack_time=0
 game.world.state="running"
 game.world.gliding=true
 for gust in [false,true]:
  game.world.riding_gust=gust
  for i in 8:
   game.world.time=float(i)/8
   game.update_friend()
   check(game.friend_sprite.get_meta("source_key")=="agility-owl" and game.friend_sprite.get_meta("source_row")==0,"Glide stays on the same calm row entering or leaving a gust")
   check(game.friend_sprite.position.x==World.PLAYER_X,"Wind and animation never displace the gliding sprite sideways")
 check(bank.pose("strikes",0,3).source_key=="canonical-aion" and bank.pose("strikes",4,3).source_key=="canonical-sheep","Accepted Aion and sheep artwork is unchanged")
 game.queue_free()
 await process_frame
 print("RESULT: %d agility checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
