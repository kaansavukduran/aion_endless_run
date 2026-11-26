class_name CampaignWardens
extends RefCounted

## The three exit Wardens keep their saved IDs. The same world-space geometry
## drives warning marks, the strike, and the player's damage check.
const ROLES := ["water", "terrace", "roots"]
const TIMING := {
	"water": {"windup": .80, "active": 1.16, "recover": 1.12},
	"terrace": {"windup": .86, "active": .20, "recover": 1.12},
	"roots": {"windup": .94, "active": .30, "recover": 1.22},
}
const DECK_HEIGHT := 84.
const TERRACE_HOP := .44
const TERRACE_DROP := .36
const WAKE_LENGTH := 495.
const TERRACE_LENGTH := 540.
const ROOTS_WIDTH := 168.
const FAR_GUARD_DISTANCE := 580.
const COLOURS := {
	"water": Color("71d9dd"), "terrace": Color("fbb3d4"), "roots": Color("f3b466"),
}
const WAVE_EDGE := [
	Vector2(-25, 14), Vector2(-25, 10), Vector2(-20, 10), Vector2(-20, 7), Vector2(-12, 7),
	Vector2(-12, 2), Vector2(-7, 2), Vector2(-7, -3), Vector2(-2, -3), Vector2(-2, -8),
	Vector2(4, -8), Vector2(4, -13), Vector2(17, -13), Vector2(17, -15), Vector2(25, -15),
	Vector2(25, -9), Vector2(19, -9), Vector2(19, -5), Vector2(14, -5), Vector2(14, 1),
	Vector2(20, 1), Vector2(20, 5), Vector2(25, 5), Vector2(25, 14),
]

static func role(e: Dictionary) -> String:
	return str(e.get("id", "")).get_slice(":", 0)

static func applies(e: Dictionary) -> bool:
	if e.get("kind") != "warden" or not bool(e.get("mini", false)): return false
	var location := role(e)
	return location in ROLES and e.id == location + ":enemy:99"

static func exposed(e: Dictionary) -> bool:
	return bool(e.get("warden", {}).get("phase") == "recover") and float(e.get("recover", 0.)) > 0.

static func active_time(e: Dictionary) -> float:
	var state: Dictionary = e.get("warden", {})
	return float(state.get("remaining", 0.)) if state.get("phase") == "active" else 0.

static func terrace_deck(w, e: Dictionary) -> Rect2:
	var x: float = Vector2(e.home).x
	return Rect2(x - 94., w.floor_at(x) - DECK_HEIGHT, 188., 18.)

static func install(w) -> void:
	if w.section != "terrace": return
	for e in w.enemies:
		if applies(e):
			var deck := terrace_deck(w, e)
			if deck not in w.platforms: w.platforms.append(deck)
			return

static func prepare(w, e: Dictionary) -> void:
	if e.has("warden"): return
	e.warden = {"phase": "wait", "remaining": 0., "side": e.facing}
	e.windup = 0.
	e.recover = 0.
	e.flash = 0.
	# Early saves may be paused mid-pattern, but their health and gate remain.
	var support: float = w.floor_at(float(e.x))
	if CampaignGround.has_floor(support): e.y = support

static func start_motion(w, e: Dictionary, location: String) -> void:
	var state: Dictionary = e.warden
	var home: Vector2 = e.home
	if location == "water":
		# At close range, switch to the other side of the player's lane.
		# At longer range, advance toward them and then fall back between tides.
		var offset := -112. if float(e.x) >= home.x else 112.
		var target := move_toward(float(e.x), home.x + offset, 224.)
		var next_side := -1 if target < float(e.x) else 1
		var path_clear := true
		for i in range(1, 9):
			var probe := lerpf(float(e.x), target, float(i) / 8.)
			if not CampaignGround.has_floor(w.floor_at(probe)):
				path_clear = false
				break
		state.phase = "shift"
		state.start_x = float(e.x)
		state.target_x = target if path_clear else float(e.x)
		state.side = next_side
		state.remaining = .43 if absf(target - float(e.x)) <= 135. else .61
		state.duration = state.remaining
	elif location == "terrace":
		install(w)
		var deck := terrace_deck(w, e)
		if w.disabled_platforms.has(deck.position.x):
			lock_attack(w, e)
			return
		state.phase = "hop"
		state.start = Vector2(float(e.x), float(e.y))
		state.end = Vector2(Vector2(e.home).x, deck.position.y)
		state.remaining = TERRACE_HOP
	else:
		lock_attack(w, e)

static func lock_attack(w, e: Dictionary) -> void:
	var location := role(e)
	var state: Dictionary = e.warden
	state.phase = "windup"
	state.side = -1 if w.player.x < float(e.x) else 1
	e.facing = state.side
	state.remaining = TIMING[location].windup
	e.windup = state.remaining
	if location == "water":
		state.start_x = float(e.x) + 40. * float(state.side)
		state.target_x = clampf(float(state.start_x) + WAKE_LENGTH * float(state.side), 38., w.length() - 36.)
	elif location == "terrace":
		var origin := Vector2(float(e.x) + 9. * float(state.side), float(e.y) - 65.)
		var end := clampf(origin.x + TERRACE_LENGTH * float(state.side), 38., w.length() - 36.)
		state.lane = Rect2(minf(origin.x, end), origin.y - 14., absf(end - origin.x), 28.)
	else:
		var middle: float = clampf(w.player.x, float(e.x) - 420., float(e.x) + 420.)
		var support: float = w.floor_at(middle)
		state.lane = Rect2(middle - ROOTS_WIDTH * .5, support - 44., ROOTS_WIDTH, 44.) if CampaignGround.has_floor(support) else Rect2()

static func release(w, e: Dictionary) -> void:
	prepare(w, e)
	if e.warden.phase != "windup": lock_attack(w, e)
	e.warden.phase = "active"
	e.warden.remaining = TIMING[role(e)].active
	e.windup = 0.
	e.flash = .24
	e.attacks = int(e.attacks) + 1
	w.pending_events.append("guardian")

static func start_recovery(e: Dictionary) -> void:
	e.warden.phase = "recover"
	e.recover = TIMING[role(e)].recover
	e.warden.remaining = e.recover
	e.flash = 0.

static func strike_rect(w, e: Dictionary, remaining: float = -1.) -> Rect2:
	var state: Dictionary = e.get("warden", {})
	if role(e) != "water": return state.get("lane", Rect2())
	if state.get("phase") != "active": return Rect2()
	var left: float = float(state.remaining) if remaining < 0. else remaining
	var progress := clampf(1. - left / float(TIMING.water.active), 0., 1.)
	var x := lerpf(float(state.start_x), float(state.target_x), progress)
	var floor: float = w.floor_at(x)
	if not CampaignGround.has_floor(floor): return Rect2()
	return Rect2(x - 25., floor - 31., 50., 30.)

static func threatens(w, area: Rect2) -> bool:
	if not area.has_area(): return false
	var centre: Vector2 = w.player_hit_center()
	var nearest := Vector2(clampf(centre.x, area.position.x, area.end.x), clampf(centre.y, area.position.y, area.end.y))
	return centre.distance_squared_to(nearest) < float(w.player_hit_radius()) ** 2

static func step(w, e: Dictionary, dt: float) -> void:
	prepare(w, e)
	var state: Dictionary = e.warden
	var location := role(e)
	var previous: float = float(state.remaining)
	state.remaining = maxf(0., previous - dt)
	match str(state.phase):
		"wait":
			if absf(float(e.x) - w.player.x) > FAR_GUARD_DISTANCE: return
			if location == "terrace" and absf(float(e.x) - Vector2(e.home).x) > 94.:
				var next_x := move_toward(float(e.x), Vector2(e.home).x, 190. * dt)
				var support: float = w.floor_at(next_x)
				if CampaignGround.has_floor(support):
					e.facing = -1 if next_x < float(e.x) else 1
					e.x = next_x
					e.y = support
					return
			e.wait = maxf(0., float(e.wait) - dt)
			if e.wait <= 0.: start_motion(w, e, location)
		"shift":
			e.facing = state.side
			var progress := 1. - float(state.remaining) / float(state.duration)
			e.x = lerpf(float(state.start_x), float(state.target_x), smoothstep(0., 1., progress))
			e.y = w.floor_at(float(e.x))
			if state.remaining <= 0.: lock_attack(w, e)
		"hop":
			var progress := 1. - float(state.remaining) / TERRACE_HOP
			var point := Vector2(state.start).lerp(Vector2(state.end), progress)
			point.y -= sin(progress * PI) * 65.
			e.x = point.x
			e.y = point.y
			if state.remaining <= 0.:
				e.y = Vector2(state.end).y
				lock_attack(w, e)
		"windup":
			e.facing = state.side
			e.windup = state.remaining
			if state.remaining <= 0.: release(w, e)
		"active":
			e.facing = state.side
			var strike := strike_rect(w, e)
			if location == "water" and strike.has_area():
				var earlier := strike_rect(w, e, previous)
				if earlier.has_area(): strike = strike.merge(earlier)
			if w.state == "playing" and threatens(w, strike): w.damage_player("warden")
			if state.remaining <= 0.:
				if location == "terrace" and float(e.y) < float(w.floor_at(float(e.x))):
					state.phase = "drop"
					state.drop_from = float(e.y)
					state.remaining = TERRACE_DROP
				else:
					start_recovery(e)
		"drop":
			var progress := 1. - float(state.remaining) / TERRACE_DROP
			e.y = lerpf(float(state.drop_from), w.floor_at(float(e.x)), progress * progress)
			if state.remaining <= 0.: start_recovery(e)
		"recover":
			e.recover = state.remaining
			if state.remaining <= 0.:
				state.phase = "wait"
				e.wait = .62

static func draw_threat(v, e: Dictionary) -> void:
	if not applies(e) or bool(e.defeated): return
	var state: Dictionary = e.get("warden", {})
	var phase: String = str(state.get("phase", "wait"))
	if phase not in ["windup", "active"]: return
	var location := role(e)
	var ink: Color = COLOURS[location]
	if location == "water" and phase == "windup":
		var x: float = float(state.start_x)
		var direction: float = float(state.side)
		for i in int(ceil(absf(float(state.target_x) - x) / 29.)):
			var marker_x := x + direction * float(i) * 29.
			if marker_x < v.camera_x - 16. or marker_x > v.camera_x + v.scene_w + 16.: continue
			var floor: float = v.world.floor_at(marker_x)
			if not CampaignGround.has_floor(floor): continue
			var p: Vector2 = v.at(Vector2(marker_x, floor - 10.))
			v.draw_rect(Rect2(p - Vector2(6., 2.), Vector2(12., 4.)), Color("203d4a"))
			v.draw_line(p - Vector2(6. * direction, 2.), p + Vector2(3. * direction, -2.), ink, 2.)
			v.draw_rect(Rect2(p + Vector2(4. * direction, -5.), Vector2(3., 5.)), ink)
		return
	var area := strike_rect(v.world, e)
	if not area.has_area() or area.end.x < v.camera_x or area.position.x > v.camera_x + v.scene_w: return
	var start: Vector2 = v.at(area.position)
	var edge := Rect2(start, area.size)
	if phase == "windup":
		v.draw_rect(edge, Color(ink, .16))
		for index in int(ceil(edge.size.x / 18.)):
			var x := start.x + float(index) * 18.
			var size := Vector2(minf(11., edge.end.x - x), 3.)
			v.draw_rect(Rect2(Vector2(x, start.y), size), ink)
			v.draw_rect(Rect2(Vector2(x, edge.end.y - size.y), size), ink)
		if location == "roots":
			var animate: bool = v.host.motion_enabled and not v.host.options.reduced_motion
			var tick := int((float(TIMING.roots.windup) - float(state.remaining)) * 12.) if animate else 0
			for index in 8:
				var x := start.x + 11. + float(index) * 20.
				var height := 8. + float(posmod(tick + index * 3, 6)) * 4.
				v.draw_rect(Rect2(Vector2(x, edge.end.y - height), Vector2(3., 3.)), ink)
		return
	var core := Color("fff1c7")
	if location == "terrace":
		v.draw_rect(edge, Color(ink, .35))
		v.draw_rect(Rect2(start + Vector2(0., 9.), Vector2(edge.size.x, 10.)), ink)
		v.draw_rect(Rect2(start + Vector2(0., 13.), Vector2(edge.size.x, 3.)), core)
	elif location == "roots":
		v.draw_rect(edge, Color(ink, .32))
		for i in 7:
			var x := start.x + 6. + float(i) * 23.
			var height := 18. + float(i % 3) * 8.
			var base := edge.end.y
			v.draw_colored_polygon(PackedVector2Array([Vector2(x, base), Vector2(x + 11., base - height), Vector2(x + 21., base)]), ink)
			v.draw_rect(Rect2(Vector2(x + 9., base - height + 7.), Vector2(4., 11.)), core)
	else:
		var centre := edge.get_center().round()
		var direction: float = float(state.side)
		var contour := PackedVector2Array()
		for offset: Vector2 in WAVE_EDGE: contour.append(centre + offset * Vector2(direction, 1.))
		v.draw_colored_polygon(contour, Color("257c97"))
		for piece: Rect2 in [Rect2(-23., 10., 40., 3.), Rect2(-16., 4., 24., 3.), Rect2(-7., -2., 19., 4.), Rect2(2., -8., 16., 4.), Rect2(6., -12., 17., 4.)]:
			var x := piece.position.x if direction > 0. else -piece.end.x
			v.draw_rect(Rect2(centre + Vector2(x, piece.position.y), piece.size), ink)
		for fleck: Rect2 in [Rect2(14., -14., 9., 3.), Rect2(1., -7., 11., 2.), Rect2(-8., 0., 8., 2.)]:
			var x := fleck.position.x if direction > 0. else -fleck.end.x
			v.draw_rect(Rect2(centre + Vector2(x, fleck.position.y), fleck.size), core)

static func draw_material(v, e: Dictionary) -> void:
	if not applies(e) or bool(e.defeated): return
	var location := role(e)
	var p: Vector2 = v.at(Vector2(float(e.x), float(e.y) - 70.))
	var ink: Color = COLOURS[location]
	var open := exposed(e)
	v.draw_rect(Rect2(p - Vector2(12., 6.), Vector2(24., 12.)), Color("30253a"))
	if open:
		for side in [-1., 1.]:
			v.draw_rect(Rect2(p + Vector2(side * 11. - 3., -4.), Vector2(6., 8.)), ink.darkened(.4))
		v.draw_rect(Rect2(p - Vector2(4., 4.), Vector2(8., 8.)), Color("ffe090"))
		v.draw_rect(Rect2(p - Vector2(2., 2.), Vector2(4., 4.)), Color("fff5d6"))
		return
	match location:
		"water":
			for i in 3:
				v.draw_rect(Rect2(p + Vector2(-8. + float(i) * 6., -3. + float(i % 2) * 3.), Vector2(5., 3.)), ink)
		"terrace":
			v.draw_rect(Rect2(p - Vector2(8., 1.), Vector2(16., 3.)), ink.darkened(.2))
			v.draw_rect(Rect2(p - Vector2(3., 4.), Vector2(6., 8.)), ink)
		"roots":
			v.draw_rect(Rect2(p - Vector2(8., 3.), Vector2(16., 6.)), ink.darkened(.35))
			v.draw_rect(Rect2(p - Vector2(4., 5.), Vector2(8., 4.)), ink)
