"""Register imagegen-redrawn empty fingers, without erasing or redrawing hand pixels in code."""
import copy
from pathlib import Path
import numpy as np
from PIL import Image
from register_m1_heroes import grid,isolated
from campaign_registration import match_patch
R=Path(__file__).resolve().parents[1]
GEN={'aion':'25ce238e-fe4c-4ef0-adff-32dfe2f4e587','sheep':'417a9738-4a04-4f56-8208-726fb8f46767','rabbit':'21e1fe5e-f79f-47ee-acb9-b616f91807a0','eren':'f525133f-5ba4-451b-a47c-0e5405474c4d'}

def register_empty_hands(D):
 for hero,uid in GEN.items():
  path=R/f'assets/m1-empty-actions-{hero}.png'
  a,d=grid(path,3);old=D['atlases'][hero];oa=np.asarray(Image.open(R/old['path']).convert('RGBA'))
  for col in [1,2]:
   f=d['frames'][2][col];of=old['frames'][2][col];oq=isolated(oa,of);x,y,w,h=of['face_patch'];patch=oq[y:y+h,x:x+w];local=np.array(of['face_landmark'])-[x,y];b=f['body_bounds'];ob=of['body_bounds'];q=isolated(a,f)
   fx,fy,error=match_patch(q,patch,[b[0]+x-ob[0],b[1]+y-ob[1]],[25,25]);face=np.array([fx,fy])+local;scale=of['scale'];delta=np.array(of['grip'])-of['face_landmark']
   if col==2 and hero in ['aion','sheep']:delta=np.array([-73,10] if hero=='aion' else [-76,-10])
   grip=face+delta
   f.update(origin=[float(face[0]-14./scale),float(b[3])],face_landmark=face.tolist(),face_patch=[fx,fy,w,h],face_residual=error,grip=grip.tolist(),scale=scale,ground_contact=True,registration='original-face-template-same-source-scale-and-sole',grenade_embedded=False)
  d['calibration']=copy.deepcopy(old['calibration']);d['runtime_frames']={'grenade_throw':[1,2]};d['edit_scope']='Imagegen redrew empty fingers in standing cels1/2 only; only these two cels are runtime replacements. Backsteps and other throws keep original source.';D['atlases'][hero+'_empty']=d;D['generation_sources'][path.name]='exec-'+uid
 D.update(source_cells=192,source_drawings=128,edited_source_variations=8,duplicated_reference_cells=64,superseded_source_drawings=32)
 D['gun_contract']='Separate rotating gun uses grip_local and is suppressed throughout grenade throws. Every runtime body cel now has empty hands; a single shared grenade art layer is held until release. grenade_hand_local matches projectile event release.'
 return D
