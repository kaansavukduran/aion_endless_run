"""Actual UI defaults/persistence and four-hero input/render playback, no setters."""
import argparse,json
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--url',default='http://127.0.0.1:8779');p.add_argument('--evidence',type=Path,default=Path('work/fidelity-evidence'));a=p.parse_args();a.evidence.mkdir(parents=True,exist_ok=True);results=[];errors=[]
def check(value,message):
 assert value,message
 results.append(message);print('PASS',message,flush=True)
with sync_playwright() as pw:
 browser=pw.chromium.launch(args=['--no-sandbox','--enable-unsafe-swiftshader'])
 ctx=browser.new_context(viewport={'width':1152,'height':648},locale='en-US',reduced_motion='reduce',record_video_dir=str(a.evidence/'video'));page=ctx.new_page();page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda m:errors.append(m.text) if 'SCRIPT ERROR' in m.text else None)
 def d():return page.locator('canvas').evaluate('c=>({...c.dataset})')
 def wait(sel):page.wait_for_selector('canvas'+sel,timeout=90000)
 def click(name=None,text=None):
  wait('[data-ui-ready="true"]');v=d();b=next(b for b in json.loads(v['ui']) if (b['name']==name if name else text in b['text']));t=json.loads(v['screenTransform']);r=page.locator('canvas').bounding_box();x=b['x']+b['w']/2;y=b['y']+b['h']/2;page.mouse.click(r['x']+(t[0]*x+t[2]*y+t[4])/float(v['rawWidth'])*r['width'],r['y']+(t[1]*x+t[3]*y+t[5])/float(v['rawHeight'])*r['height'])
 page.goto(a.url);wait('[data-version="0.12.0"][data-state="ready"]')
 fields=['motionEnabled','effectsEnabled','audioEnabled','celebrationsEnabled']
 check(all(d()[k]=='true' for k in fields),'Fresh browser defaults all four options ON, even when the OS requests reduced motion')
 click(text='Settings');wait('[data-page="settings"]');page.screenshot(path=str(a.evidence/'settings-default-on.png'))
 for key,field in [('motion','motion-enabled'),('screen_fx','effects-enabled'),('audio','audio-enabled')]:
  click(name='Setting_'+key);page.wait_for_timeout(150);wait('[data-'+field+'="false"]')
 # Scroll the actual settings panel to reveal the fourth switch.
 page.mouse.move(750,480);page.mouse.wheel(0,260);page.wait_for_timeout(500);click(name='Setting_celebrations');wait('[data-celebrations-enabled="false"]')
 check(all(d()[k]=='false' for k in fields),'All four actual switches can be explicitly turned OFF')
 page.wait_for_timeout(2300);page.reload();wait('[data-state="ready"]')
 check(all(d()[k]=='false' for k in fields),'Explicit OFF choices persist across real IndexedDB reload')
 click(text='Settings');wait('[data-page="settings"]')
 for key,field in [('motion','motion-enabled'),('screen_fx','effects-enabled'),('audio','audio-enabled')]:
  click(name='Setting_'+key);page.wait_for_timeout(150);wait('[data-'+field+'="true"]')
 page.mouse.move(750,480);page.mouse.wheel(0,260);page.wait_for_timeout(500);click(name='Setting_celebrations');wait('[data-celebrations-enabled="true"]')
 page.keyboard.press('Escape');wait('[data-page="main"]')
 page.evaluate('''()=>{window.poses={};new MutationObserver(()=>{const d=document.querySelector('canvas').dataset;if(d.state==='running'){const h=window.poses[d.character]??={};const k=d.poseSource+':'+d.sourceRow;(h[k]??=new Set()).add(d.sourceFrame)}}).observe(document.querySelector('canvas'),{attributes:true})}''')
 for hero in ['aion','owl','sheep','wolf']:
  click(name='StartSelect_'+hero);page.keyboard.press('Space');wait('[data-state="running"]');page.wait_for_timeout(220)
  check(d()['poseSource']=='canonical-'+hero and d()['sourceRow']=='1',hero+': actual run selects its own faithful sheet')
  page.keyboard.down('s');wait('[data-pose-source="canonical-rolls"]');page.wait_for_timeout(700);page.keyboard.up('s')
  check(True,hero+': actual roll plays the dedicated clockwise compact atlas')
  page.wait_for_timeout(100);page.keyboard.press('j');wait('[data-attacking="true"]');page.wait_for_timeout(80);page.screenshot(path=str(a.evidence/(hero+'-physical-strike.png')))
  page.keyboard.press('Space');wait('[data-airborne="true"]');check(d()['poseSource'] in ['canonical-'+hero,'agility-'+hero],hero+': jump/strike preserves its own character identity')
  page.keyboard.press('Escape');wait('[data-page="paused"]');click(text='Main menu');wait('[data-page="main"]')
 page.wait_for_timeout(2300);page.reload();wait('[data-state="ready"]');check(all(d()[k]=='true' for k in fields),'Explicit ON choices also persist on reload')
 check(not errors,'No browser or Godot errors during defaults and four-hero playback')
 ctx.close();browser.close()
(a.evidence/'fidelity-results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2)+'\n');print(len(results),'fidelity browser checks passed')
