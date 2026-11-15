class_name CampaignProjectileArt
extends RefCounted
## Small authored pixel silhouettes. Cache is bounded by actual weapon palettes
## and two exhaust phases; art changes never resize projectile collision rules.
var cache: Dictionary={}
func pose(kind: String,ink: String,phase: int=0) -> Dictionary:
 var key:=kind+ink+str(posmod(phase,2))
 if cache.has(key):return cache[key]
 var rows: Array[String]
 if kind in ['seeker','harpoon']:
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
 var palette={'0':Color('292532'),'1':colour.darkened(.48),'2':colour,'3':colour.lightened(.7),'4':Color('f5c66f') if phase%2==0 else colour.darkened(.25)}
 for y in rows.size():
  for x in rows[y].length():
   var c:=rows[y][x]
   if palette.has(c):image.set_pixel(x,y,palette[c])
 cache[key]={'texture':ImageTexture.create_from_image(image),'offset':Vector2(-width+3,-rows.size()/2.),'size':Vector2(width,rows.size())}
 return cache[key]
