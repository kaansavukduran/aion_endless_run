"""Normal, unseeded Emre/fruit gameplay via UI and standard gamepad inputs.
Only passive canvas diagnostics; no writable world, RNG or spawn hooks.
"""
import argparse,json,time
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--url',default='http://127.0.0.1:8781');p.add_argument('--evidence',type=Path,required=True);a=p.parse_args();a.evidence.mkdir(parents=True,exist_ok=True)
checks=[];errors=[];history=[]
def check(ok,label):
 assert ok,label
 checks.append(label);print('PASS',label,flush=True)
with sync_playwright() as pw:
 b=pw.chromium.launch(args=['--no-sandbox','--enable-unsafe-swiftshader']);c=b.new_context(viewport={'width':1100,'height':620},locale='en-GB',has_touch=True,service_workers='block',record_video_dir=str(a.evidence/'video'))
 c.add_init_script("""const pad={id:'Xbox Standard Controller',index:0,connected:true,mapping:'standard',timestamp:0,axes:[0,0,0,0],buttons:Array.from({length:17},()=>({pressed:false,touched:false,value:0}))};Object.defineProperty(navigator,'getGamepads',{value:()=>[pad]});window.padSet=(i,v)=>{pad.buttons[i]={pressed:v,touched:v,value:v?1:0};pad.timestamp=performance.now()};""")
 page=c.new_page();page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda m:errors.append(m.text) if 'SCRIPT ERROR' in m.text else None);page.goto(a.url);page.wait_for_selector('canvas[data-ui-ready="true"]',timeout=120000)
 def d():return page.locator('canvas').evaluate('c=>({...c.dataset})')
 def click(name=None,text=None):
  page.wait_for_selector('canvas[data-ui-ready="true"]');v=d();button=next(x for x in json.loads(v['ui']) if (x['name']==name if name else x['text']==text));t=json.loads(v['screenTransform']);r=page.locator('canvas').bounding_box();x=button['x']+button['w']/2;y=button['y']+button['h']/2;page.mouse.click(r['x']+(t[0]*x+t[2]*y+t[4])/float(v['rawWidth'])*r['width'],r['y']+(t[1]*x+t[3]*y+t[5])/float(v['rawHeight'])*r['height'])
 cards=[x for x in json.loads(d()['ui']) if x['name'].startswith('StartSelect_')]
 check(len(cards)==5 and all(x['x']>=0 and x['y']>=0 and x['x']+x['w']<=float(d()['viewWidth'])+1 and x['y']+x['h']<=float(d()['viewHeight'])+1 for x in cards),'All five hero cards fit the real opening screen')
 click(name='StartSelect_rabbit');check(d()['character']=='rabbit' and d()['characterName']=='Emre the Rabbit','Emre is selected from his actual named menu card')
 seen=set();best_count=0;safe=True
 for attempt in range(3):
  click(text='Start running' if attempt==0 else 'Run again');page.wait_for_selector('canvas[data-state="running"]');start=time.monotonic()
  if attempt==0:click(text='Got it · Continue')
  # Input pilot reads visible-world telemetry and presses ordinary Xbox buttons.
  page.evaluate("""()=>{window.harvest=true;let until=0,next=0;function step(){
   const d=document.querySelector('canvas').dataset,run=harvest&&d.state==='running'&&d.page==='';
   const x=Number(d.playerX),speed=Number(d.speed),now=Number(d.worldTime),air=d.airborne==='true';
   const obs=JSON.parse(d.obstacles||'[]'),en=JSON.parse(d.enemies||'[]').filter(e=>e.hp>0),plants=JSON.parse(d.plants||'[]');
   const carrier=obs.some(o=>o.kind.startsWith('carrier')&&o.x-x<speed*.62+100&&o.x-x>-100);
   const bird=en.some(e=>['crow','bat','wisp'].includes(e.kind)&&e.x-x<speed*.42+60&&e.x-x>-45);
   const ground=obs.some(o=>!o.kind.startsWith('carrier')&&o.kind!=='gate'&&!o.kind.startsWith('arch')&&o.x>x&&o.x-x<speed*.33+(o.kind.startsWith('pit')?Number(o.width||150)*.5:25));
   const flame=JSON.parse(d.projectiles||'[]').some(p=>p.owner==='plant'&&p.x>x&&p.x-x<Math.abs(p.vx)*.4);
   const plant=plants.some(p=>p.hp>0&&p.x>x&&p.x-x<speed*.4+25);
   let roll=(carrier||bird)&&!ground&&!flame&&!plant;
   padSet(1,run&&roll&&!air);padSet(0,run&&!air&&!roll&&(ground||flame||plant));
   if(run&&!roll&&now>=next&&en.some(e=>e.x>x&&e.x-x<speed*.17+105&&Math.abs(e.y-(Number(d.playerY)-48))<100)){until=now+.035;next=now+.5;}
   padSet(2,run&&now<until);if(harvest)requestAnimationFrame(step);else [0,1,2].forEach(i=>padSet(i,false));
  }requestAnimationFrame(step)}""")
  while time.monotonic()-start<70:
   v=d();fruits=json.loads(v.get('fruits','[]'));obs=json.loads(v.get('obstacles','[]'));best_count=max(best_count,int(v.get('fruitCount',0)))
   for f in fruits:
    seen.add(f['kind']);safe=safe and -41<=f['y']<=-31
    for o in obs:
     if o['kind'].startswith('carrier') or o['kind']=='gate' or o['kind'].startswith('arch'):continue
     margin=float(o.get('width',150))*.5+60 if o['kind'].startswith('pit') else 90
     safe=safe and abs(f['x']-o['x'])>=margin
   history.append({'time':v['worldTime'],'state':v['state'],'fruit_count':v.get('fruitCount'),'fruits':fruits})
   if len(fruits)>=3 and not (a.evidence/'normal-fruit-ribbon.png').exists():page.screenshot(path=str(a.evidence/'normal-fruit-ribbon.png'))
   if best_count>=8 and len(seen)==8:break
   if v['state']!='running':break
   if len(history)%100==0:print('Harvest',attempt,v['worldTime'],'count',best_count,'types',len(seen),flush=True)
   page.wait_for_timeout(100)
  page.evaluate('window.harvest=false');page.wait_for_timeout(60)
  if best_count>=8 and len(seen)==8:break
  page.wait_for_selector('canvas[data-page="finished"]',timeout=60000)
 check(best_count>=8,'Emre collects at least eight actual fruit pickups through normal unseeded play')
 check(len(seen)==8,'All eight common fruit silhouettes appear in the actual running world')
 check(safe,'Observed fruit ribbons remain on reachable ground and clear ordinary hazards and pits')
 if d()['state']=='running':page.keyboard.press('Escape');page.wait_for_selector('canvas[data-state="paused"]')
 else:page.wait_for_selector('canvas[data-page="finished"]')
 click(text='Main menu');click(text='Boss training');click(name='PracticeBoss_0');page.wait_for_selector('canvas[data-boss-phase="fight"]');hp=int(d()['bossHp']);page.evaluate('padSet(5,true)');page.wait_for_function('(hp)=>Number(document.querySelector("canvas").dataset.bossHp)<hp',arg=hp);page.evaluate('padSet(5,false)')
 check(d()['poseSource']=='emre-encounters' and int(d()['bossShots'])>0,'Emre uses his own pistol poses and RB projectiles actually damage the boss')
 page.screenshot(path=str(a.evidence/'emre-boss.png'));page.keyboard.press('Escape');page.wait_for_selector('canvas[data-state="paused"]');before=d();page.set_viewport_size({'width':393,'height':873});page.wait_for_selector('canvas[data-orientation="portrait"][data-ui-ready="true"]');after=d()
 check(after['character']=='rabbit' and after['score']==before['score'] and after['bossHp']==before['bossHp'],'Portrait rotation preserves Emre and the live boss run')
 page.screenshot(path=str(a.evidence/'emre-portrait-paused.png'));check(not errors,'No browser or Godot script errors during real Emre, fruit, controller and rotation flows')
 c.close();b.close()
(a.evidence/'result.json').write_text(json.dumps({'checks':checks,'fruit_types':sorted(seen),'max_fruit_count':best_count,'safe_placement':safe,'errors':errors,'history':history},ensure_ascii=False,indent=2)+'\n');print('RESULT:',len(checks),'normal-input orchard checks')
