class_name CampaignHUD
extends Control

## A measured copper-and-lantern strip. Every value comes from the active world.
var host
var rows: Array[Array] = []
var strip_height := 46.0
var summary := ""
var font: Font
var point_size := 17
var last_health := -1
var damage_flash := 0.0
var last_clock := 0.0
var items: ForgeItemBank

func refresh() -> void:
	items=host.hud_items
	font=host.view.font
	point_size=host.font_size(17)
	var w: AionCampaignWorld=host.world
	var active_weapon: String=host.t(CampaignVehicles.kind(w))+" ∞" if bool(w.mount.ridden) else host.t(w.weapon)+(": %d"%w.ammunition if w.weapon!="pistol" else "")
	if last_health>=0 and w.hp<last_health:damage_flash=.45
	damage_flash=maxf(0.,damage_flash-maxf(0.,w.time-last_clock));last_clock=w.time;last_health=w.hp
	var fields: Array[String]=[
		host.old("name_"+w.character),
		host.old("score")+" %05d"%w.score,
		host.t("lives")+" %d/%d"%[w.hp,w.max_hp],
		host.t("grenade")+" %d"%w.grenades,
		host.t("weapon")+": "+active_weapon,
		host.t("keepers")+" %d"%w.rescued.size()]
	if w.shield>0:fields.append(host.t("shield")+" %d"%w.shield)
	if bool(w.mount.ridden):fields.append(host.t(CampaignVehicles.kind(w))+" %d/4"%int(w.mount.hp))
	for key in w.buffs:
		if float(w.buffs[key])>0.:fields.append(host.t(str(key))+" %ds"%ceili(float(w.buffs[key])))
	rows.clear();rows.append([])
	var available: float=host.view_w-104.
	var used:=48.
	for value in fields:
		var width: float=font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,point_size).x+26.
		if value.begins_with(host.t("weapon")+":"):width+=20.
		if used+width>available and not rows[-1].is_empty():rows.append([]);used=12.
		rows[-1].append(value);used+=width
	strip_height=12.+rows.size()*(font.get_height(point_size)+5.)
	size=Vector2(host.view_w,strip_height)
	summary=" · ".join(fields)
	queue_redraw()

func _draw() -> void:
	if host==null or font==null:return
	var colors: Dictionary=host.options.colors
	draw_rect(Rect2(Vector2.ZERO,size),Color(colors.surface))
	draw_line(Vector2(0,size.y-2),Vector2(size.x,size.y-2),Color("a67e56"),2.)
	draw_line(Vector2(0,size.y),Vector2(size.x,size.y),Color(colors.border),2.)
	if damage_flash>0. and not host.options.reduced_motion:draw_rect(Rect2(Vector2.ONE,size-Vector2(2,2)),Color(colors.danger),false,2.)
	var y:=7.+font.get_ascent(point_size)
	for row_index in rows.size():
		var x:=48. if row_index==0 else 12.
		for value in rows[row_index]:
			if str(value).begins_with(host.t("weapon")+":"):
				var icon: Dictionary=host.view.vehicle_pose(CampaignVehicles.kind(host.world),0,0) if bool(host.world.mount.ridden) else items.pose(host.world.weapon)
				if not icon.is_empty():
					var raw: Vector2=icon.texture.get_size()
					var icon_size:=raw*19./maxf(raw.x,raw.y)
					draw_texture_rect(icon.texture,Rect2(Vector2(x-1,y-16)+(Vector2(19,19)-icon_size)*.5,icon_size),false)
				x+=20.
			draw_string(font,Vector2(x,y),value,HORIZONTAL_ALIGNMENT_LEFT,-1,point_size,Color(colors.text))
			x+=font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,point_size).x+26.
		y+=font.get_height(point_size)+5.
	var pose: Dictionary=host.view.frames.pose("gun-run",host.view.frames.hero_row(host.world.character),0)
	var dimensions: Vector2=pose.get("size",pose.texture.get_size()*float(pose.get("scale",1.)))
	var factor:=minf(36./dimensions.x,36./dimensions.y)
	draw_texture_rect(pose.texture,Rect2(Vector2(5,5)+(Vector2(36,36)-dimensions*factor)*.5,dimensions*factor),false)
