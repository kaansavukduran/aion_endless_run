"""Read original sprite alpha to register isolated runtime frames; never edit PNGs."""
from pathlib import Path
import hashlib,json
import numpy as np
from PIL import Image
from scipy.ndimage import label,find_objects
ROOT=Path(__file__).resolve().parents[1]
full=json.loads((ROOT/'assets/FULL-RUNNER-PROVENANCE.json').read_text());evo=json.loads((ROOT/'assets/EVOLUTION-PROVENANCE.json').read_text())['atlases']
# Reference face/ear spans in source pixels. A common anatomical span replaces
# whole-pose height scaling, which enlarged heads when bodies leaned horizontally.
heads={'aion':70,'wolf':65,'owl':65,'sheep':65}
specs={}
for hero in ['aion','owl','sheep','wolf']:
 specs['runner-'+hero]={'path':f'assets/{hero}-runner.png','rows':8,'columns':6,'y': [round(i*1254/8) for i in range(9)] if hero=='aion' else full['characters'][hero]['row_y'],'head_spans':[120]*8 if hero=='aion' else ([118,118,118,118,118,118,110,118] if hero=='wolf' else ([110]*8 if hero=='owl' else [116]*8)),'targets':[heads[hero]]*8}
specs['actions']={'path':'assets/companion-actions.png','rows':3,'columns':6,'head_spans':[166,180,175],'targets':[65]*3}
specs['strikes']={'path':'assets/evolution-strikes.png','rows':8,'columns':6,'y':evo['strikes']['y'],'head_spans':[115,115,102,102,118,118,122,122],'targets':[70,70,65,65,65,65,65,65]}
specs['rolls']={'path':'assets/evolution-rolls.png','rows':4,'columns':7,'head_spans':[155,130,139,137],'targets':[70,65,65,65]}
specs['heroes']={'path':'assets/frontier-heroes.png','rows':4,'columns':6,'head_spans':[155,137,149,135],'targets':[70,65,65,65]}
specs['boss']={'path':'assets/frontier-boss.png','rows':6,'columns':6,'y':[0,189,370,560,727,879,1024]}
specs['parkour']={'path':'assets/frontier-parkour.png','rows':4,'columns':6}
for key,s in specs.items():
 path=ROOT/s['path'];a=np.array(Image.open(path).convert('RGBA'));h,w=a.shape[:2];s.update(width=w,height=h,sha256=hashlib.sha256(path.read_bytes()).hexdigest());xs=s['x']=[round(i*w/s['columns']) for i in range(s['columns']+1)];ys=s.setdefault('y',[round(i*h/s['rows']) for i in range(s['rows']+1)]);frames=[]
 for row in range(s['rows']):
  fs=[]
  for col in range(s['columns']):
   cell=a[ys[row]:ys[row+1],xs[col]:xs[col+1]];mask=cell[:,:,3]>=32
   # Main connected silhouette for heroes, including recoil arms; discard stray
   # fragments from neighboring cells. Objects keep detached sparks/effects.
   clean=key.startswith('runner-') and row not in [3,4,5] or key in ['strikes','rolls','actions','heroes']
   if clean:
    labs,n=label(mask,np.ones((3,3)));sizes=np.bincount(labs.ravel());sizes[0]=0;mask=labs==sizes.argmax()
   yy,xx=np.where(mask);b=[int(xx.min()),int(yy.min()),int(xx.max())+1,int(yy.max())+1];runs=[]
   for y in range(b[1],b[3]):
    line=mask[y];edges=np.diff(np.pad(line.astype(np.int8),(1,1)));starts=np.where(edges==1)[0];ends=np.where(edges==-1)[0]
    runs.extend([[y,int(x),int(z-x)] for x,z in zip(starts,ends)])
   fs.append({'rect':[xs[col],ys[row],xs[col+1]-xs[col],ys[row+1]-ys[row]],'bounds':b,'runs':runs})
  frames.append(fs)
 s['frames']=frames
 s['scale']=[s['targets'][i]/v for i,v in enumerate(s['head_spans'])] if 'head_spans' in s else []
 s['anchor_x']=[(xs[1]-xs[0])*0.5]*s['rows']
(ROOT/'assets/FRONTIER-PROVENANCE.json').write_text(json.dumps({'method':'Unmodified original PNGs. Read-only alpha-component run registration, copied into independently padded ImageTextures at runtime; no shared atlas UVs. Uniform anatomical head-span calibration per row, never divide by the current pose height.','atlases':specs},separators=(',',':'))+'\n')
print('Registered',sum(v['rows']*v['columns'] for v in specs.values()),'source frames; original PNG hashes retained')
