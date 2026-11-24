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

## Hand-authored leaf encounters. Each card is a small game state: the cue the
## player sees, the decision, the counter that works, and its reward. A role is
## taught alone, repeated on changed ground (pit, current, wind, darkness), then
## combined with a known role; only the pincer and the exam close a gate.
## Positions are fractions of the route length and line up with the route's
## zone (.40), hazards (.43/.72), heavy (.62) and optional rooms (.30/.68).
const AUTHORED := {
	"water":[
		{"at":.06,"members":[["leech",0.]],"cue":"leech coils before a ground lunge","decision":"hold ground or jump","counter":"jump the lunge, shoot on landing","reward":"safe first kill"},
		{"at":.12,"members":[["hopper",0.]],"cue":"hopper bounces beside a canal pit","decision":"aim with its height","counter":"diagonal shot at the top of its hop","reward":"pit crossed"},
		{"at":.18,"members":[["leech",0.],["hopper",260.]],"gate":true,"cue":"lunge from the front, hop from behind","decision":"which threat first","counter":"jump the leech, shoot the hopper high","reward":"gate opens"},
		{"at":.25,"members":[["siphon",0.]],"cue":"a siphon drains the nearby lamp","decision":"notice the support role","counter":"shoot up before it drifts out of range","reward":"lamp relit, shield chance"},
		{"at":.41,"members":[["hopper",120.],["hopper",430.]],"cue":"the current pushes you forward","decision":"fight while being carried","counter":"walk back against the current while firing","reward":"current exit"},
		{"at":.50,"members":[["siphon",0.],["leech",220.]],"cue":"the siphon now covers a lunger","decision":"kill the support before the brawler","counter":"shoot up at the siphon, then jump the leech","reward":"breathing room"},
		{"at":.57,"members":[["drone",0.],["slime",160.]],"cue":"light pests before the heavy","decision":"spend special ammo or keep it","counter":"pistol them, save ammo for the sweeper","reward":"ammo saved"},
		{"at":.80,"members":[["leech",0.],["hopper",200.],["siphon",380.]],"gate":true,"cue":"all three canal roles together","decision":"priority under pressure","counter":"siphon, hopper, then leech","reward":"guardian approach"}
	],
	"terrace":[
		{"at":.06,"members":[["mirror",0.]],"cue":"mirror holds a slow firing line","decision":"trade shots or move","counter":"jump its shot and fire on the way down","reward":"safe first kill"},
		{"at":.12,"members":[["kite",0.]],"cue":"kite fans two shots from the air","decision":"where to stand","counter":"step between the fan, shoot up","reward":"high ground"},
		{"at":.18,"members":[["mirror",0.],["kite",240.]],"gate":true,"cue":"a ground line under an air fan","decision":"which line to break","counter":"kite first from a platform, then jump the mirror's shot","reward":"gate opens"},
		{"at":.27,"members":[["vine",0.]],"cue":"a vine sweeps the floor after a short shiver","decision":"time the crossing","counter":"stay out of its reach or cross over a platform","reward":"clear lane"},
		{"at":.41,"members":[["kite",0.],["kite",300.]],"cue":"updraft lifts every jump","decision":"use the lift to reach them","counter":"ride the updraft and fire diagonally","reward":"aerial clear"},
		{"at":.50,"members":[["vine",0.],["crow",150.]],"cue":"a crow dives over a vine","decision":"stay high or low","counter":"take a platform over the vine, shoot the crow","reward":"breathing room"},
		{"at":.58,"members":[["mirror",0.],["seed",220.]],"cue":"two firing lines before the glider","decision":"spend special ammo or keep it","counter":"crouch under the high lane","reward":"ammo saved"},
		{"at":.80,"members":[["mirror",0.],["kite",160.],["vine",380.]],"gate":true,"cue":"every garden role at once","decision":"priority under pressure","counter":"kite, mirror, then pass the vine","reward":"guardian approach"}
	],
	"roots":[
		{"at":.06,"members":[["burrow",0.]],"cue":"soil trembles before a burrow surfaces","decision":"wait or run past","counter":"wait for it to surface, shoot","reward":"safe first kill"},
		{"at":.12,"members":[["mimic",0.]],"cue":"mimic leaps and lunges fast","decision":"keep distance","counter":"back off, shoot during its landing","reward":"read the leap"},
		{"at":.18,"members":[["burrow",0.],["mimic",240.]],"gate":true,"cue":"a burrow holds the floor while a mimic leaps in","decision":"which threat first","counter":"back off the mimic, shoot the burrow as it surfaces","reward":"gate opens"},
		{"at":.27,"members":[["conductor",0.]],"cue":"a conductor charges and fires a slow bolt","decision":"notice the support role","counter":"close in between its bolts","reward":"energy cut"},
		{"at":.41,"members":[["burrow",0.],["wisp",200.]],"cue":"the darkness hides the floor","decision":"advance by light","counter":"follow the wisp glow, watch the trembling soil","reward":"dark crossed"},
		{"at":.50,"members":[["conductor",0.],["mimic",220.]],"cue":"the conductor energises a mimic","decision":"kill the support first","counter":"push to the conductor, then turn","reward":"breathing room"},
		{"at":.58,"members":[["mimic",0.],["gnome",150.]],"cue":"fast pair before the borer","decision":"spend special ammo or keep it","counter":"jump the mimic, pistol the gnome","reward":"ammo saved"},
		{"at":.80,"members":[["burrow",0.],["conductor",200.],["mimic",380.]],"gate":true,"cue":"every root role at once","decision":"priority under pressure","counter":"conductor, mimic, then burrow","reward":"guardian approach"}
	]
}

static func populate_authored(w) -> void:
	var cards: Array=AUTHORED[w.section]
	for i in cards.size():
		var card: Dictionary=cards[i]
		var x: float=w.length()*float(card.at)
		var ids: Array[String]=[]
		for k in card.members.size():
			var member: Array=card.members[k]
			var kind: String=str(member[0])
			var at: float=x+float(member[1])
			# A ground role never starts inside a canal pit: step back to its lip.
			if not flying(kind):
				for pit in w.pits:
					if at>pit.x-30. and at<pit.y+30.:at=pit.x-55.
			w.spawn_enemy(kind,at,-120. if flying(kind) else 0.,300+i*10+k)
			ids.append(w.section+":enemy:"+str(300+i*10+k))
		if bool(card.get("gate",false)):w.gates.append({"x":x+float(card.members[-1][1])+380.,"ids":ids})
		w.encounters.append({"id":w.section+":encounter:"+str(i),"x":x,"variant":mini(card.members.size()-1,2),"scene":SCENES[w.section][clampi(int(i*3/cards.size()),0,2)],"enemies":ids,"cue":card.cue,"decision":card.decision,"counter":card.counter,"reward":card.reward})

static func flying(kind: String) -> bool:
	return kind in ["crow","moth","drone","wisp","glider"] or (NEW_ENEMIES.has(kind) and bool(NEW_ENEMIES[kind].flying))

static func populate(w) -> void:
	w.encounters.clear();w.objects.clear();w.zones.clear();w.rooms.clear();w.hazards.clear()
	var regional: Array=REGIONS.get(w.section,[])
	var is_leaf: bool=not regional.is_empty()
	if not is_leaf and w.section!="arena":regional=["gnome","seed","crow"] if w.section!="quay" else ["drone","beetle","gnome"]
	if is_leaf:
		populate_authored(w)
	elif not regional.is_empty():
		var count: int=2 if w.section=="canopy" else 4
		var rhythm_rng:=RandomNumberGenerator.new();rhythm_rng.seed=w.run_seed+abs(w.section.hash())+1703
		for i in count:
			var x: float=lerpf(2200.,w.length()-1700.,float(i)/maxf(1.,count-1))
			var variant: int=rhythm_rng.randi_range(0,2)
			if i>0 and i<count-1:x+=rhythm_rng.randf_range(-180.,180.)
			var spacing: Array=[[0.,105.,285.,410.,570.],[0.,180.,245.,445.,550.],[0.,150.,325.,390.,610.]][variant]
			var ids: Array[String]=[]
			for k in 5:
				var kind: String=regional[(k+variant)%3] if k<3 else (["gnome","beetle","slime"][i%3] if k==3 else ["crow","moth","drone"][i%3])
				w.spawn_enemy(kind,x+float(spacing[k]),-120. if flying(kind) else 0.,300+i*10+k)
				ids.append(w.section+":enemy:"+str(300+i*10+k))
			if i==0 or i==count-1:w.gates.append({"x":x+760.,"ids":ids})
			w.encounters.append({"id":w.section+":encounter:"+str(i),"x":x,"variant":variant,"scene":w.section,"enemies":ids})
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
		w.mount={"available":true,"ridden":false,"x":600.,"hp":3,"type":{"water":"shell","terrace":"wind","roots":"drill"}[w.section],"hurt":0.,"wreck_age":0.}
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
	if w.section=="shore":
		w.pickups.append({"id":"shore:owl_feather","kind":"owl_feather","x":1200.,"y":-35.})
	elif w.section=="quay":
		w.pickups.append({"id":"quay:wolf_charm","kind":"wolf_charm","x":1650.,"y":-35.})
	for i in w.crates.size():w.crates[i].kind=(CampaignWeapons.SPECIAL+["heal","shield","grenade","repair","haste","power","reveal","magnet","owl_feather","wolf_charm"])[i%20]
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
	for x in w.bridge_timers:
		w.bridge_timers[x]=maxf(0.,float(w.bridge_timers[x])-dt)
		if float(w.bridge_timers[x])<=0.:w.disabled_platforms[x]=true
	if w.section=="arena" and int(w.boss.phase)>=2 and fmod(float(w.boss.clock),7.)>3.5:w.disabled_platforms[690.]=true
