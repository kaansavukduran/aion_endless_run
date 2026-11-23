class_name CampaignEncounterSave
extends RefCounted

## Save the live encounter with native value types (surface rects, positions,
## projectile vectors, numeric bridge keys). The surrounding JSON still holds
## the readable campaign index and the legacy migration fields.
const VALUES := [
	"player","velocity","facing","aim_direction","hp","grenades","weapon","ammunition",
	"boss","mount","enemies","bullets","bombs","npcs","objects","pickups","crates","gates",
	"platforms","pits","rooms","zones","hazards","disabled_platforms","platform_timers",
	"bridge_timers","buffs","assists","assist_attacks","chain","chain_time",
	"walk_distance","jumps","air_time","drop_through_time","invulnerable","entry_guard",
	"fire_time","grenade_time","travel_target","recovery_view","entry_to",
	"mount_transition","mount_transition_time","mount_transition_to","mount_transition_from","eject_target_x"
]
const MAX_PAYLOAD := 2_000_000
const PHASES := ["playing","travel","respawn_pending","continue_offer","continue_pick","dead","complete"]

static func write(w,data: Dictionary) -> void:
	var encounter: Dictionary={}
	for key in VALUES:encounter[key]=w.get(key)
	encounter.pickups=w.pickups.filter(func(item):return not w.taken.has(str(item.id)))
	data.ground_revision=CampaignGround.REVISION
	data.phase=str(w.state)
	data.offer_remaining=w.continue_remaining
	data.pending_hero=w.continue_hero
	if w.state in ["dying","respawn"]:
		data.phase="respawn_pending" if w.attempts_remaining>0 else "continue_offer"
		if w.state=="dying" and w.attempts_remaining==0:data.offer_remaining=CampaignLives.OFFER_SECONDS
	if w.state in ["briefing","paused","story"]:data.phase="playing"
	if w.completed:data.phase="complete"
	var bytes:=var_to_bytes(encounter)
	data.encounter=Marshalls.raw_to_base64(bytes)
	data.encounter_sha=data.encounter.sha256_text()

static func valid_number(value: Variant,low: float,high: float) -> bool:
	return typeof(value) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(value)) and float(value)>=low and float(value)<=high

static func read(data: Dictionary) -> Dictionary:
	if not valid_number(data.get("attempts"),0,CampaignLives.ATTEMPTS) or not valid_number(data.get("continues"),0,1000000):return {}
	if not valid_number(data.get("offer_remaining"),0.,CampaignLives.OFFER_SECONDS):return {}
	if not data.get("phase") is String or data.phase not in PHASES:return {}
	if data.get("pending_hero") not in AionCampaignWorld.HEROES:return {}
	var attempts:=int(data.attempts)
	if attempts!=float(data.attempts) or int(data.continues)!=float(data.continues):return {}
	if data.phase in ["continue_offer","continue_pick","dead"]:
		if attempts!=0 or (data.phase=="continue_pick" and float(data.offer_remaining)<=0.):return {}
	elif attempts==0:return {}
	var encoded=data.get("encounter")
	if not encoded is String or encoded.length()>MAX_PAYLOAD or encoded.sha256_text()!=data.get("encounter_sha"):return {}
	var result=bytes_to_var(Marshalls.base64_to_raw(encoded))
	if not result is Dictionary or result.size()!=VALUES.size():return {}
	# All keys are checked before applying any to the active world.
	for key in VALUES:
		if not result.has(key):return {}
	for key in ["player","velocity","aim_direction","entry_to","mount_transition_to","mount_transition_from"]:
		if not result[key] is Vector2 or not result[key].is_finite():return {}
	for key in ["enemies","bullets","bombs","npcs","objects","pickups","crates","gates","platforms","pits","rooms","zones","hazards","assists"]:
		if not result[key] is Array or result[key].size()>4096:return {}
	for key in ["boss","mount","disabled_platforms","platform_timers","bridge_timers","buffs"]:
		if not result[key] is Dictionary:return {}
	if not result.recovery_view is Rect2 or not result.recovery_view.is_finite():return {}
	if not valid_number(result.hp,0,1) or not valid_number(result.grenades,0,9):return {}
	if result.weapon not in CampaignWeapons.SPECS:return {}
	if data.phase=="travel" and not AionCampaignWorld.STAGES.has(str(result.travel_target)):return {}
	return result

static func apply(w,data: Dictionary,encounter: Dictionary) -> void:
	for key in VALUES:
		var target=w.get(key)
		if target is Array:target.assign(encounter[key])
		else:w.set(key,encounter[key])
	w.attempts_remaining=int(data.attempts)
	w.continues_used=int(data.continues)
	w.continue_remaining=float(data.offer_remaining)
	w.continue_hero=str(data.pending_hero)
	w.state=str(data.phase)
	if w.state in ["continue_offer","continue_pick","respawn_pending","dead"]:w.hp=0
	if w.state=="continue_offer" and w.continue_remaining<=0.:w.state="dead"
	w.stop_inputs()
	w.aim_direction=encounter.aim_direction
	w.pending_events.clear()
	if int(data.get("ground_revision",0))<CampaignGround.REVISION:CampaignGround.lift_flat_save(w)
