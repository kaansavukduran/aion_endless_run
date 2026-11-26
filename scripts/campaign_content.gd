class_name CampaignContent
extends RefCounted

## Draft game-content identities, not new approved AIONIA canon.
const REGIONS := {"water":["leech","hopper","siphon"],"terrace":["kite","mirror","vine"],"roots":["burrow","conductor","mimic"]}
const HEAVIES := ["sweeper","glider","borer","patrol"]
const NEW_ENEMIES := {
	"leech":{"family":"canal","atlas":"water-enemies","row":0,"radius":30.,"range":140.,"speed":120.,"flying":false},
	"hopper":{"family":"canal","atlas":"water-enemies","row":4,"radius":28.,"range":260.,"speed":110.,"flying":false},
	"siphon":{"family":"canal","atlas":"water-enemies","row":8,"radius":28.,"range":360.,"speed":65.,"flying":true},
	"kite":{"family":"garden","atlas":"garden-enemies","row":0,"radius":32.,"range":440.,"speed":105.,"flying":true},
	"mirror":{"family":"garden","atlas":"garden-enemies","row":4,"radius":32.,"range":300.,"speed":45.,"flying":false},
	"vine":{"family":"garden","atlas":"garden-enemies","row":8,"radius":35.,"range":230.,"speed":0.,"flying":false},
	"burrow":{"family":"roots","atlas":"root-enemies","row":0,"radius":30.,"range":230.,"speed":90.,"flying":false},
	"conductor":{"family":"roots","atlas":"root-enemies","row":4,"radius":32.,"range":400.,"speed":35.,"flying":false},
	"mimic":{"family":"roots","atlas":"root-enemies","row":8,"radius":34.,"range":180.,"speed":140.,"flying":false}
}
const SCENES := {"water":["moss_water","deep_channel","sunken_station"],"terrace":["hanging_gardens","wind_terraces","glass_greenhouse"],"roots":["root_corridor","crystal_hollow","drill_chamber"]}
const OBJECTS := ["planks","gate","lamp","relay","bridge","current","updraft","rock","surprise","cage","turret","panel"]
const TURRET_CYCLE := 3.
const TURRET_WARNING := .8
const TURRET_SAFE_RANGE := 140.
const TURRET_RANGE := 500.

## Handcrafted 8-encounter arcs per leaf route (0.31.0).
## Each beat pairs a clear cue -> player decision -> counterplay -> reward,
## replacing equal-interval 5-enemy blobs and monotonous geometry wallpaper.
const LEAF_PLANS := {
	"water": [
		{"ratio":0.10,"role":"teach_leech","enemies":[["leech",0.,0.],["leech",210.,0.]],"platforms":[[60.,-72.,165.]],"crate":340.,"fruit":[40.,-112.,3]},
		{"ratio":0.20,"role":"teach_hopper","enemies":[["hopper",0.,0.],["hopper",240.,0.],["slime",410.,0.]],"platforms":[[120.,-75.,150.],[340.,-120.,145.]],"pit":[165.,255.],"fruit":[175.,-115.,3]},
		{"ratio":0.29,"role":"teach_siphon","enemies":[["siphon",60.,-125.],["leech",250.,0.],["siphon",440.,-135.]],"platforms":[[0.,-68.,155.],[280.,-95.,175.]],"crate":490.},
		{"ratio":0.40,"role":"current_combo","enemies":[["leech",0.,0.],["hopper",195.,0.],["siphon",360.,-125.],["seed",510.,-72.]],"platforms":[[455.,-72.,150.],[120.,-85.,155.]],"pit":[230.,325.],"fruit":[235.,-125.,3]},
		{"ratio":0.52,"role":"channel_ambush","enemies":[["hopper",0.,0.],["siphon",165.,-130.],["beetle",320.,0.],["leech",470.,0.]],"platforms":[[70.,-78.,170.],[310.,-132.,165.]],"crate":560.},
		{"ratio":0.63,"role":"heavy_sweeper","enemies":[["siphon",90.,-130.],["leech",260.,0.],["hopper",450.,0.]],"platforms":[[40.,-75.,160.],[290.,-125.,165.]],"crate":-120.,"fruit":[70.,-118.,3]},
		{"ratio":0.76,"role":"sluice_gauntlet","enemies":[["hopper",0.,0.],["siphon",180.,-135.],["leech",340.,0.],["drone",490.,-125.]],"platforms":[[95.,-80.,165.],[345.,-78.,170.]],"pit":[220.,310.],"crate":580.},
		{"ratio":0.87,"role":"water_exam","enemies":[["leech",0.,0.],["hopper",165.,0.],["siphon",315.,-130.],["hopper",460.,0.],["siphon",580.,-115.]],"platforms":[[120.,-78.,165.],[360.,-128.,175.]],"crate":-140.,"fruit":[145.,-118.,4]}
	],
	"terrace": [
		{"ratio":0.10,"role":"teach_kite","enemies":[["kite",40.,-125.],["kite",260.,-135.]],"platforms":[[80.,-75.,165.],[265.,-135.,155.]],"crate":360.,"fruit":[95.,-115.,3]},
		{"ratio":0.20,"role":"teach_mirror","enemies":[["mirror",80.,0.],["crow",290.,-120.]],"platforms":[[0.,-72.,155.],[210.,-132.,160.]],"pit":[135.,230.],"fruit":[145.,-112.,3]},
		{"ratio":0.29,"role":"teach_vine","enemies":[["vine",110.,0.],["kite",285.,-130.],["vine",450.,0.]],"platforms":[[40.,-82.,165.],[275.,-138.,170.]],"crate":520.},
		{"ratio":0.40,"role":"updraft_combo","enemies":[["kite",0.,-135.],["mirror",190.,0.],["vine",370.,0.],["moth",500.,-125.]],"platforms":[[90.,-78.,160.],[270.,-142.,170.]],"pit":[205.,295.],"fruit":[215.,-175.,3]},
		{"ratio":0.52,"role":"garden_vantage","enemies":[["mirror",0.,0.],["kite",185.,-135.],["seed",350.,-75.],["vine",495.,0.]],"platforms":[[295.,-75.,155.],[85.,-132.,165.]],"crate":570.},
		{"ratio":0.63,"role":"heavy_glider","enemies":[["kite",110.,-135.],["vine",290.,0.],["mirror",470.,0.]],"platforms":[[55.,-78.,165.],[260.,-138.,175.]],"crate":-120.,"fruit":[75.,-120.,3]},
		{"ratio":0.76,"role":"gust_gauntlet","enemies":[["vine",0.,0.],["kite",175.,-135.],["mirror",345.,0.],["drone",500.,-125.]],"platforms":[[105.,-78.,165.],[310.,-140.,165.]],"pit":[220.,315.],"crate":585.},
		{"ratio":0.87,"role":"terrace_exam","enemies":[["kite",0.,-130.],["mirror",170.,0.],["vine",330.,0.],["kite",470.,-138.],["mirror",590.,0.]],"platforms":[[90.,-78.,165.],[300.,-138.,180.]],"crate":-140.,"fruit":[115.,-118.,4]}
	],
	"roots": [
		{"ratio":0.10,"role":"teach_burrow","enemies":[["burrow",40.,0.],["burrow",275.,0.]],"platforms":[[110.,-72.,165.]],"crate":370.,"fruit":[130.,-112.,3]},
		{"ratio":0.20,"role":"teach_conductor","enemies":[["conductor",150.,0.],["beetle",320.,0.],["burrow",460.,0.]],"platforms":[[60.,-75.,160.],[285.,-122.,155.]],"fruit":[85.,-115.,3]},
		{"ratio":0.29,"role":"teach_mimic","enemies":[["mimic",70.,0.],["burrow",260.,0.],["wisp",430.,-120.]],"platforms":[[130.,-76.,165.],[340.,-120.,155.]],"crate":510.},
		{"ratio":0.40,"role":"dark_combo","enemies":[["burrow",0.,0.],["conductor",195.,0.],["mimic",365.,0.],["seed",515.,-72.]],"platforms":[[460.,-72.,150.],[125.,-82.,160.]],"fruit":[150.,-122.,3]},
		{"ratio":0.52,"role":"hollow_ambush","enemies":[["mimic",0.,0.],["burrow",175.,0.],["conductor",350.,0.],["slime",490.,0.]],"platforms":[[85.,-76.,165.],[305.,-126.,165.]],"crate":565.},
		{"ratio":0.63,"role":"heavy_borer","enemies":[["conductor",100.,0.],["burrow",290.,0.],["mimic",470.,0.]],"platforms":[[45.,-78.,165.],[270.,-128.,170.]],"crate":-120.,"fruit":[65.,-120.,3]},
		{"ratio":0.76,"role":"crystal_gauntlet","enemies":[["burrow",0.,0.],["mimic",185.,0.],["conductor",365.,0.],["wisp",515.,-125.]],"platforms":[[100.,-76.,165.],[325.,-124.,170.]],"crate":590.},
		{"ratio":0.87,"role":"roots_exam","enemies":[["burrow",0.,0.],["conductor",175.,0.],["mimic",335.,0.],["burrow",475.,0.],["mimic",600.,0.]],"platforms":[[115.,-76.,165.],[345.,-126.,180.]],"crate":-140.,"fruit":[135.,-118.,4]}
	]
}

## Handcrafted main-path encounters (0.35.0 -> 0.45.0) for shore, quay, canopy, and relay.
## Replaces uniform platform/crate/fruit grid wallpaper with readable sightline,
## flank, mechanism, and move-and-shoot encounters. Shore avoids x 5780..6490
## to keep the required ravine crossing clear.
const MAIN_PLANS := {
	"shore": [
		{"x":1850.,"role":"shore_priority","enemies":[["gnome",0.,0.],["lantern_scout",220.,0.],["gnome",360.,0.]],"platforms":[[110.,-70.,175.]],"crate":420.,"fruit":[130.,-112.,3],"gate":true},
		{"x":3150.,"role":"shore_vertical","enemies":[["crow",60.,-120.],["gnome",210.,0.],["cap_lobber",390.,0.],["crow",500.,-130.]],"platforms":[[40.,-72.,165.],[240.,-135.,170.]],"prop":["bridge",180.],"fruit":[65.,-112.,3],"gate":false},
		{"x":4450.,"role":"shore_pre_bridge","enemies":[["beetle",0.,0.],["seed",215.,0.],["crow",350.,-125.],["beetle",495.,0.]],"platforms":[[120.,-75.,170.],[340.,-128.,160.]],"prop":["turret",320.],"crate":560.,"fruit":[140.,-115.,3],"gate":false},
		{"x":6680.,"role":"shore_finish","enemies":[["beetle",0.,0.],["seed",190.,0.],["crow",330.,-120.],["seed",470.,0.]],"platforms":[[90.,-75.,175.]],"crate":530.,"fruit":[115.,-115.,3],"gate":true}
	],
	"quay": [
		{"x":2150.,"role":"quay_skimmer_intro","enemies":[["gnome",0.,0.],["drone",190.,-120.],["gnome",350.,0.]],"platforms":[[120.,-82.,170.]],"crate":430.,"fruit":[145.,-122.,3],"gate":false},
		{"x":4100.,"role":"quay_armour_air","enemies":[["beetle",0.,0.],["drone",180.,-125.],["beetle",350.,0.],["drone",510.,-120.]],"platforms":[[95.,-84.,175.],[310.,-136.,165.]],"crate":580.,"fruit":[115.,-124.,3],"gate":false},
		{"x":6250.,"role":"quay_crossfire","enemies":[["seed",0.,0.],["beetle",205.,0.],["drone",355.,-125.],["seed",505.,0.]],"platforms":[[140.,-82.,175.],[360.,-138.,165.]],"prop":["turret",315.],"crate":565.,"fruit":[380.,-178.,3],"gate":false},
		{"x":7950.,"role":"quay_approach","enemies":[["drone",40.,-125.],["beetle",200.,0.],["gnome",340.,0.],["beetle",490.,0.],["drone",610.,-120.]],"platforms":[[120.,-84.,175.],[355.,-132.,170.]],"crate":-130.,"fruit":[145.,-124.,3],"gate":false}
	],
	"canopy": [
		{"x":1250.,"role":"canopy_high_entry","enemies":[["crow",0.,-120.],["seed",210.,0.],["crow",380.,-130.]],"platforms":[[70.,-74.,165.],[265.,-136.,165.]],"crate":440.,"fruit":[90.,-114.,3],"gate":true},
		{"x":2350.,"role":"canopy_gauntlet","enemies":[["moth",0.,-125.],["drone",195.,-125.],["seed",365.,0.],["crow",515.,-120.]],"platforms":[[80.,-76.,165.],[285.,-138.,175.]],"prop":["updraft",160.],"crate":575.,"fruit":[300.,-178.,3],"gate":true}
	],
	"causeway": [
		{"x":900.,"role":"causeway_low_approach","enemies":[["beetle",120.,0.],["gnome",340.,0.]],"platforms":[[40.,-45.,130.],[205.,-92.,140.]],"prop":["cage",90.],"vacant_cage":true,"crate":410.,"fruit":[55.,-84.,3]},
		{"x":1550.,"role":"causeway_cover","enemies":[["lantern_scout",180.,0.],["beetle",390.,0.]],"platforms":[[75.,-74.,152.],[249.,-116.,178.]],"prop":["turret",410.],"crate":-75.,"fruit":[265.,-155.,3]},
		{"x":2330.,"role":"causeway_relay_approach","enemies":[["gnome",95.,0.],["seed",280.,0.],["beetle",510.,0.]],"platforms":[[35.,-128.,150.],[232.,-89.,164.],[426.,-48.,153.]],"crate":640.,"fruit":[255.,-128.,3]}
	],
	"relay": [
		{"x":2050.,"role":"relay_rejoin","enemies":[["drone",0.,-120.],["beetle",195.,0.],["seed",375.,0.],["drone",520.,-125.]],"platforms":[[110.,-76.,170.],[320.,-132.,165.]],"crate":585.,"fruit":[130.,-116.,3],"gate":true},
		{"x":4150.,"role":"relay_lanes","enemies":[["seed",0.,0.],["gnome",180.,0.],["drone",330.,-125.],["seed",480.,0.],["gnome",610.,0.]],"platforms":[[64.,-102.,145.],[380.,-145.,175.]],"prop":["planks",220.],"fruit":[395.,-184.,3],"gate":false},
		{"x":6250.,"role":"relay_patrol_support","enemies":[["beetle",0.,0.],["drone",210.,-125.],["beetle",390.,0.],["drone",540.,-120.]],"platforms":[[95.,-78.,170.],[310.,-132.,170.]],"crate":590.,"fruit":[115.,-118.,3],"gate":false},
		{"x":8200.,"role":"relay_breach","enemies":[["drone",0.,-125.],["beetle",175.,0.],["seed",335.,0.],["beetle",490.,0.],["drone",615.,-125.]],"platforms":[[105.,-78.,175.],[330.,-134.,175.]],"prop":["turret",310.],"crate":-130.,"fruit":[125.,-118.,3],"gate":true}
	]
}

static func flying(kind: String) -> bool:
	return kind in ["crow","moth","drone","wisp","glider",CampaignHive.KIND] or (NEW_ENEMIES.has(kind) and bool(NEW_ENEMIES[kind].flying))

static func populate(w) -> void:
	w.encounters.clear();w.objects.clear();w.zones.clear();w.rooms.clear();w.hazards.clear()
	var regional: Array=REGIONS.get(w.section,[])
	var is_leaf: bool=not regional.is_empty()
	if not is_leaf and w.section!="arena":regional=["gnome","seed","crow"] if w.section!="quay" else ["drone","beetle","gnome"]
	if is_leaf:
		var plans: Array=LEAF_PLANS.get(w.section,[])
		var rhythm_rng:=RandomNumberGenerator.new();rhythm_rng.seed=w.run_seed+abs(w.section.hash())+1703
		var crate_index:=0
		for i in plans.size():
			var plan: Dictionary=plans[i]
			var x: float=clampf(w.length()*float(plan.ratio),1350.,w.length()-1650.)
			var variant: int=rhythm_rng.randi_range(0,2)
			if i>0 and i<plans.size()-1:x+=rhythm_rng.randf_range(-90.,90.)
			if plan.has("pit"):
				var pit_spec: Array=plan.pit
				var px: float=x+float(pit_spec[0]);var px_end: float=x+float(pit_spec[1])
				w.pits.append(Vector2(px,px_end))
				w.platforms.append(Rect2(px+10.,-56.,maxf(68.,px_end-px-20.),18.))
			for plat in plan.get("platforms",[]):
				w.platforms.append(Rect2(x+float(plat[0]),float(plat[1]),float(plat[2]),18.))
			var ids: Array[String]=[]
			var roster: Array=plan.get("enemies",[])
			var jitter: float=[-18.,0.,22.][variant]
			for k in roster.size():
				var entry: Array=roster[k]
				var kind: String=str(entry[0])
				var ex: float=x+float(entry[1])+(jitter if k>0 else 0.)
				var ey: float=float(entry[2])
				w.spawn_enemy(kind,ex,ey,300+i*10+k)
				ids.append(w.section+":enemy:"+str(300+i*10+k))
			if plan.has("crate"):
				var cx: float=x+float(plan.crate)
				if CampaignGround.has_floor(w.floor_at(cx)):
					var cid: String=w.section+":crate:"+str(crate_index)
					if not w.taken.has(cid):w.crates.append({"id":cid,"x":cx,"y":0.,"kind":"heavy","hp":1})
					crate_index+=1
			if plan.has("fruit"):
				var fspec: Array=plan.fruit
				for j in int(fspec[2]):
					var fid: String=w.section+":arc-fruit:"+str(i)+":"+str(j)
					if not w.taken.has(fid):w.pickups.append({"id":fid,"x":x+float(fspec[0])+j*46.,"y":float(fspec[1]),"kind":"fruit_"+str((i+j)%8)})
			# Lock gates on escalating beats and exams, leaving early teaching beats fluid.
			if i in [2,3,5,6,7]:w.gates.append({"x":x+670.,"ids":ids})
			w.encounters.append({"id":w.section+":encounter:"+str(i),"x":x,"variant":variant,"role":str(plan.role),"scene":SCENES[w.section][clampi(int(i*3/plans.size()),0,2)],"enemies":ids})
	elif MAIN_PLANS.has(w.section):
		var plans: Array=MAIN_PLANS[w.section]
		var rhythm_rng:=RandomNumberGenerator.new();rhythm_rng.seed=w.run_seed+abs(w.section.hash())+1703
		var main_crate_index:=0
		for i in plans.size():
			var plan: Dictionary=plans[i]
			var x: float=float(plan.x)
			var variant: int=rhythm_rng.randi_range(0,2)
			var jitter: float=[-16.,0.,18.][variant]
			for plat in plan.get("platforms",[]):
				w.platforms.append(Rect2(x+float(plat[0]),float(plat[1]),float(plat[2]),18.))
			if plan.has("prop"):
				var pspec: Array=plan.prop
				var pkind: String=str(pspec[0]);var px: float=x+float(pspec[1])
				if CampaignGround.has_floor(w.floor_at(px)):
					var pid: String=w.section+":tactic:"+str(i)
					var vacant: bool=bool(plan.get("vacant_cage",false))
					w.objects.append({"id":pid,"kind":pkind,"x":px,"y":0.,"hp":2,"active":vacant or w.activated.has(pid),"secret":"","vacant":vacant})
					if pkind=="planks":w.platforms.append(Rect2(px-80.,-55.,160.,18.))
			var ids: Array[String]=[]
			var roster: Array=plan.get("enemies",[])
			for k in roster.size():
				var entry: Array=roster[k]
				var kind: String=str(entry[0])
				w.spawn_enemy(kind,x+float(entry[1])+(jitter if k>0 else 0.),float(entry[2]),300+i*10+k)
				ids.append(w.section+":enemy:"+str(300+i*10+k))
			if plan.has("crate"):
				var cx: float=x+float(plan.crate)
				if CampaignGround.has_floor(w.floor_at(cx)):
					var cid: String=w.section+":crate:"+str(main_crate_index)
					if not w.taken.has(cid):w.crates.append({"id":cid,"x":cx,"y":0.,"kind":"heavy","hp":1})
					main_crate_index+=1
			if plan.has("fruit"):
				var fspec: Array=plan.fruit
				for j in int(fspec[2]):
					var fid: String=w.section+":arc-fruit:"+str(i)+":"+str(j)
					if not w.taken.has(fid):w.pickups.append({"id":fid,"x":x+float(fspec[0])+j*46.,"y":float(fspec[1]),"kind":"fruit_"+str((i+j)%8)})
			if bool(plan.get("gate",false)):w.gates.append({"x":x+690.,"ids":ids})
			w.encounters.append({"id":w.section+":encounter:"+str(i),"x":x,"variant":variant,"role":str(plan.role),"scene":w.section,"enemies":ids})
	if is_leaf:
		for i in 2:
			var x: float=w.length()*(.30 if i==0 else .68)
			var id: String=w.section+":secret:"+str(i)
			w.rooms.append({"id":id,"x":x,"y":-140.,"width":270.,"opened":w.discovered.has(id)})
			w.objects.append({"id":id+":door","kind":"rock" if w.section=="roots" else "panel","x":x-175.,"y":0.,"hp":2,"active":w.discovered.has(id),"secret":id})
			for j in 2:
				w.platforms.append(Rect2(x-290.+j*155.,-65.-j*75.,145.,18.))
			for j in 3:w.pickups.append({"id":id+":loot:"+str(j),"x":x-65.+j*65.,"y":-178.,"kind":["magnet","reveal","points"][j],"secret":id})
		var heavy: String={"water":"sweeper","terrace":"glider","roots":"borer"}[w.section]
		w.spawn_enemy(heavy,w.length()*.63,-90. if heavy=="glider" else 0.,700)
		w.mount={"available":true,"ridden":false,"x":560.,"hp":CampaignVehicles.MAX_HP,"type":{"water":"shell","terrace":"wind","roots":"drill"}[w.section],"hurt":0.,"wreck_age":0.}
		# Two signature environmental zones synced with mid & late encounters.
		var zone_kind: String="current" if w.section=="water" else ("updraft" if w.section=="terrace" else "dark")
		w.zones.append({"id":w.section+":flow","kind":zone_kind,"x":w.length()*.38,"width":1050.})
		w.zones.append({"id":w.section+":flow:late","kind":zone_kind,"x":w.length()*.73,"width":1100.})
		for i in 3:
			var hkind: String=("electric" if i%2==0 else "sluice") if w.section=="water" else (("vines" if i%2==0 else "gust") if w.section=="terrace" else ("claw" if i%2==0 else "crystal"))
			w.hazards.append({"id":w.section+":hazard:"+str(i),"kind":hkind,"x":w.length()*(.41+i*.19),"clock":float(i)*1.3,"phase":0.,"warn":false})
	if w.section=="relay":w.spawn_enemy("patrol",w.length()*.65,0.,700)
	if w.section!="arena":
		var prop_count: int=5 if is_leaf else 6
		for i in prop_count:
			var kind: String=OBJECTS[(i+abs(w.section.hash()))%OBJECTS.size()]
			var x: float=lerpf(620.,w.length()-820.,float(i)/maxf(1.,prop_count-1))
			if not CampaignGround.has_floor(w.floor_at(x)):continue
			w.objects.append({"id":w.section+":object:"+str(i),"kind":kind,"x":x,"y":0.,"hp":2,"active":w.activated.has(w.section+":object:"+str(i)),"secret":""})
			if kind=="planks":w.platforms.append(Rect2(x-80.,-55.,160.,18.))
		# The first coast lamps establish a visible change, not a tutorial modal.
		if w.section=="shore":
			for i in 2:w.objects.append({"id":"shore:lamp:"+str(i),"kind":"lamp","x":720.+i*600.,"y":0.,"hp":1,"active":w.activated.has("shore:lamp:"+str(i)),"secret":""})
	if w.section=="shore":
		w.pickups.append({"id":"shore:owl_feather","kind":"owl_feather","x":1200.,"y":-35.})
	elif w.section=="quay":
		w.pickups.append({"id":"quay:wolf_charm","kind":"wolf_charm","x":1650.,"y":-35.})
	for i in w.crates.size():w.crates[i].kind=(CampaignWeapons.SPECIAL+["heal","shield","grenade","repair","haste","power","reveal","magnet","owl_feather","wolf_charm"])[i%20]
	for e in w.enemies:
		if bool(e.mini):
			e.mini_role={"water":"current_guard","terrace":"terrace_guard","roots":"drill_guard"}.get(w.section,"current_guard")
			if e.mini_role=="drill_guard":e.armour=2
	for p in w.pickups:
		if p.kind=="repair" and w.section not in ["water","quay","terrace","roots"]:p.kind="grenade"
	for o in w.objects:
		if bool(o.active):apply_surface(w,o)
	CampaignRoutes.install_shelters(w)

static func apply_surface(w,o: Dictionary) -> void:
	# Persistent machinery must restore its collision geometry, too.
	if o.kind=="bridge":
		var surface:=Rect2(float(o.x)-130.,-55.,260.,18.)
		if not w.platforms.has(surface):w.platforms.append(surface)
	elif o.kind=="planks":w.platforms=w.platforms.filter(func(p):return not is_equal_approx(p.position.x,float(o.x)-80.))

static func hit_object(w,p: Vector2,damage: int,from: Vector2=Vector2.INF) -> bool:
	var swept:=from.is_finite()
	var low:=(minf(p.x,from.x) if swept else p.x)-45.
	var high:=(maxf(p.x,from.x) if swept else p.x)+45.
	for o in w.objects:
		var x:=float(o.x)
		if x<low or x>high or bool(o.active):continue
		if o.kind=="current" or o.kind=="updraft":continue
		var target:=Vector2(x,float(o.y)-35.)
		var nearest:=Geometry2D.get_closest_point_to_segment(target,from,p) if swept else p
		if nearest.distance_squared_to(target)>45.*45.:continue
		o.hp=int(o.hp)-damage
		if int(o.hp)<=0:
			o.active=true;w.activated[str(o.id)]=true;w.pending_events.append("mechanism")
			o.changed=0.
			if str(o.secret)!="":
				w.discovered[str(o.secret)]=true;w.award(str(o.secret),250);w.notice="arc_secret";w.notice_time=2.;w.pending_events.append("secret")
			if o.kind in ["lamp","panel","relay","turret"] and not w.awarded.has(str(o.id)+":power"):
				w.buffs["power"]=maxf(6.,float(w.buffs.get("power",0.)));w.award(str(o.id)+":power",0)
			if o.kind in ["surprise","planks","rock"]:w.pickups.append({"id":str(o.id)+":gift","x":o.x,"y":-35.,"kind":"points"})
			apply_surface(w,o)
			if o.kind=="relay":w.notice="arc_maintenance";w.notice_time=3.
		return true
	return false

static func turret_warning(o: Dictionary) -> bool:
	return fposmod(float(o.get("clock",0.)),TURRET_CYCLE)>=TURRET_CYCLE-TURRET_WARNING

static func turret_muzzle(o: Dictionary) -> Vector2:
	# Barrel opening in the cannon's resting atlas cel, relative to its base.
	return Vector2(float(o.x)+float(o.get("facing",1))*39.,float(o.y)-60.)

static func step(w,dt: float) -> void:
	var active: bool=w.state=="playing"
	for key in w.buffs:w.buffs[key]=maxf(0.,float(w.buffs[key])-dt)
	w.mount.hurt=maxf(0.,float(w.mount.get("hurt",0.))-dt)
	for o in w.objects:
		if bool(o.active):o.changed=float(o.get("changed",9.))+dt
		if active and o.kind=="cage":CampaignRoutes.step_cage(w,o)
		if active and o.kind=="gate" and not bool(o.active) and w.player.y>float(o.y)-80. and w.player.x>float(o.x)-40. and w.player.x<float(o.x)+45.:w.player.x=float(o.x)-40.
		if o.kind=="turret" and not bool(o.active):
			var dx: float=w.player.x-float(o.x)
			if absf(dx)<TURRET_SAFE_RANGE or absf(dx)>=TURRET_RANGE:
				o.clock=0.
			else:
				o.facing=-1 if dx<0. else 1
				var clock:=fposmod(float(o.get("clock",0.)),TURRET_CYCLE)+dt
				o.clock=fposmod(clock,TURRET_CYCLE)
				if clock>=TURRET_CYCLE:
					var origin:=turret_muzzle(o)
					w.bullets.append({"p":origin,"v":Vector2(float(o.facing)*200.,0.),"owner":"enemy","age":0.,"kind":"seed","damage":1,"pierce":0,"hit":[]})
					w.pending_events.append("enemy_shot")
		if active and o.kind in ["current","updraft"] and absf(w.player.x-float(o.x))<110.:
			if o.kind=="current" and w.grounded():w.player.x+=32.*dt
			elif o.kind=="updraft" and not w.grounded():w.velocity.y-=1000.*dt
	if not bool(w.mount.available):w.mount.wreck_age=float(w.mount.get("wreck_age",0.))+dt
	for room in w.rooms:
		if w.discovered.has(str(room.id)):room.opened=true
		if active and not bool(room.opened) and absf(w.player.x-float(room.x))<100. and w.player.y < -90.:
			w.discovered[str(room.id)]=true;room.opened=true;w.award(str(room.id),250);w.notice="arc_secret";w.notice_time=2.;w.pending_events.append("secret")
	for h in w.hazards:
		h.clock=float(h.clock)+dt;h.phase=fmod(float(h.clock),4.8);h.warn=float(h.phase)>2.6 and float(h.phase)<3.5
		if float(h.phase)>=3.5 and float(h.phase)<4.1 and int(h.get("last_pulse",-1))!=int(float(h.clock)/4.8):
			h.last_pulse=int(float(h.clock)/4.8)
			var surface: float=w.floor_at(float(h.x))
			if not CampaignGround.has_floor(surface):continue
			if h.kind=="crystal":
				for direction in [-1.,1.]:w.bullets.append({"p":Vector2(float(h.x),surface-115.),"v":Vector2(direction*220.,0.),"owner":"enemy","age":0.,"kind":"crystal","damage":1,"pierce":0,"hit":[]})
			if active and absf(w.player.x-float(h.x))<50.:
				var above: float=surface-w.player.y
				if h.kind=="gust" and above>40.:w.player.x-=70.;w.velocity.y=-180.
				elif h.kind=="sluice" and above<60.:w.player.x-=60.;w.velocity.y=-200.
				elif h.kind not in ["gust","sluice","crystal"] and above<90.:
					if not (h.kind=="electric" and bool(w.mount.ridden) and float(w.mount.get("dive",0.))>0.):w.damage_player("hazard")
	if not w.hazards.is_empty():w.hazards=w.hazards.filter(func(h):return not bool(h.get("once",false)) or float(h.clock)<4.2)
	for z in w.zones:
		if not active or w.player.x<float(z.x) or w.player.x>float(z.x)+float(z.width):continue
		if z.kind=="current" and w.grounded() and not bool(w.mount.ridden):w.player.x+=36.*dt
		if z.kind=="updraft" and not w.grounded():w.velocity.y-=1100.*dt
	if float(w.buffs.get("magnet",0.))>0.:
		for p in w.pickups:
			if not CampaignRoutes.pickup_exposed(w,p):continue
			var point:=Vector2(float(p.x),float(p.y))
			if point.distance_to(w.player)<250.:point=point.move_toward(w.player,320.*dt);p.x=point.x;p.y=point.y
	w.disabled_platforms.clear()
	for x in w.platform_timers:
		w.platform_timers[x]=maxf(0.,float(w.platform_timers[x])-dt)
		if float(w.platform_timers[x])>0.:w.disabled_platforms[x]=true
	for x in w.bridge_timers:
		w.bridge_timers[x]=maxf(0.,float(w.bridge_timers[x])-dt)
		if float(w.bridge_timers[x])<=0.:w.disabled_platforms[x]=true
