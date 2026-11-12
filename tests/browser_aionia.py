"""AIONIA settings, semantic menu actions and 200% text through real input.
Cloud browsers and emulated viewports; no physical screen-reader/device claim.
"""
import argparse,json,re,time
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--url',default='http://127.0.0.1:8781');p.add_argument('--case');p.add_argument('--evidence',type=Path,required=True);a=p.parse_args();a.evidence.mkdir(parents=True,exist_ok=True)
results=[];errors=[];fonts={}
def check(ok,label):
 assert ok,label
 results.append(label);print('PASS',label,flush=True)
with sync_playwright() as pw:
 browser=pw.chromium.launch(args=['--no-sandbox','--enable-unsafe-swiftshader'])
 for name,size,touch in [('desktop',(1152,648),False),('narrow-phone',(320,740),True),('portrait',(393,873),True),('portrait-16x9',(450,800),True),('landscape',(873,393),True),('tablet-portrait',(768,1024),True),('tablet-landscape',(1024,768),True)]:
  if a.case and a.case!=name:continue
  ctx=browser.new_context(viewport={'width':size[0],'height':size[1]},has_touch=touch,is_mobile=touch,locale='en-GB',color_scheme='light',service_workers='block')
  page=ctx.new_page();page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda m:errors.append(m.text) if 'SCRIPT ERROR' in m.text else None)
  page.goto(a.url);page.wait_for_selector('canvas[data-state="ready"][data-ui-ready="true"]',timeout=120000)
  def d():return page.locator('canvas').evaluate('c=>({...c.dataset})')
  def wait(attrs):page.wait_for_selector('canvas'+attrs,timeout=15000)
  def semantic(label):
   page.locator('#aion-accessibility-controls').get_by_role('button',name=label,exact=True).press('Enter');page.wait_for_timeout(120)
  def option(control):
   labels={"Option_theme_light":"Light","Option_theme_dark":"Dark","Option_theme_system":"Follow system","Option_text_size_2.0":"200%","Option_text_size_1.0":"100%"}
   page.locator("#aion-accessibility-controls").get_by_role("button",name=re.compile(r"^\[[x ]\] "+re.escape(labels[control])+r"$")).press("Enter");
   expected={'Option_theme_light':'[data-theme="light"]','Option_theme_dark':'[data-theme="dark"]','Option_theme_system':'[data-theme="system"]','Option_text_size_2.0':'[data-text-scale="2.0"]','Option_text_size_1.0':'[data-text-scale="1.0"]'}
   wait(expected[control]+'[data-ui-ready="true"]')
  def native_label(part):return next(b['text'] for b in json.loads(d()['ui']) if part in b['text'])
  v=d();check(v['version']=='0.14.1' and v['theme']=='dark' and v['themeDark']=='true',name+': fresh launch is the current game and dark even with a light OS')
  check(v['fontMode']=='system' and 'Pixelify' not in v['fontFamily'],name+': body text uses the platform sans/system fallback, not the pixel logo font');fonts[name]=v['fontFamily']
  check(page.locator('#aion-accessibility-controls').get_by_role('button').count()>=8,name+': four character choices and real menu actions have semantic counterparts')
  semantic('Settings');wait('[data-page="settings"]');option('Option_theme_light');wait('[data-theme="light"][data-theme-dark="false"]')
  check(True,name+': semantic keyboard activation reaches the actual light theme setting')
  page.screenshot(path=str(a.evidence/(name+'-light-settings.png')))
  option('Option_theme_system');wait('[data-theme="system"][data-theme-dark="false"]');page.emulate_media(color_scheme='dark');wait('[data-theme-dark="true"]')
  check(True,name+': Follow system responds to a real media-preference change')
  option('Option_theme_dark');option('Option_text_size_2.0');wait('[data-text-scale="2.0"]')
  page.locator('#aion-accessibility-controls').get_by_role('button',name=re.compile('^‹')).press('Enter');page.wait_for_timeout(150);wait('[data-page="main"][data-ui-ready="true"]')
  page.locator('#aion-accessibility-controls').get_by_role('button',name='Start running',exact=True).focus();page.wait_for_timeout(150)
  page.screenshot(path=str(a.evidence/(name+'-200-main.png')))
  semantic('Start running');wait('[data-state="running"]')
  if touch:semantic('Got it · Continue')
  wait('[data-ui-ready="true"]');v=d()
  if touch:
   controls=json.loads(v['controls']);check(v['touchLayout']=='split' and controls['jump']['x']<float(v['viewWidth'])/2<controls['attack']['x'],name+': approved split thumbs place Jump left and Attack/Roll right')
  semantic('Pause');wait('[data-state="paused"]');page.screenshot(path=str(a.evidence/(name+'-200-paused.png')))
  check(True,name+': 200% main, tutorial and pause actions remain reachable through real controls')
  semantic('Main menu');wait('[data-page="main"]');semantic('Settings');wait('[data-page="settings"]');option('Option_text_size_1.0');option('Option_theme_light')
  # Read the actual persisted IndexedDB file before reload, without mutating it.
  persisted=page.evaluate("""async()=>{
    const out=[];for(const info of await indexedDB.databases()){
      if(!info.name.includes('userfs'))continue;
      const db=await new Promise((yes,no)=>{const r=indexedDB.open(info.name);r.onsuccess=()=>yes(r.result);r.onerror=()=>no(r.error)});
      for(const store of db.objectStoreNames){const tx=db.transaction(store,'readonly'),s=tx.objectStore(store);
        const [keys,values]=await Promise.all([new Promise((y,n)=>{const r=s.getAllKeys();r.onsuccess=()=>y(r.result);r.onerror=()=>n(r.error)}),new Promise((y,n)=>{const r=s.getAll();r.onsuccess=()=>y(r.result);r.onerror=()=>n(r.error)})]);
        keys.forEach((k,i)=>{if(String(k).endsWith('/save.cfg'))out.push({path:k,contents:new TextDecoder().decode(values[i].contents)})});
      }db.close();
    }return out;
  }""")
  print('PERSISTED_BEFORE_WAIT',name,persisted,'MEMORY',d().get('saveObservation'),flush=True)
  # Readbacks follow a genuine save and fresh engine/IndexedDB load.
  wait('[data-theme="light"][data-text-scale="1.0"][data-ui-ready="true"]');check(page.evaluate('JSON.parse(localStorage.getItem("aion-runner-save-v1")).schema===1'),name+': a real synchronous recovery copy exists before immediate reload');page.reload();wait('[data-page="main"][data-ui-ready="true"]')
  check(d()['theme']=='light' and d()['fontMode']=='system' and d()['textScale']=='1.0',name+': chosen theme/font/text settings survive a real reload '+str({k:d().get(k) for k in ['theme','fontMode','textScale']}))
  semantic('Settings');option('Option_theme_dark');page.locator('#aion-accessibility-controls').get_by_role('button',name=re.compile('^‹')).press('Enter');page.wait_for_timeout(150);wait('[data-page="main"]');page.screenshot(path=str(a.evidence/(name+'-dark-main.png')))
  ctx.close()
 check(not errors,'No uncaught browser or Godot script errors in AIONIA settings and semantic controls');browser.close()
(a.evidence/'aionia-results.json').write_text(json.dumps({'checks':results,'font_families':fonts,'scope':'Chromium with cloud software GPU and emulated viewports. No physical screen-reader or device certification.'},ensure_ascii=False,indent=2)+'\n');print(len(results),'AIONIA browser checks passed')
