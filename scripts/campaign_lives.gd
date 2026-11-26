class_name CampaignLives
extends RefCounted

const ATTEMPTS := 3
const EMPTY_RESPAWN_ROUNDS := 6
const OFFER_SECONDS := 10.
const ENTRY_SECONDS := .62
const ENTRY_PROTECTION := 3.
const SHIELD_CHARGE_SECONDS := 4.
const SHIELD_RECOVERY := .45
const CROW_DIVE_CLEARANCE := 150.
const TRANSITIONS := ["dying","respawn_pending","respawn","continue_offer","dead"]

static func reset(w) -> void:
	w.attempts_remaining=ATTEMPTS
	w.continues_used=0
	w.continue_remaining=0.
	w.continue_hero=w.character
	w.entry_clock=0.
	w.entry_guard=false
	w.shield_charge=0.
	w.recovery_view=Rect2()

static func lethal(w,cause: String) -> void:
	var depleted: bool=int(w.ammunition)==0 and CampaignWeapons.sidearm_stock(w)==0
	w.hp=0
	w.attempts_remaining=maxi(0,w.attempts_remaining-1)
	w.losses+=1
	w.score=0
	w.rescue_life_start=w.rescued.size()
	w.chain=0;w.chain_time=0.;w.score_popups.clear()
	w.retry_count+=1
	w.death_cause=cause
	w.death_time=0.
	w.entry_guard=false
	w.shield_charge=0.
	w.state="dying"
	CampaignWeapons.switch_to_sidearm(w)
	if depleted and w.attempts_remaining>0:w.ammunition=EMPTY_RESPAWN_ROUNDS
	w.buffs.clear()
	w.assists.clear()
	w.melee_hit_done=true
	w.melee_time=0.
	w.shot_flash=0.
	w.rescue_time=0.
	w.rescue_target=""
	w.stop_inputs()
	w.pending_events.append("life_changed")

static func step_protection(w,dt: float) -> void:
	var protected_time:=minf(float(w.invulnerable),dt)
	w.invulnerable=maxf(0.,float(w.invulnerable)-dt)
	if is_zero_approx(float(w.invulnerable)):
		w.invulnerable=0.
		w.entry_guard=false
		w.shield_charge=minf(SHIELD_CHARGE_SECONDS,float(w.shield_charge)+(dt-protected_time)*CampaignUpgrades.shield_scale(w))

static func absorb_hit(w) -> bool:
	if not w.shield_ready():return false
	w.shield_charge=0.
	w.invulnerable=SHIELD_RECOVERY
	w.pending_events.append("shield_hit")
	return true

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
		w.continue_hero=w.character
		w.state="continue_offer"
	w.pending_events.append("life_changed")

static func tick_offer(w,dt: float) -> void:
	if w.state!="continue_offer":return
	w.continue_remaining=maxf(0.,w.continue_remaining-maxf(0.,dt))
	if w.continue_remaining<=0.:
		w.state="dead"
		w.pending_events.append("life_changed")

static func confirm(w,hero: String) -> bool:
	if w.state!="continue_offer" or w.continue_remaining<=0. or hero not in w.HEROES:return false
	if w.character!=hero:MissionHeroAbilities.reset(w)
	w.character=hero
	w.continue_hero=hero
	w.continues_used+=1
	w.attempts_remaining=ATTEMPTS
	w.continue_remaining=0.
	w.grenades=5
	w.weapon="pistol";w.ammunition=CampaignWeapons.PISTOL_START;w.pistol_reserve=0
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

static func crow_danger(w,foot: Vector2) -> bool:
	if CampaignRoutes.crow_sheltered(w,foot):return false
	var center:=foot-Vector2(0.,30.)
	for e in w.enemies:
		if str(e.kind)!="crow" or bool(e.defeated):continue
		var bird:=Vector2(float(e.x),float(e.y))
		if float(e.get("dive",0.))>0.:
			var target:=Vector2(e.get("dive_target",bird))
			var escape:=Vector2(target.x-65.,float(e.home.y))
			var nearest:=Geometry2D.get_closest_point_to_segment(center,bird,target)
			var following:=Geometry2D.get_closest_point_to_segment(center,target,escape)
			if minf(center.distance_to(nearest),center.distance_to(following))<CROW_DIVE_CLEARANCE:return true
		elif absf(bird.x-foot.x)<(260. if float(e.windup)>0. else 175.) and absf(bird.y-foot.y)<270.:
			return true
	return false

static func landing(w,area: Rect2) -> Vector2:
	var left:=maxf(55.,area.position.x+62.)
	var right:=minf(float(w.length())-105.,area.end.x-42.)
	var top:=area.position.y+88.
	var best:=Vector2.INF
	var cost:=INF
	var exposed:=Vector2.INF
	var exposed_cost:=INF
	# Prefer a clear left pocket, with a penalty for nearby live threats.
	for x in range(ceili(left),floori(right)+1,28):
		var y: float=CampaignVehicles.support_below(w,float(x),top)
		if not CampaignGround.has_floor(y) or y<top or not landing_clear(w,Vector2(x,y)):continue
		var risk:=0.
		for e in w.enemies:
			if not bool(e.defeated) and absf(float(e.y)-y)<100.:
				risk+=maxf(0.,120.-absf(float(e.x)-x))*8.
		if crow_danger(w,Vector2(x,y)):
			if x-left+risk<exposed_cost:
				exposed_cost=x-left+risk
				exposed=Vector2(x,y)
			continue
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
			var point:=Vector2(x,y)
			if not CampaignGround.has_floor(y) or not landing_clear(w,point):continue
			if not crow_danger(w,point):return point
			if not exposed.is_finite():exposed=point
	if exposed.is_finite():return exposed
	# Each authored section provides supported floor; keep that guarantee
	# explicit so adding an all-hazard layout fails validation visibly.
	push_error("Mission 1 has no safe re-entry surface in "+w.section)
	return Vector2(140.,w.floor_at(140.))

static func landing_clear(w,foot: Vector2) -> bool:
	if bool(w.boss.active) and absf(float(w.boss.x)-foot.x)<145.:return false
	var front:=maxf(w.player.x,foot.x)
	var back:=minf(w.player.x,foot.x)
	if w.gates.any(func(g):return w.gate_closed(g) and (absf(float(g.x)-foot.x)<52. or (float(g.x)>back and float(g.x)<front))):return false
	if w.objects.any(func(o):return str(o.kind)=="gate" and not bool(o.active) and (absf(float(o.x)-foot.x)<62. or (float(o.x)>back and float(o.x)<front))):return false
	if w.hazards.any(func(h):return absf(float(h.x)-foot.x)<60. and foot.y>-90.):return false
	for offset in [-22.,0.,22.]:
		if CampaignRoutes.solid_at(w,foot+Vector2(offset,-56.)):return false
		if absf(CampaignVehicles.support_below(w,foot.x+offset,foot.y-2.)-foot.y)>3.:return false
	return true

static func start_entry(w,area: Rect2) -> void:
	if w.state!="respawn_pending":return
	if w.section=="arena" and bool(w.boss.engaged):
		# After several losses, the follow camera can drift left out of the
		# fight. Keep the entry on the left side of the active boss encounter.
		var approach:=clampf(float(w.boss.x)-area.size.x*.75,0.,maxf(0.,float(w.length())-area.size.x))
		area.position.x=maxf(area.position.x,approach)
	w.entry_to=landing(w,area)
	if w.entry_to.x<area.position.x+45. or w.entry_to.x>area.end.x-42.:
		area.position.x=clampf(w.entry_to.x-110.,0.,maxf(0.,float(w.length())-area.size.x))
	w.recovery_view=area
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
		w.hurt_time=0.
		w.jumps=0
		w.air_time=0.
		w.trail.clear()
		w.invulnerable=ENTRY_PROTECTION
		w.entry_guard=true
		w.state="playing"
		w.pending_events.append("life_changed")
