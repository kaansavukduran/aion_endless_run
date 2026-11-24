extends SceneTree
# Export the canonical idle poses and small enemy poses used by the arcade sheets.
# godot --headless --script packaging/m1_arcade_sprite_sources.gd -- /path/to/staging
func _initialize() -> void:
	var args:=OS.get_cmdline_user_args()
	if args.size()!=1:quit(1);return
	var out:=str(args[0])
	DirAccess.make_dir_recursive_absolute(out)
	for hero in AionCampaignWorld.HEROES:
		var pose: Dictionary=M1HeroArt.new().pose(hero,"idle_fire",0)
		pose.texture.get_image().save_png(out+"/body-"+hero+".png")
		print(hero, " ", pose.texture.get_size(), " ", pose.face_local, " ", pose.offset)
	var frames:=RunnerFrameBank.new()
	for spec in [["gnome","enemies",3],["crow","enemies",0],["beetle","creatures",2],["slime","creatures",1]]:
		var pose: Dictionary=frames.pose(spec[1],spec[2],0)
		pose.texture.get_image().save_png(out+"/foe-"+spec[0]+".png")
		print(spec[0]," ",pose.texture.get_size())
	quit()
