"""Register Ayça's owner-requested damage states without rewriting source pixels.

The single neutral face fit calibrates one scale for all 24 drawings. Visible
faces share an anatomical X anchor; ground contact comes from the connected
sole/body, never transparent cell bounds. Ash has no fictional face marker.
"""
from pathlib import Path
import hashlib, json
import numpy as np
from PIL import Image
from campaign_registration import match_patch
from register_m1_heroes import grid, isolated

ROOT=Path(__file__).resolve().parents[1]
ACTIONS=['freeze','fire','impact','faceplant']
# Reviewed anatomical eye/closed-eye landmarks in the unmodified source PNG.
EYES=[
 [(173,92),(430,92),(684,92),(941,92),(1196,92),(1446,92)],
 [(173,351),(430,351),(686,374),(940,397),(1196,424),None],
 [(147,603),(408,623),(667,641),(919,658),(1199,697),(1447,714)],
 [(169,858),(425,876),(684,900),(936,934),(1196,966),(1444,984)],
]

def main():
 base=json.loads((ROOT/'assets/M1-HEROES-PROVENANCE.json').read_text())
 original=base['atlases']['rabbit'];neutral=original['frames'][1][0]
 original_pixels=np.array(Image.open(ROOT/original['path']).convert('RGBA'))
 image=isolated(original_pixels,neutral)
 px,py,pw,ph=neutral['face_patch'];patch=image[py:py+ph,px:px+pw]
 marker=np.array(neutral['face_landmark'])-[px,py]
 source=ROOT/'assets/m1-damage-ayca.png';pixels,atlas=grid(source,4)
 first=isolated(pixels,atlas['frames'][0][0]);best=None
 for ratio in np.linspace(.9,1.6,71):
  probe=np.array(Image.fromarray(patch).resize((round(pw*ratio),round(ph*ratio)),Image.Resampling.NEAREST))
  x,y,error=match_patch(first,probe,np.array(EYES[0][0])-marker*ratio,[18,18])
  if best is None or error<best[0]:best=(error,float(ratio),x,y,probe)
 error,ratio,x,y,probe=best
 scale=float(neutral['scale'])/ratio
 initial_eye=np.array([x,y])+marker*ratio
 # Freeze retains one face expression while its external shell grows. Track
 # the complete cheek/eye patch so shell width cannot cause horizontal drift.
 freeze_patch=first[y:y+probe.shape[0],x:x+probe.shape[1]].copy()
 freeze_marker=initial_eye-[x,y]
 for row,frames in enumerate(atlas['frames']):
  for column,f in enumerate(frames):
   rect=f['rect'];b=f['body_bounds'];point=EYES[row][column]
   visible=point is not None
   if visible:
    eye=np.array(point,dtype=float)-rect[:2]
    if row==0:
     xx,yy,fit=match_patch(isolated(pixels,f),freeze_patch,eye-freeze_marker,[14,14])
     eye=np.array([xx,yy])+freeze_marker
     f['face_fit_error']=float(fit)
    origin=[float(eye[0])-14./scale,float(b[3])]
    f['face_landmark']=[float(eye[0]),float(eye[1])]
   else:
    # Final ash mound uses the same actor anchor at the mound centre.
    origin=[float(b[0]+b[2])*.5,float(b[3])];f['face_landmark']=None
   f.update(origin=origin,scale=scale,ground_contact=True,face_visible=visible,registration='anatomical-face-x/connected-ground' if visible else 'ash-centre/connected-ground')
 atlas['source_scale']=scale
 atlas['calibration']={'reference_atlas':'m1-body-ayca','reference_row':1,'reference_column':0,'reference_face_patch':[px,py,pw,ph],'neutral_source_face_patch':[x,y,probe.shape[1],probe.shape[0]],'source_face_ratio':ratio,'source_fit_error':float(error),'one_scale_for_all_24_drawings':True,'world_head_size':float(pw)*float(neutral['scale']),'method':'One neutral whole-face fit; reviewed eye/closed-eye landmarks; six freeze faces tracked by the same complete patch. No per-frame rescaling.'}
 data={'version':1,'hero':'rabbit','name':'Ayça','actions':ACTIONS,'source_drawings':24,'runtime_drawings':24,'generation_source':'exec-7d5251d8-f832-4bb7-9a84-b021cb19b257','source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'identity_reference':'assets/m1-body-ayca.png','status':'User-requested feminine rabbit variant; existing source art remains unchanged. AI-assisted original damage drawings, not a global canon update.','method':'Unmodified generated RGBA PNG. Only registered alpha>=192 connected spans copied at runtime with two-pixel transparent gutters. Source scale fixed once; true contact baseline; no image rotation/squashing.','atlas':atlas}
 out=ROOT/'assets/M1-DAMAGE-PROVENANCE.json';tmp=out.with_suffix('.tmp');tmp.write_text(json.dumps(data,separators=(',',':'))+'\n');tmp.replace(out)
 print('Registered 24 Ayça damage poses; fixed source scale',scale,'face fit ratio',ratio,'error',error)

if __name__=='__main__':main()
