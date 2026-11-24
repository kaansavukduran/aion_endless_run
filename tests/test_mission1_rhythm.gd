## Loaded leaf routes keep their authored teaching rhythm, not a uniform corridor.
extends SceneTree
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+label)
func _initialize() -> void:call_deferred("run")
func spread(values: Array) -> float:
	var low:=INF;var high:=-INF
	for v in values:low=minf(low,v);high=maxf(high,v)
	return high-low
func run() -> void:
	for seed in [7719,123,99001]:
		for leaf in CampaignContent.REGIONS:
			var w:=AionCampaignWorld.new();w.begin("aion");w.run_seed=seed;w.load_section(leaf)
			var sizes:={};var gaps:=[];var last_x:=-1.;var compositions:=[]
			var seen_alone:={};var taught_before_combined:=true
			for e in w.encounters:
				check(str(e.cue)!="" and str(e.decision)!="" and str(e.counter)!="" and str(e.reward)!="","Each encounter card records cue, decision, counter and reward: "+str(e.id))
				var kinds:=[]
				for id in e.enemies:
					var enemy: Array=w.enemies.filter(func(x):return str(x.id)==str(id))
					if not enemy.is_empty():kinds.append(str(enemy[0].kind))
				sizes[kinds.size()]=true
				compositions.append(",".join(kinds))
				var regional: Array=kinds.filter(func(k):return k in CampaignContent.REGIONS[leaf])
				if kinds.size()==1:seen_alone[kinds[0]]=true
				elif regional.size()>=2:
					for k in regional:
						if not seen_alone.has(k) and kinds.count(k)<2:taught_before_combined=false
				if last_x>=0.:gaps.append(float(e.x)-last_x)
				last_x=float(e.x)
			check(w.encounters.size()==8,"Eight authored cards remain: "+leaf)
			check(sizes.size()>=3 and not sizes.has(5),"Group sizes vary and the old five-enemy block is gone: "+leaf)
			check(taught_before_combined,"Every role that appears in a combination was first met alone: "+leaf)
			check(spread(gaps)>w.length()*.05,"Encounter gaps alternate tension and breathing room: "+leaf)
			for i in range(1,compositions.size()):check(compositions[i]!=compositions[i-1],"No card repeats the previous composition: "+leaf)
			var authored_gates:=w.gates.filter(func(g):return Array(g.ids).any(func(id):var n:=str(id).get_slice(":enemy:",1);return n.length()==3 and n.begins_with("3")))
			check(authored_gates.size()==2,"Only the pincer and the exam close a gate: "+leaf)
			var surfaces:=w.platforms.filter(func(p):return p.position.y in [-70.,-115.]).map(func(p):return p.position.x)
			var steps:=[]
			for i in range(1,surfaces.size()):steps.append(surfaces[i]-surfaces[i-1])
			check(steps.size()>8 and spread(steps)>200.,"Platform rhythm is irregular, not a fixed metronome: "+leaf)
			var fruit:=w.pickups.filter(func(p):return str(p.id).begins_with(leaf+":fruit:"))
			check(fruit.size()<int(w.length()/220.)*.6,"Ground fruit is grouped into arcs, well under the old fruit-every-220px count: "+leaf)
	print("RESULT: %d mission rhythm checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
