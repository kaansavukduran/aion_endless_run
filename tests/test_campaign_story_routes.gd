extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + description)

func world_in(section: String) -> AionCampaignWorld:
	var w := AionCampaignWorld.new()
	w.begin("aion")
	w.load_section(section)
	w.state = "playing"
	return w

func first_signal() -> void:
	var w := world_in("shore")
	w.player = Vector2(855., w.floor_at(855.))
	var first: Dictionary = w.enemies.filter(func(e): return e.id == CampaignStory.FIRST_CROW)[0]
	check(first.kind == "crow" and CampaignStory.signal_crow(w).is_empty(), "The authored first crow owns the opening signal and its idle state is silent")
	w.enemies.assign([first])
	w.spawn_enemy("crow", 1000., -180., 940)
	var reserve: Dictionary = w.enemies.back()
	reserve.active = true
	w.enemy_shot(reserve)
	CampaignStory.step(w)
	check(CampaignStory.signal_crow(w).is_empty() and not w.discovered.has("story:signal"), "A later crow alone cannot send the opening code")
	w.enemies.pop_back()
	for i in 210:
		w.step_enemies(1. / 60.)
		if not CampaignStory.signal_crow(w).is_empty():
			CampaignStory.step(w)
			break
	check(CampaignStory.signal_crow(w).get("id") == CampaignStory.FIRST_CROW and w.discovered.has("story:signal"), "The ordinary attack windup drives both the prop and the persistent clue")

	var shelter: Rect2 = CampaignRoutes.SHELTERS.shore.front()
	var hit_x := shelter.get_center().x
	w.player = Vector2(hit_x, w.floor_at(hit_x))
	first.home = Vector2(hit_x, -185.)
	first.x = hit_x
	first.y = -185.
	for i in 90:
		w.step_enemies(1. / 60.)
		if first.has("roof_deflection"):
			break
	var contact: Vector2 = first.get("roof_deflection", Vector2.INF)
	check(contact.is_finite() and is_equal_approx(contact.y, shelter.position.y), "The physical deflection emits a cue at the exact collision deck")
	check(is_zero_approx(float(first.dive)) and CampaignStory.signal_crow(w).is_empty(), "Deflection stops the real attack and extinguishes the active cabinet signal")

func lower_copy() -> void:
	var w := world_in("canopy")
	w.player = Vector2(CampaignStory.PLATE_X, w.floor_at(CampaignStory.PLATE_X))
	CampaignStory.step(w)
	w.load_section("terrace")
	w.player = Vector2(CampaignStory.PLATE_X, w.floor_at(CampaignStory.PLATE_X))
	CampaignStory.step(w)
	check(w.discovered.has("story:top") and w.discovered.has("story:terrace"), "Canopy and Terrace plates save distinct messages")
	w.load_section("roots")
	w.player = Vector2(CampaignStory.PLATE_X, w.floor_at(CampaignStory.PLATE_X))
	CampaignStory.step(w)
	check(w.discovered.has("story:roots") and not w.discovered.has("story:roots_secret"), "The Roots entrance plate leaves the maintenance copy undiscovered")
	var approach_x := float(CampaignGround.BRANCH_ZONES.roots.x) - 15.
	w.player = Vector2(approach_x, w.floor_at(approach_x))
	CampaignStory.step(w)
	check(not w.discovered.has("story:roots_secret"), "The lower maintenance copy waits for the player to enter the actual dark lane")
	var copy_x := CampaignStory.ROOT_COPY_X
	var platforms := w.platforms.filter(func(deck): return deck.position.x <= copy_x and deck.end.x >= copy_x and deck.position.y < 0.)
	w.player = Vector2(copy_x, platforms.front().position.y)
	CampaignStory.step(w)
	check(w.grounded() and not w.discovered.has("story:roots_secret"), "Crossing the actual roof does not read the lower plate")
	w.player = Vector2(copy_x, w.floor_at(copy_x))
	w.velocity = Vector2.ZERO
	var secrets := CampaignStory.secret_count(w)
	CampaignStory.step(w)
	check(w.grounded() and w.discovered.has("story:roots_secret"), "Entering the actual dark floor discovers the maintenance copy without a menu")
	var note := CampaignStory.latest_note(w, "en")
	check(note.contains("sealed later") and CampaignStory.latest_note(w, "tr").contains("sonradan"), "The map shows the actual lower discovery in both languages")
	CampaignStory.step(w)
	check(CampaignStory.secret_count(w) == secrets + 1, "Returning through the lower lane counts this discovery only once")
	var reopened := AionCampaignWorld.new()
	check(reopened.restore(w.snapshot()) and CampaignStory.latest_note(reopened, "en") == note, "The lower copy survives the exact Continue snapshot")

func pump_retry() -> void:
	var w := world_in("fork_one")
	w.player = Vector2(CampaignRoutes.PUMP_X, CampaignRoutes.LOWER_FLOOR)
	check(CampaignRoutes.pump_frame(w, false) == 0 and w.interact() and not CampaignRoutes.pump_open(w), "Inspecting a missing coupler leaves the pump off")
	w.collect({"id": CampaignRoutes.TECHNICIAN_ID + ":supply", "kind": "relay_part"})
	check(CampaignRoutes.pump_frame(w, false) == 1 and w.interact(), "The actual collected coupler primes the pump and the ordinary action starts it")
	check(CampaignRoutes.pump_frame(w, false) == 2 and CampaignRoutes.DRY_CACHE_DECK in w.platforms, "Reduced motion shows a stable running frame plus the real service shelf")
	w.invulnerable = 0.
	w.shield_charge = 0.
	w.damage_player("shot")
	for i in 90: w.step(1. / 60.)
	check(w.attempts_remaining < CampaignLives.ATTEMPTS and CampaignRoutes.pump_open(w), "An actual lost life preserves the opened pump")
	var restored := AionCampaignWorld.new()
	check(restored.restore(w.snapshot()) and CampaignRoutes.pump_frame(restored, false) == 2 and restored.floor_at(CampaignRoutes.DRY_EXIT_X) == CampaignRoutes.DRY_FLOOR, "A Continue preserves the pump animation state and the traversable dry exit")

func run() -> void:
	first_signal()
	lower_copy()
	pump_retry()
	print("RESULT: %d campaign story and route checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
