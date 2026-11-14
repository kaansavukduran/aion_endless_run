"""Ordinary controls and read-only observations of the actual Web export.

No campaign state setters, save injection, invulnerability or debug advance API.
"""
import argparse,json,math,time,os,shutil
from pathlib import Path
from playwright.sync_api import sync_playwright

p=argparse.ArgumentParser();p.add_argument('--url',required=True);p.add_argument('--evidence',type=Path,required=True);p.add_argument('--route',choices=['water','terrace','roots'],default='water');p.add_argument('--play-through',action='store_true');p.add_argument('--browser',choices=['chromium','firefox'],default='chromium');p.add_argument('--offline',action='store_true');a=p.parse_args();a.evidence.mkdir(parents=True,exist_ok=True)
checks=[];errors=[];console=[]
def check(condition,message):
    assert condition,message
    checks.append(message);print('PASS',message,flush=True)

with sync_playwright() as pw:
    if a.browser=='firefox':
        browser=pw.firefox.launch(headless=False,env=dict(os.environ,MOZ_DISABLE_CONTENT_SANDBOX='1',LIBGL_ALWAYS_SOFTWARE='1'),firefox_user_prefs={'webgl.force-enabled':True,'dom.w3c_touch_events.enabled':1})
    else:
        browser=pw.chromium.launch(executable_path=shutil.which('chromium'),args=['--no-sandbox','--enable-unsafe-swiftshader'])
    context=browser.new_context(viewport={'width':1280,'height':720},locale='tr-TR',has_touch=True)
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
    if a.play_through:
        held=set();stages=[];retries=0;last_jump=0.;last_melee=0.;last_bomb=0.;started=time.monotonic();last_report=started;completed=False
        def keys(wanted):
            global held
            for k in held-set(wanted):page.keyboard.up(k)
            for k in set(wanted)-held:page.keyboard.down(k)
            held=set(wanted)
        while time.monotonic()-started<600:
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
            x,y=d['player'];onfloor=d.get('grounded',y==0);enemies=d['enemies'];targets=[e for e in enemies if abs(e['x']-x)<650]
            direction='d'
            gate=next((g for g in d['gates'] if g['closed'] and 0<=g['x']-x<100),None)
            if gate and targets:
                target=min(targets,key=lambda e:abs(e['x']-x));direction='d' if target['x']>=x else 'a'
            if section=='arena':
                direction='d' if x<1000 else ('a' if x>1080 else '')
            wanted=['f']+([direction] if direction else [])
            keys(wanted)
            # Jump when an approaching flyer, gap or low incoming projectile
            # warrants it. All decisions observe the public frame, never mutate it.
            flyer=any(e['kind'] in ['crow','drone','moth','wisp'] and abs(e['x']-x)<420 for e in targets)
            gap=any(0<p[0]-x<180 for p in d['pits'])
            danger=any(0<(b[0]-x)*(-1 if b[2]>0 else 1)<210 and abs(b[1]-(y-35))<65 for b in d.get('bullets',[]))
            if onfloor and (flyer or gap or danger or section=='arena') and now-last_jump>.85:
                page.keyboard.press('Space');last_jump=now
            near=any(abs(e['x']-x)<105 and abs(e['y']-y)<75 for e in targets)
            if near and now-last_melee>.5:page.keyboard.up('f');page.keyboard.down('f');last_melee=now
            if d['grenades']>0 and now-last_bomb>4 and len([e for e in targets if 100<e['x']-x<440])>=3:page.keyboard.press('g');last_bomb=now
            if section=='arena' and d['grenades']>0 and now-last_bomb>1.3 and x>900:page.keyboard.press('g');last_bomb=now
            # Visible contextual button, never a hidden teleport or mount setter.
            if section in ['quay','water'] and not d['mounted'] and 280<x<420:page.keyboard.press('e');page.wait_for_timeout(80)
            if now-last_report>15:print('PLAY',section,round(x),'HP',d['hp'],'boss',d['boss_hp'],'retry',retries,flush=True);last_report=now
            page.wait_for_timeout(65)
        keys([])
        (a.evidence/'playthrough.json').write_text(json.dumps({'completed':completed,'stages':stages,'retries':retries,'elapsed_seconds':time.monotonic()-started,'final':data()},indent=2)+'\n')
        check(completed,'Mission 1 is completable with actual keyboard/mouse-equivalent gameplay')
        check(a.route in data()['route'],'The chosen branch was actually recorded')
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
    browser.close()
