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
 page.evaluate("""() => {window.gunPoses={};new MutationObserver(()=>{const c=document.querySelector('canvas').dataset;if(c.poseSource==='canonical-'+c.character&&c.state==='running'&&Number(c.sourceRow)===8){(window.gunPoses[c.character]??=new Set()).add(Number(c.sourceFrame));}}).observe(document.querySelector('canvas'),{attributes:true});}""")
 for i,hero in enumerate(['aion','owl','sheep','wolf']):
  click(name='StartSelect_'+hero);wait('[data-character="'+hero+'"]');click(text='Boss antrenmanı');wait('[data-page="bosses"]');click(name='PracticeBoss_0');wait('[data-boss-phase="fight"]')
  page.evaluate('padButton(7,1)');wait('[data-pose-source="canonical-'+hero+'"][data-source-row="8"]');check(True,hero+': actual firing uses the dedicated coherent weapon row')
  page.wait_for_function("id=>window.gunPoses[id]?.size===(['aion','sheep'].includes(id)?7:8)",arg=hero,timeout=20000);check(True,hero+': actual trigger fire plays all separate anticipation/recoil/recovery poses')
  page.screenshot(path=str(a.evidence/(hero+'-new-gun.png')));page.evaluate('padButton(7,0)');button(9);wait('[data-page="paused"]');button(13);button(2);wait('[data-page="main"]')
 check(not errors,'No browser or Godot errors during four-hero weapon playback');browser.close()
(a.evidence/'weapon-results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2)+'\n');print(len(results),'weapon browser checks passed')
