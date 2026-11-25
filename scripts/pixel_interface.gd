class_name RunnerPixelInterface
extends RefCounted
var host
var roster_previews: Dictionary = {}

func open_campaign_picker() -> void:
	if host.campaign_started:return
	host.opening_guide=false
	host.open_subpage("characters")

func play_campaign() -> void:
	if host.opening_guide:open_campaign_picker()
	else:host.start_campaign()

func confirm_hero() -> void:
	if host.page=="characters":host.start_campaign()

func refresh_preview_state(tile: Button,image: RunnerHeroPreview,id: String) -> void:
	if not is_instance_valid(image):return
	image.set_select_state("select" if id==host.character else ("focus" if tile.has_focus() or tile.is_hovered() else "idle"))

func stage_y() -> float:
	return host.view_h*.74

func hud() -> void:
	var h = host
	h.hud = Control.new()
	h.hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.ui.add_child(h.hud)
	var band := Panel.new()
	band.name="ScoreBand"
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.add_theme_stylebox_override("panel",h.box("211c29ed","6e556d"))
	h.hud.add_child(band)
	h.position_control(band,Vector2.ZERO,Vector2(h.view_w,ceilf(h.ui_size(24)*1.25+16)))
	var stats := HBoxContainer.new()
	stats.name="ScoreStats"
	stats.add_theme_constant_override("separation",24)
	if h.portrait:stats.add_theme_constant_override("separation",14)
	h.hud.add_child(stats)
	stats.position = Vector2(18,8)
	for key in ["score","best","gems"]:
		var stack := HBoxContainer.new()
		stack.add_theme_constant_override("separation",8)
		stats.add_child(stack)
		stack.add_child(h.label(h.text(key),14,"c6a8a5"))
		var value: Label = h.label("00000",24,"f8db96" if key=="score" else "f5e6ce")
		stack.add_child(value)
		if key=="score":h.score_label=value
		elif key=="best":h.best_label=value
		else:h.crystal_label=value
	h.pause_button=h.button(h.text("pause"),h.pause_run)
	h.pause_button.name="PauseRun"
	h.pause_button.custom_minimum_size=Vector2.ZERO
	h.pause_button.add_theme_font_size_override("font_size",h.ui_size(24 if h.touch_mode else 20))
	for state in ["normal","hover","pressed","focus","disabled"]:
		var style: StyleBoxFlat=h.pause_button.get_theme_stylebox(state).duplicate()
		style.content_margin_top=4;style.content_margin_bottom=4
		h.pause_button.add_theme_stylebox_override(state,style)
	h.hud.add_child(h.pause_button)
	var pause_width: float=maxf(116,h.pause_button.get_combined_minimum_size().x)
	h.position_control(h.pause_button,Vector2(h.view_w-pause_width-8,4),Vector2(pause_width,band.size.y-8))
	if h.portrait:stats.get_child(1).hide()
	h.biome_label=h.label("",18,"eed3b4")
	h.hud.add_child(h.biome_label)
	h.position_control(h.biome_label,Vector2(18,band.size.y+6),Vector2(h.view_w-36,28))
	h.biome_label.clip_text=true
	h.progress=ProgressBar.new()
	h.progress.max_value=h.world.BIOME_DISTANCE
	h.progress.show_percentage=false
	h.progress.visible=false
	h.hud.add_child(h.progress)
	h.level_label=h.label("",19,"f8db96")
	h.hud.add_child(h.level_label)
	h.position_control(h.level_label,Vector2(18,band.size.y+36),Vector2(210,26))
	h.ammo_label=h.label("",18,"f8db96")
	h.hud.add_child(h.ammo_label)
	h.position_control(h.ammo_label,Vector2(18,130),Vector2(420,28))
	h.level_progress=ProgressBar.new()
	h.level_progress.max_value=1.0
	h.level_progress.show_percentage=false
	h.level_progress.mouse_filter=Control.MOUSE_FILTER_IGNORE
	h.level_progress.add_theme_stylebox_override("background",h.box("302437","796176"))
	var fill: StyleBoxFlat=h.box("da8d77","f4c190")
	fill.set_content_margin_all(0)
	h.level_progress.add_theme_stylebox_override("fill",fill)
	h.hud.add_child(h.level_progress)
	h.position_control(h.level_progress,Vector2(18,134),Vector2(174,8))
	h.xp_label=h.label("",17,"f8db96")
	h.xp_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	h.xp_label.clip_text=true
	h.hud.add_child(h.xp_label)
	h.position_control(h.xp_label,Vector2(h.view_w-238,band.size.y+36),Vector2(220,26))
	h.xp_progress=ProgressBar.new()
	h.xp_progress.max_value=100
	h.xp_progress.show_percentage=false
	h.xp_progress.mouse_filter=Control.MOUSE_FILTER_IGNORE
	h.xp_progress.add_theme_stylebox_override("background",h.box("302437","796176"))
	var xp_fill := StyleBoxFlat.new()
	xp_fill.bg_color=h.interface_options.color("accent")
	xp_fill.border_color=h.interface_options.color("text")
	xp_fill.set_border_width_all(1)
	h.xp_progress.add_theme_stylebox_override("fill",xp_fill)
	h.hud.add_child(h.xp_progress)
	h.position_control(h.xp_progress,Vector2(h.view_w-192,134),Vector2(174,8))
	h.power_label=h.label("",18,"f5dbbd")
	h.hud.add_child(h.power_label)
	h.position_control(h.power_label,Vector2(18,160),Vector2(h.view_w-36,24))
	h.power_label.clip_text=true
	h.goal_label=h.label("",17,"d4b6b2")
	h.hud.add_child(h.goal_label)
	h.position_control(h.goal_label,Vector2(18,188),Vector2(h.view_w-36,24))
	h.footer_label=h.wrap_label(h.text("touch_hint") if h.touch_mode else h.text("hint"),18,"e6c8b0")
	h.ui.add_child(h.footer_label)
	h.position_control(h.footer_label,Vector2(18,h.view_h-84 if h.touch_mode else h.view_h-26),Vector2(h.view_w-420 if not h.portrait else 128,74 if h.touch_mode else 25))
	if h.touch_mode and h.interface_options.touch_layout=="split":
		var left: float=224 if h.character=="wolf" else 124
		h.position_control(h.footer_label,Vector2(left,h.view_h-82),Vector2(h.view_w-left-218,76))
		h.footer_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	h.ability_label=h.wrap_label("",18,"eedbb6")
	h.ui.add_child(h.ability_label)
	h.position_control(h.ability_label,Vector2(18,h.view_h-(164 if h.portrait else 162) if h.touch_mode else h.view_h-56),Vector2(220 if h.portrait else h.view_w-360,40 if h.portrait and h.touch_mode else 32))
	if h.portrait and h.touch_mode:h.ability_label.autowrap_mode=TextServer.AUTOWRAP_OFF
	h.boss_label=h.label("",21,"f4c68b")
	h.ui.add_child(h.boss_label)
	h.boss_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	h.position_control(h.boss_label,Vector2(18,205),Vector2(h.view_w-36,96 if h.portrait else 36))
	h.boss_bar=ProgressBar.new()
	h.boss_bar.show_percentage=false
	h.boss_bar.add_theme_stylebox_override("background",h.box("302437","796176"))
	h.boss_bar.add_theme_stylebox_override("fill",h.box("c75772","e7a497"))
	h.ui.add_child(h.boss_bar)
	h.position_control(h.boss_bar,Vector2(18,310 if h.portrait else 246),Vector2(h.view_w-36,12))
	h.notice_label=h.label("",23,"ffe0a3")
	h.notice_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	h.ui.add_child(h.notice_label)
	h.notice_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	h.position_control(h.notice_label,Vector2(12,338 if h.portrait else 272),Vector2(h.view_w-24,62 if h.portrait else 34))
	if h.interface_options.text_scale>1.0:
		band.size.y=ceilf(h.ui_size(24)*1.25+16)
		stats.add_theme_constant_override("separation",20)
		stats.get_child(1).hide()
		stats.get_child(2).hide()
		h.position_control(h.pause_button,Vector2(h.view_w-pause_width-8,4),Vector2(pause_width,band.size.y-8))
		h.pause_button.add_theme_font_size_override("font_size",h.ui_size(24 if h.touch_mode else 20))
		h.position_control(h.level_label,Vector2(18,band.size.y+8),Vector2(h.view_w-36,65))
		h.position_control(h.ammo_label,Vector2(h.view_w-234,136),Vector2(216,65))
		h.position_control(h.boss_label,Vector2(18,228),Vector2(h.view_w-36,190))
		h.position_control(h.boss_bar,Vector2(18,426),Vector2(h.view_w-36,12))
		h.position_control(h.notice_label,Vector2(18,448),Vector2(h.view_w-36,96))
	h.notice_label.clip_text=true
	for node in h.hud.find_children("*","Label",true,false):
		node.add_theme_color_override("font_outline_color",Color("201a2b"))
		node.add_theme_constant_override("outline_size",2)

func card(width: float) -> VBoxContainer:
	var h=host
	width=minf(width,h.view_w-40)
	if h.page=="main":width=minf(760.,h.view_w-48.)
	var enlarged: bool=h.interface_options.text_scale>1.0
	if enlarged and h.page!="main":width=h.view_w-40
	var height: float=minf(h.view_h-120,410.)
	if h.page=="settings" or (enlarged and h.page!="main"):height=h.view_h-92
	var panel:=PanelContainer.new()
	panel.name="PagePanel"
	if h.page=="main":
		panel.set_script(preload("res://scripts/arcade_menu_frame.gd"))
		panel.palette=h.interface_options.colors
		height=20.
	h.menu_layer.add_child(panel)
	var pos:=Vector2((h.view_w-width)*.5,maxf(82.,(h.view_h-height)*.5))
	if h.page=="main":pos.y=88.
	if enlarged and h.page!="main":pos=Vector2(20,84)
	h.position_control(panel,pos.floor(),Vector2(floorf(width),floorf(height)))
	var column:=VBoxContainer.new()
	column.add_theme_constant_override("separation",8)
	column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	if h.page!="main":
		var root:=VBoxContainer.new()
		panel.add_child(root)
		root.add_child(column)
		column.size_flags_vertical=Control.SIZE_EXPAND_FILL
		column.set_meta("page_width",width-28)
		column.set_meta("page_height",height-28)
	else:panel.add_child(column)
	return column

func main(column: VBoxContainer) -> Button:
	var h=host
	var header: BoxContainer=VBoxContainer.new() if h.portrait else HBoxContainer.new()
	header.alignment=BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation",10)
	column.add_child(header)
	var title: Label=h.label("AION",36,"f8d9b1")
	title.name="ArcadeTitle"
	title.add_theme_font_size_override("font_size",h.ui_size(34))
	title.add_theme_font_override("font",h.FONT)
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(title)
	var mission: Label=h.label(AionCampaignText.word(h.language,"title"),20,"f2d5a6")
	mission.add_theme_font_size_override("font_size",h.ui_size(20))
	mission.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	mission.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	header.add_child(mission)
	if h.opening_guide:
		var guide: Label=h.label(RunnerFrontText.word(h.language,"how"),20,"ffe1b9")
		guide.add_theme_font_size_override("font_size",h.ui_size(20))
		guide.name="OpeningGuide"
		column.add_child(guide)
		var controls:=GridContainer.new()
		controls.columns=1 if h.portrait else 2
		controls.add_theme_constant_override("h_separation",12)
		controls.add_theme_constant_override("v_separation",3)
		column.add_child(controls)
		for line in RunnerFrontText.quick_controls(h.language,h.active_input,h.touch_mode,h.gamepad):
			var hint: Label=h.label(line,18)
			hint.add_theme_font_size_override("font_size",h.ui_size(19))
			hint.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			controls.add_child(hint)
	var start_row: BoxContainer=VBoxContainer.new() if h.portrait else HBoxContainer.new()
	start_row.add_theme_constant_override("separation",8);column.add_child(start_row)
	var arcade: Button=h.button(AionCampaignText.word(h.language,"continue_choose" if h.opening_guide else "arcade"),play_campaign,true)
	arcade.name="StartCampaign"
	start_row.add_child(arcade)
	if h.has_campaign_checkpoint():
		var resume: Button=h.button(AionCampaignText.word(h.language,"continue_short"),func():h.start_campaign(true))
		resume.name="ContinueCampaign"
		start_row.add_child(resume)
	var utilities:=start_row
	if not h.opening_guide:
		utilities=VBoxContainer.new() if h.portrait else HBoxContainer.new()
		utilities.add_theme_constant_override("separation",8);column.add_child(utilities)
		var choose: Button=h.button(AionCampaignText.word(h.language,"continue_choose"),open_campaign_picker)
		choose.name="ChooseHero";utilities.add_child(choose)
		var help: Button=h.button(RunnerFrontText.word(h.language,"how"),func():h.open_subpage("help"))
		help.name="HowToPlay"
		utilities.add_child(help)
	var settings: Button=h.button(h.text("settings"),func():h.open_subpage("settings"))
	settings.name="OpenSettings"
	utilities.add_child(settings)
	for control in start_row.get_children()+(utilities.get_children() if utilities!=start_row else []):
		control.autowrap_mode=TextServer.AUTOWRAP_OFF
		control.add_theme_font_size_override("font_size",h.ui_size(20))
		control.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	center_main.call_deferred(column,h.layout_generation)
	return arcade

func center_main(column: VBoxContainer,generation: int) -> void:
	if not is_instance_valid(column) or generation!=host.layout_generation:return
	var panel: PanelContainer=column.get_parent()
	var inset: Vector2=panel.get_theme_stylebox("panel").get_minimum_size()
	var fit: Vector2=column.get_combined_minimum_size()+inset
	panel.size.y=ceilf(fit.y)
	panel.position.x=floorf((host.view_w-panel.size.x)*.5)
	panel.position.y=maxf(70.,floorf((host.view_h-panel.size.y)*.5))

func characters() -> void:
	var h=host
	roster_previews.clear()
	var stage:=Control.new()
	stage.name="HeroSelection"
	stage.mouse_filter=Control.MOUSE_FILTER_IGNORE
	h.menu_layer.add_child(stage)
	var width: float=floorf(minf(1176.,h.view_w-48.))
	var top:=74.
	var height: float=h.view_h-top-24.
	h.position_control(stage,Vector2((h.view_w-width)*.5,top),Vector2(width,height))
	var heading: Label=h.label(RunnerFrontText.word(h.language,"pick_hero"),28,"ffe1b9")
	heading.add_theme_font_override("font",h.FONT)
	heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_color",Color("fff0ce"))
	heading.add_theme_color_override("font_outline_color",Color("23202b"))
	heading.add_theme_constant_override("outline_size",5)
	heading.mouse_filter=Control.MOUSE_FILTER_IGNORE
	stage.add_child(heading)
	var head: float=ceilf(heading.get_minimum_size().y)+12.
	var col_count: int=2 if h.portrait else 3
	var gap:=10.
	if not h.portrait:
		var name_width:=0.
		for id in h.FRIENDS:
			name_width=maxf(name_width,h.ui_theme.default_font.get_string_size(h.character_name(id),HORIZONTAL_ALIGNMENT_LEFT,-1,h.ui_size(21)).x)
		if name_width+8.<=floorf((width-5.*gap)/6.):col_count=6
	var row_count:=ceili(float(h.FRIENDS.size())/col_count)
	var tile_w:=floorf((width-(col_count-1)*gap)/col_count)
	var confirm: Button=h.button(RunnerFrontText.word(h.language,"play_now"),confirm_hero,true)
	confirm.name="ConfirmHero"
	var back: Button=h.button(h.text("back"),func():h.show_page(h.return_page))
	back.name="CharacterBack"
	for control in [confirm,back]:
		control.autowrap_mode=TextServer.AUTOWRAP_OFF
		stage.add_child(control)
	var footer_h: float=maxf(confirm.get_combined_minimum_size().y,back.get_combined_minimum_size().y)+8.
	var tile_h:=floorf((height-head-footer_h-row_count*gap)/row_count)
	if col_count==6:tile_h=minf(tile_h,tile_w+float(h.ui_size(34)))
	var font: Font=h.ui_theme.default_font
	var motivation_size: int=h.ui_size(19 if h.portrait or h.touch_mode else 16)
	var story_height:=0.
	var summary_height:=0.
	# Themed labels can reserve more height than bare Font metrics, especially
	# for wrapped lines in the 200% layout with an alternate system font.
	var metrics:=roster_motivation("",motivation_size,tile_w-16.)
	stage.add_child(metrics)
	for id in h.FRIENDS:
		metrics.text=RunnerFrontText.motivation(h.language,id)
		story_height=maxf(story_height,metrics.get_minimum_size().y)
	metrics.size.x=width-16.
	for id in h.FRIENDS:
		metrics.text=RunnerFrontText.motivation(h.language,id)
		summary_height=maxf(summary_height,metrics.get_minimum_size().y)
	metrics.free()
	story_height=ceilf(story_height)+8.
	summary_height=ceilf(summary_height)+10.
	var label_height:=ceilf(font.get_height(h.ui_size(21)))+10.
	var story_in_tile: bool=tile_h-label_height-story_height>=minf(70.,tile_w*.53)
	var space_for_summary: float=0. if story_in_tile else summary_height
	if not story_in_tile:
		tile_h=minf(tile_h,floorf((height-head-footer_h-row_count*gap-space_for_summary)/row_count))
	var group_top:=floorf(maxf(0.,height-head-footer_h-row_count*(tile_h+gap)-space_for_summary)*.5)
	var footer_y:=group_top+head+row_count*(tile_h+gap)+space_for_summary
	h.position_control(heading,Vector2(0.,group_top),Vector2(width,head-12.))
	var selected: Button
	for index in h.FRIENDS.size():
		var id: String=h.FRIENDS[index]
		var tile: Button=h.button("",func():h.select_character(id),id==h.character)
		tile.name="Select_"+id
		tile.accessibility_name=h.character_name(id)
		var motivation:=RunnerFrontText.motivation(h.language,id)
		tile.accessibility_description=motivation+" "+RunnerFrontText.ability_summary(h.language,id)
		tile.accessibility_name+=" · "+RunnerFrontText.word(h.language,"selected") if id==h.character else ""
		tile.custom_minimum_size.y=minf(tile.custom_minimum_size.y,tile_h)
		stage.add_child(tile)
		h.position_control(tile,Vector2((index%col_count)*(tile_w+gap),group_top+head+floori(float(index)/col_count)*(tile_h+gap)),Vector2(tile_w,tile_h))
		var portrait_art:=RunnerHeroPreview.new()
		portrait_art.name="Portrait"
		portrait_art.hero=id
		portrait_art.portrait_art=true
		portrait_art.animate=h.decorative_motion()
		portrait_art.set_select_state("select" if id==h.character else "idle")
		tile.add_child(portrait_art)
		roster_previews[id]=portrait_art
		var name_label: Label=h.label(h.character_name(id),18,"fff1d5")
		name_label.name="HeroName"
		name_label.add_theme_font_size_override("font_size",h.ui_size(21))
		name_label.add_theme_color_override("font_color",h.interface_options.color("on_primary" if id==h.character else "text"))
		name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		name_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		name_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
		tile.add_child(name_label)
		var name_h: float=ceilf(name_label.get_minimum_size().y)+8.
		var name_y: float=tile_h-name_h-2.-(story_height if story_in_tile else 0.)
		var side_width:=minf(tile_h-4.,tile_w-name_label.get_minimum_size().x-16.)
		if not h.portrait and not story_in_tile and name_y<58. and side_width>=40.:
			h.position_control(portrait_art,Vector2(2.,2.),Vector2(side_width,tile_h-4.))
			var name_x:=side_width+8.
			h.position_control(name_label,Vector2(name_x,2.),Vector2(tile_w-name_x-4.,tile_h-4.))
		else:
			var art_height:=maxf(2.,name_y)
			var art_width:=tile_w-4.
			if not h.portrait:art_width=minf(art_width,floorf(art_height*1.32))
			h.position_control(portrait_art,Vector2(floorf((tile_w-art_width)*.5),2.),Vector2(art_width,art_height))
			h.position_control(name_label,Vector2(4.,name_y),Vector2(tile_w-8.,name_h))
		if story_in_tile:
			var motive_label:=roster_motivation(motivation,motivation_size,tile_w-16.)
			motive_label.add_theme_color_override("font_color",h.interface_options.color("on_primary" if id==h.character else "muted"))
			tile.add_child(motive_label)
			h.position_control(motive_label,Vector2(8.,tile_h-story_height-2.),Vector2(tile_w-16.,story_height-2.))
		if id==h.character:selected=tile
	if not story_in_tile:
		var motive_label:=roster_motivation(RunnerFrontText.motivation(h.language,h.character),motivation_size,width-16.)
		motive_label.add_theme_color_override("font_outline_color",Color("23202b"))
		motive_label.add_theme_constant_override("outline_size",4)
		stage.add_child(motive_label)
		h.position_control(motive_label,Vector2(8.,footer_y-summary_height),Vector2(width-16.,summary_height-4.))
	var back_w: float=maxf(112.,back.get_combined_minimum_size().x+12.)
	stage.move_child(back,-1)
	stage.move_child(confirm,-1)
	h.position_control(back,Vector2(0.,footer_y),Vector2(back_w,footer_h))
	h.position_control(confirm,Vector2(back_w+gap,footer_y),Vector2(width-back_w-gap,footer_h))
	h.focus_later.call_deferred(selected)

func roster_motivation(value: String, point_size: int, width: float) -> Label:
	var item:=Label.new()
	item.name="HeroMotivation"
	# Width has to be set before shaping. At zero width Godot's initial
	# wrapped label minimum can otherwise reserve a line for each character.
	item.size.x=width
	item.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	item.text=value
	item.accessibility_name=value
	item.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	item.add_theme_font_size_override("font_size",point_size)
	item.add_theme_color_override("font_color",Color("fff0ce"))
	item.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	item.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	item.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return item

func tutorial() -> void:
	var h=host
	var panel:=PanelContainer.new()
	h.tutorial_panel=panel
	h.ui.add_child(panel)
	h.position_control(panel,Vector2(18 if h.portrait else h.view_w-520,200 if h.portrait else 80),Vector2(504 if h.portrait else 500,160))
	if h.interface_options.text_scale>1.0:
		h.position_control(panel,Vector2(18,84),Vector2(h.view_w-36,floorf(h.view_h-124)))
	var column:=VBoxContainer.new()
	panel.add_child(column)
	column.add_child(h.wrap_label(h.text("touch_tutorial"),20))
	var done: Button=h.button(h.text("touch_skip"),func():
		h.touch_tutorial_done=true
		h.clear_held_controls()
		panel.hide()
		h.save_settings())
	column.add_child(done)

func fragaria() -> void:
	var h=host
	var panel:=PanelContainer.new()
	h.fragaria_panel=panel
	panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	h.ui.add_child(panel)
	h.position_control(panel,Vector2(maxf(16,(h.view_w-480)*.5),202),Vector2(minf(480,h.view_w-32),126))
	var row:=HBoxContainer.new()
	row.mouse_filter=Control.MOUSE_FILTER_IGNORE
	panel.add_child(row)
	var picture:=TextureRect.new()
	picture.texture=preload("res://assets/fragaria-strawberry.png")
	picture.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.custom_minimum_size=Vector2(62,90)
	picture.mouse_filter=Control.MOUSE_FILTER_IGNORE
	row.add_child(picture)
	var title: Label=h.wrap_label(h.text("fragaria_found")+"\n"+h.text("fragaria_note"),22,"ffe3b4")
	title.mouse_filter=Control.MOUSE_FILTER_IGNORE
	title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	row.add_child(title)
	panel.visible=false
