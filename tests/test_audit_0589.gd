## 0.58.9 audit fix: a hero never respawns with an empty sidearm.
extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+label)
func world() -> AionCampaignWorld:
	var w:=AionCampaignWorld.new();w.begin("aion");w.run_seed=7719;w.load_section("shore")
	return w
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var w:=world();w.weapon="rocket";w.ammunition=2;w.pistol_reserve=0
	CampaignLives.lethal(w,"test")
	check(w.weapon=="pistol" and w.ammunition==CampaignLives.EMPTY_RESPAWN_ROUNDS,"A rocket with rounds left over an empty sidearm respawns with the floor: "+str(w.ammunition))
	w=world();w.weapon="pistol";w.ammunition=0;w.pistol_reserve=0
	CampaignLives.lethal(w,"test")
	check(w.ammunition==CampaignLives.EMPTY_RESPAWN_ROUNDS,"An empty pistol still respawns with the floor")
	w=world();w.weapon="rocket";w.ammunition=2;w.pistol_reserve=20
	CampaignLives.lethal(w,"test")
	check(w.ammunition==20,"A stocked sidearm keeps its own rounds")
	w=world();w.weapon="pistol";w.ammunition=0;w.attempts_remaining=1
	CampaignLives.lethal(w,"test")
	check(w.attempts_remaining==0 and w.ammunition==0,"The final life grants no floor rounds")
	print("RESULT: %d audit checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
