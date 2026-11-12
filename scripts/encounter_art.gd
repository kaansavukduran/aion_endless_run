# Small native pixel silhouettes. Hero atlases and their registration stay untouched.
extends RefCounted

static func pixel(view: Node2D, at: Vector2, rect: Rect2, ink: Color) -> void:
	view.draw_rect(Rect2((at+rect.position).round(),rect.size),ink)

static func enemy(view: Node2D, e: Dictionary, ground: float) -> void:
	var at := Vector2(e.x,ground+e.y).round()
	var fade := clampf(1.0-float(e.defeat)/0.65,0,1) if e.hp<=0 else 1.0
	if e.hp<=0: at.y += float(e.defeat)*48
	var ink := Color("35283e"); ink.a=fade
	var light := Color("f9dfb0");light.a=fade
	var step := int(e.age*10)%4
	match str(e.kind):
		"bat":
			var wing_y: int = [-10,-4,5,-4][step]
			for side in [-1,1]:
				pixel(view,at,Rect2(side*10-8,wing_y-7,18,14),ink)
				pixel(view,at,Rect2(side*25-9,wing_y-12,18,12),ink)
				pixel(view,at,Rect2(side*25-6,wing_y-9,12,6),Color(0.64,0.42,0.72,fade))
			pixel(view,at,Rect2(-11,-14,22,28),ink)
			pixel(view,at,Rect2(-9,-20,6,12),ink);pixel(view,at,Rect2(3,-20,6,12),ink)
			pixel(view,at,Rect2(-8,-6,16,17),Color(0.52,0.35,0.62,fade))
		"slime":
			pixel(view,at,Rect2(-24,-6,48,21),ink)
			pixel(view,at,Rect2(-18,-14,36,29),ink)
			pixel(view,at,Rect2(-20,-3,40,15),Color(0.36,0.70,0.49,fade))
			pixel(view,at,Rect2(-14,-10,28,20),Color(0.51,0.81,0.56,fade))
			pixel(view,at,Rect2(-12,-8,7,4),Color(0.78,0.96,0.65,fade))
		"beetle":
			for leg in 3:
				var dx := 3 if (step+leg)%2 else -3
				pixel(view,at,Rect2(-24+leg*16+dx,14,8,9),ink)
			pixel(view,at,Rect2(-21,-12,42,29),ink)
			pixel(view,at,Rect2(-15,-18,28,32),ink)
			pixel(view,at,Rect2(-17,-9,30,20),Color(0.73,0.42,0.31,fade))
			pixel(view,at,Rect2(-12,-14,21,6),Color(0.93,0.65,0.37,fade))
			pixel(view,at,Rect2(-1,-12,3,25),ink)
		"wisp":
			for flame in 3:
				pixel(view,at,Rect2(-17+flame*12,-21+((step+flame)%3)*4,10,28),Color(0.38,0.72,0.85,fade*0.85))
			pixel(view,at,Rect2(-18,-8,36,23),ink)
			pixel(view,at,Rect2(-14,-11,28,23),Color(0.51,0.84,0.92,fade))
			pixel(view,at,Rect2(-9,12,18,7),Color(0.73,0.94,0.96,fade))
	# Left-facing eyes keep enemies distinct from the right-facing runner.
	pixel(view,at,Rect2(-12,-5,5,6),light)
	pixel(view,at,Rect2(-13,-4,3,5),ink)
	pixel(view,at,Rect2(1,-5,5,6),light)
	pixel(view,at,Rect2(1,-4,3,5),ink)

static func item(view: Node2D, point: Vector2, kind: String) -> void:
	var ink := Color("35283e")
	view.draw_rect(Rect2((point-Vector2(21,21)).round(),Vector2(42,42)),ink)
	match kind:
		"spring":
			for n in 4: view.draw_rect(Rect2(point+Vector2(-12,-14+n*7),Vector2(24,4)),Color("b5d5a1"))
			view.draw_line(point+Vector2(0,-20),point+Vector2(0,20),Color("f4dfaa"),3)
		"fortune":
			view.draw_rect(Rect2(point-Vector2(13,16),Vector2(26,32)),Color("c28c51"))
			view.draw_rect(Rect2(point-Vector2(9,13),Vector2(18,26)),Color("f4d582"))
			view.draw_line(point+Vector2(-3,-8),point+Vector2(3,8),ink,3)
		"frost":
			for n in 3:
				var ray := Vector2.from_angle(float(n)*PI/3)*18
				view.draw_line(point-ray,point+ray,Color("a2dce7"),4)
			view.draw_rect(Rect2(point-Vector2(5,5),Vector2(10,10)),Color("f5f4df"))
