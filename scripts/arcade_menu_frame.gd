class_name ArcadeMenuFrame
extends PanelContainer
## Small copper fasteners and hard edge joints, shared by the title plate.
var palette: Dictionary={}
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 resized.connect(queue_redraw)
func _draw() -> void:
 if palette.is_empty():return
 var edge:=Color(palette.border);var shine:=Color(palette.accent);var shadow:=Color(palette.background)
 for corner in [Vector2(4,4),Vector2(size.x-12,4),Vector2(4,size.y-12),Vector2(size.x-12,size.y-12)]:
  draw_rect(Rect2(corner,Vector2(8,8)),shadow)
  draw_rect(Rect2(corner+Vector2(1,1),Vector2(5,5)),edge)
  draw_rect(Rect2(corner+Vector2(2,2),Vector2(2,2)),shine)
 draw_line(Vector2(16,4),Vector2(size.x-16,4),edge,1.)
 draw_line(Vector2(16,size.y-5),Vector2(size.x-16,size.y-5),shadow,2.)
