class_name RunnerPixelInterface
extends RefCounted
var host

func stage_y() -> float:
	if host.portrait:
		var preview: float=minf(360.0,host.view_h*0.31)
		if host.page=="main" and host.interface_options.text_scale<=1.0:
			# Preserve the actual translated roster and heading. A tall system
			# font needs more room than the old fixed preview/sky allocation.
			preview=minf(preview,roster_y()-chooser_height()-6-8-300-26)
		return preview
	return host.view_h-(170.0 if host.touch_mode else 210.0)

func hud() -> void:
	var h = host
	h.hud = Control.new()
	h.hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.ui.add_child(h.hud)
	var band := Panel.new()
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.add_theme_stylebox_override("panel",h.box("211c29ed","6e556d"))
	h.hud.add_child(band)
	h.position_control(band,Vector2.ZERO,Vector2(h.view_w,64))
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation",24)
	h.hud.add_child(stats)
	stats.position = Vector2(18,8)
	for key in ["score","best","gems"]:
		var stack := VBoxContainer.new()
		stack.add_theme_constant_override("separation",0)
		stats.add_child(stack)
		stack.add_child(h.label(h.text(key),14,"c6a8a5"))
		var value: Label = h.label("00000",24,"f8db96" if key=="score" else "f5e6ce")
		stack.add_child(value)
		if key=="score":h.score_label=value
		elif key=="best":h.best_label=value
		else:h.crystal_label=value
	h.pause_button=h.button(h.text("pause"),h.pause_run)
	h.pause_button.add_theme_font_size_override("font_size",20)
	h.hud.add_child(h.pause_button)
	h.position_control(h.pause_button,Vector2(h.view_w-132,8),Vector2(116,48))
	h.biome_label=h.label("",18,"eed3b4")
	h.hud.add_child(h.biome_label)
	h.position_control(h.biome_label,Vector2(18,72),Vector2(h.view_w-36,28))
	h.biome_label.clip_text=true
	h.progress=ProgressBar.new()
	h.progress.max_value=h.world.BIOME_DISTANCE
	h.progress.show_percentage=false
	h.progress.visible=false
	h.hud.add_child(h.progress)
	h.level_label=h.label("",19,"f8db96")
	h.hud.add_child(h.level_label)
	h.position_control(h.level_label,Vector2(18,102),Vector2(210,26))
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
	h.position_control(h.xp_label,Vector2(h.view_w-238,102),Vector2(220,26))
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
	h.position_control(h.power_label,Vector2(18,150),Vector2(h.view_w-36,24))
	h.power_label.clip_text=true
	h.goal_label=h.label("",17,"d4b6b2")
	h.hud.add_child(h.goal_label)
	h.position_control(h.goal_label,Vector2(18,177),Vector2(h.view_w-36,24))
	h.footer_label=h.wrap_label(h.text("touch_hint") if h.touch_mode else h.text("hint"),18,"e6c8b0")
	h.ui.add_child(h.footer_label)
	h.position_control(h.footer_label,Vector2(18,h.view_h-84 if h.touch_mode else h.view_h-26),Vector2(h.view_w-420 if not h.portrait else 128,74 if h.touch_mode else 25))
	if h.touch_mode and h.interface_options.touch_layout=="split":
		var left: float=224 if h.character=="wolf" else 124
		h.position_control(h.footer_label,Vector2(left,h.view_h-82),Vector2(h.view_w-left-218,76))
		h.footer_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	h.ability_label=h.wrap_label("",18,"eedbb6")
	h.ui.add_child(h.ability_label)
	h.position_control(h.ability_label,Vector2(18,h.view_h-162 if h.touch_mode else h.view_h-56),Vector2(210 if h.portrait else h.view_w-360,32))
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
		band.size.y=122
		stats.add_theme_constant_override("separation",20)
		stats.get_child(1).hide()
		stats.get_child(2).hide()
		h.position_control(h.pause_button,Vector2(h.view_w-224,12),Vector2(208,96))
		h.pause_button.add_theme_font_size_override("font_size",h.ui_size(24))
		h.position_control(h.level_label,Vector2(18,136),Vector2(h.view_w-36,65))
		h.position_control(h.level_progress,Vector2(18,204),Vector2(h.view_w-36,10))
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
	var enlarged: bool=h.interface_options.text_scale>1.0
	if enlarged:width=h.view_w-40
	var height: float=minf(h.view_h-120,410 if h.page!="main" else 340)
	if h.page=="settings" or enlarged:height=h.view_h-110
	if h.page=="main" and (h.touch_mode or h.portrait or h.view_h<700) and not enlarged:
		var top: float=stage_y()+26 if h.portrait else 56
		height=minf(292,roster_y()-chooser_height()-6-top-8)
	var panel:=PanelContainer.new()
	panel.name="PagePanel"
	h.menu_layer.add_child(panel)
	var pos:=Vector2((h.view_w-width)*.5,maxf(82,(h.view_h-height)*.5))
	if h.page=="main":pos=Vector2(28 if not h.portrait else (h.view_w-width)*.5,(56 if h.touch_mode or h.view_h<700 else 94) if not h.portrait else stage_y()+26)
	if enlarged:pos=Vector2(20,84)
	h.position_control(panel,pos.floor(),Vector2(floorf(width),floorf(height)))
	var column:=VBoxContainer.new()
	column.add_theme_constant_override("separation",8)
	column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	if h.page=="settings" or enlarged:
		var scroll:=ScrollContainer.new()
		scroll.name="SettingsScroll" if h.page=="settings" else "AccessiblePageScroll"
		scroll.follow_focus=true
		scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
		scroll.custom_minimum_size=Vector2(width-28,height-28)
		panel.add_child(scroll)
		scroll.add_child(column)
	else:panel.add_child(column)
	return column

func roster_geometry(width: float,separate: bool=false) -> Dictionary:
	var h=host
	var enlarged: bool=h.interface_options.text_scale>1.0
	var columns: int=1 if enlarged and h.portrait else (2 if h.portrait or separate or enlarged else h.FRIENDS.size())
	var stacked: bool=not h.portrait and not separate and not enlarged
	var tile_w: float=(width-float(columns-1)*10)/columns
	var tile_h:=210.0 if enlarged else (120.0 if h.portrait else (104.0 if not h.touch_mode else 94.0))
	var probe: Label=h.wrap_label("",20)
	probe.theme=h.ui.theme
	probe.mouse_filter=Control.MOUSE_FILTER_IGNORE
	h.ui.add_child(probe)
	# Label shaping includes the actual fallback font, smart wrapping and theme
	# line spacing. Measure at the smallest integer width the grid can allocate.
	probe.size=Vector2(maxf(60,floorf(tile_w)-(16 if stacked else 76)),0)
	for id in h.FRIENDS:
		for prefix in ["","> "]:
			probe.text=prefix+h.character_name(id)
			tile_h=maxf(tile_h,ceilf(probe.get_minimum_size().y)+22+(40 if stacked else 0))
	probe.free()
	var rows:=ceili(float(h.FRIENDS.size())/columns)
	return {"columns":columns,"width":tile_w,"height":tile_h,"total_height":tile_h*rows+float(rows-1)*10}

func roster_y() -> float:
	return host.view_h-float(roster_geometry(host.view_w-56).total_height)-20

func chooser_height() -> float:
	var probe: Label=host.wrap_label("",20)
	probe.theme=host.ui.theme
	host.ui.add_child(probe)
	probe.size.x=host.view_w-56
	probe.text=host.text("choose_before_run")
	var height: float=maxf(36,ceilf(probe.get_minimum_size().y))
	probe.free()
	return height

func roster(parent: Control, at: Vector2, width: float, separate: bool=false) -> void:
	var h=host
	var enlarged: bool=h.interface_options.text_scale>1.0
	var geometry:=roster_geometry(width,separate)
	var columns: int=geometry.columns
	var grid:=GridContainer.new()
	grid.columns=columns
	grid.add_theme_constant_override("h_separation",10)
	grid.add_theme_constant_override("v_separation",10)
	parent.add_child(grid)
	grid.position=at
	var tile_w: float=geometry.width
	for id in h.FRIENDS:
		var tile: Button=h.button("",func():h.select_character(id),id==h.character)
		tile.name=("Select_" if separate else "StartSelect_")+id
		tile.accessibility_name=h.character_name(id)+(" · "+h.text("setting_on") if id==h.character else "")
		tile.custom_minimum_size=Vector2(tile_w,geometry.height)
		grid.add_child(tile)
		var stacked: bool=not h.portrait and not separate and not enlarged
		var row: BoxContainer=VBoxContainer.new() if stacked else HBoxContainer.new()
		row.mouse_filter=Control.MOUSE_FILTER_IGNORE
		tile.add_child(row)
		row.position=Vector2(8,8)
		row.size=Vector2(tile_w-16,tile.custom_minimum_size.y-16)
		row.add_theme_constant_override("separation",6)
		var image: TextureRect=h.character_portrait(id)
		image.custom_minimum_size=Vector2(54,40 if stacked else 78)
		row.add_child(image)
		var title: Label=h.wrap_label(("> " if id==h.character else "")+h.character_name(id),20,"fff1d5")
		title.add_theme_color_override("font_color",h.interface_options.color("on_primary" if id==h.character else "text"))
		title.mouse_filter=Control.MOUSE_FILTER_IGNORE
		title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		if stacked:title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(title)

func main(column: VBoxContainer) -> Button:
	var h=host
	var record: Label=h.label(h.text("best")+"  %05d" % h.best,22,"f2d5a6")
	if h.interface_options.text_scale>1.0:
		record.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		column.add_child(record)
	else:
		h.menu_layer.add_child(record)
		record.position=Vector2(28,18)
	var logo: Label=h.label("AION",48,"f8d9b1")
	logo.add_theme_font_override("font",h.FONT)
	column.add_child(logo)
	var subtitle: Label=h.label("ENDLESS RUN",24,"d999ad")
	column.add_child(subtitle)
	var first: Button=h.button(h.text("play"),h.start_run,true)
	first.name="StartRun"
	column.add_child(first)
	var secondary: BoxContainer=column
	if not h.portrait and h.view_h<700 and h.interface_options.text_scale<=1.0:
		secondary=HBoxContainer.new()
		secondary.add_theme_constant_override("separation",8)
		column.add_child(secondary)
	for entry in ["boss_training","settings"]:
		var action: Button=h.button(h.text(entry),func():h.show_page("bosses") if entry=="boss_training" else h.open_subpage("settings"))
		action.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		if secondary!=column:
			action.custom_minimum_size=Vector2(0,64)
			action.add_theme_font_size_override("font_size",20)
		secondary.add_child(action)
	if (h.touch_mode or h.portrait or h.view_h<700) and h.interface_options.text_scale<=1.0:
		logo.text="AION · ENDLESS RUN"
		logo.add_theme_font_size_override("font_size",26)
		subtitle.hide()
		for item in column.get_children():
			if item is Button:
				item.custom_minimum_size.y=64
				item.add_theme_font_size_override("font_size",24)
	var choose: Label=h.wrap_label("",20,"ffe1b9")
	choose.name="StartChooser"
	if h.interface_options.text_scale>1.0:
		choose.text=h.text("choose_before_run")
		column.add_child(choose)
		var roster_host:=Control.new()
		roster_host.custom_minimum_size.y=roster_geometry(h.view_w-68).total_height
		column.add_child(roster_host)
		roster(roster_host,Vector2.ZERO,h.view_w-68)
		return first
	h.menu_layer.add_child(choose)
	# Shape text only after its real width exists. A Label initialized with
	# text at width zero can retain an enormous stale minimum height.
	choose.size.x=h.view_w-56
	choose.text=h.text("choose_before_run")
	var roster_at: float=roster_y()
	choose.position=Vector2(28,roster_at-chooser_height()-6)
	choose.size.y=chooser_height()
	roster(h.menu_layer,Vector2(28,roster_at),h.view_w-56)
	return first

func characters() -> void:
	var h=host
	var column: VBoxContainer=card(760)
	column.add_child(h.label(h.text("choose"),26))
	var grid_host:=Control.new()
	grid_host.custom_minimum_size.y=roster_geometry(minf(760,h.view_w-40)-28,true).total_height
	column.add_child(grid_host)
	roster(grid_host,Vector2.ZERO,minf(760,h.view_w-40)-28,true)
	var back: Button=h.button(h.text("back"),func():h.show_page(h.return_page))
	column.add_child(back)
	h.focus_later.call_deferred(back)

func tutorial() -> void:
	var h=host
	var panel:=PanelContainer.new()
	h.tutorial_panel=panel
	h.ui.add_child(panel)
	h.position_control(panel,Vector2(18 if h.portrait else h.view_w-520,200 if h.portrait else 80),Vector2(504 if h.portrait else 500,160))
	if h.interface_options.text_scale>1.0:
		h.position_control(panel,Vector2(18,84),Vector2(h.view_w-36,floorf(h.view_h-124)))
	var column:=VBoxContainer.new()
	if h.interface_options.text_scale>1.0:
		var scroll:=ScrollContainer.new()
		scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
		scroll.follow_focus=true
		scroll.custom_minimum_size=Vector2(h.view_w-64,floorf(h.view_h-148))
		panel.add_child(scroll);scroll.add_child(column)
		column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	else:panel.add_child(column)
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
