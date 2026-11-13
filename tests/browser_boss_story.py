"""Natural level5 route -> dialogue -> upgrade -> victory; real inputs only.
Passive diagnostics guide the player. No forced state, saves, RNG, health or levels.
"""
import argparse,json,time
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--url',default='http://127.0.0.1:8781');p.add_argument('--evidence',type=Path,required=True);a=p.parse_args();a.evidence.mkdir(parents=True,exist_ok=True);checks=[];timeline=[];errors=[]
def check(ok,message):
 assert ok,message
 checks.append(message);print('PASS',message,flush=True)
with sync_playwright() as pw:
 b=pw.chromium.launch(args=['--no-sandbox','--enable-unsafe-swiftshader']);c=b.new_context(viewport={'width':1280,'height':720},locale='tr-TR',has_touch=True,service_workers='block',record_video_dir=str(a.evidence/'video'))
 c.add_init_script("const pad={id:'Xbox Controller',index:0,connected:true,mapping:'standard',timestamp:0,axes:[0,0,0,0],buttons:Array.from({length:17},()=>({pressed:false,touched:false,value:0}))};Object.defineProperty(navigator,'getGamepads',{value:()=>[pad]});window.padSet=(i,v)=>{pad.buttons[i]={pressed:v,touched:v,value:v?1:0};pad.timestamp=performance.now()};")
 page=c.new_page();page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda m:errors.append(m.text) if 'SCRIPT ERROR' in m.text else None)
 def d():return page.locator('canvas').evaluate('c=>({...c.dataset})')
 def wait(sel):page.wait_for_selector('canvas'+sel,timeout=120000)
 def ui(name):
  v=d();u=next(x for x in json.loads(v['ui']) if x['name']==name or x['text']==name);t=json.loads(v['screenTransform']);r=page.locator('canvas').bounding_box();x=u['x']+u['w']/2;y=u['y']+u['h']/2
  page.touchscreen.tap(r['x']+(t[0]*x+t[2]*y+t[4])/float(v['rawWidth'])*r['width'],r['y']+(t[1]*x+t[3]*y+t[5])/float(v['rawHeight'])*r['height'])
 page.goto(a.url);wait('[data-state="ready"][data-ui-ready="true"]')
 try:
  reached=False
  for attempt in range(4):
   if d()['page']!='main':
    page.keyboard.up('f');page.keyboard.up('s')
    if d()['page']=='':
     if d()['state']=='running':page.keyboard.press('Escape')
     page.wait_for_function("['paused','finished'].includes(document.querySelector('canvas').dataset.page)")
    ui('Ana menü');wait('[data-page="main"]')
   ui('StartSelect_aion');ui('StartRun');wait('[data-state="running"]')
   if any(u['text']=='Anladım · Devam et' for u in json.loads(d()['ui'])):ui('Anladım · Devam et')
   page.evaluate("""() => {
    let jumpUntil=0, lastJump=-1000;
    window.routeAI=true;
    const loop=()=>{
     if(!routeAI)return;
     const d=document.querySelector('canvas').dataset;
     if(d.state!=='running'||d.bossPhase!=='run'){
      for(let i of [0,1,5])padSet(i,false);window.routeAI=false;return;
     }
     const player=+d.playerX,speed=+d.speed,now=performance.now();
     const obs=JSON.parse(d.obstacles).filter(o=>o.x>player-(o.kind.startsWith('carrier')?120:(o.width||160)/2+45)).sort((a,b)=>a.x-b.x),n=obs[0];
     const enemies=JSON.parse(d.enemies).filter(e=>e.hp>0&&e.x>player-60);
     const crow=enemies.some(e=>e.kind==='crow'&&e.y>-115&&e.y< -45&&e.x-player> -65&&e.x-player<speed*.65+100);
     const carrier=obs.some(o=>o.kind.startsWith('carrier')&&o.x-player> -120&&o.x-player<speed*.70+90);
     const roll=!!(crow||carrier)&&d.giant!=='true';
     const floor=n&&!/^(carrier|gate|arch)/.test(n.kind)&&n.x-player>0&&n.x-player<speed*.40+(n.kind.startsWith('pit')?(n.width||150)*.25:25);
     const bolt=JSON.parse(d.projectiles).some(p=>p.owner==='plant'&&(p.x-player)/Math.abs(p.vx)>0&&(p.x-player)/Math.abs(p.vx)<.45);
     const plant=JSON.parse(d.plants).some(p=>p.x-player>0&&p.x-player<speed*.48+20);
     if(!roll&&d.airborne==='false'&&(floor||bolt||plant)&&now-lastJump>220){jumpUntil=now+80;lastJump=now;}
     padSet(1,roll);padSet(5,true);padSet(0,now<jumpUntil);
     requestAnimationFrame(loop);
    };requestAnimationFrame(loop);
   }""")
   started=time.monotonic()
   while time.monotonic()-started<220:
    v=d()
    if v['bossPhase']=='story':reached=True;break
    if v['state']!='running':print('Natural route retry',attempt,v['state'],v['level'],flush=True);break
    page.wait_for_timeout(100)
   page.evaluate('window.routeAI=false;for(let i of [0,1,5])padSet(i,false)')
   if reached:break
  check(reached,'A normal unmodified run naturally reaches its first boss at level5')
  v=d();check(v['level']=='5' and v['bossKind']=='0','Level5 selects the first boss without waiting for level10');page.screenshot(path=str(a.evidence/'natural-boss-taunt.png'))
  frozen={k:v[k] for k in ['worldTime','worldDistance','travelDistance','levelElapsed','score']};page.keyboard.down('f');page.wait_for_timeout(450);page.keyboard.up('f');after=d();check(all(after[k]==val for k,val in frozen.items()) and after['bossShots']==v['bossShots'],'Dialogue freezes real gameplay and refuses held Fire')
  ui('StoryNext');wait('[data-story-index="1"]');page.wait_for_timeout(800);check(d()['poseSource']=='boss-story-reactions','Continue selects the actual surprised hands-to-face sheet');page.screenshot(path=str(a.evidence/'natural-hero-surprise.png'))
  page.keyboard.press('Escape');wait('[data-page="paused"]');paused=d();page.set_viewport_size({'width':393,'height':873});wait('[data-orientation="portrait"][data-ui-ready="true"]');page.keyboard.press('Escape');wait('[data-page=""]');check(d()['storyIndex']=='1' and d()['level']==paused['level'] and d()['score']==paused['score'],'Pause and portrait rotation preserve the same cinematic and run')
  page.evaluate('padSet(0,true)');page.wait_for_timeout(100);page.evaluate('padSet(0,false)');wait('[data-story-index="2"]');check(True,'Gamepad A activates the real cinematic Continue action');page.screenshot(path=str(a.evidence/'natural-red-pistol-handoff-portrait.png'))
  ui('StorySkip');wait('[data-boss-phase="intro"][data-red-weapon="true"]');check(d()['jumpHeld']=='false','Touch Skip grants the upgrade and carries no jump input into the chase')
  page.keyboard.press('Escape');wait('[data-page="paused"]');page.set_viewport_size({'width':1280,'height':720});wait('[data-orientation="landscape"][data-ui-ready="true"]');page.keyboard.press('Escape');wait('[data-boss-phase="fight"]');page.keyboard.down('f');start_hp=int(d()['bossHp']);start_level=d()['level'];started=time.monotonic();roll=False
  while time.monotonic()-started<75:
   v=d();timeline.append({k:v[k] for k in ['bossPhase','bossHp','bossShots','bossHits','bossPlayerHp','level','redWeapon','worldDistance','travelDistance']})
   if v['state']!='running':break
   if int(v['bossWins'])>0 and v['bossPhase']=='run':break
   player=float(v['playerX']);ps=[p for p in json.loads(v['projectiles']) if p['owner']=='boss' and p['x']>player-60];high=any(p['kind']=='bolt' and -60<p['x']-player<350 for p in ps)
   if high!=roll:(page.keyboard.down if high else page.keyboard.up)('s');roll=high
   low=any(p['kind'] in ['ember','seed'] and 0<(p['x']-player)/abs(p['vx'])<.45 for p in ps)
   if low and v['airborne']=='false':page.keyboard.up('s');roll=False;page.keyboard.press('Space')
   page.wait_for_timeout(25)
  page.keyboard.up('f');page.keyboard.up('s');v=d();check(any(int(x['bossHp'])<start_hp and int(x['bossHits'])>0 for x in timeline),'Real red-pistol projectiles collide with the moving boss and lower HP');check(v['bossWins']=='1' and v['bossPhase']=='run','Real inputs defeat the boss and complete the smooth return');check(v['redWeapon']=='true' and v['level']==start_level,'The upgraded gun survives the return; the boss does not farm normal levels');page.keyboard.press('Escape');page.screenshot(path=str(a.evidence/'natural-victory-return.png'));check(not errors,'No script or browser errors on the natural story and boss route')
 finally:
  (a.evidence/'results.json').write_text(json.dumps({'checks':checks,'errors':errors,'timeline':timeline,'build':page.evaluate('AION_BUILD'),'scope':'Normal UI and real keyboard/touch/browser-gamepad input. Passive observations only. No state/RNG/save/health setters. Not a physical controller or phone.'},ensure_ascii=False,indent=2)+'\n');c.close();b.close()
print('RESULT:',len(checks),'natural story checks')
