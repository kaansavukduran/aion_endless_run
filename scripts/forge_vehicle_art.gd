class_name ForgeVehicleArt
extends RefCounted

const DATA = preload("res://assets/FORGE-VEHICLES-PROVENANCE.json")
const TURRETS = preload("res://assets/M1-VEHICLE-TURRETS.json")
# 0.40.0: Process-wide shared cache avoids repeated pixel-by-pixel turret polygon cuts in WebAssembly.
static var images: Dictionary = {}
static var cache: Dictionary = {}
static var split_cache: Dictionary = {}

static func mounted_phase(kind: String, phase: int) -> int:
	var count: int=DATA.data.types[kind].frames.size()
	# Firing is provided by the independent rotating source barrel. The old
	# baked horizontal flash/deployed barrel must not remain on the hull.
	if phase==1:return 0
	return phase if phase<count else 0

static func aim_anchors(kind: String, phase: int=0, frame: int=0, target_height: float=0.) -> Dictionary:
	phase=mounted_phase(kind,phase)
	var metrics:=anchors(kind,phase,frame,target_height)
	frame=int(metrics.frame)
	var f: Dictionary=DATA.data.types[kind].frames[phase][frame]
	var gun: Dictionary=TURRETS.data.types[kind].frames[phase][frame]
	if not bool(gun.can_fire):metrics.can_fire=false;return metrics
	var pivot:=Vector2(float(gun.pivot[0]),float(gun.pivot[1]))
	var tip:=Vector2(float(gun.muzzle[0]),float(gun.muzzle[1]))
	var origin:=Vector2(float(f.origin[0]),float(f.origin[1]))
	metrics.pivot_local=(pivot-origin)*float(metrics.scale)
	metrics.barrel_length=pivot.distance_to(tip)*float(metrics.scale)
	# Turret art is canonical right-facing; its world angle is applied by view.
	metrics.muzzle_local=metrics.pivot_local+Vector2.RIGHT*float(metrics.barrel_length)
	metrics.source_facing=int(gun.source_facing)
	return metrics

func split_pose(kind: String, phase: int, frame: int, target_height: float=0.) -> Dictionary:
	phase=mounted_phase(kind,phase)
	var metrics:=aim_anchors(kind,phase,frame,target_height)
	frame=int(metrics.frame)
	var key:=kind+":"+str(phase)+":"+str(frame)+":"+str(target_height)
	if split_cache.has(key):return split_cache[key]
	var original:=pose(kind,phase,frame,target_height)
	if not bool(metrics.can_fire):return {"hull":original,"turret":{},"anchors":metrics}
	var f: Dictionary=DATA.data.types[kind].frames[phase][frame]
	var gun: Dictionary=TURRETS.data.types[kind].frames[phase][frame]
	var cut: Array=gun.cut
	var source_rect:=Rect2i(int(cut[0]),int(cut[1]),int(cut[2]-cut[0]),int(cut[3]-cut[1]))
	var polygon:=PackedVector2Array()
	for point in gun.polygon:polygon.append(Vector2(float(point[0]),float(point[1])))
	var pixels: Image=original.texture.get_image()
	var hull: Image=pixels.duplicate()
	var turret:=Image.create_empty(source_rect.size.x+4,source_rect.size.y+4,false,Image.FORMAT_RGBA8)
	var source_offset:=Vector2i(int(f.bounds[0])-2,int(f.bounds[1])-2)
	for y in source_rect.size.y:
		for x in source_rect.size.x:
			var source_pixel:=source_rect.position+Vector2i(x,y)
			if not Geometry2D.is_point_in_polygon(Vector2(source_pixel)+Vector2(.5,.5),polygon):continue
			var at:=source_pixel-source_offset
			if at.x<0 or at.y<0 or at.x>=pixels.get_width() or at.y>=pixels.get_height():continue
			turret.set_pixel(x+2,y+2,pixels.get_pixelv(at));hull.set_pixelv(at,Color.TRANSPARENT)
	var pivot:=Vector2(float(gun.pivot[0]),float(gun.pivot[1]))
	var offset: Vector2=Vector2(source_rect.position)-Vector2(2,2)-pivot
	if int(gun.source_facing)<0:
		turret.flip_x();offset.x=-offset.x-turret.get_width()
	var body: Dictionary=original.duplicate();body.texture=ImageTexture.create_from_image(hull);body.source_key="m1-vehicle-hull-"+kind
	var cannon: Dictionary={"texture":ImageTexture.create_from_image(turret),"offset":offset*float(metrics.scale),"size":turret.get_size()*float(metrics.scale),"muzzle_local":Vector2.RIGHT*float(metrics.barrel_length),"rotation":-float(gun.get("axis_radians",0.)),"source_key":"m1-vehicle-turret-"+kind,"source_phase":phase,"source_frame":frame}
	split_cache[key]={"hull":body,"turret":cannon,"anchors":metrics,"source_cut":source_rect,"source_polygon":polygon,"source_facing":int(gun.source_facing)}
	return split_cache[key]

func hull_pose(kind: String, phase: int, frame: int, target_height: float=0.) -> Dictionary:
	return split_pose(kind,phase,frame,target_height).hull

func turret_pose(kind: String, phase: int, frame: int, target_height: float=0.) -> Dictionary:
	return split_pose(kind,phase,frame,target_height).turret

static func anchors(kind: String, phase: int = 0, frame: int = 0, target_height: float = 0.) -> Dictionary:
	var data: Dictionary = DATA.data.types[kind]
	phase = phase if phase < data.frames.size() else 0
	frame = clampi(frame, 0, data.frames[phase].size() - 1)
	var f: Dictionary = data.frames[phase][frame]
	var factor: float = float(data.scale) * (target_height / float(data.target_height) if target_height > 0. else 1.)
	var origin := Vector2(float(f.origin[0]), float(f.origin[1]))
	var pivot := Vector2(float(f.barrel_pivot[0]), float(f.barrel_pivot[1]))
	var muzzle := Vector2(float(f.muzzle[0]), float(f.muzzle[1]))
	return {"pivot_local": (pivot - origin) * factor, "muzzle_local": (muzzle - origin) * factor, "barrel_length": pivot.distance_to(muzzle) * factor, "scale": factor, "phase": phase, "frame": frame, "can_fire": phase < 3}

func pose(kind: String, phase: int, frame: int, target_height: float = 0.) -> Dictionary:
	var data: Dictionary = DATA.data.types[kind]
	var metrics := anchors(kind, phase, frame, target_height)
	phase = int(metrics.phase); frame = int(metrics.frame)
	var key := kind + ":" + str(phase) + ":" + str(frame) + ":" + str(target_height)
	if cache.has(key): return cache[key]
	var sheet_image: Image=RunnerSourcePixels.sheet("res://" + str(data.path))
	var f: Dictionary = data.frames[phase][frame]
	var b: Array = f.bounds
	var result := Image.create_empty(int(b[2]) - int(b[0]) + 4, int(b[3]) - int(b[1]) + 4, false, Image.FORMAT_RGBA8)
	for run in RunnerSourcePixels.runs(f):
		result.blit_rect(sheet_image, Rect2i(int(f.rect[0]) + int(run[1]), int(f.rect[1]) + int(run[0]), int(run[2]), 1), Vector2i(int(run[1]) - int(b[0]) + 2, int(run[0]) - int(b[1]) + 2))
	var factor: float = metrics.scale
	cache[key] = {"texture": ImageTexture.create_from_image(result), "offset": Vector2(float(b[0]) - float(f.origin[0]) - 2., float(b[1]) - float(f.origin[1]) - 2.) * factor, "size": result.get_size() * factor, "muzzle_local": metrics.muzzle_local, "pivot_local": metrics.pivot_local, "barrel_length": metrics.barrel_length, "vehicle_growth": 1., "source_key": "forge-vehicle-" + kind, "source_phase": phase, "source_frame": frame}
	return cache[key]
