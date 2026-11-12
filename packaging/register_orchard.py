"""Read original PNGs and write registration only; never edits artwork."""
from pathlib import Path
import hashlib,json
import numpy as np
from PIL import Image
from scipy.ndimage import label
ROOT=Path(__file__).resolve().parents[1]
def register(path,cols,rows,scales,hero=False):
 a=np.array(Image.open(ROOT/path).convert('RGBA'));h,w=a.shape[:2];frames=[]
 for row in range(rows):
  poses=[]
  for col in range(cols):
   x0,x1=round(col*w/cols),round((col+1)*w/cols);y0,y1=round(row*h/rows),round((row+1)*h/rows)
   q=a[y0:y1,x0:x1];mask=q[:,:,3]>=64
   if hero:
    labels,n=label(mask);sizes=np.bincount(labels.ravel());sizes[0]=0;mask=labels==sizes.argmax()
   ys,xs=np.where(mask);assert len(xs)>30,(path,row,col)
   b=[int(xs.min()),int(ys.min()),int(xs.max()+1),int(ys.max()+1)];eye=None
   if hero:
    f=q.astype(float);green=mask&(f[:,:,1]>f[:,:,0]*1.10)&(f[:,:,1]>f[:,:,2]*1.15)&(f[:,:,1]>45)&(f[:,:,0]>20)
    lab,n=label(green);sizes=np.bincount(lab.ravel());sizes[0]=0
    if n and sizes.max()>=3:
     gy,gx=np.where(lab==sizes.argmax());eye=[round(float(gx.mean()),4),round(float(gy.mean()),4)]
   runs=[]
   for y in range(mask.shape[0]):
    groups=np.split(np.flatnonzero(mask[y]),np.where(np.diff(np.flatnonzero(mask[y]))>1)[0]+1)
    for group in groups:
     if len(group):runs.append([y,int(group[0]),len(group)])
   poses.append({'rect':[x0,y0,x1-x0,y1-y0],'bounds':b,'runs':runs,'eye':eye,'source_column':col})
  if hero:
   valid=[i for i,f in enumerate(poses) if f['eye'] is not None]
   for col,f in enumerate(poses):
    if f['eye'] is None and valid:
     before=max([i for i in valid if i<col],default=valid[0]);after=min([i for i in valid if i>col],default=valid[-1]);t=0 if before==after else (col-before)/(after-before);f['eye']=[round(float(poses[before]['eye'][n])*(1-t)+float(poses[after]['eye'][n])*t,4) for n in [0,1]]
    b=f['bounds'];roll=path.endswith('movement.png') and row==5
    # Low ash and late face-first fall have no trustworthy upright iris.
    floor_only=(path.endswith('encounters.png') and (row==5 or row==4 and col>=7 or row==2 and col>=6))
    f['origin']=[round((b[0]+b[2])/2,4) if roll or floor_only or f['eye'] is None else round(f['eye'][0]-18/scales[row],4),b[3]]
    f['registration']='roll-center' if roll else ('floor' if floor_only else 'near-eye-and-floor')
  else:
   for f in poses:
    b=f['bounds'];f['origin']=[(b[0]+b[2])/2,(b[1]+b[3])/2];f['registration']='center'
  frames.append(poses)
 return {'path':path,'columns':cols,'rows':rows,'width':w,'height':h,'sha256':hashlib.sha256((ROOT/path).read_bytes()).hexdigest(),'scale':scales,'anchor_x':[w/cols/2]*rows,'head_spans':[76]*rows if hero else [0]*rows,'frames':frames}
hero={k:register('assets/'+k+'.png',12,6,[.70]*6,True) for k in ['emre-movement','emre-encounters']}
# Measure the pistol tip on the first firing frame, in the same registered space.
f=hero['emre-encounters']['frames'][1][0];muzzle=[round((f['bounds'][2]-f['origin'][0])*.70,3),round((f['eye'][1]+22-f['origin'][1])*.70,3)]
p={'source_reference':{'url':'https://drive.google.com/file/d/1_gDPSpL7sQDdO791wWfx4zzZWQksbZPk/view','name':'Tavsan_Emre_Modelleme_Paftasi.png','identity':'Tan rabbit, green eyes, light blue shirt, red tie, charcoal trousers, cream tail.'},'source_generations':['exec-8f5a10d5-1aaa-4dba-93d8-cc1c74a3053f','exec-04be09f5-022d-4493-aebe-78e06ccde092'],'method':'Original PNGs retained byte-for-byte. Read-only opacity components, independent padded textures, one shared 0.70 scale for every Emre pose. Near green iris horizontally registered; floor shared. Blink landmarks interpolate. Rolls and low fallen/ash poses register body/floor, not an invented upright eye.','muzzle':muzzle,'atlases':hero}
(ROOT/'assets/EMRE-PROVENANCE.json').write_text(json.dumps(p,separators=(',',':'))+'\n')
fruits=register('assets/orchard-fruits.png',4,2,[1,1]);fruits['names']=['banana','apple','pear','apricot','grapes','orange','cherries','peach'];fruits['generation']='exec-a06237eb-e0ad-4968-8d35-b6d58707dac9'
for row in fruits['frames']:
 for f in row:
  b=f['bounds'];f['display_scale']=30/max(b[2]-b[0],b[3]-b[1])
(ROOT/'assets/ORCHARD-PROVENANCE.json').write_text(json.dumps({'atlas':fruits,'method':'Original unchanged PNG, alpha spans isolate eight common fruits. Each silhouette fits a30-unit collectible. Fragaria stays a separate rare cosmetic item.'},separators=(',',':'))+'\n')
path=ROOT/'assets/aionverse-landscapes.png';w,h=Image.open(path).size
(ROOT/'assets/LANDSCAPE-PROVENANCE.json').write_text(json.dumps({'path':'assets/aionverse-landscapes.png','sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'generation':'exec-12b30175-5cbd-4611-bc7c-6f22b631a3f4','columns':2,'rows':3,'panels':[[int(i%2*w/2)+1,int(i//2*h/3)+1,int(w/2)-2,int(h/3)-2] for i in range(6)],'biomes':['desert','snow','swamp','city','forest','volcano'],'method':'Original PNG unchanged. Runtime panel isolation excludes the one-pixel grid seam. Uniform-scale, mirrored repeat joins; crossfade and day/night tint preserve travel continuity.'},indent=2)+'\n')
print('Registered144 Emre poses,8 fruits,6 landscapes. Muzzle:',muzzle)
