"""Unseeded live endless runs driven only by a standard Gamepad API device.
No RNG replacement, level shortcut, forced item or enemy spawn, or writable game hook.
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
 b=pw.chromium.launch(args=['--no-sandbox','--enable-unsafe-swiftshader']);c=b.new_context(viewport={'width':1152,'height':648},locale='en-GB',service_workers='block')
 c.add_init_script('''const pad={id:'Xbox Standard Controller',index:0,connected:true,mapping:'standard',timestamp:0,axes:[0,0,0,0],buttons:Array.from({length:17},()=>({pressed:false,touched:false,value:0}))};Object.defineProperty(navigator,'getGamepads',{value:()=>[pad]});window.padSet=(i,v)=>{pad.buttons[i]={pressed:v,touched:v,value:v?1:0};pad.timestamp=performance.now()};''')
 page=c.new_page();page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda m:errors.append(m.text) if 'SCRIPT ERROR' in m.text else None)
 page.goto(a.url);page.wait_for_selector('canvas[data-ui-ready="true"]',timeout=120000)
 def d():return page.locator('canvas').evaluate('c=>({...c.dataset})')
 def semantic(label):page.locator('#aion-accessibility-controls').get_by_role('button',name=label,exact=True).press('Enter')
 def pick_wolf():
  point=page.locator('canvas').evaluate('''c=>{const d=c.dataset,b=JSON.parse(d.ui).find(b=>b.name==='StartSelect_wolf'),t=JSON.parse(d.screenTransform),r=c.getBoundingClientRect(),x=b.x+b.w/2,y=b.y+b.h/2;return [r.x+(t[0]*x+t[2]*y+t[4])/Number(d.rawWidth)*r.width,r.y+(t[1]*x+t[3]*y+t[5])/Number(d.rawHeight)*r.height]}''');page.mouse.click(*point)
 pick_wolf()
 seen=set();biomes=set();buffs=set();best_xp=0;bolt_seen=False;captures=set()
 for attempt in range(3):
  semantic('Start running' if attempt==0 else 'Run again');page.wait_for_selector('canvas[data-state="running"]');started=time.monotonic()
  page.evaluate('''()=>{
   window.routePilot=true;window.boltEdges=0;let attackEnd=0,attackNext=0,shotEnd=0,shotNext=0;
   function tick(){
    if(!routePilot){[0,1,2,4,5].forEach(i=>padSet(i,false));return;}
    const d=document.querySelector('canvas').dataset,run=d.state==='running'&&d.page==='';
    const x=Number(d.playerX),speed=Number(d.speed),now=Number(d.worldTime),air=d.airborne==='true';
    const obs=JSON.parse(d.obstacles||'[]').filter(o=>o.x>x-180),en=JSON.parse(d.enemies||'[]').filter(e=>e.hp>0&&e.x>x-60),plants=JSON.parse(d.plants||'[]');
    const carrier=obs.some(o=>o.kind.startsWith('carrier')&&o.x-x<speed*.64+100&&o.x-x>-100);
    const highBird=en.some(e=>['crow','bat','wisp'].includes(e.kind)&&e.x-x<speed*.45+60&&e.x-x>-45);
    const ground=obs.some(o=>!o.kind.startsWith('carrier')&&o.kind!=='gate'&&!o.kind.startsWith('arch')&&o.x>x&&o.x-x<speed*.32+(o.kind.startsWith('pit')?Number(o.width||150)*.5:25));
    const flames=JSON.parse(d.projectiles||'[]').some(p=>p.owner==='plant'&&p.x>x&&p.x-x<Math.abs(p.vx)*.37);
    const plant=plants.some(p=>p.hp>0&&p.x>x&&p.x-x<speed*.4+25);
    let roll=carrier||highBird;
    if(ground||flames||plant)roll=false;
    padSet(1,run&&roll&&!air);padSet(0,run&&!air&&!roll&&(ground||flames||plant));
    padSet(4,run);
    const near=en.some(e=>e.x>x&&e.x-x<speed*.19+110&&Math.abs(e.y-(Number(d.playerY||0)-48))<100);
    if(run&&!roll&&near&&now>=attackNext){attackEnd=now+.035;attackNext=now+.5;}
    padSet(2,run&&now<attackEnd);
    if(run&&Number(d.lightningCharges)>0&&now>=shotNext&&en.some(e=>e.x>x+40&&e.x-x<1450)){
     shotEnd=now+.05;shotNext=now+.8;boltEdges++;
    }
    padSet(5,run&&now<shotEnd);requestAnimationFrame(tick);
   }requestAnimationFrame(tick);
  }''')
  while time.monotonic()-started<165:
   v=d();history.append({k:v.get(k) for k in ['worldTime','worldDistance','state','biome','kills','xp','lightningCharges','powers','enemies','items']})
   for e in json.loads(v.get('enemies','[]')):seen.add(e['kind'])
   for k,duration in json.loads(v.get('powers','{}')).items():
    if duration>0:buffs.add(k)
   biomes.add(int(v['biome']));best_xp=max(best_xp,int(v['xp']))
   if page.evaluate('window.boltEdges||0') and int(v['lightningCharges'])<2:bolt_seen=True
   for tag in ['biome-'+v['biome']]+[e['kind'] for e in json.loads(v.get('enemies','[]')) if e['kind'] in ['bat','slime','beetle','wisp']]:
    if tag not in captures and (not tag.startswith('biome-') or int(v['biome'])>=4):
     page.screenshot(path=str(a.evidence/(tag+'.png')));captures.add(tag)
   if v['state']!='running':print('Route ended',attempt,v['worldTime'],v['deathCause'],flush=True);break
   if bolt_seen and best_xp>0 and {4,5}<=biomes and len(seen)>=5 and {'spring','fortune','frost'}<=buffs:break
   page.wait_for_timeout(150)
   if len(history)%40==0:print('Route',attempt,v['worldTime'],v['biome'],'XP',v['xp'],'buffs',sorted(buffs),'enemies',sorted(seen),flush=True)
  page.evaluate('window.routePilot=false');page.wait_for_timeout(100)
  if bolt_seen and best_xp>0 and {4,5}<=biomes and len(seen)>=5 and {'spring','fortune','frost'}<=buffs:break
  if d()['state']=='running':
   # Continue the same real run until collision rather than inject a finished state.
   page.wait_for_selector('canvas[data-page="finished"]',timeout=60000)
  else:page.wait_for_selector('canvas[data-page="finished"]',timeout=10000)
 check(best_xp>0,'Real gamepad attacks earn visible run XP on spawned enemies')
 check(bolt_seen,'A collected lightning charge is fired with a normal RB edge')
 check({4,5}<=biomes,'Normal travel reaches both forest and volcanic biomes')
 check(len(seen)>=5,'At least five ordinary enemy types appear in unseeded real encounters')
 check({'spring','fortune','frost'}<=buffs,'All three new buffs are collected through normal play')
 check(not errors,'No JavaScript or Godot script errors during varied normal play')
 b.close()
(a.evidence/'result.json').write_text(json.dumps({'checks':checks,'enemy_types':sorted(seen),'biomes':sorted(biomes),'buffs':sorted(buffs),'bolt_seen':bolt_seen,'max_xp':best_xp,'history':history},indent=2))
print('RESULT:',len(checks),'normal-input trails checks')
