"""Derivative vehicle anchors. Original PNGs and old registration remain unchanged."""
from pathlib import Path
import json,hashlib,copy
import numpy as np
from PIL import Image,ImageDraw
from scipy.ndimage import label
from register_pixel_heroes import isolated
from campaign_registration import match_patch
ROOT=Path(__file__).resolve().parents[1]
CAT=json.loads((ROOT/'assets/CAMPAIGN-EXPANSION-PROVENANCE.json').read_text())['atlases']['vehicles']
OLD=json.loads((ROOT/'assets/ARCADE-MACHINES-PROVENANCE.json').read_text());OLD['path']=OLD['source']
HERO=json.loads((ROOT/'assets/PIXEL-HEROES-PROVENANCE.json').read_text())['atlases']['pixel-aion']
HF=HERO['frames'][3][0];REFERENCE_HEIGHT=(HF['body_bounds'][3]-HF['body_bounds'][1])*HERO['scale'][3]
SPECS={
 'shell':(CAT,[0,1,2,3],[27,83,28,27],82.,[130.,99.],[109.,99.]),
 'wind':(CAT,[4,5,6,7],[69,55,24,20],82.,[138.,87.],[108.,87.]),
 'drill':(CAT,[8,9,10,11],[23,54,25,26],77.,[133.,77.],[100.,77.]),
 'skimmer':(OLD,[4,5],[65,109,27,23],83.,[153.,109.],[130.,109.]),
}

def body_bounds(q):
 ls,n=label(q[:,:,3]>=192,np.ones((3,3)));sizes=np.bincount(ls.ravel());sizes[0]=0;yy,xx=np.where(ls==sizes.argmax());return [int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)]

def cyan_collar(q,expected):
 rgb=q[:,:,:3].astype(float);mask=(q[:,:,3]>=192)&(rgb[:,:,0]<180)&(rgb[:,:,1]>65)&(rgb[:,:,2]>70)&(rgb[:,:,1]>rgb[:,:,0]*1.1)&(rgb[:,:,2]>rgb[:,:,0]*1.05)
 ls,n=label(mask,np.ones((3,3)));best=None
 for k in range(1,n+1):
  yy,xx=np.where(ls==k)
  if len(xx)<7:continue
  cx,cy=float(np.mean(xx)),float(np.mean(yy))
  if abs(cx-expected[0])>18 or abs(cy-expected[1])>22:continue
  score=(cx-expected[0])**2+(cy-expected[1])**2
  if best is None or score<best[0]:best=(score,[cx,cy])
 return None if best is None else best[1]

def main():
 result={}
 out=ROOT/'build/forge-vehicle-review';out.mkdir(exist_ok=True,parents=True)
 for kind,(atlas,rows,patch,root_x,muzzle,pivot) in SPECS.items():
  raw=np.array(Image.open(ROOT/atlas['path']).convert('RGBA'));ref=atlas['frames'][rows[0]][0];q=isolated(raw,ref);bb=body_bounds(q)
  px,py,pw,ph=patch;t=q[py:py+ph,px:px+pw].copy();neutral_floor=float(bb[3]);neutral_height=float(bb[3]-bb[1]);factor=2*REFERENCE_HEIGHT/neutral_height
  mx,my=muzzle;barrel=q[int(my)-10:int(my)+10,int(mx)-13:int(mx)+5].copy();assert barrel.shape[:2]==(20,18)
  frames=[];can=Image.new('RGBA',(6*240,len(rows)*230),(35,29,40,255));draw=ImageDraw.Draw(can)
  for phase,row in enumerate(rows):
   line=[]
   for col,original in enumerate(atlas['frames'][row]):
    f=copy.deepcopy(original);q=isolated(raw,f);body=body_bounds(q)
    expected=[px+ref['rect'][0]+col*atlas['dimensions'][0]/6-f['rect'][0],py+float(body[3]-bb[3])]
    xx,yy,error=match_patch(q,t,expected,[22,22]);dx,dy=xx-px,yy-py
    if phase==3:
     # Collapsed/debris drawings retain authored source root and real wreck floor.
     origin_x=root_x+ref['rect'][0]+col*atlas['dimensions'][0]/6-f['rect'][0];floor=float(body[3]);registration='authored-wreck-cell-root'
    else:
     origin_x=root_x+dx;floor=float(body[3]);registration='distinct-hull-core-and-connected-support'
    point=[mx+dx,my+dy];piv=[pivot[0]+dx,pivot[1]+dy]
    berror=0.;muzzle_method='fixed neutral front tip tracked by distinct body core'
    if phase<3 and kind in ['shell','skimmer'] and not (phase==0 and col==0):
     found=cyan_collar(q,point)
     if found is not None:point=found;muzzle_method='bounded front cyan collar component; hull glass and flash excluded by expected window'
    if kind=='skimmer' and phase==1:
     # Review of each actual cyan endcap: the luminous hull is not the muzzle.
     point=[[153.,109.],[158.,96.],[162.,86.],[160.,78.],[150.,101.],[160.,104.]][col]
     muzzle_method='manually reviewed deployed front cannon rim, excluding the large side glass and star flash'
    piv[1]=point[1] # Neutral straight barrel axis passes through the measured tip.
    f.update(origin=[float(origin_x),float(floor)],body_bounds=body,body_probe=[xx,yy,pw,ph],body_landmark=[xx+pw*.5,yy+ph*.5],body_residual=round(error,6),muzzle=point,barrel_pivot=piv,barrel_residual=round(berror,6),muzzle_method=muzzle_method,registration=registration,scale=factor,ground_contact=True)
    line.append(f)
    im=Image.fromarray(q);im=im.resize((round(im.width*factor),round(im.height*factor)),Image.Resampling.NEAREST);ox=col*240+105-origin_x*factor;oy=phase*230+210-floor*factor;can.alpha_composite(im,(round(ox),round(oy)));draw.line((col*240,phase*230+210,col*240+240,phase*230+210),fill=(140,120,100))
    for point2,color in [(point,(255,40,20)),(piv,(60,240,80))]:
     x=ox+point2[0]*factor;y=oy+point2[1]*factor;draw.ellipse((x-3,y-3,x+3,y+3),outline=color,width=2)
    draw.text((col*240+5,phase*230+5),f'{kind}:{phase}/{col}',fill='white')
   frames.append(line)
  can.save(out/(kind+'-registered.png'))
  result[kind]={'path':atlas['path'],'sha256':hashlib.sha256((ROOT/atlas['path']).read_bytes()).hexdigest(),'source_rows':rows,'frames':frames,'source_reference_height':neutral_height,'scale':factor,'target_height':2*REFERENCE_HEIGHT,'neutral_root':[root_x,neutral_floor],'neutral_body_probe':patch,'clip_count':len(rows),'method':'Neutral authored cockpit-root X tracked by a distinct rear wheel/gem/hull stripe patch, never armed bbox centre; fixed type scale; intact hull support follows core Y; wreck uses actual connected-floor and fixed atlas root. Front muzzle is a bounded collar/endcap match; distinct drill tip is body-relative.'}
  print(kind,'scale',factor,'neutral muzzle-from-floor',[(muzzle[0]-root_x)*factor,(muzzle[1]-neutral_floor)*factor],'phases',len(rows))
 data={'version':1,'aion_reference_height':REFERENCE_HEIGHT,'target_height':2*REFERENCE_HEIGHT,'source_status':'Derived measurement metadata only; original images and old manifests unchanged. No new drawing counted.','types':result,'legacy_skimmer_limit':'Only original hover/cannon rows exist; damage/wreck requests resolve to hover rather than inventing death poses.'}
 (ROOT/'assets/FORGE-VEHICLES-PROVENANCE.json').write_text(json.dumps(data,separators=(',',':'))+'\n')
if __name__=='__main__':main()
