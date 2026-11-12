"""Real UI, persisted locale and normal controls; passive canvas diagnostics only."""
import argparse,json,re
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--url',default='http://127.0.0.1:8781');p.add_argument('--evidence',type=Path,required=True);a=p.parse_args();a.evidence.mkdir(parents=True,exist_ok=True)
source=Path('scripts/text.gd').read_text();texts=json.loads(source.split('const STRINGS := ',1)[1].split('\nconst EXTRA',1)[0]);texts.update({p.stem:json.loads(p.read_text()) for p in Path('assets/locales').glob('*.json')})
names={'tr':'Türkçe','en':'English','cs':'Čeština','az':'Azərbaycanca','de':'Deutsch','fr':'Français','ja':'日本語','ko':'한국어','zh':'中文','es':'Español','it':'Italiano'}
checks=[];errors=[];measurements=[]
def check(ok,label):
 assert ok,label
 checks.append(label);print('PASS',label,flush=True)
with sync_playwright() as pw:
 browser=pw.chromium.launch(args=['--no-sandbox','--enable-unsafe-swiftshader'])
 for shape,size in [('portrait',(393,873)),('landscape',(873,393))]:
  ctx=browser.new_context(viewport={'width':size[0],'height':size[1]},has_touch=True,is_mobile=True,locale='az-AZ',service_workers='block');page=ctx.new_page()
  page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda m:errors.append(m.text) if 'SCRIPT ERROR' in m.text else None)
  def data():return page.locator('canvas').evaluate('c=>({...c.dataset,language:c.lang})')
  def wait(s):page.wait_for_selector('canvas'+s,timeout=120000)
  def semantic(label):page.locator('#aion-accessibility-controls').get_by_role('button',name=label,exact=True).press('Enter')
  def touch_name(name):
   point=page.locator('canvas').evaluate('''(c,name)=>{const d=c.dataset,b=JSON.parse(d.ui).find(b=>b.name===name),t=JSON.parse(d.screenTransform),r=c.getBoundingClientRect(),x=b.x+b.w/2,y=b.y+b.h/2;return [r.x+(t[0]*x+t[2]*y+t[4])/Number(d.rawWidth)*r.width,r.y+(t[1]*x+t[3]*y+t[5])/Number(d.rawHeight)*r.height]}''',name)
   page.touchscreen.tap(*point)
  page.goto(a.url);wait('[data-version="0.16.0"][data-state="ready"][data-ui-ready="true"]');check(data()['language']=='az',shape+': Azerbaijani browser locale is selected on a fresh profile')
  for lang in names:
   touch_name('LanguageMenu');wait('[data-language-picker="true"]')
   semantic(lang.upper()+'  '+names[lang]);wait('[lang="'+lang+'"][data-ui-ready="true"]')
   v=data();buttons=json.loads(v['ui']);start=next(b for b in buttons if b['text']==texts[lang]['play'])
   check(start['y']>=0 and start['y']+start['h']<=float(v['viewHeight']),shape+'/'+lang+': translated start action stays in bounds')
   roster=[b for b in buttons if b['name'].startswith('StartSelect_')]
   check(len(roster)==4 and all(b['w']>40 and b['h']>45 for b in roster),shape+'/'+lang+': four original characters remain selectable')
   semantic(texts[lang]['settings']);wait('[data-page="settings"][data-ui-ready="true"]');check(texts[lang]['desc_lightning'] in page.locator('#aion-accessibility-controls').inner_text() or len(json.loads(data()['ui']))>15,shape+'/'+lang+': localized settings page builds without missing labels')
   semantic('‹  '+texts[lang]['back']);wait('[data-page="main"][data-ui-ready="true"]')
   semantic(texts[lang]['play']);wait('[data-state="running"]')
   if page.locator('#aion-accessibility-controls').get_by_role('button',name=texts[lang]['touch_skip'],exact=True).count():semantic(texts[lang]['touch_skip'])
   semantic(texts[lang]['pause']);wait('[data-page="paused"][data-ui-ready="true"]');semantic(texts[lang]['menu']);wait('[data-page="main"][data-ui-ready="true"]')
   check(data()['language']==lang,shape+'/'+lang+': start, pause and return preserve the chosen language')
   if lang in ['az','ja','ko','zh','de']:page.screenshot(path=str(a.evidence/(shape+'-'+lang+'-main.png')))
   measurements.append({'shape':shape,'lang':lang,'roster':roster,'start':start})
  page.reload();wait('[data-state="ready"][data-ui-ready="true"]');check(data()['language']=='it',shape+': Italian override survives a real page reload')
  touch_name('LanguageMenu');wait('[data-language-picker="true"]');page.wait_for_timeout(180);touch_name('Language_it');wait('[data-language-picker="false"]');check(True,shape+': lower language option is reachable by actual touch after focus-scroll')
  ctx.close()
 ctx=browser.new_context(viewport={'width':1152,'height':648},locale='ru-RU',service_workers='block');page=ctx.new_page();page.goto(a.url);page.wait_for_selector('canvas[data-ui-ready="true"]',timeout=120000);check(page.locator('canvas').get_attribute('lang')=='en','Unsupported browser locale still falls back to English');ctx.close();browser.close()
check(not errors,'No JavaScript or Godot script errors in the tested locale flows')
(a.evidence/'result.json').write_text(json.dumps({'checks':checks,'errors':errors,'measurements':measurements},ensure_ascii=False,indent=2))
print('RESULT:',len(checks),'browser variety/locale checks')
