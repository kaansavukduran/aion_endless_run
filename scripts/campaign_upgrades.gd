class_name CampaignUpgrades
extends RefCounted

const OPTIONS := ["insight", "spark", "guard"]
const KEY_PREFIX := "mission:upgrade:"
const RECOVERY_RATE := 1.25

static func selected(w, key: String) -> bool:
	return key in OPTIONS and w.activated.has(KEY_PREFIX+key)

static func choice(w) -> String:
	for key in OPTIONS:
		if selected(w,key):return key
	return ""

static func available(w) -> bool:
	return not w.rescued.is_empty() and choice(w).is_empty()

static func choose(w, key: String) -> bool:
	if w.state!="paused" or key not in OPTIONS or not available(w):return false
	w.activated[KEY_PREFIX+key]=true
	return true

static func recovery_scale(w) -> float:
	return RECOVERY_RATE if selected(w,"spark") else 1.

static func shield_scale(w) -> float:
	return RECOVERY_RATE if selected(w,"guard") else 1.
