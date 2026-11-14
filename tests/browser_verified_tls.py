"""Forward live browser requests through the system's verified TLS trust store.
Chromium's bundled store lacks this cloud executor's proxy CA. No certificate
verification is disabled; urllib validates the actual HTTPS responses.
The PCK is delivered in16 MiB diagnostic ranges because Chromium DevTools
rejects a base64 body above100 MiB. Reassembled bytes still pass the actual
loader SHA-256 checks. Service workers are blocked only in this diagnostic driver, so this run tests
live controls, not service-worker installation/caching.
"""
import runpy,sys,urllib.request,urllib.error,urllib.parse,os,re,json,http.cookiejar
base=os.environ.get("AION_LIVE_BASE","https://kaansavukduran.github.io/aion_endless_run/")
preview=bool(re.fullmatch(r'https://aionendless-[a-z0-9]+-vegan-axolotl\.vercel\.app/',base))
assert preview or base in ["https://kaansavukduran.github.io/aion_endless_run/","https://aionendlessrun.vercel.app/"]
opener=urllib.request.build_opener()
if os.environ.get('AION_PREVIEW_ACCESS_FILE'):
 assert preview, 'Temporary preview access is restricted to this project preview'
 # A short-lived connector-created viewing capability stays outside the repo
 # and logs. Cookies remain only in this opener; protection settings are intact.
 with open(os.environ['AION_PREVIEW_ACCESS_FILE']) as access_file:
  access_url=json.load(access_file)['url']
 assert access_url.startswith(base) and '_vercel_share=' in urllib.parse.urlsplit(access_url).query
 class SameOriginRedirect(urllib.request.HTTPRedirectHandler):
  def redirect_request(self,req,fp,code,msg,headers,newurl):
   if not newurl.startswith(base):raise RuntimeError('Preview authentication redirected outside its origin')
   return super().redirect_request(req,fp,code,msg,headers,newurl)
 opener=urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()),SameOriginRedirect())
 with opener.open(access_url,timeout=60) as access_response:
  assert access_response.status==200, 'Preview viewing access failed'
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
    response=opener.open(request,timeout=90)
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
