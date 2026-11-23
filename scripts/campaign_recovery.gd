class_name CampaignRecovery
extends RefCounted

## Checkpoint stock is a snapshot, not the player's current inventory. Score,
## claims and rescue IDs remain owned by World and are never rolled back.
static var _points_cache_key := ""
static var _points_cache: Array[float] = []

static func points(w) -> Array[float]:
	if CampaignRoutes.is_fork(w.section) or w.section=="arena":return []
	var key: String="%s|%d|%d|%d|%.0f"%[w.section,w.run_seed,w.encounters.size(),w.pits.size(),w.length()]
	if key==_points_cache_key:return _points_cache
	var values: Array[float]=[]
	var fixed: Dictionary={"shore":[2600.,5480.,6750.],"quay":[3000.,6200.,8400.],"canopy":[2450.],"relay":[3000.,6500.,8600.]}
	if fixed.has(w.section):
		for x in fixed[w.section]:values.append(safe_x(w,float(x)))
	else:
		for encounter in w.encounters:values.append(safe_x(w,float(encounter.x)+900.))
	_points_cache_key=key;_points_cache=values
	return values

static func safe_x(w,x: float) -> float:
	for offset in [0.,40.,80.,120.,160.,240.,-40.,-80.]:
		var candidate: float=clampf(x+offset,180.,w.length()-300.)
		if CampaignGround.has_floor(w.floor_at(candidate)):return candidate
	return -1.

static func capture(w,x: float) -> Dictionary:
	var machine: Dictionary=w.mount.duplicate(true)
	# Section-entry recovery keeps the established dismounted retry. A real
	# mid-route flag can explicitly preserve a rider and its recorded hull.
	if x<=180. and bool(machine.get("ridden",false)):
		machine.ridden=false;machine.x=x+100.;machine.floor_y=0.
	return {"section":w.section,"x":x,"weapon":w.weapon,"ammunition":w.ammunition,"grenades":w.grenades,"shield":0,"flock":w.flock,"mount":machine}

static func enter(w) -> void:
	if str(w.rally.get("section",""))!=w.section:w.rally=capture(w,140.)
	w.chain=0;w.chain_time=0.;w.score_popups.clear();w.bridge_warned=false

static func step(w) -> void:
	if not w.grounded() or absf(w.player.y+(42. if bool(w.mount.ridden) else 0.)-w.floor_at(w.player.x))>.1:return
	for x in points(w):
		if x<0. or x<=float(w.rally.get("x",140.))+50. or w.player.x<x or w.player.x>x+600.:continue
		if w.gates.any(func(g):return float(g.x)<=x and w.gate_closed(g)):continue
		w.rally=capture(w,x);w.notice="arc_rally";w.notice_time=2.5;w.pending_events.append("checkpoint")

static func apply(w,point: Dictionary) -> void:
	if str(point.get("section",""))!=w.section:return
	var x: float=float(point.get("x",140.))
	if x<35. or x>w.length()-130. or not CampaignGround.has_floor(w.floor_at(x)):return
	w.player=Vector2(x,w.floor_at(x));w.velocity=Vector2.ZERO
	w.weapon=str(point.get("weapon","pistol"));w.ammunition=int(point.get("ammunition",0))
	w.grenades=int(point.get("grenades",3));w.flock=int(point.get("flock",1))
	var machine: Dictionary=point.get("mount",{})
	if not machine.is_empty():
		w.mount=machine.duplicate(true)
		w.mount.hp=mini(CampaignVehicles.MAX_HP,int(w.mount.hp))
		if int(w.mount.get("hp",0))<=0:w.mount.ridden=false;w.mount.available=false
		elif bool(w.mount.get("ridden",false)):
			w.mount.x=x;w.mount.floor_y=w.floor_at(x);w.player.y-=42.
	w.invulnerable=1.2

static func valid(point: Variant,section: String) -> bool:
	if not point is Dictionary or point.size()>12:return false
	if point.is_empty():return true
	if str(point.get("section",""))!=section:return false
	for key in ["x","ammunition","grenades","shield","flock"]:
		var value=point.get(key,null)
		if typeof(value) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(value)):return false
	if float(point.x)<35. or float(point.x)>float(AionCampaignWorld.STAGES[section].length)-130.:return false
	if str(point.get("weapon","")) not in CampaignWeapons.SPECS:return false
	if float(point.ammunition)<0. or float(point.ammunition)>1000. or float(point.grenades)<0. or float(point.grenades)>9. or float(point.shield)<0. or float(point.shield)>3. or float(point.flock)<1. or float(point.flock)>3.:return false
	var machine=point.get("mount",{})
	if not machine is Dictionary or machine.size()>24:return false
	for key in machine:
		var value=machine[key]
		if typeof(value) not in [TYPE_BOOL,TYPE_STRING,TYPE_INT,TYPE_FLOAT]:return false
		if str(key)=="type":
			if not value is String:return false
		elif str(key) in ["ridden","available"]:
			if not value is bool:return false
		elif typeof(value) not in [TYPE_INT,TYPE_FLOAT]:return false
		if typeof(value) in [TYPE_INT,TYPE_FLOAT] and (not is_finite(float(value)) or absf(float(value))>100000.):return false
	if not machine.is_empty():
		if str(machine.get("type","skimmer")) not in CampaignVehicles.TYPES:return false
		if not machine.get("ridden",false) is bool or not machine.get("available",false) is bool:return false
		if int(machine.get("hp",0))<0 or int(machine.get("hp",0))>3:return false
	return true
