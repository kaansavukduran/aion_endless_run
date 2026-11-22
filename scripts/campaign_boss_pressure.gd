class_name CampaignBossPressure
extends RefCounted

## The same root-machine artwork supports optional destructible ports,
## the charge/recovery core window, clean phase shifts and a readable final dash.
## 0.32.0: Added phase-transition pause/cleanup and post-dash recovery punish window.
static func on_phase_change(w,old_phase: int,new_phase: int) -> void:
	if new_phase<=old_phase:return
	w.boss.beam_warning=0.
	w.boss.windup=0.
	w.boss.dash=0.
	w.boss.recover=0.
	w.boss.shift_pause=0.75
	w.boss.wait=maxf(float(w.boss.wait),0.95)
	w.pending_events.append("mechanism")
	w.blasts.append({"p":Vector2(float(w.boss.x),-85.),"age":0.,"radius":95.,"color":"ffcf8c"})

static func hit(w,bullet: Dictionary,from: Vector2,to: Vector2) -> bool:
	var boss: Dictionary=w.boss
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
	if float(w.boss.get("shift_pause",0.))>0.:
		w.boss.shift_pause=maxf(0.,float(w.boss.shift_pause)-dt)
		return true
	if float(w.boss.get("recover",0.))>0.:
		w.boss.recover=maxf(0.,float(w.boss.recover)-dt)
		return true
	if float(w.boss.get("dash",0.))<=0.:return false
	var active_dt: float=minf(dt,float(w.boss.dash))
	w.boss.dash=maxf(0.,float(w.boss.dash)-dt)
	w.boss.x=clampf(float(w.boss.x)+float(w.boss.get("dash_direction",-1.))*420.*active_dt,1800.,w.length()-170.)
	if absf(w.player.x-float(w.boss.x))<95. and w.player.y> -80.:w.damage_player("impact")
	if float(w.boss.dash)<=0.:
		# Clear punish window after the final-phase charge so basic pistol finishes cleanly.
		w.boss.recover=maxf(0.,0.65-(dt-active_dt))
		w.boss.wait=maxf(float(w.boss.wait),1.15)
	return true

static func core_damage(w,bullet: Dictionary,from: Vector2,to: Vector2) -> int:
	var damage: int=int(bullet.damage)
	if int(w.boss.phase)==2 and w.boss_vulnerable():
		var core:=Vector2(float(w.boss.x),-75.)
		if Geometry2D.get_closest_point_to_segment(core,from,to).distance_to(core)<30.:return damage*2
	return damage

static func attack(w) -> bool:
	if int(w.boss.phase)!=3 or int(w.boss.attack)%3!=2:return false
	# World may have scheduled a beam on this odd-numbered pattern. A dash
	# owns its telegraph and active window; do not freeze a second warning
	# throughout the charge and then release it during the punish interval.
	w.boss.beam_warning=0.
	w.boss.dash=.95;w.boss.dash_direction=-1. if w.player.x<float(w.boss.x) else 1.
	return true
