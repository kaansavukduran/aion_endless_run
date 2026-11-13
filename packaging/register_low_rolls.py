"""Read unchanged source pixels; register 60 bent-knee/clockwise roll poses."""
from pathlib import Path
import json,hashlib
import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter1d,label
from scipy.signal import find_peaks
r=Path(__file__).resolve().parents[1];p=r/'assets/low-somersaults.png';a=np.array(Image.open(p).convert('RGBA'));h,w=a.shape[:2]
def cuts(mask,n):
 v=mask.astype(float);step=len(v)/n;s=gaussian_filter1d(v,step*.12);peaks,_=find_peaks(s,distance=step*.65,prominence=s.max()*.08)
 if len(peaks)!=n:peaks=np.array([round((i+.5)*step) for i in range(n)])
 out=[0];smooth=gaussian_filter1d(v,max(1,step*.018))
 for lo,hi in zip(peaks,peaks[1:]):
  left=round(lo+(hi-lo)*.28);right=round(hi-(hi-lo)*.28);m=smooth[left:right+1].min();xs=np.where(smooth[left:right+1]<=m+1e-6)[0]+left;out.append(int(min(xs,key=lambda x:abs(x-(lo+hi)/2))))
 return out+[len(v)]
ys=cuts((a[:,:,3]>=128).sum(axis=1),5);rows=[];scales=[]
for row in range(5):
 strip=a[ys[row]:ys[row+1]];xs=cuts((strip[:,:,3]>=128).sum(axis=0),12);line=[]
 for col in range(12):
  q=strip[:,xs[col]:xs[col+1]];mask=q[:,:,3]>=96;labs,n=label(mask,np.ones((3,3)));sizes=np.bincount(labs.ravel());sizes[0]=0
  # Keep substantial components, including the sheep's detached halo. Reject matte specks.
  mask=np.isin(labs,np.flatnonzero(sizes>=max(5,sizes.max()*.0015)));yy,xx=np.where(mask);b=[int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)];runs=[]
  for y in range(mask.shape[0]):
   ix=np.flatnonzero(mask[y]);groups=np.split(ix,np.where(np.diff(ix)>1)[0]+1)
   for g in groups:
    if len(g):runs.append([y,int(g[0]),len(g)])
  line.append({'rect':[xs[col],ys[row],xs[col+1]-xs[col],ys[row+1]-ys[row]],'bounds':b,'runs':runs,'eye':None,'source_column':col,'registration':'fixed-cell-center-and-ground'})
 anchor=float(np.median([(f['bounds'][0]+f['bounds'][2])/2 for f in line]))
 for f in line:f['origin']=[anchor,f['bounds'][3]]
 scale=72/max(f['bounds'][3]-f['bounds'][1] for f in line);rows.append(line);scales.append(scale)
 print(['aion','owl','sheep','wolf','rabbit'][row],'heights', [round((f['bounds'][3]-f['bounds'][1])*scale,1) for f in line])
d={'generation':'exec-546554f4-c748-4a99-b728-e81907038713','references':['assets/canonical-rolls.png','assets/emre-movement.png'],'method':'Original PNG unchanged; actual 12x5 cells, matte filtering, independent textures. Shared character scale and fixed row body axis; baseline ground contact per pose. Drawn knee bend, compact clockwise rotation and recovery.','atlas':{'path':'assets/low-somersaults.png','width':w,'height':h,'rows':5,'columns':12,'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'frames':rows,'scale':scales,'anchor_x':[0]*5}}
(r/'assets/LOW-ROLLS-PROVENANCE.json').write_text(json.dumps(d,separators=(',',':'))+'\n')
