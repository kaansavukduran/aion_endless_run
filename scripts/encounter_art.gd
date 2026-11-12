# Small power-item icons. Animated creatures use the registered PNG atlas.
extends RefCounted

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
