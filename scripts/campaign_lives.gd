class_name CampaignLives
extends RefCounted

const ATTEMPTS := 3
const OFFER_SECONDS := 10.
const ENTRY_SECONDS := .62
const ENTRY_PROTECTION := 1.25
const TRANSITIONS := ["dying","respawn_pending","respawn","continue_offer","continue_pick","dead"]

static func reset(w) -> void:
	w.attempts_remaining=ATTEMPTS
	w.continues_used=0
	w.continue_remaining=0.
	w.continue_hero=w.character
	w.entry_clock=0.
	w.entry_guard=false
	w.recovery_view=Rect2()

static func lethal(w,cause: String) -> void:
	w.hp=0
	w.attempts_remaining=maxi(0,w.attempts_remaining-1)
	w.losses+=1
	w.retry_count+=1
	w.death_cause=cause
	w.death_time=0.
	w.entry_guard=false
	w.state="dying"
	w.weapon="pistol"
	w.ammunition=0
	w.buffs.clear()
	w.assists.clear()
	w.melee_hit_done=true
	w.melee_time=0.
	w.shot_flash=0.
	w.rescue_time=0.
	w.rescue_target=""
	w.stop_inputs()
	w.pending_events.append("life_changed")

static func impact_duration(cause: String) -> float:
	match cause:
		"pit":return 0.
		"shot":return .08
		"beam","hazard","explosion":return .18
		_:return .13

static func collapse_frame(w) -> int:
	if w.state!="dying":return 5
	var impact:=impact_duration(w.death_cause)
	return clampi(int((w.death_time-impact)/(.8-impact)*6.),0,5)

static func finish_death(w) -> void:
	if w.attempts_remaining>0:
		w.state="respawn_pending"
	else:
		w.continue_remaining=OFFER_SECONDS
		w.state="continue_offer"
	w.pending_events.append("life_changed")

static func tick_offer(w,dt: float) -> void:
	if w.state!="continue_offer":return
	# Zero is visible for one frame and cannot be confirmed.
	if w.continue_remaining<=0.:
		w.state="dead"
		w.pending_events.append("life_changed")
	else:
		w.continue_remaining=maxf(0.,w.continue_remaining-maxf(0.,dt))

static func open_picker(w) -> bool:
	if w.state!="continue_offer" or w.continue_remaining<=0.:return false
	w.continue_hero=w.character
	w.state="continue_pick"
	w.pending_events.append("life_changed")
	return true

static func cancel_picker(w) -> bool:
	if w.state!="continue_pick":return false
	w.state="continue_offer"
	w.pending_events.append("life_changed")
	return true

static func confirm(w,hero: String) -> bool:
	if w.state!="continue_pick" or hero not in w.HEROES:return false
	w.character=hero
	w.continue_hero=hero
	w.continues_used+=1
	w.attempts_remaining=ATTEMPTS
	w.continue_remaining=0.
	w.grenades=5
	w.flock=1
	w.state="respawn_pending"
	w.pending_events.append("life_changed")
	return true

static func follower_sample(w,index: int) -> Dictionary:
	var sample: Dictionary={"p":w.player-Vector2((index+1)*52,0),"facing":w.facing,"grounded":w.grounded(),"crouched":w.crouching(),"walk_distance":w.walk_distance,"moving":absf(w.velocity.x)>1.,"velocity_y":w.velocity.y,"air_time":w.air_time}
	for old in w.trail:
		if float(old.time)<=w.time-float(index+1)*.27:sample=old
	return sample

static func follower_position(w,index: int) -> Vector2:
	return Vector2(follower_sample(w,index).p)

static func landing(w,area: Rect2) -> Vector2:
	var left:=maxf(55.,area.position.x+62.)
	var right:=minf(float(w.length())-105.,area.end.x-42.)
	var top:=area.position.y+88.
	var best:=Vector2.INF
	var cost:=INF
	# Prefer a clear left pocket, with a penalty for nearby live threats.
	for x in range(ceili(left),floori(right)+1,28):
		var y: float=CampaignVehicles.support_below(w,float(x),top)
		if not CampaignGround.has_floor(y) or y<top or not landing_clear(w,Vector2(x,y)):continue
		var risk:=0.
		for e in w.enemies:
			if not bool(e.defeated) and absf(float(e.y)-y)<100.:
				risk+=maxf(0.,120.-absf(float(e.x)-x))*8.
		if x-left+risk<cost:
			cost=x-left+risk
			best=Vector2(x,y)
	if best.is_finite():return best
	# Junction ledges and pits can leave a narrow view without a full-height
	# landing. Keep the approach at the nearest clear side of this encounter.
	var center:=clampf(w.player.x,55.,w.length()-105.)
	for distance in range(0,ceili(w.length()),28):
		for direction in [-1.,1.]:
			var x: float=center+direction*distance
			if x<55. or x>w.length()-105.:continue
			var y: float=CampaignVehicles.support_below(w,x,minf(top,-270.))
			if CampaignGround.has_floor(y) and landing_clear(w,Vector2(x,y)):return Vector2(x,y)
	# Each authored section provides supported floor; keep that guarantee
	# explicit so adding an all-hazard layout fails validation visibly.
	push_error("Mission 1 has no safe re-entry surface in "+w.section)
	return Vector2(140.,w.floor_at(140.))

static func landing_clear(w,foot: Vector2) -> bool:
	if bool(w.boss.active) and absf(float(w.boss.x)-foot.x)<145.:return false
	if w.gates.any(func(g):return absf(float(g.x)-foot.x)<52. and w.gate_closed(g)):return false
	if w.objects.any(func(o):return str(o.kind)=="gate" and not bool(o.active) and absf(float(o.x)-foot.x)<62.):return false
	if w.hazards.any(func(h):return absf(float(h.x)-foot.x)<60. and foot.y>-90.):return false
	for offset in [-22.,0.,22.]:
		if CampaignRoutes.solid_at(w,foot+Vector2(offset,-56.)):return false
		if absf(CampaignVehicles.support_below(w,foot.x+offset,foot.y-2.)-foot.y)>3.:return false
	return true

static func start_entry(w,area: Rect2) -> void:
	if w.state!="respawn_pending":return
	w.recovery_view=area
	w.entry_to=landing(w,area)
	w.entry_from=Vector2(area.position.x+36.,area.position.y+60.)
	w.player=w.entry_from
	w.velocity=Vector2.ZERO
	w.entry_clock=0.
	w.bullets=w.bullets.filter(func(b):
		return b.owner!="enemy" or Vector2(b.p).distance_to(w.entry_to+Vector2(0,-35))>168.)
	if float(w.boss.get("beam_warning",0.))>0. and absf(float(w.boss.get("beam_x",-999.))-w.entry_to.x)<60.:
		w.boss.beam_warning=0.
	w.state="respawn"
	w.pending_events.append("life_changed")

static func step_entry(w,dt: float) -> void:
	w.entry_clock=minf(ENTRY_SECONDS,w.entry_clock+dt)
	var progress: float=w.entry_clock/ENTRY_SECONDS
	var previous: Vector2=w.player
	w.player=Vector2(lerpf(w.entry_from.x,w.entry_to.x,smoothstep(0.,1.,progress)),
		lerpf(w.entry_from.y,w.entry_to.y,pow(maxf(0.,(progress-.19)/.81),2.2)))
	w.velocity=(w.player-previous)/maxf(dt,.001)
	if progress>=1.:
		w.player=w.entry_to
		w.velocity=Vector2.ZERO
		w.hp=1
		w.jumps=0
		w.air_time=0.
		w.trail.clear()
		w.invulnerable=ENTRY_PROTECTION
		w.entry_guard=true
		w.state="playing"
		w.pending_events.append("life_changed")
