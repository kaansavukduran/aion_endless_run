"""Actual movement into danger, death menu and checkpoint retry; no state setters."""
import json,runpy,sys
from pathlib import Path
from playwright.sync_api import Browser
original=Browser.close
out=Path('/workspace/work/arcade-m1/actual-retry');out.mkdir(exist_ok=True)
def close(browser,*args,**kwargs):
 page=browser.contexts[0].pages[0];canvas=page.locator('canvas')
 def d():return json.loads(canvas.get_attribute('data-campaign'))
 canvas.focus();page.keyboard.down('d')
 page.wait_for_function('()=>{const d=JSON.parse(document.querySelector("canvas").dataset.campaign);return d.menu==="dead"&&d.ui_ready}',timeout=60000)
 page.keyboard.up('d');dead=d();page.screenshot(path=str(out/'actual-death.png'))
 b=dead['buttons']['CampaignRetry'];t=dead['transform'];raw=dead.get('raw',[dead['view'][0]*t[0],dead['view'][1]*t[0]]);r=canvas.bounding_box();x=b[0]+b[2]/2;y=b[1]+b[3]/2
 page.touchscreen.tap(r['x']+(x*t[0]+t[1])/raw[0]*r['width'],r['y']+(y*t[0]+t[2])/raw[1]*r['height'])
 page.wait_for_function('()=>{const d=JSON.parse(document.querySelector("canvas").dataset.campaign);return d.state==="playing"&&!d.menu&&d.hp===3}',timeout=10000)
 restored=d();assert restored['section']==dead['section']=='shore'
 page.screenshot(path=str(out/'actual-retry.png'))
 (out/'results.json').write_text(json.dumps({'method':'Ordinary right movement into authored danger, actual death UI and actual Retry touch; no state setters.','passed':True,'dead':dead,'restored':restored},indent=2)+'\n')
 print('PASS Actual collision/death → visible Retry touch → restored live shore checkpoint',flush=True)
 return original(browser,*args,**kwargs)
Browser.close=close
sys.argv=['tests/browser_campaign.py','--url','http://127.0.0.1:8766','--evidence',str(out)]
runpy.run_path('tests/browser_campaign.py',run_name='__main__')
