extends SceneTree
const ButtonArt=preload("res://scripts/touch_button.gd")
const Bank=preload("res://scripts/frame_bank.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var button=ButtonArt.new();root.add_child(button)
	for dims in [80,96]:
		button.size=Vector2.ONE*dims
		for state in [0,1,2]:
			button.pressed=state==1;button.disabled=state==2
			var image: Image=button.skin_image(button.grid_size())
			var symmetric:=true;var fits:=true
			for y in image.get_height():
				for x in image.get_width():
					var opaque:=image.get_pixel(x,y).a>0
					symmetric=symmetric and opaque==(image.get_pixel(image.get_width()-1-x,y).a>0) and opaque==(image.get_pixel(x,image.get_height()-1-y).a>0)
					fits=fits and button._has_point(Vector2(x+.5,y+.5)*button.PIXEL)==opaque
			check(symmetric,"All four rim quadrants mirror exactly: "+str(dims)+"/"+str(state))
			check(fits,"Touch shape matches the rendered pixel silhouette: "+str(dims)+"/"+str(state))
	check(not button._has_point(Vector2.ZERO) and button._has_point(button.size*.5),"Rounded corners reject outside taps while the center remains usable")
	for action in ["jump","attack","duck","shoot","boost"]:
		button.action=action
		var rows: Array=button.icon_pattern();var count:=0
		for line in rows:
			check(str(line).length()==14,"Icon uses one consistent grid: "+action)
			count+=str(line).count("2")+str(line).count("3")
		check(count>30,"Each action has a readable authored silhouette: "+action)
	button.action="shoot";button.elemental=true
	check(button.icon_pattern()!=ButtonArt.ICONS.shoot,"Lightning and boss pistol remain visually distinct")
	var bank=Bank.new();var meta=bank.CREATURES.data.atlas
	check(meta.rows==4 and meta.columns==6,"Four detailed enemies each have six actual drawn poses")
	for row in 4:
		var sources:={};var scales:={};var eye_x: Array[float]=[];var floors: Array[float]=[]
		for col in 6:
			var pose: Dictionary=bank.pose("creatures",row,col)
			var spec: Dictionary=meta.frames[row][col]
			sources[pose.texture.get_image().get_data().hex_encode().sha256_text()]=true
			scales[pose.scale]=true
			var gaze: Vector2=(pose.offset+pose.eye_local)*float(pose.scale)
			eye_x.append(gaze.x)
			floors.append((pose.offset.y+pose.texture.get_height()-2)*float(pose.scale))
			check(pose.texture.get_width()>50 and pose.texture.get_height()>70,"Sprite contains detailed artwork rather than geometric placeholders: "+str(row)+"/"+str(col))
			check(pose.texture.get_image().get_pixel(0,0).a==0,"Each sprite has independently transparent padding")
		check(sources.size()>=5,"Poses really change across the animation cycle: "+str(row))
		check(scales.size()==1,"Scale stays constant for the entire enemy cycle: "+str(row))
		check(eye_x.max()-eye_x.min()<.001,"Horizontal face registration remains stable: "+str(row))
		if row in [1,2]:check(floors.max()-floors.min()<.001,"Ground enemies retain one shared foot baseline: "+str(row))
	button.queue_free();await process_frame
	print("RESULT: %d visual polish checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
