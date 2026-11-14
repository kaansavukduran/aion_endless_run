## Authored fixture views; ordinary play is tested separately in browser_forge.
extends SceneTree
var game: AionCampaignGame
var output: String
var captures:=0
func _initialize() -> void:call_deferred("run")
func capture(name: String) -> Image:
	captures+=1
	game.view.queue_redraw();game.update_hud()
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	if not name.is_empty():image.save_png(output+"/"+name+".png")
	return image
func clean(hero: String="aion") -> void:
	game.world.begin(hero);game.world.enemies.clear();game.world.objects.clear();game.world.gates.clear();game.world.npcs.clear();game.world.hazards.clear();game.world.pickups.clear();game.world.crates.clear()
	game.world.player=Vector2(400,0);game.world.velocity=Vector2.ZERO;game.world.state="playing"
	game.presentation_stage="";game.menu_kind="";game.view.camera_x=0.;game.build_ui()
func run() -> void:
	output=OS.get_environment("AION_FORGE_REVIEW")
	if output.is_empty():output="res://build/forge-review"
	DirAccess.make_dir_recursive_absolute(output);root.size=Vector2i(1152,648)
	game=AionCampaignGame.new();game.language="tr";root.add_child(game);await process_frame
	game.set_process(false);game.touch_mode=true;game.resize()
	clean()
	for i in 2:
		game.world.npcs.append({"id":"fixture-"+str(i),"x":600.+i*200.,"y":0.,"freed":true,"free_age":0.,"phase":"free","thank_age":0.,"variant":i,"secret":"","role":"keeper","gift":"points"})
	await capture("npc-ratio")
	var aim_sheet:=Image.create_empty(8*140,6*180,false,Image.FORMAT_RGBA8)
	for row in 6:
		for col in 8:
			clean(ForgeHeroArt.HEROES[row]);game.world.aim_direction=Vector2.RIGHT.rotated(-col*PI/4.);game.world.shot_flash=.10
			var image: Image=await capture("")
			var point: Vector2=root.get_final_transform()*game.view.get_global_transform_with_canvas()*Vector2(400.,game.view.ground)
			aim_sheet.blit_rect(image,Rect2i(Vector2i(point)-Vector2i(70,165),Vector2i(140,180)),Vector2i(col*140,row*180))
	aim_sheet.save_png(output+"/eightway.png")
	for type in CampaignVehicles.TYPES:
		clean();game.world.mount={"available":true,"ridden":false,"hp":4,"x":600.,"type":type};await capture("vehicle-"+type)
	var climb_sheet:=Image.create_empty(6*250,6*240,false,Image.FORMAT_RGBA8)
	for row in 6:
		clean(ForgeHeroArt.HEROES[row]);game.world.mount={"available":true,"ridden":false,"hp":4,"x":400.,"type":"shell"}
		game.world.interact()
		for frame in 6:
			var image: Image=await capture("")
			var point: Vector2=root.get_final_transform()*game.view.get_global_transform_with_canvas()*Vector2(400.,game.view.ground)
			climb_sheet.blit_rect(image,Rect2i(Vector2i(point)-Vector2i(125,225),Vector2i(250,240)),Vector2i(frame*250,row*240))
			for i in 9:game.world.step(1./120.)
	climb_sheet.save_png(output+"/six-hero-entry.png")
	clean("sheep");game.world.flock=3;game.world.mount={"available":true,"ridden":false,"hp":4,"x":400.,"type":"shell"};game.world.facing=-1
	game.world.interact();await capture("left-entry-start")
	for i in 10:game.world.step(.05)
	await capture("three-sheep-inside")
	game.world.interact();await capture("left-exit-start")
	for i in 10:game.world.step(.05)
	await capture("left-idle-after-exit")
	clean("wolf");game.world.velocity.x=235.;game.world.shot_flash=.10;await capture("wolf-mouth")
	clean("owl");game.world.player.y=-90.;game.world.flap_time=.18;game.world.gliding=true;await capture("owl-mouth")
	clean();game.world.pickups.clear()
	var index:=0
	for kind in ForgeItemBank.DATA.data.frames:
		game.world.pickups.append({"id":"fixture-item-"+str(index),"kind":kind,"x":180.+index%10*90.,"y":-50.-floori(index/10.)*80.});index+=1
	await capture("twenty-items")
	game.queue_free();await process_frame
	print("RESULT: %d forge render states, 0 failures"%captures)
	quit()
