class_name RunnerGamepad
extends RefCounted
var host
const DEFAULT_BINDINGS := {"jump":JOY_BUTTON_A,"attack":JOY_BUTTON_X,"duck":JOY_BUTTON_B,"boost":JOY_BUTTON_LEFT_SHOULDER,"shoot":JOY_BUTTON_RIGHT_SHOULDER}
const ALLOWED := [JOY_BUTTON_A,JOY_BUTTON_B,JOY_BUTTON_X,JOY_BUTTON_Y,JOY_BUTTON_LEFT_SHOULDER,JOY_BUTTON_RIGHT_SHOULDER]
const NAMES := {JOY_BUTTON_A:"A / ×",JOY_BUTTON_B:"B / ○",JOY_BUTTON_X:"X / □",JOY_BUTTON_Y:"Y / △",JOY_BUTTON_LEFT_SHOULDER:"LB / L1",JOY_BUTTON_RIGHT_SHOULDER:"RB / R1"}
var bindings: Dictionary=DEFAULT_BINDINGS.duplicate()
var deadzone := 0.55
var haptics := false
var capturing := ""
var capture_armed := false

func load_from(cfg: ConfigFile) -> void:
	deadzone=clampf(float(cfg.get_value("prefs","pad_deadzone",0.55)),0.20,0.80)
	haptics=bool(cfg.get_value("prefs","pad_haptics",false))
	var saved=cfg.get_value("prefs","pad_bindings",DEFAULT_BINDINGS)
	if saved is Dictionary and saved.size()==5:
		var valid:=true;var used:=[]
		for action in DEFAULT_BINDINGS:
			if not saved.has(action) or saved[action] not in ALLOWED or saved[action] in used:valid=false;break
			used.append(saved[action])
		if valid:bindings=saved.duplicate()

func save_to(cfg: ConfigFile) -> void:
	cfg.set_value("prefs","pad_deadzone",deadzone)
	cfg.set_value("prefs","pad_haptics",haptics)
	cfg.set_value("prefs","pad_bindings",bindings)

func binding_name(action: String) -> String:return NAMES[bindings[action]]

func begin_capture(action: String) -> void:
	host.clear_held_controls()
	capturing=action;capture_armed=true
	host.rebuild()

func capture_event(event: InputEvent) -> bool:
	if capturing=="":return false
	if (event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE) or (event is InputEventJoypadButton and event.pressed and event.button_index==JOY_BUTTON_START):
		capturing="";host.rebuild();return true
	if not capture_armed:
		if (event is InputEventJoypadButton or event is InputEventKey or event is InputEventMouseButton or event is InputEventScreenTouch) and not event.pressed:capture_armed=true
		return true
	if event is InputEventJoypadButton and event.pressed and event.button_index in ALLOWED:
		var old: int=bindings[capturing]
		for other in bindings:
			if other!=capturing and bindings[other]==event.button_index:bindings[other]=old;break
		bindings[capturing]=event.button_index
		capturing="";host.save_settings();host.rebuild()
	return true

func build_settings(column: VBoxContainer) -> void:
	column.add_child(host.label(host.text("controller"),20))
	column.add_child(host.wrap_label(host.text("pad_remap_help"),14))
	if capturing!="":column.add_child(host.wrap_label(host.text("pad_capture") % host.text("control_"+capturing),18,"f8db96"))
	for action in DEFAULT_BINDINGS:
		var option: Button=host.button(host.text("control_"+action)+"  ·  "+binding_name(action),begin_capture.bind(action))
		option.name="Bind_"+action
		column.add_child(option)
	host.add_toggle(column,"pad_haptics",haptics,func(v):haptics=v;host.save_settings())
	host.add_range_setting(column,"pad_deadzone",deadzone*100,func(v):deadzone=clampf(v/100.0,.20,.80);host.save_settings(),"GamepadDeadzone")
	var field: SpinBox=host.settings_inputs.GamepadDeadzone
	field.min_value=20;field.max_value=80
	field.get_parent().get_child(0).min_value=20;field.get_parent().get_child(0).max_value=80
	column.add_child(host.button(host.text("pad_reset"),func():bindings=DEFAULT_BINDINGS.duplicate();deadzone=.55;haptics=false;host.save_settings();host.rebuild()))

func prompts(boss: bool) -> String:
	var ids: Array=["jump","shoot","attack","duck"]
	var result: Array[String]=[]
	for action in ids:result.append(binding_name(action)+" "+host.text("control_"+action))
	return " · ".join(result)

func rumble() -> void:
	if haptics and device in Input.get_connected_joypads():Input.start_joy_vibration(device,.10,.18,.06)

func action_button(action: String,down: bool) -> void:
	if action=="jump":
		if down:host.press_jump("pad")
		else:host.release_jump("pad")
	elif action=="attack":
		if down:host.press_attack("pad")
		else:host.release_attack("pad")
	elif action=="duck":
		if down:host.press_duck("pad")
		else:host.release_duck("pad")
	elif action=="shoot":
		if down:host.press_shoot("pad")
		else:host.release_shoot("pad")
	elif action=="boost":
		if down:host.press_boost("pad")
		else:host.release_boost("pad")
	if down and host.world.state=="running":rumble()
var axes := Vector2.ZERO
var direction := -1
var repeat_left := 0.0
var device := -1
func clear() -> void:
	capturing="";capture_armed=false
	axes = Vector2.ZERO
	direction = -1
	repeat_left = 0.0
func menu_active() -> bool: return host.page != ""
func candidates() -> Array[Control]:
	var choices: Array[Control] = []
	var container: Node = host.language_picker if host.language_picker_open else host.menu_layer
	for item in container.find_children("*","Control",true,false):
		if item.is_visible_in_tree() and item.focus_mode == Control.FOCUS_ALL and (not item is BaseButton or not item.disabled): choices.append(item)
	return choices
func focus_owner() -> Control:
	var current: Control = host.get_viewport().gui_get_focus_owner()
	if is_instance_valid(current) and current.is_visible_in_tree(): return current
	var choices := candidates()
	if choices.is_empty(): return null
	choices[0].grab_focus()
	return choices[0]
func activate() -> void:
	var item := focus_owner()
	if item is BaseButton and not item.disabled:
		if item.toggle_mode: item.button_pressed = not item.button_pressed
		item.pressed.emit()
func navigate(side: int) -> void:
	var current := focus_owner()
	if current == null: return
	if current is Range and side in [SIDE_LEFT,SIDE_RIGHT]:
		current.value += maxf(current.step,1.0)*(1 if side==SIDE_RIGHT else -1)
		return
	var next: Control = current.find_valid_focus_neighbor(side)
	if next == null or next==current:
		next = current.find_prev_valid_focus() if side in [SIDE_TOP,SIDE_LEFT] else current.find_next_valid_focus()
	if is_instance_valid(next) and next.is_visible_in_tree(): next.grab_focus()
func back() -> void:
	if host.language_picker_open:
		host.toggle_language_picker()
	elif host.page=="paused": host.resume_run()
	elif host.page in ["settings","characters"]: host.show_page(host.return_page)
	elif host.page in ["finished","bosses"]: host.main_menu()
func step(dt: float) -> void:
	if not menu_active(): return
	if direction<0: return
	repeat_left -= dt
	if repeat_left<=0:
		navigate(direction)
		repeat_left = 0.14
func handle(event: InputEvent) -> bool:
	if event is InputEventJoypadMotion:
		device = event.device
		if menu_active():
			if event.axis==JOY_AXIS_LEFT_X: axes.x = event.axis_value
			elif event.axis==JOY_AXIS_LEFT_Y: axes.y = event.axis_value
			else: return true
			var next := -1
			if maxf(absf(axes.x),absf(axes.y))>deadzone:
				next = (SIDE_RIGHT if axes.x>0 else SIDE_LEFT) if absf(axes.x)>absf(axes.y) else (SIDE_BOTTOM if axes.y>0 else SIDE_TOP)
			if next!=direction:
				direction = next
				if next>=0: navigate(next); repeat_left = 0.38
			return true
		if event.axis==JOY_AXIS_TRIGGER_RIGHT:
			if event.axis_value>0.55: host.press_shoot("pad-trigger")
			elif event.axis_value<0.25: host.release_shoot("pad-trigger")
			return true
		return false
	if not event is InputEventJoypadButton: return false
	device = event.device
	var b: int = event.button_index
	if not event.pressed:
		for action in bindings:
			if bindings[action]==b:action_button(action,false)
		return true
	if b==JOY_BUTTON_START:
		clear()
		if host.page=="": host.pause_run()
		elif host.page=="paused": host.resume_run()
		elif host.page=="main": activate()
		return true
	if menu_active():
		if b in [JOY_BUTTON_A,JOY_BUTTON_X]: activate()
		elif b==JOY_BUTTON_B: back()
		elif b==JOY_BUTTON_DPAD_UP: navigate(SIDE_TOP)
		elif b==JOY_BUTTON_DPAD_DOWN: navigate(SIDE_BOTTOM)
		elif b==JOY_BUTTON_DPAD_LEFT: navigate(SIDE_LEFT)
		elif b==JOY_BUTTON_DPAD_RIGHT: navigate(SIDE_RIGHT)
		return true
	for action in bindings:
		if bindings[action]==b:action_button(action,true)
	return true
