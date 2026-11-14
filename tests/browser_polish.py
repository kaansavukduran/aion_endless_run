"""Ordinary-input ability and splash regression. No game-state setters.
Gamepad uses the standard browser API; touch uses trusted CDP input.
"""
import argparse,json
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--url',default='http://127.0.0.1:8781');p.add_argument('--evidence',type=Path,required=True);a=p.parse_args();a.evidence.mkdir(parents=True,exist_ok=True)
checks=[];errors=[];reports=[]
def check(ok,label):
 assert ok,label
 checks.append(label);print('PASS',label,flush=True)
with sync_playwright() as pw:
 browser=pw.chromium.launch(args=['--no-sandbox','--enable-unsafe-swiftshader']);ctx=browser.new_context(viewport={'width':873,'height':393},locale='tr-TR',has_touch=True,service_workers='block')
 ctx.add_init_script("const pad={id:'Xbox Controller',index:0,connected:true,mapping:'standard',timestamp:0,axes:[0,0,0,0],buttons:Array.from({length:17},()=>({pressed:false,touched:false,value:0}))};Object.defineProperty(navigator,'getGamepads',{value:()=>[pad]});window.padSet=(i,v)=>{pad.buttons[i]={pressed:v,touched:v,value:v?1:0};pad.timestamp=performance.now()};window.splashColors=[];window.splashObserver=new MutationObserver(()=>{const p=document.querySelector('#aion-loading-percent'),s=[...document.querySelectorAll('.fragaria-segments i')];if(p&&s.length===10&&((p.textContent.includes('100')&&!s[0].parentElement.classList.contains('indeterminate'))||s[0].parentElement.classList.contains('indeterminate')))splashColors.push({text:p.textContent,colors:s.map(n=>getComputedStyle(n).backgroundColor),label:getComputedStyle(p).color,indeterminate:s[0].parentElement.classList.contains('indeterminate')})});splashObserver.observe(document,{childList:true,subtree:true,attributes:true,characterData:true});")
 page=ctx.new_page();page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda m:errors.append(m.text) if 'SCRIPT ERROR' in m.text else None);page.goto(a.url);page.wait_for_selector('canvas[data-state="ready"][data-ui-ready="true"]',timeout=120000)
 def d():return page.locator('canvas').evaluate('c=>({...c.dataset})')
 def wait(s):
  try:page.wait_for_selector('canvas'+s,timeout=10000)
  except Exception:
   print('INPUT FAILURE',s,{k:d().get(k) for k in ['state','page','worldTime','playerY','jumpHeld','owlFlapsLeft','owlFlapTime','poseSource','sourceRow','character']},flush=True);raise
 def xy(x,y):
  v=d();t=json.loads(v['screenTransform']);r=page.locator('canvas').bounding_box();return r['x']+(t[0]*x+t[2]*y+t[4])/float(v['rawWidth'])*r['width'],r['y']+(t[1]*x+t[3]*y+t[5])/float(v['rawHeight'])*r['height']
 def ui(name=None,text=None):
  wait('[data-ui-ready="true"]');b=next(b for b in json.loads(d()['ui']) if (b['name']==name if name else b['text']==text));page.touchscreen.tap(*xy(b['x']+b['w']/2,b['y']+b['h']/2))
 def start(hero):
  page.keyboard.up('Space');page.evaluate('padSet(0,false)')
  if d()['page']=='':page.keyboard.press('Escape');wait('[data-page="paused"]')
  if d()['page']!='main':ui(text='Ana menü')
  ui(name='StartSelect_'+hero);ui(name='StartRun');wait('[data-state="running"][data-ui-ready="true"]')
  if any(b['text']=='Anladım · Devam et' for b in json.loads(d()['ui'])):ui(text='Anladım · Devam et')
 colors=page.evaluate('splashObserver.disconnect();splashColors');check(bool(colors) and all(r['label']=='rgb(237, 57, 78)' and all(v=='rgb(237, 57, 78)' for v in r['colors']) for r in colors),'Actual startup preparation/complete segments and percentage/ellipsis are strawberry red')
 (a.evidence/'splash-colors.json').write_text(json.dumps(colors,indent=2))
 cdp=ctx.new_cdp_session(page)
 def input_jump(kind,down,point=None):
  if kind=='key':(page.keyboard.down if down else page.keyboard.up)('Space')
  elif kind=='pad':page.evaluate('(v)=>padSet(0,v)',down)
  else:cdp.send('Input.dispatchTouchEvent',{'type':'touchStart' if down else 'touchEnd','touchPoints':[{'id':1,'x':point[0],'y':point[1]}] if down else []})
 for kind in ['key','touch','pad']:
  start('owl');b=json.loads(d()['controls'])['jump'];point=xy(b['x']+b['w']/2,b['y']+b['h']/2)
  page.evaluate("window.abilitySamples=[];window.abilityObserver?.disconnect();window.abilityObserver=new MutationObserver(()=>{let d=document.querySelector('canvas').dataset;abilitySamples.push({left:+d.owlFlapsLeft,y:+d.playerY,t:+d.worldTime,flap:+d.owlFlapTime,source:d.poseSource,row:+d.sourceRow,state:d.state})});abilityObserver.observe(document.querySelector('canvas'),{attributes:true})");input_jump(kind,True,point);wait('[data-gliding="true"]');check(d()['owlFlapsLeft']=='3',kind+' initial takeoff and held glide preserve three flap charges')
  for n in range(3):
   input_jump(kind,False,point);page.wait_for_timeout(60);input_jump(kind,True,point)
   page.wait_for_function('(n)=>abilitySamples.some(p=>p.left===n&&p.flap>0&&p.source==="polish-abilities"&&p.row===1)',arg=2-n,timeout=5000)
   check(True,kind+' flap '+str(n+1)+' selects its actual airborne wing animation')
   page.wait_for_function('(n)=>{let rows=abilitySamples.filter(p=>p.left===n&&p.flap>0&&p.state==="running");return rows.length>1&&rows.some(p=>p.y<rows[0].y-3)}',arg=2-n,timeout=5000)
   samples=page.evaluate('(n)=>abilitySamples.filter(p=>p.left===n&&p.flap>0&&p.state==="running")',2-n)
   check(min(p['y'] for p in samples)<samples[0]['y']-3,kind+' flap '+str(n+1)+' increases actual altitude')
   reports.append({'input':kind,'flap':n+1,'samples':samples})
  input_jump(kind,False,point);page.wait_for_timeout(50);input_jump(kind,True,point);page.wait_for_timeout(60);check(d()['owlFlapsLeft']=='0',kind+' cannot spend a fourth charge');input_jump(kind,False,point);page.keyboard.press('Escape');wait('[data-page="paused"]');page.screenshot(path=str(a.evidence/(kind+'-owl-flap.png')))
 for hero in ['eren','rabbit']:
  launches=[]
  for duration in [180,800]:
   start(hero);page.keyboard.down('Space');wait('[data-charging="true"]');page.wait_for_timeout(duration);check(d()['airborne']=='false',hero+' remains grounded while holding '+str(duration)+'ms');ratio=float(d()['chargeRatio']);page.screenshot(path=str(a.evidence/(hero+'-charge-'+str(duration)+'.png')));page.keyboard.up('Space');wait('[data-airborne="true"][data-charging="false"]');page.wait_for_timeout(100);launches.append({'ratio':ratio,'y':float(d()['playerY'])})
  check(launches[1]['ratio']>launches[0]['ratio'] and launches[1]['y']<launches[0]['y'],hero+' longer held charge yields a visibly higher release leap')
 check(not errors,'No script errors during the real keyboard/touch/gamepad ability matrix');(a.evidence/'polish-browser-results.json').write_text(json.dumps({'checks':checks,'flaps':reports,'errors':errors,'scope':'Real exported game via ordinary UI/input; standard API gamepad emulation, not a physical controller.'},indent=2));ctx.close();browser.close()
print('RESULT:',len(checks),'normal-input polish checks')
