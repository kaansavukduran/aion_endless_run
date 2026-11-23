"""Rebuild six pirate walk crop registrations from the committed original PNG."""
from pathlib import Path
import sys,json,shutil,hashlib,numpy as np
sys.path.insert(0,'packaging')
from campaign_registration import match_patch
from PIL import Image
from scipy.ndimage import label
p=Path('assets/pirate-walk.png')
a=np.array(Image.open(p).convert('RGBA'));labs,n=label(a[:,:,3]>=192,np.ones((3,3)));sizes=np.bincount(labs.ravel());ids=sorted([i for i in range(1,n+1) if sizes[i]>10000],key=lambda i:np.where(labs==i)[1].min());assert len(ids)==6
old=json.load(open('assets/CAMPAIGN-EXPANSION-PROVENANCE.json'))['atlases']['rescue-npcs'];target=(old['frames'][7][6]['body_bounds'][3]-old['frames'][7][6]['body_bounds'][1])*old['scales'][7]
frames=[]
for i,gid in enumerate(ids):
 yy,xx=np.where(labs==gid);x0,x1,y0,y1=int(xx.min()),int(xx.max()+1),int(yy.min()),int(yy.max()+1);q=a[y0:y1,x0:x1].copy();keep=labs[y0:y1,x0:x1]==gid;q[~keep]=0
 if i==0:scale=target/(y1-y0);patch=q[115:180,50:145].copy();ref=(50,115);ox=(x1-x0)/2
 fx,fy,err=match_patch(q,patch,ref,[40,30]);runs=[]
 for y in range(q.shape[0]):
  z=np.diff(np.pad(keep[y].astype(np.int8),(1,1)));runs.extend([[y,int(s),int(e-s)] for s,e in zip(np.where(z==1)[0],np.where(z==-1)[0])])
 frames.append({'rect':[x0,y0,x1-x0,y1-y0],'bounds':[0,0,x1-x0,y1-y0],'origin':[ox+fx-ref[0],y1-y0],'runs':runs})
Path('assets/PIRATE-WALK-PROVENANCE.json').write_text(json.dumps({'path':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'scale':scale,'frames':frames,'generation':'exec-aa2b216c-8acd-4c46-bdc9-8f510c76a316','source':'Pixel art remaster of the existing six-frame pirate walk, preserving the approved character design.','registration':'One fixed standing scale, matched face patch X, opaque soles Y; six distinct leftward walking cels.'},separators=(',',':'))+'\n')
