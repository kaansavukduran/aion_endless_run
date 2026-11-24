class_name CampaignLockArt
extends RefCounted

## Ground anchors coincide with the frame's bottom edge. Authored 2×
## cells share the same origin through warning, motion and rest.
const SHEET=preload("res://assets/m1-locks-and-traps.png")
const SLUICE=preload("res://assets/m1-sluice-trap.png")
const TRAPS := ["electric","vines","claw"]

static func gate(v,p: Vector2,section: String,frame: int,growth:=1.) -> void:
	var material:=1 if section in ["water","quay","relay"] else (2 if section in ["roots","arena"] else 0)
	var cell:=Rect2(64*frame,96*material,64,96)
	var dimensions:=Vector2(128,192)*growth
	v.draw_texture_rect_region(SHEET,Rect2((p-Vector2(dimensions.x*.5,dimensions.y)).round(),dimensions),cell)

static func trap(v,p: Vector2,kind: String,phase: float,animated: bool) -> bool:
	var row:=TRAPS.find(kind)
	if row<0 and kind!="sluice":return false
	var frame:=0
	if phase>=2.6 and phase<3.5:frame=1
	elif phase>=3.5 and phase<4.1:
		frame=3
		if animated:
			if phase<3.56:frame=2
			elif phase>4.02:frame=4
	if kind=="sluice":
		v.draw_texture_rect_region(SLUICE,Rect2(p-Vector2(64,96),Vector2(128,96)),Rect2(64*frame,0,64,48))
	else:
		v.draw_texture_rect_region(SHEET,Rect2(p-Vector2(64,112),Vector2(128,112)),Rect2(64*frame,288+56*row,64,56))
	return true
