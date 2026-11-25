class_name CampaignNativeDiagnostics
extends RefCounted

## Passive local Android QA observations. No setters, network or player IDs.
## State is sampled at most10Hz; menus emit only after their real layout changes.
var host
var clock:=0.
var state_stamp:=""
var layout_stamp:=""
var packet_id:=0

func point(logical: Vector2) -> Array:
	var p: Vector2=host.screen_transform*logical
	var raw: Vector2=host.get_viewport_rect().size
	var physical: Vector2=p/raw*Vector2(DisplayServer.window_get_size())+Vector2(DisplayServer.window_get_position())
	return [roundi(physical.x),roundi(physical.y)]

func rectangle(control: Control) -> Array:
	var rect: Rect2=control.get_global_rect()
	var first:=point(rect.position);var last:=point(rect.end)
	return [first[0],first[1],last[0]-first[0],last[1]-first[1]]

func emit(kind: String,payload: String) -> void:
	packet_id+=1
	var encoded:=Marshalls.utf8_to_base64(payload)
	var count:=ceili(float(encoded.length())/700.)
	for index in count:
		print("AION_CHUNK %s %d %d %d %s"%[kind,packet_id,index,count,encoded.substr(index*700,700)])

func step(dt: float) -> void:
	if not OS.has_feature("android") or host==null:return
	clock+=dt
	if clock<.1:return
	clock=0.
	var w=host.world
	var ui_key: String=str(host.ui_generation)+":"+str(host.ui_ready)+":"+host.menu_kind+":"+str(host.get_viewport_rect().size)
	var context: AionCampaignTouch=host.actions.get("context")
	ui_key+=":"+str(is_instance_valid(context) and context.visible)+":"+str(w.mount.ridden)
	if ui_key!=layout_stamp:
		layout_stamp=ui_key
		var controls:=[];var actions:={}
		if host.ui_ready:
			for control in host.ui.find_children("*","BaseButton",true,false):
				if control.is_visible_in_tree():controls.append({"name":str(control.name),"text":control.text,"point":point(control.get_global_rect().get_center())})
		for key in host.actions:
			var action: Control=host.actions[key]
			if action.is_visible_in_tree():actions[key]=point(action.get_global_rect().get_center())
		var payload: Dictionary={"menu":host.menu_kind,"ui_ready":host.ui_ready,"ui_generation":host.ui_generation,"language":host.language,"character":w.character,"orientation":"portrait" if host.portrait else "landscape","buttons":controls,"actions":actions}
		if is_instance_valid(host.stick):payload.stick=rectangle(host.stick)
		emit("AION_ARCADE_UI",JSON.stringify(payload))
	var assists:=[]
	for assist in w.assists:assists.append({"kind":assist.kind,"remaining":assist.remaining,"phase":assist.phase})
	var drops:=[]
	for item in w.pickups:
		if bool(w.taken.get(str(item.id),false)):continue
		if bool(item.get("from_bag",false)) or str(item.kind) in ["owl_feather","wolf_charm"]:
			drops.append({"id":item.id,"kind":item.kind,"x":item.x,"y":item.y,"rescue_id":item.get("rescue_id","")})
	var payload:=JSON.stringify({"menu":host.menu_kind,"state":w.state,"section":w.section,"character":w.character,"player":[snappedf(w.player.x,2.),snappedf(w.player.y,2.)],"velocity":[w.velocity.x,w.velocity.y],"hp":w.hp,"score":w.score,"shots":w.shots,"weapon":w.weapon,"ammunition":w.ammunition,"pistol_reserve":w.pistol_reserve,"grounded":w.grounded(),"crouching":w.crouching(),"charging":w.charging,"charge_ratio":w.charge_ratio(),"aim":[w.aim_direction.x,w.aim_direction.y],"mounted":w.mount.ridden,"vehicle_hp":w.mount.hp,"assists":assists,"assist_attacks":w.assist_attacks,"pickups":drops,"spiders":CampaignWeapons.spider_snapshot(w)})
	if payload!=state_stamp:state_stamp=payload;emit("AION_ARCADE_STATE",payload)
