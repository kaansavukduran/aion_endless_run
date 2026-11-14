"""Independent RGB template fit on actual Godot-rendered PNGs.
Only the first reference crop is located using registered model anatomy;
subsequent frame position is measured from rendered pixels, not pose metadata.
No PNGs are edited or resaved. Grounded stride may move vertically.
"""
import json,argparse
from pathlib import Path
import numpy as np
from PIL import Image
from scipy.signal import fftconvolve
parser=argparse.ArgumentParser();parser.add_argument('--renders',type=Path,default=Path('build/polish-scenes'));parser.add_argument('--output',type=Path,default=Path('build/rendered-face-review.json'));args=parser.parse_args();r=Path(__file__).resolve().parents[1];m=json.loads((r/'assets/PIXEL-HEROES-PROVENANCE.json').read_text());report=[]
for hero in ['aion','sheep','owl','wolf','rabbit','eren']:
 a=m['atlases']['pixel-'+hero];f=a['frames'][3][0];scale=a['scale'][3]
 x=round(288+(f['head_probe'][0]-f['origin'][0])*scale);y=round(534+(f['head_probe'][1]-f['origin'][1])*scale);w=round(43*scale);h=round(38*scale)
 im=np.array(Image.open(args.renders/f'{hero}-run-0.png').convert('RGB'),dtype=float)/255;t=im[y:y+h,x:x+w];frames=[]
 for i in range(6):
  im=np.array(Image.open(args.renders/f'{hero}-run-{i}.png').convert('RGB'),dtype=float)/255;q=im[y-24:y+h+24,x-12:x+w+12]
  s=fftconvolve((q*q).sum(2),np.ones(t.shape[:2]),mode='valid');cross=sum(fftconvolve(q[:,:,c],t[::-1,::-1,c],mode='valid') for c in range(3));ssd=np.maximum(0,s+(t*t).sum()-2*cross);yy,xx=np.unravel_index(np.argmin(ssd),ssd.shape)
  frames.append({'frame':i,'pixel_dx':int(xx)-12,'pixel_dy':int(yy)-24,'normalized_error':float(ssd[yy,xx]/(t*t).sum())})
 report.append({'hero':hero,'reference_rect':[x,y,w,h],'frames':frames,'horizontal_pixel_range':max(f['pixel_dx'] for f in frames)-min(f['pixel_dx'] for f in frames)})
print(json.dumps(report,indent=2));args.output.parent.mkdir(parents=True,exist_ok=True);args.output.write_text(json.dumps({'scope':'Six actual native rendered run frames each; independent RGB crop matching, separate from world/probe metadata. Not a physical-device test. Natural blinking and subpixel rasterization change the best fit by a pixel.','characters':report},indent=2)+'\n')

assert all(item["horizontal_pixel_range"]<=1 for item in report),"Rendered face drift exceeds the fixed-viewport one-pixel raster tolerance"
print("PASS:36 actual rendered frames; every hero stays within one native pixel horizontally")
