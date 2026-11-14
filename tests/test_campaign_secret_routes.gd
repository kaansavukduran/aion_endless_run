## Isolated room approach fixtures, not full mission completions.
## Hostiles are removed; actual floors, pits, platforms and jump actions remain.
extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+label)
func _initialize() -> void:call_deferred("run")
func approach(hero: String,leaf: String,index: int) -> bool:
 var w:=AionCampaignWorld.new();w.begin(hero);w.load_section(leaf)
 w.enemies.clear();w.gates.clear();w.objects.clear();w.hazards.clear();w.zones.clear();w.crates.clear();w.pickups.clear()
 var room: Dictionary=w.rooms[index];w.player=Vector2(float(room.x)-350.,0.);w.velocity=Vector2.ZERO
 var release_at:=-1.;var last_jump:=-10.
 for frame in 900:
  if release_at>=0. and w.time>=release_at:w.jump_release();release_at=-1.
  var dx: float=float(room.x)-w.player.x
  var upper: bool=w.player.y<=-139. and absf(dx)<90.
  w.move_axis=Vector2(0. if upper else (1. if dx>35. else -1.),0.)
  if w.grounded() and not w.charging and w.time-last_jump>.6 and w.player.x>=float(room.x)-300. and not upper:
   w.jump_press();last_jump=w.time;release_at=w.time+(.35 if hero in ["rabbit","eren"] else .1)
  if upper and w.grounded():
   w.move_axis=Vector2.ZERO;w.facing=1 if dx>=0 else -1;w.attack_press()
   for i in 40:w.step(.01)
   return w.npcs.any(func(n):return str(n.secret)==str(room.id) and bool(n.freed))
  w.step(.01)
 print("ROOM DIAGNOSTIC ",hero," ",leaf,"/",index," p=",w.player," hp=",w.hp," discovered=",w.discovered)
 return false
func run() -> void:
 for hero in AionCampaignWorld.HEROES:
  for leaf in ["water","terrace","roots"]:
   for index in 2:check(approach(hero,leaf,index),"Ordinary jump/charge actions reach and cut the secret-room captive: %s/%s/%d" % [hero,leaf,index])
 print("RESULT: %d secret approach checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
