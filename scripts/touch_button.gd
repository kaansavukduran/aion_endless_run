class_name RunnerTouchButton
extends Control
# One geometric cut-corner family. Skin, icon and hit target share the same
# device-pixel grid; fractional viewport scaling cannot stretch one rim.
var action:="jump"
var caption:=""
var elemental:=false
var pressed:=false
var disabled:=false
var cooldown:=0.0
var palette:={"pressed":"5b3d50","surface":"27212e","accent":"ffcf8c","border":"ad8d9f","text":"f5ebd9","muted":"cfbec4"}
var font: Font
var skins:={}
var icons:={}
const PIXEL:=2.0
const ICONS:={
 "jump":["......22......",".....2222.....","....222222....","...22222222...","..2222222222..",".222222222222.",".....2222.....",".....2222.....",".....2222.....",".....2222.....",".....2222.....","..33.2222.33..","..33......33..","...33333333..."],
 "duck":["..............",".....222......","....22222.....",".....222......",".......22.....","....222222....","...22..222....","..22..22222...","......22.22...","...2222..22...","..22.....22...",".2222...2222..","..............",".............."],
 "shoot":["..............","..............",".222222222222.","22222222222222","22333333333222","22222222222222","..22222222....","...222..22....","...222222.....","...222........","...222........","..2222........","..2222........",".............."],
 "boost":["..............","..22....22....","...22....22...","....22....22..",".....22....22.","....22....22..","...22....22...","..22....22....","..............","....3333......","....22222.....","....22222222..","...2222222222.","...3333333333."],
 "lightning":[".......33.....","......333.....",".....333......","....3333......","...33333......","..3333333333..",".3333333333...",".....33333....",".....3333.....","....3333......","....333.......","...333........","...33.........","..3..........."]}
func _init() -> void:texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
func device_scale() -> float:return maxf(.01,get_global_transform_with_canvas().get_scale().x)
func pixel_unit() -> float:return maxf(1,roundf(PIXEL*device_scale()))/device_scale()
func grid_size() -> int:return maxi(20,roundi(size.x/pixel_unit()))
static func inside_pixel(x: int,y: int,side: int) -> bool:
 if x<0 or y<0 or x>=side or y>=side:return false
 var cut:=maxi(3,side/6)
 var corner_x:=mini(x,side-1-x)
 var corner_y:=mini(y,side-1-y)
 return corner_x+corner_y>=cut
func _has_point(point: Vector2) -> bool:
 if point.x<0 or point.y<0 or point.x>=size.x or point.y>=size.y:return false
 var side:=grid_size()
 return inside_pixel(floori(point.x/size.x*side),floori(point.y/size.y*side),side)
func hit(point: Vector2) -> bool:return visible and _has_point(point-get_global_rect().position)
func skin_image(side: int) -> Image:
 var image:=Image.create_empty(side,side,false,Image.FORMAT_RGBA8)
 var face:=Color(palette.pressed if pressed else palette.surface)
 var rim:=Color(palette.accent if pressed else palette.border)
 var ink:=Color(palette.border).darkened(.62)
 for y in side:
  for x in side:
   if not inside_pixel(x,y,side):continue
   var color:=face
   var depth:=3
   for n in range(1,4):
    if not inside_pixel(x-n,y,side) or not inside_pixel(x+n,y,side) or not inside_pixel(x,y-n,side) or not inside_pixel(x,y+n,side):depth=n-1;break
   if depth==0:color=ink
   elif depth==1:color=rim
   elif depth==2:color=ink
   if disabled and depth>0:color=color.lerp(face,.45)
   image.set_pixel(x,y,color)
 return image
func icon_pattern() -> Array:return ICONS.lightning if action=="shoot" and elemental else ICONS.get(action,ICONS.jump)
func icon_image() -> Image:
 var canvas:=Image.create_empty(16,16,false,Image.FORMAT_RGBA8)
 var pattern:=icon_pattern()
 var light:=Color(palette.muted if disabled else palette.text)
 var accent:=Color(palette.accent)
 for y in pattern.size():
  for x in str(pattern[y]).length():
   var code:=str(pattern[y])[x]
   if code!=".":canvas.set_pixel(x+1,y+1,accent if code=="3" else light)
 return canvas
func _draw() -> void:
 var side:=grid_size()
 var key:=JSON.stringify([side,pressed,disabled,palette])
 if not skins.has(key):skins[key]=ImageTexture.create_from_image(skin_image(side))
 draw_texture_rect(skins[key],Rect2(Vector2.ZERO,size),false)
 var unit:=pixel_unit()
 var scale_value:=device_scale()
 var shift:=Vector2(0,unit if pressed else 0)
 var icon_key:=JSON.stringify([action,elemental,disabled,palette])
 if not icons.has(icon_key):icons[icon_key]=ImageTexture.create_from_image(icon_image())
 var icon_unit: float=maxf(1,ceilf(size.x*scale_value*.34/16.0))/scale_value
 var icon_size:=Vector2.ONE*16*icon_unit
 var origin: Vector2=((Vector2((size.x-icon_size.x)*.5,size.y*.13)*scale_value).round()/scale_value)+shift
 draw_texture_rect(icons[icon_key],Rect2(origin,icon_size),false)
 if font:
  var font_size:=roundi(size.x*.21)
  while font_size>16 and font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>size.x*.80:font_size-=1
  var measured:=font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size)
  var at: Vector2=(Vector2((size.x-measured.x)*.5,size.y*.80)*scale_value).round()/scale_value+shift
  draw_string(font,at,caption,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color(palette.muted if disabled else palette.text))
 if cooldown>0:
  var width: float=roundf(size.x*.46/unit)*unit
  var left: float=roundf((size.x-width)*.5/unit)*unit
  var y: float=roundf(size.y*.88/unit)*unit
  draw_rect(Rect2(Vector2(left,y),Vector2(width,unit)),Color(palette.border))
  draw_rect(Rect2(Vector2(left,y),Vector2(ceilf(width*(1-clampf(cooldown,0,1))/unit)*unit,unit)),Color(palette.accent))
 if pressed:
  draw_rect(Rect2(Vector2(roundf(size.x*.35/unit)*unit,roundf(size.y*.90/unit)*unit),Vector2(roundf(size.x*.30/unit)*unit,unit)),Color(palette.accent))
