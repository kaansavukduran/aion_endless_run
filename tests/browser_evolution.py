"""Real entry, single-edge strikes, rolling, levels, hug freeze and rare-power UI.
No game-state writes, test spawns or RNG replacement. Public canvas fields are
read-only observations of the running scene and visible controls.
"""
import argparse,json,time
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--url',default='http://127.0.0.1:8779');p.add_argument('--evidence',type=Path,default=Path('work/evolution-evidence'));a=p.parse_args();out=a.evidence;out.mkdir(parents=True,exist_ok=True)
results=[];errors=[]
def check(ok,msg):
 assert ok,msg
 results.append(msg);print('PASS',msg,flush=True)
with sync_playwright() as p:
 browser=p.chromium.launch(args=['--no-sandbox','--enable-unsafe-swiftshader']);context=browser.new_context(viewport={'width':1152,'height':648},locale='tr-TR');page=context.new_page()
 page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda m:errors.append(m.text) if 'SCRIPT ERROR' in m.text else None)
 def d():return page.locator('canvas').evaluate('c=>({...c.dataset,lang:c.getAttribute("lang")})')
 def ready():page.wait_for_selector('canvas[data-ui-ready="true"]')
 def point(x,y):
  v=d();t=json.loads(v['screenTransform']);r=page.locator('canvas').bounding_box()
  return {'x':r['x']+(t[0]*x+t[2]*y+t[4])/float(v['rawWidth'])*r['width'],'y':r['y']+(t[1]*x+t[3]*y+t[5])/float(v['rawHeight'])*r['height']}
 def click(name=None,text=None):
  ready();b=next(b for b in json.loads(d()['ui']) if (b['name']==name if name else text in b['text']));page.mouse.click(**point(b['x']+b['w']/2,b['y']+b['h']/2))
 def main():
  if d()['page']=='':
   if d()['state']=='running':page.keyboard.press('Escape')
   page.wait_for_function('() => ["paused","finished"].includes(document.querySelector("canvas").dataset.page)')
  if d()['page'] in ['settings','characters']:page.keyboard.press('Escape');ready()
  if d()['page']!='main':click(text={'tr':'Ana menü','en':'Main menu','cs':'Hlavní nabídka'}[d()['lang']]);page.wait_for_selector('canvas[data-page="main"]');ready()
 def run(hero):
  main();click(name='StartSelect_'+hero);page.wait_for_selector('canvas[data-character="'+hero+'"]');ready();page.keyboard.press('Space');page.wait_for_selector('canvas[data-state="running"]');ready()
 def number(key,value):
  for _ in range(14):
   v=d();b=json.loads(v['settingsInputs'])[key]
   if 180<b['y']<475:break
   page.mouse.move(**point(float(v['viewWidth'])/2+257,420));page.mouse.wheel(0,230 if b['y']>=475 else -230);page.wait_for_timeout(100)
  b=json.loads(d()['settingsInputs'])[key];page.mouse.click(**point(b['x']+b['w']*.38,b['y']+b['h']/2));page.keyboard.press('Control+a');page.keyboard.type(str(value));page.keyboard.press('Enter');page.wait_for_timeout(150)
 page.goto(a.url);page.wait_for_selector('canvas[data-state="ready"]',timeout=60000);ready()
 check(abs(float(d()['mushroomChance'])-.02)<.0001,'Normal fresh entry uses the rare two-percent mushroom default')
 for hero in ['aion','owl','sheep','wolf']:
  run(hero);page.mouse.move(**point(600,270));page.mouse.down();page.wait_for_selector('canvas[data-swing-count="1"][data-attack-variant="0"]');page.wait_for_timeout(110);page.screenshot(path=str(out/(hero+'-strike-a.png')))
  page.wait_for_timeout(850);check(d()['swingCount']=='1',hero+': holding left click creates only one real swing');page.mouse.up()
  page.mouse.click(**point(600,270));page.wait_for_selector('canvas[data-swing-count="2"][data-attack-variant="1"]');page.wait_for_timeout(110);page.screenshot(path=str(out/(hero+'-strike-b.png')));check(True,hero+': the next click uses the second drawn attack')
  run(hero);page.keyboard.down('s');page.wait_for_selector('canvas[data-ducking="true"]');frame=d()['rollFrame'];page.wait_for_function('f=>document.querySelector("canvas").dataset.rollFrame!==f',arg=frame);page.screenshot(path=str(out/(hero+'-roll.png')));check(True,hero+': ground roll advances distinct rotation frames');page.keyboard.up('s');page.wait_for_selector('canvas[data-ducking="false"]')
  check(not any(i['kind']=='mushroom' for i in json.loads(d()['items'])),'No mandatory starting mushroom: '+hero)
 # Choose the legitimate player-facing probability control for the power demo.
 main();click(text='Ayarlar');page.wait_for_selector('canvas[data-page="settings"]');ready();number('MushroomChance',100);number('PrismIntensity',75)
 check(abs(float(d()['mushroomChance'])-1)<.001 and abs(float(d()['prismIntensity'])-.75)<.001,'Probability and color intensity can be independently changed through Settings')
 page.screenshot(path=str(out/'probability-settings.png'));page.keyboard.press('Escape');ready();page.wait_for_timeout(2300);page.reload();page.wait_for_selector('canvas[data-state="ready"]',timeout=60000);ready()
 check(float(d()['mushroomChance'])==1 and abs(float(d()['prismIntensity'])-.75)<.001,'Both numeric settings persist after an actual reload')
 def bot():
  v=d()
  if v['state']!='running' or v['hugging']=='true':return v
  player=float(v['playerX']);speed=float(v['speed']);giant=v['giant']=='true'
  obstacles=[o for o in json.loads(v['obstacles']) if o['x']>player-90]
  nearest=min(obstacles,key=lambda o:o['x'],default=None)
  crows=[e for e in json.loads(v['enemies']) if e['hp']>0 and e['kind']=='crow' and -112<e['y']<-45 and -65<e['x']-player<speed*.65+110]
  arch=nearest and nearest['kind'].startswith('arch') and -80<nearest['x']-player<speed*.7+100
  if (arch or crows) and not giant:page.keyboard.down('s')
  else:page.keyboard.up('s')
  floor=nearest and not nearest['kind'].startswith('arch') and 0<nearest['x']-player<speed*.40+20
  if floor and not giant and v['airborne']=='false':page.keyboard.up('s');page.keyboard.press('Space')
  enemies=[e for e in json.loads(v['enemies']) if e['hp']>0 and 0<e['x']-player<speed*.18+(185 if giant else 110)]
  if enemies and v['ducking']=='false' and v['attacking']=='false' and float(v['attackCooldown'])<.08:
   page.mouse.click(**point(600,260))
  return v
 hug_ok=False;giant_ok=False;wave_ok=False;level_variants={};styles={};hug_evidence=None
 for attempt in range(5):
  run('sheep');level_variants={};styles={};started=time.monotonic();hug_evidence=None
  page.evaluate('''() => {window.hugFrames=[];window.hugObs=new MutationObserver(()=>{const c=document.querySelector('canvas');if(c.dataset.hugging==='true')window.hugFrames.push({t:performance.now(),clock:Number(c.dataset.worldTime),distance:Number(c.dataset.worldDistance),enemies:c.dataset.enemies,powers:c.dataset.powers});});window.hugObs.observe(document.querySelector('canvas'),{attributes:true,attributeFilter:['data-hug-time']});}''')
  while time.monotonic()-started<100:
   v=bot()
   if v['state']!='running':print('Run observation retry',attempt,v['state'],v['level'],flush=True);break
   if int(v['girl'])>=0:level_variants[int(v['level'])]=int(v['girl']);styles[int(v['level'])]=int(v['partyStyle'])
   if v['hugging']=='true' and hug_evidence is None:
    page.screenshot(path=str(out/'milestone-hug.png'));hug_evidence=page.evaluate('window.hugFrames')
   if not hug_ok and int(v['hugCount'])>0 and v['hugging']=='false' and float(v['heartTime'])>0:
    hug_evidence=page.evaluate('window.hugFrames');hug_ok=len(hug_evidence)>2 and all(s['clock']==hug_evidence[0]['clock'] and s['distance']==hug_evidence[0]['distance'] and s['enemies']==hug_evidence[0]['enemies'] and s['powers']==hug_evidence[0]['powers'] for s in hug_evidence)
    page.screenshot(path=str(out/'hug-hearts-resume.png'))
   if v['giant']=='true':
    if not giant_ok:page.screenshot(path=str(out/'rare-mushroom-colors.png'))
    giant_ok=True
    if not wave_ok and len([e for e in json.loads(v['enemies']) if e['kind']=='gnome' and e['hp']>0])>=4:
     wave_ok=True;page.screenshot(path=str(out/'irregular-gnome-crowd.png'))
   if hug_ok and giant_ok and wave_ok:break
   page.wait_for_timeout(20)
  page.evaluate('window.hugObs.disconnect()')
  if hug_ok and giant_ok and wave_ok:break
 check(hug_ok,'A natural level-ten hug freezes real travel/enemies/power clocks and resumes with hearts')
 (out/'hug-freeze-timeline.json').write_text(json.dumps(hug_evidence,indent=2)+'\n')
 check(len(set(level_variants.values()))>=6,'A real longer run shows multiple different celebration characters')
 check(all(x!=y for x,y in zip(list(level_variants.values()),list(level_variants.values())[1:])),'Consecutive level-ups change the celebration character')
 check(len(set(styles.values()))>=3,'Real level-ups use different celebration effects')
 check(giant_ok and wave_ok,'A real configured rare-power pickup starts enlarged colorful play with a gnome crowd')
 (out/'level-variants.json').write_text(json.dumps({'girls':level_variants,'styles':styles},indent=2)+'\n')
 page.keyboard.press('Escape');page.wait_for_selector('canvas[data-state="paused"]');saved=d()['level'];page.wait_for_timeout(350);check(d()['level']==saved,'Pause preserves the current run level')
 context.set_offline(True);page.keyboard.press('Escape');page.wait_for_selector('canvas[data-state="running"]');before=float(d()['worldDistance']);page.wait_for_timeout(250);check(float(d()['worldDistance'])>before,'The expanded game continues to run without network access');context.set_offline(False)
 context.close()
 context=browser.new_context(viewport={'width':390,'height':844},locale='tr-TR',has_touch=True,is_mobile=True);page=context.new_page()
 page.on('pageerror',lambda e:errors.append(str(e)));page.on('console',lambda m:errors.append(m.text) if 'SCRIPT ERROR' in m.text else None)
 page.goto(a.url);page.wait_for_selector('canvas[data-state="ready"]',timeout=60000);ready()
 check(d()['orientation']=='landscape','A portrait phone renders the new controls in a landscape playfield')
 b=next(b for b in json.loads(d()['ui']) if 'Koşuya başla' in b['text']);page.touchscreen.tap(**point(b['x']+b['w']/2,b['y']+b['h']/2));page.wait_for_selector('canvas[data-state="running"]');ready()
 def contact(key,id):
  b=json.loads(d()['controls'])[key];return dict(point(b['x']+b['w']/2,b['y']+b['h']/2),id=id)
 cdp=context.new_cdp_session(page);jump=contact('jump',1);attack=contact('attack',2)
 cdp.send('Input.dispatchTouchEvent',{'type':'touchStart','touchPoints':[jump]});page.wait_for_selector('canvas[data-airborne="true"]')
 cdp.send('Input.dispatchTouchEvent',{'type':'touchStart','touchPoints':[jump,attack]});page.wait_for_selector('canvas[data-attacking="true"][data-airborne="true"]');check(d()['swingCount']=='1','Two real phone fingers jump and perform one attack without mouse duplication')
 page.wait_for_timeout(650);check(d()['swingCount']=='1','Holding the phone attack contact does not repeat strikes')
 cdp.send('Input.dispatchTouchEvent',{'type':'touchEnd','touchPoints':[]});page.wait_for_selector('canvas[data-airborne="false"]')
 cdp.send('Input.dispatchTouchEvent',{'type':'touchStart','touchPoints':[attack]});page.wait_for_selector('canvas[data-swing-count="2"][data-attack-variant="1"]');check(True,'A second phone press switches to the alternate attack')
 cdp.send('Input.dispatchTouchEvent',{'type':'touchEnd','touchPoints':[]});roll=contact('duck',3)
 cdp.send('Input.dispatchTouchEvent',{'type':'touchStart','touchPoints':[roll]});page.wait_for_selector('canvas[data-ducking="true"]');frame=d()['rollFrame'];page.wait_for_function('f=>document.querySelector("canvas").dataset.rollFrame!==f',arg=frame);page.screenshot(path=str(out/'portrait-touch-roll.png'))
 cdp.send('Input.dispatchTouchEvent',{'type':'touchEnd','touchPoints':[]});page.wait_for_selector('canvas[data-ducking="false"]');check(True,'The rotated phone roll button advances drawn poses and releases after the minimum roll')
 check(not errors,'No uncaught browser or Godot script errors in the expanded real-entry flows');browser.close()
(out/'evolution-results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2)+'\n');print(len(results),'evolution browser checks passed')
