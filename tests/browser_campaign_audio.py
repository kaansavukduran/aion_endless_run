"""Read-only WebAudio counters with original start/createBuffer calls preserved.
Actual menu, pause and resume inputs. No world setters or save injection.
"""
from pathlib import Path
from playwright.sync_api import sync_playwright
import json,time,sys,shutil,argparse
parser=argparse.ArgumentParser();parser.add_argument('--url',required=True);parser.add_argument('--evidence',type=Path,required=True);parser.add_argument('--seconds',type=int,default=35);parser.add_argument('--expect-restart-bug',action='store_true');args=parser.parse_args();url=args.url;out=args.evidence;out.mkdir(parents=True,exist_ok=True)

def cgroup_memory_bytes():
 """Optional environment metric; hosted runners need not expose cgroup files."""
 for name in ('/sys/fs/cgroup/memory.current','/sys/fs/cgroup/memory/memory.usage_in_bytes'):
  try:
   return int(Path(name).read_text().strip())
  except (OSError,ValueError):
   continue
 return None

with sync_playwright() as p:
 b=p.chromium.launch(executable_path=shutil.which('chromium'),args=['--no-sandbox','--enable-unsafe-swiftshader'])
 c=b.new_context(viewport={'width':1280,'height':720},locale='en-US');c.add_init_script('''(()=>{window.audioProbe={starts:0,longStarts:0,buffers:0,longBuffers:0};const start=AudioBufferSourceNode.prototype.start;AudioBufferSourceNode.prototype.start=function(...args){audioProbe.starts++;if(this.buffer?.duration>20)audioProbe.longStarts++;return start.apply(this,args)};const make=BaseAudioContext.prototype.createBuffer;BaseAudioContext.prototype.createBuffer=function(...args){audioProbe.buffers++;if(args[1]/args[2]>20)audioProbe.longBuffers++;return make.apply(this,args)}})()''')
 page=c.new_page();errors=[];page.on('pageerror',lambda e:errors.append(str(e)));page.goto(url);page.wait_for_selector('canvas[data-state="ready"][data-ui-ready="true"]',timeout=120000)
 page.get_by_role('button',name='Choose hero',exact=True).press('Enter')
 page.wait_for_selector('canvas[data-page="characters"][data-ui-ready="true"]')
 name=next(b['text'] for b in json.loads(page.locator('canvas').get_attribute('data-ui')) if b['name']=='ConfirmHero')
 page.get_by_role('button',name=name,exact=True).press('Enter')
 page.wait_for_function('document.querySelector("canvas").dataset.campaign')
 def data():return json.loads(page.locator('canvas').get_attribute('data-campaign'))
 # Mission Start now consumes Escape as Skip. Finish that real presentation
 # before exercising paused → playing → paused audio. Two seconds of actual
 # play keeps this focused probe away from an unattended combat/death flow.
 page.wait_for_function('()=>{const d=JSON.parse(document.querySelector("canvas").dataset.campaign);return d.state==="playing" && !(d.presentation || d.presentation_stage)}',timeout=15000)
 def set_paused(paused):
  # Exercise the same visible Pause/Resume actions a player can activate.
  # Godot replaces these controls after a transition, so focus each new
  # action explicitly instead of sending Escape to the detached control.
  action=page.get_by_role('button',name='Pause' if paused else 'Keep going',exact=True)
  action.press('Enter',timeout=15000)
  page.wait_for_function('menu=>JSON.parse(document.querySelector("canvas").dataset.campaign).menu===menu',arg='paused' if paused else '',timeout=15000)
 set_paused(True)
 cd=c.new_cdp_session(page);samples=[];start=time.monotonic();states=['paused']
 for i in range(args.seconds):
  if i in [10,12]:
   set_paused(i==12)
   states.append('playing' if i==10 else 'paused')
  sample={'wall':time.monotonic()-start,'audio':page.evaluate('window.audioProbe'),'heap':cd.send('Runtime.getHeapUsage'),'cgroup':cgroup_memory_bytes(),'menu':data()['menu'],'music_starts':data().get('music_starts')};samples.append(sample);print(json.dumps(sample),flush=True)
  if sample['cgroup'] is not None and sample['cgroup']>12*1024**3:break
  page.wait_for_timeout(1000)
 (out/'audio-probe.json').write_text(json.dumps({'url':url,'instrumentation':'WebAudio start/createBuffer counters; wraps original methods without changing their result. Real menu/input.','states':states,'samples':samples,'errors':errors,'build':page.evaluate("fetch('build.json').then(r=>r.json()).then(v=>v.build)")},indent=2)+'\n');c.close();b.close()

last=samples[-1];observed=last['audio']['longStarts']
if args.expect_restart_bug:
 assert observed>1,'Baseline did not reproduce repeated 24-second sample allocation'
 print('EXPECTED REGRESSION REPRODUCED:',observed,'long sample starts')
else:
 assert states==['paused','playing','paused'] and len(samples)==args.seconds,('Pause/resume scenario was not fully exercised',states,len(samples))
 assert not errors,errors
 assert observed<=1,('Repeated long sample starts',last)
 assert last['music_starts']==1,('Coast music restarted across pause/death updates',last)
 print('RESULT: 3 real WebAudio checks and actual paused/playing/paused transitions, 0 failures')
