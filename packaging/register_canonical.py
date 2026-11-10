"""Register original drawn poses against anatomical landmarks, without editing PNGs.

Actual per-row counts are observed, never padded to the requested grid. Eye
landmarks stabilize normal poses; authored lunges are separate, smooth motion.
Compact roll poses are ordered by clockwise head orbit around a fixed center.
"""
from pathlib import Path
import json,hashlib,shutil,math,statistics
import numpy as np
from PIL import Image
from scipy.ndimage import label,find_objects,gaussian_filter1d
from scipy.signal import find_peaks
ROOT=Path(__file__).resolve().parents[1]
SPECS={
 'aion':('8601a90c-648b-4e8f-b9c1-10d732a5de6d',[7]*5+[8]+[7]*8),
 'owl':('b1f89257-b8f0-4ff6-93e3-3c6873edf448',[7]*5+[8]*9),
 'sheep':('b14f391e-055b-48c9-8c79-5d6c9d297736',[7]*5+[8]+[7]*8),
 'wolf':('20e29ffb-6f2a-4ec8-91b9-b99778e69e72',[8]*14)}
REFS={
 'aion':['https://drive.google.com/file/d/1rX8gLJ2jRAaIk13Y3AHA9RY2tOf_gFD3/view','assets/aion-runner.png'],
 'wolf':['https://drive.google.com/file/d/1tYPnCJqxIA7zXp8VoeLQmsMg3GFshwaE/view','assets/wolf-runner.png'],
 'sheep':['https://drive.google.com/file/d/1ZvXHIQiPgwnEA6NshwWRaENxD0Ow5lJ-/view','assets/sheep-runner.png'],
 'owl':['https://drive.google.com/file/d/14VT75IFn5JwtqEiAgjg-3IKsF_hpSP9f/view','assets/owl-runner.png']}
def boundaries(a,n,axis):
 v=(a[:,:,3]>=160).sum(axis=1 if axis=='y' else 0).astype(float);step=len(v)/n
 smooth=gaussian_filter1d(v,step*.13)
 peaks,_=find_peaks(smooth,distance=step*.65,prominence=smooth.max()*.07,height=smooth.max()*.15)
 if len(peaks)!=n:
  # Narrow effects may reduce a peak; use the constrained nominal lattice for X only.
  assert axis=='x',(axis,n,peaks.tolist())
  peaks=np.array([round((i+.5)*step) for i in range(n)])
 trough=gaussian_filter1d(v,step*.045);out=[0]
 for left,right in zip(peaks,peaks[1:]):
  lo=round(left+(right-left)*.25);hi=round(right-(right-left)*.25);minimum=trough[lo:hi+1].min();matches=np.where(trough[lo:hi+1]<=minimum+1e-6)[0]+lo
  mid=(left+right)/2;out.append(int(min(matches,key=lambda x:abs(x-mid))))
 return out+[len(v)]
def eye_point(cell,hero,body,expected=None,roll=False):
 r,g,b=[cell[:,:,i].astype(float) for i in range(3)];visible=cell[:,:,3]>=160
 if hero=='aion':m=visible&(b>65)&(b-g>22)&(g>30)&(g<155)&(r<100)&(b>r*1.4)
 elif hero=='wolf':m=visible&(b>65)&(g>65)&(g<190)&(r<75)&(b>r*1.5)
 else:m=visible&(r>110)&(g>45)&(g<180)&(g<r*.78)&(b<g*.62)
 labs,n=label(m,np.ones((3,3)));options=[];x0,y0,x1,y1=body;bw=x1-x0;bh=y1-y0
 ex,ey=expected or (x0+bw*.70,y0+bh*.31)
 for i,sl in enumerate(find_objects(labs),1):
  if sl is None:continue
  yy,xx=np.where(labs==i);area=len(xx)
  if area<3 or area>(65 if hero=="aion" else max(90,bw*bh*.05)) or xx.max()-xx.min()>bw*.28 or yy.max()-yy.min()>bh*.30:continue
  cx=float(xx.mean());cy=float(yy.mean())
  if hero=="sheep" and not roll and cy<y0+bh*.32:continue
  score=((cx-ex)/max(1,bw))**2+((cy-ey)/max(1,bh))**2
  options.append((score,cx,cy))
 if not options:return None
 best=min(options)
 return [best[1],best[2]] if best[0]<(0.6 if roll else .13) else None
atlases={};muzzles={};reports={}
for hero,(src,counts) in SPECS.items():
 path=ROOT/'assets'/('canonical-'+hero+'.png');source=Path('/workspace/generated_images/exec-'+src+'.png')
 if source.exists():shutil.copy2(source,path)
 a=np.array(Image.open(path).convert('RGBA'));h,w=a.shape[:2];ys=boundaries(a,14,'y');rows=[];eyes=[];body_bounds=[]
 for row,cols in enumerate(counts):
  strip=a[ys[row]:ys[row+1]];xs=boundaries(strip,cols,'x');line=[];roweyes=[];rowbody=[]
  for col in range(cols):
   cell=strip[:,xs[col]:xs[col+1]];mask=cell[:,:,3]>=96;labs,n=label(mask,np.ones((3,3)));sizes=np.bincount(labs.ravel());sizes[0]=0;body=labs==sizes.argmax()
   if hero=='sheep':
    yy,xx=np.where(body);top=int(yy.min());bottom=int(yy.max());gold=(cell[:,:,0]>160)&(cell[:,:,1]>110)&(cell[:,:,2]<95);gold[round(top+(bottom-top)*.30):]=False;body=body&~gold
   yy,xx=np.where(body);bb=[int(xx.min()),int(yy.min()),int(xx.max())+1,int(yy.max())+1]
   # Keep the original detached halo; preserve damage/spark effects in their own cells.
   if hero=='sheep' or row>=11:keep=mask
   else:
    keep=body.copy()
    # Melee/pistol glints may be detached in FRONT, never copy rear fragments.
    if row in [3,4,8]:
     for i,sl in enumerate(find_objects(labs),1):
      if sl and sizes[i]>=3 and sl[1].start>=bb[0]+(bb[2]-bb[0])*.6:keep|=labs==i
   yy,xx=np.where(keep);b=[int(xx.min()),int(yy.min()),int(xx.max())+1,int(yy.max())+1];runs=[]
   for y in range(b[1],b[3]):
    z=np.diff(np.pad(keep[y].astype(np.int8),(1,1)));runs.extend([[y,int(x),int(e-x)] for x,e in zip(np.where(z==1)[0],np.where(z==-1)[0])])
   expected=None
   if hero=='sheep' and row==4 and 1<=col<=4:expected=(bb[0]+(bb[2]-bb[0])*.30,bb[1]+(bb[3]-bb[1])*.3)
   if row==5:expected=((bb[0]+bb[2])/2,(bb[1]+bb[3])/2)
   eye=eye_point(cell,hero,bb,expected,row==5)
   line.append({'rect':[xs[col],ys[row],xs[col+1]-xs[col],ys[row+1]-ys[row]],'bounds':b,'body_bounds':bb,'runs':runs,'eye':eye,'source_column':col})
   roweyes.append(eye);rowbody.append(bb)
  # Missing blink irises interpolate neighboring anatomical registrations.
  valid=[i for i,e in enumerate(roweyes) if e is not None]
  if valid:
   for i in range(cols):
    if roweyes[i] is None:roweyes[i]=[float(np.interp(i,valid,[roweyes[j][axis] for j in valid])) for axis in [0,1]]
  rows.append(line);eyes.append(roweyes);body_bounds.append(rowbody)
 basebody=body_bounds[0];factor=82/statistics.median(b[3]-b[1] for b in basebody)
 initial=[e for e in eyes[0] if e is not None];target_eye=[14.,-statistics.median((basebody[i][3]-eyes[0][i][1])*factor for i in range(len(basebody)) if eyes[0][i] is not None)]
 scales=[factor]*14;roll=rows[5];rollfactor=64/max(max(f['body_bounds'][2]-f['body_bounds'][0],f['body_bounds'][3]-f['body_bounds'][1]) for f in roll[1:-1]);scales[5]=rollfactor
 for row,line in enumerate(rows):
  for col,f in enumerate(line):
   b=f['bounds'];bb=f['body_bounds'];eye=eyes[row][col];f['eye']=eye
   if row==5:
    cx=(bb[0]+bb[2])/2;cy=(bb[1]+bb[3])/2
    # Capture the full head orbit, using the actual iris when available.
    if eye is None:angle=col/len(line)*math.tau
    else:angle=math.atan2(eye[1]-cy,eye[0]-cx)
    f['roll_angle']=(angle+math.pi/4)%math.tau
    f['origin']=[cx,cy+32/rollfactor]
   elif eye is not None and row not in [9,10,12,13] or (hero=='owl' and row==13 and eye is not None):
    f['origin']=[eye[0]-target_eye[0]/factor,eye[1]-target_eye[1]/factor]
   else:
    # Physical falls/elements settle against the shared row floor, not frame bounds.
    f['origin']=[w/len(line)*(col+.5)-f['rect'][0],statistics.median(q['body_bounds'][3] for q in line)]
   f['anchor_x']=f['origin'][0]
 # Exclude standing prep/recovery from the continuous wheel loop; sort clockwise.
 compact=roll[1:-1];compact.sort(key=lambda f:f['roll_angle']);rows[5]=compact
 # Match a complete untucked row as the neutral boss gun pose, preserving identity.
 values=[]
 for f in rows[7]:
  x,y,cw,ch=f['rect'];cell=a[y:y+ch,x:x+cw];r,g,b=[cell[:,:,i] for i in range(3)];m=(cell[:,:,3]>160)&(g>100)&(b>110)&(r<140);m[:,:round(cw*.65)]=False;yy,xx=np.where(m)
  if len(xx):
   right=xx.max();my=float(np.median(yy[xx>=right-3]));values.append([(right-f['origin'][0])*factor,(my-f['origin'][1])*factor])
 muzzles[hero]=[round(statistics.median(v[i] for v in values),2) for i in [0,1]] if values else [48,-38]
 atlases['canonical-'+hero]={'path':str(path.relative_to(ROOT)),'generation_source':'exec-'+src+'.png','sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'width':w,'height':h,'rows':14,'columns':max(counts),'row_counts':[len(x) for x in rows],'drawn_source_counts':counts,'roll_source_frames':roll,'frames':rows,'scale':scales,'anchor_x':[w/counts[0]/2]*14,'head_spans':[(70 if hero=='aion' else 65)/v for v in scales],'target_eye':target_eye,'references':REFS[hero]}
 reports[hero]={'source_counts':counts,'play_counts':[len(x) for x in rows],'scale':factor,'eye_world':target_eye,'roll_source_order':[f['source_column'] for f in compact],'roll_angles':[round(f['roll_angle']*180/math.pi,1) for f in compact]}
 print(hero,reports[hero],muzzles[hero])
# Dedicated, visually reviewed compact clockwise wheel cycle. Source order is
# right, lower-right, down, lower-left, left, upper-left, up, upper-right.
roll_src='c5eec5eb-0cbe-42d9-ae90-c5566be74057'
roll_path=ROOT/'assets/canonical-rolls.png'
source=Path('/workspace/generated_images/exec-'+roll_src+'.png')
if source.exists():shutil.copy2(source,roll_path)
a=np.array(Image.open(roll_path).convert('RGBA'));h,w=a.shape[:2]
ys=boundaries(a,4,'y');roll_rows=[];roll_scales=[]
for row in range(4):
 strip=a[ys[row]:ys[row+1]];xs=boundaries(strip,8,'x');line=[]
 for col in range(8):
  cell=strip[:,xs[col]:xs[col+1]];mask=cell[:,:,3]>=96
  labs,n=label(mask,np.ones((3,3)));sizes=np.bincount(labs.ravel());sizes[0]=0
  keep=labs==sizes.argmax()
  # Sheep halo is part of the tucked silhouette, including detached gold.
  if row==2:
   for j,sl in enumerate(find_objects(labs),1):
    if sl and sizes[j]>=20:keep|=labs==j
  yy,xx=np.where(keep);b=[int(xx.min()),int(yy.min()),int(xx.max())+1,int(yy.max())+1]
  runs=[]
  for y in range(b[1],b[3]):
   z=np.diff(np.pad(keep[y].astype(np.int8),(1,1)))
   runs.extend([[y,int(x),int(e-x)] for x,e in zip(np.where(z==1)[0],np.where(z==-1)[0])])
  line.append({'rect':[xs[col],ys[row],xs[col+1]-xs[col],ys[row+1]-ys[row]],'bounds':b,'runs':runs,'eye':None,'source_column':col,'clockwise_degrees':col*45})
 factor=64/max(max(f['bounds'][2]-f['bounds'][0],f['bounds'][3]-f['bounds'][1]) for f in line)
 for f in line:
  b=f['bounds'];f['origin']=[(b[0]+b[2])/2,(b[1]+b[3])/2+32/factor];f['anchor_x']=f['origin'][0]
 roll_scales.append(factor);roll_rows.append(line)
atlases['canonical-rolls']={'path':'assets/canonical-rolls.png','generation_source':'exec-'+roll_src+'.png','sha256':hashlib.sha256(roll_path.read_bytes()).hexdigest(),'width':w,'height':h,'rows':4,'columns':8,'frames':roll_rows,'scale':roll_scales,'anchor_x':[w/16]*4,'head_spans':[65/f for f in roll_scales],'direction':'clockwise when travelling right','visually_reviewed_order':[0,45,90,135,180,225,270,315]}

legacy=json.loads((ROOT/'assets/FRONTIER-PROVENANCE.json').read_text())['atlases']['runner-owl'];atlases['legacy-owl']=legacy
aliases={}
def alias(name,pairs):aliases[name]=[{'atlas':'canonical-'+key if key!='legacy-owl' else key,'row':row} for key,row in pairs]
order=['aion','owl','sheep','wolf']
for hero in order:alias('runner-'+hero,[(hero,0),(hero,1),(hero,2),(hero,11),(hero,12),('legacy-owl' if hero=='owl' else hero,5 if hero=='owl' else 13),(hero,1 if hero=='wolf' else 6),(hero,2)])
alias('actions',[('wolf',1),('owl',6),('sheep',2)])
alias('strikes',[(hero,row) for hero in order for row in [3,4]])
aliases['rolls']=[{'atlas':'canonical-rolls','row':i} for i in range(4)];alias('heroes',[(hero,7) for hero in order]);alias('gun-run',[(hero,7) for hero in order]);alias('gun-fire',[(hero,8) for hero in order]);alias('deaths',[(hero,row) for hero in order for row in [9,10]]);alias('owl-peck',[('owl',13)])
meta={'version':'0.11.0','method':'Original PNGs unchanged. Actual per-row counts, no padded duplicates. Anatomical eye landmark origins stabilize upright head placement without scaling individual poses. Shared scale per character; compact roll center is fixed, actual head orbit sorted clockwise. User prefers faithful fewer good poses over count quotas.','new_drawn_frames':32+sum(sum(c) for _,c in SPECS.values()),'atlases':atlases,'aliases':aliases,'muzzles':muzzles,'review':reports}
(ROOT/'assets/CANONICAL-PROVENANCE.json').write_text(json.dumps(meta,separators=(',',':'))+'\n')
