"""Actual menus, natural hero loops, phone gestures, rotation and boss controls.
Normal UI/key/touch inputs and passive observations only; no game setters.
"""
import argparse,json,time
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--url',default='http://127.0.0.1:8781');p.add_argument('--evidence',type=Path,required=True);a=p.parse_args();a.evidence.mkdir(parents=True,exist_ok=True)
results=[];errors=[];samples={}
def check(ok,message):
 assert ok,message
 results.append(message);print('PASS',message,flush=True)
with sync_playwright() as pw:
 browser=pw.chromium.launch(args=['--no-sandbox','--enable-unsafe-swiftshader'])
 def context(size,mobile=False):
  c=browser.new_context(viewport={'width':size[0],'height':size[1]},screen={'width':size[0],'height':size[1]},has_touch=mobile,is_mobile=mobile,locale='tr-TR',service_workers='block',record_video_dir=str(a.evidence/'video'))
  page=c.new_page();page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda m:errors.append(m.text) if 'SCRIPT ERROR' in m.text else None);page.goto(a.url);page.wait_for_selector('canvas[data-state="ready"][data-ui-ready="true"]',timeout=120000);return c,page
 def d(page):return page.locator('canvas').evaluate('c=>({...c.dataset})')
 def wait(page,attrs):
  try:page.wait_for_selector('canvas'+attrs,timeout=10000)
  except Exception:
   v=d(page);print('FAILED INPUT STATE',{k:v.get(k) for k in ['state','page','worldTime','swingId','touchInput','touchTrace','touchFingers','touchSwipes','ducking','controls']},flush=True);page.screenshot(path=str(a.evidence/'failed-input.png'));raise
 def xy(page,x,y):
  v=d(page);t=json.loads(v['screenTransform']);r=page.locator('canvas').bounding_box();return (r['x']+(t[0]*x+t[2]*y+t[4])/float(v['rawWidth'])*r['width'],r['y']+(t[1]*x+t[3]*y+t[5])/float(v['rawHeight'])*r['height'])
 def ui(page,name=None,text=None,touch=False):
  wait(page,'[data-ui-ready="true"]');buttons=json.loads(d(page)['ui']);b=next(b for b in buttons if (b['name']==name if name else text==b['text']));x,y=xy(page,b['x']+b['w']/2,b['y']+b['h']/2);(page.touchscreen.tap if touch else page.mouse.click)(x,y)
 def button(page,name):
  return page.locator('canvas').evaluate('''(c,name)=>{const d=c.dataset,b=JSON.parse(d.controls)[name],t=JSON.parse(d.screenTransform),r=c.getBoundingClientRect(),x=b.x+b.w/2,y=b.y+b.h/2;return [r.x+(t[0]*x+t[2]*y+t[4])/Number(d.rawWidth)*r.width,r.y+(t[1]*x+t[3]*y+t[5])/Number(d.rawHeight)*r.height]}''',name)
 def menu(page):
  state=d(page)
  if state['page']=='finished':ui(page,text='Ana menü')
  else:page.keyboard.press('Escape');wait(page,'[data-state="paused"]');ui(page,text='Ana menü')
  wait(page,'[data-state="ready"]')
 c,page=context((1152,648))
 check(page.locator('#status').count()==0,'Branded loader really hands off to the playable main menu')
 for hero in ['aion','owl','wolf','sheep','rabbit']:
  ui(page,name='StartSelect_'+hero);page.keyboard.press('Space');wait(page,'[data-state="running"]')
  page.evaluate('''()=>{window.poses={};new MutationObserver(()=>{const d=document.querySelector('canvas').dataset;if(d.state==='running'&&d.spriteRow==='1'&&d.attacking==='false'&&d.airborne==='false')poses[d.sourceFrame]=[Number(d.gazeX),Number(d.visualX),d.poseSource]}).observe(document.querySelector('canvas'),{attributes:true})}''')
  expected=12 if hero=='rabbit' else (8 if hero=='wolf' else 7)
  page.wait_for_function('(n)=>Object.keys(poses).length===n',arg=expected)
  poses=page.evaluate('poses');samples[hero]=poses
  check(max(v[0] for v in poses.values())-min(v[0] for v in poses.values())<.01,f'{hero}: actual complete run loop keeps the anatomically reviewed gaze horizontally fixed')
  check(max(v[1] for v in poses.values())==min(v[1] for v in poses.values()),f'{hero}: the physical sprite anchor does not compensate by moving frame to frame')
  page.screenshot(path=str(a.evidence/(hero+'-run.png')))
  if hero=='aion':
   page.keyboard.press('Space');wait(page,'[data-airborne="true"]');page.keyboard.press('Space');wait(page,'[data-jumps="2"]');check(True,'Aion still double jumps with the repaired frames')
  if hero=='owl':
   menu(page);page.keyboard.press('Space');wait(page,'[data-state="running"]')
   page.keyboard.down('Space');wait(page,'[data-gliding="true"]');page.evaluate("window.glide=[];new MutationObserver(()=>{const d=document.querySelector('canvas').dataset;if(d.gliding==='true'&&d.attacking==='false')glide.push(Number(d.gazeX))}).observe(document.querySelector('canvas'),{attributes:true})")
   page.wait_for_function('glide.length>12',timeout=5000);xs=page.evaluate('glide');print('OWL_GLIDE_SAMPLES',len(xs),min(xs),max(xs),flush=True);check(len(xs)>12 and max(xs)-min(xs)<.01,'Owl glides through actual frames without lateral sway');page.screenshot(path=str(a.evidence/'owl-glide.png'));page.keyboard.up('Space')
  if hero=='wolf':
   page.keyboard.down('Shift');wait(page,'[data-boosting="true"][data-pose-source="agility-wolf"]');page.keyboard.press('j');wait(page,'[data-attack-kind="sprint-bite"]');check(True,'Wolf retains its four-legged sprint and separate sprint bite');page.keyboard.up('Shift')
  menu(page)
 c.close()
 for name,size in [('portrait',(393,873)),('landscape',(873,393))]:
  c,page=context(size,True);cdp=c.new_cdp_session(page);points={}
  def touch(index,point=None,kind='start'):
   if kind=='cancel':points.clear();cdp.send('Input.dispatchTouchEvent',{'type':'touchCancel','touchPoints':[]});return
   if kind in ['start','move']:points[index]={'x':point[0],'y':point[1],'id':index}
   else:points.pop(index,None)
   cdp.send('Input.dispatchTouchEvent',{'type':{'start':'touchStart','move':'touchMove','end':'touchEnd'}[kind],'touchPoints':list(points.values())})
  check(d(page)['orientation']==name,f'{name}: upright orientation is selected from the actual viewport')
  page.screenshot(path=str(a.evidence/(name+'-main.png')))
  ui(page,text='Koşuya başla',touch=True);wait(page,'[data-state="running"]')
  ui(page,text='Anladım · Devam et',touch=True)
  page.wait_for_function('!JSON.parse(document.querySelector("canvas").dataset.ui).some(b=>b.text==="Anladım · Devam et")')
  p0=xy(page,210,280);p1=xy(page,214,355)
  page.evaluate('''()=>{window.swipeObserved=false;new MutationObserver(()=>{const d=document.querySelector('canvas').dataset;if(d.ducking==='true'&&d.airborne==='false'&&d.touchSwipes==='1')swipeObserved=true}).observe(document.querySelector('canvas'),{attributes:true})}''')
  # One browser-level gesture keeps the intended fast swipe timing. Separate
  # protocol round trips can turn it into a >180 ms long press under load.
  cdp.send('Input.synthesizeScrollGesture',{'x':p0[0],'y':p0[1],'yDistance':p1[1]-p0[1],'speed':1000,'gestureSourceType':'touch','preventFling':True})
  page.wait_for_function('swipeObserved')
  check(True,f'{name}: a real down swipe rolls once without a jump')
  page.wait_for_timeout(150)
  ui(page,text='Duraklat',touch=True);wait(page,'[data-state="paused"]');ui(page,text='Ana menü',touch=True);ui(page,text='Koşuya başla',touch=True);wait(page,'[data-state="running"]')
  attack=button(page,'attack');before=int(d(page)['swingId']);touch(0,attack);wait(page,'[data-attacking="true"]');page.wait_for_timeout(650)
  check(int(d(page)['swingId'])==before+1,f'{name}: holding the attack circle gives exactly one strike')
  touch(0,kind='end');touch(0,attack);wait(page,'[data-attacking="true"]');check(int(d(page)['swingId'])==before+2,f'{name}: release and tap gives the alternating strike')
  touch(0,kind='cancel');page.wait_for_timeout(30);check(d(page)['touchFingers']=='0',f'{name}: touch cancellation releases all fingers')
  # Each independent input scenario starts through the real menus; idle
  # screenshot/protocol time must not turn an input test into hazard survival.
  if d(page)['state'] not in ['running','paused']:wait(page,'[data-page="finished"]')
  menu(page);ui(page,text='Koşuya başla',touch=True);wait(page,'[data-state="running"]')
  # Resolve both coordinates before pressing Jump: protocol/layout reads
  # between the fingers can outlast the short airborne window on a slow GPU.
  jump_point=button(page,'jump');attack_point=button(page,'attack')
  page.evaluate('''()=>{window.multiActionObserved=false;new MutationObserver(()=>{const d=document.querySelector('canvas').dataset;if(d.airborne==='true'&&d.jumpHeld==='true'&&d.attacking==='true')multiActionObserved=true}).observe(document.querySelector('canvas'),{attributes:true})}''')
  touch(0,jump_point);touch(1,attack_point);page.wait_for_function('multiActionObserved');check(True,f'{name}: jump can stay held while another finger attacks');touch(0,kind='cancel')
  old=d(page);new_size={'width':873,'height':393} if name=='portrait' else {'width':393,'height':873};page.set_viewport_size(new_size);wait(page,'[data-orientation="'+('landscape' if name=='portrait' else 'portrait')+'"][data-ui-ready="true"]');new=d(page)
  check(new['character']==old['character'] and int(new['score'])>=int(old['score']) and new['state']=='running',f'{name}: rotating mid-run keeps the character, score and running state')
  page.keyboard.press('Escape');wait(page,'[data-state="paused"]');page.screenshot(path=str(a.evidence/(name+'-rotated-pause.png')))
  ui(page,text='Ana menü',touch=True);wait(page,'[data-state="ready"]');ui(page,text='Boss antrenmanı',touch=True);ui(page,name='PracticeBoss_0',touch=True);wait(page,'[data-boss-phase="fight"]')
  hp=int(d(page)['bossHp']);touch(0,button(page,'shoot'));page.wait_for_function('(hp)=>Number(document.querySelector("canvas").dataset.bossHp)<hp',arg=hp);touch(0,kind='end')
  check(True,f'{name}: the boss Fire circle emits real projectiles and lowers actual boss health')
  page.screenshot(path=str(a.evidence/(name+'-boss.png')))
  intervals=page.evaluate('()=>new Promise(resolve=>{const dt=[];let prior=performance.now();function step(now){dt.push(now-prior);prior=now;if(dt.length>=60)resolve(dt);else requestAnimationFrame(step)}requestAnimationFrame(step)})')
  (a.evidence/(name+'-performance.json')).write_text(json.dumps({'raf_ms':intervals,'average_fps':1000/(sum(intervals)/len(intervals)),'context':'Software GPU in cloud with recording; not physical phone performance'},indent=2)+'\n')
  c.close()
 check(not errors,'No uncaught browser or Godot script errors in all tested inputs and layouts')
 browser.close()
(a.evidence/'browser-results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2)+'\n');(a.evidence/'run-samples.json').write_text(json.dumps(samples,indent=2)+'\n');print(len(results),'real browser UX checks passed')
