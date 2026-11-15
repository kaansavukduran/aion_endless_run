"""Register real grips/emitters and omit pickup-only props from held silhouettes.

Source PNG and ForgeItemBank pickup illustrations remain byte-for-byte intact.
UVs refer to the original unpadded registered bounds, not resized world art.
"""
from pathlib import Path
from collections import deque
import hashlib,json
import numpy as np
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'assets/forge-items.png'
META=json.loads((ROOT/'assets/FORGE-ITEMS-PROVENANCE.json').read_text())
SOCKETS={
'pistol':[.72,.80,.03,.25], 'heavy':[.20,.70,.98,.45],
'scatter':[.32,.48,.95,.22], 'arc':[.27,.70,.96,.35],
'beam':[.22,.72,.95,.38], 'disc':[.30,.67,.69,.43],
'harpoon':[.13,.73,.98,.30], 'seeker':[.39,.76,.975,.245],
'spore':[.11,.83,.695,.45], 'trap':[.39,.76,.975,.245], 'nova':[.26,.80,.97,.46]}
NOTES={
'pistol':'Authored LEFT: blue pressure lens is the forward emitter; narrow right cylinder is the rear pump. Grip is the angled wooden rear handle. Canonical held art mirrors BOTH pixels and sockets.',
'heavy':'Wooden pistol grip below rear housing; central forward rotary barrel opening.',
'scatter':'Wooden stock neck behind trigger guard, not the hanging lantern. Forward lower barrel port; detached ammunition shells omitted only while held.',
'arc':'Wooden pistol handle left of lower energy chamber, not the gap beside that chamber. Open copper nozzle at right.',
'beam':'Stock neck behind trigger guard; forward illuminated lens opening.',
'disc':'Solid lower crescent stock; right-facing blue/copper barrel opening, not the detached demonstration disc. Flying disc omitted while held.',
'harpoon':'Wooden pistol grip on lower left, not the hanging pendant cord. Actual arrowhead nose at upper right, not the transparent area below it.',
'seeker':'Wooden pistol handle; actual forward green loaded launcher nose.',
'spore':'Lower-left loop handle outer tube; actual nozzle aperture. External example purple plume is omitted, aperture glow and copper rim retained.',
 'trap':'Pickup remains original trap/puck. Held display uses the existing seeker launcher chassis to launch the walking spider; the puck has no barrel or hand grip.',
'nova':'Wooden pistol grip; actual forward pink lens opening.'}
# These regions remove examples/FX outside the physical barrel silhouette.
REMOVE={
 'disc':[(.70,.30),(1.,.20),(1.,.55),(.69,.55),(.71,.48),(.712,.41),(.70,.36)],
 'spore':[(.765,.18),(1.,.18),(1.,.62),(.75,.60),(.73,.52),(.715,.49),(.705,.47),(.705,.43),(.73,.40),(.75,.35)]}
def isolated(raw,f):
 b=f['bounds'];q=np.zeros((b[3]-b[1]+4,b[2]-b[0]+4,4),np.uint8)
 for y,x,n in f['runs']:q[y-b[1]+2,x-b[0]+2:x-b[0]+2+n]=raw[f['rect'][1]+y,f['rect'][0]+x:f['rect'][0]+x+n]
 return q
def largest_component(mask):
 seen=np.zeros_like(mask);components=[];height,width=mask.shape
 for y,x in zip(*np.where(mask)):
  if seen[y,x]:continue
  todo=deque([(y,x)]);seen[y,x]=True;component=[]
  while todo:
   yy,xx=todo.popleft();component.append((yy,xx))
   for dy in [-1,0,1]:
    for dx in [-1,0,1]:
     ny,nx=yy+dy,xx+dx
     if 0<=ny<height and 0<=nx<width and mask[ny,nx] and not seen[ny,nx]:seen[ny,nx]=True;todo.append((ny,nx))
  components.append(component)
 result=np.zeros_like(mask)
 for y,x in max(components,key=len):result[y,x]=True
 return result
def runs(mask):
 result=[]
 for y,row in enumerate(mask):
  starts=np.flatnonzero(np.diff(np.r_[False,row,False].astype(np.int8))==1)
  ends=np.flatnonzero(np.diff(np.r_[False,row,False].astype(np.int8))==-1)
  result.extend([[y,int(x),int(z-x)] for x,z in zip(starts,ends)])
 return result
raw=np.array(Image.open(SOURCE).convert('RGBA'));out={};review=ROOT/'build/m1-held-weapons';review.mkdir(parents=True,exist_ok=True)
for kind,uv in SOCKETS.items():
 display='seeker' if kind=='trap' else kind;f=META['frames'][display];q=isolated(raw,f);h,w=q.shape[:2];keep=q[:,:,3]>0
 if kind=='scatter':keep=largest_component(keep)
 polygon=REMOVE.get(kind)
 if polygon:
  mask=Image.new('1',(w,h));ImageDraw.Draw(mask).polygon([(2+(w-4)*x,2+(h-4)*y) for x,y in polygon],fill=1);keep&=~np.array(mask,dtype=bool)
 cleaned=q.copy();cleaned[~keep]=0
 grip=[2+(w-4)*uv[0],2+(h-4)*uv[1]];muzzle=[2+(w-4)*uv[2],2+(h-4)*uv[3]]
 for name,point in [('grip',grip),('muzzle',muzzle)]:
  px,py=map(round,point);assert cleaned[py,px,3]>=200,(kind,name,point,cleaned[py,px].tolist())
 out[kind]={'display_source':display,'source_facing':-1 if kind=='pistol' else 1,'canvas_size':[w,h],'grip_uv':uv[:2],'muzzle_uv':uv[2:],'grip_pixel':grip,'muzzle_pixel':muzzle,'grip_atlas_pixel':[grip[0]-2+f['bounds'][0]+f['rect'][0],grip[1]-2+f['bounds'][1]+f['rect'][1]],'muzzle_atlas_pixel':[muzzle[0]-2+f['bounds'][0]+f['rect'][0],muzzle[1]-2+f['bounds'][1]+f['rect'][1]],'keep_runs':runs(keep) if kind in ['scatter','disc','spore'] else [],'omitted_pixels':int(np.count_nonzero(q[:,:,3]))-int(np.count_nonzero(cleaned[:,:,3])),'note':NOTES[kind]}
 im=Image.fromarray(cleaned);im.save(review/(kind+'-held.png'))
 # Diagnostic labels only, never modifies runtime source PNG.
 if kind=='pistol':im=im.transpose(Image.Transpose.FLIP_LEFT_RIGHT);grip=[w-1-grip[0],grip[1]];muzzle=[w-1-muzzle[0],muzzle[1]]
 im=im.resize((w*2,h*2),Image.Resampling.NEAREST);bg=Image.new('RGBA',im.size,(35,33,39,255));bg.alpha_composite(im);draw=ImageDraw.Draw(bg)
 for point,color in [(grip,'lime'),(muzzle,'red')]:x,y=[v*2 for v in point];draw.ellipse((x-4,y-4,x+4,y+4),outline=color,width=2)
 bg.save(review/(kind+'-sockets.png'))
manifest={'version':1,'source_path':'assets/forge-items.png','source_sha256':hashlib.sha256(SOURCE.read_bytes()).hexdigest(),'coordinates':'Source socket UV inside original unpadded registered bounds; pixel coordinates include the two-pixel transparent gutter. Held cleanup preserves full source canvas. Pistol is mirrored only after cleanup. All other source drawings point right.','weapons':out}
(ROOT/'assets/M1-HELD-WEAPONS.json').write_text(json.dumps(manifest,separators=(',',':'))+'\n')
print('Registered held weapon silhouettes:',len(out),'omitted pickup-only pixels:',{k:v['omitted_pixels'] for k,v in out.items() if v['omitted_pixels']})
