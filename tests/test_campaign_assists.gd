## Isolated actual model fixtures, not ordinary-input/browser evidence.
extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;printerr('FAIL: '+message)
func clean() -> AionCampaignWorld:
 var w:=AionCampaignWorld.new();w.begin('aion');w.state='playing';w.player=Vector2(900,0)
 remove_threats(w)
 return w
func remove_threats(w) -> void:
 w.enemies.clear();w.objects.clear();w.hazards.clear();w.zones.clear();w.encounters.clear();w.gates.clear();w.npcs.clear();w.pickups.clear();w.crates.clear();w.platforms.clear();w.pits.clear();w.boss.active=false;w.invulnerable=0.
func enemy(w,x: float,id: int) -> Dictionary:
 # Seed machines stand still; suppress their unrelated firing in this authored
 # support fixture. Damage, helper targeting, falling rocks and movement run.
 w.spawn_enemy('seed',x,0.,id)
 var e: Dictionary=w.enemies[-1];e.wait=1000.;e.windup=0.
 return e
func collect(w,key: String,id: String) -> void:
 w.collect({'id':id,'kind':key})
func advance(w,seconds: float) -> void:
 for i in ceili(seconds/.01):w.step(.01)
func _initialize() -> void:call_deferred('run')
func run() -> void:
 for key in ['owl_feather','wolf_charm']:
  var w:=clean();collect(w,key,key+':1')
  check(w.assists.size()==1 and int(w.assists[0].remaining)==2,'A real pickup summons exactly two charges: '+key)
  advance(w,.4);collect(w,key,key+':2')
  check(w.assists.size()==1 and int(w.assists[0].remaining)==2,'A second real pickup refreshes rather than stacking helpers/charges: '+key)
  collect(w,key,key+':2')
  check(w.assists.size()==1 and int(w.assists[0].remaining)==2,'The same collected item cannot pay/summon twice: '+key)
  advance(w,12.)
  check(w.assist_attacks==0 and int(w.assists[0].remaining)==2,'No enemy means no fabricated hits or spent charges: '+key)
  advance(w,6.)
  check(w.assists.is_empty(),'An unused helper leaves within eighteen active seconds: '+key)
 var w:=clean();collect(w,'owl_feather','both:owl');collect(w,'wolf_charm','both:wolf')
 check(w.assists.size()==2,'Different helper types coexist without replacing one another')
 collect(w,'owl_feather','both:owl2')
 check(w.assists.size()==2 and w.assists.filter(func(a):return a.kind=='owl').size()==1,'Refreshing owl does not delete wolf or create duplicate owls')
 w=clean();collect(w,'owl_feather','owl:combat')
 var owl: Dictionary=w.assists[0]
 var victims: Array[Dictionary]=[enemy(w,500.,1),enemy(w,560.,2),enemy(w,1250.,3),enemy(w,1310.,4)]
 var falling_seen:=false;var previous_y: Dictionary={};var first_impact_kills:=-1
 for tick in 800:
  w.step(.01)
  for rock in owl.stones:
   if previous_y.has(str(rock.x)) and float(rock.y)>float(previous_y[str(rock.x)]):falling_seen=true
   previous_y[str(rock.x)]=float(rock.y)
  if w.assist_attacks==1 and first_impact_kills<0:first_impact_kills=w.kills
 check(falling_seen,'Owl produces actual falling rock motion before impact')
 check(first_impact_kills>=2,'One actual owl impact damages an area rather than only its target')
 check(w.assist_attacks==2 and int(owl.remaining)==0,'Owl performs exactly two actual impact attacks')
 check(victims.all(func(e):return bool(e.defeated)) and w.kills==4,'Two separated owl impacts defeat both real enemy clusters')
 check(w.assists.is_empty(),'Spent owl departs after its final projectile resolves')
 advance(w,3.);check(w.assist_attacks==2,'Spent owl cannot keep emitting attacks')
 w=clean();collect(w,'wolf_charm','wolf:combat')
 var wolf: Dictionary=w.assists[0];var left:=enemy(w,550.,1);var right:=enemy(w,1250.,2)
 var approach_left:=false;var approach_right:=false;var bite_seen:=false
 for tick in 800:
  w.step(.01)
  if wolf.phase=='run':
   approach_left=approach_left or int(wolf.facing)==-1
   approach_right=approach_right or int(wolf.facing)==1
  bite_seen=bite_seen or wolf.phase=='bite'
 check(approach_left and approach_right,'Wolf runs toward real targets on either side of the player')
 check(bite_seen,'Wolf reaches an actual bite windup rather than applying remote instant damage')
 check(bool(left.defeated) and bool(right.defeated) and w.kills==2,'Two wolf bites reach and damage the two real enemy bodies')
 check(w.assist_attacks==2 and int(wolf.remaining)==0 and wolf.hit_ids.size()==2,'Wolf spends exactly two charges on two successful distinct bites')
 check(str(wolf.hit_ids[0])!=str(wolf.hit_ids[1]),'Wolf cannot repeatedly charge the same defeated enemy')
 check(w.assists.is_empty(),'Spent wolf leaves instead of remaining as a phantom playable character')
 # Kill the intended bite victim through the real damage API during windup.
 w=clean();collect(w,'wolf_charm','wolf:cancel');wolf=w.assists[0]
 var doomed:=enemy(w,810.,1);var alternate:=enemy(w,1350.,2)
 for tick in 300:
  w.step(.01)
  if wolf.phase=='bite':break
 check(wolf.phase=='bite' and str(wolf.target)==str(doomed.id),'Cancelled-hit fixture reaches a real bite windup')
 var before: int=w.assist_attacks;w.damage_enemy(doomed,10)
 advance(w,.17)
 check(int(wolf.remaining)==2 and w.assist_attacks==before,'A victim killed before contact does not spend a wolf bite or claim a hit')
 for tick in 400:
  w.step(.01)
  if bool(alternate.defeated):break
 check(bool(alternate.defeated) and int(wolf.remaining)==1 and w.assist_attacks==before+1,'The cancelled charge can be used on the next living enemy')
 # Retain an already released projectile when the pickup refreshes its helper.
 w=clean();collect(w,'owl_feather','owl:refresh:1');owl=w.assists[0]
 var rock_victim:=enemy(w,1180.,1)
 for tick in 300:
  w.step(.01)
  if not owl.stones.is_empty():break
 check(not owl.stones.is_empty(),'Refresh fixture contains an already falling owl stone')
 collect(w,'owl_feather','owl:refresh:2')
 check(w.assists.any(func(a):return not a.stones.is_empty()),'Refreshing an owl preserves its already released falling stone')
 owl=w.assists[0]
 check(int(owl.remaining)==2 and float(owl.age)==0.,'Refreshing replaces future charges and lifetime without duplicating the helper')
 for tick in 100:
  w.step(.01)
  if bool(rock_victim.defeated):break
 check(bool(rock_victim.defeated) and w.assist_attacks==1 and int(owl.remaining)==2,'The preserved pre-refresh stone really impacts its enemy without spending a refreshed charge')
 # A released stone may finish after expiry, but may not keep the helper
 # alive long enough to launch another attack after its lifetime budget.
 w=clean();collect(w,'owl_feather','owl:late');owl=w.assists[0]
 var late_target:=enemy(w,900.,1);late_target.y=-700.;late_target.home=Vector2(900,-700.)
 enemy(w,1000.,2);owl.age=17.5;owl.x=900.;owl.y=-900.;owl.clock=0.
 w.step(.01)
 check(not owl.stones.is_empty() and int(owl.remaining)==1,'Late-life fixture launches one physical stone before expiry')
 w.damage_enemy(late_target,10)
 advance(w,1.05)
 check(int(owl.remaining)==1,'An unresolved old stone does not permit a new attack after eighteen active seconds')
 check(not owl.stones.is_empty() and w.assist_attacks==0,'At expiry a previously released high-altitude stone continues its physical fall')
 advance(w,1.1)
 check(w.assist_attacks==1 and w.assists.is_empty(),'The last pre-expiry stone impacts once and the expired helper then leaves')
 # Section transition is a position reset, not an invented extra charge.
 for key in ['owl_feather','wolf_charm']:
  w=clean();collect(w,key,'transition:'+key);var a: Dictionary=w.assists[0];a.remaining=1;a.x=6000.;a.y=-900.;a.age=10.
  if key=='owl_feather':a.stones.append({'x':6000.,'y':-900.,'vy':50.,'age':.2})
  w.load_section('quay')
  check(w.assists.size()==1 and int(w.assists[0].remaining)==1,'A real section load preserves outstanding charges: '+key)
  check(absf(float(w.assists[0].x)-w.player.x)<=130. and absf(float(w.assists[0].y)-w.player.y)<=180.,'A section load repositions the helper near the new player instead of offscreen: '+key)
  check(str(w.assists[0].phase)=='follow' and str(w.assists[0].target).is_empty(),'A section load clears obsolete target/windup coordinates: '+key)
  check(float(w.assists[0].age)==10.,'A section load preserves elapsed lifetime rather than granting eighteen extra seconds: '+key)
  check(w.assists[0].stones.is_empty(),'A section load clears old-map projectile coordinates: '+key)
  remove_threats(w);w.state='playing';advance(w,8.1)
  check(w.assists.is_empty(),'A helper expires on its original lifetime budget across section changes: '+key)
 # Unknown powerup cannot silently become a wolf/spider or another asset.
 w=clean();collect(w,'unknown_support','unknown')
 check(w.assists.is_empty(),'An unknown pickup does not silently summon a fallback helper')
 var art:=M1SupportArt.new()
 for key in ['owl_feather','wolf_charm','owl_stone','satchel']:
  check(M1SupportArt.DATA.data.frames.has(key+':0'),'The actual helper/prop key has explicitly registered artwork: '+key)
  var pose: Dictionary=art.pose(key)
  check(str(pose.source_row)==key and pose.texture.get_width()>8 and pose.texture.get_height()>8,'The renderer loads the requested named support artwork: '+key)
 check(not M1SupportArt.DATA.data.frames.has('unknown_support:0'),'Unknown support art has no registered fallback alias')
 print('RESULT: ',checks,' campaign assist checks, ',failures,' failures');quit(1 if failures else 0)
