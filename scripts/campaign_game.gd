class_name AionCampaignGame
extends Node2D

const Words = preload("res://scripts/campaign_text.gd")
const FONT = preload("res://assets/PixelifySans.ttf")
var world := AionCampaignWorld.new()
var options := RunnerInterfaceOptions.new()
var pad := RunnerGamepad.new()
var selected_hero := "aion"
var language := "en"
var view: AionCampaignView
var layer: CanvasLayer
var ui: Control
var menu: PanelContainer
var column: VBoxContainer
var hud: Label
var subtitle: Label
var boss_health: ProgressBar
var pause_button: Button
var ride_button: Button
var stick: AionCampaignStick
var actions: Dictionary = {}
var screen_transform := Transform2D.IDENTITY
var view_w := 1152.
var view_h := 648.
var portrait := false
var touch_mode := false
var menu_kind := "briefing"
var saved: Dictionary = {}
var save_ok := true
var buttons: Array[Button] = []
var focus_index := 0
var stick_touch := -1
var touch_actions: Dictionary = {}
var held: Dictionary = {}
var left_down := false
var right_down := false
var mouse_stick := false
var mouse_axis := Vector2.ZERO
var pad_axis := Vector2.ZERO
var fade := -1.
var fade_loaded := false
var fade_panel: ColorRect
var boss_announced := false
var last_state := ""
var telemetry_clock := 0.
var save_message: Label
var audio_enabled := true
var motion_enabled := true
var audio_volume := .45
var voices: Array[AudioStreamPlayer] = []
var sound_cache: Dictionary = {}
var accessibility_callback: JavaScriptObject
var accessibility_stamp := ""
var active_input := "keyboard"
var ui_generation := 0
var ui_ready := false
var leaving_scene := false
var pad_menu_wait := 0.0
var help_step := 0
var outro_step := 0

func _ready() -> void:
	var cfg := ConfigFile.new(); cfg.load("user://save.cfg")
	options.load_from(cfg); pad.load_from(cfg)
	audio_enabled=bool(cfg.get_value("prefs","audio",true));audio_volume=float(cfg.get_value("prefs","volume",.45))
	motion_enabled=bool(cfg.get_value("prefs","motion",true))
	touch_mode=OS.has_feature("mobile")
	if OS.has_feature("web"): touch_mode=bool(JavaScriptBridge.eval("matchMedia('(pointer:coarse)').matches"))
	world.begin(selected_hero)
	load_checkpoint()
	view=AionCampaignView.new();view.host=self;view.world=world;view.font=options.font_for(FONT);add_child(view)
	layer=CanvasLayer.new();add_child(layer)
	ui=Control.new();ui.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.theme=options.theme(FONT);layer.add_child(ui)
	if OS.has_feature("web"):
		accessibility_callback=JavaScriptBridge.create_callback(accessible_action)
		JavaScriptBridge.get_interface("window").aionAccessibleAction=accessibility_callback
		JavaScriptBridge.eval("(()=>{const c=document.getElementById('canvas');if(!c)return;['data-state','data-page','data-ui-ready','data-ui'].forEach(k=>c.removeAttribute(k));c.dataset.mode='campaign'})()")
	get_viewport().size_changed.connect(resize)
	Input.joy_connection_changed.connect(func(_id,_connected):release_all())
	resize()

func _exit_tree() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("(()=>{const c=document.getElementById('canvas');c?.removeAttribute('data-campaign');c?.removeAttribute('data-mode');window.aionAccessibleAction=null})()")

func t(key: String) -> String:
	if key.begins_with("arc_"):key=key.trim_prefix("arc_")
	return Words.word(language,key)
func old(key: String) -> String: return GameText.get_text(language,key)
func font_size(size: int) -> int: return roundi(size*options.text_scale)

func safe_rect(raw: Vector2) -> Rect2:
	if OS.has_feature("web"):
		var json = JavaScriptBridge.eval("(()=>{const d=document.createElement('div');d.style.cssText='position:fixed;visibility:hidden;padding:env(safe-area-inset-top) env(safe-area-inset-right) env(safe-area-inset-bottom) env(safe-area-inset-left)';document.body.append(d);const s=getComputedStyle(d),a=[parseFloat(s.paddingLeft),parseFloat(s.paddingTop),parseFloat(s.paddingRight),parseFloat(s.paddingBottom),innerWidth,innerHeight];d.remove();return JSON.stringify(a)})()")
		var a = JSON.parse_string(str(json))
		if a is Array and a.size()==6:
			var unit := Vector2(raw.x/maxf(1,float(a[4])),raw.y/maxf(1,float(a[5])))
			return Rect2(Vector2(float(a[0]),float(a[1]))*unit,raw-Vector2(float(a[0])+float(a[2]),float(a[1])+float(a[3]))*unit)
	if OS.has_feature("mobile"):return options.native_safe_layout(raw)
	return Rect2(Vector2.ZERO,raw)

func resize() -> void:
	if not is_instance_valid(ui):return
	release_all()
	var raw:=get_viewport_rect().size
	var safe:=safe_rect(raw)
	var aspect: float=safe.size.x/maxf(1.,safe.size.y)
	portrait=aspect<1.
	view_w=540. if portrait else maxf(960.,648.*aspect)
	view_h=view_w/aspect
	var factor: float=safe.size.x/view_w
	screen_transform=Transform2D(0,Vector2.ONE*factor,0,safe.position)
	layer.transform=screen_transform
	var zoom:=.72 if portrait else 1.
	view.transform=screen_transform*Transform2D(0,Vector2.ONE*zoom,0,Vector2.ZERO)
	view.scene_w=view_w/zoom;view.scene_h=view_h/zoom
	view.ground=(view_h-(220. if touch_mode else 92.))/zoom
	ui.size=Vector2(view_w,view_h)
	build_ui()

func label(value: String,size: int=20) -> Label:
	var item:=Label.new();item.text=value;item.add_theme_font_size_override("font_size",font_size(size));item.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return item
func paragraph(value: String,size: int=20) -> Label:
	var item:=label(value,size);item.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;return item
func action(value: String,callback: Callable,primary: bool=false) -> Button:
	var item:=Button.new();item.text=value;item.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	item.custom_minimum_size.y=maxf(48.,font_size(20)*1.4+12.)
	item.add_theme_font_size_override("font_size",font_size(20));item.pressed.connect(callback)
	if primary:item.add_theme_stylebox_override("normal",options.style("primary","accent",8))
	buttons.append(item);column.add_child(item);return item

func build_ui() -> void:
	ui_generation+=1
	ui_ready=false
	for child in ui.get_children():
		child.name="RetiredCampaign_"+str(child.get_instance_id())
		if child is CanvasItem:child.hide()
		child.queue_free()
	buttons.clear();actions.clear(); menu=null
	var band:=Panel.new();band.mouse_filter=Control.MOUSE_FILTER_IGNORE;band.add_theme_stylebox_override("panel",options.style("surface","border",0));ui.add_child(band)
	band.position=Vector2.ZERO;band.size=Vector2(view_w,maxf(44,font_size(17)*(2.7 if portrait or options.text_scale>1. else 1.4)+12.))
	hud=label("",17);ui.add_child(hud);hud.position=Vector2(12,6);hud.size=Vector2(view_w-140,band.size.y-8);hud.clip_text=true
	pause_button=Button.new();pause_button.name="CampaignPause";pause_button.text="II";pause_button.tooltip_text=old("pause");pause_button.add_theme_font_size_override("font_size",font_size(20));ui.add_child(pause_button)
	pause_button.position=Vector2(view_w-72,4);pause_button.size=Vector2(64,band.size.y-8);pause_button.pressed.connect(toggle_pause)
	subtitle=label("",16);ui.add_child(subtitle);subtitle.position=Vector2(12,band.size.y+6);subtitle.size=Vector2(view_w-24,90);subtitle.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_color_override("font_color",Color("fff3d8"));subtitle.add_theme_color_override("font_shadow_color",Color("211c29"));subtitle.add_theme_constant_override("shadow_outline_size",4)
	boss_health=ProgressBar.new();ui.add_child(boss_health);boss_health.show_percentage=false;boss_health.max_value=90;boss_health.position=Vector2(view_w*.27,band.size.y+6);boss_health.size=Vector2(view_w*.46,12)
	boss_health.add_theme_stylebox_override("background",options.style("surface","border",1));boss_health.add_theme_stylebox_override("fill",options.style("primary","accent",1))
	if touch_mode: build_touch()
	else:
		var help:=paragraph(t("keys"),15);ui.add_child(help);help.position=Vector2(16,view_h-48);help.size=Vector2(view_w-32,45)
	ride_button=Button.new();ride_button.name="CampaignRide";ride_button.text=t("ride")+ (" · E" if not touch_mode else "");ride_button.add_theme_font_size_override("font_size",font_size(17));ride_button.pressed.connect(func():world.interact());ui.add_child(ride_button)
	ride_button.position=Vector2(view_w*.5-110,view_h-(190 if touch_mode else 98));ride_button.size=Vector2(220,52)
	fade_panel=ColorRect.new();fade_panel.color=Color(0.06,.06,.09,0);fade_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;fade_panel.size=Vector2(view_w,view_h);ui.add_child(fade_panel)
	if menu_kind!="": build_menu()
	update_hud()
	finish_layout.call_deferred(ui_generation)

func finish_layout(generation: int) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree() or generation!=ui_generation:return
	ui_ready=true
	metadata()

func build_touch() -> void:
	stick=AionCampaignStick.new();stick.name="CampaignJoystick";stick.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.add_child(stick)
	stick.position=Vector2(24,view_h-177);stick.size=Vector2(150,150)
	var points := {"jump":Vector2(view_w-120,view_h-125),"attack":Vector2(view_w-175,view_h-235),"grenade":Vector2(view_w-230,view_h-125)}
	for key in points:
		var item:=AionCampaignTouch.new();item.name="Campaign_"+key;item.action="shoot" if key=="attack" else key
		item.caption=old("control_jump") if key=="jump" else (old("control_shoot") if key=="attack" else t("grenade"))
		item.font=options.font_for(FONT);item.palette=options.colors.duplicate();item.mouse_filter=Control.MOUSE_FILTER_IGNORE
		if key=="grenade":item.palette.accent=AionCampaignWorld.COLORS[world.character]
		ui.add_child(item);item.position=points[key];item.size=Vector2(100,100);actions[key]=item
	var hint:=label(t("boost") if world.character=="wolf" else t("move"),14);ui.add_child(hint);hint.position=Vector2(24,view_h-206)

func build_menu() -> void:
	release_all()
	var shade:=ColorRect.new();shade.color=Color("12101caa");shade.size=Vector2(view_w,view_h);ui.add_child(shade)
	menu=PanelContainer.new();menu.name="CampaignMenu";ui.add_child(menu);menu.add_theme_stylebox_override("panel",options.style("surface","border",16))
	menu.custom_minimum_size.x=minf(view_w-32,840. if not portrait else 508.)
	menu.size.x=menu.custom_minimum_size.x
	column=VBoxContainer.new();column.add_theme_constant_override("separation",10);menu.add_child(column)
	var title:=label(t({"briefing":"title","help":"title","paused":"pause","fork_one":"fork","fork_two":"fork","boss":"arena","dead":"dead","complete":"won","outro":"won","settings":"settings_hint"}.get(menu_kind,"title")),24)
	title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(title)
	match menu_kind:
		"briefing":
			column.add_child(paragraph(t("mission")+" · "+old("name_"+selected_hero),18))
			column.add_child(paragraph(t("brief")))
			if not saved.is_empty() and not bool(saved.get("completed",false)):
				action(t("continue")+" · "+old("name_"+str(saved.get("character","aion"))),resume_saved,true).name="CampaignContinue"
			action(t("restart") if not saved.is_empty() and not bool(saved.get("completed",false)) else t("start"),begin_new,true).name="CampaignBegin"
			action(t("back"),return_main)
		"help":
			var pages: Array[String]=[t("help"),t("touch") if touch_mode else pad_help() if not Input.get_connected_joypads().is_empty() else t("keys")]
			if world.character in ["rabbit","eren","owl"]:pages.append(t("owl" if world.character=="owl" else "special"))
			column.add_child(paragraph(pages[clampi(help_step,0,pages.size()-1)]))
			action(t("next"),func():
				help_step+=1
				if help_step>=pages.size():close_menu()
				else:build_ui(),true).name="CampaignGo"
			action(old("story_skip"),close_menu)
		"paused":
			action(old("resume"),close_menu,true)
			action(t("save_retry"),func():save_checkpoint();build_ui())
			action(t("back"),return_main)
			column.add_child(paragraph(t("settings_hint"),16))
		"fork_one","fork_two":
			column.add_child(paragraph(t(menu_kind)))
			var choices: Array = ["canopy","water"] if menu_kind=="fork_one" else ["terrace","roots"]
			for choice in choices:
				action(t(choice),func():world.choose_route(choice);menu_kind="";start_travel();build_ui(),choice==choices[0]).name="Route_"+choice
			action(t("back"),return_main)
		"boss":
			column.add_child(paragraph(t("boss_intro")))
			action(t("next"),close_menu,true).name="CampaignBossGo"
			action(t("back"),return_main)
		"dead":
			column.add_child(paragraph(old("score")+" %05d · " % world.score+t(world.checkpoint),20))
			action(t("retry"),func():world.retry();menu_kind="";boss_announced=false;view.camera_x=0.;save_checkpoint();build_ui(),true).name="CampaignRetry"
			action(t("back"),return_main)
		"complete":
			column.add_child(paragraph(old("score")+" %05d · " % world.score+t("keepers")+" %d" % world.rescued.size(),20))
			column.add_child(paragraph(old("best")+" %05d" % int(saved.get("best_score",world.score)),18))
			column.add_child(paragraph(t("route")+": "+" → ".join(world.route.map(func(s):return t(s))),18))
			action(t("restart"),begin_new,true)
			action(t("back"),return_main)
		"outro":
			var sentences: PackedStringArray=t("won_text").split(". ")
			var message: String=sentences[clampi(outro_step,0,sentences.size()-1)]
			column.add_child(paragraph(message))
			action(t("next"),func():
				outro_step+=1
				if outro_step>=sentences.size():menu_kind="complete"
				build_ui(),true)
			action(t("back"),return_main)
	if not save_ok:
		save_message=paragraph(t("save_failed"),16);column.add_child(save_message)
		action(t("save_retry"),func():save_checkpoint();build_ui())
	fit_menu.call_deferred(menu)

func fit_menu(target: PanelContainer) -> void:
	if not is_instance_valid(target) or not target.is_inside_tree() or not target.is_visible_in_tree(): return
	target.reset_size()
	var height: float=target.get_combined_minimum_size().y
	target.size.y=height
	target.position=Vector2(floorf((view_w-target.size.x)*.5),maxf(8.,floorf((view_h-height)*.5)))
	if not buttons.is_empty():focus_index=0;buttons[0].grab_focus()

func begin_new() -> void:
	world.begin(selected_hero);world.state="story";menu_kind="help";help_step=0;outro_step=0;boss_announced=false;view.camera_x=0.;save_checkpoint();build_ui()
func resume_saved() -> void:
	if not world.restore(saved): saved.clear();begin_new();return
	menu_kind="help";help_step=0;world.state="story";boss_announced=false;view.camera_x=0.;build_ui()
func close_menu() -> void:
	if menu_kind=="boss":world.boss.engaged=true
	release_all();menu_kind="";world.state="playing";build_ui()
func toggle_pause() -> void:
	if world.state=="playing":
		release_all();world.state="paused";menu_kind="paused";save_checkpoint();build_ui()
	elif menu_kind=="paused":close_menu()
func return_main() -> void:
	if leaving_scene:return
	release_all()
	if world.checkpoint_ready or world.completed: save_checkpoint()
	if not save_ok: menu_kind="paused";build_ui();return
	leaving_scene=true
	# The emitting Button must remain in-tree until its input event finishes.
	get_tree().call_deferred("change_scene_to_file","res://main.tscn")

func load_checkpoint() -> void:
	var content: String=FileAccess.get_file_as_string("user://campaign.json") if FileAccess.file_exists("user://campaign.json") else ""
	if OS.has_feature("web"):
		var mirror = JavaScriptBridge.eval("(()=>{try{return localStorage.getItem('aion.campaign.v1')||''}catch(_){return ''}})()")
		if mirror is String and not mirror.is_empty():content=mirror
	if content.is_empty():return
	var parsed=JSON.parse_string(content)
	if parsed is Dictionary:
		var probe:=AionCampaignWorld.new()
		if probe.restore(parsed):saved=parsed

func save_checkpoint() -> void:
	var data:=world.snapshot()
	data.best_score=maxi(int(saved.get("best_score",0)),world.score if world.completed else 0)
	var content:=JSON.stringify(data)
	var file:=FileAccess.open("user://campaign.tmp",FileAccess.WRITE)
	var disk_ok:=false
	if file!=null:
		file.store_string(content);file.flush();disk_ok=file.get_error()==OK;file.close()
		if disk_ok:disk_ok=DirAccess.rename_absolute("user://campaign.tmp","user://campaign.json")==OK
	var mirror_ok:=false
	if OS.has_feature("web"):
		mirror_ok=bool(JavaScriptBridge.eval("(()=>{try{localStorage.setItem('aion.campaign.v1',"+JSON.stringify(content)+");return localStorage.getItem('aion.campaign.v1')==="+JSON.stringify(content)+"}catch(_){return false}})()"))
		JavaScriptBridge.force_fs_sync()
	save_ok=disk_ok or mirror_ok
	if save_ok:saved=data.duplicate(true)

func release_all() -> void:
	held.clear();touch_actions.clear();stick_touch=-1;left_down=false;right_down=false;mouse_stick=false;mouse_axis=Vector2.ZERO;pad_axis=Vector2.ZERO
	world.stop_inputs()
	if is_instance_valid(stick):stick.axis=Vector2.ZERO;stick.active=false;stick.queue_redraw()

func set_action(key: String,source: String,down: bool,canceled: bool=false) -> void:
	var sources: Dictionary=held.get(key,{})
	var before:=not sources.is_empty()
	if down:sources[source]=true
	else:sources.erase(source)
	held[key]=sources
	var after:=not sources.is_empty()
	if before==after:return
	match key:
		"jump":
			if after:world.jump_press()
			else:world.jump_release(not canceled)
		"attack":
			if after:world.attack_press()
			else:world.attack_release()
		"grenade":
			if after:world.throw_grenade()
		"boost":world.boost_held=after

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT or what==NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		release_all()
		if is_instance_valid(ui) and world.state=="playing":toggle_pause()

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadMotion and event.axis==JOY_AXIS_TRIGGER_RIGHT:
		if menu_kind=="":set_action("attack","trigger",event.axis_value>.5)
		get_viewport().set_input_as_handled();return
	if event is InputEventJoypadButton:
		if menu_kind!="":
			if not event.pressed:return
			if event.button_index in [JOY_BUTTON_DPAD_DOWN,JOY_BUTTON_DPAD_RIGHT]:menu_focus(1)
			elif event.button_index in [JOY_BUTTON_DPAD_UP,JOY_BUTTON_DPAD_LEFT]:menu_focus(-1)
			elif event.button_index in [JOY_BUTTON_A,JOY_BUTTON_X]:
				var focus:=get_viewport().gui_get_focus_owner()
				if focus is Button and focus.is_inside_tree() and focus.is_visible_in_tree() and not focus.disabled:focus.pressed.emit()
			elif event.button_index in [JOY_BUTTON_B,JOY_BUTTON_START] and menu_kind=="paused":close_menu()
			get_viewport().set_input_as_handled();return
		if event.button_index==JOY_BUTTON_START and event.pressed:toggle_pause();get_viewport().set_input_as_handled();return
		for key in ["jump","attack","shoot","duck","boost"]:
			if event.button_index==pad.bindings[key]:set_action({"shoot":"attack","duck":"grenade"}.get(key,key),"pad"+str(event.button_index),event.pressed)
		if event.pressed and event.button_index==interact_binding():world.interact()
		get_viewport().set_input_as_handled();return
	if menu_kind!="":return
	if event is InputEventScreenTouch:
		var p: Vector2=screen_transform.affine_inverse()*event.position
		if event.pressed and not event.canceled:
			for key in actions:
				if actions[key].hit(p):touch_actions[event.index]=key;set_action(key,"touch"+str(event.index),true);get_viewport().set_input_as_handled();return
			if is_instance_valid(stick) and stick_touch<0 and Rect2(stick.position,stick.size).has_point(p):
				stick_touch=event.index;stick.axis=stick.value(p);stick.active=true;stick.queue_redraw();get_viewport().set_input_as_handled()
		else:
			if touch_actions.has(event.index):set_action(str(touch_actions[event.index]),"touch"+str(event.index),false,event.canceled);touch_actions.erase(event.index);get_viewport().set_input_as_handled()
			if event.index==stick_touch:stick_touch=-1;stick.axis=Vector2.ZERO;stick.active=false;stick.queue_redraw();get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if event.index==stick_touch:stick.axis=stick.value(screen_transform.affine_inverse()*event.position);stick.queue_redraw();get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.device!=InputEvent.DEVICE_ID_EMULATION:
		var p: Vector2=screen_transform.affine_inverse()*event.position
		if event.button_index==MOUSE_BUTTON_LEFT:
			if not event.pressed:
				for key in actions:set_action(key,"mouse-touch",false)
				mouse_stick=false;mouse_axis=Vector2.ZERO
				if is_instance_valid(stick):stick.axis=Vector2.ZERO;stick.active=false;stick.queue_redraw()
				set_action("attack","mouse",false)
			else:
				for key in actions:
					if actions[key].hit(p):set_action(key,"mouse-touch",true);get_viewport().set_input_as_handled();return
				if is_instance_valid(stick) and Rect2(stick.position,stick.size).has_point(p):mouse_stick=true;mouse_axis=stick.value(p);stick.axis=mouse_axis;stick.active=true;stick.queue_redraw();get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and mouse_stick:
		mouse_axis=stick.value(screen_transform.affine_inverse()*event.position);stick.axis=mouse_axis;stick.queue_redraw();get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.echo:return
		if event.keycode==KEY_ESCAPE and event.pressed:toggle_pause();get_viewport().set_input_as_handled();return
		if menu_kind!="":return
		match event.physical_keycode:
			KEY_A,KEY_LEFT:left_down=event.pressed
			KEY_D,KEY_RIGHT:right_down=event.pressed
			KEY_SPACE:set_action("jump","keyboard",event.pressed)
			KEY_F,KEY_J:set_action("attack","key"+str(event.physical_keycode),event.pressed)
			KEY_G:set_action("grenade","keyboard",event.pressed)
			KEY_SHIFT:set_action("boost","keyboard",event.pressed)
			KEY_E:
				if event.pressed:world.interact()
		get_viewport().set_input_as_handled()
	if event is InputEventMouseButton and event.device!=InputEvent.DEVICE_ID_EMULATION and menu_kind=="" and event.button_index==MOUSE_BUTTON_LEFT:
		set_action("attack","mouse",event.pressed);get_viewport().set_input_as_handled()

func menu_focus(delta: int) -> void:
	if buttons.is_empty():return
	var focused:=get_viewport().gui_get_focus_owner()
	if focused in buttons:focus_index=buttons.find(focused)
	focus_index=posmod(focus_index+delta,buttons.size());buttons[focus_index].grab_focus()

func interact_binding() -> int:
	for candidate in [JOY_BUTTON_Y,JOY_BUTTON_X,JOY_BUTTON_A,JOY_BUTTON_B,JOY_BUTTON_LEFT_SHOULDER,JOY_BUTTON_RIGHT_SHOULDER]:
		if candidate not in pad.bindings.values():return candidate
	return JOY_BUTTON_Y

func pad_help() -> String:
	return t("move")+" ← → · "+pad.binding_name("jump")+" "+old("control_jump")+" · "+pad.binding_name("shoot")+" "+old("control_shoot")+" · "+pad.binding_name("duck")+" "+t("grenade")+" · "+str(pad.NAMES[interact_binding()])+" "+t("ride")

func poll_pad() -> void:
	pad_axis=Vector2.ZERO
	var pads:=Input.get_connected_joypads()
	if pads.is_empty():return
	var id: int=pads[0]
	if menu_kind!="":
		var vertical:=Input.get_joy_axis(id,JOY_AXIS_LEFT_Y)
		if absf(vertical)>.55 and pad_menu_wait<=0.:menu_focus(1 if vertical>0. else -1);pad_menu_wait=.25
		if absf(vertical)<.2:pad_menu_wait=0.
		return
	var axis:=Input.get_joy_axis(id,JOY_AXIS_LEFT_X)
	if absf(axis)>pad.deadzone:pad_axis.x=signf(axis)*inverse_lerp(pad.deadzone,1.,absf(axis))
	if Input.is_joy_button_pressed(id,JOY_BUTTON_DPAD_LEFT):pad_axis.x=-1.
	if Input.is_joy_button_pressed(id,JOY_BUTTON_DPAD_RIGHT):pad_axis.x=1.

func start_travel() -> void:
	release_all();fade=0.;fade_loaded=false

func _process(dt: float) -> void:
	if not is_instance_valid(view):return
	pad_menu_wait=maxf(0.,pad_menu_wait-dt)
	poll_pad()
	if world.state=="playing" and menu_kind=="" and fade<0.:
		var axis: float=float(right_down)-float(left_down)
		if absf(pad_axis.x)>.01:axis=pad_axis.x
		if mouse_stick:axis=mouse_axis.x
		if stick_touch>=0 and is_instance_valid(stick):axis=stick.axis.x
		world.move_axis=Vector2(axis,0)
		if world.character=="wolf" and (stick_touch>=0 or mouse_stick):world.boost_held=absf(axis)>.85 or not Dictionary(held.get("boost",{})).is_empty()
		world.step(dt)
	if world.state=="travel" and fade<0.:start_travel()
	if world.state in ["victory","dying"]:world.step(dt)
	if fade>=0.:
		fade+=minf(dt,.05)
		if fade>=.18 and not fade_loaded:
			world.finish_travel();view.camera_x=0.;view.camera_y=0.;fade_loaded=true;boss_announced=false;save_checkpoint()
		fade_panel.color.a=clampf(fade/.18 if not fade_loaded else (0.36-fade)/.18,0.,1.)
		if fade>=.36:fade=-1.;fade_panel.color.a=0.
	if fade<0. and world.section=="arena" and not boss_announced and world.state=="playing" and absf(world.player.x-float(world.boss.x))<view.scene_w*.40:
		boss_announced=true;world.stop_inputs();world.state="story";menu_kind="boss";build_ui()
	if menu_kind=="" and world.state in ["fork_one","fork_two","dead","complete"]:
		menu_kind=world.state;release_all()
		if world.state=="complete":menu_kind="outro";save_checkpoint()
		build_ui()
	for event in world.pending_events:
		if event=="checkpoint" and menu_kind!="briefing":save_checkpoint()
		if event in ["shot","melee","grenade","blast","pickup","rescue","hurt"]:sound(event)
	world.pending_events.clear()
	# Camera movement follows physics, never an atlas bounding box or ear tip.
	view.camera_x=clampf(world.player.x-view.scene_w*.34,0.,maxf(0.,world.length()-view.scene_w))
	var desired_y:=minf(0.,world.player.y+225.)
	view.camera_y=desired_y if options.reduced_motion else lerpf(view.camera_y,desired_y,1.-exp(-minf(dt,.05)*9.))
	view.queue_redraw();update_hud()
	telemetry_clock+=dt
	if telemetry_clock>.1:telemetry_clock=0.;metadata()
	last_state=world.state

func update_hud() -> void:
	if not is_instance_valid(hud):return
	hud.text="%05d" % world.score+("\n" if portrait or options.text_scale>1. else "  ·  ")+t("lives")+" %d/%d" % [world.hp,world.max_hp]+"  ·  "+t("grenade")+" %d" % world.grenades
	subtitle.text=t("mission")+" · "+t(world.section)
	if world.weapon!="pistol":subtitle.text+="\n"+t(world.weapon)+" %d" % world.ammunition
	elif world.shield>0:subtitle.text+=" · "+t("shield")+" %d" % world.shield
	if world.notice_time>0. and world.notice!="":subtitle.text+="\n"+t(world.notice)
	if not save_ok:subtitle.text+="\n"+t("save_failed")
	var active_controls: bool=menu_kind=="" and fade<0. and world.state=="playing"
	pause_button.visible=active_controls
	boss_health.visible=world.section=="arena" and bool(world.boss.active) and menu_kind==""
	boss_health.value=world.boss.hp
	ride_button.visible=active_controls and bool(world.mount.available) and int(world.mount.hp)>0 and (bool(world.mount.ridden) or absf(world.player.x-float(world.mount.x))<110.)
	if is_instance_valid(stick):stick.visible=active_controls
	for key in actions:
		var item: AionCampaignTouch=actions[key];item.visible=active_controls;item.pressed=not Dictionary(held.get(key,{})).is_empty()
		if key=="attack":
			var near:=not world.close_enemy().is_empty() and not bool(world.mount.ridden)
			item.action="melee" if near else "shoot";item.caption=t("melee") if near else old("control_shoot");item.cooldown=world.fire_time/.32
		if key=="grenade":item.disabled=world.grenades<=0;item.cooldown=world.grenade_time/.55
		item.queue_redraw()

func sound(event: String) -> void:
	if not audio_enabled:return
	if voices.is_empty():
		for i in 6:
			var voice:=AudioStreamPlayer.new();add_child(voice);voices.append(voice)
	if not sound_cache.has(event):
		var bytes:=PackedByteArray();var count:=3600 if event in ["blast","hurt"] else 1400
		var pitch: float={"shot":520.,"melee":210.,"grenade":350.,"blast":75.,"pickup":880.,"rescue":660.,"hurt":140.}[event]
		for i in count:
			var phase: float=float(i)/22050.;var envelope: float=pow(1.-float(i)/count,2.)
			var sample:=sin(phase*pitch*TAU*(1.-float(i)/count*.4))*envelope*.22
			bytes.append_array(PackedByteArray([int(sample*32700.)&255,(int(sample*32700.)>>8)&255]))
		var stream:=AudioStreamWAV.new();stream.format=AudioStreamWAV.FORMAT_16_BITS;stream.mix_rate=22050;stream.data=bytes;sound_cache[event]=stream
	for voice in voices:
		if not voice.playing:voice.stream=sound_cache[event];voice.volume_db=linear_to_db(maxf(.001,audio_volume));voice.play();break
	if event=="hurt" and pad.haptics:
		for id in Input.get_connected_joypads():Input.start_joy_vibration(id,.2,.35,.1)

func metadata() -> void:
	if not OS.has_feature("web"):return
	accessible_update()
	var data: Dictionary=world.snapshot()
	data.merge({"state":world.state,"menu":menu_kind,"section":world.section,"player":[world.player.x,world.player.y],"facing":world.facing,"hp":world.hp,"shots":world.shots,"grenades":world.grenades,"melee":world.melee_time,"mounted":world.mount.ridden,"boss_hp":world.boss.hp,"save_ok":save_ok,"view":[view_w,view_h],"camera":view.camera_x,"pose":view.hero_marker,"actions":{},"transform":[screen_transform.x.x,screen_transform.origin.x,screen_transform.origin.y],"enemies":[],"platforms":[],"gates":[],"pits":[]})
	for key in actions:data.actions[key]=[actions[key].position.x,actions[key].position.y,actions[key].size.x,actions[key].size.y]
	if is_instance_valid(stick):data.stick=[stick.position.x,stick.position.y,stick.size.x,stick.size.y]
	for e in world.enemies:
		if not bool(e.defeated):data.enemies.append({"kind":e.kind,"x":e.x,"y":e.y,"hp":e.hp,"windup":e.windup})
	for p in world.platforms:data.platforms.append([p.position.x,p.position.y,p.size.x,p.size.y])
	for g in world.gates:data.gates.append({"x":g.x,"closed":world.gate_closed(g)})
	for p in world.pits:data.pits.append([p.x,p.y])
	var rects: Dictionary={}
	if ui_ready:
		for b in buttons:
			if is_instance_valid(b) and b.is_inside_tree() and b.is_visible_in_tree():rects[b.name]=[b.global_position.x,b.global_position.y,b.size.x,b.size.y,b.text]
	data.buttons=rects
	data.ui_generation=ui_generation
	data.ui_ready=ui_ready
	data.raw=[get_viewport_rect().size.x,get_viewport_rect().size.y]
	data.velocity=[world.velocity.x,world.velocity.y]
	data.bullets=[]
	for bullet in world.bullets:
		if bullet.owner=="enemy":data.bullets.append([bullet.p.x,bullet.p.y,bullet.v.x,bullet.v.y])
	data.grounded=world.grounded();data.invulnerable=world.invulnerable
	JavaScriptBridge.eval("document.getElementById('canvas')?.setAttribute('data-campaign',"+JSON.stringify(JSON.stringify(data))+");")

func accessible_action(args: Array) -> void:
	if args.size()<2:return
	var item=instance_from_id(int(str(args[1])))
	if not is_instance_valid(item) or not item is Button or not item.is_inside_tree() or not ui.is_ancestor_of(item) or not item.is_visible_in_tree() or item.disabled:return
	if str(args[0])=="focus":item.grab_focus()
	elif str(args[0])=="activate":item.pressed.emit()

func accessible_update() -> void:
	if not ui_ready:return
	var entries:=[]
	for item in ui.find_children("*","Button",true,false):
		if item.is_visible_in_tree():entries.append({"id":str(item.get_instance_id()),"label":item.tooltip_text if item.text=="II" else item.text,"disabled":item.disabled,"toggle":false,"pressed":false})
	var payload:=JSON.stringify({"items":entries,"language":language,"page":menu_kind,"summary":t(menu_kind) if menu_kind!="" else t(world.section)+" · "+old("score")+" "+str(world.score)})
	if payload==accessibility_stamp:return
	accessibility_stamp=payload
	var api=JavaScriptBridge.get_interface("AionAccessibility")
	if api!=null:api.update(payload)
