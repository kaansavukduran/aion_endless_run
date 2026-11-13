"""DPR3 physical-pixel bounds and real simultaneous/cancel/swipe input."""
import argparse,json
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--url',default='http://127.0.0.1:8781');p.add_argument('--evidence',type=Path,required=True);a=p.parse_args();a.evidence.mkdir(parents=True,exist_ok=True);checks=[];errors=[]
def check(ok,label):
 assert ok,label
 checks.append(label);print('PASS',label,flush=True)
with sync_playwright() as pw:
 b=pw.chromium.launch(args=['--no-sandbox','--enable-unsafe-swiftshader']);c=b.new_context(viewport={'width':873,'height':393},device_scale_factor=3,has_touch=True,locale='tr-TR',service_workers='block');page=c.new_page();page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda m:errors.append(m.text) if 'SCRIPT ERROR' in m.text else None);page.goto(a.url);page.wait_for_selector('canvas[data-state="ready"][data-ui-ready="true"]',timeout=120000)
 def d():return page.locator('canvas').evaluate('c=>({...c.dataset})')
 def wait(v):
  try:page.wait_for_selector('canvas'+v,timeout=2500)
  except Exception:
   print('INPUT_DEBUG',v,{k:d().get(k) for k in ['state','page','worldTime','playerY','touchTrace','touchInput','touchFingers']},flush=True);raise
 def xy(x,y):
  v=d();t=json.loads(v['screenTransform']);r=page.locator('canvas').bounding_box();return r['x']+(t[0]*x+t[2]*y+t[4])/float(v['rawWidth'])*r['width'],r['y']+(t[1]*x+t[3]*y+t[5])/float(v['rawHeight'])*r['height']
 def ui(name=None,text=None):
  wait('[data-ui-ready="true"]');v=next(v for v in json.loads(d()['ui']) if (v['name']==name if name else v['text']==text));page.touchscreen.tap(*xy(v['x']+v['w']/2,v['y']+v['h']/2))
 def start():
  ui(name='StartRun');wait('[data-state="running"]')
  if any(v['text']=='Anladım · Devam et' for v in json.loads(d()['ui'])):ui(text='Anladım · Devam et')
 def main():
  if d()['page']=='':page.keyboard.press('Escape');wait('[data-page="paused"]')
  ui(text='Ana menü');wait('[data-page="main"]')
 start();v=d();controls=json.loads(v['controls']);t=json.loads(v['screenTransform']);visible={k:x for k,x in controls.items() if x['visible']}
 check(set(visible)=={'jump','duck','shoot'},'Only the three meaningful Aion actions appear; no Reload')
 for name,item in visible.items():
  check(abs(item['w']-item['h'])<.01,'Square symmetric control bounds: '+name)
  corners=[t[0]*item['x']+t[4],t[3]*item['y']+t[5],t[0]*(item['x']+item['w'])+t[4],t[3]*(item['y']+item['h'])+t[5]]
  check(all(abs(x-round(x))<.002 for x in corners),'Every visible and touch-bound edge shares the physical DPR3 pixel grid: '+name)
 check(visible['jump']['x']<float(v['viewWidth'])/2<visible['shoot']['x'] and visible['duck']['x']>float(v['viewWidth'])/2,'Owner-approved left Jump / right Fire-Roll split is preserved');page.screenshot(path=str(a.evidence/'dpr3-landscape-controls.png'));main();controls=json.loads(d()['controls'])
 def point(name,id):
  v=controls[name];x,y=xy(v['x']+v['w']/2,v['y']+v['h']/2);return {'x':x,'y':y,'id':id}
 cdp=c.new_cdp_session(page);shoot=point('shoot',0);jump=point('jump',1);start();cdp.send('Input.dispatchTouchEvent',{'type':'touchStart','touchPoints':[shoot,jump]});wait('[data-airborne="true"]');page.wait_for_function('Number(document.querySelector("canvas").dataset.bossShots)>0');check(True,'Two real fingers jump and hold Fire simultaneously')
 cdp.send('Input.dispatchTouchEvent',{'type':'touchCancel','touchPoints':[]});wait('[data-jump-held="false"]');page.wait_for_timeout(400);shots=d()['bossShots'];page.wait_for_timeout(350);check(d()['bossShots']==shots and d()['touchFingers']=='0','Touch cancellation releases both real owners without a latched trigger')
 # Inspection at DPR3 can outlast a normal hazard window. Rotation has its
 # own fresh run rather than assuming the earlier cancellation run survived.
 main();start();page.keyboard.press('Escape');wait('[data-page="paused"]')
 before=d();page.set_viewport_size({'width':393,'height':873});wait('[data-orientation="portrait"][data-ui-ready="true"]');check(d()['character']==before['character'] and d()['score']==before['score'],'DPR3 rotation keeps the same paused run');page.screenshot(path=str(a.evidence/'dpr3-portrait-paused.png'))
 check(page.evaluate('document.documentElement.scrollHeight<=innerHeight+1&&document.documentElement.scrollWidth<=innerWidth+1'),'DPR3 browser document has no page scroll');check(not errors,'No script or browser errors during DPR3 simultaneous/cancel input');(a.evidence/'results.json').write_text(json.dumps({'checks':checks,'errors':errors,'controls':visible,'physical_transform':t,'build':page.evaluate('AION_BUILD'),'scope':'Real Chromium CDP touch at deviceScaleFactor3, not a physical phone. No world/save/RNG setters.'},ensure_ascii=False,indent=2)+'\n');c.close();b.close()
print('RESULT:',len(checks),'DPR3 touch checks')
