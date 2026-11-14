class_name RunnerLandscapeView
extends RefCounted
const SOURCE=preload("res://assets/aionverse-landscapes.png")
const META=preload("res://assets/LANDSCAPE-PROVENANCE.json")
var panels: Array[Texture2D]=[]

func prepare() -> void:
	if not panels.is_empty():return
	var image:=SOURCE.get_image()
	if image.is_compressed():image.decompress()
	for region in META.data.panels:
		panels.append(ImageTexture.create_from_image(image.get_region(Rect2i(region[0],region[1],region[2],region[3]))))

func panorama(host,kind: int,scroll: float,night: float,alpha: float=1.0) -> void:
	prepare()
	var texture: Texture2D=panels[kind]
	# Uniform scaling preserves the drawings in both orientations. Mirror the
	# alternating repeat at its shared edge, avoiding a discontinuous atlas seam.
	var height: float=host.ground
	var width: float=height*texture.get_width()/texture.get_height()
	var travel: float=scroll*.13
	var index: int=floori(travel/width)
	var offset: float=fposmod(travel,width)
	var tint:=Color.WHITE.lerp(Color("7580ae"),night*.62)
	tint.a=alpha
	for n in range(-1,ceili(host.scene_w/width)+2):
		var x: float=n*width-offset
		var mirrored: bool=posmod(index+n,2)==1
		host.draw_set_transform(Vector2(x+width if mirrored else x,0),0,Vector2(-1 if mirrored else 1,1))
		host.draw_texture_rect(texture,Rect2(0,0,width+1,height),false,tint)
	host.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)

func foreground(host,scroll: float,night: float) -> void:
	var spacing:=350.0
	var travel: float=scroll*.38
	var start: int=floori(travel/spacing)
	var offset: float=fposmod(travel,spacing)
	var kind: int=host.world.biome()
	var clock: float=host.animation_clock() if host.decorative_motion() else 0.0
	var poses:=[0,1,0,2]
	for n in range(-1,ceili(host.scene_w/spacing)+2):
		var seed_value: int=absi((start+n)*137+kind*79)
		var x: float=n*spacing-offset+seed_value%71
		var frame: int=poses[posmod(int(clock/0.65)+seed_value,4)] if host.decorative_motion() else 0
		var pose: Dictionary=host.frames.pose("flora",kind,frame)
		var tint:=Color.WHITE.lerp(Color("7b80a1"),night*.4)
		tint.a=.88
		host.draw_texture_rect(pose.texture,Rect2((Vector2(x,host.ground)+pose.offset*float(pose.scale)).round(),pose.texture.get_size()*float(pose.scale)),false,tint)
