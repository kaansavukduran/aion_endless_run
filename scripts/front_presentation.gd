class_name RunnerFrontPresentation
extends Node2D
## Authored title presentation and read-only autonomous attract scene.
## The demo has its own rules/view and deliberately owns no persistence API.
const OPENING_VISTA=preload("res://assets/opening-lantern-grove.png")
var host
var intro_time := 0.
var intro_active := true
var idle_time := 0.
var demo_time := 0.
var demo_index := 0
var demo_world: AionCampaignWorld
var demo_view: AionCampaignView
var options
var motion_enabled := true
var scene_w:=1152.
var scene_h:=648.
var portrait: bool:
	get:return scene_h>scene_w
var ground:=440.
var camera_x:=0.
var font: Font
var modal: Control
var frozen:=false
var last_jump:=0.
const DEMOS := [["aion","shore"],["sheep","water"],["rabbit","terrace"],["eren","arena"]]
const DEMO_BANNER_HEIGHT := 54.
func t(key: String) -> String:return AionCampaignText.word(host.language,key)
func font_size(size: int) -> int:return roundi(size*options.text_scale)
func world_hud_bottom() -> float:return DEMO_BANNER_HEIGHT
func copy(key: String) -> String:return RunnerFrontText.word(host.language,key)
func begin_intro() -> void:
	stop_demo();intro_time=0.;intro_active=true;idle_time=0.
	host.get_tree().set_meta("aion_intro_seen",true)
	if host.interface_options.reduced_motion:intro_time=4.2
	refresh()
func skip_intro() -> void:
	intro_active=false;intro_time=6.5;idle_time=0.
	refresh();host.refresh_interface_metadata.call_deferred(host.layout_generation)
func input(event: InputEvent) -> bool:
	var intentional: bool=(event is InputEventKey and event.pressed and not event.echo) or (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed) or (event is InputEventScreenDrag) or (event is InputEventMouseMotion and event.relative.length()>2.) or (event is InputEventJoypadButton and event.pressed) or (event is InputEventJoypadMotion and absf(event.axis_value)>.55)
	if not intentional:return false
	idle_time=0.
	if demo_world!=null:stop_demo();return true
	if intro_active and host.page=="main":skip_intro();return true
	return false
func refresh() -> void:
	if is_instance_valid(modal):modal.queue_free()
	if not is_instance_valid(host.ui):return
	var menu_was_visible: bool=host.menu_layer.visible
	modal=Control.new();modal.name="TitlePresentation";modal.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(modal)
	if get_parent()==host.ui:host.ui.move_child(self,host.ui.get_child_count()-1)
	if host.page=="main" and (intro_active or demo_world!=null):
		var skip: Button=host.button(copy("skip") if intro_active else copy("demo"),skip_intro if intro_active else stop_demo)
		skip.name="SkipOpening" if intro_active else "ExitAttract"
		skip.position=Vector2(20,host.view_h-maxf(72.,skip.custom_minimum_size.y)-16.)
		skip.size=Vector2(host.view_w-40,maxf(64.,skip.custom_minimum_size.y))
		modal.add_child(skip)
	host.menu_layer.visible=host.page!="main" or (not intro_active and demo_world==null)
	if host.menu_layer.visible and not menu_was_visible:
		# A demo can hide a just-built menu before its containers ever sort.
		# Report readiness only after the same Godot-frame barrier as rebuild().
		host.ui_layout_ready=false
		host.web_stamp=""
		host.refresh_interface_metadata.call_deferred(host.layout_generation)
	if is_instance_valid(host.language_button):host.language_button.visible=host.page!="main" or (not intro_active and demo_world==null)
	queue_redraw()
func start_demo(index: int=0) -> void:
	if intro_active or host.page!="main":return
	stop_demo();demo_index=posmod(index,DEMOS.size());demo_time=0.;last_jump=0.
	demo_world=AionCampaignWorld.new();demo_world.prewarm_art=false;demo_world.begin(DEMOS[demo_index][0]);demo_world.load_section(DEMOS[demo_index][1])
	demo_view=AionCampaignView.new();demo_view.world=demo_world;demo_view.host=self
	demo_view.font=host.interface_options.body_font
	add_child(demo_view);refresh()
func stop_demo() -> void:
	demo_world=null
	if is_instance_valid(demo_view):demo_view.queue_free()
	demo_view=null;idle_time=0.
	if is_instance_valid(host) and is_instance_valid(host.menu_layer):refresh()
func step(dt: float) -> void:
	options=host.interface_options;motion_enabled=host.decorative_motion();font=options.body_font
	scene_w=host.view_w;scene_h=host.view_h;ground=host.view_h-150.
	visible=host.page=="main"
	if not visible:
		if demo_world!=null:stop_demo()
		return
	if frozen:return
	var elapsed:=minf(dt,.05)
	if intro_active:
		intro_time+=elapsed
		if intro_time>=6.5:skip_intro()
	elif demo_world==null:
		if host.interface_options.attract_enabled and not host.opening_guide and not host.language_picker_open:idle_time+=elapsed
		if idle_time>=30.:start_demo()
	else:
		demo_time+=elapsed
		demo_world.move_axis=Vector2.RIGHT
		demo_world.aim_direction=Vector2.RIGHT
		demo_world.fire_held=true
		if demo_world.character in ["rabbit","eren"]:
			if demo_world.jump_held and demo_time-last_jump>1.:demo_world.jump_release()
			elif not demo_world.jump_held and demo_time-last_jump>2.4:demo_world.jump_press();last_jump=demo_time
		elif demo_time-last_jump>1.4:
			demo_world.jump_release();demo_world.jump_press()
			if demo_world.character!="owl":demo_world.jump_release()
			last_jump=demo_time
		if bool(demo_world.mount.get("available",false)) and not bool(demo_world.mount.ridden) and absf(demo_world.player.x-float(demo_world.mount.x))<100.:demo_world.interact()
		demo_world.step(elapsed)
		camera_x=maxf(0.,demo_world.player.x-scene_w*.3)
		demo_view.scene_w=scene_w;demo_view.scene_h=scene_h;demo_view.ground=ground;demo_view.camera_x=camera_x;demo_view.queue_redraw()
		if demo_time>8. or demo_world.state in ["dead","complete"]:start_demo(demo_index+1)
	queue_redraw()
func _draw() -> void:
	if not is_instance_valid(host) or host.page!="main":return
	var width: float=host.view_w;var height: float=host.view_h
	if intro_active:
		# A dedicated opaque vista prevents the menu's standing hero and floor
		# from leaking through the opening, especially in portrait mode.
		var image_size:=OPENING_VISTA.get_size()
		var scale: float=maxf(width/image_size.x,height/image_size.y)
		var target_size:=image_size*scale
		draw_texture_rect(OPENING_VISTA,Rect2(((Vector2(width,height)-target_size)*.5).floor(),target_size),false)
		var reveal:=smoothstep(0.,.8,intro_time) if host.decorative_motion() else 1.
		if reveal<1.:draw_rect(Rect2(0,0,width,height),Color(0.025,.035,.055,1.-reveal))
		if intro_time>1. or not host.decorative_motion():
			var title: String="AIONIA"
			var fs: int=host.ui_size(44)
			var title_size: Vector2=host.FONT.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,fs)
			draw_string(host.FONT,Vector2((width-title_size.x)*.5,height*.2),title,HORIZONTAL_ALIGNMENT_LEFT,-1,fs,Color("ffcf8c"))
		if intro_time>2.2 or not host.decorative_motion():
			var portrait: bool=height>width
			for i in host.FRIENDS.size():
				var hero: String=host.FRIENDS[i]
				var clip: Dictionary=host.menu_hero_art.clip_spec(hero,"idle_fire")
				# Idle poses stay grounded on the authored wet-stone path; the
				# opening never runs stationary walk cycles or changes body scale.
				var frame: int=0
				if host.decorative_motion():frame=posmod(int(maxf(0.,intro_time-2.2)*3.),int(clip.frames))
				var pose: Dictionary=host.menu_hero_art.pose(hero,"idle_fire",frame)
				var factor: float=float(pose.get("scale",1.))
				var anchor:=Vector2(width*(.12+float(i)*.152),height*.73)
				if portrait:anchor=Vector2(width*(.2+float(i%3)*.3),height*(.71+float(i/3)*.12))
				draw_texture_rect(pose.texture,Rect2((anchor+Vector2(pose.offset)*factor).round(),pose.get("size",pose.texture.get_size()*factor)),false)
	elif demo_world!=null:
		var text: String=copy("demo")
		draw_rect(Rect2(0,0,width,DEMO_BANNER_HEIGHT),Color("181620"))
		draw_string(host.interface_options.body_font,Vector2(18,34),text,HORIZONTAL_ALIGNMENT_LEFT,width-36,host.ui_size(18),Color("ffcf8c"))
