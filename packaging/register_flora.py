"""Read-only registration of original three-pose scenery; preserves PNG bytes."""
from pathlib import Path
import json,hashlib
from PIL import Image
import numpy as np
from scipy.ndimage import label
root=Path(__file__).resolve().parents[1];p=root/'assets/aionverse-flora.png';a=np.array(Image.open(p));h,w=a.shape[:2];frames=[];scales=[]
for row in range(6):
 poses=[]
 for col in range(3):
  x0,x1=round(col*w/3),round((col+1)*w/3);y0,y1=round(row*h/6),round((row+1)*h/6);q=a[y0:y1,x0:x1];labels,_=label(q[:,:,3]>=192,np.ones((3,3)));sizes=np.bincount(labels.ravel());sizes[0]=0;mask=labels==sizes.argmax();ys,xs=np.where(mask);b=[int(xs.min()),int(ys.min()),int(xs.max()+1),int(ys.max()+1)];runs=[]
  for y in range(mask.shape[0]):
   z=np.flatnonzero(mask[y]);groups=np.split(z,np.where(np.diff(z)>1)[0]+1)
   for g in groups:
    if len(g):runs.append([y,int(g[0]),len(g)])
  # Common root reference, independent of swaying leaves and outer bounds.
  bottom=mask[max(0,b[3]-18):b[3]];by,bx=np.where(bottom);origin=[round(float(bx.mean()),4),b[3]]
  poses.append({'rect':[x0,y0,x1-x0,y1-y0],'bounds':b,'runs':runs,'origin':origin,'eye':None,'registration':'root-and-floor','source_column':col,'body_bounds':b,'ground_contact':True})
 frames.append(poses);scales.append(86/max(f['bounds'][3]-f['bounds'][1] for f in poses))
meta={'generation':'exec-f5cb81ba-3205-4790-9927-9fab7373f5ab','method':'Original PNG unchanged. Opaque connected root/trunk spans discard near-transparent matte and detached shadow; independent padded runtime frames; one shared scale per prop, root and floor registration. Three small wind poses per biome. Decorative only, no hitbox.','atlas':{'path':'assets/aionverse-flora.png','width':w,'height':h,'columns':3,'rows':6,'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'frames':frames,'scale':scales,'anchor_x':[w/6]*6}}
(root/'assets/FLORA-PROVENANCE.json').write_text(json.dumps(meta,separators=(',',':'))+'\n');print('Registered18 unchanged flora poses')
