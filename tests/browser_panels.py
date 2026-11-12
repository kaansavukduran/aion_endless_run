"""Real touch menus/settings/results in TR/EN/CS and both phone orientations."""
import argparse,json
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--url',default='http://127.0.0.1:8781');p.add_argument('--evidence',required=True,type=Path);a=p.parse_args();a.evidence.mkdir(parents=True,exist_ok=True)
checks=[];errors=[]
def check(ok,label):
 assert ok,label
 checks.append(label);print('PASS',label,flush=True)
with sync_playwright() as pw:
 browser=pw.chromium.launch(args=['--no-sandbox','--enable-unsafe-swiftshader'])
 for orientation,size in [('portrait',(393,873)),('landscape',(873,393))]:
  ctx=browser.new_context(viewport={'width':size[0],'height':size[1]},is_mobile=True,has_touch=True,locale='tr-TR',service_workers='block')
  page=ctx.new_page();page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda m:errors.append(m.text) if 'SCRIPT ERROR' in m.text else None)
  page.goto(a.url);page.wait_for_selector('canvas[data-state="ready"][data-ui-ready="true"]',timeout=120000)
  def d():return page.locator('canvas').evaluate('c=>({...c.dataset})')
  def xy(x,y):
   v=d();t=json.loads(v['screenTransform']);r=page.locator('canvas').bounding_box();return r['x']+(t[0]*x+t[2]*y+t[4])/float(v['rawWidth'])*r['width'],r['y']+(t[1]*x+t[3]*y+t[5])/float(v['rawHeight'])*r['height']
  def tap(text=None,name=None):
   page.wait_for_selector('canvas[data-ui-ready="true"]');v=d();b=next(b for b in json.loads(v['ui']) if (b['name']==name if name else b['text']==text));page.touchscreen.tap(*xy(b['x']+b['w']/2,b['y']+b['h']/2));page.wait_for_timeout(150)
  def lang(code):
   tap(name='LanguageMenu');tap(name='Language_'+code)
   try:page.wait_for_selector('canvas[lang="'+code+'"][data-ui-ready="true"]')
   except Exception:
    print('FAILED LANGUAGE STATE',d(),flush=True);page.screenshot(path=str(a.evidence/('failed-language-'+code+'.png')));raise
  def fit(label):
   v=d();w,h=float(v['viewWidth']),float(v['viewHeight']);bs=json.loads(v['ui']);check(all(b['x']>=-1 and b['y']>=-1 and b['x']+b['w']<=w+1 and b['y']+b['h']<=h+1 for b in bs),label)
  labels={'tr':('Ayarlar','Koşuya başla','Anladım · Devam et','Yeniden koş','Ana menü'),'en':('Settings','Start run','Got it · Continue','Run again','Main menu'),'cs':('Nastavení','Začít běh','Rozumím · Pokračovat','Běžet znovu','Hlavní nabídka')}
  # Native settings are intentionally long: real wheel scrolling reaches the final Back action.
  for code in ['tr','en','cs']:
   lang(code);fit(orientation+' '+code+': all main actions and character cards fit on screen');page.screenshot(path=str(a.evidence/(orientation+'-'+code+'-main.png')))
   tap(text=labels[code][0]);page.wait_for_selector('canvas[data-page="settings"]');page.screenshot(path=str(a.evidence/(orientation+'-'+code+'-settings.png')))
   x,y=xy(float(d()['viewWidth'])/2,float(d()['viewHeight'])/2);page.mouse.move(x,y);page.mouse.wheel(0,20000);page.wait_for_timeout(600)
   back=next(b for b in json.loads(d()['ui']) if b['text'].startswith('‹'))
   check(back['y']>=0 and back['y']+back['h']<=float(d()['viewHeight'])+1,orientation+' '+code+': long settings scroll to the reachable Back action')
   page.screenshot(path=str(a.evidence/(orientation+'-'+code+'-settings-bottom.png')));tap(text=back['text']);page.wait_for_selector('canvas[data-page="main"]')
  lang('tr');tap(text=labels['tr'][1]);page.wait_for_selector('canvas[data-state="running"]')
  if any(b['text']==labels['tr'][2] for b in json.loads(d()['ui'])):tap(text=labels['tr'][2])
  # Let an actual obstacle defeat the player; never assign a fake result state.
  page.wait_for_selector('canvas[data-page="finished"][data-ui-ready="true"]',timeout=60000)
  for code in ['tr','en','cs']:
   lang(code);fit(orientation+' '+code+': real defeat score, retry and menu actions fit without scrolling');page.screenshot(path=str(a.evidence/(orientation+'-'+code+'-result.png')))
  tap(text=labels['cs'][3]);page.wait_for_selector('canvas[data-state="running"]');check(True,orientation+': result retry really starts the next run')
  ctx.close()
 check(not errors,'No uncaught browser/Godot errors in translated phone menus')
 browser.close()
(a.evidence/'panel-results.json').write_text(json.dumps(checks,ensure_ascii=False,indent=2)+'\n');print(len(checks),'real menu checks passed')
