class_name CampaignLockArt
extends RefCounted

## Ground anchors coincide with the frame's bottom edge. Authored 2×
## cells share the same origin through warning, motion and rest.
const SHEET=preload("res://assets/m1-locks-and-traps.png")
const SLUICE=preload("res://assets/m1-sluice-trap.png")
const ROOT_HATCH=preload("res://assets/m1-root-hatch.png")
const ROUTE_HAZARDS=preload("res://assets/m1-route-hazards.png")
const TRAPS := ["electric","vines","claw"]
const ROUTE_TRAPS := ["gust","crystal"]

static func opening_frame(age: float,animated: bool) -> int:
	return clampi(1+int(age*13.),1,5) if animated else 5

static func gate(v,p: Vector2,section: String,frame: int,growth:=1.) -> void:
	var material:=1 if section in ["water","quay","relay"] else (2 if section in ["roots","arena"] else 0)
	var cell:=Rect2(64*frame,96*material,64,96)
	var dimensions:=Vector2(128,192)*growth
	v.draw_texture_rect_region(SHEET,Rect2((p-Vector2(dimensions.x*.5,dimensions.y)).round(),dimensions),cell)

static func root_hatch(v,p: Vector2,width: float,post_height: float,opened: bool) -> void:
	if opened:
		# Broken hardware stays to the left of the opening's collision edge.
		v.draw_texture_rect_region(ROOT_HATCH,Rect2(p+Vector2(-44.,-2.),Vector2(88.,58.)),Rect2(64.,0.,44.,29.))
		return
	var lip:=p+Vector2(0.,-4.)
	for x in range(0,ceili(width),128):
		var tile_width:=minf(128.,width-x)
		v.draw_texture_rect_region(ROOT_HATCH,Rect2(lip+Vector2(x,0.),Vector2(tile_width,28.)),Rect2(0.,0.,tile_width*.5,14.))
	var post:=p+Vector2(width-24.,-post_height)
	v.draw_texture_rect_region(ROOT_HATCH,Rect2(post,Vector2(48.,post_height)),Rect2(135.,0.,24.,80.))

static func trap(v,p: Vector2,kind: String,phase: float,animated: bool) -> void:
	var row:=TRAPS.find(kind)
	var frame:=0
	if phase>=2.6 and phase<3.5:frame=1
	elif phase>=3.5 and phase<4.1:
		frame=3
		if animated:
			if phase<3.56:frame=2
			elif phase>4.02:frame=4
	if kind=="sluice":
		v.draw_texture_rect_region(SLUICE,Rect2(p-Vector2(64,96),Vector2(128,96)),Rect2(64*frame,0,64,48))
	elif row>=0:
		v.draw_texture_rect_region(SHEET,Rect2(p-Vector2(64,112),Vector2(128,112)),Rect2(64*frame,288+56*row,64,56))
	elif kind in ROUTE_TRAPS:
		v.draw_texture_rect_region(ROUTE_HAZARDS,Rect2(p-Vector2(64,144),Vector2(128,144)),Rect2(64*frame,72*ROUTE_TRAPS.find(kind),64,72))
