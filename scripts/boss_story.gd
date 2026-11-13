class_name RunnerBossStory
extends RefCounted
var host
var layer: Control
var panel: PanelContainer
var speaker: Label
var dialogue: Label
var next_button: Button
var skip_button: Button
var shown_index := -1

func build() -> void:
	layer=Control.new();layer.name="BossStory";layer.mouse_filter=Control.MOUSE_FILTER_IGNORE
	host.ui.add_child(layer)
	panel=PanelContainer.new();panel.name="StoryDialogue"
	panel.add_theme_stylebox_override("panel",host.box("211c29f5","c39886",12))
	layer.add_child(panel)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",8);panel.add_child(column)
	speaker=host.wrap_label("",18,"f8db96");speaker.name="StorySpeaker";column.add_child(speaker)
	dialogue=host.wrap_label("",22,"f5e6ce");dialogue.name="StoryLine";column.add_child(dialogue)
	var controls:=HBoxContainer.new();controls.add_theme_constant_override("separation",12);column.add_child(controls)
	next_button=host.button(host.text("story_next"),advance);next_button.name="StoryNext";next_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;controls.add_child(next_button)
	skip_button=host.button(host.text("story_skip"),skip);skip_button.name="StorySkip";skip_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;controls.add_child(skip_button)
	shown_index=-1
	update()

func advance() -> void:
	host.clear_held_controls();host.world.frontier.next_story(host.world);shown_index=-1;update()

func skip() -> void:
	host.clear_held_controls();host.world.frontier.next_story(host.world,true);shown_index=-1;update()

func update() -> void:
	if not is_instance_valid(layer):return
	var f=host.world.frontier
	layer.visible=f.storytelling() and host.page==""
	if not layer.visible:return
	var index: int=f.story_index
	var keys: Array=["story_taunt_"+str(f.boss_kind),"story_startled","story_ally_"+str(f.boss_kind)]
	dialogue.text=host.text(keys[index])
	speaker.text=host.text(["boss_name","boss_ray","boss_root"][f.boss_kind]) if index==0 else (host.character_name(host.character) if index==1 else "Fragaria")
	var width: float=host.view_w-36
	panel.position=Vector2(18,18)
	panel.size.x=width
	var column: VBoxContainer=panel.get_child(0)
	var inset: Vector2=panel.get_theme_stylebox("panel").get_minimum_size()
	panel.size.y=ceilf(host.menu_pages.measure(column,width-inset.x)+inset.y)
	if shown_index!=index:
		shown_index=index
		host.web_stamp=""
		if host.active_input=="gamepad":host.focus_later.call_deferred(next_button)
