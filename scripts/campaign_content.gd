class_name CampaignContent
extends RefCounted

## Draft game-content identities, not new approved AIONIA canon.
const REGIONS := {"water":["leech","hopper","siphon"],"terrace":["kite","mirror","vine"],"roots":["burrow","conductor","mimic"]}
const HEAVIES := ["sweeper","glider","borer","patrol"]
const NEW_ENEMIES := {
	"leech":{"family":"canal","atlas":"water-enemies","row":0,"radius":30.,"range":140.,"speed":120.,"flying":false},
	"hopper":{"family":"canal","atlas":"water-enemies","row":4,"radius":28.,"range":260.,"speed":110.,"flying":false},
	"siphon":{"family":"canal","atlas":"water-enemies","row":8,"radius":28.,"range":360.,"speed":65.,"flying":true},
	"kite":{"family":"garden","atlas":"garden-enemies","row":0,"radius":32.,"range":440.,"speed":105.,"flying":true},
	"mirror":{"family":"garden","atlas":"garden-enemies","row":4,"radius":32.,"range":300.,"speed":45.,"flying":false},
	"vine":{"family":"garden","atlas":"garden-enemies","row":8,"radius":35.,"range":230.,"speed":0.,"flying":false},
	"burrow":{"family":"roots","atlas":"root-enemies","row":0,"radius":30.,"range":230.,"speed":90.,"flying":false},
	"conductor":{"family":"roots","atlas":"root-enemies","row":4,"radius":32.,"range":400.,"speed":35.,"flying":false},
	"mimic":{"family":"roots","atlas":"root-enemies","row":8,"radius":34.,"range":180.,"speed":140.,"flying":false}
}
const SCENES := {"water":["moss_water","deep_channel","sunken_station"],"terrace":["hanging_gardens","wind_terraces","glass_greenhouse"],"roots":["root_corridor","crystal_hollow","drill_chamber"]}
const OBJECTS := ["planks","gate","lamp","relay","bridge","current","updraft","rock","surprise","cage","turret","panel"]

static func flying(kind: String) -> bool:
	return kind in ["crow","moth","drone","wisp","glider"] or (NEW_ENEMIES.has(kind) and bool(NEW_ENEMIES[kind].flying))

static func populate(w) -> void:
	w.encounters.clear();w.objects.clear();w.zones.clear();w.rooms.clear();w.hazards.clear()
	var regional: Array=REGIONS.get(w.section,[])
	var is_leaf: bool=not regional.is_empty()
	if not is_leaf and w.section!="arena":regional=["gnome","seed","crow"] if w.section!="quay" else ["drone","beetle","gnome"]
	if not regional.is_empty():
		var count: int=6 if is_leaf else (2 if w.section=="canopy" else 4)
		for i in count:
			var x: float=lerpf(1600. if is_leaf else 2200.,w.length()-1700.,float(i)/maxf(1.,count-1))
			var ids: Array[String]=[]
			for k in 5:
				var kind: String=regional[k%3] if k<3 else ["gnome","crow","seed","beetle","drone","slime"][i]
				w.spawn_enemy(kind,x+120.*k,-120. if flying(kind) else 0.,300+i*10+k)
				ids.append(w.section+":enemy:"+str(300+i*10+k))
			w.gates.append({"x":x+720.,"ids":ids})
			w.encounters.append({"id":w.section+":encounter:"+str(i),"x":x,"scene":SCENES[w.section][i/2] if is_leaf else w.section,"enemies":ids})
	if is_leaf:
		for i in 2:
			var x: float=w.length()*(.30 if i==0 else .68)
			var id: String=w.section+":secret:"+str(i)
			w.rooms.append({"id":id,"x":x,"y":-140.,"width":270.,"opened":w.discovered.has(id)})
			w.objects.append({"id":id+":door","kind":"rock" if w.section=="roots" else "panel","x":x-175.,"y":0.,"hp":2,"active":w.discovered.has(id),"secret":id})
			for j in 2:
				w.platforms.append(Rect2(x-290.+j*155.,-65.-j*75.,145.,18.))
			for j in 3:w.pickups.append({"id":id+":loot:"+str(j),"x":x-65.+j*65.,"y":-178.,"kind":["magnet","reveal","points"][j],"secret":id})
		var heavy: String={"water":"sweeper","terrace":"glider","roots":"borer"}[w.section]
		w.spawn_enemy(heavy,w.length()*.62,-90. if heavy=="glider" else 0.,700)
		w.mount={"available":true,"ridden":false,"x":600.,"hp":4,"type":{"water":"shell","terrace":"wind","roots":"drill"}[w.section],"hurt":0.,"wreck_age":0.}
		w.zones.append({"id":w.section+":flow","kind":"current" if w.section=="water" else ("updraft" if w.section=="terrace" else "dark"),"x":w.length()*.4,"width":900.})
		for i in 2:w.hazards.append({"id":w.section+":hazard:"+str(i),"kind":("electric" if i==0 else "sluice") if w.section=="water" else (("vines" if i==0 else "gust") if w.section=="terrace" else ("claw" if i==0 else "crystal")),"x":w.length()*(.43+i*.29),"clock":float(i),"phase":0.,"warn":false})
	if w.section=="relay":w.spawn_enemy("patrol",w.length()*.65,0.,700)
	if w.section!="arena":
		for i in 6:
			var kind: String=OBJECTS[(i+abs(w.section.hash()))%OBJECTS.size()]
			var x: float=lerpf(450.,w.length()-600.,float(i)/5.)
			if w.floor_at(x)!=0.:continue
			w.objects.append({"id":w.section+":object:"+str(i),"kind":kind,"x":x,"y":0.,"hp":2,"active":w.activated.has(w.section+":object:"+str(i)),"secret":""})
			if kind=="planks":w.platforms.append(Rect2(x-80.,-55.,160.,18.))
		# The first coast lamps establish a visible change, not a tutorial modal.
		if w.section=="shore":
			for i in 2:w.objects.append({"id":"shore:lamp:"+str(i),"kind":"lamp","x":720.+i*600.,"y":0.,"hp":1,"active":w.activated.has("shore:lamp:"+str(i)),"secret":""})
	for i in w.crates.size():w.crates[i].kind=(CampaignWeapons.SPECIAL+["heal","shield","grenade","repair","haste","power","reveal","magnet"])[i%18]
	for e in w.enemies:
		if bool(e.mini):
			e.mini_role={"water":"current_guard","terrace":"terrace_guard","roots":"drill_guard"}.get(w.section,"current_guard")
			if e.mini_role=="drill_guard":e.armour=2
	for p in w.pickups:
		if p.kind=="repair" and w.section not in ["water","quay","terrace","roots"]:p.kind="grenade"
	for o in w.objects:
		if bool(o.active):apply_surface(w,o)

static func apply_surface(w,o: Dictionary) -> void:
	# Persistent machinery must restore its collision geometry, too.
	if o.kind=="bridge":
		var surface:=Rect2(float(o.x)-130.,-55.,260.,18.)
		if not w.platforms.has(surface):w.platforms.append(surface)
	elif o.kind=="planks":w.platforms=w.platforms.filter(func(p):return not is_equal_approx(p.position.x,float(o.x)-80.))

static func hit_object(w,p: Vector2,damage: int,from: Vector2=Vector2.INF) -> bool:
	for o in w.objects:
		if bool(o.active) or str(o.kind) in ["current","updraft"]:continue
		var target:=Vector2(float(o.x),float(o.y)-35.)
		var nearest: Vector2=p if not from.is_finite() else Geometry2D.get_closest_point_to_segment(target,from,p)
		if nearest.distance_to(target)>45.:continue
		o.hp=int(o.hp)-damage
		if int(o.hp)<=0:
			o.active=true;w.activated[str(o.id)]=true;w.pending_events.append("mechanism")
			o.changed=0.
			if str(o.secret)!="":
				w.discovered[str(o.secret)]=true;w.award(str(o.secret),250);w.notice="arc_secret";w.notice_time=2.;w.pending_events.append("secret")
			if o.kind in ["lamp","panel","relay","turret"] and not w.awarded.has(str(o.id)+":power"):
				w.shield=mini(3,w.shield+1);w.award(str(o.id)+":power",0)
			if o.kind in ["surprise","planks","rock"]:w.pickups.append({"id":str(o.id)+":gift","x":o.x,"y":-35.,"kind":"points"})
			apply_surface(w,o)
			if o.kind=="relay":w.notice="arc_maintenance";w.notice_time=3.
		return true
	return false

static func step(w,dt: float) -> void:
	for key in w.buffs:w.buffs[key]=maxf(0.,float(w.buffs[key])-dt)
	w.mount.hurt=maxf(0.,float(w.mount.get("hurt",0.))-dt)
	for o in w.objects:
		if bool(o.active):o.changed=float(o.get("changed",9.))+dt
		if o.kind=="gate" and not bool(o.active) and w.player.y>float(o.y)-80. and w.player.x>float(o.x)-40. and w.player.x<float(o.x)+45.:w.player.x=float(o.x)-40.
		if o.kind=="turret" and not bool(o.active) and absf(w.player.x-float(o.x))<500.:
			o.clock=float(o.get("clock",0.))+dt
			if fmod(float(o.clock),3.)<dt:
				var origin:=Vector2(float(o.x),-45.);var velocity: Vector2=(w.player+Vector2(0,-38.)-origin).normalized()*200.
				w.bullets.append({"p":origin,"v":velocity,"owner":"enemy","age":0.,"kind":"seed","damage":1,"pierce":0,"hit":[]})
		if o.kind in ["current","updraft"] and absf(w.player.x-float(o.x))<110.:
			if o.kind=="current" and w.grounded():w.player.x+=32.*dt
			elif o.kind=="updraft" and not w.grounded():w.velocity.y-=1000.*dt
	if not bool(w.mount.available):w.mount.wreck_age=float(w.mount.get("wreck_age",0.))+dt
	for room in w.rooms:
		if w.discovered.has(str(room.id)):room.opened=true
		if not bool(room.opened) and absf(w.player.x-float(room.x))<100. and w.player.y < -90.:
			w.discovered[str(room.id)]=true;room.opened=true;w.award(str(room.id),250);w.notice="arc_secret";w.notice_time=2.;w.pending_events.append("secret")
	for h in w.hazards:
		h.clock=float(h.clock)+dt;h.phase=fmod(float(h.clock),4.8);h.warn=float(h.phase)>2.6 and float(h.phase)<3.5
		if float(h.phase)>=3.5 and float(h.phase)<4.1 and int(h.get("last_pulse",-1))!=int(float(h.clock)/4.8):
			h.last_pulse=int(float(h.clock)/4.8)
			if h.kind=="crystal":
				for direction in [-1.,1.]:w.bullets.append({"p":Vector2(float(h.x),-115.),"v":Vector2(direction*220.,0.),"owner":"enemy","age":0.,"kind":"crystal","damage":1,"pierce":0,"hit":[]})
			if absf(w.player.x-float(h.x))<50.:
				if h.kind=="gust" and w.player.y< -40.:w.player.x-=70.;w.velocity.y=-180.
				elif h.kind=="sluice" and w.player.y> -60.:w.player.x-=60.;w.velocity.y=-200.
				elif h.kind not in ["gust","sluice","crystal"] and w.player.y> -90.:
					if not (h.kind=="electric" and bool(w.mount.ridden) and float(w.mount.get("dive",0.))>0.):w.damage_player("hazard")
	w.hazards=w.hazards.filter(func(h):return not bool(h.get("once",false)) or float(h.clock)<4.2)
	for z in w.zones:
		if w.player.x<float(z.x) or w.player.x>float(z.x)+float(z.width):continue
		if z.kind=="current" and w.grounded() and not bool(w.mount.ridden):w.player.x+=36.*dt
		if z.kind=="updraft" and not w.grounded():w.velocity.y-=1100.*dt
	if float(w.buffs.get("magnet",0.))>0.:
		for p in w.pickups:
			var point:=Vector2(float(p.x),float(p.y))
			if point.distance_to(w.player)<250.:point=point.move_toward(w.player,320.*dt);p.x=point.x;p.y=point.y
	# Late boss phases alter one optional platform, keeping the floor safe.
	w.disabled_platforms.clear()
	for x in w.platform_timers:
		w.platform_timers[x]=maxf(0.,float(w.platform_timers[x])-dt)
		if float(w.platform_timers[x])>0.:w.disabled_platforms[x]=true
	if w.section=="arena" and int(w.boss.phase)>=2 and fmod(float(w.boss.clock),7.)>3.5:w.disabled_platforms[690.]=true
