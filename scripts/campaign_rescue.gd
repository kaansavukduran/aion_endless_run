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
## Explicit NPC animation/state contract for runtime & Sol 6.2 art handoff.
const NPC_ANIM_SPEC := {
	"idle_bound":{"phase":"bound","frames":[0,1],"loop":true,"foot":[0,0],"body":[0,-40],"event":"cut_or_shot"},
	"rescue_react":{"phase":"free","frames":[6,7],"loop":false,"until":0.35,"foot":[0,0],"body":[0,-40],"event":"rescue"},
	"free_roam":{"phase":"free","frames":[6,7],"loop":true,"foot":[0,0],"body":[0,-40],"event":"npc_contact"},
	"salute_thanks":{"phase":"thanks","frames":[2],"loop":false,"until":0.45,"foot":[0,0],"body":[0,-40],"satchel":[22,-52],"event":"npc_contact"},
	"drop_gift":{"phase":"thanks","frames":[3],"loop":false,"from":0.45,"until":1.7,"foot":[0,0],"body":[0,-40],"satchel":[22,-52],"event":"gift_drop"},
	"depart_run":{"phase":"departed","frames":[6,7],"loop":true,"until":4.8,"foot":[0,0],"body":[0,-40],"event":"courier_cover"}
}

static func clip_name(n: Dictionary) -> String:
	var phase: String=str(n.get("phase","free" if bool(n.get("freed",false)) else "bound"))
	if phase=="bound":return "idle_bound"
	if phase=="free":return "rescue_react" if float(n.get("free_age",0.))<.35 else "free_roam"
	if phase=="thanks":return "salute_thanks" if float(n.get("thank_age",0.))<.45 else "drop_gift"
	return "depart_run"

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
		var claimed: bool=w.awarded.has(id+":gift") or w.taken.has(id+":supply")
		var dropped: bool=w.gift_drops.has(id)
		var roles: Array=REGIONAL_ROLES.get(w.section,ROLES)
		var role: String=str(roles[posmod(i,roles.size())])
		if secret!="":role={"water":"observer","terrace":"gardener","roots":"archivist"}[w.section]
		var npc_entry: Dictionary={"id":id,"x":x,"home_x":x,"y":y,"freed":freed,"variant":posmod(index,8),"role":role,"gift":GIFTS[posmod(index,GIFTS.size())] if i>0 else "heavy","free_age":99. if freed and (claimed or dropped) else 0.,"phase":("departed" if claimed or dropped else ("thanks" if w.greeted.has(id) else "free")) if freed else "bound","thank_age":99. if claimed or dropped else 0.,"facing":-1,"roam_clock":0.,"secret":secret}
		npc_entry.clip=clip_name(npc_entry)
		w.npcs.append(npc_entry)
	for n in w.npcs:
		var id: String=str(n.id)
		if w.gift_drops.has(id) and not w.taken.has(id+":supply"):
			var item: Dictionary=Dictionary(w.gift_drops[id]).duplicate(true)
			item.age=0. # A resumed gift remains visible before contact can claim it.
			w.pickups.append(item)
	# A cage protects an actual captive, rather than being an unrelated prop.
	for o in w.objects:
		if o.kind!="cage" or w.npcs.is_empty():continue
		var candidates: Array=w.npcs.filter(func(n):return str(n.secret)=="")
		candidates.sort_custom(func(a,b):return absf(float(a.x)-float(o.x))<absf(float(b.x)-float(o.x)))
		if not candidates.is_empty():
			var n: Dictionary=candidates[0];o.x=n.x;o.y=n.y;n.cage=str(o.id)
			if bool(n.freed):o.active=true

static func nearest(w) -> Dictionary:
	if w.state!="playing" or not w.grounded() or w.crouching() or bool(w.mount.ridden):return {}
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

## A shot may free the rope even when the player is too far away to use a
## knife. The contact test uses the whole travelled segment, including beams.
static func hit_rope(w,from: Vector2,to: Vector2) -> bool:
	for n in w.npcs:
		if bool(n.freed) or (str(n.secret)!="" and not w.discovered.has(str(n.secret))):continue
		if w.objects.any(func(o):return str(o.id)==str(n.get("cage","")) and not bool(o.active)):continue
		var rope:=Rect2(float(n.x)-25.,float(n.y)-120.,50.,100.)
		if crosses_rect(from,to,rope):
			w.rescue(n)
			return true
	return false

## Area attacks use the same secrecy/cage protection as travelling bullets.
static func blast_ropes(w,centre: Vector2,radius: float) -> void:
	for n in w.npcs:
		if bool(n.freed) or (str(n.secret)!="" and not w.discovered.has(str(n.secret))):continue
		if w.objects.any(func(o):return str(o.id)==str(n.get("cage","")) and not bool(o.active)):continue
		var nearest:=Vector2(clampf(centre.x,float(n.x)-25.,float(n.x)+25.),clampf(centre.y,float(n.y)-120.,float(n.y)-20.))
		if centre.distance_to(nearest)<=radius:w.rescue(n)

static func crosses_rect(from: Vector2,to: Vector2,rect: Rect2) -> bool:
	if maxf(from.x,to.x)<rect.position.x or minf(from.x,to.x)>rect.end.x or maxf(from.y,to.y)<rect.position.y or minf(from.y,to.y)>rect.end.y:return false
	if rect.has_point(from) or rect.has_point(to):return true
	var corners: Array[Vector2]=[rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]
	for i in 4:
		if Geometry2D.segment_intersects_segment(from,to,corners[i],corners[(i+1)%4])!=null:return true
	return false

static func has_support(w,n: Dictionary,x: float) -> bool:
	if absf(float(n.y))<.1:return w.floor_at(x)==0.
	for platform in w.platforms:
		if w.disabled_platforms.has(platform.position.x):continue
		if absf(platform.position.y-float(n.y))<.1 and x>=platform.position.x+4. and x<=platform.end.x-4.:return true
	return false

static func handover(w,n: Dictionary) -> void:
	var id: String=str(n.id)
	if w.awarded.has(id+":gift") or w.taken.has(id+":supply") or w.gift_drops.has(id):return
	# A visible bag extraction produces a real item. Thanks/contact alone is
	# not a weapon/ammunition grant; only touching this pickup claims it.
	var direction: int=int(n.get("facing",-1))
	var x: float=float(n.x)+direction*100.
	if not has_support(w,n,x):x=float(n.x)+direction*75.
	if not has_support(w,n,x):x=float(n.x)
	var item: Dictionary={"id":id+":supply","kind":str(n.gift),"x":x,"y":float(n.y)-25.,"rescue_id":id,"role":str(n.role),"age":0.,"from_bag":true}
	w.gift_drops[id]=item.duplicate(true);w.pickups.append(item)
	w.pending_events.append("gift_drop")

static func on_gift_collected(w,item: Dictionary) -> void:
	var id: String=str(item.rescue_id)
	if w.awarded.has(id+":gift"):return
	w.award(id+":gift",0);w.gift_drops.erase(id)
	w.grenades=mini(9,w.grenades+1);w.hp=mini(w.max_hp,w.hp+1)
	if w.character=="sheep":w.flock=mini(3,w.flock+1)
	w.notice="arc_maintenance" if item.get("role","")=="archivist" else "arc_thanks";w.notice_time=2.;w.pending_events.append("rescue_gift")
	if item.get("role","")=="technician":
		w.mount.hp=mini(CampaignVehicles.MAX_HP,int(w.mount.hp)+1)
		for o in w.objects:
			if o.kind=="gate" and absf(float(o.x)-float(item.x))<400.:o.active=true;w.activated[str(o.id)]=true

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
		var phase: String=str(n.get("phase","free"))
		if phase=="free":
			n.roam_clock=float(n.get("roam_clock",0.))+dt
			var facing: int=int(n.get("facing",-1))
			var next: float=float(n.x)+float(facing)*45.*dt
			var limit: bool=absf(next-float(n.get("home_x",n.x)))>90. or next<35. or next>w.length()-90.
			if limit or not has_support(w,n,next) or float(n.roam_clock)>1.5+float(int(n.variant)%3)*.25:
				n.facing=-facing;n.roam_clock=0.
			else:n.x=next
			if float(n.free_age)>.2 and w.touches_npc(n):
				n.phase="thanks";n.thank_age=0.;n.facing=1 if w.player.x>float(n.x) else -1
				w.greeted[str(n.id)]=true;w.pending_events.append("npc_contact")
		elif phase in ["thanks","departed"]:
			n.thank_age=float(n.get("thank_age",0.))+dt
			if phase=="thanks" and float(n.thank_age)>=.9:handover(w,n)
			if phase=="thanks" and float(n.thank_age)>1.7:n.phase="departed"
			if str(n.phase)=="departed" and float(n.thank_age)<4.8:
				var next: float=float(n.x)-60.*dt
				if has_support(w,n,next):n.x=next;n.facing=-1
			if n.role=="courier" and w.awarded.has(str(n.id)+":gift") and float(n.thank_age)>1.3 and float(n.thank_age)<4.2:
				if int(float(n.thank_age)*2.)!=int((float(n.thank_age)-dt)*2.):
					var origin:=Vector2(float(n.x),float(n.y)-40.)
					var aim:=Vector2(w.facing,0.)
					var best_d:=520.
					for e in w.enemies:
						if bool(e.defeated) or CampaignEnemies.hidden(e):continue
						var ep:=Vector2(float(e.x),float(e.y)-30.)
						var d: float=origin.distance_to(ep)
						if d<best_d:best_d=d;aim=(ep-origin).normalized()
					w.bullets.append({"p":origin,"v":aim*600.,"owner":"hero","age":0.,"kind":"helper","damage":1,"pierce":0,"hit":[]})
		n.clip=clip_name(n)
