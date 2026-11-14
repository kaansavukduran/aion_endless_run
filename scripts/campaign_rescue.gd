class_name CampaignRescue
extends RefCounted

## The gun action becomes a short, non-combat knife interaction near a captive.
## Authored coordinates and stable reward IDs survive retry and save/resume.
const COUNTS := {"shore":3,"quay":2,"canopy":0,"water":9,"terrace":10,"roots":11,"relay":4,"arena":4}
const ROLES := ["keeper","technician","courier","gardener","observer","archivist"]
const REGIONAL_ROLES := {"shore":["keeper","technician","courier"],"quay":["technician","keeper"],"water":["observer","keeper","technician","courier"],"terrace":["gardener","keeper","courier","technician"],"roots":["archivist","technician","keeper","courier"],"relay":["technician","archivist","keeper","courier"],"arena":["keeper","technician","courier","archivist"]}
const GIFTS := ["heavy","repair","beam","shield","scatter","points","arc","grenade","seeker","haste","power","reveal","magnet","disc","harpoon","spore","trap","nova"]
const CUT_SECONDS := .6
const CONTACT := .3

static func populate(w) -> void:
	for i in int(COUNTS[w.section]):
		var id: String = w.section+":keeper"+("" if i==0 else ":"+str(i))
		var count: int=COUNTS[w.section]
		var x: float=lerpf(550.,w.length()-900.,float(i)/maxf(1.,count-1))
		if i==0:x=w.length()*.55 # Keep the original keeper's location and ID.
		var y:=0.
		var secret: String=""
		if w.section in ["water","terrace","roots"] and i in [count-2,count-1]:
			secret=w.section+":secret:"+str(i-(count-2));x=w.length()*(.30 if i==count-2 else .68);y=-140.
			w.platforms.append(Rect2(x-100.,y,200.,18.));w.platforms.append(Rect2(x-220.,-70.,140.,18.))
		for pit in w.pits:
			if x>pit.x-45. and x<pit.y+45.:x=pit.x-65.
		var index: int=abs(w.section.hash())+i
		var freed: bool=w.rescued.has(id)
		var roles: Array=REGIONAL_ROLES.get(w.section,ROLES)
		var role: String=str(roles[posmod(i,roles.size())])
		if secret!="":role={"water":"observer","terrace":"gardener","roots":"archivist"}[w.section]
		w.npcs.append({"id":id,"x":x,"home_x":x,"y":y,"freed":freed,"variant":posmod(index,8),"role":role,"gift":GIFTS[posmod(index,GIFTS.size())] if i>0 else "heavy","free_age":99. if freed and w.awarded.has(id+":gift") else 0.,"secret":secret})
	# A cage protects an actual captive, rather than being an unrelated prop.
	for o in w.objects:
		if o.kind!="cage" or w.npcs.is_empty():continue
		var candidates: Array=w.npcs.filter(func(n):return str(n.secret)=="")
		candidates.sort_custom(func(a,b):return absf(float(a.x)-float(o.x))<absf(float(b.x)-float(o.x)))
		if not candidates.is_empty():
			var n: Dictionary=candidates[0];o.x=n.x;o.y=n.y;n.cage=str(o.id)
			if bool(n.freed):o.active=true

static func nearest(w) -> Dictionary:
	if w.state!="playing" or not w.grounded() or bool(w.mount.ridden):return {}
	for n in w.npcs:
		if bool(n.freed) or (str(n.secret)!="" and not w.discovered.has(str(n.secret))):continue
		if w.objects.any(func(o):return str(o.id)==str(n.get("cage","")) and not bool(o.active)):continue
		var dx: float=(float(n.x)-w.player.x)*w.facing
		if dx>=-10. and dx<100. and absf(float(n.y)-w.player.y)<25.:return n
	return {}

static func begin(w) -> bool:
	if w.rescue_time>0. or w.rescue_latched:return false
	var n:=nearest(w)
	if n.is_empty():return false
	w.rescue_target=str(n.id);w.rescue_time=CUT_SECONDS;w.rescue_contact=false;w.rescue_latched=true
	w.fire_held=false;w.shot_flash=0.;w.melee_time=0.;w.velocity.x=0.;w.fire_time=CUT_SECONDS
	w.charging=false;w.charge_time=0.;w.jump_held=false
	w.pending_events.append("cut")
	return true

static func step(w,dt: float) -> void:
	if w.rescue_time>0.:
		w.rescue_time=maxf(0.,w.rescue_time-dt)
		if not w.rescue_contact and w.rescue_time<=CUT_SECONDS-CONTACT:
			w.rescue_contact=true
			for n in w.npcs:
				if str(n.id)==w.rescue_target and absf(w.player.x-float(n.x))<110. and absf(w.player.y-float(n.y))<25.:w.rescue(n)
	for n in w.npcs:
		if not bool(n.freed):continue
		n.free_age=float(n.free_age)+dt
		if float(n.free_age)>=.9 and not w.awarded.has(str(n.id)+":gift"):
			# Persist the claim together with the effect, never a replayable toast.
			w.award(str(n.id)+":gift",500 if n.gift=="points" else 0)
			if n.gift!="points":w.collect({"id":str(n.id)+":supply","kind":str(n.gift),"x":n.x,"y":n.y})
			w.notice="arc_maintenance" if n.role=="archivist" else "arc_thanks";w.notice_time=2.;w.pending_events.append("rescue_gift")
			if n.role=="technician":
				w.mount.hp=mini(4,int(w.mount.hp)+1)
				for o in w.objects:
					if o.kind=="gate" and absf(float(o.x)-float(n.x))<400.:o.active=true;w.activated[str(o.id)]=true
		if n.role=="courier" and float(n.free_age)>1.3 and float(n.free_age)<4.2:
			if w.floor_at(float(n.x))==0.:n.x=move_toward(float(n.x),w.player.x-70.,90.*dt)
			if int(float(n.free_age)*2.)!=int((float(n.free_age)-dt)*2.):
				w.bullets.append({"p":Vector2(float(n.x),float(n.y)-40.),"v":Vector2(w.facing*600.,0.),"owner":"hero","age":0.,"kind":"helper","damage":1,"pierce":0,"hit":[]})
		if float(n.free_age)>2.4:
			var next: float=float(n.x)-60.*dt
			if float(n.y)<-.1:
				n.x=maxf(float(n.home_x)-75.,next)
			elif w.floor_at(next)==0.:n.x=next
