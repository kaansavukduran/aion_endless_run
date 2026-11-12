extends Control
# ResourceLoader reports real project loading; setup after 100% is indeterminate.
const FRUIT=preload("res://assets/fragaria-strawberry.png")
const PIXEL=preload("res://assets/PixelifySans.ttf")
const SCENE="res://main.tscn"
var progress := -1.0
var failed := false
var loading := false
var starting := false
var retry: Button
var lang := "en"
var phrases := {"en":["Loading…","Preparing…","Could not load the game.","Try again"],"tr":["Yükleniyor…","Hazırlanıyor…","Oyun yüklenemedi.","Yeniden dene"],"cs":["Načítání…","Příprava…","Hru se nepodařilo načíst.","Zkusit znovu"]}

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var locale:=OS.get_locale().replace("_","-").split("-")[0].to_lower()
	if locale in phrases:lang=locale
	if OS.has_feature("web"):
		# The web shell already showed verified pack loading. Avoid a second splash.
		get_tree().change_scene_to_file.call_deferred(SCENE)
		return
	retry=Button.new();retry.text=phrases[lang][3];retry.accessibility_name=retry.text
	retry.custom_minimum_size=Vector2(240,56);retry.pressed.connect(begin)
	add_child(retry);retry.hide()
	get_viewport().size_changed.connect(queue_redraw)
	begin.call_deferred()

func begin() -> void:
	failed=false;progress=-1;starting=false;retry.hide()
	var result:=ResourceLoader.load_threaded_request(SCENE)
	loading=result==OK
	if not loading:failed=true;retry.show();retry.grab_focus()
	queue_redraw()

func _process(_dt: float) -> void:
	if OS.has_feature("web"):return
	if loading:
		var detail:=[]
		var status:=ResourceLoader.load_threaded_get_status(SCENE,detail)
		if not detail.is_empty():progress=clampf(float(detail[0]),0,1)
		if status==ResourceLoader.THREAD_LOAD_LOADED:
			loading=false;starting=true;progress=-1;queue_redraw()
			finish.call_deferred()
		elif status in [ResourceLoader.THREAD_LOAD_FAILED,ResourceLoader.THREAD_LOAD_INVALID_RESOURCE]:
			loading=false;failed=true;retry.show();retry.grab_focus()
	queue_redraw()

func finish() -> void:
	# Give the final phase one actual render; never impose an artificial timer.
	await get_tree().process_frame
	var packed=ResourceLoader.load_threaded_get(SCENE)
	if packed is PackedScene and get_tree().change_scene_to_packed(packed)==OK:return
	starting=false;failed=true;retry.show();retry.grab_focus()

func centered(value: String,at: Vector2,font_size: int,color: Color=Color.WHITE) -> void:
	var width:=PIXEL.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	draw_string(PIXEL,Vector2(at.x-width*.5,at.y).round(),value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func _draw() -> void:
	var raw:=size
	var safe:=Rect2(Vector2.ZERO,raw)
	if OS.has_feature("mobile"):safe=preload("res://scripts/interface_options.gd").native_safe_layout(raw)
	var logical:=Vector2(540,960) if raw.y>raw.x else Vector2(960,540)
	var scale_value:=minf(safe.size.x/logical.x,safe.size.y/logical.y)
	var origin: Vector2=safe.position+(safe.size-logical*scale_value)*.5
	draw_set_transform(origin,0,Vector2.ONE*scale_value)
	draw_rect(Rect2(Vector2.ZERO,logical),Color.BLACK)
	var x:=logical.x*.5
	var portrait:=logical.y>logical.x
	var y:=logical.y*.31 if portrait else logical.y*.25
	var fruit_size:=FRUIT.get_size()*minf(116.0/FRUIT.get_width(),130.0/FRUIT.get_height())
	draw_texture_rect(FRUIT,Rect2(Vector2(x,y)-fruit_size*.5,fruit_size),false)
	centered("Fragaria Interactive",Vector2(x,y+112),34)
	var bar_y:=logical.y*.63 if portrait else logical.y*.64
	centered(phrases[lang][2 if failed else (1 if starting else 0)],Vector2(x,bar_y-44),24)
	centered((str(floori(progress*100))+"%") if progress>=0 else "…",Vector2(x,bar_y-12),24,Color("97ff52"))
	var width:=360.0
	draw_rect(Rect2(x-width*.5-6,bar_y,width+12,38),Color("403a4e"))
	for i in 10:
		var filled: bool=progress>=0 and i<floori(progress*10)
		var color:=Color("d7d7da")
		if filled:color=Color("ed394e") if i<3 else (Color("f88c9a") if i<7 else Color("97ff52"))
		if progress<0 and i in [4,5]:color=Color("97ff52")
		draw_rect(Rect2(x-width*.5+i*36+2,bar_y+5,32,28),color)
	draw_string(PIXEL,Vector2(20,logical.y-22),"v"+str(ProjectSettings.get_setting("application/config/version")),HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color.WHITE)
	if is_instance_valid(retry):
		retry.position=origin+Vector2(x-120,bar_y+64)*scale_value
		retry.scale=Vector2.ONE*scale_value
