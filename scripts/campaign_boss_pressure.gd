class_name CampaignBossPressure
extends RefCounted

## The same root-machine artwork now supports optional destructible ports,
## the existing charge/recovery core window and a readable final dash.
## Phase language: 1 teaches that the core opens after a ground slam; 2 adds a
## breakable root arm whose second slam wave stops once the arm is broken; 3 is
## a short dash/fan climax. Each new phase starts with a visible stagger that
## clears the air and announces what changed.
const STAGGER := 1.2
const CORE_OPEN := 1.1
const ARM_HP := 8
const ARM_OFFSET := Vector2(-120.,-40.)
static func phase_change(w) -> bool:
	var boss: Dictionary=w.boss
	var seen: int=int(boss.get("phase_seen",1))
	if int(boss.phase)<=seen:return false
	boss.phase_seen=int(boss.phase);boss.stagger=STAGGER;boss.windup=0.;boss.wait=maxf(float(boss.wait),STAGGER)
	boss.dash=0.;boss.beam_warning=0.
	if int(boss.phase)==2 and not boss.has("arm"):boss.arm=ARM_HP
	w.bullets=w.bullets.filter(func(b):return b.owner!="enemy")
	for e in w.enemies:
		if str(e.kind)=="drone" and not bool(e.defeated):e.defeated=true
	w.notice="arc_boss_phase_"+str(boss.phase);w.notice_time=2.2;w.pending_events.append("guardian")
	return true

static func after_slam(w) -> void:
	var boss: Dictionary=w.boss
	if int(boss.phase)==1:boss.core_open=CORE_OPEN
	elif int(boss.phase)==2 and int(boss.get("arm",0))>0:
		# The living root arm sends a second, later wave: two jumps, never a wall.
		w.bullets.append({"p":Vector2(float(boss.x)+90.,-16.),"v":Vector2(-320.,0.),"owner":"enemy","age":0.,"kind":"wave","damage":1,"pierce":0,"hit":[]})

static func clear_hazards(w) -> void:
	w.bullets=w.bullets.filter(func(b):return b.owner!="enemy")
	w.boss.dash=0.;w.boss.beam_warning=0.;w.boss.windup=0.
	for e in w.enemies:
		if str(e.kind)=="drone" and not bool(e.defeated):e.defeated=true

static func arm_point(w) -> Vector2:
	return Vector2(float(w.boss.x),0.)+ARM_OFFSET

static func hit(w,bullet: Dictionary,from: Vector2,to: Vector2) -> bool:
	var boss: Dictionary=w.boss
	if int(boss.phase)==2 and int(boss.get("arm",0))>0:
		var arm:=arm_point(w)
		if Geometry2D.get_closest_point_to_segment(arm,from,to).distance_to(arm)<=28.:
			boss.arm=maxi(0,int(boss.arm)-int(bullet.damage));w.damage_boss(int(bullet.damage))
			w.pending_events.append("armour_hit")
			if int(boss.arm)==0:w.award("boss:arm",200);w.pending_events.append("enemy");w.notice="arc_boss_arm_broken";w.notice_time=2.
			return true
	if int(boss.phase)==1:
		if not boss.has("ports"):boss.ports=[3,3]
		for i in 2:
			if int(boss.ports[i])<=0:continue
			var target:=Vector2(float(boss.x)+(-65. if i==0 else 65.),-95.)
			if Geometry2D.get_closest_point_to_segment(target,from,to).distance_to(target)>25.:continue
			boss.ports[i]=maxi(0,int(boss.ports[i])-int(bullet.damage));w.damage_boss(int(bullet.damage)*2)
			w.pending_events.append("armour_hit")
			if int(boss.ports[i])==0:w.award("boss:port:"+str(i),150);w.pending_events.append("enemy")
			return true
	return false

static func motion(w,dt: float) -> bool:
	if float(w.boss.get("dash",0.))<=0.:return false
	w.boss.dash=maxf(0.,float(w.boss.dash)-dt)
	w.boss.x=clampf(float(w.boss.x)+float(w.boss.get("dash_direction",-1.))*420.*dt,1800.,w.length()-170.)
	if absf(w.player.x-float(w.boss.x))<95. and w.player.y> -80.:w.damage_player("impact")
	return true

static func core_damage(w,bullet: Dictionary,from: Vector2,to: Vector2) -> int:
	var damage: int=int(bullet.damage)
	if float(w.boss.get("core_open",0.))>0. or (int(w.boss.phase)==2 and w.boss_vulnerable()):
		var core:=Vector2(float(w.boss.x),-75.)
		if Geometry2D.get_closest_point_to_segment(core,from,to).distance_to(core)<30.:return damage*2
	return damage

static func attack(w) -> bool:
	if int(w.boss.phase)!=3 or int(w.boss.attack)%3!=2:return false
	w.boss.dash=.95;w.boss.dash_direction=-1. if w.player.x<float(w.boss.x) else 1.
	return true
