"""Register independently drawn compact tunnel anatomy; never resize source cels."""
from pathlib import Path
import json
import numpy as np
from PIL import Image
from register_m1_heroes import grid,isolated
from campaign_registration import match_patch
ROOT=Path(__file__).resolve().parents[1]
BASE=json.loads((ROOT/'assets/M1-HEROES-PROVENANCE.json').read_text())
GEN={'aion':'113aa4e4-19cc-462e-85e2-e1095a4b2bb3','sheep':'c253e156-f438-421c-a370-b51d1fd28631','rabbit':'3377a097-2763-4175-a41f-19bc3312cf68','eren':'dbded90c-86b0-4a64-92fa-b4f14d5bd1b4'}
NEUTRAL={'aion':(245,98,246,135),'sheep':(165,138,173,169),'rabbit':(198,113,190,159),'eren':(265,88,256,135)}
THROW={'aion':[(1,37),(-108,18),(-104,-19),(46,31),(18,40),(1,37)],'sheep':[(8,31),(-85,18),(-86,-8),(53,17),(30,32),(8,31)],'rabbit':[(-8,46),(-90,22),(-115,-8),(54,28),(28,58),(-8,46)],'eren':[(-9,47),(-145,26),(-145,-10),(38,27),(10,45),(-9,47)]}

def register_tunnel_actions(data):
 for hero in GEN:
  path=ROOT/f'assets/m1-tunnel-{hero}.png';a,d=grid(path,4)
  old=BASE['atlases'][hero];of=old['frames'][1][0];oa=np.asarray(Image.open(ROOT/old['path']).convert('RGBA'));oq=isolated(oa,of)
  x,y,w,h=of['face_patch'];template=oq[y:y+h,x:x+w];marker=np.array(of['face_landmark'])-[x,y]
  ex,ey,gx,gy=NEUTRAL[hero];neutral=d['frames'][3][0];nq=isolated(a,neutral);best=None
  for ratio in np.arange(.65,2.61,.01):
   patch=np.asarray(Image.fromarray(template).resize((round(w*ratio),round(h*ratio)),Image.Resampling.NEAREST))
   px,py,error=match_patch(nq,patch,[ex-marker[0]*ratio,ey-marker[1]*ratio],[12,12])
   if best is None or error<best[0]:best=(error,float(ratio),px,py,patch)
  err,ratio,px,py,fit=best;scale=of['scale']/ratio;patch=nq[py:py+fit.shape[0],px:px+fit.shape[1]].copy();local=np.array([ex-px,ey-py]);nb=neutral['body_bounds']
  heights=[]
  for row,frames in enumerate(d['frames']):
   for col,f in enumerate(frames):
    b=f['body_bounds'];q=isolated(a,f);fx,fy,error=match_patch(q,patch,[b[0]+px-nb[0],b[1]+py-nb[1]],[45,35]);face=np.array([fx,fy])+local
    origin=[float(face[0]-14./scale),float(b[3])];delta=np.array(THROW[hero][col] if row==2 else [gx-ex,gy-ey]);grip=face+delta
    f.update(origin=origin,face_landmark=face.tolist(),face_patch=[fx,fy,patch.shape[1],patch.shape[0]],face_residual=error,grip=grip.tolist(),scale=scale,ground_contact=True,registration='full-face-x-and-connected-sole-compact-anatomy',grenade_embedded=False)
    heights.append((origin[1]-f['bounds'][1])*scale)
  d['calibration']={'source_scale':scale,'face_fit_ratio':ratio,'face_fit_error':err,'reference':old['path'],'same_scale_for_all_clips':True,'neutral_eye':[ex,ey],'neutral_hand':[gx,gy],'throw_hand_deltas':THROW[hero],'max_visible_height':max(heights)}
  print('Tunnel',hero,'scale',scale,'height',max(heights))
  data['atlases'][hero+'_tunnel']=d;data['generation_sources'][path.name]='exec-'+GEN[hero]
 data['playback'].update({'tunnel_walk_back':{'frames':6,'world_distance':94.,'loop':True},'tunnel_walk':{'frames':6,'world_distance':110.,'loop':True},'tunnel_throw':dict(data['playback']['grenade_throw']),'tunnel_idle':{'frames':6,'seconds':.28,'loop':False}})
 data['tunnel_actions']=['tunnel_walk_back','tunnel_walk','tunnel_throw','tunnel_idle'];data['tunnel_rows']={a:i for i,a in enumerate(data['tunnel_actions'])};data.update(source_cells=288,source_drawings=224,runtime_drawings=192)
 return data

if __name__=='__main__':
 p=ROOT/'assets/M1-HERO-ACTIONS.json';d=register_tunnel_actions(json.loads(p.read_text()));q=p.with_suffix('.tmp');q.write_text(json.dumps(d,separators=(',',':'))+'\n');q.replace(p)
