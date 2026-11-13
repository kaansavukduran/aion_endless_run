class_name RunnerNativeDiagnostics
extends RefCounted
# Passive local Android diagnostics. No network, player identity or setters.
var host
var stamp := ""
var packet_id := 0
func point(rect: Rect2) -> Array:
	var p: Vector2=host.screen_transform*rect.get_center()
	var raw: Vector2=host.layout_size
	var physical:=p/raw*Vector2(DisplayServer.window_get_size())+Vector2(DisplayServer.window_get_position())
	return [roundi(physical.x),roundi(physical.y)]
func layout() -> void:
	if not OS.has_feature("android"):return
	var buttons:=[];var actions:={};var regions:={}
	for name in ["PagePanel","StartChooser"]:
		var control=host.menu_layer.get_node_or_null(name)
		if control!=null and control.is_visible_in_tree():
			var rect: Rect2=control.get_global_rect()
			regions[name]=[rect.position.x,rect.position.y,rect.size.x,rect.size.y]
	for control in host.ui.find_children("*","BaseButton",true,false):
		if control.is_visible_in_tree():buttons.append({"name":str(control.name),"text":control.text,"point":point(control.get_global_rect())})
	for id in host.action_buttons:
		var control=host.action_buttons[id]
		if control.is_visible_in_tree():actions[id]=point(control.get_global_rect())
	emit_packet("AION_UI",JSON.stringify({"page":host.page,"language":host.language,"character":host.character,"orientation":"portrait" if host.portrait else "landscape","score":host.world.score,"level":host.world.adventure.level,"buttons":buttons,"actions":actions,"regions":regions}))
func state() -> void:
	if not OS.has_feature("android"):return
	var w=host.world
	var payload:=JSON.stringify({"page":host.page,"character":host.character,"state":w.state,"airborne":w.y<0,"charging":w.charging,"charge_ratio":w.charge_ratio(),"gliding":w.gliding,"attacking":w.adventure.attack_time>0,"shooting":w.frontier.shot_flash>0,"ammo":w.frontier.ammo,"reload_time":w.frontier.reload_time,"reloads":w.frontier.reloads,"rolling":w.adventure.ducking(w)})
	if stamp!=payload:stamp=payload;print("AION_STATE "+payload)

func emit_packet(kind: String, payload: String) -> void:
	# Android log lines are bounded. ASCII base64 chunks prevent UTF-8 or JSON
	# truncation even with eleven language labels and large accessibility menus.
	packet_id += 1
	var encoded := Marshalls.utf8_to_base64(payload)
	var count := ceili(float(encoded.length())/700.0)
	for index in count:
		print("AION_CHUNK %s %d %d %d %s" % [kind,packet_id,index,count,encoded.substr(index*700,700)])
