"""Real-input three-language, pre-run selection and visible-size verification."""
import argparse,json,time
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--url',default='http://127.0.0.1:8779');p.add_argument('--evidence',type=Path,default=Path('work/localization-evidence'));args=p.parse_args();out=args.evidence;out.mkdir(parents=True,exist_ok=True)
results=[];errors=[]
def check(value,message):
 assert value,message
 results.append(message);print('PASS',message,flush=True)
with sync_playwright() as p:
 browser=p.chromium.launch(args=['--no-sandbox','--enable-unsafe-swiftshader']);context=None;page=None
 def data():return page.locator('canvas').evaluate('c=>({...c.dataset,lang:c.getAttribute("lang")})')
 def wait_ui():page.wait_for_selector('canvas[data-ui-ready="true"]')
 def click(name=None,text=None,touch=False):
  wait_ui();d=data();b=next(b for b in json.loads(d['ui']) if (b['name']==name if name else text in b['text']));t=json.loads(d['screenTransform']);r=page.locator('canvas').bounding_box();x=b['x']+b['w']/2;y=b['y']+b['h']/2
  point={'x':r['x']+(t[0]*x+t[2]*y+t[4])/float(d['rawWidth'])*r['width'],'y':r['y']+(t[1]*x+t[3]*y+t[5])/float(d['rawHeight'])*r['height']}
  (page.touchscreen.tap if touch else page.mouse.click)(**point)
 def new_context(locale,phone=False):
  global context,page
  if context:context.close()
  context=browser.new_context(viewport={'width':390,'height':844} if phone else {'width':1152,'height':648},locale=locale,has_touch=phone,is_mobile=phone)
  page=context.new_page();page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda msg:errors.append(msg.text) if 'SCRIPT ERROR' in msg.text else None)
  page.goto(args.url);page.wait_for_selector('canvas[data-state="ready"]',timeout=60000);wait_ui()
 def choose_language(lang,touch=False):
  click(name='LanguageMenu',touch=touch);page.wait_for_selector('canvas[data-language-picker="true"]');click(name='Language_'+lang,touch=touch);page.wait_for_selector('canvas[lang="'+lang+'"]');wait_ui()
 def start_character(id):
  if data()['page']!='main':
   if data()['page']=='':
    if data()['state']=='running':page.keyboard.press('Escape')
    page.wait_for_function('() => ["paused","finished"].includes(document.querySelector("canvas").dataset.page)')
   menu={'tr':'Ana menü','en':'Main menu','cs':'Hlavní nabídka'}[data()['lang']];click(text=menu);page.wait_for_selector('canvas[data-page="main"]');wait_ui()
  click(name='StartSelect_'+id);page.wait_for_selector('canvas[data-character="'+id+'"]');page.keyboard.press('Space');page.wait_for_selector('canvas[data-state="running"]');wait_ui()
 for locale,lang,name in [('tr-TR','tr','Baykuş Ömer'),('en-GB','en','Omar the Owl'),('cs-CZ','cs','Sova Omar'),('de-DE','en','Omar the Owl')]:
  new_context(locale)
  check(data()['lang']==lang,'First launch follows primary locale with English fallback: '+locale)
  check(data()['languageOverride']=='false','Fresh locale remains automatic until explicitly selected: '+locale)
  check(len([b for b in json.loads(data()['ui']) if b['name'].startswith('StartSelect_')])==4,'Four characters are visibly selectable before running: '+lang)
  click(name='StartSelect_owl');page.wait_for_selector('canvas[data-character="owl"]')
  check(data()['characterName']==name,'Actual selected character name is localized: '+name)
  page.screenshot(path=str(out/('start-'+locale+'.png')))
 choose_language('cs');check(data()['languageOverride']=='true','Header language dropdown explicitly switches German-default English to Czech')
 click(name='StartSelect_wolf');page.wait_for_selector('canvas[data-character="wolf"]');check(data()['characterName']=='Prokletý moudrý vlk','Czech wolf name is visible in the selected-character UI')
 page.wait_for_timeout(2300);page.reload();page.wait_for_selector('canvas[data-state="ready"]',timeout=60000);wait_ui();check(data()['lang']=='cs' and data()['character']=='wolf','Manual Czech choice and starting character survive reload')
 page.keyboard.press('Space');page.wait_for_selector('canvas[data-state="running"]');page.keyboard.press('Escape');page.wait_for_selector('canvas[data-state="paused"]');wait_ui()
 check(not any(b['name'].startswith(('Select_','StartSelect_')) or b['text']=='Postavy' for b in json.loads(data()['ui'])),'Pause does not expose a character change during the run')
 choose_language('tr');check(data()['state']=='paused' and data()['character']=='wolf' and data()['characterName']=='Melun Bilge Kurt','Language can change during a paused run without changing the character')
 page.keyboard.press('Escape');page.wait_for_selector('canvas[data-state="running"]');check(data()['character']=='wolf','Resume preserves the locked running character')
 # Observe real opaque atlas dimensions through genuine jump/boost/glide inputs.
 start_character('wolf');page.keyboard.down('Shift');page.wait_for_selector('canvas[data-boosting="true"][data-action-sheet="true"]');check(abs(float(data()['heroHeadSize'])-65)<.1,'Grounded wolf dash keeps the normal calibrated head size')
 page.keyboard.press('Space');page.wait_for_selector('canvas[data-airborne="true"]');check(abs(float(data()['heroHeadSize'])-65)<.1 and data()['giant']=='false','Wolf jump keeps the same normal calibrated head size');page.screenshot(path=str(out/'wolf-fixed-jump.png'));page.keyboard.up('Shift')
 start_character('sheep');page.keyboard.press('Space');page.wait_for_selector('canvas[data-airborne="true"]');check(abs(float(data()['heroHeadSize'])-65)<.1 and data()['giant']=='false','Leader sheep jump keeps the normal size');page.screenshot(path=str(out/'sheep-fixed-jump.png'))
 # Catch a naturally spawned updraft while deliberately leaping over the first
 # mushroom, so intentional giant power cannot hide a pose-scale regression.
 caught=False
 for attempt in range(3):
  start_character('owl');started=time.monotonic();held=False
  while time.monotonic()-started<18:
   d=data()
   if d['state']!='running':break
   if d['ridingGust']=='true' and d['giant']=='false' and d['attacking']=='false':caught=True;break
   player=float(d['playerX']);gust=float(d['nextGust']);width=float(d['gustWidth']);speed=float(d['speed'])
   if d['airborne']=='false':
    page.keyboard.up('Space');held=False
    mushroom=any(i['kind']=='mushroom' and 0<i['x']-player<speed*.40+25 for i in json.loads(d['items']))
    if mushroom or gust>0 and abs(gust-player)<width/2+145:
     page.keyboard.up('j');page.keyboard.down('Space');held=True
    else:page.keyboard.down('j')
   else:page.keyboard.up('j')
   page.wait_for_timeout(20)
  if caught:break
  page.keyboard.up('Space');page.keyboard.up('j')
 check(caught,'A normal-sized owl catches an actual naturally spawned updraft')
 check(abs(float(d['heroHeadSize'])-65)<.1 and d['actionSheet']=='true','Owl updraft wingstroke keeps the same normal calibrated head size');page.screenshot(path=str(out/'owl-fixed-updraft.png'));page.keyboard.up('Space');page.keyboard.up('j')
 # The same dropdown uses rotated canvas controls on a portrait phone.
 new_context('cs-CZ',True);click(name='LanguageMenu',touch=True);page.wait_for_selector('canvas[data-language-picker="true"]');page.screenshot(path=str(out/'phone-czech-dropdown.png'));click(name='Language_tr',touch=True);page.wait_for_selector('canvas[lang="tr"]');check(data()['orientation']=='landscape','Touch language dropdown works in the always-landscape phone layout')
 click(name='StartSelect_sheep',touch=True);page.wait_for_selector('canvas[data-character="sheep"]');check(data()['characterName']=='Kutsanmış Cahil Koyun','Touch starting-screen choice uses the exact Turkish sheep name')
 check(not errors,'No browser or Godot script errors in localized menu/pose flows');browser.close()
(out/'localization-results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2)+'\n');print(len(results),'localization browser checks passed')
