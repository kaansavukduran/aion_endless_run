"""Register committed frame drawings, preserving original PNG bytes and debris.
Run at repository root. No image synthesis or source pixel replacement here.
"""
from pathlib import Path
import json,hashlib,sys
import numpy as np
from PIL import Image
sys.path.insert(0,str(Path(__file__).resolve().parent))
from register_pixel_heroes import cuts
ROOT=Path(__file__).resolve().parents[1]
references=json.loads((ROOT/'assets/CAMPAIGN-EFFECTS-REFERENCES.json').read_text())
output={'references':references,'license':'Owner-authorized AI-assisted original art based on existing game identities; original atlases retained.','banks':{}}
names=['crow','gnome','moth','slime','beetle','wisp','drone','seed','warden']
for name,nrows,ncols in [('checkpoint-flags',1,4),('legacy-deaths',9,6)]:
 path=ROOT/'assets'/f'{name}.png';a=np.array(Image.open(path).convert('RGBA'));mask=a[:,:,3]>=192;ys=cuts(mask.sum(1),nrows);rows=[];scales=[];origins=[]
 for row in range(nrows):
  strip=mask[ys[row]:ys[row+1]];xs=cuts(strip.sum(0),ncols);line=[];bounds=[]
  for col in range(ncols):
   x0,y0,x1,y1=xs[col],ys[row],xs[col+1],ys[row+1];m=mask[y0:y1,x0:x1];yy,xx=np.where(m);assert len(yy)>30,(name,row,col)
   b=[int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)];bounds.append(b);runs=[]
   for y in range(b[1],b[3]):
    z=np.diff(np.pad(m[y].astype(np.int8),(1,1)));runs.extend([[y,int(s),int(e-s)] for s,e in zip(np.where(z==1)[0],np.where(z==-1)[0])])
   line.append({'rect':[int(x0),int(y0),int(x1-x0),int(y1-y0)],'bounds':b,'runs':runs})
  scale=(100. if name=='checkpoint-flags' else references[names[row]]['height'])/(bounds[0][3]-bounds[0][1]);scales.append(scale)
  base_y=max(b[3] for b in bounds);base_x=(bounds[0][0]+bounds[0][2])*.5
  for f,b in zip(line,bounds):
   if name=='checkpoint-flags':
    x,y,w,h=f['rect'];m=mask[y:y+h,x:x+w];yy,xx=np.where(m & (np.arange(h)[:,None]>=b[3]-15));origin_x=(xx.min()+xx.max()+1)*.5;origin_y=b[3]
   else:origin_x=base_x;origin_y=base_y
   f['origin']=[float(origin_x),float(origin_y)]
  rows.append(line)
 output['banks'][name]={'path':f'assets/{name}.png','sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'frames':rows,'scales':scales}
output['generation']={'checkpoint-flags':'exec-1f7130b1-c37f-4c29-9d27-f8031b0b306b','legacy-deaths':'exec-25c77589-ac8d-47b7-9ee0-ba82f5a6935f'}
(ROOT/'assets/CAMPAIGN-EFFECTS.json').write_text(json.dumps(output,separators=(',',':'))+'\n')
print('Registered4flag frames and54legacy enemy death drawings; PNG bytes unchanged.')
