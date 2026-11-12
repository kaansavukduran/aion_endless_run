"""Normal UI + virtual standard Gamepad API device; no game-state setters.
Physical Xbox/PS hardware is not available in this cloud executor.
"""
import argparse,json,time
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--url',default='http://127.0.0.1:8779');p.add_argument('--evidence',type=Path,default=Path('work/encounters-evidence'));a=p.parse_args();a.evidence.mkdir(parents=True,exist_ok=True)
results=[];errors=[];timeline=[]
def check(v,m):
 assert v,m
 results.append(m);print('PASS',m,flush=True)
with sync_playwright() as pw:
 browser=pw.chromium.launch(args=['--no-sandbox','--enable-unsafe-swiftshader']);ctx=browser.new_context(viewport={'width':1152,'height':648},locale='tr-TR');page=ctx.new_page()
 page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda m:errors.append(m.text) if 'SCRIPT ERROR' in m.text or 'ERROR:' in m.text else None)
 ctx.add_init_script('''(() => {const pad={id:'Xbox 360 Controller (XInput STANDARD GAMEPAD)',index:0,connected:true,mapping:'standard',timestamp:0,axes:[0,0,0,0],buttons:Array.from({length:17},()=>({pressed:false,touched:false,value:0}))};window.virtualPad=pad;Object.defineProperty(navigator,'getGamepads',{value:()=>pad.connected?[pad]:[]});window.padButton=(i,v)=>{pad.buttons[i]={pressed:v>.5,touched:v>0,value:v};pad.timestamp=performance.now();};window.padConnect=id=>{pad.connected=false;const gone=new Event('gamepaddisconnected');Object.defineProperty(gone,'gamepad',{value:pad});window.dispatchEvent(gone);pad.id=id;pad.connected=true;const arrived=new Event('gamepadconnected');Object.defineProperty(arrived,'gamepad',{value:pad});window.dispatchEvent(arrived);};})();''')
 def d():return page.locator('canvas').evaluate('c=>({...c.dataset})')
 def wait(sel):page.wait_for_selector('canvas'+sel,timeout=90000)
 def button(i):
  page.evaluate('i=>padButton(i,1)',i);page.wait_for_timeout(140);page.evaluate('i=>padButton(i,0)',i);page.wait_for_timeout(140)
 def click(name=None,text=None):
  wait('[data-ui-ready="true"]');v=d();b=next(b for b in json.loads(v['ui']) if (b['name']==name if name else text in b['text']));t=json.loads(v['screenTransform']);r=page.locator('canvas').bounding_box();x=b['x']+b['w']/2;y=b['y']+b['h']/2;page.mouse.click(r['x']+(t[0]*x+t[2]*y+t[4])/float(v['rawWidth'])*r['width'],r['y']+(t[1]*x+t[3]*y+t[5])/float(v['rawHeight'])*r['height'])
 page.goto(a.url);wait('[data-version="0.13.0"][data-state="ready"][data-ui-ready="true"]')
 button(0);wait('[data-state="running"]');check(True,'Virtual Xbox A activates the actual focused Start action')
 button(9);wait('[data-page="paused"]');check(True,'Start opens Pause')
 button(13);button(2);wait('[data-page="main"]');check(True,'D-pad and X activate Main menu from Pause')
 button(0);wait('[data-state="running"]');button(9);wait('[data-page="paused"]');button(13);button(13);button(0);wait('[data-page="settings"]');check(True,'A selects Settings through directional menu navigation')
 button(1);wait('[data-page="paused"]');button(0);wait('[data-state="running"]');check(True,'B returns and A resumes the actual paused run')
 wait('[data-page="finished"]');page.screenshot(path=str(a.evidence/'gamepad-result-menu.png'));button(0);wait('[data-state="running"]');check(True,'A activates Run again after a real collision')
 wait('[data-page="finished"]');button(13);button(13);button(2);wait('[data-page="settings"]');check(True,'X activates Settings on the actual game-over menu')
 button(1);wait('[data-page="finished"]');button(13);button(0);wait('[data-page="main"]');check(True,'D-pad and A activate Main menu after game over')
 for profile in ['Sony Interactive Entertainment Wireless Controller (STANDARD GAMEPAD)','Sony DualSense Wireless Controller (STANDARD GAMEPAD)']:
  page.evaluate('id=>padConnect(id)',profile);page.wait_for_timeout(200);button(0);wait('[data-state="running"]');button(9);wait('[data-page="paused"]');button(0);wait('[data-state="running"]');button(9);wait('[data-page="paused"]');button(13);button(2);wait('[data-page="main"]');check(True,'Standard PlayStation mapping activates/resumes/navigates: '+profile)
 click(name='StartSelect_sheep');wait('[data-character="sheep"]');click(text='Boss antrenmanı');wait('[data-page="bosses"]')
 start_best=d()['best']
 for kind in range(3):
  click(name='PracticeBoss_'+str(kind));wait('[data-boss-phase="fight"]');v=d();check(v['bossKind']==str(kind) and v['practice']=='true','Normal training UI starts distinct boss '+str(kind));check(json.loads(v['followerVisible'])==[True,True],'Both follower sheep remain rendered in boss '+str(kind))
  for attempt in range(3):
   page.evaluate('padButton(7,1)');deadline=time.monotonic()+55;captured=False;patterns=set();phase_two=False;duck=False;jump=False
   while time.monotonic()<deadline:
    v=d();phase=v['bossPhase']
    if phase in ['victory','run'] or v['page']=='bosses':break
    if v['state']!='running':
     print('Normal controller retry',kind,attempt,v['bossHp'],v['bossPlayerHp'],flush=True);break
    player=float(v['playerX']);ps=[q for q in json.loads(v['projectiles']) if q['owner']=='boss' and q['x']>player-50]
    high=any(q['kind']=='bolt' and -50<q['x']-player<330 for q in ps)
    low=any(q['kind'] in ['ember','seed'] and 0<(q['x']-player)/abs(q['vx'])<(.30 if v['bossPattern']=='seeds' else .40) for q in ps)
    if high!=duck:page.evaluate('v=>padButton(1,v?1:0)',high);duck=high
    need_jump=low and v['airborne']=='false'
    if need_jump!=jump:page.evaluate('v=>padButton(0,v?1:0)',need_jump);jump=need_jump
    patterns.add(v['bossPattern']);phase_two=phase_two or int(v['bossHp'])<=int(v['bossMaxHp'])//2
    if not captured and int(v['bossHits'])>=5 and not ps:
     page.screenshot(path=str(a.evidence/('boss-'+str(kind)+'-three-sheep.png')));captured=True
    timeline.append({'boss':kind,'hp':v['bossHp'],'shots':v['bossShots'],'health':v['bossPlayerHp'],'pattern':v['bossPattern'],'followers':v['followerVisible']})
    page.wait_for_timeout(15)
   page.evaluate('()=>[0,1,7].forEach(i=>padButton(i,0))')
   if int(d()['bossWins'])==1:break
   wait('[data-page="finished"]');button(0);wait('[data-boss-phase="fight"]')
  check(int(d()['bossWins'])==1,'Actual RT/R2 fire damages and defeats moving boss '+str(kind))
  check(len(patterns)>=3 and phase_two,'Boss '+str(kind)+' uses varied attacks and a half-health phase')
  wait('[data-page="bosses"]');check(d()['best']==start_best,'Training boss '+str(kind)+' preserves the actual saved record')
 check(not errors,'No uncaught browser or Godot errors in gamepad/boss flows');browser.close()
(a.evidence/'encounter-results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2)+'\n');(a.evidence/'boss-timeline.json').write_text(json.dumps(timeline,indent=2)+'\n');print(len(results),'encounter browser checks passed')
