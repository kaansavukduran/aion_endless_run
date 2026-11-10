"""Read-only original sprite registration for combat/defeat. Never rewrites PNGs."""
from pathlib import Path
import hashlib,json,statistics,shutil
import numpy as np
from PIL import Image
from scipy.ndimage import label
ROOT=Path(__file__).resolve().parents[1]
old=json.loads((ROOT/'assets/MOTION-PROVENANCE.json').read_text())
specs={'weapons':('0f97237f-193c-4c7c-9116-320ba4cda586',12,8),'bosses':('996664ac-03ba-40dc-bdda-a95dd137a902',12,9),'defeats':('055eb7ec-bbbd-4767-bc7f-128d01d7fe4a',12,8)}
def boundaries(a,n,axis):
 v=(a[:,:,3]>=32).sum(axis=1 if axis=='y' else 0);length=len(v);step=length/n;result=[0]
 for i in range(1,n):
  nominal=round(i*step);lo=max(result[-1]+1,round(nominal-step*.32));hi=min(length-1,round(nominal+step*.32));part=v[lo:hi+1];low=np.where(part==part.min())[0]+lo;groups=np.split(low,np.where(np.diff(low)>1)[0]+1);group=min(groups,key=lambda g:abs(float(g.mean())-nominal));result.append(int(round(float(group.mean()))))
 return result+[length]
atlases={};muzzles={}
for key,(origin,cols,rows) in specs.items():
 path=ROOT/'assets'/('encounter-'+key+'.png');shutil.copy2('/workspace/generated_images/exec-'+origin+'.png',path)
 a=np.array(Image.open(path).convert('RGBA'));h,w=a.shape[:2];xs=boundaries(a,cols,'x');ys=boundaries(a,rows,'y');frames=[];baselines=[]
 for row in range(rows):
  line=[]
  for col in range(cols):
   cell=a[ys[row]:ys[row+1],xs[col]:xs[col+1]];mask=cell[:,:,3]>=32
   components,n=label(mask,np.ones((3,3)));sizes=np.bincount(components.ravel());sizes[0]=0;primary=components==sizes.argmax()
   # Bodies plus detached muzzle/defeat sparks stay in this cell only.
   if key=='weapons':mask=primary
   yy,xx=np.where(mask);assert len(xx)>20,(key,row,col)
   b=[int(xx.min()),int(yy.min()),int(xx.max())+1,int(yy.max())+1];runs=[]
   for y in range(b[1],b[3]):
    edges=np.diff(np.pad(mask[y].astype(np.int8),(1,1)));beg=np.where(edges==1)[0];end=np.where(edges==-1)[0];runs.extend([[y,int(x),int(z-x)] for x,z in zip(beg,end)])
   line.append({'rect':[xs[col],ys[row],xs[col+1]-xs[col],ys[row+1]-ys[row]],'bounds':b,'runs':runs,'anchor_x':w/cols*(col+.5)-xs[col],'anchor_y':h/rows*(row+.5)-ys[row]})
  frames.append(line);baselines.append(statistics.median(f['bounds'][3] for f in line))
 scales=[];heads=[]
 for row in range(rows):
  if key=='bosses':factor=1.;head=0
  else:
   hero=['aion','owl','sheep','wolf'][row//2];ref=old['atlases']['motion-'+hero];target=ref['reference_height'][1]*ref['scale'][1]
   first=frames[(row//2)*2];bodyheight=statistics.median(f['bounds'][3]-f['bounds'][1] for f in (first if key=='weapons' else first[:2]));factor=target/bodyheight;head=(70 if hero=='aion' else 65)/factor
  scales.append(factor);heads.append(head)
 if key=='weapons':
  for i,hero in enumerate(['aion','owl','sheep','wolf']):
   values=[]
   for col in range(cols):
    f=frames[i*2][col];x,y,cw,ch=f['rect'];cell=a[y:y+ch,x:x+cw];m=(cell[:,:,3]>150)&(cell[:,:,1]>120)&(cell[:,:,2]>120)&(cell[:,:,0]<140);m[:,:round(cw*.65)]=False
    yy,xx=np.where(m)
    if len(xx):
     right=xx.max();ym=statistics.median(yy[xx>=right-3]);values.append([(right-f['anchor_x'])*scales[i*2],(ym-f['bounds'][3])*scales[i*2]])
   muzzles[hero]=[round(statistics.median(v[n] for v in values),2) for n in [0,1]] if values else [48,-38]
 atlases['encounter-'+key]={'path':str(path.relative_to(ROOT)),'generation_source':'exec-'+origin+'.png','sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'width':w,'height':h,'columns':cols,'rows':rows,'frames':frames,'baselines':baselines,'scale':scales,'head_spans':heads,'anchor_x':[w/cols*.5]*rows}
aliases={'gun-run':[{'atlas':'encounter-weapons','row':i*2} for i in range(4)],'gun-fire':[{'atlas':'encounter-weapons','row':i*2+1} for i in range(4)],'deaths':[{'atlas':'encounter-defeats','row':i} for i in range(8)],'boss-designs':[{'atlas':'encounter-bosses','row':i} for i in range(9)]}
meta={'version':'0.10.0','method':'Original PNGs unchanged. Actual alpha gutters, isolated runtime textures, fixed pair scale, 12 physically drawn frames. Muzzle anchors measured from cyan barrels of aiming frames, never flash bounds.','new_drawn_frames':300,'atlases':atlases,'aliases':aliases,'muzzles':muzzles}
(ROOT/'assets/ENCOUNTERS-PROVENANCE.json').write_text(json.dumps(meta,separators=(',',':'))+'\n');print('Registered 300 original drawn frames; muzzle anchors',muzzles)
