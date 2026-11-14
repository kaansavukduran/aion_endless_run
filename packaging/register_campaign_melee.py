"""Register new close attacks without resampling or overwriting source art."""
from pathlib import Path
import hashlib,json
import numpy as np
from PIL import Image
from scipy.ndimage import label
from campaign_registration import match_patch
from register_pixel_heroes import cuts

ROOT=Path(__file__).resolve().parents[1]
base=json.loads((ROOT/'assets/PIXEL-HEROES-PROVENANCE.json').read_text())
result={}
for name,heroes in [('campaign-melee',['aion','owl','sheep','wolf','rabbit']),('campaign-eren-melee',['eren'])]:
    path=ROOT/'assets'/f'{name}.png';a=np.array(Image.open(path).convert('RGBA'));height,width=a.shape[:2]
    ys=cuts((a[:,:,3]>=192).sum(1),len(heroes))
    for row,hero in enumerate(heroes):
        frames=[];template=None;scale=None
        xs=cuts((a[ys[row]:ys[row+1],:,3]>=192).sum(0),6)
        for col in range(6):
            x,z=xs[col],xs[col+1];y,w=ys[row],ys[row+1]
            q=a[y:w,x:z].copy();mask=q[:,:,3]>=192
            labs,n=label(mask,np.ones((3,3)));sizes=np.bincount(labs.ravel());sizes[0]=0
            body=labs==sizes.argmax();by,bx=np.where(body)
            body_bounds=[int(bx.min()),int(by.min()),int(bx.max()+1),int(by.max()+1)]
            keep=body.copy()
            for k in range(1,n+1):
                if hero!='sheep' or sizes[k]<max(12,sizes.max()*.008):continue
                ky,kx=np.where(labs==k)
                # The separate halo belongs above the head. Neighboring-row
                # ears/feet must never extend a character's supposed floor.
                if ky.max()<body_bounds[1]+8 and kx.mean()>body_bounds[0] and kx.mean()<body_bounds[2]:keep|=labs==k
            yy,xx=np.where(keep);b=[int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)]
            q[~keep]=0
            if template is None:
                # Upper face stays in the patch; fist, muzzle and changing ears
                # do not determine horizontal registration.
                bw,bh=body_bounds[2]-body_bounds[0],body_bounds[3]-body_bounds[1]
                tx=int(body_bounds[0]+bw*.48);ty=int(body_bounds[1]+bh*.28)
                tw=max(25,int(bw*.27));th=max(20,int(bh*.20))
                template=q[ty:ty+th,tx:tx+tw].copy();reference=(tx,ty)
                old=base['atlases']['pixel-'+hero];f=old['frames'][0][0]
                neutral_height=(f['body_bounds'][3]-f['body_bounds'][1])*old['scale'][0]
                scale=neutral_height/bh
                first_origin=tx+tw*.5-14./scale
                if hero in ['sheep','wolf','rabbit','eren']:
                    foot_y=b[3]-max(12,int(bh*.08));foot_xs=np.where(keep[foot_y:b[3]])[1]
                    foot_x=int(np.median(foot_xs));tx=max(0,foot_x-16);ty=foot_y
                    template=q[ty:b[3],tx:tx+32].copy();reference=(tx,ty)
            fx,fy,error=match_patch(q,template,reference,[35,40])
            origin_x=first_origin+fx-reference[0]
            runs=[]
            for yy in range(b[1],b[3]):
                d=np.diff(np.pad(keep[yy].astype(np.int8),(1,1)))
                runs.extend([[yy,int(s),int(e-s)] for s,e in zip(np.where(d==1)[0],np.where(d==-1)[0])])
            frames.append({'rect':[x,y,z-x,w-y],'bounds':b,'body_bounds':body_bounds,'origin':[origin_x,body_bounds[3]],'probe':[fx,fy,template.shape[1],template.shape[0]],'registration':'planted-foot' if hero in ['sheep','wolf','rabbit','eren'] else 'upper-face','registration_residual':round(error,6),'runs':runs})
        result[hero]={'path':f'assets/{name}.png','sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'scale':scale,'frames':frames}
(ROOT/'assets/CAMPAIGN-MELEE-PROVENANCE.json').write_text(json.dumps({'method':'Original AI-assisted PNGs unchanged. Actual alpha gutters, not a nominal equal lattice, separate rows and columns. Largest body plus the sheep halo only; no neighboring-row fragments. Upper-face/planted-boot patches register body translation while preserving intentional headbutt/bite motion. Actual opaque body feet register floor. One constant scale per hero.','generation_sources':{'campaign-melee':'exec-dc77327c-3611-4e08-98db-9ab3c6a5455a','campaign-eren-melee':'exec-e1d685ff-6220-4677-82f3-aeccd0a47fba'},'heroes':result},separators=(',',':'))+'\n')
print('Registered 36 new close-attack drawings. Original running/jumping assets unchanged.')
