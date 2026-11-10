class_name RunnerGamepad
extends RefCounted
var host
var axes := Vector2.ZERO
var direction := -1
var repeat_left := 0.0
var device := -1
func clear() -> void:
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
			if axes.length()>0.55:
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
		if b==JOY_BUTTON_A: host.release_jump("pad")
		if b==JOY_BUTTON_X: host.release_attack("pad")
		if b==JOY_BUTTON_RIGHT_SHOULDER: host.release_shoot("pad")
		if b==JOY_BUTTON_B: host.release_duck("pad")
		if b==JOY_BUTTON_LEFT_SHOULDER: host.release_boost("pad")
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
	if b==JOY_BUTTON_A: host.press_jump("pad")
	elif b==JOY_BUTTON_X: host.press_attack("pad")
	elif b==JOY_BUTTON_B: host.press_duck("pad")
	elif b==JOY_BUTTON_LEFT_SHOULDER: host.press_boost("pad")
	elif b==JOY_BUTTON_RIGHT_SHOULDER: host.press_shoot("pad")
	return true
