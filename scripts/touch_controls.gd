class_name RunnerTouchControls
extends RefCounted
const HOLD_DELAY := 0.18
const SWIPE_DISTANCE := 44.0
const SWIPE_SECONDS := 0.65
var host
var fingers := {}
var clock := 0.0
var swipe_count := 0
var last_input := {}
var trace: Array[Dictionary] = []
func clear() -> void:
	trace.append({"kind":"clear","time":clock,"page":host.page})
	if trace.size()>24:trace.pop_front()
	fingers.clear()
	refresh()
func action(id: String,source: String,down: bool,cancelled: bool=false) -> void:
	if down:
		match id:
			"jump":host.press_jump(source)
			"attack":host.press_attack(source)
			"duck":host.press_duck(source)
			"shoot":host.press_shoot(source)
			"boost":host.press_boost(source)
	else:
		host.release_jump(source,not cancelled);host.release_attack(source);host.release_duck(source);host.release_shoot(source);host.release_boost(source)
func refresh() -> void:
	for id in host.action_buttons:
		var b=host.action_buttons[id]
		b.pressed=fingers.values().any(func(f):return f.role==id)
		b.queue_redraw()
func handle(event: InputEvent) -> bool:
	if not (event is InputEventScreenTouch or event is InputEventScreenDrag):return false
	if host.page!="" or host.world.state!="running":
		if event is InputEventScreenTouch and not event.pressed:
			action("","touch:"+str(event.index),false)
			fingers.erase(event.index)
			refresh()
		return false
	var index: int=event.index
	var source: String="touch:"+str(index)
	var point: Vector2=host.screen_transform.affine_inverse()*event.position
	last_input={"kind":"touch" if event is InputEventScreenTouch else "drag","index":index,"point":[point.x,point.y],"time":clock,"fingers":fingers.keys()}
	if event is InputEventScreenTouch:
		last_input["down"]=event.pressed
		last_input["cancel"]=event.canceled
	trace.append(last_input)
	if trace.size()>24:trace.pop_front()
	if event is InputEventScreenTouch:
		if event.pressed and not event.canceled:
			if host.pause_button.get_global_rect().has_point(point):host.pause_run();return true
			for id in host.action_buttons:
				if host.action_buttons[id].hit(point):
					fingers[index]={"role":id,"start":point,"last":point,"at":clock,"jumped":false,"moving":false}
					if host.action_buttons[id].disabled:fingers[index].role="cancelled"
					else:action(id,source,true)
					refresh();return true
			last_input["routed"]=true
			var role: String="boost" if host.on_wolf(host.to_game_point(event.position)) else "world"
			if fingers.values().any(func(f):return f.role=="world"):role="cancelled"
			fingers[index]={"role":role,"start":point,"last":point,"at":clock,"jumped":false,"moving":false}
			if role=="boost":action(role,source,true)
		else:
			if fingers.has(index):
				var finger: Dictionary=fingers[index]
				if not event.canceled and finger.role=="world" and not finger.jumped and not finger.moving and clock-finger.at<0.4:host.press_jump(source)
				action(str(finger.role),source,false,event.canceled)
				fingers.erase(index)
			refresh()
		return true
	if not fingers.has(index):return true
	var f: Dictionary=fingers[index]
	last_input["role"]=f.role
	last_input["age"]=clock-f.at
	last_input["jumped"]=f.jumped
	f.last=point
	if f.role in host.action_buttons:
		if not host.action_buttons[f.role].hit(point):action(f.role,source,false,true);f.role="cancelled";refresh()
	elif f.role=="world" and not f.jumped:
		var delta: Vector2=point-f.start
		if delta.length()>10:f.moving=true
		if delta.y>=SWIPE_DISTANCE and delta.y>absf(delta.x)*1.35 and clock-f.at<=SWIPE_SECONDS:
			host.press_duck(source);host.release_duck(source);f.role="cancelled";swipe_count+=1
	return true
func step(dt: float) -> void:
	clock+=dt
	for index in fingers:
		var f: Dictionary=fingers[index]
		if f.role=="world" and not f.moving and not f.jumped and clock-f.at>=HOLD_DELAY:
			f.jumped=true;host.press_jump("touch:"+str(index))
	refresh()
