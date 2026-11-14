class_name RunnerHeroPreview
extends Control
var hero := "aion"
var clock := 0.
var animate := true
var action := "ability"
var frames := RunnerFrameBank.new()
var catalogue := CampaignCatalog.new()
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
func _process(dt: float) -> void:
	if not is_visible_in_tree():return
	if animate:clock+=minf(dt,.05)
	queue_redraw()
func _draw() -> void:
	var row:=0
	var phase:=fmod(clock,3.)
	if animate and phase>1.:
		row=2 if hero=="aion" else (6 if hero in ["wolf","owl","rabbit","eren"] else 1)
	var key: String="runner-"+hero
	if action=="move":row=1
	elif action=="jump":row=2
	elif action=="shoot":key="gun-fire";row=frames.hero_row(hero)
	var frame: int=frames.cycle(key,row,clock,.85) if animate else 0
	var pose: Dictionary=catalogue.pose("rescue-heroes",frames.hero_row(hero),posmod(int(clock*6.),6) if animate else 3) if action=="rescue" else frames.pose(key,row,frame)
	var factor: float=float(pose.get("scale",1.))
	var dimensions: Vector2=pose.get("size",pose.texture.get_size()*factor)
	var fit: float=minf(1.25,minf(size.x/150.,size.y/110.))
	var anchor:=Vector2(size.x*.5,size.y-6.).round()
	draw_set_transform(anchor,0,Vector2.ONE*fit)
	draw_texture_rect(pose.texture,Rect2((Vector2(pose.offset)*factor).round(),dimensions),false)
	draw_set_transform(Vector2.ZERO)
