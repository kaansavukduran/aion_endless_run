class_name RunnerTouchButton
extends Control
var action := "jump"
var caption := ""
var pressed := false
var disabled := false
var cooldown := 0.0
var font: Font
func hit(point: Vector2) -> bool:
	return visible and (point-get_global_rect().get_center()).length()<=size.x*.5
func _has_point(point: Vector2) -> bool:return (point-size*.5).length()<=size.x*.5
func _draw() -> void:
	var center:=size*.5
	var radius:=size.x*.48
	var shape:=PackedVector2Array()
	for i in 20:
		var p:=center+Vector2.from_angle(float(i)*TAU/20.0)*radius
		shape.append((p/3).round()*3)
	draw_colored_polygon(shape,Color("564052") if pressed else Color("29202ee8"))
	var outline:=shape.duplicate();outline.append(shape[0])
	draw_polyline(outline,Color("f8d59e") if pressed else Color("b78b87"),4 if pressed else 2)
	var ink:=Color("f5e2ba") if not disabled else Color("81717d")
	var c:=center+Vector2(0,-8)
	match action:
		"jump":
			draw_line(c+Vector2(-12,3),c+Vector2(0,-10),ink,5)
			draw_line(c+Vector2(0,-10),c+Vector2(12,3),ink,5)
			draw_line(c+Vector2(0,-9),c+Vector2(0,12),ink,5)
		"attack":
			draw_rect(Rect2(c-Vector2(13,7),Vector2(24,19)),ink)
			for i in 3:draw_rect(Rect2(c+Vector2(-11+i*8,-12),Vector2(6,10)),ink)
		"duck":
			var points:=PackedVector2Array()
			for i in 10:points.append(c+Vector2.from_angle(-PI*.6+i*.48)*14)
			draw_polyline(points,ink,4)
			draw_line(points[-1],points[-1]+Vector2(-9,-3),ink,4)
		"shoot":
			draw_rect(Rect2(c+Vector2(-17,-7),Vector2(32,8)),ink)
			draw_rect(Rect2(c+Vector2(-10,0),Vector2(9,16)),ink)
		"boost":
			for i in 2:
				draw_polyline(PackedVector2Array([c+Vector2(-13+i*14,-10),c+Vector2(-3+i*14,0),c+Vector2(-13+i*14,10)]),ink,4)
	if font:
		var text_size:=font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,24)
		var caption_size:=maxi(20,mini(24,floori(24.0*(size.x-12)/maxf(1,text_size.x))))
		text_size=font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,caption_size)
		draw_string(font,Vector2((size.x-text_size.x)*.5,size.y*.80),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,caption_size,ink)
	if cooldown>0:
		var p:=PackedVector2Array()
		for i in 20:p.append(center+Vector2.from_angle(-PI/2+float(i)/19*TAU*cooldown)*(radius-7))
		draw_polyline(p,Color("e8aa64"),3)
	if disabled:
		draw_line(center+Vector2(-14,14),center+Vector2(14,-14),Color("b6a0a4"),3)
