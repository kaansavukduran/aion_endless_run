"""Read-only registration of the original wolf/owl mobility PNGs.

Use the large near eye (not the golden beak/feathers or far eye). Explicit
per-row eye search windows are reviewed against the actual artwork. Neither
silhouette bounds nor attack effects are used to recenter the character.
"""
from pathlib import Path
import hashlib,json,shutil,statistics
import numpy as np
from PIL import Image
from scipy.ndimage import label,find_objects,gaussian_filter1d
from scipy.signal import find_peaks
ROOT=Path(__file__).resolve().parents[1]
SOURCES={'wolf':'21a5f39b-a96c-4c07-acc1-78709cd7566e','owl':'3b11f278-8b20-4bab-b358-4788b5b8dec0'}
base=json.loads((ROOT/'assets/CANONICAL-PROVENANCE.json').read_text())
def cuts(a,n,axis):
 v=(a[:,:,3]>=160).sum(axis=1 if axis=='y' else 0).astype(float);step=len(v)/n;s=gaussian_filter1d(v,step*.13)
 peaks,_=find_peaks(s,distance=step*.65,prominence=s.max()*.07,height=s.max()*.15)
 if len(peaks)!=n:peaks=np.array([round((i+.5)*step) for i in range(n)])
 v=gaussian_filter1d(v,step*.035);out=[0]
 for l,r in zip(peaks,peaks[1:]):
  lo=round(l+(r-l)*.27);hi=round(r-(r-l)*.27);z=np.where(v[lo:hi+1]<=v[lo:hi+1].min()+1e-6)[0]+lo
  out.append(int(min(z,key=lambda x:abs(x-(l+r)/2))))
 return out+[len(v)]
atlases={}
for hero,src in SOURCES.items():
 path=ROOT/'assets'/('agility-'+hero+'.png');source=Path('/workspace/generated_images/exec-'+src+'.png')
 if source.exists():shutil.copy2(source,path)
 a=np.array(Image.open(path).convert('RGBA'));h,w=a.shape[:2];ys=cuts(a,4,'y');rows=[]
 for row in range(4):
  strip=a[ys[row]:ys[row+1]];xs=cuts(strip,8,'x');frames=[]
  for col in range(8):
   c=strip[:,xs[col]:xs[col+1]];mask=c[:,:,3]>=128;labs,n=label(mask,np.ones((3,3)));sizes=np.bincount(labs.ravel());sizes[0]=0;body=labs==sizes.argmax();yy,xx=np.where(body);bb=[int(xx.min()),int(yy.min()),int(xx.max())+1,int(yy.max())+1]
   r,g,b=[c[:,:,i].astype(float) for i in range(3)]
   if hero=='owl':
    iris=mask&(r>110)&(g>55)&(g<220)&(g<r*.95)&(b<g*.65);expected_x=(140 if row in [0,3] else 118);expected_y=(105 if row in [0,3] else 96)
   else:
    iris=mask&(g>65)&(g<210)&(r<90)&(b>r*1.5);expected_x=169;expected_y=111
   ex=expected_x+col*w/8-xs[col];ey=expected_y+row*h/4-ys[row]
   eye_labs,n=label(iris,np.ones((3,3)));options=[]
   for j,sl in enumerate(find_objects(eye_labs),1):
    if sl is None:continue
    yy,xx=np.where(eye_labs==j);area=len(xx);cx=float(xx.mean());cy=float(yy.mean())
    if not (20 if hero=='owl' else 25)<=area<=(180 if hero=='owl' else 220):continue
    distance=(cx-ex)**2+(cy-ey)**2
    if distance<35**2:options.append((distance,cx,cy,area))
   if options:
    score,eye_x,eye_y,area=(min(options) if hero=='owl' else max(options,key=lambda q:q[3]));eye=[eye_x,eye_y]
   else:eye=None;area=0
   keep=body.copy()
   # Front-only contact effects; never retain a detached tail-side fragment.
   if row in [1,2,3]:
    for j,sl in enumerate(find_objects(labs),1):
     if sl and sizes[j]>=8 and sl[1].start>bb[0]+(bb[2]-bb[0])*.65:keep|=labs==j
   yy,xx=np.where(keep);bounds=[int(xx.min()),int(yy.min()),int(xx.max())+1,int(yy.max())+1];runs=[]
   for y in range(bounds[1],bounds[3]):
    z=np.diff(np.pad(keep[y].astype(np.int8),(1,1)));runs.extend([[y,int(x),int(e-x)] for x,e in zip(np.where(z==1)[0],np.where(z==-1)[0])])
   frames.append({'rect':[xs[col],ys[row],xs[col+1]-xs[col],ys[row+1]-ys[row]],'bounds':bounds,'body_bounds':bb,'eye':eye,'eye_area':area,'source_column':col,'runs':runs})
  valid=[i for i,f in enumerate(frames) if f['eye'] is not None]
  assert len(valid)>=6,(hero,row,'ambiguous iris row')
  for i,f in enumerate(frames):
   f['blink']=f['eye'] is None
   if f['eye'] is None:
    # Interpolate coordinates in source lattice space across the blink.
    f['eye']=[float(np.interp(i,valid,[frames[j]['eye'][axis]+(frames[j]['rect'][axis]-f['rect'][axis]) for j in valid])) for axis in [0,1]]
  rows.append(frames)
 old=base['atlases']['canonical-'+hero];old_eye_top=statistics.median(f['eye'][1]-f['body_bounds'][1] for f in old['frames'][0]);new_eye_top=statistics.median(f['eye'][1]-f['body_bounds'][1] for f in rows[1]);factor=old['scale'][0]*old_eye_top/new_eye_top
 # One scale for the entire hero sheet; flying posture has feet tucked.
 target=old['target_eye'];targets=[]
 for row,line in enumerate(rows):
  floor_eye=-statistics.median((f['body_bounds'][3]-f['eye'][1])*factor for f in line)
  row_target=[target[0],target[1] if (hero=='owl' and row in [0,3]) else floor_eye]
  targets.append(row_target)
  for f in line:f['origin']=[f['eye'][0]-row_target[0]/factor,f['eye'][1]-row_target[1]/factor];f['anchor_x']=f['origin'][0]
 atlases['agility-'+hero]={'path':str(path.relative_to(ROOT)),'width':w,'height':h,'columns':8,'rows':4,'frames':rows,'scale':[factor]*4,'head_spans':[old['head_spans'][0]*old['scale'][0]/factor]*4,'anchor_x':[w/16]*4,'target_eyes':targets,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'generation_source':'exec-'+src+'.png','references':old['references']}
 print(hero,'scale',factor,'targets',targets)
 print('iris',[[[round(f['eye'][0],1),round(f['eye'][1],1)] for f in line] for line in rows])
def ref(hero,row):return {'atlas':'agility-'+hero,'row':row}
aliases={'runner-wolf':[None]*6+[ref('wolf',0),None],'runner-owl':[None]*6+[ref('owl',0),None],'actions':[ref('wolf',0),ref('owl',0),None],'strikes':[None,None,ref('owl',1),ref('owl',2),None,None,ref('wolf',1),ref('wolf',2)],'owl-peck':[ref('owl',3)],'wolf-dash-bite':[ref('wolf',3)]}
meta={'version':'0.12.0','new_drawn_frames':64,'method':'Original PNGs unchanged; near-iris landmarks reviewed per animation. One scale per hero. Static gaze during glide/wing attacks, authored continuous forward combat lunge is separate. Four-legged sprint and distinct sprint bite. Aion/sheep canonical artwork untouched.','atlases':atlases,'aliases':aliases}
(ROOT/'assets/AGILITY-PROVENANCE.json').write_text(json.dumps(meta,separators=(',',':'))+'\n')
