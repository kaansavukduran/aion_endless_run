class_name RunnerWebAccessibility
extends RefCounted
var host
var callback: JavaScriptObject
var stamp := ""
func setup() -> void:
	if not OS.has_feature("web"):return
	callback=JavaScriptBridge.create_callback(dispatch)
	JavaScriptBridge.get_interface("window").aionAccessibleAction=callback
func dispatch(args: Array) -> void:
	if args.size()<2:return
	var item=instance_from_id(int(str(args[1])))
	if not is_instance_valid(item) or not item is Control or not item.is_inside_tree() or not item.is_visible_in_tree() or not host.ui.is_ancestor_of(item):return
	if item is BaseButton and item.disabled:return
	if str(args[0]) in ["activate","range"]:host.active_input="keyboard"
	match str(args[0]):
		"focus":item.grab_focus()
		"activate":
			if item is BaseButton:
				if item.toggle_mode:item.button_pressed=not item.button_pressed
				item.pressed.emit()
		"range":
			if item is Range and args.size()>2:item.value=clampf(float(str(args[2])),item.min_value,item.max_value)
func update() -> void:
	if not OS.has_feature("web"):return
	var entries:=[]
	for item in host.ui.find_children("*","Control",true,false):
		if not item.is_visible_in_tree() or str(item.name).begins_with("RetiredUI_"):continue
		if item is BaseButton:
			if item.text=="" and item.accessibility_name=="":continue
			entries.append({"id":str(item.get_instance_id()),"label":item.accessibility_name if item.accessibility_name!="" else item.text,"disabled":item.disabled,"toggle":item.toggle_mode,"pressed":item.button_pressed})
		elif item is HSlider:
			entries.append({"id":str(item.get_instance_id()),"label":item.accessibility_name,"range":true,"min":item.min_value,"max":item.max_value,"step":item.step,"value":item.value})
	var summary: String=host.text("score")+" "+str(host.world.score)+" · "+(host.text("level_short") % host.world.adventure.level)
	if host.page=="paused":summary=host.text("paused")
	elif host.page=="settings":summary=host.text("settings")
	elif host.page!="finished":summary=host.text("fragaria_found") if host.world.adventure.fragaria_time>0 else "Aion Endless Run"
	if host.world.frontier.storytelling() and host.page=="":summary=host.story_ui.speaker.text+" · "+host.story_ui.dialogue.text
	var payload:=JSON.stringify({"items":entries,"language":host.language,"page":host.page,"summary":summary})
	if stamp==payload:return
	stamp=payload
	var api=JavaScriptBridge.get_interface("AionAccessibility")
	if api!=null:api.update(payload)
