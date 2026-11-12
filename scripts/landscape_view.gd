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
	# Small botanical details move faster than the panorama. Hashed world
	# indices preserve variety and placement across screen edges and resizing.
	var spacing:=173.0
	var travel: float=scroll*.48
	var start: int=floori(travel/spacing)
	var offset: float=fposmod(travel,spacing)
	var kind: int=host.world.biome()
	for n in range(-1,ceili(host.scene_w/spacing)+2):
		var seed_value: int=absi((start+n)*137+kind*79)
		var x: float=n*spacing-offset+seed_value%41
		var y: float=host.ground-5
		var color:=Color("58734a").lerp(Color("29434a"),night*.5)
		if kind==1:color=Color("bfdce4")
		elif kind==5:color=Color("b8796e")
		if seed_value%3==0:
			for leaf in 3:
				host.draw_rect(Rect2(x+leaf*5,y-5-leaf%2*3,3,8+leaf%2*3),color)
			if kind in [0,2,4]:
				host.draw_rect(Rect2(x+6,y-11,4,4),Color("eaa0ad"))
		elif seed_value%3==1:
			host.draw_rect(Rect2(x,y-3,16,5),color.darkened(.2))
			host.draw_rect(Rect2(x+3,y-6,10,4),color.lightened(.14))
		else:
			for leaf in 4:host.draw_rect(Rect2(x+leaf*5,y-leaf%2*3,4,3),color)
