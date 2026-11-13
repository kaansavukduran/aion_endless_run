extends SceneTree
const Bank=preload("res://scripts/frame_bank.gd")
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
				if logical!="rolls":probes.append(sprite.get_meta("head_probe_world"))
			for p in probes:check(p.distance_to(probes[0])<.001,"Independent nose/cheek probe remains registered")
		check(texture_hashes.size()==18,"All eighteen live run/fire/roll drawings are distinct: "+hero)
		check(bank.pose("rolls",index,5).height<bank.pose("runner-"+hero,0,0).height*.9,"Final held crouch is visibly low: "+hero)
	for probe in bank.PIXEL.data.face_registration:
		check(float(probe.residual)<.15,"Whole-face source pixel fit remains inside reviewed error: "+str(probe.hero))
	sprite.free()
	print("RESULT: %d pixel hero checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
