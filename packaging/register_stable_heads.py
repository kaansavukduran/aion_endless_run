"""Correct colour-only iris misidentification using registered whole-face pixels.

Reads original PNGs only. Bounded multi-channel template registration includes
nose, cheek, eye and outline, so a blue badge or a turquoise gun cannot become
an iris during a blink. Physical actor transforms and per-character scales stay
unchanged. Metadata records the actual probe rectangles and fit residuals.
"""
from pathlib import Path
import json,numpy as np
from PIL import Image
from scipy.signal import fftconvolve
from scipy.ndimage import label
ROOT=Path(__file__).resolve().parents[1];cache={};report=[]
def pixels(a,f):
 if a['path'] not in cache:cache[a['path']]=np.array(Image.open(ROOT/a['path']).convert('RGBA'))
 x,y,w,h=f['rect'];q=cache[a['path']][y:y+h,x:x+w].copy();mask=np.zeros(q.shape[:2],bool)
 for yy,xx,n in f['runs']:mask[yy,xx:xx+n]=True
 q[~mask]=0
 return q.astype(float)/255

def search(q,t,expected):
 sq=fftconvolve((q*q).sum(2),np.ones(t.shape[:2]),mode='valid');cross=sum(fftconvolve(q[:,:,c],t[::-1,::-1,c],mode='valid') for c in range(4));ssd=np.maximum(0,sq+(t*t).sum()-2*cross)
 if expected is not None:
  yy,xx=np.indices(ssd.shape);ssd[abs(xx-expected)>12]=np.inf
 y,x=np.unravel_index(np.argmin(ssd),ssd.shape);return int(x),int(y),float(ssd[y,x]/(t*t).sum())

def correct(a,rows,refrow,hero,reference=None,target=None):
 ref=a['frames'][refrow][0];q=pixels(a,ref);eye=reference or ref['eye'];assert eye is not None,hero
 x=max(0,round(eye[0]-14));y=max(0,round(eye[1]-16));t=q[y:y+34,x:x+39];b=ref.get('body_bounds',ref['bounds']);relative=[x-b[0],y-b[1]];refscale=a['scale'][refrow]
 target=target or [(eye[i]-ref['origin'][i])*refscale for i in range(2)]
 for row in rows:
  measurements=[]
  fs=a['frames'][row];step=a['width']/len(fs)
  initial=[search(pixels(a,f),t,None) for f in fs]
  reliable=[found[0]+f['rect'][0]-(i+.5)*step for i,(f,found) in enumerate(zip(fs,initial)) if found[2]<.16]
  if not reliable:raise ValueError(('No reviewed face cluster',hero,row))
  median=float(np.median(reliable))
  for i,f in enumerate(fs):
   # Good full-face fits need no lattice assumption: actual drawn cells
   # may be irregular. Weak blink fits are constrained to the previously
   # reviewed anatomical neighborhood, not a tail or another eye.
   expected=None if initial[i][2]<.16 else (f['eye'][0]-eye[0]+x if f.get('eye') is not None else median+(i+.5)*step-f['rect'][0])
   xx,yy,error=search(pixels(a,f),t,expected)
   if error>.38:raise ValueError(('Face needs review',hero,row,f['source_column'],error))
   marker=[float(round(xx+eye[0]-x)),float(round(yy+eye[1]-y))];old=f['origin'];new=[marker[i]-target[i]/a['scale'][row] for i in range(2)]
   measurements.append({'frame':f['source_column'],'old_origin':old,'new_origin':new,'residual':round(error,5),'source_probe':[xx,yy,39,34]})
   f['origin']=new;f['eye']=marker;f['anchor_x']=new[0];f['registration']='head';f['head_probe']=[xx,yy,39,34]
  report.append({'hero':hero,'path':a['path'],'row':row,'reference_row':refrow,'reference_probe':[x,y,39,34],'target':target,'measurements':measurements})

p=ROOT/'assets/CANONICAL-PROVENANCE.json';canonical=json.loads(p.read_text())
for hero in ['aion','owl','sheep','wolf']:
 a=canonical['atlases']['canonical-'+hero]
 for row in [0,1,2,6,7,8]:correct(a,[row],7 if row in [0,1,7,8] else row,hero,target=a['target_eye'])
canonical['registration_revision']='0.19.0-whole-face';p.write_text(json.dumps(canonical,separators=(',',':'))+'\n')
p=ROOT/'assets/AGILITY-PROVENANCE.json';agility=json.loads(p.read_text())
for key,a in agility['atlases'].items():correct(a,[0],0,key,target=a['target_eyes'][0])
p.write_text(json.dumps(agility,separators=(',',':'))+'\n')
p=ROOT/'assets/EMRE-PROVENANCE.json';emre=json.loads(p.read_text())
for key,rows in [('emre-movement',[0,1,2]),('emre-encounters',[0,1])]:
 for row in rows:correct(emre['atlases'][key],[row],row,key)
p.write_text(json.dumps(emre,separators=(',',':'))+'\n')
p=ROOT/'assets/EREN-PROVENANCE.json';eren=json.loads(p.read_text());a=eren['atlas'];ref=a['frames'][3][0];q=pixels(a,ref);b=ref['body_bounds'];rgb=q[:,:,:3];cream=(q[:,:,3]>.5)&(rgb[:,:,0]>.72)&(rgb[:,:,1]>rgb[:,:,0]*.78)&(rgb[:,:,2]>rgb[:,:,1]*.60)
cream[:round(b[1]+(b[3]-b[1])*.27)]=False;cream[round(b[1]+(b[3]-b[1])*.68):]=False
labs,n=label(cream,np.ones((3,3)));sizes=np.bincount(labs.ravel());sizes[0]=0;yy,xx=np.where(labs==sizes.argmax());eye=[float(xx.mean()-8),float(yy.mean()-9)]
correct(a,[0,1,2,3,4],3,'eren',reference=eye)
# Eren's actual pistol tip after registration; the attachment and projectile
# share this measured origin rather than borrowing Emre's weapon coordinates.
f=a['frames'][3][0];q=pixels(a,f);yy,xx=np.where(q[:,:,3]>.5);front=xx>=xx.max()-2;eren['muzzle']=[float((xx.max()+2-f['origin'][0])*a['scale'][3]),float((np.median(yy[front])-f['origin'][1])*a['scale'][3])]
a['head_spans']=[84.0]*10
p.write_text(json.dumps(eren,separators=(',',':'))+'\n')
(ROOT/'assets/HEAD-REGISTRATION.json').write_text(json.dumps({'method':'Bounded whole-face RGB/alpha template. Reference is a neutral live pistol-run pose. Never image bounds centroid or a single colour-only iris. Original PNGs unchanged; actor transforms and scales unchanged.','clips':report},separators=(',',':'))+'\n')
print('Registered',len(report),'whole-face clips; Eren muzzle',eren['muzzle'])
for rr in report:
 changes=[abs(q['new_origin'][0]-q['old_origin'][0]) for q in rr['measurements']];print(rr['hero'],rr['row'],'max corrected X',round(max(changes),2),'worst residual',max(q['residual'] for q in rr['measurements']))
