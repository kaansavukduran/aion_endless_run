"""Register original item drawings by alpha gutters; retain the source PNG."""
from pathlib import Path
import hashlib,json
import numpy as np
from PIL import Image
from scipy.ndimage import label
from register_pixel_heroes import cuts

ROOT=Path(__file__).resolve().parents[1]
path=ROOT/'assets/forge-items.png'
a=np.asarray(Image.open(path).convert('RGBA'))
names=['heavy','scatter','arc','beam','disc','harpoon','seeker','spore','trap','nova','grenade','shield','heal','repair','points','haste','power','reveal','magnet','pistol']
ys=cuts((a[:,:,3]>=192).sum(1),4)
frames={}
for row in range(4):
    strip=a[ys[row]:ys[row+1]]
    xs=cuts((strip[:,:,3]>=192).sum(0),5)
    for col in range(5):
        q=strip[:,xs[col]:xs[col+1]]
        labs,_=label(q[:,:,3]>=192,np.ones((3,3)))
        sizes=np.bincount(labs.ravel());sizes[0]=0
        keep=np.isin(labs,np.where(sizes>=max(12,sizes.max()*.004))[0])
        yy,xx=np.where(keep)
        bounds=[int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)]
        runs=[]
        for y in range(bounds[1],bounds[3]):
            diff=np.diff(np.pad(keep[y].astype(np.int8),(1,1)))
            runs.extend([[y,int(s),int(e-s)] for s,e in zip(np.where(diff==1)[0],np.where(diff==-1)[0])])
        frames[names[row*5+col]]={'rect':[xs[col],ys[row],q.shape[1],q.shape[0]],'bounds':bounds,'runs':runs,'scale':46./max(bounds[2]-bounds[0],bounds[3]-bounds[1]),'source_edge':bool(xs[col]+bounds[0]==0 or ys[row]+bounds[1]==0 or xs[col]+bounds[2]==a.shape[1] or ys[row]+bounds[3]==a.shape[0])}
data={'path':'assets/forge-items.png','sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'generation':'exec-e7b45e5b-c77d-415a-b379-151ee58916c0','status':'Original AI-assisted owner-requested game artwork, draft visual approval; not SNK assets.','drawings':20,'animations':0,'method':'Isolated source alpha spans, centered anchor, nearest sampling, 2-pixel transparent gutters. Static item drawings are not counted as animation frames.','frames':frames}
(ROOT/'assets/FORGE-ITEMS-PROVENANCE.json').write_text(json.dumps(data,separators=(',',':'))+'\n')
print('Registered',len(frames),'item drawings; source-edge cells:',[k for k,v in frames.items() if v['source_edge']])
