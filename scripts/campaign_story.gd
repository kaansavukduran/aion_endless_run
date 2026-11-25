class_name CampaignStory
extends RefCounted

const SIGNAL_X := 1160.
const LANTERN_X := 720.
const PLATE_X := 720.
const NOTICE_SECONDS := 4.5
const WORDS := {
	"story_lantern": ["Feneri röleye bağlayan tel kesilmiş.", "Someone cut the wire linking this lantern to the relay."],
	"story_signal": ["Röle sinyal veriyor. Karga ona tepki verdi.", "The relay is sending a signal. The crow reacted to it."],
	"story_keeper": ["Bekçi · Al bu ikmali. Kıyıda hâlâ yardım bekleyenler var.", "Keeper · Take these supplies. Others on the coast still need help."],
	"story_technician": ["Teknisyen · Bakım rölesine ulaş. Fenerlerin hattı oradan geçiyor.", "Technician · Reach the relay. The lanterns are wired through it."],
	"story_pump": ["Teknisyen · Bu parça pompayı çalıştırır. Alt kanalda dene.", "Technician · This part starts the pump. Try it in the lower channel."],
	"story_courier": ["Kurye · Fenerleri söndürme emri Bakır Röle’den geçmiş.", "Courier · The order to kill the lanterns passed through Copper Relay."],
	"story_gardener": ["Bahçıvan · Fenerler önce yukarıdan aşağı söndü. Üst hatta bak.", "Gardener · The upper lanterns went dark first. Check that line."],
	"story_observer": ["Gözcü · Su kapısı fenerlerden hemen sonra kapandı.", "Observer · The floodgate closed right after the lanterns went dark."],
	"story_archivist": ["Arşivci · Emrin mührü doğru görünüyor. İmza kayıtlarda yok.", "Archivist · The order has a seal. Its signature is missing from the records."],
	"story_water": ["Su kanalının bakım levhasında kapanış saati kazılı.", "The service plate in the channel records when the gate closed."],
	"story_top": ["Üst hattın kabloları aynı noktada Bakır Röle’ye bağlanıyor.", "The upper cables all lead to Copper Relay."],
	"story_roots": ["Kök Geçidi’nde röle emrinin kopyası var. Mühür sonradan basılmış.", "Root Passage holds a copy of the relay order. The seal was added later."],
	"won_text": ["Fenerler yeniden yanıyor. Sahte bakım emri, donmuş gözlemevinin çağrı kodunu taşıyor.", "The lanterns burn again. The forged maintenance order carries the frozen observatory’s call sign."]
}
const ROUTE_CLUES := {
	"canopy": "story_top", "terrace": "story_top", "water": "story_water", "roots": "story_roots"
}
const ROLE_CLUES := {
	"keeper": "story_keeper", "technician": "story_technician", "courier": "story_courier",
	"gardener": "story_gardener", "observer": "story_observer", "archivist": "story_archivist"
}
const NOTE_ORDER := [
	"story_archivist", "story_roots", "story_observer", "story_water", "story_gardener", "story_top",
	"story_pump", "story_courier", "story_technician", "story_keeper", "story_signal", "story_lantern"
]

static func line(language: String, key: String) -> String:
	var options: Array = WORDS.get(key, [])
	if options.is_empty():
		return ""
	return str(options[0 if GameText.language_for_locale(language) == "tr" else 1])

static func clue_id(key: String) -> String:
	return "story:" + key.trim_prefix("story_")

static func latest_note(w, language: String) -> String:
	for key: String in NOTE_ORDER:
		if w.discovered.has(clue_id(key)):
			return line(language, key)
	return ""

static func secret_count(w) -> int:
	var count := 0
	for id in w.discovered:
		if not str(id).begins_with("story:") and not str(id).begins_with("map:"):
			count += 1
	return count

static func record(w, key: String) -> bool:
	var id := clue_id(key)
	if w.discovered.has(id):
		return false
	w.discovered[id] = true
	w.notice = key
	w.notice_time = NOTICE_SECONDS
	w.pending_events.append("story_clue")
	return true

static func signal_crow(w) -> Dictionary:
	for enemy: Dictionary in w.enemies:
		if enemy.kind != "crow" or bool(enemy.defeated) or not bool(enemy.active):
			continue
		# The relay is bound to the authored introductory group. A later crow
		# flying back through the coast must not activate the introductory prop.
		if absf(float(enemy.home.x) - SIGNAL_X) <= 390. and (float(enemy.windup) > .0 or float(enemy.get("dive", 0.)) > .0):
			return enemy
	return {}

static func step(w) -> void:
	if w.state != "playing":
		return
	var section: String = w.section
	if w.pending_events.has("npc_contact"):
		for keeper: Dictionary in w.npcs:
			if not w.greeted.has(str(keeper.id)) or float(keeper.get("thank_age", 99.)) > .06:
				continue
			var key: String = "story_pump" if keeper.get("gift") == "relay_part" else ROLE_CLUES.get(keeper.get("role", "keeper"), "story_keeper")
			if record(w, key):
				return
	if section == "shore":
		var opening_slot: bool = w.notice_time <= .0 or w.notice == "arc_checkpoint"
		var free_slot: bool = opening_slot or w.notice == "story_lantern"
		if free_slot and w.player.x >= 680. and w.player.x < 1510. and not w.discovered.has(clue_id("story_signal")) and not signal_crow(w).is_empty():
			record(w, "story_signal")
			return
		if opening_slot and w.player.x >= 515. and w.player.x < 1050. and record(w, "story_lantern"):
			return
	if w.notice_time > .0:
		return
	var route_clue: String = ROUTE_CLUES.get(section, "")
	if not route_clue.is_empty() and absf(w.player.x - PLATE_X) <= 150. and absf(w.player.y - float(w.floor_at(PLATE_X))) <= 125.:
		record(w, route_clue)

static func draw(v) -> void:
	var w = v.world
	if w.section == "shore":
		draw_signal(v)
		var floor: float = w.floor_at(LANTERN_X)
		if LANTERN_X >= v.camera_x - 36. and LANTERN_X <= v.camera_x + v.scene_w + 36. and CampaignGround.has_floor(floor):
			var foot: Vector2 = v.at(Vector2(LANTERN_X, floor))
			# Two stepped, loose wire ends are visible beside the existing lamp.
			v.draw_polyline(PackedVector2Array([foot + Vector2(5., -50.), foot + Vector2(16., -49.), foot + Vector2(23., -41.)]), Color("3a2a38"), 4.)
			v.draw_polyline(PackedVector2Array([foot + Vector2(35., -36.), foot + Vector2(46., -23.), foot + Vector2(55., -22.)]), Color("3a2a38"), 4.)
			v.draw_rect(Rect2(foot + Vector2(21., -43.), Vector2(4., 3.)), Color("c38d5b"))
			v.draw_rect(Rect2(foot + Vector2(33., -38.), Vector2(4., 3.)), Color("c38d5b"))
	elif ROUTE_CLUES.has(w.section) and PLATE_X >= v.camera_x - 36. and PLATE_X <= v.camera_x + v.scene_w + 36.:
		var floor: float = w.floor_at(PLATE_X)
		if CampaignGround.has_floor(floor):
			var foot: Vector2 = v.at(Vector2(PLATE_X, floor))
			v.draw_rect(Rect2(foot + Vector2(-5., -37.), Vector2(10., 37.)), Color("332b36"))
			v.draw_rect(Rect2(foot + Vector2(-3., -31.), Vector2(4., 31.)), Color("8e654b"))
			v.draw_rect(Rect2(foot + Vector2(-20., -53.), Vector2(40., 26.)), Color("352b39"))
			v.draw_rect(Rect2(foot + Vector2(-17., -50.), Vector2(34., 19.)), Color("8e654b"))
			v.draw_rect(Rect2(foot + Vector2(-15., -47.), Vector2(30., 13.)), Color("3a323a"))
			for i in 3:
				v.draw_rect(Rect2(foot + Vector2(-11. + i * 8., -42.), Vector2(6., 2.)), Color("e0b583"))

static func draw_signal(v) -> void:
	var w = v.world
	if w.section != "shore" or SIGNAL_X < v.camera_x - 36. or SIGNAL_X > v.camera_x + v.scene_w + 36.:
		return
	var floor: float = w.floor_at(SIGNAL_X)
	if not CampaignGround.has_floor(floor):
		return
	var foot: Vector2 = v.at(Vector2(SIGNAL_X, floor))
	var crow := signal_crow(w)
	var sending := not crow.is_empty()
	# Copper feet meet the collision surface. All art offsets reference that
	# single foot rather than the cabinet's animated screen-space light.
	v.draw_rect(Rect2(foot + Vector2(-18., -7.), Vector2(36., 7.)), Color("39302e"))
	v.draw_rect(Rect2(foot + Vector2(-13., -9.), Vector2(26., 4.)), Color("bd8555"))
	v.draw_rect(Rect2(foot + Vector2(-17., -44.), Vector2(34., 34.)), Color("2b2434"))
	v.draw_rect(Rect2(foot + Vector2(-14., -39.), Vector2(28., 27.)), Color("744d4b"))
	v.draw_rect(Rect2(foot + Vector2(-11., -36.), Vector2(22., 13.)), Color("291f2c"))
	v.draw_rect(Rect2(foot + Vector2(-15., -43.), Vector2(30., 3.)), Color("d2a174"))
	v.draw_rect(Rect2(foot + Vector2(-5., -48.), Vector2(11., 4.)), Color("573d42"))
	v.draw_rect(Rect2(foot + Vector2(-1., -59.), Vector2(3., 12.)), Color("d2a174"))
	var signal_colour := Color("ffe09b") if sending else Color("775669")
	v.draw_rect(Rect2(foot + Vector2(-4., -61.), Vector2(9., 4.)), signal_colour)
	for i in 3:
		v.draw_rect(Rect2(foot + Vector2(-8. + i * 6., -32.), Vector2(4., 5.)), signal_colour)
	v.draw_rect(Rect2(foot + Vector2(-9., -19.), Vector2(18., 2.)), Color("d2a174"))
	if not sending:
		return
	# Feedback appears only for the actual crow's windup/dive. Reduced motion
	# shows the same coded signal at fixed positions with no pulse loop.
	var tip := foot + Vector2(2., -62.)
	var target: Vector2 = v.at(Vector2(float(crow.x), float(crow.y) - 30.))
	var phase := fmod(w.time * 3., 1.) if v.host.motion_enabled and not v.host.options.reduced_motion else .45
	for i in 3:
		var point := tip.lerp(target, minf(.88, (float(i) + phase) / 3.)).round()
		v.draw_rect(Rect2(point, Vector2(5., 3.)), Color("dca974"))
