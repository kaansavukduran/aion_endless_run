## Deterministic model playthrough via the same action API as UI.
## No teleport, damage injection, invulnerability or enemy removal.
extends SceneTree
var results: Array=[]
func _initialize() -> void:call_deferred("run")
func run_case(hero: String,leaf: String) -> Dictionary:
 var w:=AionCampaignWorld.new();w.begin(hero);w.run_seed=7719;w.load_section("shore")
 var retries:=0;var frames:=0;var last_jump:=-10.;var last_cut:=-10.;var last_bomb:=-10.;var release_jump:=-1.;var stalled:=0.;var previous_x:=0.;var last_stage:="";var stages: Array=[];var settled_until:=0.;var fire:=false
 while frames<120000:
  frames+=1
  if w.section!=last_stage:stages.append(w.section);print("STAGE ",hero,"/",leaf," ",w.section," HP ",w.hp);last_stage=w.section
  if w.state=="complete":break
  if w.state=="dying":w.step(.02);continue
  if w.state=="dead":break
  if w.state=="continue_offer":
   retries+=1
   if retries>8:break
   CampaignLives.open_picker(w);CampaignLives.confirm(w,hero)
  if w.state=="respawn_pending":
   CampaignLives.start_entry(w,Rect2(maxf(0.,w.player.x-400.),-420.,1152.,600.));fire=false;settled_until=0.;last_jump=-10.
  if w.state=="respawn":w.step(.02);continue
  if w.state=="travel":w.finish_travel();fire=false;continue
  if w.state=="fork_one":w.choose_route("water" if leaf=="water" else "canopy");fire=false;continue
  if w.state=="fork_two":w.choose_route(leaf);fire=false;continue
  if w.state=="victory":w.step(.02);continue
  # Same boss-intro acknowledgement boundary used by the UI.
  if w.section=="arena" and w.player.x>float(w.boss.x)-690.:w.boss.engaged=true
  if release_jump>=0. and w.time>=release_jump:w.jump_release();release_jump=-1.
  var x:=w.player.x;var y:=w.player.y;var direction:=1.;var want_fire:=true
  var targets: Array=w.enemies.filter(func(e):return not bool(e.defeated) and absf(float(e.x)-x)<680.)
  targets.sort_custom(func(a,b):return absf(float(a.x)-x)<absf(float(b.x)-x))
  var target: Dictionary=targets[0] if not targets.is_empty() else {}
  var closed: bool=w.gates.any(func(g):return w.gate_closed(g) and float(g.x)-x>=0. and float(g.x)-x<180.)
  if not target.is_empty() and (closed or absf(float(target.x)-x)<320.):
   direction=signf(float(target.x)-x)
   if flyer_target(target) and absf(float(target.x)-x)<280.:direction=0. if w.facing==int(signf(float(target.x)-x)) else signf(float(target.x)-x)
  if w.section=="arena" and bool(w.boss.engaged):
   var desired: float=float(w.boss.x)-(210.+float(retries%3)*20.)
   direction=signf(desired-x) if absf(desired-x)>35. else (1. if w.facing<0 else 0.)
   if not target.is_empty() and absf(float(target.x)-x)<450.:direction=0. if w.facing==int(signf(float(target.x)-x)) else signf(float(target.x)-x)
   if float(w.boss.get("beam_warning",0.))>0. and absf(x-float(w.boss.beam_x))<95.:direction=-1.
   if target.is_empty() and w.facing<0. and direction==0.:direction=1.
   if int(w.boss.attack)%3==1:direction=-1.
  var danger:=w.bullets.any(func(b):return b.owner=="enemy" and Vector2(b.p).distance_to(w.player+Vector2(0,-37.))<(230. if hero in ["rabbit","eren"] else 100.))
  var flyer: bool=not target.is_empty() and float(target.y)<-65. and absf(float(target.x)-x)<450.
  var gap: bool=w.pits.any(func(p):return p.x-x>0. and p.x-x<(90. if hero in ["rabbit","eren"] else 150.))
  var object_gate: bool=w.objects.any(func(o):return o.kind=="gate" and not bool(o.active) and float(o.x)-x>0. and float(o.x)-x<100.)
  var jump: bool=(danger or flyer or gap or (object_gate and target.is_empty())) and w.time-last_jump>.85
  if w.section=="arena" and int(w.boss.attack)%3==1:jump=false # Outrun the fan; charging would slow the rabbit into it.
  var n:=CampaignRescue.nearest(w)
  if not n.is_empty() and (target.is_empty() or absf(float(target.x)-x)>200.) and w.time-last_cut>1.5 and w.grounded():
   w.attack_release();fire=false;w.attack_press();last_cut=w.time;settled_until=w.time+1.3
  if flyer and absf((w.player.y+w.muzzle_offset().y)-(float(target.y)-30.))>32.:want_fire=false
  if w.time<settled_until:direction=0.;want_fire=false;jump=false
  if w.rescue_time>0.:direction=0.;want_fire=false;jump=false
  w.move_axis=Vector2(direction,0)
  if want_fire and not fire:w.attack_press();fire=true
  elif not want_fire and fire:w.attack_release();fire=false
  if not w.close_enemy().is_empty() and w.time-last_cut>.35 and fire:w.attack_release();w.attack_press();last_cut=w.time
  if jump and w.grounded():
   w.jump_press();release_jump=w.time+((.55 if flyer else .35) if hero in ["rabbit","eren"] else (.7 if hero=="owl" else .12));last_jump=w.time
  if hero=="owl" and flyer and not w.grounded() and w.velocity.y>0. and w.player.y>float(target.y)+45. and w.flap_count<3 and w.time-last_jump>.4:
   w.jump_release();w.jump_press();release_jump=w.time+.7;last_jump=w.time
  if w.grenades>0 and w.time-last_bomb>3. and ((not target.is_empty() and (bool(target.mini) or bool(target.get("heavy",false)))) or targets.size()>=3 or (w.section=="arena" and bool(w.boss.engaged) and (hero not in ["rabbit","eren"] or int(w.boss.phase)>=2) and absf(float(w.boss.x)-x)<430.)):
   w.throw_grenade();last_bomb=w.time
  var hp_before:=w.hp;var boss_before: int=w.boss.hp
  w.step(.02)
  if OS.get_environment("AION_PLAY_TRACE")=="1" and w.section=="arena" and (hp_before!=w.hp or (boss_before!=int(w.boss.hp) and int(w.boss.hp)%10==0)):
   print("TRACE ",w.time," p=",w.player," hp=",w.hp," boss=",w.boss.hp," phase=",w.boss.phase," vy=",w.velocity.y," fire=",fire," melee=",w.melee_time," enemy=",target," bullets=",w.bullets.filter(func(b):return b.owner=="enemy" and Vector2(b.p).distance_to(w.player)<120.))
  w.pending_events.clear()
  # Time without horizontal progress is a diagnostic, not a bypass.
  stalled=stalled+.02 if absf(w.player.x-previous_x)<.1 else 0.;previous_x=w.player.x
  if stalled>90.:break
 var result: Dictionary={"hero":hero,"route":leaf,"completed":w.completed,"state":w.state,"section":w.section,"x":w.player.x,"y":w.player.y,"weapon":w.weapon,"objects":w.objects.filter(func(o):return not bool(o.active) and absf(float(o.x)-w.player.x)<150.),"hp":w.hp,"boss_hp":w.boss.hp,"seconds":w.time,"retries":retries,"rescues":w.rescued.size(),"stages":stages,"frames":frames,"remaining":w.enemies.filter(func(e):return not bool(e.defeated) and absf(float(e.x)-w.player.x)<800.)}
 print(JSON.stringify(result));return result
func flyer_target(e: Dictionary) -> bool:return float(e.y)<-65.
func run() -> void:
 var heroes: Array=AionCampaignWorld.HEROES
 if OS.get_environment("AION_PLAY_HERO")!="":heroes=[OS.get_environment("AION_PLAY_HERO")]
 var leaves: Array=["water","terrace","roots"]
 if OS.get_environment("AION_PLAY_ROUTE")!="":leaves=[OS.get_environment("AION_PLAY_ROUTE")]
 for hero in heroes:
  for leaf in leaves:results.append(run_case(hero,leaf))
 var output:=OS.get_environment("AION_PLAY_RESULTS")
 if output!="":var file:=FileAccess.open(output,FileAccess.WRITE);file.store_string(JSON.stringify(results,"  "))
 var failed:=results.filter(func(r):return not bool(r.completed)).size()
 print("RESULT: %d model route completions, %d failures" % [results.size(),failed]);quit(1 if failed else 0)
