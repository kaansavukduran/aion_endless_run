"""Read-only registration of the original arcade machine atlas; never retouch pixels."""
from pathlib import Path
import hashlib,json
import numpy as np
from PIL import Image
from scipy.ndimage import label
from campaign_registration import match_patch

root=Path(__file__).resolve().parents[1]
source=root/'assets/arcade-machines.png'
image=Image.open(source).convert('RGBA')
pixels=np.asarray(image)
height,width=pixels.shape[:2]
rows=[]
templates={}
for row in range(8):
    frames=[]
    for col in range(6):
        left,right=round(col*width/6),round((col+1)*width/6)
        top,bottom=round(row*height/8),round((row+1)*height/8)
        cell=pixels[top:bottom,left:right]
        mask=cell[:,:,3]>=128
        ys,xs=np.where(mask)
        assert len(xs)>800,(row,col,'missing drawing')
        x0,x1=int(xs.min()),int(xs.max())+1
        y0,y1=int(ys.min()),int(ys.max())+1
        # Central glass lens, not the extended muzzle or changing rotors/leaves.
        r,g,b=cell[:,:,:3].astype(float).transpose(2,0,1)
        feature=(b>120)&(g>125)&(b>r*1.35)&(g>r*1.3)&mask
        yy,xx=np.indices(mask.shape)
        if row in [4,5]:
            feature=(r>190)&(g>155)&(b<170)&mask
            feature&=(xx>80)&(xx<145)&(yy>85)&(yy<150)
        elif row>=6: feature&=(xx>35)&(xx<125)&(yy>65)&(yy<150)
        else: feature&=(xx>65)&(xx<145)&(yy>40)&(yy<145)
        components,count=label(feature)
        assert count,(row,col,'missing reviewed core landmark')
        sizes=np.bincount(components.ravel());sizes[0]=0
        fy,fx=np.where(components==sizes.argmax())
        cx,cy=float(fx.mean()),float(fy.mean())
        pair=row//2
        if pair not in templates:
            tx,ty=(58,82) if pair==2 else (round(cx)-14,round(cy)-14)
            templates[pair]=(cell[ty:ty+28,tx:tx+28].copy(),(tx,ty))
        patch,expected=templates[pair]
        px,py,error=match_patch(cell,patch,expected,[28,28])
        cx,cy=(px+18.,py+12.) if pair==2 else (px+14.,py+14.)
        runs=[]
        for y in range(y0,y1):
            row_mask=mask[y]
            changes=np.diff(np.pad(row_mask.astype(np.int8),(1,1)))
            for a,z in zip(np.where(changes==1)[0],np.where(changes==-1)[0]):runs.append([y,int(a),int(z-a)])
        frames.append({'rect':[left,top,right-left,bottom-top],'bounds':[x0,y0,x1,y1],'origin':[cx,cy if row in [0,1,4,5] else y1],'core':[cx,cy],'probe':[px,py,28,28],'registration_residual':round(error,6),'runs':runs})
    rows.append(frames)
data={'version':1,'source':'assets/arcade-machines.png','sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'dimensions':[width,height],'columns':6,'rows':8,'generation':'exec-1cd580bf-53b0-4738-9fe4-064d51668bfb','method':'Original AI-assisted atlas retained byte-for-byte. Alpha128 silhouette spans; full lens/lamp template tracks glass and rim together (not changing colour centroid); actual feet for grounded machines. No physics-origin or per-frame scale compensation.','row_names':['scout_hover','scout_attack','seed_walk','seed_attack','skimmer_hover','skimmer_cannon','warden_walk','warden_attack'],'scales':[.50,.50,.52,.52,.72,.72,.90,.90],'frames':rows}
(root/'assets/ARCADE-MACHINES-PROVENANCE.json').write_text(json.dumps(data,separators=(',',':'))+'\n')
print('Registered48 source drawings; original PNG unchanged:',data['sha256'])
