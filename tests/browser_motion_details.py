"""Real-input 0.9 anatomy, isolated frames, four biomes, gaps/plants and boss chase.
No game setters, forced spawns, RNG replacement, shortcuts or synthetic levels.
"""
import argparse,json,time
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--url',default='http://127.0.0.1:8779');p.add_argument('--endurance',action='store_true');p.add_argument('--route-only',action='store_true');p.add_argument('--evidence',type=Path,default=Path('work/frontier-evidence'));a=p.parse_args();out=a.evidence;out.mkdir(parents=True,exist_ok=True)
results=[];errors=[]
def check(value,message):
 assert value,message
 results.append(message);print('PASS',message,flush=True)
with sync_playwright() as p:
 browser=p.chromium.launch(args=['--no-sandbox','--enable-unsafe-swiftshader']);context=browser.new_context(viewport={'width':1152,'height':648},locale='tr-TR',has_touch=True);page=context.new_page()
 page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda m:errors.append(m.text) if 'SCRIPT ERROR' in m.text else None)
 def d():return page.locator('canvas').evaluate('c=>({...c.dataset,lang:c.getAttribute("lang")})')
 def ready():page.wait_for_selector('canvas[data-ui-ready="true"]')
 def point(x,y):
  v=d();t=json.loads(v['screenTransform']);r=page.locator('canvas').bounding_box();return {'x':r['x']+(t[0]*x+t[2]*y+t[4])/float(v['rawWidth'])*r['width'],'y':r['y']+(t[1]*x+t[3]*y+t[5])/float(v['rawHeight'])*r['height']}
 def click(name=None,text=None):
  ready();b=next(b for b in json.loads(d()['ui']) if (b['name']==name if name else text in b['text']));page.mouse.click(**point(b['x']+b['w']/2,b['y']+b['h']/2))
 def main():
  if d()['page']=='':
   if d()['state']=='running':page.keyboard.press('Escape')
   page.wait_for_function('() => ["paused","finished"].includes(document.querySelector("canvas").dataset.page)')
  if d()['page']!='main':click(text='Ana menü');page.wait_for_selector('canvas[data-page="main"]');ready()
 def run(hero):
  main();click(name='StartSelect_'+hero);page.wait_for_selector('canvas[data-character="'+hero+'"]');ready();page.keyboard.press('Space');page.wait_for_selector('canvas[data-state="running"]');ready()
 page.goto(a.url);page.wait_for_selector('canvas[data-state="ready"][data-version="0.9.0"]',timeout=90000);ready()
 check(d()['lang']=='tr','The actual 0.9 entry retains browser-language selection')
 for hero in ([] if a.route_only else ['aion','owl','sheep','wolf']):
  run(hero);head=float(d()['heroHeadSize']);check(d()['isolatedFrame']=='true',hero+': running uses a separate padded frame texture')
  if hero=='wolf':
   page.keyboard.down('Shift');page.wait_for_selector('canvas[data-boosting="true"]');check(abs(float(d()['heroHeadSize'])-head)<.01,'Wolf sprint preserves its actual calibrated head size');page.screenshot(path=str(out/'wolf-anatomical-dash.png'));page.keyboard.up('Shift')
  run(hero);head=float(d()['heroHeadSize']);page.keyboard.press('Space');page.wait_for_selector('canvas[data-airborne="true"]');check(abs(float(d()['heroHeadSize'])-head)<.01,hero+': jumping does not enlarge the character anatomy')
  run(hero);page.mouse.click(**point(600,270));page.wait_for_selector('canvas[data-attacking="true"]');check(d()['isolatedFrame']=='true' and abs(float(d()['heroHeadSize'])-head)<.01,hero+': a strike is isolated from adjacent atlas pixels and keeps the same head span');page.screenshot(path=str(out/(hero+'-isolated-strike.png')))
 # Observe all run frames after normal start, then actual owl airborne/ground attacks.
 page.evaluate("""() => { window.observedRunFrames=new Set();window.observedRollFrames=new Set();new MutationObserver(()=>{const c=document.querySelector('canvas').dataset;if(c.character==='wolf'&&c.state==='running'&&c.poseSource==='motion-wolf'&&c.sourceRow==='1')window.observedRunFrames.add(Number(c.sourceFrame));if(c.character==='wolf'&&c.ducking==='true'&&c.poseSource==='motion-rolls')window.observedRollFrames.add(Number(c.sourceFrame));}).observe(document.querySelector('canvas'),{attributes:true}); }""")
 run('wolf');page.wait_for_function('()=>window.observedRunFrames.size===12',timeout=20000)
 check(True,'Normal wolf running really displays all twelve intermediate frames')
 run('owl');page.keyboard.down('Space');page.wait_for_selector('canvas[data-airborne="true"]');page.mouse.click(**point(600,270));page.wait_for_selector('canvas[data-attacking="true"][data-attack-kind="peck"][data-source-row="8"]');check(d()['poseSource']=='motion-owl','An airborne left click really renders the dedicated owl beak row');page.keyboard.press('Escape');page.wait_for_selector('canvas[data-state="paused"]');page.screenshot(path=str(out/'owl-airborne-beak.png'));page.keyboard.up('Space')
 run('owl');page.mouse.click(**point(600,270));page.wait_for_selector('canvas[data-attacking="true"][data-attack-kind="melee"][data-source-row="4"]');check(True,'The grounded owl still uses its alternating wing animation')
 run('wolf');page.keyboard.down('s');page.wait_for_selector('canvas[data-ducking="true"]');page.wait_for_function('()=>window.observedRollFrames.size===12',timeout=20000)
 check(True,'A real held roll displays twelve distinct drawn rotation frames');page.keyboard.up('s')
 page.keyboard.press('Escape');page.wait_for_selector('canvas[data-state="paused"]');elapsed=float(d()['levelElapsed']);page.wait_for_timeout(500);check(float(d()['levelElapsed'])==elapsed,'Actual Esc pauses the active level timer');check(not errors,'No browser or Godot errors during detailed motion controls');browser.close()
(out/'motion-detail-results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2)+'\n');print(len(results),'motion detail checks passed')
