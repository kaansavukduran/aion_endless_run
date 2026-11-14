"""Ordinary controls and read-only observations of the actual Web export.

No campaign state setters, save injection, invulnerability or debug advance API.
"""
import argparse,json,math,time,os,shutil
from pathlib import Path
from playwright.sync_api import sync_playwright

p=argparse.ArgumentParser();p.add_argument('--url',required=True);p.add_argument('--evidence',type=Path,required=True);p.add_argument('--route',choices=['water','terrace','roots'],default='water');p.add_argument('--play-through',action='store_true');p.add_argument('--browser',choices=['chromium','firefox'],default='chromium');p.add_argument('--offline',action='store_true');p.add_argument('--expanded-rescue',action='store_true');p.add_argument('--rescue-only',action='store_true');p.add_argument('--record-video',action='store_true');p.add_argument('--profile',action='store_true');p.add_argument('--debug-port',type=int);p.add_argument('--headed',action='store_true');p.add_argument('--angle-gl',action='store_true');p.add_argument('--steering-file',type=Path);a=p.parse_args();a.evidence.mkdir(parents=True,exist_ok=True)
checks=[];errors=[];console=[]
def check(condition,message):
    assert condition,message
    checks.append(message);print('PASS',message,flush=True)

with sync_playwright() as pw:
    if a.browser=='firefox':
        browser=pw.firefox.launch(headless=False,env=dict(os.environ,MOZ_DISABLE_CONTENT_SANDBOX='1',LIBGL_ALWAYS_SOFTWARE='1'),firefox_user_prefs={'webgl.force-enabled':True,'dom.w3c_touch_events.enabled':1})
    else:
        browser=pw.chromium.launch(executable_path=shutil.which('chromium'),headless=not a.headed,args=['--no-sandbox','--enable-unsafe-swiftshader']+(['--remote-debugging-port='+str(a.debug_port)] if a.debug_port else [])+(['--use-angle=gl'] if a.angle_gl else []))
    context=browser.new_context(viewport={'width':1280,'height':720},locale='tr-TR',has_touch=True,**({'record_video_dir':str(a.evidence/'video'),'record_video_size':{'width':1280,'height':720}} if a.record_video else {}))
    page=context.new_page();page.on('pageerror',lambda e:errors.append(str(e)))
    def message(m):
        console.append({'time':time.monotonic(),'type':m.type,'text':m.text})
        if 'ERROR:' in m.text or 'SCRIPT ERROR' in m.text:errors.append(m.text)
    page.on('console',message)
    page.goto(a.url,timeout=120000);page.wait_for_selector('canvas[data-state="ready"][data-ui-ready="true"]',timeout=120000)
    canvas=page.locator('canvas')
    initial=canvas.evaluate('c=>({...c.dataset})');main_button=next(b for b in json.loads(initial['ui']) if b['name']=='StartCampaign');tr=json.loads(initial['screenTransform']);rect=canvas.bounding_box()
    xx,yy=main_button['x']+main_button['w']/2,main_button['y']+main_button['h']/2
    page.touchscreen.tap(rect['x']+(tr[0]*xx+tr[2]*yy+tr[4])/float(initial['rawWidth'])*rect['width'],rect['y']+(tr[1]*xx+tr[3]*yy+tr[5])/float(initial['rawHeight'])*rect['height'])
    page.wait_for_function('document.querySelector("canvas").hasAttribute("data-campaign")',timeout=45000)
    def data():return json.loads(canvas.get_attribute('data-campaign'))
    import sys
    default_hook=sys.excepthook
    def failure_hook(kind,value,tb):
        try:
            (a.evidence/'failure.json').write_text(json.dumps({'error':str(value),'state':data(),'console_errors':errors},indent=2)+'\n');page.screenshot(path=str(a.evidence/'failure.png'))
        except Exception:pass
        default_hook(kind,value,tb)
    sys.excepthook=failure_hook
    def xy(x,y):
        d=data();r=canvas.bounding_box();tr=d['transform'];raw=d.get('raw',[d['view'][0]*tr[0],d['view'][1]*tr[0]])
        return r['x']+(x*tr[0]+tr[1])/raw[0]*r['width'],r['y']+(y*tr[0]+tr[2])/raw[1]*r['height']
    def button(name=None,text=None,expect_menu=None):
        page.wait_for_function('([name,text,expected])=>{const s=document.querySelector("canvas").dataset.campaign;if(!s)return false;const d=JSON.parse(s);return (expected && d.menu!==expected) || (d.ui_ready && Object.entries(d.buttons).some(([k,v])=>name ? k===name : v[4]===text))}',arg=[name,text,expect_menu],timeout=10000)
        if name:
            try:page.wait_for_function('([name,expected])=>{const c=document.querySelector("canvas"),d=c.dataset.campaign&&JSON.parse(c.dataset.campaign);return d && (d.buttons[name] || (expected && d.menu!==expected))}',arg=[name,expect_menu],timeout=10000)
            except Exception:
                (a.evidence/'button-failure.json').write_text(json.dumps({'wanted':name,'state':data(),'errors':errors},indent=2)+'\n');page.screenshot(path=str(a.evidence/'button-failure.png'));raise
        if expect_menu and data()['menu']!=expect_menu:return False
        d=data();generation=d.get('ui_generation',0);key=next(k for k,v in d['buttons'].items() if (k==name if name else v[4]==text));v=d['buttons'][key];page.touchscreen.tap(*xy(v[0]+v[2]/2,v[1]+v[3]/2))
        page.wait_for_function('(old)=>{const s=document.querySelector("canvas").dataset.campaign;return !s || JSON.parse(s).ui_generation!==old}',arg=generation,timeout=10000)
        page.wait_for_timeout(120)
    def fit():
        d=data()
        for name,b in d['buttons'].items():check(b[0]>=0 and b[1]>=0 and b[0]+b[2]<=d['view'][0]+1 and b[1]+b[3]<=d['view'][1]+1,'Visible reachable menu action: '+name)
    fit();page.screenshot(path=str(a.evidence/'briefing.png'));button('CampaignBegin');fit()
    while data()['menu']=='help':button('CampaignGo')
    canvas.focus();page.wait_for_timeout(200)
    check(data()['state']=='playing','Main menu → Arcade → mission → play through normal buttons')
    p0=data()['player'][0];page.keyboard.down('d');page.wait_for_function('(x)=>JSON.parse(document.querySelector("canvas").dataset.campaign).player[0]>x+80',arg=p0,timeout=10000);page.keyboard.up('d');page.wait_for_timeout(200);p1=data()['player'][0]
    check(p1>p0+75,'D moves the player right; this is not automatic scrolling')
    page.keyboard.down('a');page.wait_for_function('(x)=>JSON.parse(document.querySelector("canvas").dataset.campaign).player[0]<x-35',arg=p1,timeout=10000);page.keyboard.up('a');page.wait_for_timeout(150);check(data()['player'][0]<p1-30 and data()['facing']==-1,'A moves and faces left')
    page.keyboard.down('d');page.wait_for_function('JSON.parse(document.querySelector("canvas").dataset.campaign).facing===1',timeout=10000);page.keyboard.up('d');page.keyboard.down('f');page.wait_for_function('JSON.parse(document.querySelector("canvas").dataset.campaign).shots>=2',timeout=10000);page.keyboard.up('f');page.wait_for_timeout(150);check(data()['shots']>=2,'Held fire produces real, spaced gunshots')
    count=data()['grenades'];page.keyboard.press('g');page.wait_for_timeout(200);check(data()['grenades']==count-1,'G spends exactly one energy grenade')
    before=data();r=before['actions']['attack'];page.touchscreen.tap(*xy(r[0]+r[2]/2,r[1]+r[3]/2))
    page.wait_for_function('(shots)=>{const d=JSON.parse(document.querySelector("canvas").dataset.campaign);return d.shots>shots || d.melee>0}',arg=before['shots'],timeout=10000)
    check(True,'Actual right Fire touch reaches a gunshot or contextual close strike')
    page.wait_for_timeout(600);before=data();r=before['actions']['grenade'];page.touchscreen.tap(*xy(r[0]+r[2]/2,r[1]+r[3]/2))
    page.wait_for_function('(count)=>JSON.parse(document.querySelector("canvas").dataset.campaign).grenades===count-1',arg=before['grenades'],timeout=10000)
    check(True,'Actual right Grenade touch spends one bomb without a second underlying command')
    page.keyboard.press('Escape');page.wait_for_timeout(200);frozen=data();page.wait_for_timeout(350);check(data()['time']==frozen['time'],'Pause freezes the active mission')
    page.set_viewport_size({'width':393,'height':873});page.wait_for_timeout(700);fit();check(data()['section']==frozen['section'] and data()['score']==frozen['score'],'Portrait rotation preserves checkpoint and score');page.screenshot(path=str(a.evidence/'portrait-paused.png'))
    button(text='Devam et');page.wait_for_timeout(200);d=data();check(len(d['actions'])==3 and 'grenade' in d['actions'] and 'stick' in d,'Approved fixed left stick and three right actions exist')
    for name,r in d['actions'].items():check(r[0]>=0 and r[1]>=0 and r[0]+r[2]<=d['view'][0] and r[1]+r[3]<=d['view'][1],'Touch target is inside portrait viewport: '+name)
    if a.browser=='chromium':
        cdp=context.new_cdp_session(page)
        def touch(kind,points):cdp.send('Input.dispatchTouchEvent',{'type':kind,'touchPoints':[{'id':i,'x':x,'y':y} for i,x,y in points]})
        s=d['stick'];jx,jy=xy(s[0]+s[2]*.84,s[1]+s[3]*.5);j=d['actions']['jump'];bx,by=xy(j[0]+j[2]/2,j[1]+j[3]/2)
        x0=d['player'][0];touch('touchStart',[(1,jx,jy)]);page.wait_for_timeout(250);touch('touchStart',[(1,jx,jy),(2,bx,by)]);page.wait_for_function('(x)=>{const d=JSON.parse(document.querySelector("canvas").dataset.campaign);return d.player[0]>x+35 && d.player[1]<-15}',arg=x0,timeout=10000);check(data()['player'][0]>x0+35 and data()['player'][1]<-15,'Real multitouch moves and jumps simultaneously');touch('touchCancel',[]);page.wait_for_function('Math.abs(JSON.parse(document.querySelector("canvas").dataset.campaign).velocity[0])<1',timeout=10000);x0=data()['player'][0];page.wait_for_timeout(250);check(abs(data()['player'][0]-x0)<1,'Touch cancellation releases the joystick without a stuck direction')
    else:
        r=d['actions']['jump'];page.touchscreen.tap(*xy(r[0]+r[2]/2,r[1]+r[3]/2));page.wait_for_function('JSON.parse(document.querySelector("canvas").dataset.campaign).player[1]<-10',timeout=10000);check(True,'Firefox actual touch reaches the same jump action; CDP multitouch is Chromium-only')
    page.set_viewport_size({'width':1280,'height':720});page.wait_for_timeout(700);page.screenshot(path=str(a.evidence/'landscape-playing.png'));canvas.focus()
    if a.play_through or a.rescue_only:
        held=set();stages=[];retries=0;last_jump=0.;last_melee=0.;last_bomb=0.;started=time.monotonic();last_report=started;completed=False;rescues_tested=[];settle_until=0.;steering_id=None
        def keys(wanted):
            global held
            for k in held-set(wanted):page.keyboard.up(k)
            for k in set(wanted)-held:page.keyboard.down(k)
            held=set(wanted)
        while time.monotonic()-started<1000:
            d=data();now=time.monotonic();state=d['state'];section=d['section']
            if d['menu'] and not d.get('ui_ready',True):keys([]);page.wait_for_timeout(50);continue
            if section not in stages:stages.append(section);page.screenshot(path=str(a.evidence/(section+'.png')));print('STAGE',section,'HP',d['hp'],'score',d['score'],flush=True)
            if state=='complete':
                keys([]);completed=True
                while data()['menu']=='outro':button(text='Devam')
                page.screenshot(path=str(a.evidence/'mission-complete.png'));break
            if d['menu']:
                keys([])
                if d['menu']=='dead':retries+=1;button('CampaignRetry',expect_menu='dead')
                elif d['menu']=='fork_one':button('Route_water' if a.route=='water' else 'Route_canopy')
                elif d['menu']=='fork_two':button('Route_'+a.route)
                elif d['menu']=='boss':
                    (a.evidence/'boss-entry-state.json').write_text(json.dumps(d,indent=2)+'\n')
                    canvas.focus();page.keyboard.press('Enter');page.wait_for_timeout(350)
                elif d['menu']=='paused':button(text='Devam et')
                page.wait_for_timeout(120);canvas.focus();continue
            if state!='playing':keys([]);page.wait_for_timeout(80);continue
            if a.steering_file and a.steering_file.exists():
                command=json.loads(a.steering_file.read_text())
                if command.get('id')!=steering_id:
                    steering_id=command.get('id');keys(command.get('keys',[]))
                    if command.get('jump'):page.keyboard.press('Space')
                    page.wait_for_timeout(min(5000,max(0,int(command.get('milliseconds',300)))));keys([])
                    (a.evidence/('guided-input-'+str(steering_id)+'.json')).write_text(json.dumps({'command':command,'state_after':data()},indent=2)+'\n')
                    continue
            x,y=d['player'];onfloor=d.get('grounded',y==0);targets=[e for e in d['enemies'] if abs(e['x']-x)<680]
            target=min(targets,key=lambda e:abs(e['x']-x)) if targets else None
            direction='d';wanted=['f']
            closed=any(g['closed'] and 0<=g['x']-x<180 for g in d['gates'])
            if target and (closed or abs(target['x']-x)<320):
                facing=1 if target['x']>=x else -1;direction='d' if facing==1 else 'a'
                if target['y']<-65 and abs(target['x']-x)<280 and d['facing']==facing:direction=''
            if section=='arena':
                desired=float(d.get('boss_x',1400))-210
                direction='d' if x<desired-35 else ('a' if x>desired+35 else ('d' if d['facing']<0 else ''))
                if target and abs(target['x']-x)<450:
                    facing=1 if target['x']>=x else -1;direction='' if d['facing']==facing else ('d' if facing==1 else 'a')
                if d.get('boss_warning',0)>0 and abs(x-d.get('boss_beam_x',-999))<95:direction='a'
            if target and target['y']<-65 and abs((y-46)-(target['y']-30))>34:wanted=[]
            if direction:wanted.append(direction)
            keys(wanted)
            flyer=target and target['y']<-65 and abs(target['x']-x)<450
            gap=any(0<p[0]-x<150 for p in d['pits'])
            object_gate=not targets and any(o['kind']=='gate' and not o['active'] and 0<o['x']-x<110 for o in d.get('objects',[]))
            danger=any(math.hypot(b[0]-x,b[1]-(y-37))<100 for b in d.get('bullets',[]))
            if onfloor and (flyer or gap or danger or object_gate) and now-last_jump>.85:
                page.keyboard.press('Space');last_jump=now
            near=any(abs(e['x']-x)<95 and abs(e['y']-y)<75 for e in targets)
            if near and now-last_melee>.35:page.keyboard.up('f');page.keyboard.down('f');last_melee=now
            if d['grenades']>0 and now-last_bomb>3 and (len([e for e in targets if 100<e['x']-x<440])>=3 or (target and target['hp']>1 and abs(target['x']-x)<400) or (section=='arena' and abs(float(d.get('boss_x',1400))-x)<430)):
                page.keyboard.press('g');last_bomb=now
            if a.expanded_rescue:
                # Fresh touch Fire near a captive, never a state setter or save injection.
                captive=next((n for n in d.get('npcs',[]) if not n['freed'] and not n['secret'] and 15<(n['x']-x)*d['facing']<95 and abs(n['y']-y)<20 and d.get('rescue_candidate',n['id'])==n['id']),None)
                if captive and onfloor and not any(abs(e['x']-x)<170 for e in targets):
                    keys([]);page.wait_for_timeout(150);fresh=data()
                    if fresh.get('rescue_candidate',captive['id'])!=captive['id']:continue
                    r=fresh['actions']['attack'];anchor=fresh['player'];shot_count=fresh['shots']
                    page.touchscreen.tap(*xy(r[0]+r[2]/2,r[1]+r[3]/2))
                    page.wait_for_function('id=>{const d=JSON.parse(document.querySelector("canvas").dataset.campaign);return d.rescue_time>0 || d.rescued.includes(id)}',arg=captive['id'],timeout=15000)
                    page.wait_for_timeout(160);mid=data()
                    check(mid['shots']==shot_count,'Contextual touch Fire cuts ropes without firing a shot')
                    check(abs(mid['player'][0]-anchor[0])<1,'Actual cut keeps the physical actor in place')
                    page.screenshot(path=str(a.evidence/('rescue-'+str(len(rescues_tested))+'-cut.png')))
                    page.wait_for_function('id=>JSON.parse(document.querySelector("canvas").dataset.campaign).awarded[id+":gift"]===true',arg=captive['id'],timeout=15000)
                    done=data();check(captive['id'] in done['rescued'],'Knife contact actually frees that captive')
                    saved=page.evaluate("JSON.parse(localStorage.getItem('aion.campaign.v1'))")
                    check(saved['awarded'].get(captive['id']+':gift') and captive['id'] in saved['rescued'],'Actual rescue and handover reach persistent browser storage')
                    page.screenshot(path=str(a.evidence/('rescue-'+str(len(rescues_tested))+'-thanks.png')))
                    rescues_tested.append({'id':captive['id'],'gift':captive['gift'],'weapon_after':done['weapon'],'ammo_after':done['ammunition']})
                    if a.profile and not (a.evidence/'performance.json').exists():
                        timings=page.evaluate("""async()=>{
                            const times=[];let previous=performance.now(),start=previous;
                            await new Promise(resolve=>{function frame(t){times.push(t-previous);previous=t;if(t-start<6000)requestAnimationFrame(frame);else resolve()}requestAnimationFrame(frame)});
                            const gl=document.querySelector('canvas').getContext('webgl2'),debug=gl&&gl.getExtension('WEBGL_debug_renderer_info');
                            return {interval_ms:times.slice(2),renderer:debug?gl.getParameter(debug.UNMASKED_RENDERER_WEBGL):'unavailable',viewport:[innerWidth,innerHeight],dpr:devicePixelRatio};
                        }""")
                        samples=sorted(timings.pop('interval_ms'));timings.update({'scope':'Actual active mission, standing after a rescue; motion enabled. Not a physical phone or peak-load certification.','samples':len(samples),'mean_fps':1000/(sum(samples)/len(samples)),'median_frame_ms':samples[len(samples)//2],'p95_frame_ms':samples[int(len(samples)*.95)],'frames_over_50ms':sum(v>50 for v in samples),'build':page.evaluate("fetch('build.json').then(r=>r.json()).then(v=>v.build)")})
                        (a.evidence/'performance.json').write_text(json.dumps(timings,indent=2)+'\n')
                    if a.rescue_only:break
                    continue
            # Visible contextual button, never a hidden teleport or mount setter.
            if section in ['quay','water'] and not d['mounted'] and 280<x<420:page.keyboard.press('e');page.wait_for_timeout(80)
            if now-last_report>15:
                (a.evidence/'latest-state.json').write_text(json.dumps(d,indent=2)+'\n')
                if a.browser=='chromium':
                    sample={'elapsed':now-started,'heap':cdp.send('Runtime.getHeapUsage'),'dom':cdp.send('Memory.getDOMCounters')}
                    with (a.evidence/'browser-memory.jsonl').open('a') as log:log.write(json.dumps(sample)+'\n')
                print('PLAY',section,round(x),'y',round(y),'HP',d['hp'],'boss',d['boss_hp'],'retry',retries,flush=True);last_report=now
            page.wait_for_timeout(65)
        keys([])
        (a.evidence/'playthrough.json').write_text(json.dumps({'completed':completed,'stages':stages,'retries':retries,'elapsed_seconds':time.monotonic()-started,'rescues_tested':rescues_tested,'final':data()},indent=2)+'\n')
        if a.rescue_only:check(bool(rescues_tested),'An actual captive was reached, cut free and rewarded through ordinary controls')
        else:
            check(completed,'Mission 1 is completable with actual keyboard/mouse-equivalent gameplay')
            check(a.route in data()['route'],'The chosen branch was actually recorded')
        if not a.rescue_only:
            saved=page.evaluate("JSON.parse(localStorage.getItem('aion.campaign.v1'))")
            check(saved['completed'] and saved['best_score']>=data()['score'],'Actual completed checkpoint and campaign best are persisted')
            button(text='Ana menü');page.wait_for_selector('canvas[data-state="ready"][data-ui-ready="true"]')
            check(canvas.get_attribute('data-campaign') is None,'Return to the original runner clears stale campaign observations')
            check(page.evaluate("JSON.parse(localStorage.getItem('aion.campaign.v1')).completed"),'Returning to main preserves the completed campaign')
            # Re-enter via the real semantic counterpart of the actual Godot button.
            page.get_by_role('button',name='Arcade',exact=True).focus();page.keyboard.press('Enter');page.wait_for_function('document.querySelector("canvas").hasAttribute("data-campaign")')
    if a.offline:
        if data()['state']=='playing':canvas.focus();page.keyboard.press('Escape');page.wait_for_function('JSON.parse(document.querySelector("canvas").dataset.campaign).menu==="paused"')
        before=page.evaluate("JSON.parse(localStorage.getItem('aion.campaign.v1'))")
        page.evaluate('navigator.serviceWorker.ready.then(()=>true)');context.set_offline(True);page.reload(timeout=120000);page.wait_for_selector('canvas[data-state="ready"][data-ui-ready="true"]',timeout=120000)
        page.get_by_role('button',name='Arcade',exact=True).focus();page.keyboard.press('Enter');page.wait_for_function('document.querySelector("canvas").hasAttribute("data-campaign")')
        after=page.evaluate("JSON.parse(localStorage.getItem('aion.campaign.v1'))")
        check(after['checkpoint']==before['checkpoint'] and after['score']==before['score'],'Offline reload starts the real game and preserves its separate campaign checkpoint')
        if not before['completed']:
            button('CampaignContinue')
            while data()['menu']=='help':button('CampaignGo')
            check(data()['score']==before['score'] and data()['section']==before['checkpoint'],'Actual Continue resumes saved checkpoint offline')
        page.screenshot(path=str(a.evidence/'offline-restored.png'));context.set_offline(False)
    (a.evidence/'console.json').write_text(json.dumps(console,indent=2)+'\n')
    check(not errors,'No browser or Godot script errors during the actual flow: '+str(errors[:3]))
    (a.evidence/'results.json').write_text(json.dumps({'checks':checks,'errors':errors,'build':page.evaluate("fetch('build.json').then(r=>r.json()).then(x=>x.build)"),'final':data()},indent=2)+'\n')
    context.close();browser.close()
