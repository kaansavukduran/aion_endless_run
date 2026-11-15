class_name RunnerHeroPreview
extends Control
var hero := "aion"
var clock := 0.
var animate := true
var action := "ability"
var frames := RunnerFrameBank.new()
var body_art := preload("res://scripts/m1_hero_art.gd").new()
var weapon_art := ForgeItemBank.new()
const GunArt=preload("res://scripts/m1_combat_art.gd")
var catalogue := CampaignCatalog.new()
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
func _process(dt: float) -> void:
	if not is_visible_in_tree() or not animate:return
	clock+=minf(dt,.05)
	queue_redraw()
func _draw() -> void:
	var row:=0
	var phase:=fmod(clock,3.)
	if animate and phase>1.:
		row=2 if hero=="aion" else (6 if hero in ["wolf","owl","rabbit","eren"] else 1)
	var key: String="runner-"+hero
	if action=="move":row=1
	elif action=="jump":row=2
	elif action=="shoot":key="gun-fire";row=frames.hero_row(hero)
	elif action=="armed_walk":key="gun-run";row=frames.hero_row(hero)
	var pose: Dictionary
	if body_art.has(hero):
		var body_action: String="walk" if action in ["move","armed_walk"] else ("air_fire" if action=="jump" or (action=="ability" and phase>1.) else "idle_fire")
		pose=body_art.pose(hero,body_action,posmod(int(clock*7.),6) if animate else 0)
	else:
		var frame: int=frames.cycle(key,row,clock,.85) if animate else 0
		pose=catalogue.pose("rescue-heroes",frames.hero_row(hero),posmod(int(clock*6.),6) if animate else 3) if action=="rescue" else frames.pose(key,row,frame)
	var factor: float=float(pose.get("scale",1.))
	var dimensions: Vector2=pose.get("size",pose.texture.get_size()*factor)
	var fit: float=minf(1.25,minf(size.x/150.,size.y/110.))
	var anchor:=Vector2(size.x*.5,size.y-6.).round()
	draw_set_transform(anchor,0,Vector2.ONE*fit)
	draw_texture_rect(pose.texture,Rect2((Vector2(pose.offset)*factor).round(),dimensions),false)
	if bool(pose.get("body_only",false)):
		var socket: Dictionary=GunArt.weapon_metrics("pistol")
		if action=="rescue":
			# Same short cutting blade and registered hand as the live action.
			draw_rect(Rect2(Vector2(pose.grip_local)+Vector2(-3,-2),Vector2(6,5)),Color("87583f"))
			var blade:=PackedVector2Array([Vector2(1,-2),Vector2(20,-2),Vector2(24,0),Vector2(1,2)])
			for i in blade.size():blade[i]+=Vector2(pose.grip_local)
			draw_polygon(blade,PackedColorArray([Color("d7e9e8")]))
		else:
			var gun: Dictionary=weapon_art.pose("pistol")
			draw_texture_rect(GunArt.weapon_texture(weapon_art,"pistol"),Rect2(Vector2(pose.grip_local)+Vector2(socket.offset),Vector2(socket.size)),false)
		if action=="shoot" and animate and posmod(int(clock*7.),6) in [2,3]:
			var muzzle: Vector2=Vector2(pose.grip_local)+Vector2(socket.muzzle)
			draw_line(muzzle,muzzle+Vector2(5,0),Color("ffcf8c"),2.)
	draw_set_transform(Vector2.ZERO)
