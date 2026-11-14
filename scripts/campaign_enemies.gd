class_name CampaignEnemies
extends RefCounted

## New roles retain one normal HP. Armoured machines and guardians are separate.
static func hidden(e: Dictionary) -> bool:
	return e.kind=="burrow" and fmod(float(e.age),4.)<1.4

static func shot(w,e: Dictionary,offset: float=0.,height: float=-35.,speed: float=220.) -> void:
	var origin:=Vector2(float(e.x),float(e.y)+height)
	var direction: Vector2=(w.player+Vector2(0,-36)-origin).normalized().rotated(offset)
	w.bullets.append({"p":origin,"v":direction*speed,"owner":"enemy","age":0.,"kind":"seed","damage":1,"pierce":0,"hit":[]})

static func attack(w,e: Dictionary) -> void:
	e.flash=.45;e.attacks=int(e.attacks)+1
	w.pending_events.append("guardian" if bool(e.mini) else "enemy_shot")
	var kind: String=e.kind
	if bool(e.mini):
		var role: String=e.get("mini_role","current_guard")
		if role=="current_guard":
			if int(e.attacks)%2==0:
				for angle in [-.25,0.,.25]:shot(w,e,angle)
			else:w.bullets.append({"p":Vector2(float(e.x),-18.),"v":Vector2(-260.,0.),"owner":"enemy","age":0.,"kind":"wave","damage":1,"pierce":0,"hit":[]})
		elif role=="terrace_guard":
			for surface in w.platforms:
				if absf(surface.position.x-float(e.x))<450.:w.platform_timers[surface.position.x]=1.5;break
			if int(e.attacks)%2==0:
				for angle in [-.35,0.,.35]:shot(w,e,angle,-90.)
			else:
				w.hazards.append({"id":str(e.id)+":vine:"+str(e.attacks),"kind":"vines","x":w.player.x,"clock":2.7,"phase":2.7,"warn":true,"once":true})
		else:
			var high: bool=int(e.attacks)%2==0
			w.bullets.append({"p":Vector2(float(e.x),-115. if high else -16.),"v":Vector2(-280.,0.),"owner":"enemy","age":0.,"kind":"wave","damage":1,"pierce":0,"hit":[]})
		return
	match kind:
		"leech":e.lunge=.65
		"hopper":e.leap=.8
		"siphon":
			for o in w.objects:
				if o.kind=="lamp" and absf(float(o.x)-float(e.x))<300.:o.active=false;w.activated.erase(str(o.id))
			shot(w,e,0.,-15.,170.)
		"kite":
			shot(w,e,-.20,-12.,245.);shot(w,e,.20,-12.,245.)
		"mirror":shot(w,e,0.,-25.,185.)
		"vine":
			e.sweep=.45
			if absf(w.player.x-float(e.x))<210. and w.player.y> -85.:w.damage_player()
		"burrow":e.lunge=.55
		"conductor":
			for other in w.enemies:
				if other!=e and absf(float(other.x)-float(e.x))<300.:other.energised=2.
			shot(w,e)
		"mimic":e.leap=.6;e.lunge=.6
		"sweeper":
			for angle in [-.18,0.,.18]:shot(w,e,angle,-40.,210.)
		"glider":shot(w,e,-.25);shot(w,e,.25)
		"borer":e.lunge=.9
		"patrol":
			shot(w,e,0.,-95. if int(e.attacks)%2==0 else -20.,260.)

static func step(w,e: Dictionary,dt: float) -> bool:
	var kind: String=e.kind
	if not CampaignContent.NEW_ENEMIES.has(kind) and kind not in CampaignContent.HEAVIES and not bool(e.mini):return false
	var spec: Dictionary=CampaignContent.NEW_ENEMIES.get(kind,{"speed":45.,"range":500.})
	var dx: float=w.player.x-float(e.x)
	var flying: bool=CampaignContent.flying(kind)
	if flying:
		e.y=float(e.home.y)+sin(float(e.age)*(3. if kind=="kite" else 1.5))*28.
	if absf(dx)>180. and kind not in ["mirror","vine","conductor"] and not hidden(e):
		var candidate: float=float(e.x)+signf(dx)*float(spec.speed)*dt
		if flying or w.floor_at(candidate)==0.:e.x=candidate
	if kind=="hopper":e.y=-absf(sin(float(e.age)*3.))*85.
	for key in ["lunge","leap","sweep","energised"]:e[key]=maxf(0.,float(e.get(key,0.))-dt)
	if float(e.leap)>0.:e.y=-sin(float(e.leap)/.8*PI)*100.
	if float(e.lunge)>0.:
		var next: float=float(e.x)+signf(dx)*(230. if kind!="borer" else 270.)*dt
		if w.floor_at(next)==0.:e.x=next
	if hidden(e):e.y=0.
	if absf(dx)<38. and absf(w.player.y-float(e.y))<55. and not hidden(e):
		w.damage_player()
		if kind=="leech":w.buffs.slow=2.
	if float(e.windup)>0.:
		e.windup=maxf(0.,float(e.windup)-dt)
		if float(e.windup)==0.:attack(w,e);e.wait=2.1 if not bool(e.mini) else 1.8
	else:
		e.wait=float(e.wait)-dt*(1.4 if float(e.energised)>0. else 1.)
		if float(e.wait)<=0. and absf(dx)<float(spec.range) and not hidden(e):e.windup=.9
	return true
