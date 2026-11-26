## 0.58.7 audit fixes: the relay opening check before the scout has woken,
## and every rescue gift has art for its hand-over arc.
extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var w:=AionCampaignWorld.new();w.begin("aion");w.run_seed=7719;w.load_section("relay")
	var drone: Dictionary={};var scout: Dictionary={}
	for e in w.enemies:
		if e.id==CampaignContent.RELAY_DRONE:drone=e
		if e.id==CampaignContent.RELAY_SCOUT:scout=e
	check(not drone.is_empty() and not scout.is_empty(),"Relay drone and scout exist")
	scout.erase("flash");scout.windup=0.;scout.erase("recover")
	check(CampaignContent.relay_opening_blocked(w,drone)==false,"The drone's opening check works before the scout has ever flashed")
	scout.flash=.2
	check(CampaignContent.relay_opening_blocked(w,drone)==true,"A flashing scout still blocks the drone's opening")
	# Every rescue gift must be drawable by the hand-over animation.
	var kinds:={}
	for section in AionCampaignWorld.STAGES:
		w.load_section(section)
		for npc in w.npcs:
			if npc.has("gift"):kinds[str(npc.gift)]=section
	for kind in kinds:
		var drawable: bool=kind=="relay_part" or kind in ["rocket","pistol_ammo"] or ForgeItemBank.SUPPLY_CELLS.has(kind) or ForgeItemBank.DATA.data.frames.has(kind)
		check(drawable,"Rescue gift has hand-over art: %s (%s)"%[kind,kinds[kind]])
	check(kinds.has("relay_part"),"The technician's relay part gift is covered")
	var view_source:=FileAccess.get_file_as_string("res://scripts/campaign_view.gd")
	check(view_source.contains("if str(npc.gift)==\"relay_part\":CampaignRoutes.draw_part"),"The relay part gift is drawn with its pickup art")
	print("RESULT: %d audit checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
