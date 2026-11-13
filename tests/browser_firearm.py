"""0.17 normal UI/input flows. A known legacy save fixture models the reported
Italian/light/200% setup; no writable game/RNG/spawn/physics hooks are used.
"""
import argparse,json,re,time
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--url',default='http://127.0.0.1:8781');p.add_argument('--skip-menu',action='store_true');p.add_argument('--menu-only',action='store_true');p.add_argument('--evidence',type=Path,required=True);a=p.parse_args();a.evidence.mkdir(parents=True,exist_ok=True)
checks=[];errors=[];samples={}
def check(ok,label):
 assert ok,label
 checks.append(label);print('PASS',label,flush=True)
with sync_playwright() as pw:
 browser=pw.chromium.launch(args=['--no-sandbox','--enable-unsafe-swiftshader'])
 def context(size,locale='tr-TR',seed=False):
  c=browser.new_context(viewport={'width':size[0],'height':size[1]},has_touch=True,locale=locale,service_workers='block',record_video_dir=str(a.evidence/'video'))
  c.add_init_script("""const pad={id:'Xbox Standard Controller',index:0,connected:true,mapping:'standard',timestamp:0,axes:[0,0,0,0],buttons:Array.from({length:17},()=>({pressed:false,touched:false,value:0}))};Object.defineProperty(navigator,'getGamepads',{value:()=>[pad]});window.padSet=(i,v)=>{pad.buttons[i]={pressed:v,touched:v,value:v?1:0};pad.timestamp=performance.now()};""")
  if seed:
   config='[meta]\nschema=1\nrevision=91\n[prefs]\nlanguage="it"\nlanguage_override=true\ntheme_mode="light"\ntext_scale=2.0\ntouch_tutorial_done=true\n[records]\nbest=43210\nbest_level=7\n'
   if a.skip_menu:config=config.replace('text_scale=2.0','text_scale=1.0').replace('theme_mode="light"','theme_mode="dark"').replace('language_override=true','language_override=false')+'[migration]\nunused=true\n'
   c.add_init_script('if(!localStorage.getItem("firearm-fixture-seeded")){localStorage.setItem("aion-runner-save-v1",JSON.stringify('+json.dumps({'schema':1,'revision':91,'config':config})+'));localStorage.setItem("firearm-fixture-seeded","1")}')
  page=c.new_page();page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda m:errors.append(m.text) if 'SCRIPT ERROR' in m.text else None);page.goto(a.url);page.wait_for_selector('canvas[data-state="ready"][data-ui-ready="true"]',timeout=120000);return c,page
 def d(page):return page.locator('canvas').evaluate('c=>({...c.dataset})')
 def wait(page,attrs):
  try:page.wait_for_selector('canvas'+attrs,timeout=15000)
  except Exception:
   print('WAIT_FAILED',attrs,json.dumps(d(page),ensure_ascii=False)[:6000],flush=True);raise
 def xy(page,x,y):
  v=d(page);t=json.loads(v['screenTransform']);r=page.locator('canvas').bounding_box();return r['x']+(t[0]*x+t[2]*y+t[4])/float(v['rawWidth'])*r['width'],r['y']+(t[1]*x+t[3]*y+t[5])/float(v['rawHeight'])*r['height']
 def click(page,name=None,text=None):
  wait(page,'[data-ui-ready="true"]');items=json.loads(d(page)['ui']);matches=[b for b in items if (b['name']==name if name else b['text']==text)];
  if not matches:raise AssertionError(('MISSING_BUTTON',name,text,d(page)))
  b=matches[0];page.touchscreen.tap(*xy(page,b['x']+b['w']/2,b['y']+b['h']/2))
 def semantic(page,pattern):
  found=page.locator('#aion-accessibility-controls').get_by_role('button',name=re.compile(pattern))
  if found.count():found.press('Enter');return
  while int(d(page).get('menuPage','0'))>0:
   old=d(page)['menuPage'];click(page,name='PreviousPage');page.wait_for_function('(n)=>document.querySelector("canvas").dataset.menuPage!==n',arg=old);wait(page,'[data-ui-ready="true"]')
  for _ in range(60):
   found=page.locator('#aion-accessibility-controls').get_by_role('button',name=re.compile(pattern))
   if found.count():found.press('Enter');return
   old=d(page)['menuPage'];click(page,name='NextPage');page.wait_for_function('(n)=>document.querySelector("canvas").dataset.menuPage!==n',arg=old);wait(page,'[data-ui-ready="true"]')
  raise AssertionError('No reachable option: '+pattern)
 def action(page,name):
  v=d(page);b=json.loads(v['controls'])[name];return xy(page,b['x']+b['w']/2,b['y']+b['h']/2)
 def menu(page,english=False):
  if d(page)['page']=='':
   page.locator('canvas').focus();page.keyboard.press('Escape')
   page.wait_for_function("['paused','finished'].includes(document.querySelector('canvas').dataset.page)",timeout=15000)
  if d(page)['page']!='main':click(page,text='Main menu' if english else 'Ana menü')
  wait(page,'[data-state="ready"][data-ui-ready="true"]')
 def bounds(page):
  v=d(page);bs=[b for b in json.loads(v['ui']) if b['name'].startswith('StartSelect_') or b['name']=='StartRun' or b['text'] in ['Ayarlar','Boss antrenmanı']]
  fit=all(b['x']>=-1 and b['y']>=-1 and b['x']+b['w']<=float(v['viewWidth'])+1 and b['y']+b['h']<=float(v['viewHeight'])+1 for b in bs)
  overlap=False
  for i,b in enumerate(bs):
   for other in bs[i+1:]:overlap|=min(b['x']+b['w'],other['x']+other['w'])-max(b['x'],other['x'])>1 and min(b['y']+b['h'],other['y']+other['h'])-max(b['y'],other['y'])>1
  return len(bs)==8 and fit and not overlap
 c,page=context((2048,1024),seed=True)
 if not a.skip_menu:
  check(page.locator('canvas').get_attribute('lang')=='tr' and d(page)['languageOverride']=='false','Legacy Italian override follows the Turkish device/browser locale')
  check(d(page)['theme']=='light' and float(d(page)['textScale'])==2 and d(page)['best']=='43210','Language migration preserves light theme,200% text and records')
  for w,h in [(2048,1024),(393,873),(768,1024),(873,393)]:
   page.set_viewport_size({'width':w,'height':h});page.wait_for_function('(ratio)=>{const d=document.querySelector("canvas").dataset;return Math.abs(Number(d.rawWidth)/Number(d.rawHeight)-ratio)<.025&&d.uiReady==="true"}',arg=w/h)
   check(bounds(page),f'At200% all five cards and three main actions fit without overlap: {w}x{h}')
   page.screenshot(path=str(a.evidence/f'main-large-{w}x{h}.png'))
  page.set_viewport_size({'width':1100,'height':620});page.wait_for_function('Math.abs(Number(document.querySelector("canvas").dataset.rawWidth)/Number(document.querySelector("canvas").dataset.rawHeight)-1100/620)<.025&&document.querySelector("canvas").dataset.uiReady==="true"')
  click(page,name='LanguageMenu');semantic(page,r'^IT\s+Italiano$');wait(page,'[lang="it"]');page.reload();wait(page,'[data-state="ready"][data-ui-ready="true"]')
  check(page.locator('canvas').get_attribute('lang')=='it' and d(page)['languageOverride']=='true','A new explicit language choice persists after reopening')
  click(page,name='LanguageMenu');semantic(page,r'^Lingua di sistema');wait(page,'[lang="tr"]');page.reload();wait(page,'[data-state="ready"][data-ui-ready="true"]')
  check(page.locator('canvas').get_attribute('lang')=='tr' and d(page)['languageOverride']=='false' and d(page)['best']=='43210','System language can be restored and survives reopening with the record')
  click(page,text='Ayarlar');semantic(page,r'^\[ \] 100%$');wait(page,'[data-text-scale="1.0"]');semantic(page,r'^\[ \] Koyu$');wait(page,'[data-theme="dark"]');page.locator('canvas').focus();page.keyboard.press('Escape');wait(page,'[data-page="main"]')
  page.screenshot(path=str(a.evidence/'main-dark-1100x620.png'))
 else:
  page.set_viewport_size({'width':1100,'height':620});page.wait_for_timeout(400)
 if a.menu_only:
  check(not errors,'No browser or script errors in menu/language migration flows');c.close();browser.close()
  (a.evidence/'result.json').write_text(json.dumps({'checks':checks,'errors':errors,'scope':'Real menu UI with documented Italian/light/200% legacy preference and record fixture; no running-world injection.'},ensure_ascii=False,indent=2)+'\n');print('RESULT:',len(checks),'menu browser checks');raise SystemExit(0)
 for hero,name in [('aion','Aion'),('sheep','Kutsanmış'),('wolf','Melun'),('owl','Ömer'),('rabbit','Emre')]:
  click(page,name='StartSelect_'+hero);check(d(page)['characterName']==name,'Exact visible hero name: '+name);click(page,name='StartRun');wait(page,'[data-state="running"]')
  page.evaluate('''()=>{window.poses={};new MutationObserver(()=>{const d=document.querySelector('canvas').dataset;if(d.state==='running'&&d.airborne==='false'&&d.shooting==='false')poses[d.sourceFrame]=Number(d.gazeX)}).observe(document.querySelector('canvas'),{attributes:true})}''')
  count=12 if hero=='rabbit' else (8 if hero in ['wolf','owl'] else 7);page.wait_for_function('(n)=>Object.keys(poses).length===n',arg=count);xs=list(page.evaluate('poses').values());samples[hero]=xs
  check(max(xs)-min(xs)<.01 and d(page)['attacking']=='false','Stable faithful pistol loop replaces melee: '+hero)
  page.mouse.move(420,250);page.mouse.down();wait(page,'[data-ammo="4"]')
  page.mouse.up()
  if hero=='aion':
   page.keyboard.press('Space');page.keyboard.press('r');page.wait_for_function('Number(document.querySelector("canvas").dataset.reloading)>0');check(int(d(page)['ammo'])<5,'R starts a visible reload without restoring early rounds');wait(page,'[data-ammo="5"][data-reloading="0.0"]')
   check(d(page)['reloads']=='1','One-second reload restores all five rounds during normal running')
  check(d(page)['levelBarVisible']=='false','No long level progress bar: '+hero)
  if hero=='wolf':
   page.keyboard.down('Shift');wait(page,'[data-boosting="true"][data-pose-source="agility-wolf"][data-gun-overlay="true"]');check(True,'Wolf keeps four-legged sprint with his own pistol overlay');page.keyboard.up('Shift')
  if hero=='owl':
   page.keyboard.down('Space');wait(page,'[data-gliding="true"][data-gun-overlay="true"]');check(d(page)['poseSource']=='agility-owl','Owl retains calm glide with the pistol');page.keyboard.up('Space')
  page.screenshot(path=str(a.evidence/(hero+'-pistol.png')));menu(page)
 click(page,text='Boss antrenmanı');click(page,name='PracticeBoss_0');wait(page,'[data-boss-phase="fight"]');hp=int(d(page)['bossHp'])
 page.mouse.move(420,250);page.mouse.down();wait(page,'[data-ammo="0"]');page.wait_for_function('Number(document.querySelector("canvas").dataset.bossShots)===5');page.mouse.up();page.wait_for_timeout(180)
 check(d(page)['ammo']=='0' and d(page)['bossShots']=='5','Held left click emits exactly five rounds and an empty magazine stops in real combat')
 page.evaluate('padSet(2,true)');page.wait_for_function('Number(document.querySelector("canvas").dataset.reloading)>0');page.evaluate('padSet(2,false)');wait(page,'[data-ammo="5"]');hp=int(d(page)['bossHp']);page.evaluate('padSet(5,true)');page.wait_for_function('(hp)=>Number(document.querySelector("canvas").dataset.bossHp)<hp',arg=hp);page.evaluate('padSet(5,false)');page.evaluate('padSet(2,true)');page.wait_for_function('Number(document.querySelector("canvas").dataset.reloading)>0');page.evaluate('padSet(2,false)')
 check(True,'RB fires real boss-damaging bullets and X/Square manually reloads')
 page.keyboard.press('Escape');wait(page,'[data-state="paused"]');before=d(page);page.set_viewport_size({'width':393,'height':873});wait(page,'[data-orientation="portrait"][data-ui-ready="true"]');after=d(page);check(after['ammo']==before['ammo'] and after['reloading']==before['reloading'] and after['score']==before['score'],'Pause and rotation preserve magazine, reload timer and run state');c.close()
 c,page=context((393,873),locale='en-GB');click(page,name='StartRun');click(page,text='Got it · Continue');wait(page,'[data-state="running"]');cdp=c.new_cdp_session(page)
 fire=action(page,'shoot');cdp.send('Input.dispatchTouchEvent',{'type':'touchStart','touchPoints':[{'x':fire[0],'y':fire[1],'id':0}]});wait(page,'[data-ammo="4"]');cdp.send('Input.dispatchTouchEvent',{'type':'touchCancel','touchPoints':[]});wait(page,'[data-touch-fingers="0"]');saved=d(page)['ammo'];page.wait_for_timeout(400)
 check(d(page)['ammo']==saved,'Cancelling a Fire touch releases the trigger without extra shots')
 reload=action(page,'attack');page.touchscreen.tap(*reload);page.wait_for_function('Number(document.querySelector("canvas").dataset.reloading)>0');wait(page,'[data-ammo="5"]');check(True,'Portrait Reload circle restores the shared five-round magazine')
 page.keyboard.press('Escape');wait(page,'[data-state="paused"]');page.screenshot(path=str(a.evidence/'portrait-weapon-paused.png'));check(not errors,'No browser or Godot script errors in all menu, gun, reload and rotation flows');c.close();browser.close()
(a.evidence/'result.json').write_text(json.dumps({'checks':checks,'errors':errors,'gaze_samples':samples,'scope':'Actual UI, key/mouse/touch and standard Gamepad API input. A documented legacy save fixture seeds settings/records only, never the running world.'},ensure_ascii=False,indent=2)+'\n');print('RESULT:',len(checks),'firearm browser checks')
