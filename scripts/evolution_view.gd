extends Node2D
const META = preload("res://assets/EVOLUTION-PROVENANCE.json")
const GIRLS = preload("res://assets/evolution-celebrants.png")
var host

func heart(canvas: Node2D,point: Vector2, size: float, color: Color) -> void:
	var shape := PackedVector2Array([Vector2(0,1),Vector2(-1,0),Vector2(-1,-0.6),Vector2(-0.5,-1),Vector2(0,-0.55),Vector2(0.5,-1),Vector2(1,-0.6),Vector2(1,0)])
	for i in shape.size(): shape[i] = (point + shape[i] * size).round()
	canvas.draw_colored_polygon(shape,color)

func girl(canvas: Node2D,row: int, frame: int, point: Vector2, opacity: float, depth: float = 1.0) -> void:
	var f: Dictionary = host.frames.pose("celebrants",row,frame)
	var tex: Texture2D = f.texture
	var factor: float = float(f.scale)*depth
	canvas.draw_texture_rect(tex,Rect2((point+f.offset*factor).round(),tex.get_size()*factor),false,Color(1,1,1,opacity))

func fragaria_tableau() -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	var a=host.world.adventure
	if a.fragaria_time<=0 or not a.celebrations_enabled:return result
	var width: float=host.scene_w*.80
	var center: float=host.scene_w*.50-(host.world.distance-a.fragaria_origin_distance)*.12
	for i in 8:
		result.append({"row":i,"anchor":Vector2(center-width*.5+width*(float(i)+.5)/8.0,host.ground-65)})
	return result

func fragaria(canvas: Node2D) -> void:
	var party:=fragaria_tableau()
	if party.is_empty():return
	var center: float=(party[0].anchor.x+party[-1].anchor.x)*.5
	var font_size:=mini(64,floori(host.scene_w/7.0))
	var width: float=host.FONT.get_string_size("FRAGARIA",HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	var point:=Vector2(center-width*.5,host.ground-153)
	canvas.draw_string_outline(host.FONT,point,"FRAGARIA",HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,4,Color("302333"))
	canvas.draw_string(host.FONT,point,"FRAGARIA",HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color("ffd1bd"))
	for item in party:
		var count: int=host.frames.count("celebrants",item.row)/2
		var frame:=posmod(int(host.world.time*7)+item.row,count) if host.decorative_motion() else 1
		girl(canvas,item.row,frame,item.anchor,1.0,.50)
		if host.effects_enabled and host.decorative_motion():
			for j in 3:
				var phase:=fposmod(host.world.time*.6+item.row*.23+j*.3,1.0)
				var p: Vector2=item.anchor+Vector2(sin(item.row+j*2)*22,-95+phase*85)
				canvas.draw_rect(Rect2(p.round(),Vector2(3,3)),[Color("ff9ab7"),Color("ffe0a1"),Color("b5daa0")][j])

func _draw() -> void:
	draw_scene(self,false)

func draw_scene(canvas: Node2D,background: bool) -> void:
	if host == null: return
	var w = host.world
	var a = w.adventure
	if background and w.state in ["running","paused"]:fragaria(canvas)
	if not a.enabled or not a.celebrations_enabled or w.state not in ["running","paused"]: return
	var clock: float = a.celebration_clock
	var moving: bool = host.motion
	var ground: float = host.ground
	var hug: bool = a.hugging()
	var near: bool = hug or a.heart_time>0
	if background==near: return
	if a.girl_index >= 0 and (a.celebration_time > 0 or hug):
		var half: int = host.frames.count("celebrants",a.girl_index)/2
		var frame := posmod(int(clock*7),half) if moving else 1
		var anchor := Vector2(a.celebration_x(w,moving),ground-58)
		var opacity := 1.0
		var depth := 0.65
		if a.heart_time > 0:
			frame = host.frames.count("celebrants",a.girl_index)-1
			depth = 1.0
			anchor = Vector2(w.PLAYER_X+38-(w.distance-a.celebration_spawn_distance)*0.7,ground)
			opacity = a.heart_time/2.0
		if hug:
			var phase: float = 1.0-a.hug_time/a.HUG_DURATION
			frame = half + mini(half-1,int(phase*half))
			depth = 1.0
			if not moving: frame = half+half/2
			anchor = Vector2(w.PLAYER_X+140.0-(1.0 if not moving else smoothstep(0.0,0.25,phase))*102.0,ground)
		if background:
			# A real elevated background bank, drawn BEFORE nearby trees and the road.
			var colors := [Color("766065"),Color("637f90"),Color("385d49"),Color("50566b")]
			canvas.draw_rect(Rect2(anchor+Vector2(-64,0),Vector2(128,26)),colors[w.biome()])
			canvas.draw_rect(Rect2(anchor+Vector2(-68,-3),Vector2(136,5)),colors[w.biome()].lightened(0.30))
		girl(canvas,a.girl_index,frame,anchor,1.0 if hug else opacity,depth)
		if not hug and a.heart_time <= 0:
			canvas.draw_string(host.FONT,anchor+Vector2(-38,-78),host.text("level_short") % a.level,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("ffdeaa"))
		if host.effects_enabled and host.decorative_motion():
			for i in 16:
				var phase := fposmod(clock * (0.33 + float(i%4)*0.035) + float(i)*0.163,1.0)
				var color := Color.from_hsv(fposmod(float(i)*0.137 + float(a.girl_index)*0.08,1.0),0.45,1.0, sin(phase*PI)*0.70)
				var point := anchor+Vector2(sin(float(i)*1.79)*phase*75,-112+phase*100)
				match a.celebration_style:
					0: canvas.draw_rect(Rect2(point.round(),Vector2(3+i%3,3+i%2)),color)
					1:
						canvas.draw_line(point-Vector2(4,0),point+Vector2(4,0),color,2)
						canvas.draw_line(point-Vector2(0,4),point+Vector2(0,4),color,2)
					2: heart(canvas,point,3+float(i%2),color)
					3: canvas.draw_circle(point,2+float(i%2),color)
	if hug or a.heart_time > 0:
		for i in (7 if moving else 3):
			var phase := fposmod(clock*0.55+float(i)*0.157,1.0) if moving else float(i)*0.30
			var point := Vector2(w.PLAYER_X+sin(float(i)*2.2)*55,ground-68-phase*98)
			heart(canvas,point,5+float(i%3),Color(1.0,0.51,0.72,0.82 if not moving else sin(phase*PI)*0.85))
