"""Normal-entry combat, powers, platforming, flock and rotated multi-touch.
Reads public canvas state/visible control geometry; never writes game state.
"""
import argparse,json,time
from pathlib import Path
from playwright.sync_api import sync_playwright
parser=argparse.ArgumentParser()
parser.add_argument('--url',default='http://127.0.0.1:8779')
parser.add_argument('--evidence',default='work/adventure-evidence',type=Path)
args=parser.parse_args();out=args.evidence;out.mkdir(parents=True,exist_ok=True)
results=[];errors=[]
def check(value,message):
 assert value,message
 results.append(message)
 print('PASS',message,flush=True)
with sync_playwright() as p:
 browser=p.chromium.launch(args=['--no-sandbox','--enable-unsafe-swiftshader'])
 context=browser.new_context(viewport={'width':1152,'height':648},locale='tr-TR')
 page=None
 def data():return page.locator('canvas').evaluate('(e)=>({...e.dataset})')
 def wait_ui():page.wait_for_selector('canvas[data-ui-ready="true"]',timeout=60000)
 def screen_point(x,y):
  d=data();t=json.loads(d['screenTransform']);rect=page.locator('canvas').bounding_box()
  return {'x':rect['x']+(t[0]*x+t[2]*y+t[4])/float(d['rawWidth'])*rect['width'],'y':rect['y']+(t[1]*x+t[3]*y+t[5])/float(d['rawHeight'])*rect['height']}
 def click_button(text=None,name=None,touch=False):
  wait_ui();buttons=json.loads(data()['ui']);button=next(b for b in buttons if (b.get('name')==name if name else text in b['text']))
  point=screen_point(button['x']+button['w']/2,button['y']+button['h']/2)
  if touch:page.touchscreen.tap(**point)
  else:page.mouse.click(**point)
 def open_game(character='aion'):
  global page
  if page:page.close()
  page=context.new_page();page.on('pageerror',lambda error:errors.append(str(error)));page.on('console',lambda msg:errors.append(msg.text) if 'SCRIPT ERROR' in msg.text else None)
  page.goto(args.url);page.wait_for_selector('canvas[data-state="ready"]',timeout=60000);wait_ui()
  if data()['character']!=character:
   click_button('Karakterler');page.wait_for_selector('canvas[data-page="characters"]');click_button(name='Select_'+character);page.wait_for_selector('canvas[data-character="'+character+'"]');page.keyboard.press('Escape');page.wait_for_selector('canvas[data-page="main"]');wait_ui()
  page.keyboard.press('Space');page.wait_for_selector('canvas[data-state="running"]');wait_ui()
  return data()
 # Genuine attacks for every character, including real enemies and the first
 # nearby mushroom. These are actual user clicks, not a test spawn command.
 for character,row in [('aion',0),('owl',1),('sheep',2),('wolf',3)]:
  open_game(character)
  page.mouse.move(600,270);page.mouse.down()
  page.wait_for_selector('canvas[data-attacking="true"][data-combat-row="'+str(row)+'"]')
  check(True,'Distinct actual attack sheet row: '+character)
  page.wait_for_selector('canvas[data-giant="true"]',timeout=10000)
  check('mushroom' in json.loads(data()['discoveries']),'Real mushroom pickup unlocks giant form: '+character)
  page.wait_for_function('() => Number(document.querySelector("canvas").dataset.kills)>0',timeout=12000)
  check(data()['state']=='running','Held left click causes real enemy damage/defeat: '+character)
  page.screenshot(path=str(out/(character+'-combat.png')))
  page.mouse.up()
 # Pause, local discovery persistence, TR/EN and independent screen effects.
 page.keyboard.press('Escape');page.wait_for_selector('canvas[data-state="paused"]')
 frozen=json.loads(data()['powers'])['mushroom'];page.wait_for_timeout(500)
 check(json.loads(data()['powers'])['mushroom']==frozen,'Pause freezes active power duration')
 click_button('Ayarlar');click_button('English');page.wait_for_selector('canvas[lang="en"]');wait_ui()
 check(data()['page']=='settings','New controls/power help change language without leaving settings')
 click_button('Gentle camera');page.wait_for_selector('canvas[data-effects-enabled="false"]')
 check(True,'Screen effects can be switched off independently')
 page.screenshot(path=str(out/'settings-en.png'))
 page.wait_for_timeout(2200);page.reload();page.wait_for_selector('canvas[data-state="ready"]',timeout=60000);wait_ui()
 check(data()['effectsEnabled']=='false' and 'mushroom' in json.loads(data()['discoveries']),'Effects and discovered powers survive a real reload')
 click_button('Settings');click_button('Türkçe');page.keyboard.press('Escape');wait_ui();page.wait_for_timeout(2200)
 # Stomp a naturally arriving gnome. The vertical trajectory is controlled
 # with Space, with approach time calculated from the observable real speed.
 open_game('aion');started=time.monotonic();stomped=False
 while time.monotonic()-started<18:
  d=data()
  if d['state']!='running':break
  enemies=[e for e in json.loads(d['enemies']) if e['kind']=='gnome' and e['hp']>0 and e['x']>float(d['playerX'])-20]
  if int(d['stomps'])>0:stomped=True;break
  if enemies and d['airborne']=='false':
   target=min(enemies,key=lambda e:e['x']);desired=float(d['speed'])*1.04*0.68
   if 0<target['x']-float(d['playerX'])<desired+15:page.keyboard.press('Space')
  page.wait_for_timeout(15)
 check(stomped,'Space can stomp a real gnome and bounce upward')
 page.screenshot(path=str(out/'actual-stomp.png'))
 # Run a playable dodge/attack policy until a low branch is passed while small.
 # Skip mushrooms with a normal jump so giant smashing cannot fake this check.
 def bot_step(skip_mushrooms=False):
  d=data();player=float(d['playerX']);speed=float(d['speed'])
  if d['state']!='running':return d
  obstacles=[o for o in json.loads(d['obstacles']) if o['x']>player-80]
  nearest=min(obstacles,key=lambda o:o['x'],default=None)
  arch=nearest and nearest['kind']=='arch' and -65<nearest['x']-player<speed*0.85+70 and d['giant']=='false'
  if arch:
   page.keyboard.down('s');page.keyboard.down('j')
  else:
   page.keyboard.up('s');page.keyboard.down('j')
  if d['airborne']=='false':
   floor=nearest and nearest['kind']!='arch' and 0<nearest['x']-player<speed*0.42+10 and d['giant']=='false'
   mushroom=skip_mushrooms and not arch and any(i['kind']=='mushroom' and 0<i['x']-player<speed*0.36+35 for i in json.loads(d['items']))
   if floor or mushroom:page.keyboard.press('Space')
  return d
 passed=False;weather_seen=False
 for attempt in range(5):
  open_game('aion');started=time.monotonic();branch_x=None
  while time.monotonic()-started<45:
   d=bot_step(True)
   if d['state']!='running':
    print('Branch observation retry',attempt,d['state'],d['obstacles'],d['enemies'],flush=True);page.screenshot(path=str(out/('branch-attempt-'+str(attempt)+'.png')));break
   weather_seen=weather_seen or d['weather']!='clear'
   player=float(d['playerX'])
   arches=[o for o in json.loads(d['obstacles']) if o['kind']=='arch' and abs(o['x']-player)<25]
   if arches and d['ducking']=='true' and d['giant']=='false':
    page.screenshot(path=str(out/'duck-under-branch.png'));branch_x=arches[0]['x']
    page.keyboard.down('s');page.wait_for_timeout(450)
    if data()['state']=='running':passed=True;break
   page.wait_for_timeout(20)
  if passed:break
 check(passed,'Holding Down/S really clears a low branch while normal-sized')
 if not weather_seen:
  started=time.monotonic()
  while time.monotonic()-started<18 and data()['state']=='running':
   d=bot_step(True)
   if d['weather']!='clear':weather_seen=True;page.screenshot(path=str(out/'natural-weather.png'));break
   page.wait_for_timeout(20)
 check(weather_seen or data()['weather']!='clear','A natural weather change appears during the run')
 page.keyboard.up('s');page.keyboard.up('j')
 # Recruit actual followers and observe a full staggered jump from settled feet.
 found=False
 for attempt in range(3):
  open_game('sheep');started=time.monotonic()
  while time.monotonic()-started<55:
   d=bot_step(False)
   if d['state']!='running':break
   player=float(d['playerX']);obstacles=[o for o in json.loads(d['obstacles']) if o['x']>player-10]
   safe=not obstacles or min(o['x']-player for o in obstacles)>float(d['speed'])*1.2+100
   threats=[e for e in json.loads(d['enemies']) if e['hp']>0 and e['x']>player-65]
   safe=safe and (not threats or min(e['x']-player for e in threats)>float(d['speed'])*1.4+100)
   if d['flock']=='3' and d['airborne']=='false' and abs(float(d['follower-1Y']))<0.01 and abs(float(d['follower-2Y']))<0.01 and safe:
    found=True;break
   page.wait_for_timeout(20)
  if found:break
 check(found,'Ground pickups recruit three real visible sheep in adventure mode')
 check(all(0<h<=64.9 for h in json.loads(d['followersOpaqueHeight'])),'Both real follower sheep stay smaller than the normal-sized leader')
 page.keyboard.up('s');page.keyboard.down('j')
 page.evaluate('''() => {window.flockTimeline=[];window.flockObserver=new MutationObserver(()=>{let c=document.querySelector('canvas');window.flockTimeline.push({t:performance.now(),y:Number(c.dataset.playerY),second:Number(c.getAttribute('data-follower-1-y')),third:Number(c.getAttribute('data-follower-2-y')),count:Number(c.dataset.flock)});});window.flockObserver.observe(document.querySelector('canvas'),{attributes:true,attributeFilter:['data-player-y','data-follower-1-y','data-follower-2-y']});}''')
 page.keyboard.press('Space');page.wait_for_function('() => Number(document.querySelector("canvas").getAttribute("data-follower-2-y")) < -3')
 timeline=page.evaluate('window.flockObserver.disconnect(); window.flockTimeline');(out/'flock-timeline.json').write_text(json.dumps(timeline,indent=2))
 check(any(s['y']<-3 and s['second']>-1 and s['third']>-1 and s['count']==3 for s in timeline),'Leader takes off while both followers are still grounded')
 check(any(s['second']<-3 and s['third']>-1 and s['count']==3 for s in timeline),'Second sheep takes off in a separate delayed stage')
 check(any(s['third']<-3 and s['count']==3 for s in timeline),'Third sheep takes off last, following the same path')
 page.screenshot(path=str(out/'three-stage-flock-jump.png'))
 context.close()
 # Real two-finger input with portrait-to-landscape projection, without a fake
 # fullscreen/orientation shim or game-state setters.
 context=browser.new_context(viewport={'width':390,'height':844},has_touch=True,is_mobile=True,locale='tr-TR')
 page=context.new_page();page.on('pageerror',lambda error:errors.append(str(error)));page.on('console',lambda msg:errors.append(msg.text) if 'SCRIPT ERROR' in msg.text else None);page.goto(args.url);page.wait_for_selector('canvas[data-state="ready"]',timeout=60000);wait_ui()
 check(data()['orientation']=='landscape' and float(data()['viewWidth'])>float(data()['viewHeight']),'A portrait phone always renders the game as a landscape playfield')
 click_button('Koşuya başla',touch=True);page.wait_for_selector('canvas[data-state="running"]');wait_ui();page.wait_for_timeout(250)
 buttons=json.loads(data()['controls'])
 def center(button):return screen_point(button['x']+button['w']/2,button['y']+button['h']/2)
 jump=dict(center(buttons['jump']),id=1);attack=dict(center(buttons['attack']),id=2)
 cdp=context.new_cdp_session(page);cdp.send('Input.dispatchTouchEvent',{'type':'touchStart','touchPoints':[jump]});page.wait_for_selector('canvas[data-airborne="true"]')
 check(data()['jumps']=='1','One touch on Jump produces one jump, without an emulated-mouse duplicate')
 cdp.send('Input.dispatchTouchEvent',{'type':'touchStart','touchPoints':[jump,attack]});page.wait_for_selector('canvas[data-attacking="true"][data-airborne="true"]')
 check(True,'Two fingers can jump and attack simultaneously on a rotated phone')
 page.screenshot(path=str(out/'portrait-two-finger-combat.png'))
 cdp.send('Input.dispatchTouchEvent',{'type':'touchEnd','touchPoints':[]});page.wait_for_selector('canvas[data-airborne="false"]')
 duck=dict(center(json.loads(data()['controls'])['duck']),id=3);cdp.send('Input.dispatchTouchEvent',{'type':'touchStart','touchPoints':[duck]});page.wait_for_selector('canvas[data-ducking="true"]');page.screenshot(path=str(out/'portrait-touch-duck.png'))
 cdp.send('Input.dispatchTouchEvent',{'type':'touchEnd','touchPoints':[]});page.wait_for_selector('canvas[data-ducking="false"]')
 check(True,'Touch duck holds and releases correctly in the rotated layout')
 page.evaluate('document.fullscreenElement ? document.exitFullscreen() : Promise.resolve()');page.set_viewport_size({'width':844,'height':390});wait_ui();page.wait_for_timeout(300)
 check(float(data()['viewWidth'])>float(data()['viewHeight']),'Rotating the phone keeps the landscape layout and active run')
 page.screenshot(path=str(out/'phone-landscape.png'))
 check(not errors,'No uncaught browser errors across combat, UI and phone flows')
 browser.close()
(out/'adventure-results.json').write_text(json.dumps(results,indent=2,ensure_ascii=False)+'\n')
print(len(results),'adventure browser checks passed')
