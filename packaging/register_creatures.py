"""Read-only registration of the 24-pose creature atlas. Never rewrites art."""
import hashlib,json
from pathlib import Path
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
path=ROOT/'assets/woodland-creatures.png'
a=np.array(Image.open(path).convert('RGBA'));assert a.shape==(1024,1536,4)
scales=[.37,.29,.32,.34];names=['bat','slime','beetle','wisp'];frames=[]
for row in range(4):
 poses=[]
 for col in range(6):
  q=a[row*256:(row+1)*256,col*256:(col+1)*256].astype(float)
  mask=q[:,:,3]>=32;yy,xx=np.indices(mask.shape);ys,xs=np.where(mask)
  bounds=[int(xs.min()),int(ys.min()),int(xs.max()+1),int(ys.max()+1)]
  gold=(q[:,:,3]>180)&(q[:,:,0]>130)&(q[:,:,1]>95)&(q[:,:,0]>q[:,:,1]*1.04)&(q[:,:,1]>q[:,:,2]*1.25)&(q[:,:,2]<135)
  if row==0:gold&=(xx>95)&(xx<135)&(yy>130)&(yy<175)
  elif row==1:gold&=(xx>60)&(xx<140)&(yy>bounds[1]+(bounds[3]-bounds[1])*.43)
  elif row==2:gold&=(xx>70)&(xx<103)&(yy>140)&(yy<181)
  else:gold&=(xx>78)&(xx<130)&(yy>120)&(yy<190)
  assert gold.sum()>40,(row,col)
  eye=[round(float(xx[gold].mean()),4),round(float(yy[gold].mean()),4)]
  origin=[eye[0]+(8 if row==0 else (7 if row==3 else (9 if row==1 else 18)))/scales[row],eye[1]+6/scales[row] if row==0 else (eye[1]-3/scales[row] if row==3 else bounds[3])]
  runs=[]
  for y in range(256):
   line=np.flatnonzero(mask[y]);groups=np.split(line,np.where(np.diff(line)>1)[0]+1)
   for group in groups:
    if len(group):runs.append([y,int(group[0]),len(group)])
  poses.append({'rect':[col*256,row*256,256,256],'bounds':bounds,'runs':runs,'eye':eye,'origin':[round(x,4) for x in origin],'source_column':col,'registration':'near-eye-and-floor' if row in [1,2] else 'near-eye','frame_seconds':round(([.70,np.pi/2.8,.65,.85][row])/6,6)})
 frames.append(poses)
meta={'method':'Original generated PNG retained byte-for-byte. Read-only alpha spans (>=32) exclude near-transparent matte, with two transparent pixels of runtime padding. One scale per species. Eye landmark fixes horizontal registration; shared floor for ground creatures. Physics coordinates and hitboxes are unchanged.','source_generation':'exec-f2df8e40-1ef4-4618-84ef-672809d77628','species':names,'reference_style':'Existing Aion and adventure enemy pixel-art design; original heroes/crow/gnome assets are unchanged.','atlas':{'path':'assets/woodland-creatures.png','rows':4,'columns':6,'width':1536,'height':1024,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'scale':scales,'anchor_x':[128]*4,'frames':frames}}
(ROOT/'assets/CREATURES-PROVENANCE.json').write_text(json.dumps(meta,separators=(',',':'))+'\n')
print('Registered',sum(len(r) for r in frames),'original poses;',path.stat().st_size,'source bytes')
