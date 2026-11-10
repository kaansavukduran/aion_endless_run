extends Node2D
const META = preload("res://assets/EVOLUTION-PROVENANCE.json")
const GIRLS = preload("res://assets/evolution-celebrants.png")
var host

func heart(point: Vector2, size: float, color: Color) -> void:
	var shape := PackedVector2Array([Vector2(0,1),Vector2(-1,0),Vector2(-1,-0.6),Vector2(-0.5,-1),Vector2(0,-0.55),Vector2(0.5,-1),Vector2(1,-0.6),Vector2(1,0)])
	for i in shape.size(): shape[i] = (point + shape[i] * size).round()
	draw_colored_polygon(shape,color)

func girl(row: int, frame: int, point: Vector2, opacity: float) -> void:
	var d: Dictionary = META.data.atlases.celebrants
	var b: Array = d.bounds[row][frame]
	var reference: Array = d.bounds[row][0]
	var scale_value := 116.0 / float(reference[3]-reference[1])
	var crop := Rect2(float(d.x[frame])+b[0],float(d.y[row])+b[1],b[2]-b[0],b[3]-b[1])
	var offset := Vector2(float(b[0])-float(d.anchor_x[row]),float(b[1])-float(b[3])) * scale_value
	draw_texture_rect_region(GIRLS,Rect2((point+offset).round(),crop.size*scale_value),crop,Color(1,1,1,opacity))

func _draw() -> void:
	if host == null: return
	var w = host.world
	var a = w.adventure
	if not a.enabled or not a.celebrations_enabled or w.state not in ["running","paused"]: return
	var clock: float = a.celebration_clock
	var moving: bool = host.motion
	var ground: float = host.ground
	var hug: bool = a.hugging()
	if a.girl_index >= 0 and (a.celebration_time > 0 or hug):
		var frame := int(clock*5) % 4 if moving else 3
		var anchor := Vector2(host.view_w - 335.0,ground)
		var opacity := 0.82
		if a.heart_time > 0:
			frame = 7
			anchor = Vector2(w.PLAYER_X-45-(2.0-a.heart_time)*80,ground)
			opacity = a.heart_time/2.0
		if hug:
			var phase: float = 1.0-a.hug_time/a.HUG_DURATION
			frame = 4 if phase < 0.18 else (5 if phase < 0.40 else (6 if phase < 0.82 else 7))
			if not moving: frame = 6
			anchor = Vector2(w.PLAYER_X - 140.0 + (1.0 if not moving else smoothstep(0.0,0.25,phase))*105.0,ground)
		girl(a.girl_index,frame,anchor,1.0 if hug else opacity)
		if not hug and a.heart_time <= 0:
			draw_string(host.FONT,anchor+Vector2(-61,-128),host.text("level_short") % a.level,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("ffdeaa"))
		if host.effects_enabled and moving:
			for i in 32:
				var phase := fposmod(clock * (0.33 + float(i%4)*0.035) + float(i)*0.163,1.0)
				var color := Color.from_hsv(fposmod(float(i)*0.137 + float(a.girl_index)*0.08,1.0),0.45,1.0, sin(phase*PI)*0.70)
				var point := anchor+Vector2(sin(float(i)*1.79)*phase*105,-142+phase*130)
				match a.celebration_style:
					0: draw_rect(Rect2(point.round(),Vector2(3+i%3,3+i%2)),color)
					1:
						draw_line(point-Vector2(4,0),point+Vector2(4,0),color,2)
						draw_line(point-Vector2(0,4),point+Vector2(0,4),color,2)
					2: heart(point,3+float(i%2),color)
					3: draw_circle(point,2+float(i%2),color)
	if hug or a.heart_time > 0:
		for i in (7 if moving else 3):
			var phase := fposmod(clock*0.55+float(i)*0.157,1.0) if moving else float(i)*0.30
			var point := Vector2(w.PLAYER_X+sin(float(i)*2.2)*55,ground-68-phase*98)
			heart(point,5+float(i%3),Color(1.0,0.51,0.72,0.82 if not moving else sin(phase*PI)*0.85))
