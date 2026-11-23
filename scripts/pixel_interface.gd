class_name RunnerPixelInterface
extends RefCounted
var host
var roster_page := 0
var roster_previews: Dictionary = {}
var last_roster_capacity := 0

var launch_pending := false
var launch_committed := false
var launch_callback: Callable
var launch_clock := 0.

func request_launch(callback: Callable,quick: bool=false) -> void:
	if launch_pending or launch_committed:return
	launch_pending=true
	launch_callback=callback
	launch_clock=0.
	host.clear_held_controls()
	if quick:
		finish_launch();return
	# A saved selection can be on a different roster page. Show its real card
	# before starting the transition rather than animating another identity.
	if not is_instance_valid(roster_previews.get(host.character,null)):
		roster_page=roster_page_for(host.character)
		host.rebuild()
	trigger_launch_preview(host.character)

func trigger_launch_preview(hero_id: String) -> void:
	var preview=roster_previews.get(hero_id,null)
	if not launch_pending:
		if is_instance_valid(preview):preview.set_select_state("launch")
		return
	if not host.decorative_motion() or not is_instance_valid(preview):
		finish_launch()
		return
	preview.set_select_state("launch")
	preview.clock=launch_clock
	if not preview.launch_finished.is_connected(finish_launch):preview.launch_finished.connect(finish_launch,CONNECT_ONE_SHOT)
	lock_launch_controls(host.menu_layer)

func lock_launch_controls(node: Node) -> void:
	if node is BaseButton:node.disabled=true
	for child in node.get_children():lock_launch_controls(child)

func finish_launch() -> void:
	if not launch_pending or launch_committed:return
	launch_pending=false
	launch_committed=true
	var callback:=launch_callback
	launch_callback=Callable()
	if callback.is_valid():callback.call()

func refresh_preview_state(tile: Button,image: RunnerHeroPreview,id: String) -> void:
	if not is_instance_valid(image):return
	image.set_select_state("launch" if launch_pending and id==host.character else ("select" if id==host.character else ("focus" if tile.has_focus() or tile.is_hovered() else "idle")))

func main_roster_geometry(allow_paging: bool=true) -> Dictionary:
	var width: float=host.view_w-56 if host.portrait else host.view_w*.5-42
	return roster_geometry(width,false,allow_paging,true)

func main_roster_paged() -> bool:
	if host.portrait and (host.interface_options.text_scale>1. or host.FRIENDS.size()>4):return true
	return float(main_roster_geometry(false).total_height)>host.view_h-80.

func paged_roster() -> bool:
	return host.page=="main" and main_roster_paged()

func roster_page_capacity() -> int:
	return int(main_roster_geometry(false).columns) if main_roster_paged() else host.FRIENDS.size()

func roster_page_count() -> int:
	return ceili(float(host.FRIENDS.size())/roster_page_capacity())

func roster_page_for(id: String) -> int:
	return floori(float(maxi(0,host.FRIENDS.find(id)))/roster_page_capacity())


func split_main() -> bool:
	return host.page=="main" and not host.portrait

func roster_width() -> float:
	return host.view_w*.5-42 if split_main() else host.view_w-56

func stage_y() -> float:
	if host.portrait:
		var preview: float=minf(360.0,host.view_h*0.36)
		if host.page=="main":
			# Preserve the actual translated roster and heading. A tall system
			# font needs more room than the old fixed preview/sky allocation.
			preview=minf(preview,roster_y()-chooser_height()-6-8-(520 if host.interface_options.text_scale>1.0 else 350)-26)
		return maxf(140.0,preview)
	var baseline: float=host.view_h-(170.0 if host.touch_mode else 210.0)
	return minf(baseline,roster_y()-12) if host.page=="main" and not split_main() else baseline

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
	if h.page=="main":width=host.view_w*.5-42 if split_main() else minf(640,h.view_w-56)
	var enlarged: bool=h.interface_options.text_scale>1.0
	if enlarged and h.page!="main":width=h.view_w-40
	var height: float=minf(h.view_h-120,410 if h.page!="main" else 340)
	if h.page=="settings" or (enlarged and h.page!="main"):height=h.view_h-92
	if h.page=="main":
		var top: float=stage_y()+26 if h.portrait else (24 if enlarged else 56)
		height=minf(292,roster_y()-chooser_height()-6-top-8)
	if split_main():height=h.view_h-144
	var panel:=PanelContainer.new()
	panel.name="PagePanel"
	if h.page=="main":
		panel.set_script(preload("res://scripts/arcade_menu_frame.gd"));panel.palette=h.interface_options.colors
	h.menu_layer.add_child(panel)
	var pos:=Vector2((h.view_w-width)*.5,maxf(82,(h.view_h-height)*.5))
	if h.page=="main":pos=Vector2(28 if not h.portrait else (h.view_w-width)*.5,(24 if enlarged else (56 if h.touch_mode or h.view_h<700 else 94)) if not h.portrait else stage_y()+26)
	if enlarged and h.page!="main":pos=Vector2(20,84)
	if split_main():pos=Vector2(28,72)
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

func roster_geometry(width: float,separate: bool=false,allow_paging: bool=true,for_main: bool=false) -> Dictionary:
	var h=host
	var enlarged: bool=h.interface_options.text_scale>1.0
	var columns: int=2 if for_main or split_main() or h.portrait or separate else h.FRIENDS.size()
	var stacked: bool=true
	var tile_h:=132.0 if h.portrait else 152.0
	var probe: Label=h.wrap_label("",20)
	probe.add_theme_font_size_override("font_size",h.ui_size(20))
	probe.theme=h.ui.theme
	probe.mouse_filter=Control.MOUSE_FILTER_IGNORE
	h.ui.add_child(probe)
	# Keep the user's exact font and size. A canonical name that cannot fit
	# a column gets a wider card instead of a character-level orphan line.
	if for_main or h.page=="main":
		var font: Font=probe.get_theme_font("font")
		var longest:=0.
		for id in h.FRIENDS:
			longest=maxf(longest,font.get_string_size(h.character_name(id),HORIZONTAL_ALIGNMENT_LEFT,-1,h.ui_size(20)).x)
		while columns>1 and longest>floorf((width-float(columns-1)*10)/columns)-16:
			columns-=1
	var tile_w: float=(width-float(columns-1)*10)/columns
	# Label shaping includes the actual fallback font, smart wrapping and theme
	# line spacing. Measure at the smallest integer width the grid can allocate.
	probe.size=Vector2(maxf(60,floorf(tile_w)-(16 if stacked else 76)),0)
	for id in h.FRIENDS:
		for prefix in [""]:
			probe.text=prefix+h.character_name(id)
			probe.get_line_count()
			tile_h=maxf(tile_h,ceilf(probe.get_minimum_size().y)+22+(96 if stacked else 0))
	probe.free()
	var paged: bool=allow_paging and not separate and (main_roster_paged() if for_main else paged_roster())
	var rows:=1 if paged else ceili(float(h.FRIENDS.size())/columns)
	return {"columns":columns,"width":tile_w,"height":tile_h,"total_height":tile_h*rows+float(rows-1)*10+(ceilf(h.ui_size(30)*1.6)+28 if paged else 0)}

func roster_y() -> float:
	var height: float=roster_geometry(roster_width()).total_height
	var header: float=72. if host.interface_options.text_scale>1. else 72.+chooser_height()+6.
	return maxf(header,(host.view_h-height)*.5) if split_main() else host.view_h-height-20

func chooser_height() -> float:
	if host.interface_options.text_scale>1:return 0.0
	var probe: Label=host.wrap_label("",18)
	probe.theme=host.ui.theme
	host.ui.add_child(probe)
	probe.size.x=roster_width()
	probe.text=host.text("characters")
	var height: float=maxf(36,ceilf(probe.get_minimum_size().y))
	probe.free()
	return height

func roster(parent: Control, at: Vector2, width: float, separate: bool=false) -> void:
	var h=host
	var old_preview=roster_previews.get(h.character,null)
	if launch_pending and is_instance_valid(old_preview):launch_clock=old_preview.clock
	roster_previews.clear()
	var enlarged: bool=h.interface_options.text_scale>1.0
	var geometry:=roster_geometry(width,separate)
	var columns: int=geometry.columns
	var paged: bool=paged_roster() and not separate
	var capacity: int=columns if paged else h.FRIENDS.size()
	if h.page=="main" and not separate:
		if last_roster_capacity!=capacity:roster_page=floori(float(maxi(0,h.FRIENDS.find(h.character)))/capacity)
		last_roster_capacity=capacity
		roster_page=clampi(roster_page,0,ceili(float(h.FRIENDS.size())/capacity)-1)
	var grid:=GridContainer.new()
	grid.columns=columns
	grid.add_theme_constant_override("h_separation",10)
	grid.add_theme_constant_override("v_separation",10)
	parent.add_child(grid)
	grid.position=at
	var tile_w: float=geometry.width
	var shown: Array=h.FRIENDS.slice(roster_page*capacity,roster_page*capacity+capacity) if paged else h.FRIENDS
	for id in shown:
		var tile: Button=h.button("",func():h.select_character(id),id==h.character)
		tile.name=("Select_" if separate else "StartSelect_")+id
		tile.accessibility_name=h.character_name(id)+(" · "+h.text("setting_on") if id==h.character else "")
		tile.custom_minimum_size=Vector2(tile_w,geometry.height)
		grid.add_child(tile)
		if id==h.character:
			var selected: StyleBoxFlat=tile.get_theme_stylebox("normal").duplicate()
			selected.border_width_bottom=6
			tile.add_theme_stylebox_override("normal",selected)
		var stacked: bool=true
		var row: BoxContainer=VBoxContainer.new() if stacked else HBoxContainer.new()
		row.mouse_filter=Control.MOUSE_FILTER_IGNORE
		tile.add_child(row)
		row.position=Vector2(8,8)
		row.size=Vector2(tile_w-16,tile.custom_minimum_size.y-16)
		row.add_theme_constant_override("separation",6)
		var image:=RunnerHeroPreview.new()
		image.hero=id;image.body_art=h.menu_hero_art;image.weapon_art=h.menu_weapon_art;image.action="armed_walk";image.animate=h.decorative_motion()
		image.set_select_state("select" if id==h.character else "idle")
		image.custom_minimum_size=Vector2(80,96)
		row.add_child(image)
		roster_previews[id]=image
		tile.focus_entered.connect(func():refresh_preview_state(tile,image,id))
		tile.mouse_entered.connect(func():refresh_preview_state(tile,image,id))
		tile.focus_exited.connect(func():refresh_preview_state(tile,image,id))
		tile.mouse_exited.connect(func():refresh_preview_state(tile,image,id))
		var title: Label=h.wrap_label(h.character_name(id),20,"fff1d5")
		title.name="HeroName"
		title.add_theme_font_size_override("font_size",h.ui_size(20))
		title.add_theme_color_override("font_color",h.interface_options.color("on_primary" if id==h.character else "text"))
		title.mouse_filter=Control.MOUSE_FILTER_IGNORE
		title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		if stacked:title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(title)
	if paged:
		var pages:=ceili(float(h.FRIENDS.size())/capacity)
		var navigation:=HBoxContainer.new();navigation.position=at+Vector2(0,float(geometry.height)+10);parent.add_child(navigation)
		var before: Button=h.button("‹",func():roster_page=maxi(0,roster_page-1);h.rebuild());before.name="RosterPrevious";before.disabled=roster_page==0
		var after: Button=h.button("›",func():roster_page=mini(pages-1,roster_page+1);h.rebuild());after.name="RosterNext";after.disabled=roster_page>=pages-1
		for b in [before,after]:b.custom_minimum_size=Vector2((width-12)*.5,62);navigation.add_child(b)

func main(column: VBoxContainer) -> Button:
	var h=host
	if not launch_pending:launch_committed=false
	var enlarged: bool=h.interface_options.text_scale>1.
	var title: Label=h.label("AION",32,"f8d9b1")
	title.name="ArcadeTitle";title.add_theme_font_override("font",h.FONT)
	title.add_theme_font_size_override("font_size",h.ui_size(24 if enlarged else 40))
	column.add_child(title)
	var mission: Label=h.wrap_label(AionCampaignText.word(h.language,"title"),17,"f2d5a6")
	mission.name="MissionTitle"
	if not enlarged:column.add_child(mission)
	else:mission.free()
	var modes:=HBoxContainer.new();modes.add_theme_constant_override("separation",8);column.add_child(modes)
	var arcade: Button=h.button(AionCampaignText.word(h.language,"arcade"),func():request_launch(h.start_campaign),true)
	arcade.name="StartCampaign";arcade.custom_minimum_size.y=maxf(64,h.ui_size(38));arcade.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	arcade.add_theme_font_size_override("font_size",h.ui_size(20));modes.add_child(arcade)
	if h.has_campaign_checkpoint():
		var resume: Button=h.button(AionCampaignText.word(h.language,"continue_short"),func():request_launch(func():h.campaign_resume_requested=true;h.start_campaign(),true))
		resume.name="ContinueCampaign";resume.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		resume.add_theme_font_size_override("font_size",h.ui_size(17));modes.add_child(resume)
	var secondary:=HBoxContainer.new();secondary.add_theme_constant_override("separation",8);column.add_child(secondary)
	var endless: Button=h.button(AionCampaignText.word(h.language,"endless"),func():request_launch(h.start_run))
	endless.name="StartRun";endless.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	endless.disabled=h.character not in h.World.PLAYABLE_HEROES
	if endless.disabled:
		endless.text=RunnerFrontText.endless_limited_label(h.language)
		endless.tooltip_text=RunnerFrontText.endless_availability(h.language)
		endless.accessibility_name=endless.text+" · "+endless.tooltip_text
		endless.accessibility_description=endless.tooltip_text
	endless.custom_minimum_size.y=maxf(60,h.ui_size(34));endless.add_theme_font_size_override("font_size",h.ui_size(17));secondary.add_child(endless)
	var help: Button=h.button(RunnerFrontText.word(h.language,"how"),func():h.open_subpage("help"))
	help.name="HowToPlay";help.size_flags_horizontal=Control.SIZE_EXPAND_FILL;help.add_theme_font_size_override("font_size",h.ui_size(17));secondary.add_child(help)
	var utilities:=HBoxContainer.new();utilities.add_theme_constant_override("separation",8);column.add_child(utilities)
	for entry in ["characters","settings"]:
		var action: Button=h.button(h.text(entry),func():h.open_subpage(entry))
		action.name="ChooseHero" if entry=="characters" else "OpenSettings"
		action.size_flags_horizontal=Control.SIZE_EXPAND_FILL;action.custom_minimum_size.y=maxf(48,h.ui_size(28))
		action.add_theme_font_size_override("font_size",h.ui_size(17));utilities.add_child(action)
	var choose: Label=h.wrap_label(h.text("characters"),18,"ffe1b9")
	choose.name="StartChooser"
	# Width must exist before entering the tree; shaping at width zero caches
	# a many-line minimum which otherwise leaves an oversized invisible label.
	choose.size=Vector2(roster_width(),chooser_height());choose.visible=not enlarged
	var roster_group:=Control.new()
	roster_group.name="StartRoster"
	roster_group.mouse_filter=Control.MOUSE_FILTER_IGNORE
	h.menu_layer.add_child(roster_group)
	var roster_at: float=roster_y()
	var roster_left: float=h.view_w*.5+14 if split_main() else 28.
	roster_group.position=Vector2(roster_left,roster_at)
	roster_group.add_child(choose)
	choose.position=Vector2(0,-chooser_height()-6);choose.size.y=chooser_height()
	roster(roster_group,Vector2.ZERO,roster_width())
	if launch_pending:trigger_launch_preview(h.character)
	fit_main.call_deferred(column,roster_group,h.layout_generation)
	return arcade

func fit_main(column: VBoxContainer,roster_group: Control,generation: int) -> void:
	if not is_instance_valid(host) or not host.is_inside_tree() or generation!=host.layout_generation or not is_instance_valid(column) or not is_instance_valid(roster_group):return
	var panel: PanelContainer=column.get_parent()
	# Size the background to the real wrapped content instead of a large fixed
	# preview slot. The font and chosen text scale remain unchanged.
	var inset: Vector2=panel.get_theme_stylebox("panel").get_minimum_size()
	var content_height: float=host.menu_pages.measure(column,panel.size.x-inset.x)
	panel.size.y=ceilf(content_height+inset.y)
	if split_main():panel.position.y=maxf(72,floorf((host.view_h-panel.size.y)*.5))
	elif host.portrait:
		var gap: float=22. if host.interface_options.text_scale<=1. else 16.
		var heading: float=chooser_height()
		roster_group.position.y=minf(roster_group.position.y,panel.position.y+panel.size.y+gap+heading+(6. if heading>0. else 0.))


func characters() -> void:
	var h=host
	roster_previews.clear()
	var column: VBoxContainer=card(760)
	column.add_child(h.wrap_label(h.text("choose"),26))
	for id in h.FRIENDS:
		var tile: BoxContainer=HBoxContainer.new() if not h.portrait and h.interface_options.text_scale>1.0 else VBoxContainer.new()
		tile.name="HeroCard_"+id
		column.add_child(tile)
		var preview:=RunnerHeroPreview.new()
		preview.hero=id;preview.body_art=h.menu_hero_art;preview.weapon_art=h.menu_weapon_art;preview.animate=h.decorative_motion()
		preview.custom_minimum_size=Vector2(160,124)
		preview.set_select_state("select" if id==h.character else "idle")
		roster_previews[id]=preview
		tile.add_child(preview)
		var info: BoxContainer=VBoxContainer.new()
		info.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		tile.add_child(info)
		var choice: Button=h.button(("✓ " if id==h.character else "")+h.character_name(id),func():h.select_character(id),id==h.character)
		choice.name="Select_"+id
		choice.focus_entered.connect(func():refresh_preview_state(choice,preview,id))
		choice.mouse_entered.connect(func():refresh_preview_state(choice,preview,id))
		choice.focus_exited.connect(func():refresh_preview_state(choice,preview,id))
		choice.mouse_exited.connect(func():refresh_preview_state(choice,preview,id))
		info.add_child(choice)
		info.add_child(h.wrap_label(RunnerFrontText.ability_summary(h.language,id),17))
	var confirm: Button=h.button(RunnerFrontText.word(h.language,"confirm"),func():h.show_page("main"),true)
	confirm.name="ConfirmHero";confirm.set_meta("menu_pin",true);column.add_child(confirm)
	h.menu_pages.prepare(column,Vector2(float(column.get_meta("page_width")),float(column.get_meta("page_height"))))

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
