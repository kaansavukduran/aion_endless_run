extends SceneTree
const World=preload("res://scripts/world.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+label)
func arena():
 var w=World.new();w.reset();w.adventure.item_wait=999.;w.obstacle_wait=999.;w.frontier.plant_wait=999.;w.adventure.ambient_gnome_wait=999.;return w
func _initialize():call_deferred("run")
func run():
 for hero in ["owl","wolf","invalid"]:
  var w=World.new();w.character=hero;w.reset();check(w.character=="aion","Removed/invalid stored hero safely falls back: "+hero)
 for hero in ["aion","sheep","rabbit","eren"]:
  var w=World.new();w.character=hero;w.reset();check(w.character==hero,"Playable identity retained: "+hero)
 var bagworld=arena();bagworld.adventure.mushroom_chance=0.
 var found=[]
 for i in 11:found.append(bagworld.adventure.choose_power(bagworld))
 check(found.has("owl_feather") and found.has("wolf_charm"),"Both real companion pickups enter the normal item bag")
 var w=arena();w.adventure.collect(w,"owl_feather")
 check(w.adventure.assists.size()==1 and int(w.adventure.assists[0].charges)==2,"Owl starts with exactly two stones")
 for i in 60:w.adventure.step_assists(w,1./60.,0.)
 check(int(w.adventure.assists[0].charges)==2,"No target does not consume owl attacks")
 var enemies=[]
 for x in [600.,800.,1000.]:enemies.append(w.adventure.spawn_enemy(w,"gnome",x))
 for i in 150:w.adventure.step_assists(w,1./60.,0.)
 check(enemies.filter(func(e):return int(e.hp)<=0).size()==2,"Owl drops exactly two separated attacks")
 check(w.adventure.assists.is_empty(),"Owl exits after completing both attacks")
 var aoe=arena();aoe.adventure.collect(aoe,"owl_feather")
 var a=aoe.adventure.spawn_enemy(aoe,"gnome",600.);var b=aoe.adventure.spawn_enemy(aoe,"crow",650.,-95.)
 for i in 45:aoe.adventure.step_assists(aoe,1./60.,0.)
 check(a.hp==0 and b.hp==0,"A falling stone has genuine area damage, including airborne targets")
 var wolf=arena();wolf.adventure.collect(wolf,"wolf_charm")
 var targets=[]
 for x in [500.,740.,980.]:targets.append(wolf.adventure.spawn_enemy(wolf,"gnome",x))
 for i in 180:wolf.adventure.step_assists(wolf,1./60.,0.)
 check(targets.filter(func(e):return int(e.hp)<=0).size()==2,"Wolf runs and bites exactly two targets")
 check(wolf.adventure.assists.is_empty(),"Wolf exits after its second bite")
 var wait=arena();wait.adventure.collect(wait,"wolf_charm")
 var crow=wait.adventure.spawn_enemy(wait,"crow",500.,-150.)
 for i in 60:wait.adventure.step_assists(wait,1./60.,0.)
 check(crow.hp==1 and int(wait.adventure.assists[0].charges)==2,"Ground wolf does not float up to bite flying enemies")
 wait.adventure.collect(wait,"wolf_charm")
 check(wait.adventure.assists.size()==1 and int(wait.adventure.assists[0].charges)==2,"Recollection replaces charges rather than stacking helpers")
 for i in 800:wait.adventure.step_assists(wait,1./60.,0.)
 check(wait.adventure.assists.is_empty(),"Untargeted helper has a bounded twelve-second lifetime")
 var pause=arena();pause.adventure.collect(pause,"owl_feather");pause.frontier.phase="fight"
 for i in 300:pause.adventure.step_assists(pause,1./60.,0.)
 check(float(pause.adventure.assists[0].age)==0. and int(pause.adventure.assists[0].charges)==2,"Legacy boss playfield pauses ordinary helper clocks")
 var dive=arena();var e=dive.adventure.spawn_enemy(dive,"crow",World.PLAYER_X+250.,-86.)
 var old: float=e.x;dive.adventure.after_step(dive,1./60.,10.,-250.)
 check(absf((old-float(e.x))-10.*1.13*.9)<.001,"Only forward diving crow speed is reduced by ten percent")
 var high=dive.adventure.spawn_enemy(dive,"crow",World.PLAYER_X+250.,-154.)
 old=high.x;dive.adventure.after_step(dive,1./60.,10.,-250.)
 check(absf((old-float(high.x))-10.*1.13)<.001,"Ordinary high flight retains its previous speed")
 print("RESULT: ",checks," endless companion checks, ",failures," failures");quit(1 if failures else 0)
