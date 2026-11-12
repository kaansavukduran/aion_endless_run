"""Normal inputs and passive pose observations for wolf/owl mobility; no setters."""
import argparse,json
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--url',default='http://127.0.0.1:8779');p.add_argument('--evidence',type=Path,default=Path('work/agility-evidence'));a=p.parse_args();a.evidence.mkdir(parents=True,exist_ok=True);results=[];errors=[]
def check(v,m):
 assert v,m
 results.append(m);print('PASS',m,flush=True)
with sync_playwright() as pw:
 browser=pw.chromium.launch(args=['--no-sandbox','--enable-unsafe-swiftshader']);ctx=browser.new_context(viewport={'width':1152,'height':648},locale='en-US',record_video_dir=str(a.evidence/'video'));page=ctx.new_page();page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda m:errors.append(m.text) if 'SCRIPT ERROR' in m.text else None)
 def d():return page.locator('canvas').evaluate('c=>({...c.dataset})')
 def wait(s):page.wait_for_selector('canvas'+s,timeout=90000)
 def click(name=None,text=None):
  wait('[data-ui-ready="true"]');v=d();b=next(b for b in json.loads(v['ui']) if (b['name']==name if name else text in b['text']));t=json.loads(v['screenTransform']);r=page.locator('canvas').bounding_box();x=b['x']+b['w']/2;y=b['y']+b['h']/2;page.mouse.click(r['x']+(t[0]*x+t[2]*y+t[4])/float(v['rawWidth'])*r['width'],r['y']+(t[1]*x+t[3]*y+t[5])/float(v['rawHeight'])*r['height'])
 def main():
  page.keyboard.up('Space');page.keyboard.up('Shift');page.keyboard.up('j')
  if d()['page']=='finished':click(text='Main menu')
  else:page.keyboard.press('Escape');wait('[data-page="paused"]');click(text='Main menu')
  wait('[data-page="main"]')
 def start(hero):click(name='StartSelect_'+hero);page.keyboard.press('Space');wait('[data-state="running"]')
 page.goto(a.url);wait('[data-version="0.13.0"][data-state="ready"]')
 page.evaluate('''()=>{window.agility={wolf:{},owl:{},glideX:[],sprintMax:0,biteMax:0,peckMax:0,airPeck:false,wingGaze:[]};new MutationObserver(()=>{const d=document.querySelector('canvas').dataset;if(d.state!=='running')return;if(d.attacking==='true'){if(d.attackKind==='sprint-bite')agility.sprintMax=Math.max(agility.sprintMax,Number(d.visualX)-Number(d.playerX));if(d.attackKind==='bite')agility.biteMax=Math.max(agility.biteMax,Number(d.visualX)-Number(d.playerX));if(d.attackKind==='peck'){agility.peckMax=Math.max(agility.peckMax,Number(d.visualX)-Number(d.playerX));if(d.airborne==='true'&&d.poseSource==='agility-owl'&&d.sourceRow==='3')agility.airPeck=true;}if(d.character==='owl'&&d.attackKind==='melee'&&d.poseSource==='agility-owl')agility.wingGaze.push(Number(d.gazeX));}if(d.boosting==='true'&&d.character==='wolf'&&d.sourceRow==='0'&&d.poseSource==='agility-wolf')window.agility.wolf[d.sourceFrame]=true;if(d.gliding==='true'&&d.attacking==='false'&&d.poseSource==='agility-owl'&&d.sourceRow==='0'){window.agility.owl[d.sourceFrame]=true;window.agility.glideX.push(Number(d.gazeX));}}).observe(document.querySelector('canvas'),{attributes:true})}''')
 start('wolf');page.keyboard.down('Shift');wait('[data-boosting="true"][data-pose-source="agility-wolf"][data-source-row="0"]');page.wait_for_function('Object.keys(agility.wolf).length===8');check(True,'Wolf really plays all eight low four-legged sprint frames')
 page.screenshot(path=str(a.evidence/'wolf-four-legged-sprint.png'));page.keyboard.press('j');wait('[data-attack-kind="sprint-bite"][data-source-row="3"]');page.wait_for_timeout(160);page.wait_for_function('agility.sprintMax>35');check(page.evaluate('agility.sprintMax')>35,'Sprint attack visibly lunges farther forward');page.screenshot(path=str(a.evidence/'wolf-sprint-bite.png'));page.keyboard.up('Shift');check(page.evaluate('agility.sprintMax')>35,'Actual sprint bite was dispatched and advanced before boost release');main()
 start('wolf');page.keyboard.down('j');wait('[data-attacking="true"][data-source-row="1"]');page.wait_for_function('agility.biteMax>25');check(page.evaluate('agility.biteMax')>25,'Normal wolf bite opens forward with a real lunge');page.screenshot(path=str(a.evidence/'wolf-contact-bite.png'));page.wait_for_timeout(350);check(d()['attacking']=='false','Holding attack does not repeat the bite');page.keyboard.up('j');page.wait_for_timeout(130);page.keyboard.press('j');wait('[data-attacking="true"][data-source-row="2"]');page.wait_for_timeout(170);check(d()['attackKind']=='claw','Next normal attack alternates to the physical claw swipe');page.screenshot(path=str(a.evidence/'wolf-claw-contact.png'));main()
 for attempt in range(3):
  start('owl');page.keyboard.down('Space');wait('[data-gliding="true"]')
  try:page.wait_for_function('Object.keys(agility.owl).length===8',timeout=3000)
  except Exception:
   main();continue
  break
 check(page.evaluate('Object.keys(agility.owl).length===8'),'Owl really plays all eight calm glide frames')
 xs=page.evaluate('agility.glideX');check(max(xs)-min(xs)<0.02,'Actual registered near eye stays fixed horizontally through the whole glide loop')
 page.screenshot(path=str(a.evidence/'owl-calm-glide.png'));main()
 start('owl');page.keyboard.down('Space');wait('[data-gliding="true"]');page.keyboard.press('j');wait('[data-attack-kind="peck"][data-pose-source="agility-owl"][data-source-row="3"]');page.wait_for_timeout(170);check(page.evaluate('agility.airPeck'),'Beak strike is rendered in flight with spread wings');check(0<page.evaluate('agility.peckMax')<=18.1,'Air peck makes one controlled forward thrust');page.screenshot(path=str(a.evidence/'owl-airborne-beak.png'));main()
 start('owl');page.keyboard.press('j');wait('[data-attacking="true"][data-source-row="1"]');page.wait_for_timeout(170);check(page.evaluate('agility.wingGaze.length>1&&Math.max(...agility.wingGaze)-Math.min(...agility.wingGaze)<.02'),'Grounded wing strike keeps the torso horizontally steady');page.screenshot(path=str(a.evidence/'owl-forward-wing.png'));main()
 check(not errors,'No browser or Godot errors in new mobility and attack flows')
 (a.evidence/'gaze-samples.json').write_text(json.dumps(xs)+'\n');(a.evidence/'kinematics.json').write_text(json.dumps(page.evaluate('({sprintMax:agility.sprintMax,biteMax:agility.biteMax,peckMax:agility.peckMax,glideMin:Math.min(...agility.glideX),glideMax:Math.max(...agility.glideX),airPeck:agility.airPeck,wingMin:Math.min(...agility.wingGaze),wingMax:Math.max(...agility.wingGaze)})'),indent=2)+'\n');ctx.close();browser.close()
(a.evidence/'agility-results.json').write_text(json.dumps(results,indent=2)+'\n');print(len(results),'agility browser checks passed')
