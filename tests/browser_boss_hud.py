"""Actual translated boss training HUD after the portrait overflow repair."""
import argparse,json
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--url',default='http://127.0.0.1:8781');p.add_argument('--evidence',required=True,type=Path);a=p.parse_args();a.evidence.mkdir(parents=True,exist_ok=True);checks=[];errors=[]
with sync_playwright() as pw:
 b=pw.chromium.launch(args=['--no-sandbox','--enable-unsafe-swiftshader'])
 for orientation,viewport in [('portrait',{'width':393,'height':873}),('landscape',{'width':873,'height':393})]:
  for code,title in [('tr','Boss antrenmanı'),('en','Boss training'),('cs','Trénink bossů')]:
   ctx=b.new_context(viewport=viewport,has_touch=True,is_mobile=True,locale={'tr':'tr-TR','en':'en-US','cs':'cs-CZ'}[code],service_workers='block');page=ctx.new_page();page.on('pageerror',lambda e:errors.append(str(e)));page.goto(a.url);page.wait_for_selector('canvas[data-state="ready"][data-ui-ready="true"]',timeout=120000)
   def d():return page.locator('canvas').evaluate('c=>({...c.dataset})')
   def tap(text=None,name=None):
    v=d();q=next(q for q in json.loads(v['ui']) if (q['name']==name if name else q['text']==text));t=json.loads(v['screenTransform']);r=page.locator('canvas').bounding_box();x=q['x']+q['w']/2;y=q['y']+q['h']/2;page.touchscreen.tap(r['x']+(t[0]*x+t[2]*y+t[4])/float(v['rawWidth'])*r['width'],r['y']+(t[1]*x+t[3]*y+t[5])/float(v['rawHeight'])*r['height'])
   tap(text=title);page.wait_for_selector('canvas[data-page="bosses"][data-ui-ready="true"]');tap(name='PracticeBoss_'+str(['tr','en','cs'].index(code)));page.wait_for_selector('canvas[data-boss-phase="fight"]');page.wait_for_timeout(700)
   v=d();hud=json.loads(v['bossHud']);w,h=float(v['viewWidth']),float(v['viewHeight'])
   for key in ['status','notice']:
    q=hud[key];assert q['x']>=0 and q['y']>=0 and q['x']+q['w']<=w+1 and q['y']+q['h']<=h+1 and q['required_h']<=q['h'],(orientation,code,key,hud)
   assert hud['status']['y']+hud['status']['h']+4<=hud['bar_y'] and hud['notice']['y']>hud['bar_y']+12,hud
   assert 'SPACE' not in hud['notice']['text'].upper() and ' / F ' not in hud['notice']['text'],hud
   checks.append(orientation+' '+code+': real boss status and mobile help fit without HP overlap or keyboard-only instructions');print('PASS',checks[-1],flush=True);page.screenshot(path=str(a.evidence/(orientation+'-'+code+'-boss.png')));ctx.close()
 assert not errors,errors
 b.close()
(a.evidence/'boss-hud-results.json').write_text(json.dumps(checks,ensure_ascii=False,indent=2)+'\n');print(len(checks),'boss HUD browser checks passed')
