"""Register the authored 28px held pistol without changing original pickup art."""
from pathlib import Path
import hashlib,json
import numpy as np
from PIL import Image
from scipy.ndimage import label
ROOT=Path(__file__).resolve().parents[1]

def register(root=ROOT):
 source=root/'assets/m1-held-pistol.png';a=np.asarray(Image.open(source).convert('RGBA'))
 labs,n=label(a[:,:,3]>=192,np.ones((3,3)));sizes=np.bincount(labs.ravel());sizes[0]=0;body=labs==sizes.argmax();yy,xx=np.where(body);bounds=[int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)];runs=[]
 for y in range(bounds[1],bounds[3]):
  z=np.diff(np.pad(body[y].astype(np.int8),(1,1)))
  runs.extend([[y,int(x),int(e-x)] for x,e in zip(np.where(z==1)[0],np.where(z==-1)[0])])
 canvas=[bounds[2]-bounds[0]+4,bounds[3]-bounds[1]+4];grip=[145.,625.];muzzle=[995.,210.]
 for point in [grip,muzzle]:
  x,y=map(round,point);assert body[y+bounds[1]-2,x+bounds[0]-2],'Socket must be on the connected opaque held body'
 original=hashlib.sha256((root/'assets/forge-items.png').read_bytes()).hexdigest()
 data={'version':1,'status':'Owner-requested game-local held-pistol gameplay variant; AI-assisted source, not owner canon approval. Original pickup and other ten weapons unchanged.','generation':'imagegen exec-a0013a83-0a67-4745-8580-82f4011cd057','reference':'Original cyan pressure lens, brass rim and brown angled grip from forge-items.png; simplified for native 28px readability.','source_pickup_sha256':original,'weapons':{'pistol':{'path':'assets/m1-held-pistol.png','source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'source_dimensions':[a.shape[1],a.shape[0]],'bounds':bounds,'runs':runs,'canvas_size':canvas,'source_facing':1,'display_source':'pistol','display_width':28.,'grip_pixel':grip,'muzzle_pixel':muzzle,'note':'Right-facing cyan front lens; opaque brown/brass lower grip and actual front-rim muzzle. One fixed scale and isolated transparent gutter.'}}}
 out=root/'assets/M1-HELD-VARIANTS.json';tmp=out.with_suffix('.tmp');tmp.write_text(json.dumps(data,separators=(',',':'))+'\n');tmp.replace(out)
 print('Registered held pistol',canvas,'sourceSHA',data['weapons']['pistol']['source_sha256'])
if __name__=='__main__':register()
