## Isolated source-registration checks; this is not browser gameplay evidence.
extends SceneTree
const Damage=preload("res://scripts/m1_damage_art.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var data: Dictionary=Damage.DATA.data
	var bank:=Damage.new()
	check(Damage.has("rabbit") and not Damage.has("eren"),"Ayça damage is explicitly distinct from the archived male rabbit")
	check(Damage.ACTIONS==["freeze","fire","impact","faceplant"],"Four explicit semantic damage clips have no unknown-action alias")
	check(data.source_drawings==24 and data.runtime_drawings==24,"Exactly twenty-four actual source cels are registered")
	check(FileAccess.get_sha256("res://"+str(data.atlas.path))==str(data.source_sha256),"Runtime source is the unmodified recorded generated PNG")
	var hashes: Dictionary={}
	var scale_value: float=data.atlas.source_scale
	for action in Damage.ACTIONS:
		var previous_height:=INF
		for frame in 6:
			var pose: Dictionary=bank.pose("rabbit",action,frame)
			var pixels: Image=pose.texture.get_image()
			var m: Dictionary=Damage.metrics("rabbit",action,frame)
			check(Vector2(pose.offset)==Vector2(m.offset) and Vector2(pose.size)==Vector2(m.size),"Texture and cheap metrics share the same source registration")
			check(is_equal_approx(float(pose.source_scale),scale_value),"Source anatomy has one scale across all poses, never per-frame bounds scaling")
			check(str(pose.source_key)=="m1-damage-ayca" and int(pose.source_frame)==frame and int(pose.source_row)==Damage.ACTIONS.find(action),"Each semantic damage request loads its actual named cel")
			check(Vector2(pose.size).is_equal_approx(Vector2(pixels.get_size())*scale_value),"Draw size matches the actual isolated source texture")
			var edges_clear:=true
			for x in pixels.get_width():
				for y in [0,1,pixels.get_height()-2,pixels.get_height()-1]:edges_clear=edges_clear and pixels.get_pixel(x,y).a==0.
			for y in pixels.get_height():
				for x in [0,1,pixels.get_width()-2,pixels.get_width()-1]:edges_clear=edges_clear and pixels.get_pixel(x,y).a==0.
			check(edges_clear,"Transparent texture gutters isolate this cel from neighboring source art")
			var row: int=Damage.ACTIONS.find(action)
			var source: Dictionary=data.atlas.frames[row][frame]
			var ground_y: float=float(pose.offset.y)+float(source.body_bounds[3]-source.bounds[1]+2)*scale_value
			check(pose.ground_contact and absf(ground_y)<.001,"Actual connected sole/body contacts the support plane")
			if pose.face_visible:
				check(absf(float(pose.face_local.x)-14.)<.001,"Visible anatomical face stays horizontally registered throughout the clip")
				check(is_equal_approx(float(pose.head_size),float(M1HeroArt.DATA.data.atlases.rabbit.calibration.rabbit.face_patch[2])*float(M1HeroArt.DATA.data.atlases.rabbit.calibration.rabbit.source_scale)),"Visible skull uses Ayça's existing calibrated face size")
				var marker:=Vector2i(roundi(float(source.face_landmark[0])-float(source.bounds[0])+2.),roundi(float(source.face_landmark[1])-float(source.bounds[1])+2.))
				check(Rect2i(Vector2i.ZERO,pixels.get_size()).has_point(marker) and pixels.get_pixelv(marker).a>.5,"Reviewed open/closed-eye landmark lies on actual opaque face pixels")
			else:
				check(action=="fire" and frame==5 and float(pose.head_size)==0.,"Final ashes have no invented face/head probe")
			if action in ["impact","faceplant"]:
				check(float(pose.height)<=previous_height+1.,"Authored collapse progresses into a lower grounded pose")
				previous_height=float(pose.height)
			var hash:=pixels.get_data().hex_encode().sha256_text()
			check(not hashes.has(hash),"Each of the twenty-four drawings has distinct source pixels")
			hashes[hash]=true
	print("RESULT: %d Ayça damage art checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
