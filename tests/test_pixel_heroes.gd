extends SceneTree
const Bank=preload("res://scripts/frame_bank.gd")
const World=preload("res://scripts/world.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+message)
func _initialize():call_deferred("run")
func run():
	var bank=Bank.new()
	var sprite=Sprite2D.new();sprite.centered=false
	for hero in ["aion","owl","sheep","wolf","rabbit","eren"]:
		var a: Dictionary=bank.PIXEL.data.atlases["pixel-"+hero]
		check(a.physical_rows==11 and a.frames.size()==12 and a.row_counts.slice(0,11).all(func(n):return int(n)==6) and a.frames.slice(0,11).all(func(line):return line.size()==6),"Eleven complete authored six-pose clips, plus an explicit reused enemy-fall timeline: "+hero)
		var texture_hashes: Dictionary={}
		for row in 11:
			check(is_equal_approx(a.scale[row],a.scale[0]),"One character scale across every action, death and special: "+hero+str(row))
			for col in 6:
				var frame: Dictionary=a.frames[row][col]
				var pose: Dictionary=bank.pose("runner-"+hero,0,col) if row==0 else {}
				# Review crop coverage itself, including a high ear or airborne foot.
				check(frame.bounds[0]>0 and frame.bounds[1]>0 and frame.bounds[2]<frame.rect[2] and frame.bounds[3]<frame.rect[3],"No silhouette touches a crop edge: "+hero+"/"+str(row)+"/"+str(col))
				check(not frame.runs.is_empty(),"Source silhouette spans exist")
		var index: int=["aion","owl","sheep","wolf","rabbit","eren"].find(hero)
		for logical in ["gun-run","gun-fire","rolls"]:
			var first:=bank.pose(logical,index,0)
			var probes:=[]
			for col in 6:
				bank.place(sprite,logical,index,col,Vector2(288,500))
				var pose:=bank.pose(logical,index,col)
				texture_hashes[hash(pose.texture.get_image().get_data())]=true
				check(sprite.position==Vector2(288,500) and is_equal_approx(sprite.scale.x,a.scale[0]),"No actor-position or scaling compensation: "+hero+"/"+logical)
				check(pose.source_key=="pixel-"+hero,"The actual renderer selects this hero's new drawing")
				if logical!="rolls":
					probes.append(sprite.get_meta("head_probe_world"))
					var source: Dictionary=a.frames[3 if logical=="gun-run" else 4][col]
					check(absf((source.body_bounds[3]-source.origin[1])*a.scale[0])<.001,"Opaque foot contacts the fixed ground in every run/fire pose: "+hero+"/"+logical+"/"+str(col))
			for p in probes:check(absf(p.x-probes[0].x)<.001,"Independent nose/cheek probe stays horizontally registered while planted feet allow natural vertical stride")
		check(texture_hashes.size()==18,"All eighteen live run/fire/roll drawings are distinct: "+hero)
		check(bank.pose("rolls",index,5).height<bank.pose("runner-"+hero,0,0).height*.9,"Recovery pose is visibly low: "+hero)
		for state_row in [3,4]:
			for col in 6:
				var element:=bank.pose("runner-"+hero,state_row,col)
				var registered: bool=element.has("probe_local")
				if registered:registered=is_equal_approx((element.offset.x+element.probe_local.x)*element.scale,(a.target_eye[0]-15*a.scale[0]))
				check(registered,"Element effects keep the actual face horizontally registered: "+hero+"/"+str(state_row)+"/"+str(col))
	for probe in bank.PIXEL.data.face_registration:
		check(float(probe.residual)<(.35 if int(probe.row)==7 else .15),"Whole-face source pixel fit remains inside reviewed error: "+str(probe.hero))
	sprite.free()
	# Exercise the real scene selector as well as the bank. These are explicit
	# deterministic damage-state fixtures, separate from normal-input browsers.
	var game=load("res://main.tscn").instantiate();root.add_child(game);await process_frame;game.set_physics_process(false)
	for hero in ["aion","owl","sheep","wolf","rabbit","eren"]:
		game.character=hero;game.world.character=hero
		for state in ["ice","fire"]:
			game.world.state=state
			var first_x: float=-9999
			for col in 6:
				game.world.hit_time=col*.7/5;game.update_friend()
				var item: Sprite2D=game.friend_sprite
				var probe: Vector2=item.get_meta("head_probe_world")
				if col==0:first_x=probe.x
				check(item.get_meta("source_key")=="pixel-"+hero and item.get_meta("source_row")== (7 if state=="ice" else 8) and is_equal_approx(probe.x,first_x) and is_equal_approx(item.position.x,World.PLAYER_X),"Actual scene selects a fixed elemental face at a fixed actor origin: "+hero+"/"+state+"/"+str(col))
	game.queue_free();await process_frame
	print("RESULT: %d pixel hero checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
