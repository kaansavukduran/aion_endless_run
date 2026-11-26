"""Lossless per-row source strips for two proven first-use decode hotspots.

This is mechanical asset packing, not new artwork: every RGBA byte inside a
registered source rectangle survives unchanged. Source sheets remain intact.
"""
from pathlib import Path
import hashlib,json,re,struct
from io import BytesIO
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
OUTPUT=ROOT/'assets/campaign-row-sheets'

def digest(path):return hashlib.sha256(path.read_bytes()).hexdigest()

def runtime_pixels(source):
 """Preserve the RGBA the current import actually draws, including its codec.

 legacy-deaths uses an existing lossy WebP import. Cropping the original PNG
 would silently change those rendered colors. Decode its existing CTEX payload
 once, then store the exact resulting row RGBA losslessly; never re-encode lossy.
 """
 imported=(source.with_name(source.name+'.import')).read_text()
 match=re.search(r'^path="res://([^"]+\.ctex)"',imported,re.MULTILINE)
 if not match:raise RuntimeError('Import the source with Godot first: '+str(source))
 path=ROOT/match.group(1);data=path.read_bytes()
 if data[:4]!=b'GST2' or struct.unpack_from('<I',data,4)[0]>1:raise RuntimeError('Unsupported source CTEX: '+str(path))
 codec=struct.unpack_from('<I',data,36)[0];mipmaps=struct.unpack_from('<I',data,44)[0];size=struct.unpack_from('<I',data,52)[0]
 if codec not in [1,2] or mipmaps!=0:raise RuntimeError('Only current unmipped PNG/WebP imports are supported: '+str(path))
 pixels=Image.open(BytesIO(data[56:56+size])).convert('RGBA')
 return pixels,{'pixel_source':'Existing Godot imported RGBA, preserving the original import codec result; stored losslessly in the strips.','import_path':str(path.relative_to(ROOT)),'import_sha256':digest(path),'decoded_source_sha256':hashlib.sha256(pixels.tobytes()).hexdigest()}

def main():
 OUTPUT.mkdir(exist_ok=True)
 walking=json.loads((ROOT/'assets/KEEPERS-WALK-PROVENANCE.json').read_text())
 effects=json.loads((ROOT/'assets/CAMPAIGN-EFFECTS.json').read_text())['banks']['legacy-deaths']
 manifest={'version':1,'method':'Exact unscaled runtime RGBA row crops. Original source PNGs/imports, registered masks, rectangle coordinates and actor offsets are unchanged. Runtime loads only a requested row strip.','groups':{}}
 for key,atlas in [('keepers-walk',walking),('legacy-deaths',effects)]:
  source=ROOT/atlas['path'];image,import_info=runtime_pixels(source)
  rows=[]
  for row,frames in enumerate(atlas['frames']):
   # Only these registered runs are ever sampled. Crop their exact union,
   # retaining the original rect/mask coordinates through source_crop.
   left=min(f['rect'][0]+run[1] for f in frames for run in f['runs']);top=min(f['rect'][1]+run[0] for f in frames for run in f['runs'])
   right=max(f['rect'][0]+run[1]+run[2] for f in frames for run in f['runs']);bottom=max(f['rect'][1]+run[0]+1 for f in frames for run in f['runs'])
   target=OUTPUT/f'{key}-{row:02d}.png';cropped=image.crop((left,top,right,bottom))
   cropped.save(target,compress_level=9)
   assert Image.open(target).convert('RGBA').tobytes()==cropped.tobytes()
   # The source import's alpha-border processing has already happened. A
   # second application changes hidden RGB around row edges unnecessarily.
   settings=target.with_name(target.name+'.import')
   if settings.exists():
    text=settings.read_text().replace('process/fix_alpha_border=true','process/fix_alpha_border=false')
    settings.write_text(text)
   else:
    settings.write_text('[remap]\nimporter="texture"\ntype="CompressedTexture2D"\n\n[params]\ncompress/mode=0\nmipmaps/generate=false\nprocess/fix_alpha_border=false\nprocess/premult_alpha=false\n')
   # Every source run must still be in the translated strip bounds.
   for f in frames:
    for y,x,length in f['runs']:
     assert 0<=f['rect'][0]+x-left and f['rect'][0]+x+length-left<=cropped.width
     assert 0<=f['rect'][1]+y-top<cropped.height
   rows.append({'path':str(target.relative_to(ROOT)),'source_crop':[left,top,right-left,bottom-top],'sha256':digest(target),'rgba_bytes':cropped.width*cropped.height*4})
  manifest['groups'][key]={'source_path':atlas['path'],'source_sha256':digest(source),'source_size':list(image.size),'rows':rows,**import_info}
 output=ROOT/'assets/CAMPAIGN-ROW-SHEETS.json';temporary=output.with_suffix('.tmp');temporary.write_text(json.dumps(manifest,separators=(',',':'))+'\n');temporary.replace(output)
 print('Packed exact rows:',{k:len(v['rows']) for k,v in manifest['groups'].items()})

if __name__=='__main__':main()
