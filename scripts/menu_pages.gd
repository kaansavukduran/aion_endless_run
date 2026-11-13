class_name RunnerMenuPages
extends RefCounted
var host
var positions := {}
var pages: Array = []
var current := 0
var content: VBoxContainer
var footer: HBoxContainer
var previous: Button
var following: Button
var counter: Label
var available := Vector2.ZERO
var generation := 0
var focus_name := ""

func prepare(column: VBoxContainer, dimensions: Vector2) -> void:
	content=column
	available=dimensions
	generation=host.layout_generation
	# Hide immediately: a long VBox must never expand its containing panel.
	for child in content.get_children():child.hide()
	finish.call_deferred(generation)

func measure(node: Control,width: float) -> float:
	node.size=Vector2(width,0)
	if node is HBoxContainer:
		var total:=0.0
		for child in node.get_children():
			if child is Control:total+=child.get_combined_minimum_size().x
		total+=maxi(0,node.get_child_count()-1)*node.get_theme_constant("separation")
		if total>width:
			var stack:=VBoxContainer.new()
			var parent: Node=node.get_parent()
			var index:=node.get_index()
			parent.add_child(stack);parent.move_child(stack,index)
			for child in node.get_children():node.remove_child(child);stack.add_child(child)
			node.free()
			node=stack
	if node is BoxContainer:
		var children:=node.get_children()
		var height:=0.0
		var fixed:=0.0;var expanding:=0
		if node is HBoxContainer:
			for child in children:
				if not child is Control:continue
				if child.size_flags_horizontal&Control.SIZE_EXPAND:expanding+=1
				else:fixed+=child.get_combined_minimum_size().x
		var flexible: float=maxf(40,(width-fixed-maxi(0,children.size()-1)*node.get_theme_constant("separation"))/maxi(1,expanding))
		for child in children:
			if not child is Control:continue
			var child_width: float=width if node is VBoxContainer else (flexible if child.size_flags_horizontal&Control.SIZE_EXPAND else child.get_combined_minimum_size().x)
			var h:=measure(child,child_width)
			height=height+h if node is VBoxContainer else maxf(height,h)
		if node is VBoxContainer:height+=maxi(0,children.size()-1)*node.get_theme_constant("separation")
		return maxf(height,node.custom_minimum_size.y)
	if node is Label:
		# Force the Label's own shaping after resizing. A hidden Label can
		# otherwise retain a one-pixel-wide paragraph from initial construction.
		node.get_line_count()
		return node.get_minimum_size().y
	if node is Button:
		var font: Font=node.get_theme_font("font")
		var font_size: int=node.get_theme_font_size("font_size")
		var padding:=Vector2.ZERO
		if node is Button:padding=node.get_theme_stylebox("normal").get_minimum_size()
		var text_width: float=width-padding.x-(40 if node is CheckButton else 0)
		var flags: int=TextServer.BREAK_MANDATORY|TextServer.BREAK_WORD_BOUND|TextServer.BREAK_ADAPTIVE
		var measured: Vector2=font.get_multiline_string_size(node.text,HORIZONTAL_ALIGNMENT_LEFT,maxf(24,text_width),font_size,-1,flags)
		return maxf(node.get_combined_minimum_size().y,measured.y+padding.y+4)
	return node.get_combined_minimum_size().y

func split_text(item: Label,limit: float) -> Array:
	var result: Array=[]
	var original: String=item.text
	var rest:=original
	while not rest.is_empty():
		var lo:=1;var hi:=rest.length();var best:=1
		while lo<=hi:
			var mid: int=(lo+hi)/2
			item.text=rest.left(mid)
			if measure(item,available.x)<=limit:best=mid;lo=mid+1
			else:hi=mid-1
		if best<rest.length():
			var boundary:=rest.rfind(" ",best)
			if boundary>best/2:best=boundary
		var fragment: Label=item.duplicate()
		fragment.text=rest.left(best).strip_edges()
		fragment.accessibility_name=fragment.text
		content.add_child(fragment);fragment.hide()
		result.append(fragment)
		rest=rest.substr(best).strip_edges()
	content.remove_child(item);item.queue_free()
	return result

func finish(expected: int) -> void:
	if not is_instance_valid(host) or not host.is_inside_tree() or expected!=host.layout_generation or not is_instance_valid(content):return
	footer=HBoxContainer.new();footer.name="PageNavigation"
	var pinned_height:=0.0
	for child in content.get_children().duplicate():
		if child.get_meta("menu_pin",false):
			content.remove_child(child);content.get_parent().add_child(child);child.show()
			pinned_height+=measure(child,available.x)+8
	footer.add_theme_constant_override("separation",8)
	content.get_parent().add_child(footer)
	previous=host.button("‹",func():select(current-1),false);previous.name="PreviousPage"
	following=host.button("›",func():select(current+1),false);following.name="NextPage"
	for b in [previous,following]:
		b.custom_minimum_size=Vector2(58,maxf(56,host.ui_size(28)+12))
		b.add_theme_font_size_override("font_size",host.ui_size(22))
	previous.accessibility_name=host.text("page_previous")
	following.accessibility_name=host.text("page_next")
	footer.add_child(previous)
	counter=host.label("1 / 1",18);counter.add_theme_font_size_override("font_size",host.ui_size(18));counter.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;counter.size_flags_horizontal=Control.SIZE_EXPAND_FILL;footer.add_child(counter)
	footer.add_child(following)
	var back: Button=host.button(host.text("back"),func():host.gamepad.back());back.name="PageBack";back.add_theme_font_size_override("font_size",host.ui_size(20));back.custom_minimum_size=Vector2(100,previous.custom_minimum_size.y);footer.add_child(back)
	back.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var limit: float=maxf(90,available.y-measure(footer,available.x)-14-pinned_height)
	pages=[]
	var items: Array=[]
	# Reflow wide rows before obtaining the final content list.
	for child in content.get_children().duplicate():
		if child is Control:measure(child,available.x)
	for child in content.get_children().duplicate():
		if not child is Control:continue
		var height:=measure(child,available.x)
		if child is Label and height>limit:items.append_array(split_text(child,limit))
		else:items.append(child)
	var group: Array=[];var used:=0.0
	for item in items:
		content.move_child(item,content.get_child_count()-1)
		var height:=measure(item,available.x)
		if used+height>limit and not group.is_empty():pages.append(group);group=[];used=0
		group.append(item);used+=height+8
	if not group.is_empty():pages.append(group)
	if pages.is_empty():pages.append([])
	var selected:=clampi(int(positions.get(host.page,0)),0,pages.size()-1)
	if focus_name!="":
		for i in pages.size():
			for item in pages[i]:
				if str(item.name)==focus_name or item.find_child(focus_name,true,false)!=null:selected=i
	select(selected,false)
	if is_instance_valid(host) and expected==host.layout_generation:host.refresh_interface_metadata.call_deferred(expected)

func select(index: int,focus: bool=true) -> void:
	if pages.is_empty() or not is_instance_valid(content):return
	current=clampi(index,0,pages.size()-1)
	positions[host.page]=current
	for child in content.get_children():child.hide()
	for item in pages[current]:item.show()
	previous.disabled=current==0
	following.disabled=current==pages.size()-1
	counter.text="%d / %d" % [current+1,pages.size()]
	footer.visible=pages.size()>1 or host.page=="settings"
	if focus:
		host.ui_layout_ready=false
		host.web_stamp=""
		for item in pages[current]:
			if item is BaseButton and not item.disabled:host.focus_later.call_deferred(item);break
		host.refresh_interface_metadata.call_deferred(host.layout_generation)

func reset(value: String) -> void:
	positions[value]=0
