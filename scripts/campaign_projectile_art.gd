class_name CampaignProjectileArt
extends RefCounted
## Small authored pixel silhouettes. Cache is bounded by actual weapon palettes
## and two exhaust phases; art changes never resize projectile collision rules.
# 0.41.0: Process-wide shared projectile silhouette cache.
static var cache: Dictionary={}
func pose(kind: String,ink: String,phase: int=0) -> Dictionary:
 var key:=kind+ink+str(posmod(phase,2))
 if cache.has(key):return cache[key]
 var rows: Array[String]
 if kind=='rocket':
  rows=['      001                       ','     011100        0000        ','    0131111000000001111000       ','   01331111222222222222221100    ','0001333111223333333333322221100  ','04413331112235555555332222221100 ','045133311122353333353322222221100','045133311122353333353322222221100','04413331112235555555332222221100 ','0001333111223333333333322221100  ','   01331111222222222222221100    ','    0131111000000001111000       ','     011100        0000        ','      001                       ']
 elif kind in ['seeker','harpoon']:
  rows=['      00                ','     01100000000        ','000001222222222100      ','0333312222222222110     ','04444122222222222110    ','04444122222222222110    ','0333312222222222110     ','000001222222222100      ','     01100000000        ','      00                ']
 elif kind in ['spore','seed','nova']:
  rows=['       000     ','      0110     ','     001100    ','   0012222100  ','  012222222210 ',' 01222332222210','012223333222210','012223322222210','012222222222210',' 0122222222210 ','  01222222210  ','   00111100    ','     0000      ']
 elif kind=='disc':
  rows=['     000000     ','   0011111100   ','  012222222210  ',' 01222000022210 ','0122201331022210','0122013333102210','0122013333102210','0122201331022210',' 01222000022210 ','  012222222210  ','   0011111100   ','     000000     ']
 else:
  rows=['           00000        ','       00001222100      ','  000001122233332210    ','001111222233333333210   ','0444442222333333333210  ','0444442222333333333210  ','001111222233333333210   ','  000001122233332210    ','       00001222100      ','           00000        ']
 var width:=0
 for row in rows:width=maxi(width,row.length())
 var image:=Image.create_empty(width,rows.size(),false,Image.FORMAT_RGBA8)
 var colour:=Color(ink)
 var palette={'0':Color('292532'),'1':colour.darkened(.48),'2':colour,'3':colour.lightened(.7),'4':Color('f5c66f') if phase%2==0 else colour.darkened(.25),'5':Color('67c1b3')}
 for y in rows.size():
  for x in rows[y].length():
   var c:=rows[y][x]
   if palette.has(c):image.set_pixel(x,y,palette[c])
 cache[key]={'texture':ImageTexture.create_from_image(image),'offset':Vector2(-width+3,-rows.size()/2.),'size':Vector2(width,rows.size())}
 return cache[key]

static func draw_flight(v,b: Dictionary,p: Vector2) -> void:
 if str(b.owner)!='hero' or not v.host.motion_enabled or v.host.options.reduced_motion:return
 var direction:=Vector2(b.v).normalized()
 if b.kind=='rocket':
  var side:=direction.orthogonal()
  for i in 5:
   var amount:=float(i)/4.
   var drift:=sin(float(b.age)*12.-float(i)*.9)*amount*7.
   var back: Vector2=(p-direction*(30.+float(i)*10.)+side*drift).round()
   var smoke:=Color('695264');smoke.a=.54-.40*amount
   v.draw_rect(Rect2(back-Vector2(3.,2.),Vector2(7.,5.)),smoke)
   v.draw_rect(Rect2(back-Vector2(1.,1.),Vector2(4.,3.)),Color('e39961') if i<2 else smoke)
 elif b.kind in ['pistol','heavy']:
  var tint:=Color('edbf80');tint.a=.50 if b.kind=='pistol' else .35
  v.draw_line(p-direction*30.,p-direction*13.,tint,2.)

static func draw_rocket_blast(v,blast: Dictionary) -> void:
 var point: Vector2=v.at(Vector2(blast.p)).round()
 var progress:=clampf(float(blast.age)/.5,0.,1.)
 var animated: bool=v.host.motion_enabled and not v.host.options.reduced_motion
 var reach:=26.+progress*32. if animated else 32.
 var flame:=Color('f8c775');flame.a=1.-progress
 var core:=Color('fff3b9');core.a=maxf(0.,1.-progress*3.)
 v.draw_rect(Rect2(point-Vector2(reach*.43,5.),Vector2(reach*.86,10.)),flame)
 v.draw_rect(Rect2(point-Vector2(5.,reach*.35),Vector2(10.,reach*.70)),flame)
 v.draw_rect(Rect2(point-Vector2(7.,6.),Vector2(14.,12.)),core)
 if not animated:return
 for i in 8:
  var direction:=Vector2.from_angle(float(i)*TAU/8.+.16)
  var origin: Vector2=(point+direction*reach).round()
  var dusk:=Color('593c57');dusk.a=(1.-progress)*.7
  v.draw_rect(Rect2(origin-Vector2(4.,3.),Vector2(8.,6.)),dusk)
  v.draw_line(origin,origin+direction*(8.+float(i%3)*3.),flame,2.)

static func draw_muzzle(v,point: Vector2,aim: Vector2,kind: String,colour: Color) -> void:
 var long_flash:=kind in ['heavy','rocket','scatter']
 var size:=24. if kind=='rocket' else (16. if long_flash else 9.)
 var spread:=7. if kind=='rocket' else (5. if long_flash else 3.)
 v.draw_set_transform(point.round(),aim.angle(),Vector2.ONE)
 v.draw_polygon(PackedVector2Array([Vector2(0.,-spread),Vector2(size*.40,-spread*.6),Vector2(size,0.),Vector2(size*.40,spread*.6),Vector2(0.,spread)]),PackedColorArray([colour]))
 v.draw_rect(Rect2(0.,-1.,size*.43,3.),Color('fff1c0'))
 if long_flash and v.host.motion_enabled and not v.host.options.reduced_motion:
  v.draw_rect(Rect2(-10.,-7.,4.,2.),Color('bb7c58'))
  v.draw_rect(Rect2(-14.,-9.,3.,2.),Color('705061'))
 v.draw_set_transform(Vector2.ZERO)

static func draw_armour_chip(v,blast: Dictionary) -> void:
 var at: Vector2=v.at(Vector2(blast.p)).round()
 var age:=clampf(float(blast.age)/.19,0.,1.)
 var ink:=Color('fff1a3');ink.a=1.-age
 var radius:=4.+age*15. if v.host.motion_enabled and not v.host.options.reduced_motion else 7.
 for offset in [Vector2(-.8,-.5),Vector2(.25,-1.),Vector2(.8,-.3),Vector2(.65,.68)]:
  v.draw_rect(Rect2((at+offset*radius).round(),Vector2(3.,2.)),ink)

static func draw_beetle_shell(v,enemy: Dictionary) -> void:
 if not CampaignWeapons.shell_beetle(enemy) or bool(enemy.defeated):return
 var p: Vector2=v.at(Vector2(float(enemy.x),float(enemy.y)))
 var front:=float(enemy.facing)
 if CampaignWeapons.shell_open(enemy):
  v.draw_rect(Rect2((p+Vector2(5.*front,-29.)).round()-Vector2(3.,2.),Vector2(7.,4.)),Color('cf7556'))
  v.draw_rect(Rect2((p+Vector2(5.*front,-30.)).round()-Vector2(1.,1.),Vector2(3.,3.)),Color('fbd487'))
  return
 for corner in [Vector2(11.,-45.),Vector2(16.,-42.),Vector2(20.,-39.)]:
  var step: Vector2=(p+Vector2(corner.x*front,corner.y)).round()
  v.draw_rect(Rect2(step-Vector2(2.,1.),Vector2(5.,4.)),Color('44364d'))
  v.draw_rect(Rect2(step-Vector2(1.,1.),Vector2(3.,2.)),Color('edc480'))
