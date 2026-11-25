class_name CampaignRocketArt
extends RefCounted

## Original copper and enamel relay launcher. Both held and pickup poses use
## this sheet so the measured contact points always belong to the drawn prop.
const HELD_GRIP := Vector2(17,19)
const HELD_MUZZLE := Vector2(39,8)
const HELD_WIDTH := 45.
const HELD_CANVAS := Vector2(40,22)
const LAUNCHER := [
	"           000           0000          ",
	"          04340         045340         ",
	"     0000008880000000000088888000000   ",
	"   0022222277777777777777777777772200  ",
	"  02333455554444444444444444455543300  ",
	" 02345678888888888888888888887654432100",
	"0234567899999944444555544999887654432100",
	"0234567898669946341341344966887654432100",
	"0234567898669946431431434966887654432100",
	"012345678888884444444444488887654432100",
	" 0123455777777777777777777777654432100 ",
	"  00122222221111111111111112223321100  ",
	"    00343000044111114400004443000     ",
	"      04340   04455540   04340        ",
	"      04230    045540   04320         ",
	"       04320   04540   04120          ",
	"        04120  04420   0000           ",
	"         000  04320                   ",
	"              04320                   ",
	"              04120                   ",
	"             001120                   ",
	"              0000                    ",
]
const AMMO := [
	"    00000000000000    ",
	"   0333313333133330   ",
	"  0344431344431344430 ",
	" 0345543134554313455430",
	" 0348853134885313488530",
	" 0348853134885313488530",
	" 0348853134885313488530",
	" 0000000000000000000000",
	" 0777777777777777777770",
	" 0688888828888888888860",
	" 0688899222998888888860",
	" 0688899292998888888860",
	" 0688899292998888888860",
	" 0677777777777777777760",
	" 0566888888888888866550",
	" 0000000000000000000000",
]
const INK := {
	"0":Color("281f34"),"1":Color("49334b"),"2":Color("78474c"),
	"3":Color("a9624f"),"4":Color("d38955"),"5":Color("f2c17c"),
	"6":Color("345568"),"7":Color("33797c"),"8":Color("54a8a0"),"9":Color("bce2cb"),
}
static var _textures: Dictionary = {}

static func texture(kind: String) -> Texture2D:
	if _textures.has(kind):return _textures[kind]
	var pixels: Array=LAUNCHER if kind=="rocket" else AMMO
	var width:=0
	for row: String in pixels:width=maxi(width,row.length())
	var image:=Image.create_empty(width,pixels.size(),false,Image.FORMAT_RGBA8)
	for y in pixels.size():
		var row: String=pixels[y]
		for x in row.length():
			var pixel:=row[x]
			if INK.has(pixel):image.set_pixel(x,y,INK[pixel])
	var result:=ImageTexture.create_from_image(image)
	_textures[kind]=result
	return result

static func pickup(kind: String) -> Dictionary:
	var image:=texture(kind)
	var size: Vector2=image.get_size()*(52. if kind=="rocket" else 36.)/image.get_width()
	return {"texture":image,"offset":-size*.5,"size":size,"source_key":"relay-workshop-pixels","kind":kind}

static func weapon_metrics() -> Dictionary:
	var factor:=HELD_WIDTH/HELD_CANVAS.x
	return {"kind":"rocket","display_source":"rocket","size":HELD_CANVAS*factor,
		"offset":-HELD_GRIP*factor,"muzzle":(HELD_MUZZLE-HELD_GRIP)*factor,
		"factor":factor,"grip_pixel":HELD_GRIP,"muzzle_pixel":HELD_MUZZLE}
