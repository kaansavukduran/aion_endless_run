"""Real inputs only. No world, inventory, physics or RNG setters."""
import argparse,json,time,re
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--url',default='http://127.0.0.1:8781');p.add_argument('--evidence',type=Path,required=True);a=p.parse_args();a.evidence.mkdir(parents=True,exist_ok=True)
checks=[];errors=[];peaks={};rolls={}
def check(ok,label):
 if not ok and 'd' in globals():print('CHECK_STATE',{k:d().get(k) for k in ['state','page','charging','jumps','playerY','touchInput','touchTrace']},flush=True)
 assert ok,label
 checks.append(label);print('PASS',label,flush=True)
with sync_playwright() as pw:
 browser=pw.chromium.launch(args=['--no-sandbox','--enable-unsafe-swiftshader']);ctx=browser.new_context(viewport={'width':1100,'height':620},locale='tr-TR',has_touch=True,service_workers='block',record_video_dir=str(a.evidence/'video'))
 ctx.add_init_script("const pad={id:'Xbox Controller',index:0,connected:true,mapping:'standard',timestamp:0,axes:[0,0,0,0],buttons:Array.from({length:17},()=>({pressed:false,touched:false,value:0}))};Object.defineProperty(navigator,'getGamepads',{value:()=>[pad]});window.padSet=(i,v)=>{pad.buttons[i]={pressed:v,touched:v,value:v?1:0};pad.timestamp=performance.now()};")
 page=ctx.new_page();page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda m:errors.append(m.text) if 'SCRIPT ERROR' in m.text else None);page.goto(a.url);page.wait_for_selector('canvas[data-state="ready"][data-ui-ready="true"]',timeout=120000)
 def d():return page.locator('canvas').evaluate('c=>({...c.dataset})')
 def wait(attrs):
  try:page.wait_for_selector('canvas'+attrs,timeout=20000)
  except Exception:
   print('WAIT_FAILED',attrs,{k:d().get(k) for k in ['state','page','charging','chargeRatio','airborne','jumps','playerY','touchInput','touchTrace','controls']},flush=True);raise
 def xy(x,y):
  v=d();t=json.loads(v['screenTransform']);r=page.locator('canvas').bounding_box();return r['x']+(t[0]*x+t[2]*y+t[4])/float(v['rawWidth'])*r['width'],r['y']+(t[1]*x+t[3]*y+t[5])/float(v['rawHeight'])*r['height']
 def ui(name=None,text=None):
  wait('[data-ui-ready="true"]');items=json.loads(d()['ui']);b=next(x for x in items if (x['name']==name if name else x['text']==text));page.touchscreen.tap(*xy(b['x']+b['w']/2,b['y']+b['h']/2))
 def action(name):
  b=json.loads(d()['controls'])[name];return xy(b['x']+b['w']/2,b['y']+b['h']/2)
 def menu():
  if d()['page']=='':
   page.locator('canvas').focus();page.keyboard.press('Escape');page.wait_for_function("['paused','finished'].includes(document.querySelector('canvas').dataset.page)")
  if d()['page']!='main':ui(text='Ana menü')
  wait('[data-state="ready"][data-ui-ready="true"]')
 def start(hero):
  if d()['page']!='main':menu()
  ui(name='StartSelect_'+hero);ui(name='StartRun');wait('[data-state="running"][data-ui-ready="true"]')
  if any(x['text']=='Anladım · Devam et' for x in json.loads(d()['ui'])):ui(text='Anladım · Devam et')
  page.wait_for_function('Number(document.querySelector("canvas").dataset.worldTime)>.02')
 cdp=ctx.new_cdp_session(page)
 def touch(point,down):cdp.send('Input.dispatchTouchEvent',{'type':'touchStart' if down else 'touchEnd','touchPoints':[{'x':point[0],'y':point[1],'id':0}] if down else []})
 def observe_roll():page.evaluate("window.rollObserver?.disconnect();window.roll=[];window.rollObserver=new MutationObserver(()=>{const d=document.querySelector('canvas').dataset;if(d.ducking==='true'&&(d.poseSource==='shoulder-rolls'||d.poseSource==='eren-animations'))roll.push({frame:Number(d.sourceFrame),height:Number(d.heroOpaqueHeight),y:Number(d.playerY),time:Number(d.worldTime)})});window.rollObserver.observe(document.querySelector('canvas'),{attributes:true})")
 for hero,kind in [('aion','key'),('owl','pad'),('sheep','touch'),('wolf','key'),('rabbit','key'),('eren','key')]:
  start(hero);height=float(d()['heroOpaqueHeight']);observe_roll()
  if kind=='key':page.keyboard.down('ArrowDown')
  elif kind=='pad':page.evaluate('padSet(1,true)')
  else:touch(action('duck'),True)
  try:page.wait_for_function('roll.some(p=>p.frame<=2)&&roll.some(p=>p.frame>=3&&p.frame<=8)')
  except Exception:
   print('ROLL_FAILED',hero,{k:d().get(k) for k in ['state','page','ducking','poseSource','sourceFrame','touchInput','touchTrace','touchFingers']},page.evaluate('roll.slice(0,10)'),flush=True);page.screenshot(path=str(a.evidence/'roll-failed.png'));raise
  check(min(x['height'] for x in page.evaluate('roll'))<height*.92 and d()['playerY']=='0.0','Drawn knee bend leads to a lower ground-contact roll: '+hero)
  try:page.wait_for_function('roll.some(p=>p.time-roll[0].time>.85)')
  except Exception:
   print('HOLD_FAILED',hero,{k:d().get(k) for k in ['state','page','ducking','touchTrace','worldTime']},page.evaluate('roll[-1]') if False else page.evaluate('roll.slice(-3)'),flush=True);raise
  check(all(x['frame']==(2 if hero=='eren' else 3) for x in page.evaluate('roll.filter(p=>p.time-roll[0].time>.7)')),'One shoulder roll settles into a low held stance: '+hero);rolls[hero]=page.evaluate('roll')
  page.screenshot(path=str(a.evidence/(hero+'-low-roll.png')))
  if kind=='key':page.keyboard.up('ArrowDown')
  elif kind=='pad':page.evaluate('padSet(1,false)')
  else:touch(None,False)
  wait('[data-ducking="false"]');check(d()['attacking']=='false','Release recovers to pistol running without melee: '+hero);menu()
 def observe_jump():page.evaluate("window.leapObserver?.disconnect();window.leap={peak:0,last:0,air:false,apex:false,maxJumps:0,launches:0,lastAir:false};window.leapObserver=new MutationObserver(()=>{const d=document.querySelector('canvas').dataset;const y=Number(d.playerY);if(y<0&&!leap.lastAir)leap.launches++;leap.lastAir=y<0;if(y<0){leap.air=true;leap.maxJumps=Math.max(leap.maxJumps,Number(d.jumps));leap.peak=Math.max(leap.peak,-y);if(y>leap.last+.01&&leap.last<-10)leap.apex=true;leap.last=y}});window.leapObserver.observe(document.querySelector('canvas'),{attributes:true})")
 for kind,ratio in [('key',.1),('pad',.5),('touch',1.0)]:
  start('rabbit');observe_jump();point=action('jump')
  if kind=='key':page.keyboard.down('Space')
  elif kind=='pad':page.evaluate('padSet(0,true)')
  else:touch(point,True)
  page.wait_for_function('(n)=>Number(document.querySelector("canvas").dataset.chargeRatio)>=n',arg=ratio)
  check(d()['charging']=='true' and d()['airborne']=='false','Emre visibly charges on the ground through '+kind)
  if kind=='touch':page.screenshot(path=str(a.evidence/'emre-full-charge.png'))
  if kind=='key':page.keyboard.up('Space')
  elif kind=='pad':page.evaluate('padSet(0,false)')
  else:touch(None,False)
  wait('[data-charging="false"][data-airborne="true"]');page.wait_for_function('leap.apex',timeout=20000);peaks[kind]=page.evaluate('leap.peak')
  check(page.evaluate('leap.maxJumps===1&&leap.launches===1'),'Release produces exactly one real leap through '+kind)
  if kind=='touch':page.screenshot(path=str(a.evidence/'emre-high-leap.png'))
  menu()
 check(peaks['key']<peaks['pad']<peaks['touch'],'Measured real leap apex increases with the held charge time')
 start('rabbit');page.evaluate("window.cancelAirborne=false;new MutationObserver(()=>{if(document.querySelector('canvas').dataset.airborne==='true')cancelAirborne=true}).observe(document.querySelector('canvas'),{attributes:true})");touch(action('jump'),True);wait('[data-charging="true"]');cdp.send('Input.dispatchTouchEvent',{'type':'touchCancel','touchPoints':[]});wait('[data-charging="false"]');page.wait_for_timeout(200)
 check(not page.evaluate('cancelAirborne'),'A cancelled charging touch never launches the rabbit')
 touch(action('jump'),True);wait('[data-charging="true"]');prior=d();page.set_viewport_size({'width':393,'height':873});wait('[data-orientation="portrait"][data-ui-ready="true"]');check(d()['charging']=='false' and d()['airborne']=='false' and d()['character']=='rabbit' and int(d()['score'])>=int(prior['score']),'Rotation clears a held charge safely and preserves the run');touch(None,False);menu()
 # Real settings paging. Every currently visible action must fit the canvas.
 def fitted():
  v=d();return all(b['x']>=-1 and b['y']>=-1 and b['x']+b['w']<=float(v['viewWidth'])+1 and b['y']+b['h']<=float(v['viewHeight'])+1 for b in json.loads(v['ui']))
 for size in [(1100,620),(393,873)]:
  page.set_viewport_size({'width':size[0],'height':size[1]});page.wait_for_function('(n)=>Math.abs(Number(document.querySelector("canvas").dataset.rawWidth)/Number(document.querySelector("canvas").dataset.rawHeight)-n)<.025',arg=size[0]/size[1]);ui(text='Ayarlar');wait('[data-page="settings"][data-ui-ready="true"]');n=int(d()['menuPages']);seen=[]
  for i in range(n):
   check(fitted(),'Settings page fits without wheel scrolling '+str(size)+'/'+str(i+1));seen.extend(b['name'] for b in json.loads(d()['ui']))
   if i<n-1:
    old=d()['menuPage'];ui(name='NextPage');page.wait_for_function('(old)=>document.querySelector("canvas").dataset.menuPage!==old',arg=old);wait('[data-ui-ready="true"]')
  check('Bind_jump' in seen and 'Option_text_size_2_0' in seen,'Font and gamepad settings remain reachable using page buttons '+str(size));page.screenshot(path=str(a.evidence/('settings-last-'+str(size[0])+'.png')));ui(name='PageBack');wait('[data-page="main"]')
 check(page.evaluate('document.documentElement.scrollHeight<=innerHeight+1&&document.documentElement.scrollWidth<=innerWidth+1'),'The actual browser document has no horizontal or vertical page overflow')
 check(not errors,'No browser or Godot script errors in roll, charge, cancel, paging and rotation flows');report={'checks':checks,'errors':errors,'apex_by_input':peaks,'roll_samples':rolls,'build':page.evaluate('AION_BUILD'),'scope':'Normal menu,key,standard Gamepad API and browser touch input. Only passive observations; no save/world/RNG/inventory injection.'};(a.evidence/'results.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n');ctx.close();browser.close()
print('RESULT:',len(checks),'real low-roll/charged-jump/paged-menu checks')
