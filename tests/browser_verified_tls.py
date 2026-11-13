"""Forward live browser requests through the system's verified TLS trust store.
Chromium's bundled store lacks this cloud executor's proxy CA. No certificate
verification is disabled; urllib validates the actual HTTPS responses.
The PCK is delivered in16 MiB diagnostic ranges because Chromium DevTools
rejects a base64 body above100 MiB. Reassembled bytes still pass the actual
loader SHA-256 checks. Service workers are blocked only in this diagnostic driver, so this run tests
live controls, not service-worker installation/caching.
"""
import runpy,sys,urllib.request,urllib.error,os
base=os.environ.get("AION_LIVE_BASE","https://kaansavukduran.github.io/aion_endless_run/")
assert base in ["https://kaansavukduran.github.io/aion_endless_run/","https://aionendlessrun.vercel.app/"]
from playwright.sync_api import Browser
from playwright.sync_api import Page
original_on=Page.on
def trace_on(self,event,handler):
 if event=="pageerror":
  def traced(error):
   print("LIVE PAGE ERROR:",str(error),flush=True)
   handler(error)
  return original_on(self,event,traced)
 return original_on(self,event,handler)
Page.on=trace_on
original=Browser.new_context
cache={}
def create(self,*args,**kwargs):
 kwargs['service_workers']='block'
 context=original(self,*args,**kwargs)
 context.add_init_script("""(() => {
  if (typeof Worklet === 'undefined') return;
  const load = Worklet.prototype.addModule;
  Worklet.prototype.addModule = async function(url, options) {
    const response = await fetch(new URL(url, location.href).href);
    if (!response.ok) throw new Error('Live worklet fetch failed: '+response.status);
    const blob = URL.createObjectURL(new Blob([await response.arrayBuffer()], {type:'application/javascript'}));
    try { return await load.call(this, blob, options); }
    finally { URL.revokeObjectURL(blob); }
  };
 })();""")
 context.add_init_script("""(() => {
  const request = window.fetch.bind(window);
  window.fetch = async (input, options = {}) => {
    const url = new URL(typeof input === 'string' ? input : input.url, location.href).href;
    if (!new URL(url).pathname.endsWith('.pck')) return request(input, options);
    const step = 16 * 1024 * 1024;
    let position = 0, total = 0, first = null;
    const part = async () => {
      const headers = new Headers(options.headers || {});
      headers.set('Range', `bytes=${position}-${position + step - 1}`);
      const r = await request(url, {...options, headers});
      const range = r.headers.get('content-range');
      if (r.status !== 206 || !range) throw new Error('Diagnostic range delivery failed');
      total = Number(range.split('/')[1]);
      const bytes = new Uint8Array(await r.arrayBuffer());
      position += bytes.byteLength;
      return bytes;
    };
    first = await part();
    const stream = new ReadableStream({async pull(controller) {
      controller.enqueue(first || await part()); first = null;
      if (position >= total) controller.close();
    }});
    return new Response(stream, {status:200, headers:{'Content-Length':String(total),'Content-Type':'application/octet-stream'}});
  };
 })();""")
 state={'offline':False}
 old_offline=context.set_offline
 def offline(value):
  state['offline']=value
  return old_offline(value)
 context.set_offline=offline
 def forward(route):
  url=route.request.url
  if state['offline']:
   route.abort('internetdisconnected');return
  if not url.startswith(base):
   route.abort('blockedbyclient');return
  if url not in cache:
   request=urllib.request.Request(url,headers={'Accept-Encoding':'identity','User-Agent':'Aion-live-verification'})
   try:
    response=urllib.request.urlopen(request,timeout=90)
   except urllib.error.HTTPError as response_error:
    response=response_error
    print('LIVE HTTP',response.code,url,flush=True)
   with response:
    headers={k:v for k,v in response.headers.items() if k.lower() not in ['content-length','transfer-encoding','connection','content-encoding']}
    cache[url]=(response.status,headers,response.read())
  code,headers,body=cache[url]
  headers=dict(headers)
  byte_range=route.request.headers.get('range','')
  if byte_range.startswith('bytes=') and url.split('?')[0].endswith('.pck'):
   start,end=map(int,byte_range[6:].split('-'));size=len(body);end=min(end,size-1)
   body=body[start:end+1];code=206
   headers['content-range']=f'bytes {start}-{end}/{size}'
   headers['content-length']=str(len(body))
  route.fulfill(status=code,headers=headers,body=body)
 context.route('**/*',forward)
 return context
Browser.new_context=create
script=sys.argv[1]
sys.argv=[script,*sys.argv[2:]]
runpy.run_path(script,run_name='__main__')
