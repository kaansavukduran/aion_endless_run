"""Register original new PNGs using alpha gutters; never rewrite source pixels.

Counts in the manifest are actual nonempty crops, not generated clones.
Run locally with Pillow/numpy/scipy after adding a source to SOURCES.
"""
from pathlib import Path
import json,hashlib
import numpy as np
from PIL import Image
from scipy.ndimage import label,find_objects
from register_pixel_heroes import cuts
from campaign_registration import match_patch

ROOT=Path(__file__).resolve().parents[1]
SOURCES={
 'rescue-heroes':('campaign-rescue-heroes',6,6,90,'exec-19c5ee09-9b2d-4d34-97cd-ed1f613d5f64'),
 'rescue-npcs':('campaign-rescue-npcs',8,8,76,'exec-bbe09662-0766-43eb-8263-bc58c44561d3'),
 'water-enemies':('campaign-water-enemies',12,6,64,'exec-b3e1a87f-9fd5-42bf-ba84-50ecae93b62a'),
 'garden-enemies':('campaign-garden-enemies',12,6,70,'exec-a468c208-150c-44e2-b762-16b537a3f097'),
 'heavy-machines':('campaign-heavy-machines',16,5,100,'exec-1d8213dc-8549-4010-a7ea-accb0cc92e5e'),
 'mini-bosses':('campaign-mini-bosses',12,6,125,'exec-62d0de69-73e1-4cba-a34c-3820d8f8ac2a'),
 'vehicles':('campaign-vehicles',12,6,62,'exec-21dcbf36-fc53-48bb-81d4-a37a5c7c1b90'),
 'root-engine':('campaign-root-engine',12,6,180,'exec-5300ea0e-000b-4909-982d-54d8d3f8404c'),
 'environment':('campaign-environment',12,4,82,'exec-d6b5c50b-da8f-43a3-b0b2-b247eea681e7'),
 'root-enemies':('campaign-root-enemies',12,6,70,'exec-7eb26c22-16cf-4175-b73c-ba0ed6e9aa93'),
}
HEROES=['aion','owl','sheep','wolf','rabbit','eren']
pixel=json.loads((ROOT/'assets/PIXEL-HEROES-PROVENANCE.json').read_text())
atlases={};drawing_hashes=set();excluded=[]
for key,(filename,nrows,ncols,target,generation) in SOURCES.items():
 path=ROOT/'assets'/f'{filename}.png'
 if not path.exists():continue
 a=np.asarray(Image.open(path).convert('RGBA'));global_labels,_=label(a[:,:,3]>=192,np.ones((3,3)));global_objects=find_objects(global_labels);ys=cuts((a[:,:,3]>=192).sum(1),nrows)
 rows=[];scales=[];templates={}
 for row in range(nrows):
  strip=a[ys[row]:ys[row+1]];xs=cuts((strip[:,:,3]>=192).sum(0),ncols);line=[]
  for col in range(ncols):
   q=strip[:,xs[col]:xs[col+1]];labs,n=label(q[:,:,3]>=192,np.ones((3,3)))
   sizes=np.bincount(labs.ravel());sizes[0]=0;assert sizes.max()>40,(key,row,col,'empty cell')
   body=labs==sizes.argmax();by,bx=np.where(body);rect_x,rect_y=xs[col],ys[row];rect_end_x,rect_end_y=xs[col+1],ys[row+1]
   gid=int(global_labels[rect_y+by[0],rect_x+bx[0]]);gy,gx=global_objects[gid-1]
   rect_x=min(rect_x,gx.start);rect_y=min(rect_y,gy.start);rect_end_x=max(rect_end_x,gx.stop);rect_end_y=max(rect_end_y,gy.stop)
   if rect_end_x-rect_x>=q.shape[1]*1.65 or rect_end_y-rect_y>=q.shape[0]*1.8:
    excluded.append({'atlas':key,'row':row,'column':col,'reason':'Connected silhouette crosses into another source drawing; not usable, not counted.'});continue
   q=a[rect_y:rect_end_y,rect_x:rect_end_x];labs,n=label(q[:,:,3]>=192,np.ones((3,3)));sizes=np.bincount(labs.ravel());sizes[0]=0
   body=global_labels[rect_y:rect_end_y,rect_x:rect_end_x]==gid;by,bx=np.where(body);bb=[int(bx.min()),int(by.min()),int(bx.max()+1),int(by.max()+1)]
   keep=body.copy()
   for k in range(1,n+1):
    if sizes[k]<max(5,sizes.max()*.003):continue
    yy,xx=np.where(labs==k)
    if key=='rescue-heroes' and HEROES[row]=='sheep' and yy.max()<bb[1]+15:keep|=labs==k
    elif key not in ['rescue-heroes','rescue-npcs']:keep|=labs==k
   yy,xx=np.where(keep);bounds=[int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)]
   group=row if key.startswith('rescue') or key=='environment' else (0 if key=='root-engine' else row//4)
   if col==0 and (key.startswith('rescue') or key=='environment' or (row%4==0 and (key!='root-engine' or row==0))):
    if key=='rescue-heroes':
     old=pixel['atlases']['pixel-'+HEROES[row]];f=old['frames'][3][0];target=(f['body_bounds'][3]-f['body_bounds'][1])*old['scale'][3]
    factor=target/(bb[3]-bb[1])
    if key=='rescue-npcs':factor=76/(bb[3]-bb[1])* .89 # seated poses stay seated, do not stretch later rows
    templates[group]={'scale':factor,'origin':(bb[0]+bb[2])*.5}
   factor=templates[group]['scale'];origin_x=(bb[0]+bb[2])*.5
   if key=='rescue-heroes':
    cleaned=q.copy();cleaned[~keep]=0
    if col==0:
     tx=round(bb[0]+(bb[2]-bb[0])*.57);ty=round(bb[1]+(bb[3]-bb[1])*.20)
     patch=cleaned[ty:ty+max(15,round((bb[3]-bb[1])*.18)),tx:tx+max(15,round((bb[2]-bb[0])*.23))].copy()
     reference=(tx,ty);templates[group].update(patch=patch,reference=reference)
    t=templates[group];fx,fy,error=match_patch(cleaned,t['patch'],t['reference'],[35,30]);origin_x=t['origin']+fx-t['reference'][0]
   origin_y=bb[3]
   flight=(key=='water-enemies' and group==2) or (key=='garden-enemies' and group==0) or (key=='heavy-machines' and group==1)
   if flight and row%4!=3:
    t=templates[group]
    if 'core_patch' not in t:
     tx=round(bb[0]+(bb[2]-bb[0])*.42);ty=round(bb[1]+(bb[3]-bb[1])*.43);t['core_ref']=(tx,ty);t['core_patch']=q[ty:ty+20,tx:tx+24].copy();t['core_origin']=[origin_x,(bb[1]+bb[3])*.5+35./factor]
    fx,fy,error=match_patch(q,t['core_patch'],t['core_ref'],[35,32]);origin_x=t['core_origin'][0]+fx-t['core_ref'][0];origin_y=t['core_origin'][1]+fy-t['core_ref'][1]
   if key=='vehicles':origin_y=bb[3] if row%4==3 else bb[1]+(bb[3]-bb[1])*.35
   runs=[]
   for y in range(bounds[1],bounds[3]):
    z=np.diff(np.pad(keep[y].astype(np.int8),(1,1)))
    runs.extend([[y,int(s),int(e-s)] for s,e in zip(np.where(z==1)[0],np.where(z==-1)[0])])
   isolated=q.copy();isolated[~keep]=0;drawing_hashes.add(hashlib.sha256(isolated.tobytes()).hexdigest())
   line.append({'source_column':col,'rect':[rect_x,rect_y,rect_end_x-rect_x,rect_end_y-rect_y],'bounds':bounds,'body_bounds':bb,'origin':[origin_x,origin_y],'registered_full_body':True,'source_edge':bool(gx.start==0 or gy.start==0 or gx.stop==a.shape[1] or gy.stop==a.shape[0]),'runs':runs})
  rows.append(line);scales.append(templates[group]['scale'])
 atlases[key]={'path':'assets/'+filename+'.png','sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'dimensions':[a.shape[1],a.shape[0]],'rows':nrows,'columns':ncols,'frames':rows,'scales':scales,'generation':generation}
data={'version':1,'method':'Original PNG bytes retained. Actual alpha gutters, independent sampling gutters, connected bodies, fixed per-character scale, actual foot floor, upper face registration for six knife cycles. No physics offsets or copied extra frames.','license':'New owner-authorized AI-assisted original artwork; no SNK art. Designs are game drafts, not canon approval.','atlases':atlases,'excluded':excluded,'drawings':sum(sum(len(row) for row in v['frames']) for v in atlases.values()),'distinct_crop_hashes':len(drawing_hashes),'animation_groups':sum(v['rows'] for v in atlases.values())}
(ROOT/'assets/CAMPAIGN-EXPANSION-PROVENANCE.json').write_text(json.dumps(data,separators=(',',':'))+'\n')
print('Registered',data['drawings'],'drawings;',data['distinct_crop_hashes'],'distinct crops; PNG bytes unchanged.')
