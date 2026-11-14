"""Read-only WebAudio counters with original start/createBuffer calls preserved.
Actual menu, pause and resume inputs. No world setters or save injection.
"""
from pathlib import Path
from playwright.sync_api import sync_playwright
import json,time,sys,shutil,argparse
parser=argparse.ArgumentParser();parser.add_argument('--url',required=True);parser.add_argument('--evidence',type=Path,required=True);parser.add_argument('--seconds',type=int,default=35);parser.add_argument('--expect-restart-bug',action='store_true');args=parser.parse_args();url=args.url;out=args.evidence;out.mkdir(parents=True,exist_ok=True)
with sync_playwright() as p:
 b=p.chromium.launch(executable_path=shutil.which('chromium'),args=['--no-sandbox','--enable-unsafe-swiftshader'])
 c=b.new_context(viewport={'width':1280,'height':720},locale='en-US');c.add_init_script('''(()=>{window.audioProbe={starts:0,longStarts:0,buffers:0,longBuffers:0};const start=AudioBufferSourceNode.prototype.start;AudioBufferSourceNode.prototype.start=function(...args){audioProbe.starts++;if(this.buffer?.duration>20)audioProbe.longStarts++;return start.apply(this,args)};const make=BaseAudioContext.prototype.createBuffer;BaseAudioContext.prototype.createBuffer=function(...args){audioProbe.buffers++;if(args[1]/args[2]>20)audioProbe.longBuffers++;return make.apply(this,args)}})()''')
 page=c.new_page();errors=[];page.on('pageerror',lambda e:errors.append(str(e)));page.goto(url);page.wait_for_selector('canvas[data-state="ready"][data-ui-ready="true"]',timeout=120000)
 page.get_by_role('button',name='Arcade',exact=True).press('Enter');page.wait_for_function('document.querySelector("canvas").dataset.campaign')
 page.get_by_role('button',name='Begin mission',exact=True).press('Enter')
 def data():return json.loads(page.locator('canvas').get_attribute('data-campaign'))
 while data()['menu']=='help':page.get_by_role('button',name=data()['buttons']['CampaignGo'][4],exact=True).press('Enter');page.wait_for_timeout(160)
 page.locator('canvas').focus();page.keyboard.press('Escape');cd=c.new_cdp_session(page);samples=[];start=time.monotonic()
 for i in range(args.seconds):
  if i==10:page.keyboard.press('Escape')
  if i==20:page.keyboard.press('Escape')
  sample={'wall':time.monotonic()-start,'audio':page.evaluate('window.audioProbe'),'heap':cd.send('Runtime.getHeapUsage'),'cgroup':int(Path('/sys/fs/cgroup/memory.current').read_text()),'menu':data()['menu'],'music_starts':data().get('music_starts')};samples.append(sample);print(json.dumps(sample),flush=True)
  if sample['cgroup']>12*1024**3:break
  page.wait_for_timeout(1000)
 (out/'audio-probe.json').write_text(json.dumps({'url':url,'instrumentation':'WebAudio start/createBuffer counters; wraps original methods without changing their result. Real menu/input.','samples':samples,'errors':errors,'build':page.evaluate("fetch('build.json').then(r=>r.json()).then(v=>v.build)")},indent=2)+'\n');c.close();b.close()

last=samples[-1];observed=last['audio']['longStarts']
if args.expect_restart_bug:
 assert observed>1,'Baseline did not reproduce repeated 24-second sample allocation'
 print('EXPECTED REGRESSION REPRODUCED:',observed,'long sample starts')
else:
 assert not errors,errors
 assert observed<=1,('Repeated long sample starts',last)
 assert last['music_starts']==1,('Coast music restarted across pause/death updates',last)
 print('RESULT: 3 real WebAudio lifecycle checks, 0 failures')
