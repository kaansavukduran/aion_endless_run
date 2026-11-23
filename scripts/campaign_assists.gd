class_name CampaignAssists
extends RefCounted

const BITE_CONTACT := .15
const BITE_DURATION := .36
const BITE_REACH := 63.
const DROP_POSE := .32

static func summon(w,kind: String) -> void:
	var hero := "owl" if kind=="owl_feather" else "wolf"
	var released_stones: Array=[]
	for old in w.assists:
		if str(old.kind)==hero:released_stones.append_array(old.stones)
	w.assists=w.assists.filter(func(a):return str(a.kind)!=hero)
	var start: float=w.player.x-w.facing*130.
	var floor: float=w.floor_at(start)
	var y: float=w.player.y-170. if hero=="owl" else (floor if CampaignGround.has_floor(floor) else w.player.y)
	w.assists.append({"kind":hero,"remaining":2,"age":0.,"clock":.25,"x":start,"y":y,"facing":w.facing,
		"phase":"follow","phase_age":0.,"stride":0.,"target":"","hit_ids":[],"stones":released_stones})
	w.pending_events.append("pickup")

static func find_target(w,id: String) -> Dictionary:
	if id=="boss":
		if bool(w.boss.active) and bool(w.boss.get("engaged",false)) and int(w.boss.hp)>0:
			return {"id":"boss","x":w.boss.x,"y":w.boss.get("y",0.)}
		return {}
	for e in w.enemies:
		if str(e.id)==id and not bool(e.defeated) and not CampaignEnemies.hidden(e):return e
	return {}

static func target(w,a: Dictionary) -> Dictionary:
	var locked:=find_target(w,str(a.target)) if not str(a.target).is_empty() else {}
	if not locked.is_empty() and absf(float(locked.x)-w.player.x)<1120. and not a.hit_ids.has(str(locked.id)):
		return locked
	var best: Dictionary={};var distance:=1000.
	for e in w.enemies:
		if bool(e.defeated) or CampaignEnemies.hidden(e) or a.hit_ids.has(str(e.id)):continue
		if a.kind=="wolf" and (CampaignContent.flying(str(e.kind)) or absf(float(e.y)-w.floor_at(float(e.x)))>85.):continue
		var d: float=absf(float(e.x)-w.player.x)
		if d<distance:best=e;distance=d
	if best.is_empty():best=find_target(w,"boss")
	return best

static func set_phase(a: Dictionary,phase: String) -> void:
	if a.phase==phase:return
	a.phase=phase;a.phase_age=0.

static func move(w,a: Dictionary,destination: float,speed: float,dt: float,deadzone: float=0.) -> bool:
	var old_x:=float(a.x)
	if absf(old_x-destination)<=deadzone:return false
	var x:=move_toward(old_x,destination,speed*dt)
	if a.kind=="wolf":
		var floor: float=w.floor_at(x)
		if not CampaignGround.has_floor(floor):floor=w.crossing_floor(x,float(a.y)-48.,float(a.y)+52.,1.)
		if not CampaignGround.has_floor(floor):return false
		a.y=floor
	a.x=x;a.facing=1 if x>old_x else -1
	a.stride=float(a.get("stride",0.))+absf(x-old_x)
	return true

static func step_stones(w,a: Dictionary,dt: float) -> void:
	for rock in a.stones:
		rock.vy=float(rock.vy)+750.*dt;rock.y=float(rock.y)+float(rock.vy)*dt;rock.age=float(rock.age)+dt
		var point:=Vector2(float(rock.x),float(rock.y))
		var hit: bool=w.enemies.any(func(e):return not bool(e.defeated) and not CampaignEnemies.hidden(e) and point.distance_to(Vector2(float(e.x),float(e.y)-25.))<30.)
		if hit or float(rock.y)>=w.floor_at(float(rock.x))-6. or float(rock.age)>2.:
			CampaignWeapons.blast(w,point,145.,4,"d7c7a8");rock.age=99.;w.assist_attacks+=1
	a.stones=a.stones.filter(func(r):return float(r.age)<3.)

static func bite(w,a: Dictionary) -> void:
	if a.phase=="bite" and float(a.phase_age)>=BITE_CONTACT:
		a.phase="bite_recover"
		var victim:=find_target(w,str(a.target))
		if not victim.is_empty():
			var dx: float=(float(victim.x)-float(a.x))*float(a.facing)
			if dx>=-8. and dx<=BITE_REACH and absf(float(victim.y)-float(a.y))<72.:
				if victim.id=="boss":w.damage_boss(5)
				else:w.damage_enemy(victim,maxi(5,int(victim.hp)+int(victim.get("armour",0))))
				a.hit_ids.append(str(victim.id));a.remaining=int(a.remaining)-1;w.assist_attacks+=1;a.clock=.55
	if float(a.phase_age)>=BITE_DURATION:
		a.target=""
		set_phase(a,"follow")

static func step(w,dt: float) -> void:
	if w.assists.is_empty():return
	for a in w.assists:
		a.age=float(a.age)+dt;a.clock=maxf(0.,float(a.clock)-dt);a.phase_age=float(a.phase_age)+dt
		step_stones(w,a,dt)
		if float(a.age)>=18.:continue
		# An attack has a planted anchor and a committed facing and victim.
		if a.phase in ["bite","bite_recover"]:
			bite(w,a)
			continue
		if a.phase=="drop" and float(a.phase_age)<DROP_POSE:continue
		if int(a.remaining)<=0:
			set_phase(a,"depart")
			move(w,a,float(a.x)+float(a.facing)*250.,200.,dt)
			if a.kind=="owl":a.y=float(a.y)-80.*dt
			continue
		var e:=target(w,a)
		if e.is_empty():
			a.target=""
			var moved:=move(w,a,w.player.x-w.facing*105.,240.,dt,26.)
			set_phase(a,"fly" if a.kind=="owl" else ("run" if moved else "follow"))
			if a.kind=="owl":a.y=move_toward(float(a.y),w.player.y-170.,125.*dt)
			continue
		a.target=str(e.id)
		var dx:=float(e.x)-float(a.x)
		if a.kind=="owl":
			set_phase(a,"fly")
			move(w,a,float(e.x),500.,dt,12.)
			a.y=move_toward(float(a.y),minf(w.player.y-160.,float(e.y)-180.),250.*dt)
			if absf(dx)<20. and float(a.clock)<=0.:
				a.stones.append({"x":float(a.x),"y":float(a.y)+20.,"vy":50.,"age":0.})
				a.remaining=int(a.remaining)-1;a.clock=1.;a.hit_ids.append(str(e.id));a.target=""
				set_phase(a,"drop")
		elif absf(dx)<43. and float(a.clock)<=0. and absf(float(e.y)-float(a.y))<72.:
			a.facing=1 if dx>=0. else -1
			set_phase(a,"bite")
		else:
			var moved:=move(w,a,float(e.x),455.,dt,35.)
			set_phase(a,"run" if moved else "follow")
	w.assists=w.assists.filter(func(a):return (int(a.remaining)>0 and float(a.age)<18.) or not a.stones.is_empty() or (int(a.remaining)<=0 and float(a.clock)>0.))

static func section_changed(w) -> void:
	for a in w.assists:
		a.x=w.player.x-w.facing*90.;a.y=w.player.y-170. if a.kind=="owl" else w.player.y
		a.phase="follow";a.phase_age=0.;a.clock=.3;a.target="";a.stones=[];a.stride=0.
