class_name CampaignTimberArt
extends RefCounted

## Original locally authored pixel art. Source pixels equal world pixels;
## no stretching of timber grain, braces, nails or the crate silhouette.
const ATLAS=preload("res://assets/campaign-timber.png")
const CRATE=Rect2(0,0,44,42)
const COLLAR=Rect2(144,0,8,24)
const POST=Rect2(152,0,12,32)
const FOOT=Rect2(164,0,20,8)
const BRACE=Rect2(48,32,32,32)
const BRACE_RIGHT=Rect2(80,32,32,32)

static func piece(v,source: Rect2,position: Vector2) -> void:
	v.draw_texture_rect_region(ATLAS,Rect2(position.round(),source.size),source)

static func crate(v,position: Vector2) -> void:
	piece(v,CRATE,v.at(position)-Vector2(22,42))

static func walkway(v,surface: Rect2) -> void:
	var p: Vector2=v.at(surface.position)
	var width: int=roundi(surface.size.x)
	# Posts are scenery, not new blockers. A pit has no ground to stand on.
	# Long route bridges receive spaced supports; narrow stepping stones over
	# gaps keep their beam without a floating foot in the empty pit.
	var supports: Array[float]=[14.,surface.size.x-26.]
	for x in range(158,width-50,144):supports.append(float(x))
	for dx in supports:
		var floor_y: float=v.world.floor_at(surface.position.x+dx+6.)
		if not CampaignGround.has_floor(floor_y):continue
		var height: int=roundi(floor_y-surface.position.y)
		if height<=24:continue
		var base: Vector2=p+Vector2(dx,height)
		for y in range(16,height-6,32):
			var length: int=mini(32,height-6-y)
			piece(v,Rect2(POST.position,Vector2(12,length)),p+Vector2(dx,y))
		piece(v,FOOT,base-Vector2(4,8))
		if height>=48:
			if dx+32.<width:piece(v,BRACE,p+Vector2(dx+3,19))
			elif dx>=23.:piece(v,BRACE_RIGHT,p+Vector2(dx-23,19))
	# Cap row begins at precisely the physical one-way landing Y. End pieces
	# are cropped, never rescaled, so short/long ledges share pixel density.
	for x in range(0,width,32):
		var length: int=mini(32,width-x)
		var variant: int=posmod(int(surface.position.x/32.)+int(x/32.),3)
		piece(v,Rect2(48+variant*32,0,length,24),p+Vector2(x,0))
	piece(v,COLLAR,p)
	piece(v,COLLAR,p+Vector2(width-8,0))
