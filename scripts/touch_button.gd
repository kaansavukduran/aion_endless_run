class_name RunnerTouchButton
extends Control

# Rasterised on one integral two-unit pixel grid. Every quadrant uses the
# same mask; state changes never move the rim or its actual touch target.
var action := "jump"
var caption := ""
var elemental := false
var pressed := false
var disabled := false
var cooldown := 0.0
var palette := {"pressed":"5b3d50","surface":"27212e","accent":"ffcf8c","border":"ad8d9f","text":"f5ebd9","muted":"cfbec4"}
var font: Font
var skins := {}
var icons := {}

func _init() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
const PIXEL := 2.0
const ICONS := {
	"reload":[".....2222.....","...22222222...","..222....222..",".222......222.",".22........22.","222...........","222...33......","222..3333.....",".22..3333...2.",".222..33...222","..222.....2222","...22222222222",".....222222222",".........22222"],
	"jump":["......22......",".....2222.....","....222222....","...22222222...","..2222222222..",".222222222222.",".....2222.....",".....2222.....",".....2222.....",".....2222.....",".....2222.....","..33.2222.33..","..33......33..","...33333333..."],
	"attack":["..............","....2222......","..22222222....",".2222222222...",".23223223222..",".232232232222.",".222222222222.","..22222222222.","..2222222222..","...22222222...","....333333....","....222222....","....222222....",".............."],
	"duck":[".....2222.....","...22222222...","..222....222..",".222......222.",".22........22.","222.........2.","22....33......","22...3333.....","22...3333.....","222...33...22.",".222......222.","..22222222222.","...2222222222.","........22222."],
	"shoot":["..............","..............",".222222222222.","22222222222222","22333333333222","22222222222222","..22222222....","...222..22....","...222222.....","...222........","...222........","..2222........","..2222........",".............."],
	"boost":["..............","..22....22....","...22....22...","....22....22..",".....22....22.","....22....22..","...22....22...","..22....22....","..............","....3333......","....22222.....","....22222222..","...2222222222.","...3333333333."],
	"lightning":[".......33.....","......333.....",".....333......","....3333......","...33333......","..3333333333..",".3333333333...",".....33333....",".....3333.....","....3333......","....333.......","...333........","...33.........","..3..........."]
}

static func inside_pixel(x: int, y: int, side: int) -> bool:
	var center := float(side-1)*0.5
	var radius := float(side)*0.5-1.0
	return Vector2(float(x)-center,float(y)-center).length_squared() <= radius*radius

func grid_size() -> int: return maxi(24,roundi(size.x/PIXEL))

func hit(point: Vector2) -> bool:
	return visible and _has_point(point-get_global_rect().position)

func _has_point(point: Vector2) -> bool:
	if point.x<0 or point.y<0 or point.x>=size.x or point.y>=size.y:return false
	var side:=grid_size()
	return inside_pixel(floori(point.x/size.x*side),floori(point.y/size.y*side),side)

func skin_image(side: int) -> Image:
	var canvas:=Image.create_empty(side,side,false,Image.FORMAT_RGBA8)
	var border:=Color(palette.border)
	var accent:=Color(palette.accent)
	var face:=Color(palette.pressed if pressed else palette.surface)
	var ink:=border.darkened(0.68)
	var center:=float(side-1)*.5
	var radius:=float(side)*.5-1.0
	for y in side:
		for x in side:
			if not inside_pixel(x,y,side):continue
			var depth:=radius-Vector2(x-center,y-center).length()
			var color:=face
			if depth<1:color=ink
			elif depth<2:color=accent if pressed else border.darkened(.20)
			elif depth<3.5:color=border.lerp(accent,.56 if pressed else .32).lightened(.08) if y<center else border.darkened(.25)
			elif depth<4.5:color=ink
			elif y<center-2:color=face.lightened(.045)
			else:color=face.darkened(.035)
			if disabled:color=color.lerp(face,.32)
			canvas.set_pixel(x,y,color)
	# Symmetric inset metal studs belong to the rim, rather than free-floating
	# decorative dots. Identical positions in every state preserve the silhouette.
	for stud in [Vector2i(side/2-1,3),Vector2i(side/2-1,side-5)]:
		for dy in 2:
			for dx in 2:canvas.set_pixel(stud.x+dx,stud.y+dy,accent.darkened(.12 if not pressed else 0))
	return canvas

func icon_pattern() -> Array:
	return ICONS.lightning if action=="shoot" and elemental else ICONS.get(action,ICONS.jump)

func icon_image() -> Image:
	var pattern:=icon_pattern()
	var canvas:=Image.create_empty(16,16,false,Image.FORMAT_RGBA8)
	var light:=Color(palette.muted if disabled else palette.text)
	var jewel:=Color(palette.accent)
	if elemental:jewel=Color("87d8e7") if Color(palette.surface).get_luminance()<.3 else Color("23637b")
	var ink:=Color(palette.border).darkened(.68)
	for y in pattern.size():
		for x in str(pattern[y]).length():
			if str(pattern[y])[x]==".":continue
			for edge in [Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1)]:
				canvas.set_pixel(x+1+edge.x,y+1+edge.y,ink)
	for y in pattern.size():
		for x in str(pattern[y]).length():
			var code:=str(pattern[y])[x]
			if code!=".":canvas.set_pixel(x+1,y+1,jewel if code=="3" else light)
	return canvas

func draw_icon(origin: Vector2) -> void:
	# Bake the crisp keyline and authored pixels once; two textured draws replace
	# hundreds of tiny rectangles on each frame of a phone's renderer.
	var key:=JSON.stringify([action,elemental,disabled,palette])
	if not icons.has(key):icons[key]=ImageTexture.create_from_image(icon_image())
	draw_texture_rect(icons[key],Rect2(origin-Vector2.ONE*PIXEL,Vector2.ONE*16*PIXEL),false)

func _draw() -> void:
	var side:=grid_size()
	var key:=JSON.stringify([side,pressed,disabled,palette])
	if not skins.has(key):skins[key]=ImageTexture.create_from_image(skin_image(side))
	draw_texture_rect(skins[key],Rect2(Vector2.ZERO,size),false)
	var shift:=Vector2(0,PIXEL if pressed else 0)
	var pattern:=icon_pattern()
	var origin:=Vector2(roundf((size.x-14*PIXEL)*.5/PIXEL)*PIXEL,roundf((size.y*.43-7*PIXEL)/PIXEL)*PIXEL)+shift
	draw_icon(origin)
	if font:
		var measured:=font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,20)
		var caption_size:=clampi(floori(20.0*size.x*.74/maxf(1,measured.x)),18 if size.x>=96 else 16,20)
		measured=font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,caption_size)
		var anchor:=Vector2(roundf((size.x-measured.x)*.5),roundf(size.y*.80))+shift
		draw_string(font,anchor,caption,HORIZONTAL_ALIGNMENT_LEFT,-1,caption_size,Color(palette.muted if disabled else palette.text))
	if cooldown>0:
		var filled:=ceili(clampf(cooldown,0,1)*8)
		for n in 8:
			var angle:float=-PI/2+n*TAU/8
			var point:Vector2=(size*.5+Vector2.from_angle(angle)*(size.x*.43))/PIXEL
			var cell:Vector2=(point-Vector2.ONE).round()*PIXEL
			draw_rect(Rect2(cell,Vector2.ONE*PIXEL*2),Color(palette.accent if n<filled else palette.border))
	if disabled:
		var badge:Vector2=(Vector2(size.x*.75,size.y*.22)/PIXEL).round()*PIXEL
		draw_rect(Rect2(badge-Vector2.ONE*6,Vector2.ONE*12),Color(palette.surface))
		for n in 3:
			draw_rect(Rect2(badge+Vector2(n-1,n-1)*PIXEL,Vector2.ONE*PIXEL),Color(palette.muted))
			draw_rect(Rect2(badge+Vector2(1-n,n-1)*PIXEL,Vector2.ONE*PIXEL),Color(palette.muted))
