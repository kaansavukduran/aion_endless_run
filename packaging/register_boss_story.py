"""Register six new reaction clips and a red pistol; leave source pixels intact."""
from pathlib import Path
import hashlib,json
import numpy as np
from PIL import Image
from scipy.ndimage import label
from register_pixel_heroes import cuts,face_fit
ROOT=Path(__file__).resolve().parents[1]

def main():
 path=ROOT/'assets/boss-story-reactions.png';image=np.array(Image.open(path).convert('RGBA'));h,w=image.shape[:2]
 ys=cuts((image[:,:,3]>=192).sum(1),7);rows=[];scales=[]
 heroes=['aion','owl','sheep','wolf','rabbit','eren']
 original=json.loads((ROOT/'assets/PIXEL-HEROES-PROVENANCE.json').read_text())
 for row in range(7):
  strip=image[ys[row]:ys[row+1]];xs=cuts((strip[:,:,3]>=192).sum(0),6);line=[]
  for col in range(6):
   q=strip[:,xs[col]:xs[col+1]];labs,n=label(q[:,:,3]>=192,np.ones((3,3)));sizes=np.bincount(labs.ravel());sizes[0]=0
   body=labs==sizes.argmax();keep=body.copy();yy,xx=np.where(body);bb=[int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)]
   if row==2 or row==6:
    for k in range(1,n+1):
     if sizes[k]>=max(4,sizes.max()*.004):keep|=labs==k
   yy,xx=np.where(keep);b=[int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)];runs=[]
   for y in range(b[1],b[3]):
    z=np.diff(np.pad(keep[y].astype(np.int8),(1,1)));runs.extend([[y,int(x),int(e-x)] for x,e in zip(np.where(z==1)[0],np.where(z==-1)[0])])
   line.append({'rect':[xs[col],ys[row],xs[col+1]-xs[col],ys[row+1]-ys[row]],'bounds':b,'body_bounds':bb,'runs':runs,'eye':None,'source_column':col,'origin':[(bb[0]+bb[2])/2,float(bb[3])],'ground_contact':row<6,'registration':'reviewed-face-x-and-ground'})
  neutral=line[0];bb=neutral['body_bounds']
  scale=(82 if row<4 else 92)/(bb[3]-bb[1]) if row<6 else 38/(bb[2]-bb[0]);scales.append(scale)
  if row<6:
   # Restrict face matching to the anatomically expected head region. Both
   # eye widening and jaw opening are authored changes, not registration noise.
   src=original['atlases']['pixel-'+heroes[row]]['frames'][0][0];b0=src['body_bounds'];eye=src['eye']
   expected=[bb[i]+(eye[i]-b0[i])/(b0[i+2]-b0[i])*(bb[i+2]-bb[i]) for i in [0,1]]
   x=int(expected[0]-15);y=int(expected[1]-17);template=strip[:,xs[0]:xs[1]][y:y+38,x:x+43]
   for f in line:
    rx,ry,rw,rh=f['rect'];q=image[ry:ry+rh,rx:rx+rw]
    b=f['body_bounds'];e=[b[i]+(expected[i]-bb[i])/(bb[i+2]-bb[i])*(b[i+2]-b[i]) for i in [0,1]]
    xx,yy,error=face_fit(q,template,e,[18,15]);f['eye']=[xx+15,yy+17];f['head_probe']=[xx,yy,43,38];f['origin'][0]=xx+15-14/scale;f['face_residual']=round(error,6)
  rows.append(line)
 data={'version':'0.21.0','source':'exec-ff70a5b9-d7ac-4b02-9e58-ea25f0cb99db','source_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'playback_note':'Cinematic uses source columns1..5; first neutral column is deliberately not selected because the generated first Aion/wolf tail reaches the outside source edge. No missing pixels are claimed repaired; complete neutral column1 is used, not padded duplicate art.',
       'purpose':'Six character-faithful grounded surprise clips and six red-pistol poses. New image generation; original gameplay drawings unchanged. Owner visual approval remains separate from technical registration.','atlas':{'path':str(path.relative_to(ROOT)),'width':w,'height':h,'rows':7,'columns':6,'row_counts':[6]*7,'frames':rows,'scale':scales,'anchor_x':[0]*7,'head_spans':[1]*7}}
 (ROOT/'assets/STORY-PROVENANCE.json').write_text(json.dumps(data,separators=(',',':'))+'\n')
 print('Registered',w,h,'42 reaction/weapon source frames')
if __name__=='__main__':main()
