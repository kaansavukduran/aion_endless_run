"""Original hand-authored pixel prop atlas for Mission 1.

Integer source pixels only; no external assets, blur, resampling or random noise.
Frames use cell-local support (32,46); the asymmetric pennant uses its fixed
pole-base support (24,46). All are rendered at integer scale 2.
"""
from pathlib import Path
from PIL import Image, ImageDraw
import hashlib,json
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets';WORK=ROOT/'build/m1-forge-props-review';WORK.mkdir(exist_ok=True,parents=True)
CELL=(64,48);ORIGIN=(32,46)
P={
 'ink':'#29262d','deep':'#3b3030','stone_d':'#514f46','stone':'#777663','stone_l':'#a5a58b','stone_h':'#cfcaab',
 'moss_d':'#3f563c','moss':'#6c8951','moss_l':'#9caa61','copper_d':'#59372b','copper':'#a56a46','copper_l':'#dcaa70','copper_h':'#f2ce94',
 'iron_d':'#333d3b','iron':'#586563','iron_l':'#8d9690','iron_h':'#c1c2aa',
 'wood_d':'#45312b','wood':'#745039','wood_l':'#aa7c50','glass_d':'#22494d','glass':'#3e7d83','glass_l':'#6fc3c0','glass_h':'#bee9d6',
 'amber_d':'#80532f','amber':'#e9a64f','amber_l':'#ffe4a1','red':'#cf6555'
}

def color(c):return P.get(c,c)
def box(d,xy,c):d.rectangle(tuple(map(int,xy)),fill=color(c))
def line(d,pts,c,w=1):d.line([tuple(map(int,p)) for p in pts],fill=color(c),width=w)
def poly(d,pts,c):d.polygon([tuple(map(int,p)) for p in pts],fill=color(c))
def dot(d,x,y,c):box(d,(x,y,x,y),c)
def rivet(d,x,y,lit=False):
 box(d,(x,y,x+2,y+2),'ink');dot(d,x,y,'copper_h' if lit else 'copper_l');dot(d,x+1,y+1,'copper')
def tube(d,x0,y0,x1,y1):
 box(d,(x0,y0,x1,y1),'ink');box(d,(x0+1,y0+1,x1-1,y1-1),'copper_d');line(d,[(x0+2,y0+1),(x1-2,y0+1)],'copper_l');line(d,[(x0+2,y1-2),(x1-2,y1-2)],'copper')
def foot(d,x0=12,x1=51):
 poly(d,[(x0+2,42),(x1-2,42),(x1,44),(x1,45),(x0,45),(x0,44)],'ink');line(d,[(x0+3,43),(x1-3,43)],'stone_l');line(d,[(x0+1,44),(x1-1,44)],'stone_d')
def low_cover(f):
 im=Image.new('RGBA',CELL);d=ImageDraw.Draw(im)
 if f==3:
  poly(d,[(8,40),(12,35),(23,36),(26,39),(37,37),(43,39),(52,38),(55,43),(55,45),(8,45)],'ink');poly(d,[(10,40),(13,37),(22,38),(24,41),(36,39),(41,41),(51,40),(53,43),(53,44),(10,44)],'stone');line(d,[(13,37),(22,38),(24,41),(34,40)],'stone_l');line(d,[(40,41),(49,40)],'stone_h');box(d,(10,43,17,44),'moss_d');dot(d,12,42,'moss_l');return im
 poly(d,[(8,31),(11,28),(50,28),(55,32),(55,45),(8,45)],'ink')
 poly(d,[(10,32),(12,30),(49,30),(53,33),(53,43),(10,43)],'stone_d')
 poly(d,[(11,31),(13,29),(48,29),(52,32),(11,32)],'stone_h')
 box(d,(10,33,52,41),'stone');line(d,[(10,42),(53,42)],'stone_d');line(d,[(12,34),(23,34),(25,36),(36,36),(38,34),(50,34)],'stone_l')
 line(d,[(26,33),(25,38),(27,41)],'stone_d');line(d,[(43,34),(41,39),(42,41)],'stone_d');line(d,[(14,38),(19,37),(22,39)],'stone_d')
 poly(d,[(11,29),(17,29),(17,31),(21,31),(20,33),(15,32),(12,34),(10,33)],'moss');dot(d,13,29,'moss_l');line(d,[(47,30),(49,31),(50,34)],'moss_d')
 # Shallow relay groove, physically carved rather than a floating icon.
 line(d,[(31,33),(29,36),(32,39),(35,36),(33,34)],'stone_d');dot(d,31,35,'stone_h')
 if f>=1:line(d,[(38,29),(35,33),(37,36)],'ink');dot(d,38,29,'amber_l')
 if f>=2:line(d,[(37,36),(34,38),(35,43)],'ink');line(d,[(36,38),(37,40)],'stone_h');box(d,(48,41,50,42),'ink')
 return im

def grate(f):
 im=Image.new('RGBA',CELL);d=ImageDraw.Draw(im)
 # Anchored stone recess. Its empty aperture is never drawn as an item reward.
 poly(d,[(8,9),(11,6),(52,6),(55,9),(55,45),(8,45)],'ink');box(d,(10,10,53,43),'stone_d');line(d,[(12,8),(51,8)],'stone_h');line(d,[(10,10),(10,42)],'stone_l');line(d,[(12,43),(52,43)],'stone')
 box(d,(14,12,49,41),'deep');box(d,(16,14,47,39),'iron_d');line(d,[(17,14),(46,14)],'copper_d')
 for y in [20,30,40]:line(d,[(12,y),(51,y)],'stone')
 if f<2:
  tube(d,12,10,51,14);tube(d,12,38,51,42)
  for x in [16,23,30,37,44]:
   box(d,(x,13,x+3,39),'ink');box(d,(x+1,14,x+2,38),'copper_d');line(d,[(x+1,15),(x+1,36)],'copper_l');dot(d,x+2,18,'copper')
  tube(d,12,25,51,29);rivet(d,13,11);rivet(d,47,11);rivet(d,13,39);rivet(d,47,39)
  if f==1:
   line(d,[(33,12),(30,20),(33,25),(29,29),(31,39)],'ink',2);line(d,[(34,14),(32,21),(34,24)],'copper_h');box(d,(29,26,33,28),'deep')
 else:
  # Distinct bent halves: clear, readable hole through the centre.
  poly(d,[(13,12),(24,12),(20,27),(18,39),(12,41),(12,25)],'ink');poly(d,[(14,14),(21,14),(18,27),(17,37),(14,38)],'copper_d');line(d,[(15,15),(17,15),(15,35)],'copper_l')
  poly(d,[(41,12),(51,12),(51,40),(44,38),(45,26)],'ink');poly(d,[(44,14),(49,14),(49,37),(46,35),(47,25)],'copper_d');line(d,[(46,15),(48,15),(48,34)],'copper_l')
  for y in [18,28,36]:line(d,[(13,y),(19 if y<25 else 17,y-2)],'copper');line(d,[(46,y-1),(50,y)],'copper')
  box(d,(23,42,28,44),'copper_d');line(d,[(23,42),(28,42)],'copper_l');box(d,(36,43,41,44),'copper');dot(d,39,42,'copper_h')
  if f==2:
   line(d,[(27,8),(25,6)],'amber_l');line(d,[(36,9),(38,6)],'amber');dot(d,31,7,'copper_h');line(d,[(25,21),(27,19)],'copper_l');dot(d,37,31,'amber_l')
 return im

def ammo(f):
 im=Image.new('RGBA',CELL);d=ImageDraw.Draw(im)
 poly(d,[(16,29),(19,26),(44,26),(47,29),(47,45),(16,45)],'ink');box(d,(18,30,45,43),'wood');line(d,[(19,31),(44,31)],'wood_l');line(d,[(19,34),(44,34)],'wood_d');line(d,[(20,41),(44,41)],'wood_d');line(d,[(25,31),(25,42)],'wood_d');line(d,[(38,31),(38,42)],'wood_d')
 for x in [17,44]:box(d,(x,28,x+2,44),'copper_d');line(d,[(x,29),(x,42)],'copper_l');rivet(d,x,29);rivet(d,x,41)
 if f<2:
  tube(d,16,24 if f==0 else 22,47,29 if f==0 else 27);box(d,(28,29,34,34),'ink');box(d,(29,30,33,32),'copper_l');dot(d,31,31,'copper_h')
  # Three engraved pistol cartridges distinguish ammunition from fruit/chests.
  for x in [27,31,35]:box(d,(x,37,x+2,40),'copper_d');dot(d,x+1,36,'copper_h');line(d,[(x+1,37),(x+1,39)],'copper_l')
 else:
  poly(d,[(17,26),(20,22),(44,22),(46,26)],'ink');line(d,[(20,23),(43,23)],'copper_l');box(d,(20,27,43,31),'deep')
  if f==2:
   for x,y in [(23,26),(29,25),(35,26)]:
    box(d,(x,y,x+4,y+8),'ink');box(d,(x+1,y+1,x+3,y+7),'copper');line(d,[(x+1,y+2),(x+1,y+5)],'copper_h');box(d,(x+1,y-1,x+3,y),'stone_h');dot(d,x+2,y-2,'stone_l')
  else:line(d,[(23,29),(40,29)],'wood_d');dot(d,25,29,'copper_d')
 return im

def signal(f):
 im=Image.new('RGBA',CELL);d=ImageDraw.Draw(im)
 foot(d,20,43);box(d,(22,12,41,43),'ink');box(d,(24,14,39,41),'copper_d');line(d,[(24,14),(38,14),(38,40)],'copper');line(d,[(24,16),(24,39)],'copper_l')
 tube(d,20,10,43,14);box(d,(23,18,38,30),'ink');box(d,(25,20,36,28),'glass_d');line(d,[(25,20),(35,20)],'glass');line(d,[(25,21),(25,25)],'glass_l')
 # Readable copper circuit: three coded windows and a physical latch.
 for x in [26,30,34]:box(d,(x,22,x+1,25),'iron_d')
 if f:
  for i,x in enumerate([26,30,34]):
   on=(i==0 or (i+f)%2==0 or f==3);box(d,(x,22,x+1,25),'amber' if on else 'glass');dot(d,x,22,'amber_l' if on else 'glass_l')
  line(d,[(27,27),(34,27)],'glass_l');box(d,(30,16,33,17),'amber_l' if f==3 else 'amber')
 line(d,[(27,33),(27,37),(32,37),(32,34),(36,34)],'copper');dot(d,27,33,'copper_h');box(d,(36,33,37,38),'ink');line(d,[(36,34),(36,37)],'copper_h')
 rivet(d,24,39);rivet(d,37,39);rivet(d,21,11);rivet(d,40,11)
 if f==3:dot(d,30,15,'amber_l');dot(d,33,15,'amber_l')
 return im

def plaque(kind,f):
 im=Image.new('RGBA',CELL);d=ImageDraw.Draw(im)
 box(d,(27,39,30,45),'ink');line(d,[(28,40),(28,44)],'wood_l');box(d,(35,39,38,45),'ink');line(d,[(36,40),(36,44)],'wood')
 poly(d,[(10,29),(13,26),(50,26),(53,29),(53,38),(50,41),(13,41),(10,38)],'ink');poly(d,[(12,30),(14,28),(49,28),(51,30),(51,37),(49,39),(14,39),(12,37)],'copper_d');line(d,[(14,28),(48,28)],'copper_l');line(d,[(12,31),(12,36)],'copper');line(d,[(15,39),(49,39)],'wood_d')
 face='glass_l' if f else 'stone_l';shade='glass_d' if f else 'wood_d'
 # All route pictograms are engraved; no language is baked into sprites.
 if kind=='water':
  for y in [31,35]:line(d,[(17,y),(20,y-1),(23,y+1),(26,y-1),(29,y+1),(32,y-1),(35,y)],shade,2);line(d,[(17,y),(20,y-1),(23,y+1),(26,y-1),(29,y+1),(32,y-1),(35,y)],face)
 elif kind=='terrace':
  line(d,[(17,37),(17,35),(22,35),(22,32),(27,32),(27,29),(32,29)],face,2);poly(d,[(28,35),(30,32),(34,32),(33,35),(30,37)],face);dot(d,29,35,shade)
 elif kind=='roots':
  line(d,[(25,29),(25,33),(21,36),(19,38)],face,2);line(d,[(25,33),(29,35),(31,38)],face,2);poly(d,[(34,30),(37,33),(34,37),(32,33)],face);line(d,[(34,31),(34,35)],shade)
 else:
  poly(d,[(26,29),(23,30),(22,33),(23,36),(26,37),(28,36),(25,35),(24,33),(25,31),(28,30)],face);line(d,[(31,30),(31,34),(28,37)],face);line(d,[(31,34),(35,37)],face)
 # Engraved forward arrow has the same directional meaning on every plate.
 line(d,[(40,33),(46,33),(44,31)],face,2);line(d,[(46,33),(44,35)],face)
 rivet(d,13,30);rivet(d,48,36)
 if f:dot(d,16,28,'amber_l');dot(d,48,28,'amber')
 return im

def pump(f):
 im=Image.new('RGBA',CELL);d=ImageDraw.Draw(im)
 foot(d,10,53);tube(d,14,10,21,42);tube(d,42,19,49,42);tube(d,16,6,43,12);tube(d,42,13,49,24)
 box(d,(24,15,39,40),'ink');box(d,(26,17,37,38),'iron_d');box(d,(27,18,36,37),'glass_d');line(d,[(27,18),(35,18)],'glass');line(d,[(27,19),(27,34)],'glass_l')
 for y in [22,28,34]:line(d,[(35,y),(37,y)],'copper_l')
 if f:
  level=32 if f==1 else 21;box(d,(28,level,34,36),'glass');line(d,[(28,level),(34,level)],'glass_h')
  if f>=2:
   for x,y in ([(30,25),(33,31),(29,34)] if f==2 else [(32,23),(29,29),(33,35)]):box(d,(x,y,x+1,y+2),'glass_l');dot(d,x,y,'glass_h')
 # Forged valve wheel: distinct physical spokes per operating state.
 d.ellipse((11,22,25,36),fill=color('ink'));d.ellipse((13,24,23,34),fill=color('copper_d'));d.ellipse((14,25,22,33),outline=color('copper_l'),width=1)
 spokes=[[(18,25),(18,33),(14,29),(22,29)],[(15,26),(21,32),(15,32),(21,26)],[(18,25),(18,33),(14,29),(22,29)],[(15,26),(21,32),(15,32),(21,26)]][f]
 line(d,spokes[:2],'copper_l');line(d,spokes[2:],'copper_l');box(d,(17,28,19,30),'copper_h')
 for x in [14,44]:rivet(d,x,10);rivet(d,x,39)
 box(d,(30,11,34,13),'glass_d' if not f else 'amber');dot(d,31,11,'glass' if not f else 'amber_l')
 return im

def pennant(f):
 im=Image.new('RGBA',CELL);d=ImageDraw.Draw(im)
 foot(d,18,29);box(d,(21,4,24,43),'ink');line(d,[(22,5),(22,41)],'copper_l');line(d,[(23,7),(23,41)],'copper_d');poly(d,[(20,4),(22,2),(24,3),(25,5),(22,6)],'copper_h')
 shapes=[[(24,8),(32,7),(39,10),(45,9),(42,17),(34,19),(25,17)],[(24,8),(33,9),(40,7),(45,10),(43,18),(35,17),(25,18)],[(24,8),(32,11),(39,12),(44,14),(41,21),(33,20),(25,18)],[(24,8),(33,8),(40,10),(45,12),(43,19),(35,19),(25,17)]]
 poly(d,shapes[f],'ink');inner=[(x-1 if x>30 else x+1,y+1 if i<4 else y-1) for i,(x,y) in enumerate(shapes[f])];poly(d,inner,'glass_d');line(d,[(25,10),(32,10+f%2),(38,12+f//2),(42,12+f//2)],'glass_l');line(d,[(26,16),(33,17),(39,16+f)],'glass')
 # Woven directional chevron, not a disconnected UI arrow.
 line(d,[(31,12+f//2),(34,14+f//2),(31,16+f//2)],'amber_l');dot(d,24,9,'copper_h');dot(d,24,16,'copper_l')
 return im

DRAWINGS=[('relay_cover',4,low_cover),('copper_grate',4,grate),('ammo_cache',4,ammo),('shore_signal',4,signal),('route_water',2,lambda f:plaque('water',f)),('route_terrace',2,lambda f:plaque('terrace',f)),('route_roots',2,lambda f:plaque('roots',f)),('route_root_secret',2,lambda f:plaque('secret',f)),('water_pump',4,pump),('wind_pennant',4,pennant)]

def main():
 atlas=Image.new('RGBA',(CELL[0]*4,CELL[1]*len(DRAWINGS)));entries={};hashes=set()
 for row,(key,count,fn) in enumerate(DRAWINGS):
  frames=[]
  for col in range(count):
   image=fn(col);bbox=image.getbbox();assert bbox and bbox[3]==46,(key,col,bbox)
   origin=(24,46) if key=='wind_pennant' else ORIGIN
   hashes.add(hashlib.sha256(image.tobytes()).hexdigest());atlas.alpha_composite(image,(CELL[0]*col,CELL[1]*row));frames.append({'rect':[CELL[0]*col,CELL[1]*row,*CELL],'visible_bounds':list(bbox),'origin':list(origin)})
  entries[key]={'row':row,'frame_count':count,'frames':frames,'visible_world_size':[(frames[0]['visible_bounds'][2]-frames[0]['visible_bounds'][0])*2,(frames[0]['visible_bounds'][3]-frames[0]['visible_bounds'][1])*2]}
 path=OUT/'m1-forge-props.png';atlas.save(path,optimize=True)
 meta={'version':1,'authorship':'Original project-local hand-authored integer-pixel source generator; no external graphics, no generated or duplicated filler frames.','source':'packaging/draw_m1_forge_props.py','palette':P,'cell':list(CELL),'origin':list(ORIGIN),'world_scale':2,'path':'assets/m1-forge-props.png','sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'distinct_frames':len(hashes),'total_frames':sum(d[1] for d in DRAWINGS),'entries':entries}
 (OUT/'m1-forge-props-PROVENANCE.json').write_text(json.dumps(meta,indent=2)+'\n')
 # Review is exact nearest-neighbour integer enlargement, separate from source.
 bg=Image.new('RGBA',atlas.size,(35,29,40,255));bg.alpha_composite(atlas);bg.resize((atlas.width*3,atlas.height*3),Image.Resampling.NEAREST).save(WORK/'contact-3x.png')
 print(json.dumps({'png_bytes':path.stat().st_size,'frames':meta['total_frames'],'distinct':len(hashes),'sizes':{k:v['visible_world_size'] for k,v in entries.items()}}))
if __name__=='__main__':main()
