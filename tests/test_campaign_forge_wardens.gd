extends SceneTree

const DT := 1. / 60.
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + label)

func fresh(section: String, hero: String = "aion") -> AionCampaignWorld:
	var w := AionCampaignWorld.new()
	w.begin(hero)
	w.load_section(section)
	w.enemies.assign(w.enemies.filter(func(e): return CampaignWardens.applies(e)))
	var e: Dictionary = w.enemies[0]
	var x := float(e.x) - 285.
	w.player = Vector2(x, w.floor_at(x))
	w.objects.clear()
	w.hazards.clear()
	w.zones.clear()
	w.pickups.clear()
	w.npcs.clear()
	w.crates.clear()
	w.invulnerable = 0.
	w.pending_events.clear()
	return w

func phase(e: Dictionary) -> String:
	return str(e.get("warden", {}).get("phase", ""))

func advance(w: AionCampaignWorld, frames: int) -> void:
	for i in frames: w.step(DT)

func until_phase(w: AionCampaignWorld, e: Dictionary, target: String) -> bool:
	for i in 360:
		if phase(e) == target: return true
		w.step(DT)
	return false

func check_cycles() -> void:
	for section: String in CampaignWardens.ROLES:
		var w := fresh(section)
		var e: Dictionary = w.enemies[0]
		var e_id := section + ":enemy:99"
		var gate: Dictionary = w.gates.filter(func(g): return e_id in g.ids)[0]
		var home: Vector2 = e.home
		check(e.id == e_id and e.hp == 12 and w.gate_closed(gate), section + " keeps its original mandatory guard ID, health and gate")
		check(until_phase(w, e, "windup"), section + " enters its regional visible warning on normal physics ticks")
		var warned_at := w.time
		var locked := CampaignWardens.strike_rect(w, e)
		var warning_x: float = e.x
		check(w.hp == 1 and e.attacks == 0 and not CampaignWardens.exposed(e), section + " warns before dealing damage or becoming exposed")
		if section == "water":
			check(absf(warning_x - home.x) >= 100. and is_equal_approx(float(e.y), w.floor_at(warning_x)), "Water moves laterally on supported terrain before locking the low wave")
		elif section == "terrace":
			var deck := CampaignWardens.terrace_deck(w, e)
			check(deck in w.platforms and is_equal_approx(float(e.y), deck.position.y) and locked.end.y < w.player.y - 100., "Terrace lands on a real upper deck and leaves more than 100 pixels of floor clearance")
		else:
			check(locked.has_area() and is_equal_approx(locked.get_center().x, w.player.x) and is_equal_approx(locked.end.y, w.floor_at(w.player.x)), "Roots locks the visible floor strip under the original player position")
			w.move_axis = Vector2.LEFT
			advance(w, 31)
			w.move_axis = Vector2.ZERO
			check(CampaignWardens.strike_rect(w, e) == locked and w.player.x < locked.position.x, "Tracking ends with the warning and normal lateral input leaves the Roots strip")
		check(until_phase(w, e, "active") and w.time - warned_at >= .60, section + " gives at least 0.60 seconds of actual warning before release")
		check(w.pending_events.count("guardian") == 1 and e.attacks == 1, section + " emits one synchronized enemy attack event")
		if section == "water":
			var first_crest := CampaignWardens.strike_rect(w, e)
			w.jump_press()
			w.jump_release()
			advance(w, 12)
			var later_crest := CampaignWardens.strike_rect(w, e)
			check(later_crest.position.x < first_crest.position.x and is_equal_approx(later_crest.end.y + 1., w.floor_at(later_crest.get_center().x)), "The Water crest actually travels along the drawn floor line")
		else:
			check(CampaignWardens.strike_rect(w, e) == locked, section + " uses exactly the indivisible locked warning rectangle for damage")
		check(until_phase(w, e, "recover") and w.hp == 1, section + " readable safe choice survives the whole attack through normal movement")
		check(is_equal_approx(float(e.y), w.floor_at(float(e.x))), section + " finishes on melee-reachable ground")
		var opened_at := w.time
		check(CampaignWardens.exposed(e) and until_phase(w, e, "wait") and w.time - opened_at >= .75, section + " has at least 0.75 seconds of real punish time")
		if section == "water":
			w.invulnerable = 99.
			check(until_phase(w, e, "windup") and float(e.x) - warning_x >= 180., "The Water Warden visibly alternates to the far side of its nearby lane on the next pattern")

func check_harm_and_migration() -> void:
	for section: String in CampaignWardens.ROLES:
		var w := fresh(section)
		var e: Dictionary = w.enemies[0]
		check(until_phase(w, e, "windup"), section + " reaches an independently sampled damage window")
		var warned := CampaignWardens.strike_rect(w, e)
		var save := w.snapshot()
		var reopened := AionCampaignWorld.new()
		check(reopened.restore(save), section + " exact regional encounter reopens from the existing save format")
		var restored: Dictionary = reopened.enemies.filter(func(candidate): return CampaignWardens.applies(candidate))[0]
		check(phase(restored) == "windup" and CampaignWardens.strike_rect(reopened, restored) == warned, section + " restores the same warning geometry and phase")
		if section == "terrace":
			var deck := CampaignWardens.terrace_deck(reopened, restored)
			check(reopened.platforms.count(deck) == 1, "Terrace checkpoint reload keeps exactly one real supporting deck")
		check(until_phase(w, e, "active"), section + " fires in the damage fixture")
		if section == "terrace":
			w.player.y = CampaignWardens.strike_rect(w, e).get_center().y + 37.
		var elapsed := 65 if section == "water" else 5
		advance(w, elapsed)
		check(w.hp == 0 and w.attempts_remaining == 2, section + " active geometry damages an actual player inside the marked path exactly once")
	var old := fresh("terrace")
	var old_guard: Dictionary = old.enemies[0]
	old_guard.x = float(old_guard.x) - 225.
	old_guard.y = -97.
	old_guard.hp = 5
	old_guard.attacks = 2
	old_guard.windup = .42
	var old_deck := CampaignWardens.terrace_deck(old, old_guard)
	old.platforms.erase(old_deck)
	var migrated := AionCampaignWorld.new()
	check(migrated.restore(old.snapshot()) and migrated.platforms.count(old_deck) == 1, "Pre-upgrade Terrace checkpoints gain the one real approach deck")
	migrated.step(DT)
	var new_guard: Dictionary = migrated.enemies[0]
	check(new_guard.hp == 5 and new_guard.attacks == 2 and absf(float(new_guard.x) - float(old_guard.x)) < 5. and is_equal_approx(float(new_guard.y), migrated.floor_at(float(new_guard.x))), "Legacy injured Warden keeps combat progress and walks back on its actual floor instead of snapping")

func check_hero_attacks() -> void:
	for section: String in CampaignWardens.ROLES:
		for hero: String in AionCampaignWorld.HEROES:
			var w := fresh(section, hero)
			var e: Dictionary = w.enemies[0]
			w.invulnerable = 99.
			var hp: int = e.hp
			var armour: int = e.armour
			w.damage_enemy(e, 4)
			check(e.hp == hp and e.armour == armour, section + "/" + hero + " cannot brute-force the closed shell")
			check(until_phase(w, e, "recover"), section + "/" + hero + " reaches the punish window")
			var xx: float = float(e.x) - 180.
			w.player = Vector2(xx, w.floor_at(xx))
			w.aim_direction = Vector2.RIGHT
			w.facing = 1
			w.ammunition = 1
			w.attack_press()
			w.attack_release()
			advance(w, 18)
			check(w.shots == 1 and w.ammunition == 0 and (e.hp < hp or e.armour < armour), section + "/" + hero + " can punish with the actual last sidearm round")
			hp = e.hp
			armour = e.armour
			xx = float(e.x) - 57.
			w.player = Vector2(xx, w.floor_at(xx))
			advance(w, 3)
			w.attack_press()
			w.attack_release()
			advance(w, 12)
			check(w.shots == 1 and w.ammunition == 0 and (e.hp < hp or e.armour < armour), section + "/" + hero + " can use the grounded recovery with zero ammo and an ordinary attack press")
			check(CampaignWardens.exposed(e), section + "/" + hero + " gets time for both an aimed shot and melee approach")

func run() -> void:
	check_cycles()
	check_harm_and_migration()
	check_hero_attacks()
	print("RESULT: %d regional Warden checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
