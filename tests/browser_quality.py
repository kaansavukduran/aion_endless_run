"""Owner's six-hero quality regression: normal UI and input, passive observations.
Gamepad events use the standard browser API, not a physical controller.
"""
import argparse,json,time
from pathlib import Path
from playwright.sync_api import sync_playwright
parser=argparse.ArgumentParser();parser.add_argument('--url',default='http://127.0.0.1:8781');parser.add_argument('--evidence',type=Path,required=True);parser.add_argument('--menu-only',action='store_true');parser.add_argument('--heroes',nargs='*');parser.add_argument('--record-video',action='store_true');args=parser.parse_args();args.evidence.mkdir(parents=True,exist_ok=True)
checks=[];errors=[];clips={};menu_results=[]
def check(ok,label):
 assert ok,label
 checks.append(label);print('PASS',label,flush=True)
with sync_playwright() as pw:
 browser=pw.chromium.launch(args=['--no-sandbox','--enable-unsafe-swiftshader'])
 ctx=browser.new_context(viewport={'width':1280,'height':720},locale='tr-TR',has_touch=True,service_workers='block',**({'record_video_dir':str(args.evidence/'video')} if args.record_video else {}))
 ctx.add_init_script("const pad={id:'Xbox Controller',index:0,connected:true,mapping:'standard',timestamp:0,axes:[0,0,0,0],buttons:Array.from({length:17},()=>({pressed:false,touched:false,value:0}))};Object.defineProperty(navigator,'getGamepads',{value:()=>[pad]});window.padSet=(i,v)=>{pad.buttons[i]={pressed:v,touched:v,value:v?1:0};pad.timestamp=performance.now()};")
 page=ctx.new_page();page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda m:errors.append(m.text) if 'SCRIPT ERROR' in m.text else None)
 page.goto(args.url);page.wait_for_selector('canvas[data-state="ready"][data-ui-ready="true"]',timeout=120000)
 def d():return page.locator('canvas').evaluate('c=>({...c.dataset})')
 def wait(s):page.wait_for_selector('canvas'+s,timeout=20000)
 def xy(x,y):
  v=d();t=json.loads(v['screenTransform']);r=page.locator('canvas').bounding_box();return r['x']+(t[0]*x+t[2]*y+t[4])/float(v['rawWidth'])*r['width'],r['y']+(t[1]*x+t[3]*y+t[5])/float(v['rawHeight'])*r['height']
 def ui(name=None,text=None):
  wait('[data-ui-ready="true"]');b=next(b for b in json.loads(d()['ui']) if (b['name']==name if name else b['text']==text));page.touchscreen.tap(*xy(b['x']+b['w']/2,b['y']+b['h']/2))
 def action(name):
  b=json.loads(d()['controls'])[name];return xy(b['x']+b['w']/2,b['y']+b['h']/2)
 def menu():
  page.keyboard.up('f');page.keyboard.up('ArrowDown');page.keyboard.up('Space');page.keyboard.up('Shift');page.evaluate('for(let i of [0,1,5,9])padSet(i,false)')
  if d()['page']=='':
   page.locator('canvas').focus();page.keyboard.press('Escape');page.wait_for_function("['paused','finished'].includes(document.querySelector('canvas').dataset.page)")
  if d()['page']!='main':ui(text='Ana menü')
  wait('[data-state="ready"][data-page="main"][data-ui-ready="true"]')
 def start(hero):
  menu();ui(name='StartSelect_'+hero);ui(name='StartRun');wait('[data-state="running"][data-ui-ready="true"]')
  if any(b['text']=='Anladım · Devam et' for b in json.loads(d()['ui'])):ui(text='Anladım · Devam et')
  page.wait_for_function('Number(document.querySelector("canvas").dataset.worldTime)>.02')
 def observer():page.evaluate("window.poseObserver?.disconnect();window.poseSamples=[];window.poseObserver=new MutationObserver(()=>{let d=document.querySelector('canvas').dataset;poseSamples.push({state:d.state,source:d.poseSource,frame:+d.sourceFrame,row:+d.sourceRow,count:+d.frameCount,probeX:+d.headProbeX,probeY:+d.headProbeY,x:+d.visualX,scale:+d.actorScale,time:+d.worldTime,y:+d.playerY,shots:+d.bossShots,height:+d.heroOpaqueHeight,duck:d.ducking==='true'})});poseObserver.observe(document.querySelector('canvas'),{attributes:true})")
 def stable(label,source=None,samples=None):
  rows=page.evaluate('poseSamples') if samples is None else samples;rows=[x for x in rows if x['probeX']>-900 and (not source or x['source']==source)]
  check(bool(rows),label+' has independently registered head samples')
  unique={x['frame'] for x in rows};count=max(x['count'] for x in rows)
  check(len(unique)==count,label+' covers every actual frame '+str(sorted(unique)))
  check(max(x['probeX'] for x in rows)-min(x['probeX'] for x in rows)<.01,label+' face stays horizontally registered')
  check(max(x['x'] for x in rows)-min(x['x'] for x in rows)<.01,label+' physics anchor is never shifted to hide a bad frame')
  check(max(x['scale'] for x in rows)-min(x['scale'] for x in rows)<.00001,label+' has one consistent scale')
  clips[label]=rows
 def fitted(label):
  v=d();buttons=json.loads(v['ui']);w,h=float(v['viewWidth']),float(v['viewHeight']);cards=[b for b in buttons if b['name'].startswith('StartSelect_')]
  check(len(cards)==6,label+' shows Eren and Emre as separate visible choices')
  check(all(b['x']>=-1 and b['y']>=-1 and b['x']+b['w']<=w+1 and b['y']+b['h']<=h+1 for b in buttons),label+' all real buttons fit without a wheel')
  lang=next(b for b in buttons if b['name']=='LanguageMenu');overlap=lambda a,b:a['x']<b['x']+b['w'] and a['x']+a['w']>b['x'] and a['y']<b['y']+b['h'] and a['y']+a['h']>b['y'];check(all(not overlap(lang,b) for b in cards),label+' language control covers no character card')
  rect=json.loads(v['mainPanel']);actions=[b for b in buttons if not b['name'].startswith('StartSelect_') and b['name']!='LanguageButton'];bottom=max(b['y']+b['h'] for b in actions if b['x']<rect[0]+rect[2] and b['y']>=rect[1] and b['y']<rect[1]+rect[3]);gap=rect[1]+rect[3]-bottom
  check(-1<=gap<=32,label+' menu panel ends at actual content, gap='+str(round(gap,2)))
  menu_results.append({'label':label,'panel':rect,'bottom_gap':gap,'buttons':buttons})
 def resize(w,h):
  page.set_viewport_size({'width':w,'height':h});page.wait_for_function('(n)=>Math.abs(Number(document.querySelector("canvas").dataset.rawWidth)/Number(document.querySelector("canvas").dataset.rawHeight)-n)<.025',arg=w/h);wait('[data-ui-ready="true"]');page.wait_for_timeout(200)
 cdp=ctx.new_cdp_session(page)
 def touch(point,down):cdp.send('Input.dispatchTouchEvent',{'type':'touchStart' if down else 'touchEnd','touchPoints':[{'x':point[0],'y':point[1],'id':0}] if down else []})
 try:
  check(page.locator('canvas').get_attribute('lang')=='tr','Fresh profile uses the actual browser language')
  fitted('Dark desktop 100%');page.screenshot(path=str(args.evidence/'main-dark.png'))
  # Capture touch coordinates before the world starts. Inspecting transforms
  # mid-run must not consume the real obstacle/recovery reaction window.
  roll_point=action('duck')
  for hero,roll_input in ([] if args.menu_only else [('aion','key'),('owl','pad'),('sheep','touch'),('wolf','key'),('rabbit','key'),('eren','key')]):
   if args.heroes and hero not in args.heroes:continue
   start(hero);observer();page.wait_for_function('poseSamples.length>0&&new Set(poseSamples.map(x=>x.frame)).size>=Number(document.querySelector("canvas").dataset.frameCount)',timeout=3500);stable(hero+' gun-run');page.screenshot(path=str(args.evidence/(hero+'-running.png')))
   fire_samples=[];shots=0
   for attempt in range(3):
    start(hero);observer();page.wait_for_timeout(attempt*37);page.keyboard.down('f');page.wait_for_timeout(2100);page.keyboard.up('f');rows=page.evaluate('poseSamples');page.keyboard.press('Escape')
    shots=max(shots,max(x['shots'] for x in rows));fire_row=4
    fire_samples.extend(x for x in rows if x['row']==fire_row)
    if fire_samples and len({x['frame'] for x in fire_samples})==max(x['count'] for x in fire_samples):break
   check(shots>=6,hero+' fires more than five bullets with no reload');stable(hero+' gun-fire',samples=fire_samples);check(d()['ammo']=='infinite' and 'attack' not in json.loads(d()['controls']),hero+' has no magazine or Reload control')
   start(hero);height=float(d()['heroOpaqueHeight']);observer()
   if roll_input=='key':page.keyboard.down('ArrowDown')
   elif roll_input=='pad':page.evaluate('padSet(1,true)')
   else:touch(roll_point,True)
   wait('[data-ducking="true"]');page.wait_for_timeout(920)
   if roll_input=='key':page.keyboard.up('ArrowDown')
   elif roll_input=='pad':page.evaluate('padSet(1,false)')
   else:touch(None,False)
   rows=[x for x in page.evaluate('poseSamples') if x['duck']];late=[x for x in rows if x['time']-rows[0]['time']>.75]
   recovery_row=3
   page.wait_for_function('(v)=>poseSamples.some(p=>p.time>v.time&&p.state==="running"&&!p.duck&&p.row===v.row)',arg={'time':rows[-1]['time'],'row':recovery_row},timeout=1500)
   recovered=page.evaluate('(v)=>poseSamples.find(p=>p.time>v.time&&p.state==="running"&&!p.duck&&p.row===v.row)',{'time':rows[-1]['time'],'row':recovery_row});page.keyboard.press('Escape')
   check(any(x['frame']>=4 for x in rows) and bool(late) and all(x['frame']==5 for x in late),hero+' bends, shoulder rolls once, then remains visibly low')
   check(min(x['height'] for x in rows)<height*.93 and all(x['y']==0 for x in rows),hero+' lowers the actual drawing while staying on the ground')
   check(recovered['state']=='running' and not recovered['duck'],hero+' visibly recovers to its own pistol-run design before the next hazard')
  if not args.menu_only:
   start('wolf');observer();page.keyboard.down('Shift');wait('[data-boosting="true"]');page.wait_for_timeout(900);stable('Wolf four-leg sprint','pixel-wolf');page.keyboard.up('Shift')
   start('owl');page.keyboard.down('Space');wait('[data-gliding="true"]');observer();page.wait_for_timeout(1100);stable('Owl steady glide','pixel-owl');page.screenshot(path=str(args.evidence/'owl-gliding.png'));page.keyboard.up('Space')
   start('rabbit');page.keyboard.down('Space');wait('[data-charging="true"]');page.wait_for_function('Number(document.querySelector("canvas").dataset.chargeRatio)>.7');check(d()['airborne']=='false','Emre still charges on the ground');page.keyboard.up('Space');wait('[data-airborne="true"]');check(d()['character']=='rabbit','Emre releases his own charged leap')
   start('eren');page.keyboard.down('Space');wait('[data-airborne="true"]');check(d()['charging']=='false' and d()['poseSource']=='pixel-eren','Eren has his own immediate single jump');page.screenshot(path=str(args.evidence/'eren-jumping.png'));page.keyboard.up('Space')
   start('aion');touch(action('shoot'),True);page.wait_for_function('Number(document.querySelector("canvas").dataset.bossShots)>=2');cdp.send('Input.dispatchTouchEvent',{'type':'touchCancel','touchPoints':[]});page.wait_for_timeout(450);shots=d()['bossShots'];page.wait_for_timeout(400);check(d()['bossShots']==shots,'Cancelling a Fire touch never leaves the trigger latched')
   for confirm in [0,2]:
    start('aion');page.evaluate('padSet(9,true)');wait('[data-page="paused"]');page.evaluate('padSet(9,false)');page.wait_for_timeout(120);page.evaluate('(n)=>padSet(n,true)',confirm);wait('[data-state="running"]');page.evaluate('(n)=>padSet(n,false)',confirm);check(True,'Gamepad Start and '+('A/×' if confirm==0 else 'X/□')+' actually pause and resume the selected menu action')
   start('aion');page.keyboard.press('Escape');wait('[data-page="paused"]');before=d();resize(393,873);after=d();check(before['score']==after['score'] and before['character']==after['character'],'Paused rotation preserves the run and character');page.screenshot(path=str(args.evidence/'portrait-paused.png'));menu()
  def option(name):
   for _ in range(30):
    names=[b['name'] for b in json.loads(d()['ui'])]
    if name in names:ui(name=name);return
    if 'NextPage' not in names:break
    old=d()['menuPage'];ui(name='NextPage');page.wait_for_function('(n)=>document.querySelector("canvas").dataset.menuPage!==n',arg=old);wait('[data-ui-ready="true"]')
   raise AssertionError('Missing settings option '+name)
  ui(text='Ayarlar');wait('[data-page="settings"]');option('Option_theme_light');option('Option_text_size_2_0');ui(name='PageBack');wait('[data-page="main"]')
  for w,h in [(393,873),(873,393),(2048,1024)]:resize(w,h);fitted('Light 200% '+str(w)+'x'+str(h));page.screenshot(path=str(args.evidence/('main-light-200-'+str(w)+'.png')))
  check(page.evaluate('document.documentElement.scrollHeight<=innerHeight+1&&document.documentElement.scrollWidth<=innerWidth+1'),'Browser document has no horizontal or vertical page scroll')
  check(not errors,'No browser or Godot script errors in the selected real-input flows')
 finally:
  report={'checks':checks,'errors':errors,'clips':clips,'hero_subset':args.heroes or 'all six','menus':menu_results,'build':page.evaluate('AION_BUILD'),'scope':'Actual normal UI, keyboard, browser CDP touch and emulated standard Gamepad API; only passive pose probes, no world, save, inventory or RNG setters. Source-template evidence separately verifies registration against original PNG pixels.'};(args.evidence/'results.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n');ctx.close();browser.close()
print('RESULT:',len(checks),'real-input quality checks')
