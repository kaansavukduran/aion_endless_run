"""Register unchanged, actually drawn shoulder poses and the Eren atlas.

No PNG retouching. Atlas cells, isolated alpha spans, authored single scales and
body/ground origins are explicit and reviewable. Eren has seven real idle poses.
"""
from pathlib import Path
import json,hashlib,numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter1d,label
from scipy.signal import find_peaks
ROOT=Path(__file__).resolve().parents[1]
def cuts(v,n):
 step=len(v)/n;s=gaussian_filter1d(v.astype(float),step*.12);p,_=find_peaks(s,distance=step*.63,prominence=s.max()*.075)
 if len(p)!=n:p=np.array([(i+.5)*step for i in range(n)])
 smooth=gaussian_filter1d(v.astype(float),max(1,step*.018));out=[0]
 for lo,hi in zip(p,p[1:]):
  x0=round(lo+(hi-lo)*.28);x1=round(hi-(hi-lo)*.28);m=smooth[x0:x1+1].min();xs=np.where(smooth[x0:x1+1]<=m+1e-7)[0]+x0;out.append(int(min(xs,key=lambda x:abs(x-(lo+hi)/2))))
 return out+[len(v)]
def atlas(name,counts,heights):
 path=ROOT/'assets'/name;a=np.array(Image.open(path).convert('RGBA'));h,w=a.shape[:2];ys=cuts((a[:,:,3]>=128).sum(1),len(counts));rows=[];scales=[]
 for row,n in enumerate(counts):
  strip=a[ys[row]:ys[row+1]];xs=cuts((strip[:,:,3]>=128).sum(0),n);line=[]
  for col in range(n):
   q=strip[:,xs[col]:xs[col+1]];labs,k=label(q[:,:,3]>=96,np.ones((3,3)));sizes=np.bincount(labs.ravel());sizes[0]=0;mask=np.isin(labs,np.flatnonzero(sizes>=max(6,sizes.max()*.002)));yy,xx=np.where(mask);b=[int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)];runs=[]
   for y in range(mask.shape[0]):
    ix=np.flatnonzero(mask[y]);groups=np.split(ix,np.where(np.diff(ix)>1)[0]+1)
    for g in groups:
     if len(g):runs.append([y,int(g[0]),len(g)])
   line.append({'rect':[xs[col],ys[row],xs[col+1]-xs[col],ys[row+1]-ys[row]],'bounds':b,'body_bounds':b,'runs':runs,'eye':None,'source_column':col,'registration':'body-axis-and-ground'})
  # Entry/recovery share the upright character size; never fit each frame.
  scale=heights[row]/np.median([f['bounds'][3]-f['bounds'][1] for f in (line[:1]+line[-1:])]);scales.append(float(scale))
  for f in line:
   b=f['bounds'];f['origin']=[float((b[0]+b[2])/2),float(b[3])]
  rows.append(line)
 return {'path':'assets/'+name,'width':w,'height':h,'rows':len(rows),'columns':max(counts),'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'frames':rows,'scale':scales,'anchor_x':[0]*len(rows)}
shoulder=atlas('shoulder-somersaults.png',[12]*5,[82,82,82,82,82])
(ROOT/'assets/SHOULDER-POSES-PROVENANCE.json').write_text(json.dumps({'generation':'exec-3ffdcb46-a057-4ac2-892b-410313513491','method':'Original unchanged PNG. Actual12x5 drawn poses: lower, hands plant, shoulder/back roll, feet plant and rise. One somersault then hold the low recovery pose; never a looping sphere. All old PNGs preserved.','atlas':shoulder},separators=(',',':'))+'\n')
eren=atlas('eren-animations.png',[7]+[8]*9,[92]*10)
# All Eren rows use the same physical character scale (including airborne).
eren['scale']=[eren['scale'][0]]*10
(ROOT/'assets/EREN-PROVENANCE.json').write_text(json.dumps({'identity':'AIO-CHAR-EREN','name':'Eren','generation':'exec-9d6b3fef-8769-430d-a745-6dfbd85f46bf','method':'Original generated PNG unchanged.79 actual drawn poses;7 idle and8 in each remaining row. Current original sketch is primary design; modelling sheet is labelled Draft01, not a claim of final canon design approval. Eren and Emre remain distinct.','animations':['idle','run','jump','gun-run','gun-fire','shoulder-roll','hurt-fall','freeze','burn','ash'],'atlas':eren,'muzzle':[56,-30]},separators=(',',':'))+'\n')
print('Registered60 shoulder poses and79 Eren poses, source PNGs unchanged')
