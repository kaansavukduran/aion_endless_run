class_name AionCampaignStick
extends Control
var axis := Vector2.ZERO
var active := false
var ink := Color("ad8d9f")

func _draw() -> void:
	var center := size*.5
	var radius := size.x*.47
	var points := PackedVector2Array()
	for i in 8: points.append((center+Vector2.from_angle((i+.5)*TAU/8.)*radius).round())
	draw_colored_polygon(points,Color("27212edd")); draw_polyline(points+PackedVector2Array([points[0]]),ink,3.)
	draw_line(center-Vector2(radius*.7,0),center+Vector2(radius*.7,0),Color("6a5969"),2.)
	var knob := center+axis*radius*.48
	var inner := PackedVector2Array()
	for i in 8: inner.append((knob+Vector2.from_angle((i+.5)*TAU/8.)*radius*.40).round())
	draw_colored_polygon(inner,Color("81374e") if active else Color("493649"))
	draw_polyline(inner+PackedVector2Array([inner[0]]),Color("ffcf8c") if active else ink,3.)

func value(point: Vector2) -> Vector2:
	var delta := (point-position-size*.5)/(size.x*.37)
	return delta.limit_length(1.) if delta.length()>.18 else Vector2.ZERO
