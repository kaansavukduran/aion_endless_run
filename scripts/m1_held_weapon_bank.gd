class_name M1HeldWeaponBank
extends RefCounted

const DATA=preload('res://assets/M1-HELD-WEAPONS.json')
static var cache: Dictionary={}

static func display_source(kind: String) -> String:
 if not DATA.data.weapons.has(kind):kind='pistol'
 return str(DATA.data.weapons[kind].display_source)

static func texture(items: ForgeItemBank,kind: String) -> Texture2D:
 if not DATA.data.weapons.has(kind):kind='pistol'
 if cache.has(kind):return cache[kind]
 var registration: Dictionary=DATA.data.weapons[kind]
 var source: Image=items.pose(str(registration.display_source)).texture.get_image()
 # Preserve original pickup-cache pixels and the complete registered canvas.
 var pixels: Image=source.duplicate()
 if not registration.keep_runs.is_empty():
  pixels=Image.create_empty(source.get_width(),source.get_height(),false,Image.FORMAT_RGBA8)
  for run in registration.keep_runs:
   pixels.blit_rect(source,Rect2i(int(run[1]),int(run[0]),int(run[2]),1),Vector2i(int(run[1]),int(run[0])))
 if int(registration.source_facing)<0:pixels.flip_x()
 cache[kind]=ImageTexture.create_from_image(pixels)
 return cache[kind]
