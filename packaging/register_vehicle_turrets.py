"""Measure original cannon layers; do not rewrite source PNGs or old anchors."""
from pathlib import Path
import hashlib,json,sys,math
import numpy as np
from PIL import Image,ImageDraw
from campaign_registration import match_patch
ROOT=Path(__file__).resolve().parents[1]
META=json.loads((ROOT/'assets/FORGE-VEHICLES-PROVENANCE.json').read_text())
# Trace the peripheral bronze barrel, leaving the original hull/socket around it.
# A rectangular crop alone would remove cyan shell corners and green body pixels.
# Skimmer leaves its rear brass mounting collar on the hull so the rotating
# barrel remains attached when aimed vertically.
CUTS={'shell':[108,85,140,113],'wind':[107,78,143,96],'drill':[108,63,139,90],'skimmer':[23,60,60,86]}
POLYGONS={
 'shell':[(112,99),(118,90),(128,87),(135,92),(139,100),(135,109),(126,111),(116,108),(112,104)],
 'wind':[(109,87),(116,79),(124,79),(126,80),(138,80),(141,84),(141,89),(127,90),(123,94),(114,94),(109,91)],
 'drill':[(109,67),(118,64),(122,68),(136,74),(138,77),(133,80),(127,82),(122,85),(115,88),(110,86),(109,80)],
 'skimmer':[(24,69),(28,64),(34,62),(45,64),(49,62),(56,64),(59,68),(59,84),(24,84)]}

def polygon_mask(shape, points):
 # Pixel-centre ray crossing matches Geometry2D.is_point_in_polygon at runtime.
 yy,xx=np.indices(shape);px=xx+.5;py=yy+.5;inside=np.zeros(shape,dtype=bool)
 for (x0,y0),(x1,y1) in zip(points,points[1:]+points[:1]):
  if y0==y1:continue
  inside^=((y0>py)!=(y1>py))&(px<(x1-x0)*(py-y0)/(y1-y0)+x0)
 return inside

# Visually traced connector centres and metal noses for source poses whose old
# metadata followed the chassis rather than the visibly tilting barrel.
CALIBRATIONS={
 ('wind',0,5):([111,90],[139,90],None),
 ('wind',2,0):([108,88],[138,88],[(109,88),(116,80),(124,80),(126,81),(138,81),(141,85),(141,90),(127,91),(123,95),(114,95),(109,92)]),
 ('wind',2,1):([108,89],[139,89],[(109,89),(116,81),(124,81),(126,82),(138,82),(141,86),(141,91),(127,92),(123,96),(114,96),(109,93)]),
 ('wind',2,2):([108,88],[138,94],[(108,86),(116,83),(125,85),(137,88),(140,91),(140,97),(133,98),(124,94),(114,93),(108,91)]),
 ('wind',2,3):([106,94],[133,100],[(104,89),(114,88),(123,92),(133,95),(135,98),(135,105),(130,105),(121,101),(112,98),(104,95)]),
 ('wind',2,4):([106,103],[133,109],[(103,98),(113,97),(124,101),(133,104),(135,108),(134,114),(128,114),(120,109),(109,107),(103,103)]),
 ('wind',2,5):([112,103],[138,109],[(110,97),(119,98),(128,101),(138,104),(140,107),(139,113),(133,113),(124,109),(115,106),(110,103)]),
 ('drill',2,0):([100,86],[133,86],[(109,77),(118,74),(122,78),(136,84),(138,87),(133,90),(127,92),(122,95),(115,98),(110,96),(109,90)]),
 ('drill',2,1):([105,86],[138,88],[(112,78),(119,77),(124,81),(137,86),(139,89),(135,92),(127,95),(118,95),(111,91)]),
 ('drill',2,2):([108,88],[137,95],[(112,82),(120,82),(127,86),(140,93),(141,96),(133,98),(123,98),(113,94),(110,88)]),
 ('drill',2,3):([106,85],[132,94],[(107,76),(116,77),(123,82),(133,92),(134,95),(126,96),(115,92),(106,88),(104,82)]),
 ('drill',2,4):([106,95],[129,103],[(108,86),(117,87),(123,93),(131,101),(132,104),(124,105),(114,102),(105,99),(104,92)]),
 ('drill',2,5):([109,102],[129,109],[(112,92),(119,95),(125,101),(131,108),(131,111),(121,112),(111,110),(108,105),(108,98)])}

def image_for(raw,f):
 q=np.zeros((int(f['rect'][3]),int(f['rect'][2]),4),dtype=np.uint8)
 for y,x,n in f['runs']:q[y,x:x+n]=raw[int(f['rect'][1])+y,int(f['rect'][0])+x:int(f['rect'][0])+x+n]
 return q
out={}
review=ROOT/'build/vehicle-turret-review';review.mkdir(parents=True,exist_ok=True)
for kind,data in META['types'].items():
 raw=np.array(Image.open(ROOT/data['path']).convert('RGBA'));first=data['frames'][0][0];ref=image_for(raw,first)
 c=CUTS[kind];template=ref[c[1]:c[3],c[0]:c[2]].copy()
 rows=[];canvas=Image.new('RGBA',(6*350,len(data['frames'])*270),(32,28,38,255));draw=ImageDraw.Draw(canvas)
 for phase,line in enumerate(data['frames']):
  result=[]
  for col,f in enumerate(line):
   q=image_for(raw,f)
   if phase==3:result.append({'can_fire':False});continue
   if kind=='skimmer':
    dx=float(f['body_landmark'][0])-float(first['body_landmark'][0]);dy=float(f['body_landmark'][1])-float(first['body_landmark'][1])
    x,y,error=match_patch(q,template,[c[0]+dx,c[1]+dy],[10,10])
    dx=x-c[0];dy=y-c[1];pivot=[58.+dx,74.+dy];muzzle=[26.+dx,74.+dy];direction=-1
   else:
    pivot=list(map(float,f['barrel_pivot']));muzzle=list(map(float,f['muzzle']));direction=1;error=0.
    dx=pivot[0]-float(first['barrel_pivot'][0]);dy=pivot[1]-float(first['barrel_pivot'][1])
   cut=[max(0,int(round(c[0]+dx))),max(0,int(round(c[1]+dy))),min(q.shape[1],int(round(c[2]+dx))),min(q.shape[0],int(round(c[3]+dy)))]
   polygon=[[float(x+dx),float(y+dy)] for x,y in POLYGONS[kind]]
   calibration=CALIBRATIONS.get((kind,phase,col))
   if calibration:
    pivot,muzzle,traced=calibration
    if traced:
     polygon=[list(point) for point in traced]
     cut=[max(0,int(math.floor(min(point[0] for point in polygon)))),max(0,int(math.floor(min(point[1] for point in polygon)))),min(q.shape[1],int(math.ceil(max(point[0] for point in polygon)))+1),min(q.shape[0],int(math.ceil(max(point[1] for point in polygon)))+1)]
   mask=polygon_mask(q.shape[:2],polygon);x0,y0,x1,y1=cut
   hull=q.copy();hull[mask]=0;barrel=q.copy();barrel[~mask]=0;gun=barrel[y0:y1,x0:x1]
   count=int(np.count_nonzero(gun[:,:,3]));assert count>25,(kind,phase,col,count)
   result.append({'can_fire':True,'cut':cut,'polygon':polygon,'pivot':pivot,'muzzle':muzzle,'source_facing':direction,'axis_radians':math.atan2(muzzle[1]-pivot[1],abs(muzzle[0]-pivot[0])),'template_error':round(error,6),'opaque_pixels':count})
   # Diagnostic partition only: original canvas positions and pixels retained.
   hi=Image.fromarray(hull);hi=hi.resize((round(hi.width*1.5),round(hi.height*1.5)),Image.Resampling.NEAREST);canvas.alpha_composite(hi,(col*350,phase*270+20))
   gi=Image.fromarray(gun);gi=gi.resize((gi.width*2,gi.height*2),Image.Resampling.NEAREST);canvas.alpha_composite(gi,(col*350+240,phase*270+45));draw.text((col*350+2,phase*270+2),f'{kind} {phase}/{col} cut{cut}',fill='white')
  rows.append(result)
 canvas.save(review/(kind+'-partition.png'))
 out[kind]={'source':data['path'],'sha256':hashlib.sha256((ROOT/data['path']).read_bytes()).hexdigest(),'frames':rows}
(ROOT/'assets/M1-VEHICLE-TURRETS.json').write_text(json.dumps({'version':3,'method':'Peripheral polygon source-pixel partition, original bytes unchanged. Mounted fire phase uses neutral hull to prevent a second fixed barrel/flash. Skimmer uses the visible rear left cannon, canonically mirrored right; its old front-lantern endpoint remains only in legacy APIs.','types':out},separators=(',',':'))+'\n')
print('Registered original cannon partitions:',sum(sum(bool(f['can_fire']) for f in line) for d in out.values() for line in d['frames']))
