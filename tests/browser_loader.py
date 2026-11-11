"""Real PCK boot, packet faults, cache repair and mobile touch; no game setters."""
import argparse,hashlib,http.server,json,os,threading
from pathlib import Path
from playwright.sync_api import sync_playwright
p=argparse.ArgumentParser();p.add_argument('--browser',choices=['chromium','firefox'],default='chromium');p.add_argument('--export',type=Path,default=Path('build/web'));p.add_argument('--evidence',type=Path,required=True);a=p.parse_args();a.evidence.mkdir(parents=True,exist_ok=True)
root=a.export.resolve();meta=json.loads((root/'build.json').read_text());pack_name=next(n for n in meta['assets'] if n.endswith('.pck'));pack=(root/pack_name).read_bytes();faults=[];requests=[];results=[];dialogs=[];stale_entry=[False]
class Handler(http.server.SimpleHTTPRequestHandler):
 def __init__(self,*args,**kwargs):super().__init__(*args,directory=str(root),**kwargs)
 def log_message(self,*args):pass
 def end_headers(self):self.send_header('Cache-Control','no-cache');super().end_headers()
 def do_GET(self):
  path=self.path.split('?')[0].lstrip('/');requests.append(path)
  if not path and stale_entry[0]:
   stale_entry[0]=False;body=(root/'index.html').read_bytes().replace(meta['build'].encode(),b'0000000000000000')
   self.send_response(200);self.send_header('Content-Type','text/html');self.send_header('Content-Length',str(len(body)));self.end_headers();self.wfile.write(body);return
  if path==pack_name and faults:
   kind=faults.pop(0)
   if kind=='html':body=b'<html>stale deployment</html>';mime='text/html';status=200
   elif kind=='short':body=pack[:1024];mime='application/octet-stream';status=200
   elif kind=='partial':body=pack[:1024];mime='application/octet-stream';status=206
   elif kind=='hash':body=pack[:-1]+bytes([pack[-1]^1]);mime='application/octet-stream';status=200
   self.send_response(status);self.send_header('Content-Type',mime);self.send_header('Content-Length',str(len(body)));self.end_headers();self.wfile.write(body);return
  super().do_GET()
server=http.server.ThreadingHTTPServer(('127.0.0.1',0),Handler);threading.Thread(target=server.serve_forever,daemon=True).start();url='http://127.0.0.1:'+str(server.server_port)+'/'
def check(value,message):
 assert value,message
 results.append(message);print('PASS',message,flush=True)
with sync_playwright() as pw:
 if a.browser=='firefox':
  env=dict(os.environ,DISPLAY=os.environ.get('DISPLAY',':99'),XDG_CACHE_HOME=str(a.evidence.resolve()/'firefox-cache'),XDG_CONFIG_HOME=str(a.evidence.resolve()/'firefox-config'),MOZ_DISABLE_CONTENT_SANDBOX='1',LIBGL_ALWAYS_SOFTWARE='1')
  browser=pw.firefox.launch(headless=False,env=env,firefox_user_prefs={'webgl.force-enabled':True,'dom.w3c_touch_events.enabled':1})
  mobile={'user_agent':'Mozilla/5.0 (Android 15; Mobile; rv:145.0) Gecko/145.0 Firefox/145.0'}
 else:browser=pw.chromium.launch(args=['--no-sandbox','--enable-unsafe-swiftshader']);mobile={'is_mobile':True}
 def context(workers='block',portrait=False):
  ctx=browser.new_context(viewport={'width':393,'height':873} if portrait else {'width':850,'height':390},has_touch=True,device_scale_factor=2,locale='tr-TR',service_workers=workers,**mobile)
  page=ctx.new_page();page.on('dialog',lambda d:(dialogs.append(d.message),d.dismiss()));return ctx,page
 def ready(page):page.wait_for_selector('canvas[data-state="ready"][data-ui-ready="true"]',timeout=120000)
 def data(page):return page.locator('canvas').evaluate('c=>({...c.dataset})')
 def tap_text(page,text):
  v=data(page);b=next(b for b in json.loads(v['ui']) if b['text']==text);t=json.loads(v['screenTransform']);r=page.locator('canvas').bounding_box();x=b['x']+b['w']/2;y=b['y']+b['h']/2;page.touchscreen.tap(r['x']+(t[0]*x+t[2]*y+t[4])/float(v['rawWidth'])*r['width'],r['y']+(t[1]*x+t[3]*y+t[5])/float(v['rawHeight'])*r['height'])
 def tap_start(page):
  tap_text(page,'Koşuya başla');page.wait_for_selector('canvas[data-state="running"]')
 # A stale page can reference files removed by a newer deployment.
 stale_entry[0]=True;ctx,page=context();page.goto(url);ready(page)
 check(page.evaluate('AION_BUILD.build')==meta['build'],'A stale page with missing engine files recovers to the current manifest')
 check(page.url.count('build=')==1 and 'aion-recovery' not in page.url,'Recovery finishes without a redirect loop')
 ctx.close()
 # Same alert as the reported failure used to reach Godot. The guard retries instead.
 faults[:]=['html','short'];ctx,page=context();page.goto(url);ready(page)
 check(page.evaluate('AION_BOOT.state.attempts')==3,'HTML and truncated PCK responses are rejected, then the real game starts')
 check(not dialogs,'No native missing-PCK alert reaches the mobile user')
 tap_start(page);check(data(page)['state']=='running','Landscape phone touch starts the actual game')
 page.screenshot(path=str(a.evidence/'landscape-game.png'));ctx.close()
 faults[:]=['hash'];ctx,page=context(portrait=True);page.goto(url);ready(page)
 check(page.evaluate('AION_BOOT.state.attempts')==2,'A same-size corrupt PCK fails SHA-256 validation and is downloaded again')
 tap_start(page);check(data(page)['devicePortrait']=='true' and data(page)['orientation']=='landscape','Portrait phone touch works with the landscape game transform')
 page.screenshot(path=str(a.evidence/'portrait-landscape-game.png'));ctx.close()
 faults[:]=['partial','html','short'];ctx,page=context();before=requests.count(next(n for n in meta['assets'] if n.endswith('.wasm')));page.goto(url);page.wait_for_selector('#aion-retry',timeout=30000)
 check(page.locator('#status-notice').inner_text().startswith('Oyun dosyası tam yüklenemedi'),'Persistent download failure shows a Turkish retry screen')
 check(requests.count(next(n for n in meta['assets'] if n.endswith('.wasm')))==before,'An invalid pack never starts or allocates the engine')
 page.screenshot(path=str(a.evidence/'retry-screen.png'));page.locator('#aion-retry').click();ready(page);check(True,'The normal Retry button recovers once the connection returns');ctx.close()
 # Real ServiceWorker/CacheStorage repair: save a score through ordinary input first.
 ctx,page=context(workers='allow');page.goto(url);ready(page);page.evaluate('navigator.serviceWorker.ready.then(()=>true)');page.reload();ready(page)
 tap_start(page);page.wait_for_timeout(1000);tap_text(page,'Duraklat');page.wait_for_selector('canvas[data-state="paused"]');saved=int(data(page)['score']);page.wait_for_timeout(2300)
 page.evaluate('''async ({build,pack})=>{const c=await caches.open('aion-offline-'+build);await c.put(new URL(pack,location.href).href,new Response('<html>bad cached pack</html>',{headers:{'Content-Type':'text/html'}}));}''',{'build':meta['build'],'pack':pack_name})
 page.reload();ready(page)
 check(page.evaluate('AION_BOOT.state.attempts')>=2,'A poisoned real offline cache is repaired automatically')
 check(int(data(page)['best'])>=saved>0,'Repair preserves the score in actual IndexedDB; no data clearing')
 page.evaluate('navigator.serviceWorker.ready.then(()=>true)');ctx.set_offline(True);page.reload();ready(page)
 check(int(data(page)['best'])>=saved,'The verified repaired game really reloads offline with its record')
 check(not dialogs,'No missing-PCK dialog in retry, cache repair or offline boot')
 page.screenshot(path=str(a.evidence/'repaired-offline.png'));ctx.close();browser.close()
server.shutdown();(a.evidence/'loader-results.json').write_text(json.dumps(results,ensure_ascii=False,indent=2)+'\n');print(len(results),'loader checks passed')
