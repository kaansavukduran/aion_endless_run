class_name RunnerPixelInterface
extends RefCounted
var host

func stage_y() -> float:
	return minf(360.0,host.view_h*0.31) if host.portrait else host.view_h-(170.0 if host.touch_mode else 210.0)

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
	h.ability_label=h.wrap_label("",18,"eedbb6")
	h.ui.add_child(h.ability_label)
	h.position_control(h.ability_label,Vector2(18,h.view_h-162 if h.touch_mode else h.view_h-56),Vector2(210 if h.portrait else h.view_w-360,32))
	h.boss_label=h.label("",21,"f4c68b")
	h.ui.add_child(h.boss_label)
	h.position_control(h.boss_label,Vector2(h.view_w*.5-minf(230,h.view_w*.42),205),Vector2(minf(460,h.view_w*.84),32))
	h.boss_bar=ProgressBar.new()
	h.boss_bar.show_percentage=false
	h.boss_bar.add_theme_stylebox_override("background",h.box("302437","796176"))
	h.boss_bar.add_theme_stylebox_override("fill",h.box("c75772","e7a497"))
	h.ui.add_child(h.boss_bar)
	h.position_control(h.boss_bar,Vector2(h.view_w*.08,242),Vector2(h.view_w*.84,12))
	h.notice_label=h.label("",23,"ffe0a3")
	h.notice_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	h.ui.add_child(h.notice_label)
	h.position_control(h.notice_label,Vector2(12,268),Vector2(h.view_w-24,34))
	h.notice_label.clip_text=true

func card(width: float) -> VBoxContainer:
	var h=host
	width=minf(width,h.view_w-40)
	var height: float=minf(h.view_h-120,410 if h.page!="main" else 340)
	if h.page=="settings":height=h.view_h-110
	if h.page=="main" and h.touch_mode and not h.portrait:height=292
	var panel:=PanelContainer.new()
	panel.name="PagePanel"
	h.menu_layer.add_child(panel)
	var pos:=Vector2((h.view_w-width)*.5,maxf(82,(h.view_h-height)*.5))
	if h.page=="main":pos=Vector2(28 if not h.portrait else (h.view_w-width)*.5,(56 if h.touch_mode else 94) if not h.portrait else stage_y()+26)
	h.position_control(panel,pos,Vector2(width,height))
	var column:=VBoxContainer.new()
	column.add_theme_constant_override("separation",8)
	column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	if h.page=="settings":
		var scroll:=ScrollContainer.new()
		scroll.name="SettingsScroll"
		scroll.follow_focus=true
		scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
		scroll.custom_minimum_size=Vector2(width-28,height-28)
		panel.add_child(scroll)
		scroll.add_child(column)
	else:panel.add_child(column)
	return column

func roster(parent: Control, at: Vector2, width: float, separate: bool=false) -> void:
	var h=host
	var columns:=2 if h.portrait or separate else 4
	var grid:=GridContainer.new()
	grid.columns=columns
	grid.add_theme_constant_override("h_separation",10)
	grid.add_theme_constant_override("v_separation",10)
	parent.add_child(grid)
	grid.position=at
	var tile_w: float=(width-float(columns-1)*10)/columns
	for id in h.FRIENDS:
		var tile: Button=h.button("",func():h.select_character(id),id==h.character)
		tile.name=("Select_" if separate else "StartSelect_")+id
		tile.custom_minimum_size=Vector2(tile_w,104 if h.portrait or not h.touch_mode else 92)
		grid.add_child(tile)
		var row:=HBoxContainer.new()
		row.mouse_filter=Control.MOUSE_FILTER_IGNORE
		tile.add_child(row)
		row.position=Vector2(8,8)
		row.size=Vector2(tile_w-16,88)
		row.add_theme_constant_override("separation",6)
		var image: TextureRect=h.character_portrait(id)
		image.custom_minimum_size=Vector2(54,78)
		row.add_child(image)
		var title: Label=h.wrap_label(("> " if id==h.character else "")+h.character_name(id),20,"fff1d5")
		title.mouse_filter=Control.MOUSE_FILTER_IGNORE
		title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
		row.add_child(title)

func main(column: VBoxContainer) -> Button:
	var h=host
	var record: Label=h.label(h.text("best")+"  %05d" % h.best,22,"f2d5a6")
	h.menu_layer.add_child(record)
	record.position=Vector2(28,18)
	column.add_child(h.label("AION",48,"f8d9b1"))
	column.add_child(h.label("ENDLESS RUN",24,"d999ad"))
	var first: Button=h.button(h.text("play"),h.start_run,true)
	column.add_child(first)
	column.add_child(h.button(h.text("boss_training"),func():h.show_page("bosses")))
	column.add_child(h.button(h.text("settings"),func():h.open_subpage("settings")))
	var choose: Label=h.label(h.text("choose_before_run"),20,"ffe1b9")
	h.menu_layer.add_child(choose)
	var roster_y: float=h.view_h-246 if h.portrait else h.view_h-(120 if h.touch_mode else 154)
	choose.position=Vector2(28,roster_y-32)
	roster(h.menu_layer,Vector2(28,roster_y),h.view_w-56)
	return first

func characters() -> void:
	var h=host
	var column: VBoxContainer=card(760)
	column.add_child(h.label(h.text("choose"),26))
	var grid_host:=Control.new()
	grid_host.custom_minimum_size.y=220
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
	h.position_control(panel,Vector2(18 if h.portrait else h.view_w-350,200),Vector2(504 if h.portrait else 330,160))
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
