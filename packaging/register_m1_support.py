"""Register untouched owner-requested source PNG; source alpha spans only."""
from pathlib import Path
import hashlib,json,numpy as np
from PIL import Image
from register_pixel_heroes import cuts
root=Path(__file__).resolve().parents[1];p=root/'assets/m1-support.png';a=np.asarray(Image.open(p).convert('RGBA'));ys=cuts((a[:,:,3]>=160).sum(1),3);frames={};groups=[]
for row in range(3):
 xs=cuts((a[ys[row]:ys[row+1],:,3]>=160).sum(0),6);group=[]
 for col in range(6):
  q=a[ys[row]:ys[row+1],xs[col]:xs[col+1]];mask=q[:,:,3]>=96;yy,xx=np.where(mask);bounds=[int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)];runs=[]
  for y in range(bounds[1],bounds[3]):
   z=np.diff(np.pad(mask[y].astype(np.int8),(1,1)));runs.extend([[y,int(s),int(e-s)] for s,e in zip(np.where(z==1)[0],np.where(z==-1)[0])])
  red=(q[:,:,0]>130)&(q[:,:,0]>q[:,:,1]*1.5)&(q[:,:,1]<100)&mask
  ry,rx=np.where(red&(np.indices(mask.shape)[1]>mask.shape[1]*.45)&(np.indices(mask.shape)[0]<mask.shape[0]*.7))
  origin=[float(np.median(rx)) if row==0 and len(rx)>15 else (bounds[0]+bounds[2])*.5,float(bounds[3]) if row==0 else (bounds[1]+bounds[3])*.5]
  group.append({'rect':[int(xs[col]),int(ys[row]),q.shape[1],q.shape[0]],'bounds':bounds,'runs':runs,'origin':origin})
 groups.append(group)
scale=30./np.median([f['bounds'][3]-f['bounds'][1] for f in groups[0]])
for row,key in enumerate(['spider-walk','spider-burst']):
 for i,f in enumerate(groups[row]):f['scale']=float(scale);frames[key+':'+str(i)]=f
for key,size,f in zip(['owl_feather','wolf_charm','owl_stone','satchel','trap','energy'],[32,32,26,34,32,30],groups[2]):
 f['scale']=size/max(f['bounds'][2]-f['bounds'][0],f['bounds'][3]-f['bounds'][1]);frames[key+':0']=f
(root/'assets/M1-SUPPORT-PROVENANCE.json').write_text(json.dumps({'path':'assets/m1-support.png','sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'status':'Owner-requested original gameart, visualdraft; no SNK art.','source_drawings':18,'animated_clips':2,'static_props':6,'frames':frames},separators=(',',':'))+'\n')
print('Registered12animationframesand6props')
