"""Register newly drawn backstep and throw cels without modifying source PNGs.

Only connected silhouette runs and measured registration data are generated.
Scale is fitted once from the existing anatomical face, never per frame.
"""
import hashlib,json
from pathlib import Path
import numpy as np
from PIL import Image
from register_m1_heroes import grid,isolated
from campaign_registration import match_patch
ROOT=Path(__file__).resolve().parents[1]
OLD=json.loads((ROOT/'assets/M1-HEROES-PROVENANCE.json').read_text())
ACTIONS=['walk_back','crouch_walk_back','grenade_throw','crouch_grenade_throw']
GEN={'aion':'759389f6-cd48-4a81-b560-e8709be38119','sheep':'69b0fbd9-9273-41f4-bf38-347b049e8414','rabbit':'ddb09219-3e80-4f85-b727-dcca408756be','eren':'797a5f0c-b793-4fa1-92c2-c65ec3f79fd1'}
# Reviewed source-local neutral eye and knuckle centers, not iris-color searches.
NEUTRAL={'aion':(184,121,211,184),'sheep':(174,135,193,192),'rabbit':(198,113,211,187),'eren':(190,114,213,177)}
THROW_HAND={'aion':[(27,63),(-83,30),(-93,-10),(62,32),(25,57),(27,63)],'sheep':[(19,57),(-59,17),(-105,-42),(42,28),(42,71),(19,57)],'rabbit':[(13,74),(-79,36),(-107,-15),(66,4),(25,72),(13,74)],'eren':[(23,63),(-90,23),(-96,-16),(49,27),(31,83),(23,63)]}

CROUCH_GEN={'aion':'252738dc-e9e0-478f-833c-f676760ead00','sheep':'1d043b29-8bca-4ee6-bca3-35bd296b82fe','rabbit':'0db11a21-c5c3-4001-a515-caed205e44fc','eren':'a513c59a-07cf-4831-86ca-fee9cbb5ffeb'}
CROUCH_NEUTRAL={'aion':(237,183,250,246),'sheep':(225,204,228,261),'rabbit':(258,162,251,224),'eren':(264,162,259,236)}
CROUCH_HAND={'aion':[(13,63),(-58,44),(-102,-2),(70,44),(33,67),(13,63)],'sheep':[(3,57),(-80,25),(-90,-8),(78,25),(53,55),(3,57)],'rabbit':[(-7,62),(-75,35),(-125,-12),(60,30),(40,65),(-7,62)],'eren':[(-5,74),(-95,55),(-112,4),(60,40),(9,88),(-5,74)]}

def main():
 atlases={}
 for key in list(GEN)+[h+'_crouch' for h in GEN]:
  crouch=key.endswith('_crouch');hero=key.removesuffix('_crouch');rows=2 if crouch else 3
  p=ROOT/(f'assets/m1-low-actions-{hero}.png' if crouch else f'assets/m1-actions-{hero}.png');a,d=grid(p,rows)
  old=OLD['atlases'][hero];of=old['frames'][1][0];oa=np.asarray(Image.open(ROOT/old['path']).convert('RGBA'));oq=isolated(oa,of)
  x,y,w,h=of['face_patch'];template=oq[y:y+h,x:x+w];marker=np.array(of['face_landmark'])-[x,y]
  ex,ey,gx,gy=(CROUCH_NEUTRAL if crouch else NEUTRAL)[hero];neutral=d['frames'][1 if crouch else 2][0];nq=isolated(a,neutral);best=None
  for ratio in np.arange(.8,2.61,.01):
   patch=np.asarray(Image.fromarray(template).resize((round(w*ratio),round(h*ratio)),Image.Resampling.NEAREST))
   px,py,error=match_patch(nq,patch,[ex-marker[0]*ratio,ey-marker[1]*ratio],[15,15])
   if best is None or error<best[0]:best=(error,float(ratio),px,py,patch)
  err,ratio,px,py,oldfit=best;scale=of['scale']/ratio
  # New neutral full-face patch tracks translations, preserving new source pixels.
  patch=nq[py:py+oldfit.shape[0],px:px+oldfit.shape[1]].copy();local=np.array([ex-px,ey-py]);nb=neutral['body_bounds']
  for row,frames in enumerate(d['frames']):
   for col,f in enumerate(frames):
    b=f['body_bounds'];q=isolated(a,f);expected=[b[0]+px-nb[0],b[1]+py-nb[1]]
    fx,fy,error=match_patch(q,patch,expected,[65,65]);face=np.array([fx,fy])+local
    # Soles are inspected separately from tail, coat, ears, and halo extent.
    origin=[float(face[0]-14./scale),float(b[3])]
    hand_delta=np.array(CROUCH_HAND[hero][col] if crouch and row==1 else (THROW_HAND[hero][col] if not crouch and row==2 else [gx-ex,gy-ey]));grip=face+hand_delta
    f.update(origin=origin,face_landmark=face.tolist(),face_patch=[fx,fy,patch.shape[1],patch.shape[0]],face_residual=error,grip=grip.tolist(),scale=scale,ground_contact=True,registration='full-face-x-and-connected-sole',grenade_embedded=not crouch and row==2 and col in [1,2])
  d['calibration']={'source_scale':scale,'face_fit_ratio':ratio,'face_fit_error':err,'reference':old['path'],'same_scale_for_all_clips':True,'neutral_eye':[ex,ey],'neutral_hand':[gx,gy],'manual_throw_hand_deltas':(CROUCH_HAND if crouch else THROW_HAND)[hero]}
  atlases[key]=d
 data={'version':1,'status':'Owner-requested additional game animation art; AI-assisted new drawings; not final owner art approval or global canon update.','method':'New independent backstep/crouch-backstep and throw drawings; original approved PNG bytes preserved. Connected alpha>=192 body/halo runs with isolated gutters. One whole-face-calibrated scale per hero, anatomical X and actual connected sole Y registration.','actions':ACTIONS,'hero_keys':list(GEN),'source_drawings':120,'runtime_drawings':96,'superseded_source_drawings':24,'generation_sources':{**{f'm1-actions-{k}.png':f'exec-{v}' for k,v in GEN.items()},**{f'm1-low-actions-{k}.png':f'exec-{v}' for k,v in CROUCH_GEN.items()}},'atlases':atlases,'playback':{'walk_back':{'frames':6,'world_distance':132.,'loop':True,'direction':'actor remains aimed right while stepping left'},'crouch_walk_back':{'frames':6,'world_distance':94.,'loop':True},'grenade_throw':{'frames':6,'seconds':.42,'frame_starts':[0.,.04,.10,.16,.24,.33],'release_at':.16,'loop':False,'interrupt':'world owns cancel/pause/event; presentation never creates projectile'}},'gun_contract':'Separate rotating gun uses grip_local; grenade throw suppresses gun. Throw cels 1/2 contain held grenade and release cel3 is empty. grenade_hand_local records throw hand; event spawning belongs to CampaignGrenade.'}
 data['playback']['crouch_grenade_throw']=dict(data['playback']['grenade_throw'])
 from register_m1_empty_hands import register_empty_hands
 data=register_empty_hands(data)
 from register_m1_tunnel_actions import register_tunnel_actions
 data=register_tunnel_actions(data)
 output=ROOT/'assets/M1-HERO-ACTIONS.json';temporary=output.with_suffix('.tmp');temporary.write_text(json.dumps(data,separators=(',',':'))+'\n');temporary.replace(output)
 print('Registered',data['runtime_drawings'],'runtime cels',[(k,v['calibration']['source_scale'],v['calibration']['face_fit_ratio']) for k,v in atlases.items()])
if __name__=='__main__':main()
