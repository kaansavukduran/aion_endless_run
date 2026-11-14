"""Register owner-authorized new hero poses; source RGBA bytes remain unchanged.

Actual alpha components isolate cells. One calibrated body scale per hero/source
is reused for the complete clip; whole-face patches anchor mouth-carry loops.
"""
from pathlib import Path
import hashlib,json
import numpy as np
from PIL import Image
from scipy.ndimage import label,find_objects
from register_pixel_heroes import cuts,isolated
from campaign_registration import match_patch
ROOT=Path(__file__).resolve().parents[1]
HEROES=['aion','wolf','sheep','owl','rabbit','eren']
BASE=json.loads((ROOT/'assets/PIXEL-HEROES-PROVENANCE.json').read_text())
REVIEW=ROOT/'build/forge-art-review';REVIEW.mkdir(exist_ok=True,parents=True)

def grid(name,rows,cols):
 path=ROOT/'assets'/('forge-'+name+'.png');a=np.array(Image.open(path).convert('RGBA'));h,w=a.shape[:2]
 labels,_=label(a[:,:,3]>=192,np.ones((3,3)));objects=find_objects(labels)
 ys=cuts((a[:,:,3]>=192).sum(1),rows);frames=[]
 for row in range(rows):
  strip=a[ys[row]:ys[row+1]];xs=cuts((strip[:,:,3]>=192).sum(0),cols);line=[]
  for col in range(cols):
   rect=[xs[col],ys[row],xs[col+1],ys[row+1]];q=a[rect[1]:rect[3],rect[0]:rect[2]]
   ls,n=label(q[:,:,3]>=192,np.ones((3,3)));sizes=np.bincount(ls.ravel());sizes[0]=0;body=ls==sizes.argmax();yy,xx=np.where(body)
   ident=labels[rect[1]+yy[0],rect[0]+xx[0]];sy,sx=objects[ident-1]
   assert sx.stop-sx.start<w/cols*1.5 and sy.stop-sy.start<h/rows*1.6,(name,row,col,'joined source poses')
   rx=max(0,min(rect[0],sx.start-2));ry=max(0,min(rect[1],sy.start-2));ex=min(w,max(rect[2],sx.stop+2));ey=min(h,max(rect[3],sy.stop+2))
   keep=labels[ry:ey,rx:ex]==ident
   for k in range(1,n+1):
    if sizes[k]>=max(6,sizes.max()*.003):keep[rect[1]-ry:rect[3]-ry,rect[0]-rx:rect[2]-rx]|=ls==k
   yy,xx=np.where(labels[ry:ey,rx:ex]==ident);bb=[int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)]
   yy,xx=np.where(keep);b=[int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)];runs=[]
   for y in range(b[1],b[3]):
    z=np.diff(np.pad(keep[y].astype(np.int8),(1,1)));runs.extend([[y,int(s),int(e-s)] for s,e in zip(np.where(z==1)[0],np.where(z==-1)[0])])
   line.append({'rect':[rx,ry,ex-rx,ey-ry],'bounds':b,'body_bounds':bb,'origin':[(bb[0]+bb[2])/2,bb[3]],'source_column':col,'runs':runs})
  frames.append(line)
 return a,{'path':str(path.relative_to(ROOT)),'dimensions':[w,h],'rows':rows,'columns':cols,'frames':frames,'scales':[1.]*rows,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}

def calibrate(a,d,row,hero,eye,reviewed_ratio=None):
 old=BASE['atlases']['pixel-'+hero];f=old['frames'][0][0];oa=np.asarray(Image.open(ROOT/old['path']).convert('RGBA'));q=isolated(oa,f);x,y,w,h=f['head_probe'];patch=q[y:y+h,x:x+w]
 nq=isolated(a,d['frames'][row][0]);best=None
 # Match a complete face patch (eye, cheek, muzzle), never single blue pixels.
 for ratio in ([reviewed_ratio] if reviewed_ratio else np.linspace(.8,1.85,43)):
  t=np.asarray(Image.fromarray(patch).resize((round(w*ratio),round(h*ratio)),Image.Resampling.NEAREST))
  expected=[eye[0]-15*ratio,eye[1]-17*ratio]
  xx,yy,error=match_patch(nq,t,expected,[12,12])
  score=error
  if best is None or score<best[0]:best=(score,float(ratio),xx,yy,t)
 error,ratio,xx,yy,t=best;factor=float(old['scale'][0])/ratio
 return factor,[xx+15*ratio,yy+17*ratio],{'reference':old['path'],'reference_head_span':old['head_spans'][0],'neutral_patch_ratio':ratio,'neutral_patch_error':error,'neutral_world_head_span':old['head_spans'][0]*old['scale'][0],'calibration':'reviewed skull proportion override; patch records landmark only' if reviewed_ratio else 'bounded complete-face patch fit'}

def register_clip(a,d,rows,hero,eye,airborne=False):
 factor,marker,cal=calibrate(a,d,rows[0],hero,eye);old=BASE['atlases']['pixel-'+hero];target=old['target_eye'];ref=d['frames'][rows[0]][0];q=isolated(a,ref)
 pw,ph=round(43*cal['neutral_patch_ratio']),round(38*cal['neutral_patch_ratio']);tx=round(marker[0]-pw*.35);ty=round(marker[1]-ph*.45);patch=q[ty:ty+ph,tx:tx+pw].copy();assert patch.shape[:2]==(ph,pw)
 rb=ref['body_bounds']
 for row in rows:
  d['scales'][row]=factor
  for f in d['frames'][row]:
   b=f['body_bounds'];expected=[b[0]+(tx-rb[0]),b[1]+(ty-rb[1])]
   xx,yy,error=match_patch(isolated(a,f),patch,expected,[45,50]);m=[xx+(marker[0]-tx),yy+(marker[1]-ty)]
   f.update(origin=[m[0]-target[0]/factor,m[1]-target[1]/factor if airborne else float(b[3])],face_landmark=m,face_patch=[xx,yy,pw,ph],face_residual=round(error,6),registration='face-body-air' if airborne else 'face-x-and-feet',ground_contact=not airborne)
 d.setdefault('calibration',{})[hero]=cal
 return factor

def add_muzzles(a,d):
 directions=[(1,0),(1,-1),(0,-1),(-1,-1),(-1,0),(-1,1),(0,1),(1,1)]
 for row,line in enumerate(d['frames']):
  for f in line:
   q=isolated(a,f);b=f['body_bounds'];col=f['source_column'];direction=directions[col] if d['columns']==8 else (1,0)
   if direction==(1,0):expected=(b[2]-3,b[1]+(b[3]-b[1])*.48)
   elif direction==(-1,0):expected=(b[0]+3,b[1]+(b[3]-b[1])*.48)
   elif direction==(1,-1):expected=(b[2]-5,b[1]+(b[3]-b[1])*.25)
   elif direction==(-1,-1):expected=(b[0]+5,b[1]+(b[3]-b[1])*.25)
   elif direction==(0,-1):expected=((b[0]+b[2])*.5+20,b[1]+3)
   elif direction==(0,1):expected=((b[0]+b[2])*.5,b[3]-3)
   elif direction==(-1,1):expected=(b[0]+10,b[3]-20)
   else:expected=(b[2]-10,b[3]-20)
   rgb=q[:,:,:3].astype(float);cyan=(q[:,:,3]>=192)&(rgb[:,:,2]>100)&(rgb[:,:,1]>70)&(rgb[:,:,2]>rgb[:,:,0]*1.5)&(rgb[:,:,1]>rgb[:,:,0]*1.3)
   yy,xx=np.where(cyan)
   assert len(xx)>0,('No muzzle cyan',d['path'],row,col)
   k=np.argmin((xx-expected[0])**2+(yy-expected[1])**2)
   f['muzzle']=[float(xx[k]),float(yy[k])];f['muzzle_method']='reviewable cyan barrel tip near directional authored muzzle window'

def main():
 atlases={};a,d=grid('mouth-carry',4,6)
 register_clip(a,d,[0,1],'owl',[184,107],True);register_clip(a,d,[2,3],'wolf',[183,97],False)
 d['clips']={'owl_glide':{'row':0,'frames':6,'seconds':1.,'loop':True},'owl_flap':{'row':1,'frames':6,'seconds':.3,'loop':False},'wolf_gallop':{'row':2,'frames':6,'seconds':.42,'loop':True},'wolf_fire':{'row':3,'frames':6,'seconds':.3,'loop':False}}
 add_muzzles(a,d)
 atlases['mouth-carry']=d
 a,d=grid('embark',6,6)
 eyes=[[144,77],[149,77],[123,95],[132,88],[120,77],[130,72]]
 for row,hero in enumerate(HEROES):
  factor,marker,cal=calibrate(a,d,row,hero,eyes[row],1.5 if hero=='aion' else None);d['scales'][row]=factor;d.setdefault('calibration',{})[hero]=cal
  # A fixed anatomical root derived from the neutral face, not each pose's bbox.
  ref=d['frames'][row][0];origin=[marker[0]-BASE['atlases']['pixel-'+hero]['target_eye'][0]/factor,ref['body_bounds'][3]]
  global_origin=[ref['rect'][0]+origin[0],ref['rect'][1]+origin[1]]
  for f in d['frames'][row]:
   # Fixed source atlas cell root; gutter crop widths never move the actor.
   f['origin']=[global_origin[0]+f['source_column']*d['dimensions'][0]/6-f['rect'][0],global_origin[1]-f['rect'][1]];f['registration']='authored-hatch-root';f['ground_contact']=f['source_column']==0
 d['clips']={h:{'row':i,'frames':6,'seconds':.45,'loop':False,'exit':'reverse'} for i,h in enumerate(HEROES)};atlases['embark']=d
 a,d=grid('eightway',6,8)
 eyes=[[149,57],[151,53],[128,62],[141,58],[137,59],[145,56]]
 for row,hero in enumerate(HEROES):
  factor,marker,cal=calibrate(a,d,row,hero,eyes[row],{'aion':1.15,'sheep':1.2}.get(hero));d['scales'][row]=factor;d.setdefault('calibration',{})[hero]=cal
  ref=d['frames'][row][0];q=isolated(a,ref);pw,ph=round(43*cal['neutral_patch_ratio']),round(38*cal['neutral_patch_ratio']);tx=round(marker[0]-pw*.35);ty=round(marker[1]-ph*.45);patch=q[ty:ty+ph,tx:tx+pw].copy();assert patch.shape[:2]==(ph,pw)
  for f in d['frames'][row]:
   b=f['body_bounds'];col=f['source_column'];flipped=col in [3,4,5];front=col==6
   t=patch[:,::-1].copy() if flipped else patch
   expected=[marker[0]-tx,marker[1]-ty]
   # Expected head window follows the regular cell, not the gun/halo bounds.
   expected=[eyes[row][0]-t.shape[1]*(.65 if flipped else .35),eyes[row][1]-t.shape[0]*.45]
   xx,yy,error=match_patch(isolated(a,f),t,expected,[55,38])
   mx=xx+(pw-(marker[0]-tx) if flipped else marker[0]-tx);my=yy+(marker[1]-ty)
   target=0. if front else (-14. if flipped else 14.)
   f['face_landmark']=[mx,my];f['face_patch']=[xx,yy,pw,ph];f['face_residual']=round(error,6);f['face_flipped']=flipped
   foot_y=float(b[3])
   if col==6:
    # The downward gun may end below the shoes: exclude its narrow centre.
    qq=isolated(a,f);mask=qq[:,:,3]>=192;centre=int((b[0]+b[2])/2);mask[:,max(0,centre-13):centre+14]=False
    py,px=np.where(mask);foot_y=float(py.max()+1)
   f['origin']=[mx-target/factor,foot_y];f['registration']='face-x-and-anatomical-feet';f['ground_contact']=True
 d['direction_order']=['right','up_right','up','up_left','left','down_left','down','down_right'];d['clips']={h:{'row':i,'frames':8,'kind':'eight distinct directional keyposes, not eight animations'} for i,h in enumerate(HEROES)};add_muzzles(a,d);atlases['eightway']=d
 # Visually reviewed cyan matches: Aion's gill and wolf's iris are NOT muzzle tips.
 d['frames'][0][2]['muzzle']=[154.,20.];d['frames'][0][2]['muzzle_method']='manually reviewed vertical pistol endcap; blue gill excluded'
 a,d=grid('mouth-aim',2,8)
 for row,hero,eye in [(0,'owl',[175,157]),(1,'wolf',[194,164])]:
  factor,marker,cal=calibrate(a,d,row,hero,eye,1.5 if hero=='wolf' else None);d['scales'][row]=factor;d.setdefault('calibration',{})[hero]=cal
  for f in d['frames'][row]:
   q=isolated(a,f);b=f['body_bounds'];y0=max(b[1],b[3]-16);yy,xx=np.where(q[y0:b[3],:,3]>=192)
   # Feet/body support, never the width of wing, tail or tilted gun.
   foot=float(np.median(xx));foot_y=float(b[3])
   if f['source_column']==6:
    mask=q[:,:,3]>=192;centre=int((b[0]+b[2])/2);mask[:,max(0,centre-14):centre+15]=False;py,px=np.where(mask);foot_y=float(py.max()+1)
   f['origin']=[foot,foot_y];f['body_landmark']=[foot,foot_y];f['registration']='toe-body-support';f['ground_contact']=hero=='wolf'
 d['direction_order']=['right','up_right','up','up_left','left','down_left','down','down_right'];add_muzzles(a,d);atlases['mouth-aim']=d
 d['frames'][1][2]['muzzle']=[198.,82.];d['frames'][1][2]['muzzle_method']='manually reviewed upward mouth-pistol endcap; cyan iris excluded'
 hashes=[]
 for key,d in atlases.items():
  src=np.asarray(Image.open(ROOT/d['path']).convert('RGBA'))
  for row in d['frames']:
   for f in row:hashes.append(hashlib.sha256(isolated(src,f).tobytes()).hexdigest())
 out={'version':1,'source_status':'Owner-authorized AI-assisted original draft artwork; approval is not implied. Original files retained byte-identically.','license':'AI-assisted original game art generated for this project; no third-party game assets.','heroes':HEROES,'generation_ids':{'mouth-carry':'f1660c63-7454-47c5-b54d-3bb01f62d47f','embark':'f2c8f259-6045-490f-b6d7-4760d54527b7','eightway':'0460ec51-891e-42fb-8c39-75e49765a84a','mouth-aim':'1029d219-6d9f-4b55-9ad7-7f2e437dbad6'},'atlases':atlases,'distinct_pose_crops':len(set(hashes)),'total_pose_crops':len(hashes),'method':'Alpha-connected bodies with isolated sampling gutters; fixed scale calibrated against approved neutral face patch, full-face registration for steady carry loops. Hatch poses retain authored articulation; no bitmap resizing, rotations or copied extra frames.'}
 (ROOT/'assets/FORGE-HEROES-PROVENANCE.json').write_text(json.dumps(out,separators=(',',':'))+'\n')
 for key,d in atlases.items():print(key,'scales',d['scales'],'calibration',d['calibration'])
 print('Distinct',len(set(hashes)),'of',len(hashes))
if __name__=='__main__':main()
