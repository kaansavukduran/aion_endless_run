"""Real-input 0.8 anatomy, isolated frames, four biomes, gaps/plants and boss chase.
No game setters, forced spawns, RNG replacement, shortcuts or synthetic levels.
"""
import argparse,json,time
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--url',default='http://127.0.0.1:8779');p.add_argument('--evidence',type=Path,default=Path('work/frontier-evidence'));a=p.parse_args();out=a.evidence;out.mkdir(parents=True,exist_ok=True)
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
 page.goto(a.url);page.wait_for_selector('canvas[data-state="ready"][data-version="0.8.0"]',timeout=90000);ready()
 check(d()['lang']=='tr','The actual 0.8 entry retains browser-language selection')
 for hero in ['aion','owl','sheep','wolf']:
  run(hero);head=float(d()['heroHeadSize']);check(d()['isolatedFrame']=='true',hero+': running uses a separate padded frame texture')
  if hero=='wolf':
   page.keyboard.down('Shift');page.wait_for_selector('canvas[data-boosting="true"]');check(abs(float(d()['heroHeadSize'])-head)<.01,'Wolf sprint preserves its actual calibrated head size');page.screenshot(path=str(out/'wolf-anatomical-dash.png'));page.keyboard.up('Shift')
  run(hero);head=float(d()['heroHeadSize']);page.keyboard.press('Space');page.wait_for_selector('canvas[data-airborne="true"]');check(abs(float(d()['heroHeadSize'])-head)<.01,hero+': jumping does not enlarge the character anatomy')
  run(hero);page.mouse.click(**point(600,270));page.wait_for_selector('canvas[data-attacking="true"]');check(d()['isolatedFrame']=='true' and abs(float(d()['heroHeadSize'])-head)<.01,hero+': a strike is isolated from adjacent atlas pixels and keeps the same head span');page.screenshot(path=str(out/(hero+'-isolated-strike.png')))
 # Normal player controls only. Survive the actual generated route and chase.
 biomes=set();captured_biomes=set();fight_capture=False;gaps=False;plant_seen=False;plant_bolt=False;boss_seen=False;boss_damage=False;boss_won=False;mobile_shoot=False;arena_clean=True;level_frozen=True;boss_distance=None;shooting=False;timelines=[];won_capture=set()
 for attempt in range(6):
  run('sheep');started=time.monotonic();shooting=False;boss_distance=None
  while time.monotonic()-started<170:
   v=d()
   if v['state']!='running':print('Route retry',attempt,v['state'],v['level'],v['bossPhase'],v['obstacles'],v['enemies'],flush=True);page.screenshot(path=str(out/('route-failure-'+str(attempt)+'.png')));break
   
   if int(v['biome'])==0 or float(v['worldDistance'])%6500>700:biomes.add(int(v['biome']))
   player=float(v['playerX']);speed=float(v['speed']);boss=v['bossPhase'];giant=v['giant']=='true'
   if boss!='run':
    arena_clean=arena_clean and all(not json.loads(v[key]) for key in ['obstacles','enemies','items','plants'])
    if boss_distance is None:boss_distance=float(v['worldDistance'])
    level_frozen=level_frozen and float(v['worldDistance'])==boss_distance
    if not boss_seen:
     boss_seen=True;page.screenshot(path=str(out/'real-handoff-boss-intro.png'))
    if boss=='fight' and not mobile_shoot:
     page.keyboard.press('Escape');page.wait_for_selector('canvas[data-state="paused"]');page.evaluate('document.fullscreenElement ? document.exitFullscreen() : Promise.resolve()');page.set_viewport_size({'width':390,'height':844});page.wait_for_timeout(200);ready();page.keyboard.press('Escape');page.wait_for_selector('canvas[data-state="running"]');ready()
     def contact(key,id):
      b=json.loads(d()['controls'])[key];return dict(point(b['x']+b['w']/2,b['y']+b['h']/2),id=id)
     cdp=context.new_cdp_session(page);fire=contact('shoot',1);jump=contact('jump',2);before=int(d()['bossShots'])
     cdp.send('Input.dispatchTouchEvent',{'type':'touchStart','touchPoints':[fire,jump]});page.wait_for_function('n=>Number(document.querySelector("canvas").dataset.bossShots)>n',arg=before);page.wait_for_selector('canvas[data-airborne="true"]');check(d()['orientation']=='landscape','A rotated portrait phone can shoot and jump with two real fingers during the boss');page.screenshot(path=str(out/'portrait-two-finger-boss.png'));cdp.send('Input.dispatchTouchEvent',{'type':'touchEnd','touchPoints':[]});mobile_shoot=True
     page.keyboard.press('Escape');page.wait_for_selector('canvas[data-state="paused"]');page.evaluate('document.fullscreenElement ? document.exitFullscreen() : Promise.resolve()');page.set_viewport_size({'width':1152,'height':648});page.wait_for_timeout(200);ready();page.keyboard.press('Escape');page.wait_for_selector('canvas[data-state="running"]');ready()
    if boss=='fight':
     if not shooting:page.mouse.move(**point(600,280));page.mouse.down(button='right');shooting=True
     if int(v['bossHp'])<int(v['bossMaxHp']):boss_damage=True
     ps=[p for p in json.loads(v['projectiles']) if p['owner']=='boss' and p['x']>player-60]
     if not fight_capture and int(v['bossHp'])<int(v['bossMaxHp'])-8 and (not ps or min((p['x']-player)/abs(p['vx']) for p in ps)>.9):
      page.screenshot(path=str(out/'actual-robot-chase.png'));fight_capture=True
     high=any(p['kind']=='bolt' and -60<p['x']-player<350 for p in ps)
     if high:page.keyboard.down('s')
     else:page.keyboard.up('s')
     low=any(p['kind']=='ember' and 0<(p['x']-player)/abs(p['vx'])<.45 for p in ps)
     if low and v['airborne']=='false':page.keyboard.up('s');page.keyboard.press('Space')
     timelines.append({'t':time.monotonic()-started,'level':v['level'],'phase':boss,'hp':v['bossHp'],'health':v['bossPlayerHp'],'shots':v['bossShots'],'hits':v['bossHits'],'distance':v['worldDistance'],'warning':v['bossWarning']})
    else:
     if shooting:page.mouse.up(button='right');shooting=False
     page.keyboard.up('s')
     if boss=='victory' and int(v['bossWins']) not in won_capture:
      won_capture.add(int(v['bossWins']));boss_won=True;page.screenshot(path=str(out/'boss-victory.png'))
   else:
    boss_distance=None
    if shooting:page.mouse.up(button='right');shooting=False
    obstacles=[o for o in json.loads(v['obstacles']) if o['x']>player-float(o.get('width',160))/2-45]
    nearest=min(obstacles,key=lambda o:o['x'],default=None)
    enemies=[e for e in json.loads(v['enemies']) if e['hp']>0 and e['x']>player-60]
    low_crow=any(e['kind']=='crow' and -115<e['y']<-45 and -65<e['x']-player<speed*.65+100 for e in enemies)
    arch=nearest and nearest['kind'].startswith('arch') and -90<nearest['x']-player<speed*.70+90
    if (arch or low_crow) and not giant:page.keyboard.down('s')
    else:page.keyboard.up('s')
    floor=nearest and not nearest['kind'].startswith('arch') and 0<nearest['x']-player<speed*.40+(float(nearest.get('width',64))*.25 if nearest['kind'].startswith('pit') else 25)
    ps=[p for p in json.loads(v['projectiles']) if p['owner']=='plant' and 0<(p['x']-player)/abs(p['vx'])<.45]
    plants=json.loads(v['plants'])
    if plants:plant_seen=True
    plant_bolt=plant_bolt or any(p['owner']=='plant' for p in json.loads(v['projectiles']))
    plant_body=any(0<p['x']-player<speed*.48+20 for p in plants)
    stomp_target=any(e['kind']=='gnome' and 0<e['x']-player<speed*.61+20 for e in enemies) and not arch and not low_crow
    if (floor or ps or plant_body or stomp_target) and v['airborne']=='false' and (not giant or nearest and nearest['kind'].startswith('pit')):page.keyboard.up('s');page.keyboard.press('Space')
    if any(o['kind'].startswith('pit') and abs(o['x']-player)<float(o.get('width',150))*.45 for o in obstacles) and v['airborne']=='true':
     gaps=True
    close=[e for e in enemies if 0<e['x']-player<speed*.18+110]
    if close and v['ducking']=='false' and v['attacking']=='false' and float(v['attackCooldown'])<.05:page.mouse.click(**point(600,270))
    if int(v['biome']) in [2,3] and int(v['biome']) in biomes and int(v['biome']) not in captured_biomes and not any(0<o['x']-player<speed*1.5+80 for o in obstacles) and not any(-60<e['x']-player<speed*1.5+80 for e in enemies) and not plants and not ps:page.screenshot(path=str(out/('biome-'+v['biome']+'.png')));captured_biomes.add(int(v['biome']))
   if len(biomes)==4 and plant_seen and plant_bolt and gaps and boss_won and int(v['bossWins'])>=2 and boss=='run':break
   page.wait_for_timeout(15)
  if shooting:page.mouse.up(button='right');shooting=False
  page.keyboard.up('s')
  if len(biomes)==4 and plant_seen and plant_bolt and gaps and boss_won:break
 check(boss_seen and arena_clean,'A naturally reached tenth-level handoff starts an arena containing only the boss and hero combat')
 check(level_frozen,'Normal distance and levels remain frozen while the actual chase scenery advances')
 check(boss_damage and boss_won,'Real right-click energy projectiles lower the health bar and defeat the original robot')
 check(mobile_shoot,'The real boss Fire button supports held touch alongside a second jump contact')
 check(len(biomes)==4,'A real generated route visits desert, snow, marsh and city')
 check(gaps,'A real jump clears a naturally generated floor gap')
 check(plant_seen and plant_bolt,'A naturally rare plant visibly telegraphs and creates an actual fire projectile')
 (out/'boss-timeline.json').write_text(json.dumps(timelines,indent=2)+'\n')
 page.keyboard.press('Escape');page.wait_for_selector('canvas[data-state="paused"]');context.set_offline(True);page.keyboard.press('Escape');page.wait_for_selector('canvas[data-state="running"]');before=float(d()['worldDistance']);page.wait_for_timeout(250);check(float(d()['worldDistance'])>before,'The expanded game continues offline after a boss victory');context.set_offline(False)
 check(not errors,'No uncaught browser or Godot script errors in the full normal-entry frontier run');browser.close()
(out/'frontier-results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2)+'\n');print(len(results),'frontier browser checks passed')
