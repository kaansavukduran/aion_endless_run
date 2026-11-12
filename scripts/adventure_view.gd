extends Node2D

const META = preload("res://assets/ADVENTURE-PROVENANCE.json")
const ENEMIES = preload("res://assets/adventure-enemies.png")
const ITEMS = preload("res://assets/adventure-items.png")
const EVOLUTION = preload("res://assets/EVOLUTION-PROVENANCE.json")

const FRAGARIA = preload("res://assets/fragaria-strawberry.png")
const PixelArt = preload("res://scripts/encounter_art.gd")
var host

func atlas(name: String, row: int, frame: int, anchor: Vector2, width: float, centered: bool = false) -> void:
	var f: Dictionary = host.frames.pose(name,row,frame)
	var tex: Texture2D = f.texture
	var factor: float = width/f.cell_width
	var offset: Vector2 = f.offset
	if centered: offset.y = f.top-f.cell_height*0.5-2
	draw_texture_rect(tex,Rect2((anchor+offset*factor).round(),tex.get_size()*factor),false)

func creature(enemy: Dictionary, ground: float) -> void:
	var row: int = ["bat","slime","beetle","wisp"].find(enemy.kind)
	var seconds: float = [.70,PI/2.8,.65,.85][row]
	var clock: float = maxf(0,float(enemy.age)-float(enemy.defeat)) if host.motion else 0.0
	var frame: int = host.frames.cycle("creatures",row,clock,seconds)
	var f: Dictionary = host.frames.pose("creatures",row,frame)
	var factor: float = f.scale
	var anchor := Vector2(enemy.x,ground+enemy.y+(15.0 if row==1 else (23.0 if row==2 else 0.0)))
	var fade := 1.0
	if enemy.hp<=0:
		fade=clampf(1.0-float(enemy.defeat)/.65,0,1)
		anchor.y+=float(enemy.defeat)*40
	var texture: Texture2D = f.texture
	draw_texture_rect(texture,Rect2((anchor+f.offset*factor).round(),texture.get_size()*factor),false,Color(1,1,1,fade))
	if enemy.hp<=0 and enemy.defeat<.35 and host.motion:
		for n in 4:
			var point: Vector2 = anchor+Vector2.from_angle(n*TAU/4-PI/4)*(8+enemy.defeat*60)
			draw_rect(Rect2(point.round(),Vector2.ONE*3),Color(1,.83,.56,fade))

func _draw() -> void:
	if host == null: return
	var world = host.world
	var a = world.adventure
	if not a.enabled: return
	var clock: float = host.animation_clock()
	var ground: float = host.ground
	if a.giant() and host.effects_enabled and host.decorative_motion():
		for ribbon in 5:
			var points := PackedVector2Array()
			for n in 25:
				var x: float = float(n)/24.0*host.scene_w
				points.append(Vector2(x,220+ribbon*40+sin(x*0.007+clock*0.45+ribbon)*28))
			var color := Color.from_hsv(fposmod(clock*0.035+float(ribbon)*0.16,1.0),0.45,1.0,0.065*host.prism_intensity)
			draw_polyline(points,color,23)
	# Weather never changes collision bounds or hides the foreground silhouettes.
	if a.weather in ["rain", "storm", "snow", "sand"] and host.decorative_motion():
		var tint := Color("a7c9ea") if a.weather in ["rain", "storm"] else (Color("ebf6ff") if a.weather == "snow" else Color("e4c695"))
		tint.a = 0.38
		for i in 64:
			var x := fposmod(i * 151.0 - clock * (180.0 if a.weather == "sand" else 45.0), host.scene_w)
			var y := 146.0 + fposmod(i * 93.0 + clock * (510.0 if a.weather in ["rain", "storm"] else 70.0), ground - 145.0)
			if a.weather in ["rain", "storm"]: draw_line(Vector2(x, y), Vector2(x - 4, y + 15), tint, 2)
			else: draw_rect(Rect2(Vector2(x, y).round(), Vector2(3, 3)), tint)
	if a.thunder_time > 0.0 and host.effects_enabled and host.decorative_motion():
		var bolt := PackedVector2Array([Vector2(a.thunder_x, 147), Vector2(a.thunder_x - 20, 185), Vector2(a.thunder_x + 8, 181), Vector2(a.thunder_x - 24, 236)])
		draw_polyline(bolt, Color(0.87, 0.91, 1.0, minf(0.7, a.thunder_time * 1.4)), 4)
	for item in a.items:
		var bob := sin(clock * 4.0 + item.id) * 3.0
		var point := Vector2(item.x, ground + item.y + bob)
		var frame: int = host.frames.cycle("power",0,clock,1.0)
		if item.kind=="fragaria":
			draw_texture_rect(FRAGARIA,Rect2(point-Vector2(22,42),Vector2(44,62)),false)
		elif item.kind in ["spring","fortune","frost"]: PixelArt.item(self,point,item.kind)
		elif item.kind == "mushroom": atlas("power", 0, frame, point, 63, true)
		else:
			var icons := {"lightning":0,"slow":1,"haste":2,"shield":3,"magnet":4,"leaf":5}
			atlas("power",int(icons[item.kind])+1,host.frames.cycle("power",int(icons[item.kind])+1,clock,1.0),point,46,true)
	for enemy in a.enemies:
		if enemy.kind in ["bat","slime","beetle","wisp"]:
			creature(enemy,ground)
			continue
		var row := 0 if enemy.kind == "crow" else 3
		var frame: int = host.frames.cycle("enemies",row,clock+float(enemy.id)*0.13,0.8)
		if enemy.hp <= 0:
			row = 2 if enemy.kind == "crow" else 5
			frame = host.frames.progress("enemies",row,enemy.defeat/0.65) if host.motion else host.frames.count("enemies",row)-1
		elif enemy.hurt > 0.0:
			row = 2 if enemy.kind == "crow" else 5
			frame = 0
		elif enemy.kind == "crow" and enemy.diving: row = 1
		elif enemy.kind == "gnome" and enemy.x < world.PLAYER_X + 160:
			row = 4
			frame = host.frames.cycle("enemies",row,clock,0.75)
		var anchor := Vector2(enemy.x, ground + enemy.y + (24.0 if enemy.kind == "crow" else 23.0))
		atlas("enemies", row, frame, anchor, 80 if enemy.kind == "crow" else 65)
		if enemy.hp > 0 and enemy.hp < enemy.max_hp:
			draw_rect(Rect2(enemy.x - 15, ground + enemy.y - 39, 30, 4), Color("34283c"))
			draw_rect(Rect2(enemy.x - 15, ground + enemy.y - 39, 30.0 * enemy.hp / enemy.max_hp, 4), Color("ffc576"))
		if enemy.kind == "crow" and enemy.diving and enemy.hp > 0 and enemy.x > world.PLAYER_X + 135:
			draw_string(host.FONT, Vector2(enemy.x - 4, ground + enemy.y - 43), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("ffd57a"))
	if a.lightning_time > 0.0:
		var source: Vector2 = a.lightning_origin+Vector2(0,ground)
		var end: Vector2 = a.lightning_end+Vector2(0,ground)
		var alpha: float = minf(1,a.lightning_time/0.12)
		var beam := PackedVector2Array()
		for n in 26:
			var point := source.lerp(end,float(n)/25)
			point.y += (0 if n in [0,25] else (6 if n%2 else -6))
			beam.append(point)
		draw_polyline(beam,Color(0.51,0.79,0.88,alpha*0.23),15)
		draw_polyline(beam,Color(1,0.91,0.63,alpha),3)
		for target in a.lightning_targets:
			var impact: Vector2 = target+Vector2(0,ground)
			draw_line(Vector2(impact.x,source.y),impact,Color(1,0.91,0.63,alpha),2)
	if a.xp_notice>0:
		draw_string(host.interface_options.body_font,Vector2(world.PLAYER_X+18,ground+world.y-122-(1-a.xp_notice)*20),"+%d XP"%a.last_xp,HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color(1,0.88,0.60,minf(1,a.xp_notice*3)))
	if a.powers.frost>0:
		for n in 9:
			var point := Vector2(world.PLAYER_X+24+n*45,ground-8-fposmod(clock*15+n*17,70))
			draw_rect(Rect2(point.round(),Vector2(3,3)),Color(0.65,0.88,0.94,0.6))

	if float(a.powers.shield) > 0.0:
		draw_arc(Vector2(world.PLAYER_X, ground + world.y - a.body_height(world) * 0.5), a.body_height(world) * 0.65, 0, TAU, 24, Color(0.55, 0.94, 0.88, 0.7), 3)
	if a.giant() and host.effects_enabled and host.decorative_motion():
		for i in 8:
			var hue := fposmod(clock * 0.035 + float(i) / 8, 1.0)
			var color := Color.from_hsv(hue, 0.35, 0.95, 0.12*host.prism_intensity)
			var x := fposmod(i * 197.0 + sin(clock * 0.8 + i) * 12, host.scene_w)
			draw_circle(Vector2(x, 220.0 + sin(i + clock * 0.6) * 55), 5 + i % 3, color)

	# Contact-only claw marks, attached to the advancing forepaw, never a projectile.
	if world.character=="wolf" and a.attack_time>0 and not a.attack_sprinting and a.attack_variant==1 and host.motion:
		var phase: float = (a.ATTACK_DURATION-a.attack_time)/a.ATTACK_DURATION
		if phase>0.28 and phase<0.72:
			var fade: float = sin((phase-0.28)/0.44*PI)
			var center: Vector2 = Vector2(world.PLAYER_X+57,ground+world.y-45)+host.combat_lunge()
			for n in 3:
				var p: Vector2 = center+Vector2(n*6,-n*3)
				draw_polyline(PackedVector2Array([p+Vector2(-8,-10),p+Vector2(1,0),p+Vector2(4,12)]),Color(0.90,0.75,1.0,fade),2)
