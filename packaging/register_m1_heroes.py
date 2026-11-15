"""Register owner-requested body layers. Never rewrite generated PNG pixels.

A whole-face template locates the anatomical pivot. One source scale per hero
and atlas is calibrated once; posture, gun direction and effects never resize it.
"""
from pathlib import Path
import json,hashlib
import numpy as np
from PIL import Image
from scipy.ndimage import label
from campaign_registration import match_patch
from register_pixel_heroes import cuts
ROOT=Path(__file__).resolve().parents[1]
BASE=json.loads((ROOT/'assets/PIXEL-HEROES-PROVENANCE.json').read_text())
HEROES=['aion','sheep','rabbit','eren']
ACTIONS=['walk','idle_fire','air_fire','crouch_walk','crouch_fire']
NEUTRAL={'aion':(150,117,174,155),'sheep':(149,103,170,153),'rabbit':(150,101,169,153),'eren':(147,80,173,132)}
CROUCH_NEUTRAL={'rabbit':(188,137,204,189),'eren':(185,146,205,197)}

def grid(path,rows,cols=6):
 a=np.array(Image.open(path).convert('RGBA'));h,w=a.shape[:2];frames=[];ys=cuts((a[:,:,3]>=192).sum(1),rows)
 for row in range(rows):
  line=[];xs=cuts((a[ys[row]:ys[row+1],:,3]>=192).sum(0),cols)
  for col in range(cols):
   x,y,ex,ey=xs[col],ys[row],xs[col+1],ys[row+1]
   q=a[y:ey,x:ex];mask=q[:,:,3]>=192;labs,n=label(mask,np.ones((3,3)));sizes=np.bincount(labs.ravel());sizes[0]=0;ident=int(sizes.argmax());body=labs==ident
   yy,xx=np.where(body);bb=[int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)]
   keep=body.copy()
   # Keep a detached halo but not matte fragments or neighboring cells.
   for k in range(1,n+1):
    if sizes[k]>=max(16,sizes[ident]*.006):keep|=labs==k
   yy,xx=np.where(keep);b=[int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)]
   assert b[0]>=2 and b[1]>=2 and b[2]<=q.shape[1]-2 and b[3]<=q.shape[0]-2,(path,row,col,'silhouette touches cell edge')
   runs=[]
   for yy in range(b[1],b[3]):
    z=np.diff(np.pad(keep[yy].astype(np.int8),(1,1)));runs += [[yy,int(s),int(e-s)] for s,e in zip(np.where(z==1)[0],np.where(z==-1)[0])]
   line.append({'rect':[x,y,ex-x,ey-y],'bounds':b,'body_bounds':bb,'runs':runs,'source_column':col})
  frames.append(line)
 return a,{'path':str(path.relative_to(ROOT)),'rows':rows,'columns':cols,'dimensions':[w,h],'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'frames':frames}

def isolated(a,f):
 x,y,w,h=f['rect'];q=a[y:y+h,x:x+w].copy();keep=np.zeros(q.shape[:2],bool)
 for yy,xx,n in f['runs']:keep[yy,xx:xx+n]=True
 q[~keep]=0;return q

def register(a,d,hero,rows,neutral_row,eye_grip,scale,reference_patch=None,reference_marker=None,ratio=1.):
 ex,ey,gx,gy=eye_grip;ref=d['frames'][neutral_row][0];q=isolated(a,ref)
 # Full eye/cheek/nose boundary, not a single blue/green/amber color search.
 px,py,pw,ph=round(ex-22*ratio),round(ey-21*ratio),round(58*ratio),round(48*ratio)
 if reference_patch is None:patch=q[py:py+ph,px:px+pw].copy()
 else:patch=reference_patch
 assert patch.shape[0]>20 and patch.shape[1]>20
 if reference_marker is None:reference_marker=[ex-px,ey-py]
 target_x=14.;refbb=ref['body_bounds'];ref_eye=[ex,ey]
 d.setdefault('hero_scales',{})[hero]=scale
 d.setdefault('calibration',{})[hero]={'source_scale':scale,'neutral_eye':[ex,ey],'neutral_grip':[gx,gy],'face_patch':[px,py,patch.shape[1],patch.shape[0]],'same_scale_for_all_clips':True,'reference':'old registered neutral gun body height; alternate crouch source calibrated by one full-face patch ratio','alternate_face_ratio':ratio}
 for row in rows:
  for f in d['frames'][row]:
   b=f['body_bounds'];expected=[b[0]+px-refbb[0],b[1]+py-refbb[1]]
   xx,yy,error=match_patch(isolated(a,f),patch,expected,[55,55])
   marker=[xx+reference_marker[0],yy+reference_marker[1]]
   origin_x=marker[0]-target_x/scale
   # Air uses the same body/head reference as the neutral; grounded actions
   # use the actual connected sole, so ears/halo do not create floating feet.
   origin_y=marker[1]+(refbb[3]-ref_eye[1]) if row==2 and len(rows)==5 else float(b[3])
   grip=[marker[0]+gx-ex,marker[1]+gy-ey]
   f.update(origin=[origin_x,origin_y],face_landmark=marker,face_patch=[xx,yy,patch.shape[1],patch.shape[0]],face_residual=round(error,6),grip=grip,scale=scale,ground_contact=not(row==2 and len(rows)==5),registration='full-face-x-and-sole' if not(row==2 and len(rows)==5) else 'full-face-body-air')
 # Track the actual wrist/knuckle region independently of the skull. This
 # carries authored arm recoil into both the weapon layer and physics muzzle.
 for row in rows:
  rf=d['frames'][row][0];rq=isolated(a,rf);cx,cy=rf['grip'];hw,hh=round(14*ratio),round(13*ratio)
  tx,ty=round(cx-hw),round(cy-hh);hand=rq[ty:ty+hh*2,tx:tx+hw*2].copy()
  assert hand.shape[:2]==(hh*2,hw*2),(hero,row,'hand patch clipped')
  local=[cx-tx,cy-ty]
  for f in d['frames'][row]:
   q=isolated(a,f);expected=[f['grip'][0]-local[0],f['grip'][1]-local[1]]
   xx,yy,error=match_patch(q,hand,expected,[max(5,round(9*ratio)),max(5,round(9*ratio))])
   f['grip']=[xx+local[0],yy+local[1]];f['grip_patch']=[xx,yy,hand.shape[1],hand.shape[0]];f['grip_residual']=round(error,6);f['grip_method']='bounded whole-wrist RGB/alpha patch; row-neutral reviewed hand socket'
 return patch,[ex-px,ey-py]

def main():
 atlases={};sources={};body_refs={}
 for hero,name in [('aion','aion'),('sheep','sheep'),('rabbit','ayca'),('eren','eren')]:
  a,d=grid(ROOT/f'assets/m1-body-{name}.png',5)
  old=BASE['atlases']['pixel-'+hero];oldf=old['frames'][3][0];ob=oldf['body_bounds'];target_height=(ob[3]-ob[1])*old['scale'][3]
  b=d['frames'][1][0]['body_bounds'];scale=target_height/(b[3]-b[1])
  n=list(NEUTRAL[hero]);n[1]+=d['dimensions'][1]/5-d['frames'][1][0]['rect'][1];n[3]+=d['dimensions'][1]/5-d['frames'][1][0]['rect'][1]
  patch,marker=register(a,d,hero,range(5),1,n,scale)
  d['runtime_rows']=[0,1,2]
  atlases[hero]=d;sources[hero]=a;body_refs[hero]=(patch,marker,scale)
 a,d=grid(ROOT/'assets/m1-rabbit-crouch.png',4)
 for hero,rows in [('rabbit',[0,1]),('eren',[2,3])]:
  patch,marker,base_scale=body_refs[hero];ex,ey,gx,gy=CROUCH_NEUTRAL[hero];adjust=d['dimensions'][1]/4*rows[1]-d['frames'][rows[1]][0]['rect'][1];ey+=adjust;gy+=adjust;q=isolated(a,d['frames'][rows[1]][0]);best=None
  for ratio in np.linspace(.8,1.6,81):
   t=np.asarray(Image.fromarray(patch).resize((round(patch.shape[1]*ratio),round(patch.shape[0]*ratio)),Image.Resampling.NEAREST))
   expected=[ex-marker[0]*ratio,ey-marker[1]*ratio];x,y,error=match_patch(q,t,expected,[12,12])
   if best is None or error<best[0]:best=(error,float(ratio),x,y,t)
  error,ratio,x,y,t=best
  # Retain the visually reviewed eye/hand socket after the neutral fit; only
  # subsequent frames use local template translation. No per-frame scaling.
  actual_marker=[x+marker[0]*ratio,y+marker[1]*ratio];delta=[actual_marker[0]-ex,actual_marker[1]-ey]
  eyegrip=(actual_marker[0],actual_marker[1],gx+delta[0],gy+delta[1])
  register(a,d,hero,rows,rows[1],eyegrip,base_scale/ratio,t,[marker[0]*ratio,marker[1]*ratio],ratio)
  d['calibration'][hero]['neutral_fit_error']=error
 atlases['rabbit_crouch']=d
 for hero,eyegrip in [('aion',(234.,180.,253.,244.)),('sheep',(220.,202.,254.,262.))]:
  a,d=grid(ROOT/f'assets/m1-{hero}-crouch.png',2)
  patch,marker,base_scale=body_refs[hero];ex,ey,gx,gy=eyegrip;q=isolated(a,d['frames'][1][0]);best=None
  for ratio in np.linspace(1.1,2.5,141):
   t=np.asarray(Image.fromarray(patch).resize((round(patch.shape[1]*ratio),round(patch.shape[0]*ratio)),Image.Resampling.NEAREST))
   x,y,error=match_patch(q,t,[ex-marker[0]*ratio,ey-marker[1]*ratio],[15,15])
   if best is None or error<best[0]:best=(error,float(ratio),x,y,t)
  error,ratio,x,y,t=best;actual_marker=[x+marker[0]*ratio,y+marker[1]*ratio];delta=[actual_marker[0]-ex,actual_marker[1]-ey]
  register(a,d,hero,[0,1],1,(actual_marker[0],actual_marker[1],gx+delta[0],gy+delta[1]),base_scale/ratio,t,[marker[0]*ratio,marker[1]*ratio],ratio)
  d['calibration'][hero]['neutral_fit_error']=error;atlases[hero+'_crouch']=d
 data={'generation_sources':{'m1-body-aion.png':'exec-d146196f-70e2-4a74-ad2c-d55e47ef2466','m1-body-ayca.png':'exec-be99eae3-c7d2-42f3-b4c8-f3534fbf45e0','m1-body-eren.png':'exec-3ac5d398-1b1d-4720-a56d-ab9a21659f28','m1-body-sheep.png':'exec-3881cc69-d285-4924-b61a-85be3bf0e599','m1-rabbit-crouch.png':'exec-20b646fb-3266-4049-a5a5-3ab4cd3dee0a','m1-aion-crouch.png':'exec-6b2f9a1a-c915-43ef-b829-062941c7fefe','m1-sheep-crouch.png':'exec-b2fca39b-99d9-4047-8bc7-c75ea8aed3b9'},'version':1,'status':'Owner-requested game art variant, not a global canon update. AI-assisted source drawings; original source PNGs unchanged.','method':'Unmodified generated RGBA sources; alpha>=192 connected-body spans with independent texture gutters; whole face registration, fixed source scale per hero/atlas, true sole baseline and measured empty-hand grip. No physics root or per-frame scale changes.','hero_keys':HEROES,'actions':ACTIONS,'atlases':atlases,'runtime_drawings':120,'source_drawings':168,'superseded_source_drawings':48,'runtime_rows':{'aion':{**{k:['aion',i] for i,k in enumerate(ACTIONS[:3])},'crouch_walk':['aion_crouch',0],'crouch_fire':['aion_crouch',1]},'sheep':{**{k:['sheep',i] for i,k in enumerate(ACTIONS[:3])},'crouch_walk':['sheep_crouch',0],'crouch_fire':['sheep_crouch',1]},'rabbit':{**{k:['rabbit',i] for i,k in enumerate(ACTIONS[:3])},'crouch_walk':['rabbit_crouch',0],'crouch_fire':['rabbit_crouch',1]},'eren':{**{k:['eren',i] for i,k in enumerate(ACTIONS[:3])},'crouch_walk':['rabbit_crouch',2],'crouch_fire':['rabbit_crouch',3]}},'playback':{'walk':{'frames':6,'world_distance':174.,'loop':True},'idle_fire':{'frames':6,'seconds':.28,'loop':False,'idle_frame':0},'air_fire':{'frames':6,'selection':'flight phase, recoil may affect hands only'},'crouch_walk':{'frames':6,'world_distance':110.,'loop':True},'crouch_fire':{'frames':6,'seconds':.28,'loop':False}},'gun_contract':'Body-only cels. A separate weapon texture rotates about grip_local; physics muzzle must derive from the same grip and actual weapon barrel_length. Aiming never swaps or rescales the whole body.'}
 output=ROOT/'assets/M1-HEROES-PROVENANCE.json';temporary=output.with_suffix('.tmp');temporary.write_text(json.dumps(data,separators=(',',':'))+'\n');temporary.replace(output)
 print('Registered',data['runtime_drawings'],'runtime poses from',data['source_drawings'],'generated drawings')
 for key,v in atlases.items():print(key,v['calibration'])
if __name__=='__main__':main()
