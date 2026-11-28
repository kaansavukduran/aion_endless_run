class_name CampaignStory
extends RefCounted

const SIGNAL_X := 1160.
const FIRST_CROW := "shore:enemy:3"
const LANTERN_X := 720.
const PLATE_X := 720.
# Read the plaque on the hollow floor before reaching the ammo cache at x7830.
const ROOT_COPY_X := 7748.
const NOTICE_SECONDS := 4.5
const WORDS := {
	"story_hero_aion": ["Aion · Kesik fener hattını izleyeceğim.", "Aion · I’ll trace the cut lantern wire."],
	"story_hero_sheep": ["Kutsanmış · Sürümü güvene götürmeliyim.", "Kutsanmış · I need to get my flock to safety."],
	"story_hero_rabbit": ["Ayça · İskele bekçilerine yardıma geldim.", "Ayça · I came to help the quay keepers."],
	"story_hero_eren": ["Eren · İmdat çağrısı burada kesildi.", "Eren · The distress call cut out here."],
	"story_hero_armadillo": ["Doğukan · Bakım yolunu açmak bana düştü.", "Doğukan · I’ll reopen the service path."],
	"story_hero_frog": ["Light · Su kanalında kalanları arıyorum.", "Light · I’m looking for survivors in the canal."],
	"story_lantern": ["Feneri röleye bağlayan tel kesilmiş.", "Someone cut the wire linking this lantern to the relay."],
	"story_signal": ["Karga röle sinyaliyle dalıyor. Ahşap siper dalışı keser.", "The crow dives on the relay’s signal. The timber shelter stops its dive."],
	"story_keeper": ["Bekçi · Al bu ikmali. Kıyıda hâlâ yardım bekleyenler var.", "Keeper · Take these supplies. Others on the coast still need help."],
	"story_technician": ["Teknisyen · Bakım rölesine ulaş. Fenerlerin hattı oradan geçiyor.", "Technician · Reach the relay. The lanterns are wired through it."],
	"story_pump": ["Teknisyen · Bu parça pompayı çalıştırır. Alt kanalda dene.", "Technician · This part starts the pump. Try it in the lower channel."],
	"story_courier": ["Kurye · Fenerleri söndürme emri Bakır Röle’den geçmiş.", "Courier · The order to kill the lanterns passed through Copper Relay."],
	"story_gardener": ["Bahçıvan · Fenerler önce yukarıdan aşağı söndü. Üst hatta bak.", "Gardener · The upper lanterns went dark first. Check that line."],
	"story_observer": ["Gözcü · Su kapısı fenerlerden hemen sonra kapandı.", "Observer · The floodgate closed right after the lanterns went dark."],
	"story_archivist": ["Arşivci · Emrin mührü doğru görünüyor. İmza kayıtlarda yok.", "Archivist · The order has a seal. Its signature is missing from the records."],
	"story_water": ["Bakım levhası · Alt kanal, Bakır Röle’ye bağlı.", "Service plate · The lower channel leads to Copper Relay."],
	"story_top": ["Üst iskeledeki bakır kablolar röleye uzanıyor.", "The upper deck’s copper wires run to the relay."],
	"story_terrace": ["Teras levhası · Üst bakım iskelesinde ikmal bırakılmış.", "Terrace plate · Supplies were left on the upper service deck."],
	"story_roots": ["Ana kök hattı röleye gider. Eski bakım yolu çukurda kalmış.", "The main root line leads to the relay. The old service lane is in the hollow."],
	"story_roots_secret": ["Bakım kopyası · Emrin mührü sonradan basılmış. Burada yedek cephane var.", "Maintenance copy · The order was sealed later. Spare rounds are here."],
	"won_text": ["Fenerler yeniden yanıyor. Sahte bakım emri, donmuş gözlemevinin çağrı kodunu taşıyor.", "The lanterns burn again. The forged maintenance order carries the frozen observatory’s call sign."]
}
const ROUTE_CLUES := {
	"canopy": ["story_top", "route_terrace"], "terrace": ["story_terrace", "route_terrace"],
	"water": ["story_water", "route_water"], "roots": ["story_roots", "route_roots"]
}
const ROLE_CLUES := {
	"keeper": "story_keeper", "technician": "story_technician", "courier": "story_courier",
	"gardener": "story_gardener", "observer": "story_observer", "archivist": "story_archivist"
}
const NOTE_ORDER := [
	"story_roots_secret", "story_archivist", "story_roots", "story_observer", "story_water", "story_terrace", "story_gardener", "story_top",
	"story_pump", "story_courier", "story_technician", "story_keeper", "story_signal", "story_lantern"
]

static func line(language: String, key: String) -> String:
	var options: Array = WORDS.get(key, [])
	if options.is_empty():
		return ""
	return str(options[0 if GameText.language_for_locale(language) == "tr" else 1])

static func clue_id(key: String) -> String:
	return "story:" + key.trim_prefix("story_")

static func opening(w) -> void:
	w.notice = "story_hero_" + str(w.character)
	w.notice_time = NOTICE_SECONDS

static func latest_note(w, language: String) -> String:
	for key: String in NOTE_ORDER:
		if w.discovered.has(clue_id(key)):
			return line(language, key)
	return ""

static func secret_count(w) -> int:
	var count := 0
	for id in w.discovered:
		if id == "story:roots_secret" or (not str(id).begins_with("story:") and not str(id).begins_with("map:")):
			count += 1
	return count

static func record(w, key: String, announce: bool = true) -> bool:
	var id := clue_id(key)
	if w.discovered.has(id):
		return false
	w.discovered[id] = true
	if announce:
		w.notice = key
		w.notice_time = NOTICE_SECONDS
	w.pending_events.append("story_clue")
	return true

static func signal_crow(w) -> Dictionary:
	for enemy: Dictionary in w.enemies:
		if enemy.id != FIRST_CROW or enemy.kind != "crow" or bool(enemy.defeated) or not bool(enemy.active):
			continue
		# Fight state and the cabinet share the same cue. Reserve crows from
		# other encounters cannot enter this loop if they fly back toward it.
		if float(enemy.windup) > .0 or float(enemy.get("dive", 0.)) > .0:
			return enemy
		break
	return {}

static func reads_ground_plate(w, x: float, reach: float) -> bool:
	var foot := CampaignRoutes.foot(w)
	if absf(foot.x - x) > reach or not w.grounded():
		return false
	var floor: float = w.floor_at(foot.x)
	return CampaignGround.has_floor(floor) and absf(foot.y - floor) < 5.

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
		var opening_slot: bool = w.notice_time <= .0 or w.notice == "arc_checkpoint" or w.notice.begins_with("story_hero_")
		var free_slot: bool = opening_slot or w.notice == "story_lantern"
		if w.player.x >= 680. and w.player.x < 1510. and not w.discovered.has(clue_id("story_signal")) and not signal_crow(w).is_empty():
			if record(w, "story_signal", free_slot):
				return
		if opening_slot and w.player.x >= 515. and w.player.x < 1050. and record(w, "story_lantern"):
			return
	if section == "roots" and w.player.x >= float(CampaignGround.BRANCH_ZONES.roots.x) and reads_ground_plate(w, ROOT_COPY_X, 68.) and record(w, "story_roots_secret"):
		return
	var route_clue: Array = ROUTE_CLUES.get(section, [])
	if not route_clue.is_empty() and reads_ground_plate(w, PLATE_X, 130.):
		record(w, route_clue[0], w.notice_time <= .0 or w.notice == "arc_checkpoint")

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
	elif ROUTE_CLUES.has(w.section):
		var route: Array = ROUTE_CLUES[w.section]
		draw_plate(v, PLATE_X, route[0], route[1])
		if w.section == "roots":
			draw_plate(v, ROOT_COPY_X, "story_roots_secret", "route_root_secret")

static func draw_plate(v, x: float, clue: String, art: String) -> void:
	if x < v.camera_x - 52. or x > v.camera_x + v.scene_w + 52.:
		return
	var floor: float = v.world.floor_at(x)
	if CampaignGround.has_floor(floor):
		var frame := int(v.world.discovered.has(clue_id(clue)))
		CampaignForgePropArt.draw(v, art, v.at(Vector2(x, floor)), frame)

static func draw_signal(v) -> void:
	var w = v.world
	if w.section != "shore" or SIGNAL_X < v.camera_x - 36. or SIGNAL_X > v.camera_x + v.scene_w + 36.:
		return
	var floor: float = w.floor_at(SIGNAL_X)
	if not CampaignGround.has_floor(floor):
		return
	var foot: Vector2 = v.at(Vector2(SIGNAL_X, floor))
	var crow := signal_crow(w)
	var animated: bool = v.host.motion_enabled and not v.host.options.reduced_motion
	var signal_frame := 0
	if not crow.is_empty():
		signal_frame = 1 + posmod(floori(w.time * 7.), 3) if animated else 3
	CampaignForgePropArt.draw(v, "shore_signal", foot, signal_frame)
	if crow.is_empty():
		return
	var tip := foot + Vector2(0., -64.)
	var target: Vector2 = v.at(Vector2(float(crow.x), float(crow.y) - 24.))
	var phase := fmod(w.time * 3., 1.) if animated else .35
	for i in 4:
		var point := tip.lerp(target, minf(.90, (float(i) + phase) / 4.)).round()
		v.draw_rect(Rect2(point - Vector2(5., 3.), Vector2(10., 6.)), Color("503947"))
		v.draw_rect(Rect2(point - Vector2(3., 1.), Vector2(6., 2.)), Color("ffdc91"))
