"""Register new pixel-art layers; never rewrite source PNG pixels.

Authoritative model sheets stay private and unchanged. Origins align anatomy,
not full silhouette centroids. Ground support and body flight use separate anchors.
"""
from pathlib import Path
import json,hashlib
import numpy as np
from PIL import Image
from scipy.ndimage import label,find_objects
from register_pixel_heroes import cuts,face_fit,isolated
ROOT=Path(__file__).resolve().parents[1]

def grid(name,rows,cols):
 path=ROOT/'assets'/('polish-'+name+'.png');a=np.array(Image.open(path).convert('RGBA'));h,w=a.shape[:2]
 ys=cuts((a[:,:,3]>=192).sum(1),rows);frames=[];gl,_=label(a[:,:,3]>=192,np.ones((3,3)));objects=find_objects(gl)
 for row in range(rows):
  strip=a[ys[row]:ys[row+1]];xs=cuts((strip[:,:,3]>=192).sum(0),cols);line=[]
  for col in range(cols):
   q=strip[:,xs[col]:xs[col+1]];labs,n=label(q[:,:,3]>=192,np.ones((3,3)));sizes=np.bincount(labs.ravel());sizes[0]=0;body=labs==sizes.argmax();yy,xx=np.where(body)
   ident=int(gl[ys[row]+yy[0],xs[col]+xx[0]]);sy,sx=objects[ident-1]
   rx=max(0,min(xs[col],sx.start-2));ry=max(0,min(ys[row],sy.start-2));ex=min(w,max(xs[col+1],sx.stop+2));ey=min(h,max(ys[row+1],sy.stop+2))
   keep=gl[ry:ey,rx:ex]==ident
   for k in range(1,n+1):
    if sizes[k]>=max(4,sizes.max()*.003):keep[ys[row]-ry:ys[row+1]-ry,xs[col]-rx:xs[col+1]-rx]|=labs==k
   yy,xx=np.where(gl[ry:ey,rx:ex]==ident);bb=[int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)]
   yy,xx=np.where(keep);b=[int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)];runs=[]
   for y in range(b[1],b[3]):
    z=np.diff(np.pad(keep[y].astype(np.int8),(1,1)));runs.extend([[y,int(x),int(e-x)] for x,e in zip(np.where(z==1)[0],np.where(z==-1)[0])])
   line.append({'rect':[rx,ry,ex-rx,ey-ry],'bounds':b,'body_bounds':bb,'runs':runs,'eye':None,'source_column':col,'origin':[(bb[0]+bb[2])/2,float(bb[3])],'registration':'floor','ground_contact':True})
  frames.append(line)
 return a,{'path':str(path.relative_to(ROOT)),'width':w,'height':h,'rows':rows,'columns':cols,'row_counts':[cols]*rows,'frames':frames,'scale':[1.]*rows,'anchor_x':[0]*rows,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}

def face_rows(a,d,rows,eye,target,factor):
 ref=d['frames'][rows[0]][0];q=isolated(a,ref);x,y=eye[0]-15,eye[1]-17;t=q[y:y+38,x:x+43]
 assert t.shape==(38,43,4)
 rb=ref['body_bounds']
 for row in rows:
  d['scale'][row]=factor
  for f in d['frames'][row]:
   b=f['body_bounds'];expected=[b[i]+(eye[i]-rb[i])/(rb[i+2]-rb[i])*(b[i+2]-b[i]) for i in [0,1]]
   xx,yy,error=face_fit(isolated(a,f),t,expected,[22,25]);marker=[xx+15,yy+17]
   f.update(eye=marker,head_probe=[xx,yy,43,38],face_residual=round(error,6),origin=[marker[0]-target[0]/factor,marker[1]-target[1]/factor],registration='body-air',ground_contact=False)
 return d

def main():
 pixel=json.loads((ROOT/'assets/PIXEL-HEROES-PROVENANCE.json').read_text());atlases={};aliases={}
 a,rolls=grid('rolls',2,6)
 # Manually reviewed skull widths in source pixels; constant across each clip.
 for row,hero,span in [(0,'aion',185),(1,'sheep',200)]:
  base=pixel['atlases']['pixel-'+hero];factor=base['head_spans'][0]*base['scale'][0]/span;rolls['scale'][row]=factor
  for f in rolls['frames'][row]:f['registration']='shoulder-and-ground'
 rolls['head_spans']=[185,200];atlases['polish-rolls']=rolls
 aliases['rolls']=[{'atlas':'polish-rolls','row':0},None,{'atlas':'polish-rolls','row':1},None,None,None]
 a,abilities=grid('abilities',4,6)
 (ROOT/'build/polish-review').mkdir(parents=True,exist_ok=True)
 for row in [0,2]:Image.fromarray(isolated(a,abilities['frames'][row][0])).save(ROOT/'build/polish-review'/('ability-neutral-'+str(row)+'.png'))
 # Explicitly reviewed face landmarks, not an iris colour centroid.
 owl=pixel['atlases']['pixel-owl'];eren=pixel['atlases']['pixel-eren']
 owl_factor=owl['head_spans'][0]*owl['scale'][0]/102
 eren_factor=eren['head_spans'][0]*eren['scale'][0]/101
 face_rows(a,abilities,[0,1],[177,104],owl['target_eye'],owl_factor)
 face_rows(a,abilities,[2,3],[170,101],eren['target_eye'],eren_factor)
 # Reviewed forward-paw centers in ORIGINAL source coordinates. The pistol
 # attaches to the hand, not to a previous drawing's body-relative position.
 grips={2:[(186,682),(435,682),(689,678),(937,680),(1195,686),(1451,699)],3:[(196,946),(451,909),(710,881),(952,868),(1201,902),(1451,945)]}
 for row,points in grips.items():
  for f,(x,y) in zip(abilities['frames'][row],points):f['weapon_grip']=[x-f['rect'][0],y-f['rect'][1]]
 abilities['head_spans']=[102,102,101,101]
 for f in abilities['frames'][2]:f['origin'][1]=float(f['body_bounds'][3]);f['ground_contact']=True;f['registration']='face-x-and-planted-shoes'
 atlases['polish-abilities']=abilities
 aliases['runner-owl']=[None]*8;aliases['runner-owl'][6]={'atlas':'polish-abilities','row':0}
 aliases['owl-flap']=[{'atlas':'polish-abilities','row':1}]
 aliases['runner-eren']=[None]*8;aliases['runner-eren'][6]={'atlas':'polish-abilities','row':2};aliases['runner-eren'][2]={'atlas':'polish-abilities','row':3}
 a,enemies=grid('enemies',6,6)
 factor=78/(enemies['width']/6)
 face_rows(a,enemies,[0,1],[62,129],[-8,-6],factor)
 for row in [2,3,4,5]:enemies['scale'][row]=factor
 for f in enemies['frames'][2]:f['ground_contact']=False;f['registration']='defeat-body'
 enemies['head_spans']=[1]*6;atlases['polish-enemies']=enemies;aliases['enemies']=[{'atlas':'polish-enemies','row':i} for i in range(6)]
 a,items=grid('pickups',3,6)
 for row in range(3):
  items['scale'][row]=40/(items['width']/6)
  for f in items['frames'][row]:
   b=f['bounds'];f['origin']=[(b[0]+b[2])/2,(b[1]+b[3])/2];f['registration']='collectible-center';f['ground_contact']=False
 atlases['polish-pickups']=items;aliases['pickups']=[{'atlas':'polish-pickups','row':i} for i in range(3)]
 data={'version':'0.22.0','method':'Source PNGs unchanged; actual alpha gutters and isolated spans; calibrated constant source scales; grounded foot/root anchors separate from airborne body landmarks. Original model references are private, not redistributed.','generation_sources':{'abilities':'5e373fce-2e48-4ab9-a978-121e21ea7545','rolls':'1de687a1-50d0-4ea9-86e4-99cda2ae9dbb','enemies':'b9ef5767-4943-4e63-b0c9-04dae2016f64','pickups':'d0ac6809-131d-46fb-9547-5092903b6b6e'},'atlases':atlases,'aliases':aliases,'pickup_order':['banana','apple','pear','apricot','grapes','orange','cherries','peach','mushroom','lightning','slow','haste','shield','magnet','leaf','spring','fortune','frost']}
 (ROOT/'assets/POLISH-PROVENANCE.json').write_text(json.dumps(data,separators=(',',':'))+'\n')
 print('Registered24 ability,12 roll,36 encounter and18 collectible source poses')
if __name__=='__main__':main()
