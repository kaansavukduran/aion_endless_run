"""Read opacity components to register source art; never modify image bytes."""
from PIL import Image
from pathlib import Path
import json,hashlib
full=json.loads(Path('assets/FULL-RUNNER-PROVENANCE.json').read_text());action=json.loads(Path('assets/ACTION-PROVENANCE.json').read_text());combat=json.loads(Path('assets/ADVENTURE-PROVENANCE.json').read_text())['atlases']['combat']
def component_box(im):
 mask=im.getchannel('A');w,h=mask.size;pixels=mask.tobytes();seen=bytearray(w*h);best=[]
 for n,a in enumerate(pixels):
  if a<32 or seen[n]:continue
  seen[n]=1;q=[n];component=[]
  while q:
   i=q.pop();component.append(i);x=i%w;y=i//w
   for v in ([i-1] if x else [])+([i+1] if x+1<w else [])+([i-w] if y else [])+([i+w] if y+1<h else []):
    if not seen[v] and pixels[v]>=32:seen[v]=1;q.append(v)
  if len(component)>len(best):best=component
 assert best
 xs=[i%w for i in best];ys=[i//w for i in best]
 return [min(xs),min(ys),max(xs)+1,max(ys)+1]
def register(path,ys):
 im=Image.open(path);rows=[]
 for r in range(len(ys)-1):
  rows.append([component_box(im.crop((round(f*im.width/6),ys[r],round((f+1)*im.width/6),ys[r+1]))) for f in range(6)])
 return {'sha256':hashlib.sha256(Path(path).read_bytes()).hexdigest(),'bounds':rows}
m={'method':'Largest connected alpha>=32 component, using original atlas row boundaries; PNG files remain byte-for-byte unchanged. Active upright poses target 90 logical pixels; wings/limbs keep original proportions. Freeze/fire/ash preserve source effects; crouch is intentionally lower.','normal_height':90,'follower_ratio':0.72,'runner':{},'actions':register('assets/companion-actions.png',[round(i*action['height']/3) for i in range(4)]),'combat':register('assets/adventure-combat.png',combat['row_y'])}
for id,d in full['characters'].items():m['runner'][id]=register('assets/'+id+'-runner.png',d['row_y'])
Path('assets/SPRITE-REGISTRATION.json').write_text(json.dumps(m,indent=2)+'\n')
print('Registered',sum(len(r) for d in m['runner'].values() for r in d['bounds'])+18+48,'unmodified source frames')
