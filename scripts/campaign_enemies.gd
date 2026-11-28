class_name CampaignEnemies
extends RefCounted

const CROW_DIVE_SECONDS := .70 / .9
const CROW_DIVE_OFFSET := Vector2(0., -25.)
const CROW_DIVE_RADIUS := 35.

static func aim_crow_dive(w, e: Dictionary) -> void:
	e.dive_aim = w.player + CROW_DIVE_OFFSET
	e.facing = -1 if Vector2(e.dive_aim).x < float(e.x) else 1

static func start_crow_dive(w, e: Dictionary) -> void:
	e.dive = CROW_DIVE_SECONDS
	e.dive_duration = CROW_DIVE_SECONDS
	e.dive_start = Vector2(float(e.x), float(e.y))
	e.dive_target = e.get("dive_aim", w.player + CROW_DIVE_OFFSET)
	e.erase("dive_aim")

static func crow_set_position(e: Dictionary, point: Vector2) -> void:
	var dx := point.x - float(e.x)
	if absf(dx) > .05: e.facing = -1 if dx < 0. else 1
	e.x = point.x
	e.y = point.y

static func flight_height(e: Dictionary) -> float:
	return float(e.home.y) + sin(float(e.age) * 2.2) * 20.

static func step_crow_rebound(e: Dictionary) -> bool:
	var contact: Vector2 = e.get("roof_deflection", Vector2.INF)
	var elapsed := float(e.age) - float(e.get("roof_deflection_age", -10.))
	if not contact.is_finite() or elapsed > CampaignRoutes.ROOF_DEFLECTION_SECONDS: return false
	var progress := clampf(elapsed / CampaignRoutes.ROOF_DEFLECTION_SECONDS, 0., 1.)
	var from := contact - Vector2(0., 14.)
	var direction := -1. if Vector2(e.dive_target).x > Vector2(e.dive_start).x else 1.
	var retreat := Vector2(contact.x + direction * 56., flight_height(e))
	crow_set_position(e, from.lerp(retreat, smoothstep(0., 1., progress)))
	return true

static func step_crow_dive(w, e: Dictionary, dt: float) -> void:
	var duration: float = e.get("dive_duration", CROW_DIVE_SECONDS)
	var inbound := float(e.dive) > duration * .5
	var from: Vector2 = e.get("dive_last", e.dive_start)
	var target: Vector2 = e.dive_target
	e.dive = maxf(0., float(e.dive) - dt)
	var phase := 1. - float(e.dive) / duration
	var direction := -1. if target.x > Vector2(e.dive_start).x else 1.
	var retreat := Vector2(target.x + direction * 65., flight_height(e))
	var hit_end := Vector2(e.dive_start).lerp(target, minf(1., phase * 2.))
	var point := hit_end if phase < .5 else target.lerp(retreat, (phase - .5) * 2.)
	if inbound and CampaignRoutes.stop_crow_dive_at_roof(w, e, hit_end):
		var contact: Vector2 = e.roof_deflection
		hit_end = contact - Vector2(0., 14.)
		point = hit_end
		e.dive = 0.
		e.wait = maxf(float(e.wait), 1.35)
	crow_set_position(e, point)
	if e.dive > 0.: e.dive_last = point
	else: e.erase("dive_last")
	if inbound and w.state == "playing" and not CampaignRoutes.crow_sheltered(w, w.player):
		var centre: Vector2 = w.player + CROW_DIVE_OFFSET
		var closest := Geometry2D.get_closest_point_to_segment(centre, from, hit_end)
		if closest.distance_squared_to(centre) < CROW_DIVE_RADIUS * CROW_DIVE_RADIUS:
			w.enemy_body_hit(e)

## New roles retain one normal HP. Armoured machines and guardians are separate.
## 0.32.0: Explicit 4-stage readability cycle (telegraph -> active -> recovery -> reposition).
## Timings are rule constants; Sol 6.2 art must match these windows rather than alter them.
const ROLE_TIMING := {
	"leech":{"windup":0.75,"recover":0.55},
	"hopper":{"windup":0.70,"recover":0.50},
	"siphon":{"windup":0.90,"recover":0.60},
	"kite":{"windup":0.80,"recover":0.55},
	"mirror":{"windup":0.95,"recover":0.70},
	"vine":{"windup":0.95,"recover":0.65},
	"burrow":{"windup":0.65,"recover":0.55},
	"conductor":{"windup":0.95,"recover":0.65},
	"mimic":{"windup":0.80,"recover":0.60},
	"sweeper":{"windup":1.00,"recover":0.75},
	"glider":{"windup":0.95,"recover":0.70},
	"borer":{"windup":1.00,"recover":0.80},
	"patrol":{"windup":0.95,"recover":0.70}
}

static func timing_for(e: Dictionary) -> Dictionary:
	if CampaignWardens.applies(e):return CampaignWardens.TIMING[CampaignWardens.role(e)]
	if bool(e.get("mini",false)):return {"windup":0.90,"recover":0.55}
	return ROLE_TIMING.get(str(e.get("kind","")),{"windup":0.85,"recover":0.55})

static func hidden(e: Dictionary) -> bool:
	# Once surfaced for an attack, the burrow commits through the complete
	# readable attack and punish interval. Its age/ambush clock keeps running.
	return e.kind=="burrow" and fmod(float(e.age),4.)<1.4 and float(e.get("windup",0.))<=0. and active_time(e)<=0. and float(e.get("recover",0.))<=0.

static func shot(w,e: Dictionary,offset: float=0.,height: float=-35.,speed: float=220.) -> void:
	var origin:=Vector2(float(e.x),float(e.y)+height)
	var direction: Vector2=(w.player+Vector2(0,-36)-origin).normalized().rotated(offset)
	w.bullets.append({"p":origin,"v":direction*speed,"owner":"enemy","age":0.,"kind":"seed","damage":1,"pierce":0,"hit":[]})

static func vine_sweep(e: Dictionary) -> Rect2:
	return Rect2(float(e.x)-210.,float(e.y)-85.,420.,140.)

static func attack(w,e: Dictionary) -> void:
	if CampaignWardens.applies(e):
		CampaignWardens.release(w,e)
		return
	var timing: Dictionary=timing_for(e)
	e.flash=.45;e.attacks=int(e.attacks)+1;e.recover=float(timing.recover)
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
		"hopper":e.leap=.8;e.leap_duration=.8
		"siphon":
			for o in w.objects:
				if o.kind=="lamp" and absf(float(o.x)-float(e.x))<300.:o.active=false;w.activated.erase(str(o.id))
			shot(w,e,0.,-15.,170.)
		"kite":
			shot(w,e,-.20,-12.,245.);shot(w,e,.20,-12.,245.)
		"mirror":shot(w,e,0.,-25.,185.)
		"vine":
			e.sweep=.45
			if vine_sweep(e).has_point(CampaignRoutes.foot(w)):w.damage_player()
		"burrow":e.lunge=.55
		"conductor":
			e.buff_pulse=.5
			for other in w.enemies:
				if other!=e and not bool(other.defeated) and absf(float(other.x)-float(e.x))<300.:other.energised=2.
			shot(w,e)
		"mimic":e.leap=.6;e.leap_duration=.6;e.lunge=.6
		"sweeper":
			for angle in [-.18,0.,.18]:shot(w,e,angle,-40.,210.)
		"glider":shot(w,e,-.25);shot(w,e,.25)
		"borer":e.lunge=.9
		"patrol":
			shot(w,e,0.,-95. if int(e.attacks)%2==0 else -20.,260.)

static func active_time(e: Dictionary) -> float:
	if e.has("warden"):return CampaignWardens.active_time(e)
	return maxf(float(e.get("lunge",0.)),maxf(float(e.get("leap",0.)),float(e.get("sweep",0.))))

static func step(w,e: Dictionary,dt: float) -> bool:
	if CampaignWardens.applies(e):
		CampaignWardens.step(w,e,dt)
		return true
	var kind: String=e.kind
	if not CampaignContent.NEW_ENEMIES.has(kind) and kind not in CampaignContent.HEAVIES and not bool(e.mini):return false
	var spec: Dictionary=CampaignContent.NEW_ENEMIES.get(kind,{"speed":45.,"range":500.})
	var timing: Dictionary=timing_for(e)
	var dx: float=w.player.x-float(e.x)
	var flying: bool=CampaignContent.flying(kind)
	var is_hidden: bool=hidden(e)
	if kind=="burrow":
		var cycle: float=fmod(float(e.age),4.)
		e.emerge_warn=is_hidden and cycle>=0.95 and cycle<1.4
	# Recovery is reserved by attack(), but its clock starts only once the
	# longest active action ends. Spend a boundary-crossing tick once only.
	var active_before: float=active_time(e)
	var lunge_before: float=float(e.get("lunge",0.))
	var recovery_before: float=float(e.get("recover",0.))
	for key in ["lunge","leap","sweep","energised","buff_pulse"]:
		e[key]=maxf(0.,float(e.get(key,0.))-dt)
	e.recover=maxf(0.,recovery_before-maxf(0.,dt-active_before))
	var recovering: bool=recovery_before>0. and active_time(e)<=0.
	var active_dt: float=minf(dt,active_before)
	if flying:
		e.y=float(e.home.y)+sin(float(e.age)*(3. if kind=="kite" else 1.5))*28.
	if absf(dx)>180. and kind not in ["mirror","vine","conductor"] and not is_hidden and not recovering:
		var candidate: float=float(e.x)+signf(dx)*float(spec.speed)*dt
		if flying or CampaignGround.has_floor(w.floor_at(candidate)):e.x=candidate
	if lunge_before>0.:
		var next: float=float(e.x)+signf(dx)*(230. if kind!="borer" else 270.)*minf(active_dt,lunge_before)
		if CampaignGround.has_floor(w.floor_at(next)):e.x=next
	var support: float=w.floor_at(float(e.x))
	if not flying and CampaignGround.PROFILES.has(w.section) and CampaignGround.has_floor(support):e.y=support
	if kind=="hopper" and not recovering:e.y=support-absf(sin(float(e.age)*3.))*85.
	if float(e.leap)>0.:
		var leap_duration: float=float(e.get("leap_duration",.6 if kind=="mimic" else .8))
		var leap_phase: float=clampf(1.-float(e.leap)/leap_duration,0.,1.)
		e.y=(support if CampaignGround.has_floor(support) else float(e.home.y))-sin(leap_phase*PI)*100.
	if recovering and not flying:e.y=support if CampaignGround.has_floor(support) else float(e.home.y)
	if is_hidden:e.y=support if CampaignGround.has_floor(support) else float(e.home.y)
	# Prevent instant spawn-frame contact hits and reward attacking during recovery.
	var active_contact: bool=float(e.age)>0.45 and (not recovering or float(e.get("lunge",0.))>0. or float(e.get("leap",0.))>0.)
	if w.state=="playing" and active_contact and absf(w.player.x-float(e.x))<38. and absf(w.player.y-float(e.y))<55. and not is_hidden:
		w.enemy_body_hit(e)
		if kind=="leech":w.buffs.slow=2.
	# The attack and punish interval own their full ticks, including the
	# final recovery tick. Reposition/windup cannot run concurrently.
	if active_before>0. or recovery_before>0.:return true
	if float(e.windup)>0.:
		e.windup=maxf(0.,float(e.windup)-dt)
		if float(e.windup)==0.:attack(w,e);e.wait=2.1 if not bool(e.mini) else 1.8
	elif not recovering:
		e.wait=float(e.wait)-dt*(1.4 if float(e.energised)>0. else 1.)
		# Keep telegraph starts within readable onscreen distance.
		if float(e.wait)<=0. and absf(dx)<minf(float(spec.range),520.) and not is_hidden:
			e.windup=float(timing.windup)
	return true
