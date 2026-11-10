"""Real keyboard/two-finger regressions for the original character abilities.
Adventure/flock combat coverage lives in browser_adventure.py.
"""
import argparse,json
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--url',default='http://127.0.0.1:8779');p.add_argument('--evidence',type=Path,default=Path('work/ability-evidence'));args=p.parse_args();args.evidence.mkdir(parents=True,exist_ok=True)
results=[]
def check(value,message):
 assert value,message
 results.append(message);print('PASS',message,flush=True)
with sync_playwright() as p:
 browser=p.chromium.launch(args=['--no-sandbox','--enable-unsafe-swiftshader'])
 context=browser.new_context(viewport={'width':1152,'height':648},locale='tr-TR');page=None
 def data():return page.locator('canvas').evaluate('c=>({...c.dataset})')
 def click(text=None,name=None,touch=False):
  page.wait_for_selector('canvas[data-ui-ready="true"]');d=data();b=next(b for b in json.loads(d['ui']) if (b['name']==name if name else text in b['text']))
  t=json.loads(d['screenTransform']);x=b['x']+b['w']/2;y=b['y']+b['h']/2;r=page.locator('canvas').bounding_box();point={'x':r['x']+(t[0]*x+t[2]*y+t[4])/float(d['rawWidth'])*r['width'],'y':r['y']+(t[1]*x+t[3]*y+t[5])/float(d['rawHeight'])*r['height']}
  (page.touchscreen.tap if touch else page.mouse.click)(**point)
 def game(character,touch=False):
  global page
  if page:page.close()
  page=context.new_page();page.goto(args.url);page.wait_for_selector('canvas[data-state="ready"]',timeout=60000)
  if data()['character']!=character:
   click('Karakterler',touch=touch);page.wait_for_selector('canvas[data-page="characters"]');click(name='Select_'+character,touch=touch);page.wait_for_selector('canvas[data-character="'+character+'"]');page.keyboard.press('Escape');page.wait_for_selector('canvas[data-page="main"]')
  page.keyboard.press('Space');page.wait_for_selector('canvas[data-state="running"]')
 game('aion');page.keyboard.press('Space');page.wait_for_selector('canvas[data-jumps="1"]');page.wait_for_timeout(100);page.keyboard.press('Space');page.wait_for_selector('canvas[data-jumps="2"][data-airborne="true"]');check(True,'Aion performs a second actual airborne jump')
 page.keyboard.press('Space');check(int(data()['jumps'])<=2,'Repeated input never exceeds Aion two-jump budget');page.screenshot(path=str(args.evidence/'aion-double-jump.png'))
 page.wait_for_selector('canvas[data-airborne="false"]');page.keyboard.press('Space');page.wait_for_selector('canvas[data-jumps="1"]');check(True,'Landing replenishes Aion jumps')
 game('owl');page.keyboard.down('Space');page.wait_for_selector('canvas[data-gliding="true"][data-sprite-row="6"]');check(data()['jumps']=='1','Owl has one jump and uses real held glide frames');page.screenshot(path=str(args.evidence/'owl-glide.png'));page.keyboard.up('Space');page.wait_for_selector('canvas[data-gliding="false"]');check(True,'Releasing Space exits glide')
 game('wolf');base=float(data()['speed']);page.keyboard.down('Shift');page.wait_for_selector('canvas[data-boosting="true"][data-sprite-row="6"]');check(float(data()['speed'])>base*1.4,'Shift increases actual wolf speed');before=data()['windHead'];page.wait_for_function('b=>document.querySelector("canvas").dataset.windHead!==b',arg=before);check(data()['actionSheet']=='true','Dash uses its own atlas with moving wind geometry');page.screenshot(path=str(args.evidence/'wolf-wind.png'));page.keyboard.up('Shift');page.wait_for_selector('canvas[data-boosting="false"]');check(True,'Releasing Shift clears boost')
 context.close();page=None
 context=browser.new_context(viewport={'width':844,'height':390},has_touch=True,is_mobile=True,locale='tr-TR');game('wolf',touch=True);page.wait_for_selector('canvas[data-ui-ready="true"]')
 d=data();r=page.locator('canvas').bounding_box();t=json.loads(d['screenTransform'])
 def project(x,y):return {'x':r['x']+(t[0]*x+t[2]*y+t[4])/float(d['rawWidth'])*r['width'],'y':r['y']+(t[1]*x+t[3]*y+t[5])/float(d['rawHeight'])*r['height']}
 first=dict(project(float(d['playerX']),float(d['viewHeight'])-180),id=1);second=dict(project(650,280),id=2);cdp=context.new_cdp_session(page)
 cdp.send('Input.dispatchTouchEvent',{'type':'touchStart','touchPoints':[first]});page.wait_for_selector('canvas[data-boosting="true"]');cdp.send('Input.dispatchTouchEvent',{'type':'touchStart','touchPoints':[first,second]});page.wait_for_selector('canvas[data-boosting="true"][data-airborne="true"]');check(True,'Two phone fingers can hold the wolf to boost and jump elsewhere');page.screenshot(path=str(args.evidence/'mobile-wolf-boost-jump.png'))
 cdp.send('Input.dispatchTouchEvent',{'type':'touchEnd','touchPoints':[]});page.wait_for_selector('canvas[data-boosting="false"]');check(True,'Ending touch contacts clears wolf boost');browser.close()
(args.evidence/'ability-results.json').write_text(json.dumps(results,indent=2)+'\n');print(len(results),'ability browser checks passed')
