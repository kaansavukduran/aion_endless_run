"""Production smoke with normal input; pair with full local six-hero acceptance.
Use a system-CA forwarding wrapper when the cloud browser lacks its proxy CA.
"""
import argparse,json,os
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--browser',choices=['firefox','chromium'],default='firefox');p.add_argument('--url',required=True);p.add_argument('--evidence',type=Path,required=True);a=p.parse_args();a.evidence.mkdir(parents=True,exist_ok=True)
checks=[];errors=[];dialogs=[]
def check(ok,label):
 assert ok,label
 checks.append(label);print('PASS',label,flush=True)
with sync_playwright() as pw:
 if a.browser=='firefox':
  env=dict(os.environ,DISPLAY=os.environ.get('DISPLAY',':101'),XDG_CACHE_HOME=str(a.evidence/'cache'),XDG_CONFIG_HOME=str(a.evidence/'config'),MOZ_DISABLE_CONTENT_SANDBOX='1',LIBGL_ALWAYS_SOFTWARE='1')
  browser=pw.firefox.launch(headless=False,env=env,firefox_user_prefs={'webgl.force-enabled':True,'dom.w3c_touch_events.enabled':1})
 else:browser=pw.chromium.launch(args=['--no-sandbox','--enable-unsafe-swiftshader'])
 kwargs={'viewport':{'width':873,'height':393},'has_touch':True,'device_scale_factor':2,'locale':'tr-TR'}
 if a.browser=='firefox':kwargs['user_agent']='Mozilla/5.0 (Android 15; Mobile; rv:153.0) Gecko/153.0 Firefox/153.0'
 ctx=browser.new_context(**kwargs);page=ctx.new_page();page.on('pageerror',lambda e:errors.append(str(e)));page.on('dialog',lambda v:(dialogs.append(v.message),v.dismiss()));page.on('console',lambda m:errors.append(m.text) if 'SCRIPT ERROR' in m.text else None)
 page.goto(a.url,timeout=120000);page.wait_for_selector('canvas[data-state="ready"][data-ui-ready="true"]',timeout=120000)
 def d():return page.locator('canvas').evaluate('c=>({...c.dataset})')
 def wait(v):page.wait_for_selector('canvas'+v,timeout=20000)
 def xy(x,y):
  v=d();t=json.loads(v['screenTransform']);r=page.locator('canvas').bounding_box();return r['x']+(t[0]*x+t[2]*y+t[4])/float(v['rawWidth'])*r['width'],r['y']+(t[1]*x+t[3]*y+t[5])/float(v['rawHeight'])*r['height']
 def ui(name=None,text=None):
  wait('[data-ui-ready="true"]');b=next(b for b in json.loads(d()['ui']) if (b['name']==name if name else b['text']==text));page.touchscreen.tap(*xy(b['x']+b['w']/2,b['y']+b['h']/2))
 def action(name):
  b=json.loads(d()['controls'])[name];page.touchscreen.tap(*xy(b['x']+b['w']/2,b['y']+b['h']/2))
 def start(hero):
  ui(name='StartSelect_'+hero);ui(name='StartRun');wait('[data-state="running"]')
  if any(b['text']=='Anladım · Devam et' for b in json.loads(d()['ui'])):ui(text='Anladım · Devam et')
 check(d()['version']=='0.22.0' and page.evaluate('AION_BOOT.state.phase')=='ready','Actual production0.22.0 boots with verified PCK, no missing-data fallback')
 check(len([b for b in json.loads(d()['ui']) if b['name'].startswith('StartSelect_')])==6,'All six real production character cards are visible');page.screenshot(path=str(a.evidence/'landscape-main.png'))
 start('aion');page.evaluate('window.faceSamples=[];new MutationObserver(()=>{let d=document.querySelector("canvas").dataset;if(d.state==="running"&&d.airborne==="false")faceSamples.push({f:+d.sourceFrame,x:+d.headProbeX,actor:+d.visualX})}).observe(document.querySelector("canvas"),{attributes:true})');page.wait_for_function('new Set(faceSamples.map(p=>p.f)).size===Number(document.querySelector("canvas").dataset.frameCount)');samples=page.evaluate('faceSamples');check(max(v['x'] for v in samples)-min(v['x'] for v in samples)<.01 and max(v['actor'] for v in samples)-min(v['actor'] for v in samples)<.01,'Complete production Aion run loop has stable face and actor anchors')
 action('shoot');page.wait_for_function('Number(document.querySelector("canvas").dataset.bossShots)>0');page.keyboard.down('f');page.wait_for_function('Number(document.querySelector("canvas").dataset.bossShots)>=6');page.keyboard.up('f');page.keyboard.press('Escape');wait('[data-state="paused"]');check(d()['ammo']=='infinite' and 'attack' not in json.loads(d()['controls']),'Production touch Fire and held Fire pass five shots without Reload')
 prior=d();page.set_viewport_size({'width':393,'height':873});wait('[data-orientation="portrait"][data-ui-ready="true"]');check(d()['score']==prior['score'] and d()['character']==prior['character'],'Actual production portrait rotation preserves paused score and character');page.screenshot(path=str(a.evidence/'portrait-paused.png'));ui(text='Ana menü');wait('[data-page="main"]')
 start('eren');page.keyboard.down('Space');wait('[data-charging="true"]');page.wait_for_function('Number(document.querySelector("canvas").dataset.chargeRatio)>.4');check(d()['airborne']=='false','Production Eren charges on the ground');page.keyboard.up('Space');wait('[data-airborne="true"]');page.keyboard.press('Escape');wait('[data-page="paused"]');check(d()['poseSource']=='polish-abilities' and d()['charging']=='false','Production Eren releases his own drawn charged jump');page.screenshot(path=str(a.evidence/'eren-jump.png'));ui(text='Ana menü');wait('[data-page="main"]')
 start('rabbit');page.keyboard.down('Space');page.wait_for_function('Number(document.querySelector("canvas").dataset.chargeRatio)>.5');check(d()['charging']=='true' and d()['airborne']=='false','Production Emre still builds charge on the ground');page.keyboard.up('Space');wait('[data-airborne="true"][data-charging="false"]');page.keyboard.press('Escape');wait('[data-page="paused"]');check(d()['jumps']=='1','Production Emre release produces one charged leap');page.screenshot(path=str(a.evidence/'emre-charge-leap.png'));ui(text='Ana menü');wait('[data-page="main"]')
 start('aion');action('duck');pose=page.wait_for_function('()=>{const d=document.querySelector("canvas").dataset;return d.ducking==="true"&&d.sourceRow==="0"?{source:d.poseSource,row:d.sourceRow}:false}').json_value();page.keyboard.press('Escape');wait('[data-page="paused"]');check(pose['source']=='polish-rolls' and pose['row']=='0','Production Roll touch selects the new faithful shoulder atlas')
 check(not errors and not dialogs,'No script errors or missing-PCK alerts during live play');report={'url':a.url,'browser':a.browser+' '+browser.version,'build':page.evaluate('AION_BUILD'),'checks':checks,'dialogs':dialogs,'errors':errors,'face_samples':samples,'scope':'Actual public HTTPS bytes verified by loader; normal UI and browser touch/keys. Firefox is headed Gecko with Android UA, not a physical Poco. CA-forwarded diagnostic wrappers disable SW; actual offline worker is verified separately.'};(a.evidence/'live-results.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n');ctx.close();browser.close()
print('RESULT:',len(checks),'actual public play checks')
