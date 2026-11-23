class_name M1HeldWeaponBank
extends RefCounted

const DATA=preload('res://assets/M1-HELD-WEAPONS.json')
const VARIANTS=preload('res://assets/M1-HELD-VARIANTS.json')
static var cache: Dictionary={}
static var variant_sources: Dictionary={}

static func registration(kind: String) -> Dictionary:
 if VARIANTS.data.weapons.has(kind):return VARIANTS.data.weapons[kind]
 return DATA.data.weapons.get(kind,DATA.data.weapons.pistol)

static func display_source(kind: String) -> String:
 if not DATA.data.weapons.has(kind):kind='pistol'
 return str(DATA.data.weapons[kind].display_source)

static func texture(items: ForgeItemBank,kind: String) -> Texture2D:
 if not DATA.data.weapons.has(kind):kind='pistol'
 if cache.has(kind):return cache[kind]
 var registration: Dictionary=M1HeldWeaponBank.registration(kind)
 if registration.has('path'):
  var path: String='res://'+str(registration.path)
  if not variant_sources.has(path):
   var raw:=RunnerSourcePixels.image(path)
   if raw.is_compressed():raw.decompress()
   raw.convert(Image.FORMAT_RGBA8);variant_sources[path]=raw
  var canvas: Array=registration.canvas_size;var bounds: Array=registration.bounds
  var isolated:=Image.create_empty(int(canvas[0]),int(canvas[1]),false,Image.FORMAT_RGBA8)
  for run in registration.runs:
   isolated.blit_rect(variant_sources[path],Rect2i(int(run[1]),int(run[0]),int(run[2]),1),Vector2i(int(run[1])-int(bounds[0])+2,int(run[0])-int(bounds[1])+2))
  if int(registration.source_facing)<0:isolated.flip_x()
  cache[kind]=ImageTexture.create_from_image(isolated)
  return cache[kind]
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
