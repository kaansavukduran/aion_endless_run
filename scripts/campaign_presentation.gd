class_name CampaignPresentation
extends Control

## Reuses the actual approved actor poses; this is presentation, not new artwork.
var host
var tutorial_topic := ""
var frames := RunnerFrameBank.new()
var clock := 0.0
var topic_index := 0

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	frames=host.view.frames
	if tutorial_topic!="":return
	var stack:=VBoxContainer.new();stack.position=Vector2(16,size.y*.22);stack.size.x=size.x-32.;stack.add_theme_constant_override("separation",12);add_child(stack)
	for row in [[host.t("won") if host.presentation_stage=="victory" else host.t("mission")+" · "+host.t("title"),26,"ffcf8c"],[host.t("lights_restored") if host.presentation_stage=="victory" else host.t("intro_objective"),17,"f5ebd9"]]:
		var line:=Label.new();line.text=row[0];line.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;line.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;line.add_theme_font_override("font",host.view.font);line.add_theme_font_size_override("font_size",host.font_size(int(row[1])));line.add_theme_color_override("font_color",Color(row[2]));stack.add_child(line)

func _process(dt: float) -> void:
	if not is_visible_in_tree():return
	clock+=minf(dt,.05)
	queue_redraw()

func _draw() -> void:
	if host==null:return
	var motion: bool=host.motion_enabled and not host.options.reduced_motion
	var actor_key: String="runner-"+host.world.character
	var actor_row:=1
	var progress:=clock if motion else 0.
	if tutorial_topic!="":
		# Each topic demonstrates the same action family as the real player.
		var center:=Vector2(size.x*.5,size.y-12.)
		draw_line(Vector2(20,size.y-10),Vector2(size.x-20,size.y-10),Color("a67e56"),3.)
		if topic_index==0:actor_row=1
		elif topic_index==1:actor_row=2;center.y-=absf(sin(progress*2.))*34.
		elif topic_index in [2,3]:actor_key="gun-fire";actor_row=frames.hero_row(host.world.character)
		elif topic_index==4:actor_row=6
		var pose: Dictionary=frames.pose(actor_key,actor_row,frames.cycle(actor_key,actor_row,progress,1.))
		var dimensions: Vector2=pose.get("size",pose.texture.get_size()*float(pose.get("scale",1.)))
		var ratio:=minf(1.,(size.y-20.)/maxf(1.,dimensions.y))
		var p:=Vector2(pose.offset)*float(pose.get("scale",1.))*ratio+center
		draw_texture_rect(pose.texture,Rect2(p,dimensions*ratio),false)
		if topic_index in [2,3]:
			var x:=center.x+45.+fmod(progress*110.,maxf(50.,size.x*.3))
			draw_rect(Rect2(Vector2(x,center.y-38),Vector2(8,3)),Color("ffcf8c"))
		if topic_index==3:
			var angle:=progress*3.
			draw_circle(center+Vector2(65.,-30.-absf(sin(angle))*32.),7.,Color(AionCampaignWorld.COLORS[host.world.character]))
		return
	var stage: String=host.presentation_stage
	if stage=="":return
	draw_rect(Rect2(Vector2.ZERO,size),Color("171320b8"))
	var color:=Color("ffcf8c")
	var victory: bool=stage=="victory"
	var row:=frames.hero_row(host.world.character)
	var pose: Dictionary=frames.pose("heroes" if victory else "gun-run",row,frames.cycle("heroes" if victory else "gun-run",row,progress,1.))
	var center:=Vector2(size.x*.5,size.y*.76)
	var dimensions: Vector2=pose.get("size",pose.texture.get_size()*float(pose.get("scale",1.)))
	draw_texture_rect(pose.texture,Rect2(center+Vector2(pose.offset)*float(pose.get("scale",1.)),dimensions),false)
	if victory:
		for i in 8:
			var angle:=TAU*float(i)/8.
			var p:=center+Vector2.from_angle(angle)*(65.+(sin(progress*3.+i)*5. if motion else 0.))
			draw_rect(Rect2(p.round(),Vector2(4,4)),color)
