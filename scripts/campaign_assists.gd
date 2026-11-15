class_name CampaignAssists
extends RefCounted

static func summon(w,kind: String) -> void:
 var hero: String='owl' if kind=='owl_feather' else 'wolf'
 var released_stones: Array=[]
 for old in w.assists:
  if str(old.kind)==hero:released_stones.append_array(old.stones)
 w.assists=w.assists.filter(func(a):return str(a.kind)!=hero)
 w.assists.append({'kind':hero,'remaining':2,'age':0.,'clock':.25,'x':w.player.x-130.,'y':w.player.y-170. if hero=='owl' else w.floor_at(w.player.x),'facing':w.facing,'phase':'follow','phase_age':0.,'target':'','hit_ids':[],'stones':released_stones})
 w.pending_events.append('pickup')

static func target(w,a: Dictionary) -> Dictionary:
 var best: Dictionary={};var distance:=INF
 for e in w.enemies:
  if bool(e.defeated) or a.hit_ids.has(str(e.id)):continue
  if str(a.kind)=='wolf' and absf(float(e.y)-w.floor_at(float(e.x)))>160.:continue
  var d: float=absf(float(e.x)-w.player.x)
  if d<distance and d<1000.:best=e;distance=d
 if best.is_empty() and bool(w.boss.active) and bool(w.boss.get('engaged',false)):
  best={'id':'boss','x':w.boss.x,'y':w.boss.get('y',0.)}
 return best

static func step(w,dt: float) -> void:
 for a in w.assists:
  a.age=float(a.age)+dt;a.clock=maxf(0.,float(a.clock)-dt);a.phase_age=float(a.phase_age)+dt
  for rock in a.stones:
   rock.vy=float(rock.vy)+750.*dt;rock.y=float(rock.y)+float(rock.vy)*dt;rock.age=float(rock.age)+dt
   var point:=Vector2(float(rock.x),float(rock.y))
   var hits: bool=w.enemies.any(func(e):return not bool(e.defeated) and point.distance_to(Vector2(float(e.x),float(e.y)-25.))<30.)
   if hits or float(rock.y)>=w.floor_at(float(rock.x))-6. or float(rock.age)>2.:
    CampaignWeapons.blast(w,point,145.,4,'d7c7a8');rock.age=99.;w.assist_attacks+=1
  a.stones=a.stones.filter(func(r):return float(r.age)<3.)
  # Expiry stops new attacks while already-released rocks finish falling.
  if float(a.age)>=18.:continue
  if int(a.remaining)<=0:
   a.x=float(a.x)+float(a.facing)*200.*dt
   if a.kind=='owl':a.y=float(a.y)-80.*dt
   continue
  var e: Dictionary=target(w,a)
  if e.is_empty():
   a.phase='follow';a.x=move_toward(float(a.x),w.player.x-w.facing*95.,240.*dt);a.y=move_toward(float(a.y),w.player.y-170. if a.kind=='owl' else w.floor_at(float(a.x)),300.*dt)
   continue
  a.facing=1 if float(e.x)>float(a.x) else -1
  if a.kind=='owl':
   a.phase='fly';a.x=move_toward(float(a.x),float(e.x),560.*dt);a.y=move_toward(float(a.y),minf(w.player.y-160.,float(e.y)-180.),350.*dt)
   if absf(float(a.x)-float(e.x))<20. and float(a.clock)<=0.:
    a.stones.append({'x':float(a.x),'y':float(a.y)+20.,'vy':50.,'age':0.});a.remaining=int(a.remaining)-1;a.clock=1.;a.hit_ids.append(str(e.id));a.phase='drop';a.phase_age=0.
  else:
   if str(a.phase)=='bite':
    if float(a.phase_age)>=.15:
     var hit:=false
     if str(a.target)=='boss' and bool(w.boss.active) and int(w.boss.hp)>0:w.damage_boss(5);hit=true
     else:
      for victim in w.enemies:
       if str(victim.id)==str(a.target) and not bool(victim.defeated):w.damage_enemy(victim,maxi(5,int(victim.hp)+int(victim.get('armour',0))));hit=true
     if hit:
      a.hit_ids.append(str(a.target));a.remaining=int(a.remaining)-1;w.assist_attacks+=1;a.clock=.55
     a.phase='run';a.phase_age=0.

   else:
    a.phase='run';a.x=move_toward(float(a.x),float(e.x),490.*dt);a.y=move_toward(float(a.y),minf(w.floor_at(float(a.x)),float(e.y)),500.*dt)
    if absf(float(a.x)-float(e.x))<45. and float(a.clock)<=0.:a.phase='bite';a.phase_age=0.;a.target=str(e.id)
 w.assists=w.assists.filter(func(a):return (int(a.remaining)>0 and float(a.age)<18.) or not a.stones.is_empty() or (int(a.remaining)<=0 and float(a.clock)>0.))

static func section_changed(w) -> void:
 for a in w.assists:
  a.x=w.player.x-w.facing*90.;a.y=w.player.y-170. if a.kind=='owl' else w.player.y
  a.phase='follow';a.phase_age=0.;a.clock=.3;a.target='';a.stones=[]
