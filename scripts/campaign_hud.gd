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
var point_size := 18
var last_health := -1
var damage_flash := 0.0
var last_clock := 0.0
var last_signature: Array = []
var shield_fill := 0
var items: ForgeItemBank

func avatar_pose() -> Dictionary:
	return host.view.m1_heroes.pose(host.world.character,"idle_fire",0)

func refresh() -> void:
	items=host.hud_items
	font=host.view.font
	point_size=host.font_size(18)
	var w: AionCampaignWorld=host.world
	point_size=maxi(1,point_size)
	var life_rescued:=w.life_rescues()
	if last_health>=0 and w.hp<last_health:damage_flash=.45
	var dt: float=maxf(0.,w.time-last_clock)
	var prev_flash:=damage_flash
	damage_flash=maxf(0.,damage_flash-dt);last_clock=w.time;last_health=w.hp
	shield_fill=4 if w.shield_ready() else mini(3,floori(w.shield_charge*4./CampaignLives.SHIELD_CHARGE_SECONDS))
	var ridden: bool=bool(w.mount.ridden)
	var vehicle: String=CampaignVehicles.kind(w) if ridden else ""
	var sig: Array=[w.character,w.score,w.attempts_remaining,w.hp,w.grenades,w.weapon,w.ammunition,
		life_rescued,vehicle,int(w.mount.hp),host.view_w,point_size,host.language,shield_fill,font]
	if sig==last_signature and damage_flash<=0. and prev_flash<=0. and not rows.is_empty():
		return
	last_signature=sig
	var active_weapon:=CampaignFieldUI.equipped_weapon(host)
	var life:=CampaignFieldUI.text(host,"life")+" %d/%d"%[w.hp,w.max_hp]
	var reserves:=maxi(0,w.attempts_remaining-1)
	var spare:=CampaignFieldUI.text(host,"reserve")+" %d"%reserves
	var grenades: String=host.t("grenade")+" %d"%w.grenades
	var score: String=host.old("score")+" %05d"%w.score
	var rescue: String=host.t("keepers")+" %d"%life_rescued
	var fields: Array=[
		["life",life],["reserve",spare],["weapon",active_weapon],["grenade",grenades],
		["score",score],["rescues",rescue]]
	if ridden:
		fields.append(["vehicle","%s %d/%d"%[host.t(vehicle),int(w.mount.hp),CampaignVehicles.MAX_HP]])
	var weapon_icon: Dictionary=host.view.vehicle_pose(vehicle,0,0) if ridden else (items.pose(w.weapon) if w.ammunition>0 else {})
	rows.clear();rows.append([])
	var available: float=host.view_w-80.
	var used:=48.
	for field in fields:
		var icon: Dictionary=weapon_icon if field[0]=="weapon" else {}
		var value: String=field[1]
		var width: float=font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,point_size).x+17.
		if not icon.is_empty():width+=20.
		var portraits:=mini(3,life_rescued) if field[0]=="rescues" and point_size<=26 else 0
		width+=portraits*19.
		if used+width>available and not rows[-1].is_empty():rows.append([]);used=12.
		rows[-1].append({"kind":field[0],"text":value,"advance":width,"icon":icon,"portraits":portraits});used+=width
	strip_height=12.+rows.size()*(font.get_height(point_size)+5.)
	size=Vector2(host.view_w,strip_height)
	summary=" · ".join([life,host.t("reserve_lives")+" %d"%reserves,host.t("weapon")+" · "+active_weapon,
		grenades,score,host.t("life_rescues")+" %d"%life_rescued])
	if w.hp>0:summary+=" · "+host.t("shield_ready" if shield_fill==4 else "shield_charging")
	queue_redraw()

func _draw() -> void:
	if host==null or font==null:return
	var colors: Dictionary=host.options.colors
	var w: AionCampaignWorld=host.world
	draw_rect(Rect2(Vector2.ZERO,size),Color(colors.surface))
	draw_line(Vector2(0,size.y-2),Vector2(size.x,size.y-2),Color("a67e56"),2.)
	draw_line(Vector2(0,size.y),Vector2(size.x,size.y),Color(colors.border),2.)
	if damage_flash>0. and not host.options.reduced_motion:draw_rect(Rect2(Vector2.ONE,size-Vector2(2,2)),Color(colors.danger),false,2.)
	var primary_color:=Color(colors.text)
	var muted_color:=Color(colors.text);muted_color.a=.82
	var y:=7.+font.get_ascent(point_size)
	for row_index in rows.size():
		var x:=48. if row_index==0 else 12.
		for field in rows[row_index]:
			var tint: Color=primary_color
			if (field.kind=="life" and w.hp<=0) or (field.kind=="reserve" and w.attempts_remaining<=1):
				tint=Color(colors.danger)
			elif field.kind=="weapon" and not bool(w.mount.ridden) and w.ammunition<=5:
				tint=Color(colors.danger)
			elif field.kind=="grenade" and w.grenades<=0:
				tint=muted_color
			elif field.kind in ["score","rescues","vehicle"]:
				tint=muted_color
			var icon: Dictionary=field.icon
			var text_x:=x
			if not icon.is_empty():
				var raw: Vector2=icon.texture.get_size()
				var icon_size:=raw*19./maxf(raw.x,raw.y)
				draw_texture_rect(icon.texture,Rect2(Vector2(x-1,y-16)+(Vector2(19,19)-icon_size)*.5,icon_size),false)
				text_x+=20.
			if int(field.portraits)>0:
				var npc: Dictionary=host.view.catalogue.pose("rescue-npcs",7,3)
				var shape: Vector2=npc.texture.get_size()
				var face:=Rect2(Vector2(shape.x*.15,0.),shape*Vector2(.72,.61))
				for index in int(field.portraits):
					draw_texture_rect_region(npc.texture,Rect2(text_x,y-16.,17.,17.),face)
					text_x+=19.
			draw_string(font,Vector2(text_x,y),field.text,HORIZONTAL_ALIGNMENT_LEFT,-1,point_size,tint)
			x+=float(field.advance)
		y+=font.get_height(point_size)+5.
	var pose: Dictionary=avatar_pose()
	var dimensions: Vector2=pose.get("size",pose.texture.get_size()*float(pose.get("scale",1.)))
	var factor:=minf(36./dimensions.x,36./dimensions.y)
	draw_texture_rect(pose.texture,Rect2(Vector2(5,5)+(Vector2(36,36)-dimensions*factor)*.5,dimensions*factor),false)
	if w.hp>0:draw_shield(colors)

func draw_shield(colors: Dictionary) -> void:
	var origin:=Vector2(33.,29.)
	var surface:=Color(colors.surface)
	var rim:=Color(colors.text);rim.a=.75
	var fill:=Color(colors.text) if shield_fill==4 else rim
	draw_rect(Rect2(origin-Vector2.ONE,Vector2(14.,14.)),surface)
	for row in 12:
		var inset:=maxi(0,row-6)
		draw_rect(Rect2(origin+Vector2(inset,row),Vector2(12-2*inset,1)),rim)
	for row in range(1,10):
		var inset:=maxi(1,row-5)
		var charge:=row>=10-shield_fill*3
		draw_rect(Rect2(origin+Vector2(inset,row),Vector2(12-2*inset,1)),fill if charge else surface)
