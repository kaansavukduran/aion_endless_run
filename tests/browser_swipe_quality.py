"""Trusted rapid downward touch sequence; no world, save or RNG setters."""
import argparse,asyncio,json
from pathlib import Path
from playwright.async_api import async_playwright
p=argparse.ArgumentParser();p.add_argument('--url',default='http://127.0.0.1:8781');p.add_argument('--evidence',type=Path,required=True);a=p.parse_args();a.evidence.mkdir(parents=True,exist_ok=True)
async def run():
 async with async_playwright() as pw:
  b=await pw.chromium.launch(args=['--no-sandbox','--enable-unsafe-swiftshader']);c=await b.new_context(viewport={'width':873,'height':393},device_scale_factor=3,has_touch=True,locale='tr-TR',service_workers='block');page=await c.new_page();errors=[];page.on('pageerror',lambda e:errors.append(str(e)));await page.goto(a.url);await page.wait_for_selector('canvas[data-state="ready"][data-ui-ready="true"]',timeout=120000)
  async def data():return await page.locator('canvas').evaluate('c=>({...c.dataset})')
  v=await data();t=json.loads(v['screenTransform']);r=await page.locator('canvas').bounding_box()
  def xy(x,y):return r['x']+(t[0]*x+t[2]*y+t[4])/float(v['rawWidth'])*r['width'],r['y']+(t[1]*x+t[3]*y+t[5])/float(v['rawHeight'])*r['height']
  async def ui(name):
   s=await data();u=next(u for u in json.loads(s['ui']) if u['name']==name or u['text']==name);await page.touchscreen.tap(*xy(u['x']+u['w']/2,u['y']+u['h']/2))
  x,y=xy(float(v['viewWidth'])*.54,210);cdp=await c.new_cdp_session(page);await ui('StartRun');await page.wait_for_selector('canvas[data-state="running"][data-ui-ready="true"]')
  if any(u['text']=='Anladım · Devam et' for u in json.loads((await data())['ui'])):await ui('Anladım · Devam et')
  await page.evaluate("window.swipeSamples=[];new MutationObserver(()=>{let d=document.querySelector('canvas').dataset;if(d.state==='running')swipeSamples.push({duck:d.ducking==='true',source:d.poseSource,row:+d.sourceRow,y:+d.playerY,jumps:+d.jumps,swipes:+d.touchSwipes})}).observe(document.querySelector('canvas'),{attributes:true})")
  # Enqueue the three trusted input events in order without round-trip waits
  # between movement samples. Software DPR3 rendering must not turn a rapid
  # gesture into a long hold while Python waits on individual acknowledgements.
  await asyncio.gather(cdp.send('Input.dispatchTouchEvent',{'type':'touchStart','touchPoints':[{'x':x,'y':y,'id':3}]}),cdp.send('Input.dispatchTouchEvent',{'type':'touchMove','touchPoints':[{'x':x,'y':y+80,'id':3}]}),cdp.send('Input.dispatchTouchEvent',{'type':'touchEnd','touchPoints':[]}))
  await page.wait_for_function("swipeSamples.some(p=>p.duck&&p.source==='polish-rolls'&&p.row===0)",timeout=3000);await page.keyboard.press('Escape');await page.wait_for_selector('canvas[data-page="paused"]');samples=await page.evaluate('swipeSamples');v=await data();checks=[]
  def check(ok,label):
   assert ok,(label,v.get('touchTrace'),samples)
   checks.append(label);print('PASS',label,flush=True)
  check(any(p['duck'] and p['y']==0 and p['source']=='polish-rolls' and p['row']==0 for p in samples),'Actual DPR3 downward touch reaches the drawn ground shoulder roll')
  check(max(p['jumps'] for p in samples)==0,'The gesture never creates a jump')
  check(v['touchFingers']=='0' and v['touchSwipes']=='1','One real gesture produces one roll and releases its finger')
  check(not errors,'No browser errors during the trusted touch gesture');await page.screenshot(path=str(a.evidence/'dpr3-swipe-paused.png'));(a.evidence/'results.json').write_text(json.dumps({'checks':checks,'errors':errors,'samples':samples,'build':await page.evaluate('AION_BUILD'),'scope':'Trusted rapid CDP touch start/move/end in a Chromium DPR3 context. No state injection; no physical-device claim.'},ensure_ascii=False,indent=2)+'\n');await c.close();await b.close()
 print('RESULT:',len(checks),'real swipe checks')
asyncio.run(run())
