class_name CampaignHUD
extends Control

## A measured copper-and-lantern strip. Every value comes from the active world.
## 0.33.0: Primary/secondary visual hierarchy + dirty-state caching to avoid
## redundant per-frame font measurements and redraws.
var host
var rows: Array[Array] = []
var strip_height := 46.0
var summary := ""
var font: Font
var point_size := 17
var last_health := -1
var damage_flash := 0.0
var last_clock := 0.0
var last_signature := ""
var items: ForgeItemBank

func avatar_pose() -> Dictionary:
	return host.view.m1_heroes.pose(host.world.character,"idle_fire",0)

func refresh() -> void:
	items=host.hud_items
	font=host.view.font
	point_size=host.font_size(17)
	var w: AionCampaignWorld=host.world
	point_size=maxi(1,point_size)
	var life_rescued:=w.life_rescues()
	var active_weapon: String=host.t(CampaignVehicles.kind(w))+" ∞" if bool(w.mount.ridden) else host.t(w.weapon)+(": %d"%w.ammunition if w.weapon!="pistol" else "")
	if last_health>=0 and w.hp<last_health:damage_flash=.45
	var dt: float=maxf(0.,w.time-last_clock)
	var prev_flash:=damage_flash
	damage_flash=maxf(0.,damage_flash-dt);last_clock=w.time;last_health=w.hp
	var assist_parts: Array[String]=[]
	for assist in w.assists:
		if int(assist.remaining)>0:assist_parts.append(host.t("owl_feather" if assist.kind=="owl" else "wolf_charm")+" ×"+str(assist.remaining))
	var buff_parts: Array[String]=[]
	for key in w.buffs:
		if float(w.buffs[key])>0.:buff_parts.append(host.t(str(key))+" %ds"%ceili(float(w.buffs[key])))
	var sig: String="%s|%d|%d|%d|%d|%s|%d|%d|%d|%d|%s|%s|%.0f|%d|%s"%[
		w.character,w.score,w.attempts_remaining,w.hp,w.grenades,active_weapon,life_rescued,w.flock,
		1 if bool(w.mount.ridden) else 0,int(w.mount.hp),
		",".join(assist_parts),",".join(buff_parts),host.view_w,point_size,host.language]
	if sig==last_signature and damage_flash<=0. and prev_flash<=0. and not rows.is_empty():
		return
	last_signature=sig
	# Hierarchy: immediate combat decisions first (life, weapon/ammo, grenades),
	# followed by mission context (hero, score, keepers, vehicle, assists, buffs).
	var fields: Array[String]=[
		host.t("reserve_lives")+" %d"%maxi(0,w.attempts_remaining-1),
		host.t("weapon")+": "+active_weapon,
		host.t("grenade")+" %d"%w.grenades]
	fields.append(host.old("name_"+w.character))
	fields.append(host.old("score")+" %05d"%w.score)
	fields.append(host.t("life_rescues")+" %d"%life_rescued)
	if bool(w.mount.ridden):fields.append(host.t(CampaignVehicles.kind(w))+" %d/%d"%[int(w.mount.hp),CampaignVehicles.MAX_HP])
	if w.character=="sheep" and w.flock>1:fields.append(host.t("flock_support"))
	for a in assist_parts:fields.append(a)
	for b in buff_parts:fields.append(b)
	rows.clear();rows.append([])
	var available: float=host.view_w-104.
	var used:=48.
	for value in fields:
		var width: float=font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,point_size).x+26.
		if value.begins_with(host.t("weapon")+":"):width+=20.
		if value.begins_with(host.t("life_rescues")+" "):width+=mini(3,life_rescued)*19.
		if used+width>available and not rows[-1].is_empty():rows.append([]);used=12.
		rows[-1].append(value);used+=width
	strip_height=12.+rows.size()*(font.get_height(point_size)+5.)
	size=Vector2(host.view_w,strip_height)
	summary=" · ".join(fields)
	queue_redraw()

func _draw() -> void:
	if host==null or font==null:return
	var colors: Dictionary=host.options.colors
	var w: AionCampaignWorld=host.world
	draw_rect(Rect2(Vector2.ZERO,size),Color(colors.surface))
	draw_line(Vector2(0,size.y-2),Vector2(size.x,size.y-2),Color("a67e56"),2.)
	draw_line(Vector2(0,size.y),Vector2(size.x,size.y),Color(colors.border),2.)
	if damage_flash>0. and not host.options.reduced_motion:draw_rect(Rect2(Vector2.ONE,size-Vector2(2,2)),Color(colors.danger),false,2.)
	var lives_prefix: String=host.t("reserve_lives")+" "
	var weapon_prefix: String=host.t("weapon")+":"
	var grenade_prefix: String=host.t("grenade")+" "
	var primary_color:=Color(colors.text)
	var muted_color:=Color(colors.text);muted_color.a=.82
	var y:=7.+font.get_ascent(point_size)
	for row_index in rows.size():
		var x:=48. if row_index==0 else 12.
		for value in rows[row_index]:
			var s:=str(value)
			var tint: Color=primary_color
			if s.begins_with(lives_prefix):
				if w.attempts_remaining<=1:tint=Color(colors.danger)
			elif s.begins_with(weapon_prefix):
				var icon: Dictionary=host.view.vehicle_pose(CampaignVehicles.kind(w),0,0) if bool(w.mount.ridden) else items.pose(w.weapon)
				if not icon.is_empty():
					var raw: Vector2=icon.texture.get_size()
					var icon_size:=raw*19./maxf(raw.x,raw.y)
					draw_texture_rect(icon.texture,Rect2(Vector2(x-1,y-16)+(Vector2(19,19)-icon_size)*.5,icon_size),false)
				x+=20.
				if not bool(w.mount.ridden) and w.weapon!="pistol" and w.ammunition<=5:tint=Color(colors.danger)
			elif s.begins_with(host.t("life_rescues")+" "):
				for i in mini(3,w.life_rescues()):
					var npc: Dictionary=host.view.catalogue.pose("rescue-npcs",7,3)
					var shape: Vector2=npc.texture.get_size()
					var face:=Rect2(Vector2(shape.x*.15,0.),shape*Vector2(.72,.61))
					draw_texture_rect_region(npc.texture,Rect2(x,y-16.,17.,17.),face)
					x+=19.
			elif not s.begins_with(grenade_prefix):
				tint=muted_color
			draw_string(font,Vector2(x,y),s,HORIZONTAL_ALIGNMENT_LEFT,-1,point_size,tint)
			x+=font.get_string_size(s,HORIZONTAL_ALIGNMENT_LEFT,-1,point_size).x+26.
		y+=font.get_height(point_size)+5.
	var pose: Dictionary=avatar_pose()
	var dimensions: Vector2=pose.get("size",pose.texture.get_size()*float(pose.get("scale",1.)))
	var factor:=minf(36./dimensions.x,36./dimensions.y)
	draw_texture_rect(pose.texture,Rect2(Vector2(5,5)+(Vector2(36,36)-dimensions*factor)*.5,dimensions*factor),false)
