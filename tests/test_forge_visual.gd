extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var view:=AionCampaignView.new()
	var decoded_before:=RunnerSourcePixels.decodes
	var reference: float=view.hero_reference_height()
	check(RunnerSourcePixels.decodes==decoded_before,"Reading Aion's registration does not decode a texture while drawing an NPC")
	check(is_equal_approx(reference,float(view.frames.pose("gun-run",view.frames.hero_row("aion"),0).height)),"Metadata-only reference exactly matches the drawn silhouette")
	for row in 8:
		check(is_equal_approx(view.npc_growth(row)*view.npc_reference_height(row),reference*1.75),"Actual upright NPC body is 1.75 times Aion, excluding padding: "+str(row))
	for type in CampaignVehicles.TYPES:
		var old_growth: float=-1.
		for phase in (2 if type=="skimmer" else 4):
			for frame in 6:
				var pose: Dictionary=view.vehicle_pose(type,phase,frame)
				var growth: float=pose.vehicle_growth
				if old_growth<0.:old_growth=growth
				check(is_equal_approx(old_growth,growth),"Vehicle scale remains fixed across recoil/damage/wreck: "+type)
				var data: Dictionary=ForgeVehicleArt.DATA.data.types[type]
				var f: Dictionary=data.frames[phase][frame]
				var b: Array=f.body_bounds
				var metrics: Dictionary=ForgeVehicleArt.anchors(type,phase,frame,reference*2.)
				var foot_y: float=float(pose.offset.y)+(float(b[3]-f.bounds[1])+2.)*float(metrics.scale)
				check(absf(foot_y)<.001,"Visible opaque vehicle feet contact real support: "+type)
				if phase==0 and frame==0:check(is_equal_approx(float(b[3]-b[1])*float(metrics.scale),reference*2.),"Actual vehicle body is exactly twice Aion: "+type)
	var items:=ForgeItemBank.new()
	var hashes: Dictionary={}
	for kind in items.DATA.data.frames:
		var p: Dictionary=items.pose(kind)
		var image: Image=p.texture.get_image()
		var maximum: float=maxf(p.size.x,p.size.y)
		check(maximum>=46. and maximum<49.,"Readable but compact item silhouette: "+str(kind))
		check(image.get_pixel(0,0).a==0. and image.get_pixel(image.get_width()-1,image.get_height()-1).a==0.,"Independent transparent sampling gutter: "+str(kind))
		hashes[hash(image.get_data())]=true
	check(hashes.size()==20,"Twenty distinct genuine pickups, no repeated generic rectangles")
	check(FileAccess.get_sha256("res://assets/forge-items.png")==items.DATA.data.sha256,"Registered item source remains byte-identical")
	for facing in [-1,1]:
		var w:=AionCampaignWorld.new();w.begin("aion");w.load_section("water");w.state="playing";w.facing=facing
		w.enemies.clear();w.npcs.clear();w.hazards.clear();w.gates.clear();w.objects.clear()
		w.player=Vector2(float(w.mount.x)-70.*facing,0.)
		view.world=w
		check(w.interact(),"Ordinary mount action begins entry")
		for step in 10:
			check(absf(view.vehicle_draw_position().y)<.001,"Entry never applies the rider's +42 saddle offset to the hull")
			check(view.vehicle_draw_facing()==facing,"Vehicle body and foreground hatch face identically")
			w.step(.05)
		check(w.interact(),"Ordinary mount action begins exit")
		for step in 10:
			check(view.vehicle_draw_facing()==facing,"Left/right exit cannot flip the main hull against its foreground")
			w.step(.05)
		check(view.vehicle_draw_facing()==facing,"Idle hull retains its last actual exit direction")
	view.free()
	print("RESULT: %d forge scale/art checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
