"""Register real drawn frames only. Read PNG alpha; never rewrite image artwork."""
from pathlib import Path
import hashlib,json,statistics
import numpy as np
from PIL import Image
from scipy.ndimage import label
ROOT=Path(__file__).resolve().parents[1]
SOURCES={
 'aion':('66f9db93-3582-4070-ab88-78fb139b44de',12,8),'owl':('ce1e1943-61bc-4284-8dd4-9fab98f5e6eb',12,9),
 'sheep':('805a078b-49a7-47bb-8b54-7e9b35bb5b15',12,8),'wolf':('70c5c34b-c2ce-45fc-b4fe-0416f83324c6',12,8),
 'world':('29d0bae0-7261-4f20-94d4-ee395e630e3b',11,11),'girls':('21237b16-f9c6-4db0-a79f-1eca05ac0e20',12,8),
 'rolls':('21f24791-36f9-43f1-96e4-7627405f5b19',12,4),'elements':('e4e35797-b0d1-4228-8a3a-a29b7fb5d454',12,12),
 'powers':('43c04ca8-cc57-4001-960c-9afc493d8257',12,10),'terrain':('4595ca2a-ed80-4549-b51c-aea88d2e49bc',12,6)}

def boundaries(a,n,axis):
 # Choose the actual transparent gutter nearest each nominal row boundary.
 v=(a[:,:,3]>=32).sum(axis=1 if axis=='y' else 0);length=len(v);step=length/n;result=[0]
 for i in range(1,n):
  nominal=round(i*step);lo=max(result[-1]+1,round(nominal-step*.32));hi=min(length-1,round(nominal+step*.32));part=v[lo:hi+1];low=np.where(part==part.min())[0]+lo
  groups=np.split(low,np.where(np.diff(low)>1)[0]+1);group=min(groups,key=lambda g:abs(float(g.mean())-nominal));result.append(int(round(float(group.mean()))))
 return result+[length]

atlases={}
for key,(origin,cols,rows) in SOURCES.items():
 path=ROOT/'assets'/('motion-'+key+'.png')
 if not path.exists():
  import shutil;shutil.copy2('/workspace/generated_images/exec-'+origin+'.png',path)
 a=np.array(Image.open(path).convert('RGBA'));h,w=a.shape[:2];xs=boundaries(a,cols,'x');ys=boundaries(a,rows,'y');frames=[];baselines=[];row_heights=[]
 assert cols>=10,'Animated atlases require >=10 actual drawn columns; never pad duplicate frames'
 for row in range(rows):
  line=[]
  for col in range(cols):
   cell=a[ys[row]:ys[row+1],xs[col]:xs[col+1]];mask=cell[:,:,3]>=32
   clean=key in ['aion','owl','sheep','wolf','rolls'] or key=='terrain'
   if clean:
    components,n=label(mask,np.ones((3,3)));sizes=np.bincount(components.ravel());sizes[0]=0;mask=components==sizes.argmax()
   yy,xx=np.where(mask);assert len(xx)>20,(key,row,col)
   b=[int(xx.min()),int(yy.min()),int(xx.max())+1,int(yy.max())+1];runs=[]
   for y in range(b[1],b[3]):
    edges=np.diff(np.pad(mask[y].astype(np.int8),(1,1)));beg=np.where(edges==1)[0];end=np.where(edges==-1)[0]
    runs.extend([[y,int(x),int(z-x)] for x,z in zip(beg,end)])
   line.append({'rect':[xs[col],ys[row],xs[col+1]-xs[col],ys[row+1]-ys[row]],'bounds':b,'runs':runs,'anchor_x':w/cols*(col+0.5)-xs[col]})
  frames.append(line);baselines.append(statistics.median(f['bounds'][3] for f in line));row_heights.append(statistics.median(f['bounds'][3]-f['bounds'][1] for f in line))
 factor=82.0/row_heights[0] if key in ['aion','owl','sheep','wolf'] else 1.0
 if key=='girls':factor=108.0/row_heights[0]
 scales=[factor]*rows;heads=[(70.0 if key=='aion' else 65.0)/factor]*rows if key in ['aion','owl','sheep','wolf'] else None
 if key=='elements':
  scales=[82.0/row_heights[(r//3)*3] for r in range(rows)]
  heads=[(70.0 if r<3 else 65.0)/scales[r] for r in range(rows)]
 if key=='rolls':heads=[0.0]*rows
 d={'path':str(path.relative_to(ROOT)),'generation_source':'exec-'+origin+'.png','sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'width':w,'height':h,'columns':cols,'rows':rows,'x':xs,'y':ys,'frames':frames,'baselines':baselines,'reference_height':row_heights,'scale':scales,'anchor_x':[(xs[1]-xs[0])*0.5]*rows}
 if heads:d['head_spans']=heads
 atlases['motion-'+key]=d
 print(key,cols,rows,'drawn frames',cols*rows)
# Historical parkour art is still used only for static ground props/pit rims.
legacy=json.loads((ROOT/'assets/FRONTIER-PROVENANCE.json').read_text())['atlases']['parkour'];atlases['parkour']=legacy
aliases={}
def alias(name,pairs):aliases[name]=[{'atlas':'motion-'+key,'row':row} for key,row in pairs]
order=['aion','owl','sheep','wolf']
for i,hero in enumerate(order):alias('runner-'+hero,[(hero,0),(hero,1),(hero,2),('elements',i*3),('elements',i*3+1),('elements',i*3+2),(hero,6),(hero,2)])
alias('actions',[('wolf',6),('owl',6),('sheep',2)])
alias('strikes',[(hero,row) for hero in order for row in [4,5]])
alias('rolls',[('rolls',i) for i in range(4)])
alias('heroes',[(hero,7) for hero in order])
alias('owl-peck',[('owl',8)])
alias('celebrants',[('girls',i) for i in range(8)])
alias('enemies',[('world',i) for i in range(6)])
alias('boss',[('world',6),('world',7),('world',8),('world',9),('powers',9),('world',10)])
alias('power',[('powers',i) for i in range(10)])
alias('hazards',[('powers',7),('powers',8)])
alias('boost-pads',[('terrain',i) for i in range(4)])
alias('carriers',[('terrain',4),('terrain',5)])
meta={'method':'Original generated PNGs unchanged. Real gutters and >=10 drawn animation frames per atlas, connected primary silhouettes, two-pixel isolated runtime textures, one common character scale per atlas. Static ground props remain static. Runtime frame counts come from this registry; never fill gaps by duplicate or blended frames.','version':'0.9.0','new_drawn_frames':sum(c*r for _,c,r in SOURCES.values()),'minimum_animated_columns':10,'atlases':atlases,'aliases':aliases}
(ROOT/'assets/MOTION-PROVENANCE.json').write_text(json.dumps(meta,separators=(',',':'))+'\n')
print('NEW DRAWN FRAMES:',meta['new_drawn_frames'])
