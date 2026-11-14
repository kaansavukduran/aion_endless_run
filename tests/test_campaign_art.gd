extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+message)
func largest_body(image: Image) -> Rect2i:
	var width:=image.get_width();var height:=image.get_height()
	var visited:=PackedByteArray();visited.resize(width*height)
	var largest:=0;var bounds:=Rect2i()
	for y in height:
		for x in width:
			var index:=y*width+x
			if visited[index] or image.get_pixel(x,y).a<.75:continue
			var queue:=PackedInt32Array([index]);visited[index]=1;var cursor:=0;var low:=Vector2i(x,y);var high:=low
			while cursor<queue.size():
				var at:=queue[cursor];cursor+=1;var xx:=at%width;var yy:=int(at/width)
				low=Vector2i(mini(low.x,xx),mini(low.y,yy));high=Vector2i(maxi(high.x,xx),maxi(high.y,yy))
				for offset in [Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1),Vector2i(-1,-1),Vector2i(1,-1),Vector2i(-1,1),Vector2i(1,1)]:
					var nx: int=xx+offset.x;var ny: int=yy+offset.y
					if nx<0 or nx>=width or ny<0 or ny>=height:continue
					var next: int=ny*width+nx
					if not visited[next] and image.get_pixel(nx,ny).a>=.75:visited[next]=1;queue.append(next)
			if queue.size()>largest:largest=queue.size();bounds=Rect2i(low,high-low+Vector2i.ONE)
	return bounds
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var art:=AionCampaignArt.new();var bank:=RunnerFrameBank.new()
	for hero in AionCampaignWorld.HEROES:
		var neutral: Dictionary=bank.pose("runner-"+hero,0,0)
		# The sheep's detached halo is not part of its anatomical body height.
		var approved_body:=largest_body(neutral.texture.get_image())
		var approved_height: float=approved_body.size.y*float(neutral.scale)
		var first_height:=0.
		for frame in 6:
			var pose:=art.melee(hero,frame);var image: Image=pose.texture.get_image();var bounds:=largest_body(image)
			var scale: float=art.MELEE.data.heroes[hero].scale
			var actual_bottom: float=float(pose.offset.y)+bounds.end.y*scale
			check(absf(actual_bottom)<=.001,"Actual connected body feet meet the floor, not a detached neighboring-row fragment: "+hero+"/"+str(frame))
			check(bounds.size.y>60 and bounds.size.x>50,"Attack retains a complete readable body")
			var height: float=bounds.size.y*scale
			if frame==0:first_height=height
			check(height>first_height*.68 and height<first_height*1.16,"Constant source scale preserves normal attack proportions")
			var clean:=true
			for x in image.get_width():clean=clean and image.get_pixel(x,0).a==0. and image.get_pixel(x,image.get_height()-1).a==0.
			for y in image.get_height():clean=clean and image.get_pixel(0,y).a==0. and image.get_pixel(image.get_width()-1,y).a==0.
			check(clean,"Independent attack texture has transparent sampling gutters")
		check(first_height>approved_height*.9 and first_height<approved_height*1.1,"First attack body size agrees with actual connected approved neutral: "+hero)
		check(bank.pose("gun-run",bank.hero_row(hero),0).source_key=="pixel-"+hero,"Ground/fire artwork identity agrees with selected hero")
	for row in 8:
		for frame in 6:
			var pose:=art.pose(row,frame)
			check(pose.texture.get_width()>40 and pose.texture.get_height()>40,"All 48 machine source drawings produce usable textures")
	print("RESULT: %d campaign art checks, %d failures" % [checks,failures]);quit(1 if failures else 0)
