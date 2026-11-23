"""Six Mission 1 heroes through ordinary browser input and passive observations.

One fresh context at a time. No game-state setters, storage injection, debug
advance, teleportation, immunity, or synthetic simulation time. Run only after
coordinating browser capacity with the other QA worker.

Videos are original canvas.captureStream(60)/MediaRecorder WebM streams. They
are never transcoded, retimed, or padded to pretend that the renderer achieved
60 fps. Captured VideoFrame timestamps and optional ffprobe timestamps report
actual cadence separately from the requested capture rate and browser rAF.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

from playwright.sync_api import sync_playwright

HEROES = ("aion", "sheep", "rabbit", "eren", "armadillo", "frog")
ROOT = Path(__file__).resolve().parents[1]

# Observation buffers and a virtual input device belong to this test, not to
# the Godot application. None of these functions writes application state.
OBSERVER = """(() => {
  window.sixProbe = {packets: [], raf: [], events: [], origin: performance.timeOrigin};
  for (const type of ['keydown','keyup','pointermove','pointerdown','pointerup','touchstart','touchend','touchcancel']) {
    window.addEventListener(type, e => sixProbe.events.push({type, timestamp_ms:e.timeStamp,
      observed_ms:performance.now(),trusted:e.isTrusted,key:e.key || null,x:e.clientX,y:e.clientY}), {capture:true,passive:true});
  }
  let attached = false;
  const attach = () => {
    const canvas = document.querySelector('canvas');
    if (!canvas || attached) return;
    attached = true;
    new MutationObserver(records => {
      if (!records.some(r => ['data-campaign','data-front'].includes(r.attributeName))) return;
      const p = {wall_ms: performance.now(), utc_ms: performance.timeOrigin + performance.now()};
      if (canvas.dataset.campaign) p.campaign = JSON.parse(canvas.dataset.campaign);
      if (canvas.dataset.front) p.front = JSON.parse(canvas.dataset.front);
      sixProbe.packets.push(p);
    }).observe(canvas, {attributes: true});
  };
  new MutationObserver(attach).observe(document, {childList: true, subtree: true});
  const frame = t => { sixProbe.raf.push(t); requestAnimationFrame(frame); };
  requestAnimationFrame(frame);
  const pad = {id:'Xbox Controller (QA virtual input)', index:0, connected:false,
    mapping:'standard', timestamp:0, axes:[0,0,0,0],
    buttons:Array.from({length:17}, () => ({pressed:false,touched:false,value:0}))};
  Object.defineProperty(navigator, 'getGamepads', {value:() => pad.connected ? [pad] : []});
  window.sixPad = (axes, buttons, connected=true) => {
    const changed = pad.connected !== connected;
    pad.connected = connected; pad.axes = axes;
    pad.buttons = pad.buttons.map((_, i) => ({pressed:buttons.includes(i),touched:buttons.includes(i),value:buttons.includes(i)?1:0}));
    pad.timestamp = performance.now();
    if (changed) {
      const event = new Event(connected ? 'gamepadconnected' : 'gamepaddisconnected');
      Object.defineProperty(event, 'gamepad', {value:pad}); window.dispatchEvent(event);
    }
  };
})();"""

START_VIDEO = """() => {
  const canvas = document.querySelector('canvas');
  if (!canvas.captureStream || !window.MediaRecorder) return {supported:false};
  const stream = canvas.captureStream(60);
  const mimeType = ['video/webm;codecs=vp9','video/webm;codecs=vp8','video/webm'].find(t => MediaRecorder.isTypeSupported(t));
  if (!mimeType) return {supported:false};
  const recorder = new MediaRecorder(stream, {mimeType, videoBitsPerSecond:8000000});
  const capture = window.sixCapture = {stream, recorder, chunks:[], frames:[], mimeType,
    started:performance.now(), target_fps:60, track:stream.getVideoTracks()[0].getSettings()};
  recorder.ondataavailable = event => { if(event.data.size) capture.chunks.push(event.data); };
  if ('MediaStreamTrackProcessor' in window) {
    capture.sampleTrack = stream.getVideoTracks()[0].clone();
    capture.reader = new MediaStreamTrackProcessor({track:capture.sampleTrack}).readable.getReader();
    (async () => {
      try { for (;;) { const item = await capture.reader.read(); if(item.done) break;
        capture.frames.push({timestamp_us:item.value.timestamp, wall_ms:performance.now()}); item.value.close();
      } } catch (_) { /* The reader is cancelled when recording ends. */ }
    })();
  }
  recorder.start(250);
  return {supported:true,mimeType,requested_fps:60,track:capture.track,frame_timestamps:!!capture.reader};
}"""

STOP_VIDEO = """async () => {
  const c = window.sixCapture; if(!c) return {supported:false};
  await new Promise(resolve => { c.recorder.onstop = resolve; c.recorder.stop(); });
  if(c.reader) await c.reader.cancel();
  if(c.sampleTrack) c.sampleTrack.stop();
  c.stream.getTracks().forEach(track => track.stop());
  const blob = new Blob(c.chunks, {type:c.mimeType});
  const url = URL.createObjectURL(blob), link = document.createElement('a');
  link.href = url; link.download = 'normal-input.webm'; link.style.display='none';
  document.body.append(link); link.click(); link.remove();
  setTimeout(() => URL.revokeObjectURL(url), 10000);
  return {supported:true,requested_fps:60,track:c.track,frames:c.frames,
    started_ms:c.started,stopped_ms:performance.now(),mimeType:c.mimeType,bytes:blob.size,
    retimed:false,audio:false};
}"""


class PoseRegistry:
    """Source evidence lookup; expected action is supplied by the input test."""
    def __init__(self):
        self.base = json.loads((ROOT / "assets/M1-HEROES-PROVENANCE.json").read_text())
        self.extra = json.loads((ROOT / "assets/M1-HERO-ACTIONS.json").read_text())
        self.mission = json.loads((ROOT / "assets/MISSION-HEROES-PROVENANCE.json").read_text())
        self.source_hashes={path:hashlib.sha256((ROOT/path).read_bytes()).hexdigest() for path in ('assets/M1-HEROES-PROVENANCE.json','assets/M1-HERO-ACTIONS.json','assets/MISSION-HEROES-PROVENANCE.json','scripts/m1_hero_action_art.gd','scripts/mission_hero_art.gd','assets/M1-HELD-WEAPONS.json','scripts/m1_combat_art.gd','scripts/campaign_view.gd','scripts/mission_frog_tongue_art.gd')}

    def cels(self, hero, action):
        if hero in ("armadillo", "frog"):
            clip = self.mission['clips'][action]
            override = self.mission.get('runtime_overrides', {}).get(hero, {}).get(action, {})
            atlas = override.get('atlas',clip.get('atlas',hero) if clip.get('hero',hero)==hero else hero)
            row = override.get('row', clip['row'])
            order = override.get('order', list(range(clip['frames'])))
            return {('mission-hero-' + atlas, row, frame) for frame in order}
        if action in ('walk_back', 'crouch_walk_back', 'grenade_throw', 'crouch_grenade_throw'):
            result = set()
            for frame in range(self.extra['playback'][action]['frames']):
                key = hero + ('_crouch' if action in ('crouch_walk_back','crouch_grenade_throw') else '_empty' if action == 'grenade_throw' and frame in (1,2) else '')
                row = (1 if action == 'crouch_grenade_throw' else 0) if '_crouch' in key else ('walk_back','crouch_walk_back','grenade_throw').index(action)
                result.add(('m1-action-' + key, row, frame))
            return result
        atlas, row = self.base['runtime_rows'][hero][action]
        return {('m1-body-' + atlas, row, frame) for frame in range(len(self.base['atlases'][atlas]['frames'][row]))}


class Probe:
    def __init__(self, page, hero, destination, registry):
        self.page, self.hero, self.out, self.registry = page, hero, destination, registry
        self.canvas = page.locator('canvas')
        self.held = set()
        self.results, self.inputs, self.limitations = [], [], set()
        self.stage = 'boot'
        self.last_packet = None
        self.checked_campaign = None
        self.first_failure = None
        self.sample_index = 0

    def read(self):
        values = self.canvas.evaluate('c => ({...c.dataset})')
        self.last_packet = {'dataset':values, 'campaign':json.loads(values['campaign']) if values.get('campaign') else None,
                            'front':json.loads(values['front']) if values.get('front') else None}
        return self.last_packet

    def wait(self, predicate, label, timeout=12, alive=False):
        until = time.monotonic() + timeout
        while time.monotonic() < until:
            packet = self.read()
            d = packet['campaign']
            if alive and d and (d['state'] != 'playing' or d['hp'] <= 0 or d['menu']):
                raise AssertionError(f'{label}: live action interrupted: {d["state"]}/{d["menu"]}, hp={d["hp"]}')
            if predicate(packet):
                return packet
            self.page.wait_for_timeout(20)
        raise AssertionError(f'{label}: no matching fresh engine observation within {timeout}s')

    def check(self, condition, label, evidence=None):
        row = {'label':label,'status':'PASS' if condition else 'FAIL','stage':self.stage,'evidence':evidence}
        self.results.append(row)
        if not condition:
            self.first_failure={'label':label,'stage':self.stage,'evidence':evidence,'campaign':self.checked_campaign}
            (self.out/'first-checked-failure.json').write_text(json.dumps(self.first_failure,ensure_ascii=False,indent=2)+'\n')
            raise AssertionError(label)
        print('PASS', self.hero, label, flush=True)

    def event(self, kind, value):
        self.inputs.append({'kind':kind,'value':value,'wall_monotonic':time.monotonic(),
                            'browser_ms':self.page.evaluate('performance.now()'),'stage':self.stage})

    def keys(self, wanted):
        wanted = set(wanted)
        for key in sorted(self.held - wanted):
            self.event('key_up', key); self.page.keyboard.up(key)
        for key in sorted(wanted - self.held):
            self.event('key_down', key); self.page.keyboard.down(key)
        self.held = wanted

    def ui_xy(self, x, y, packet=None):
        packet = packet or self.read(); d = packet['campaign']; values = packet['dataset']
        rect = self.canvas.bounding_box()
        if d:
            scale, ox, oy = d['transform']; rw, rh = d['raw']; px, py = x*scale+ox, y*scale+oy
        else:
            t = json.loads(values['screenTransform']); rw, rh = float(values['rawWidth']), float(values['rawHeight'])
            px, py = t[0]*x+t[2]*y+t[4], t[1]*x+t[3]*y+t[5]
        return rect['x']+px/rw*rect['width'], rect['y']+py/rh*rect['height']

    def front_button(self, name):
        p = self.wait(lambda p:p['dataset'].get('uiReady')=='true' and any(b['name']==name for b in json.loads(p['dataset'].get('ui','[]'))), 'visible front action '+name)
        b = next(b for b in json.loads(p['dataset']['ui']) if b['name']==name)
        self.check(not b.get('disabled',False), 'Enabled front action '+name)
        self.event('front_click', {'name':name,'rect':b})
        self.page.mouse.click(*self.ui_xy(b['x']+b['w']/2,b['y']+b['h']/2,p))

    def campaign_button(self, name):
        p = self.wait(lambda p:p['campaign'] and p['campaign']['ui_ready'] and name in p['campaign']['buttons'], 'visible campaign action '+name)
        d = p['campaign']; b = d['buttons'][name]; generation = d['ui_generation']
        self.event('campaign_click', {'name':name,'rect':b,'generation':generation})
        self.page.mouse.click(*self.ui_xy(b[0]+b[2]/2,b[1]+b[3]/2,p))
        self.wait(lambda p:p['campaign'] and p['campaign']['ui_ready'] and p['campaign']['ui_generation']!=generation, 'fresh UI after '+name)

    def aim(self, side, d=None, distance=280):
        d = d or self.read()['campaign']
        y = d.get('pose',{}).get('muzzle',[0,d['player'][1]-38])[1]
        target_x=max(20.,min(d['view'][0]-20.,d['player'][0]-d['camera']+side*distance))
        target_y=max(20.,min(d['view'][1]-20.,y+d['ground']))
        xy = self.ui_xy(target_x,target_y)
        self.page.mouse.move(*xy)

    def mark(self):
        return self.page.evaluate('sixProbe.packets.length')

    def observed_since(self, index):
        return self.page.evaluate('start=>sixProbe.packets.slice(start).filter(p=>p.campaign).map(p=>p.campaign)',index)

    def sample(self, seconds, side=None):
        mark=self.mark()
        first = self.wait(lambda p:p['campaign'] and p['campaign']['state']=='playing' and not p['campaign']['menu'], 'live sample precondition', alive=True)['campaign']
        # Each bounded stage places an ordinary pointer once. Repeated blocking
        # mouse round-trips can outlast a simulation tick on a software GPU.
        # The actual aim direction is still checked in every captured packet.
        if side is not None:self.aim(side,first)
        start=first['time'];deadline=time.monotonic()+max(10,seconds*12)
        while time.monotonic()<deadline:
            d=self.wait(lambda p:bool(p['campaign']),'campaign sample',alive=True)['campaign']
            if d['time']>=start+seconds:
                # Consume ALL passive engine emissions, not just the few that
                # the Python/browser transport happened to poll in real time.
                # This retains the strict all-cel assertion without aliasing.
                packets=[first]+self.observed_since(mark)
                self.sample_index+=1
                (self.out/f'sample-{self.sample_index:02d}-{self.stage}.json').write_text(json.dumps({'stage':self.stage,'clock':'unmodified world.time','requested_simulation_seconds':seconds,'packets':packets},ensure_ascii=False)+'\n')
                return packets
            self.page.wait_for_timeout(20)
        raise AssertionError('Engine simulation did not finish the bounded input observation')

    def pose_check(self, samples, action, side=None, moving=True):
        self.checked_campaign=samples[-1] if samples else None
        accepted = self.registry.cels(self.hero,action)
        matching = [d for d in samples if (str(d.get('pose',{}).get('source')),d.get('pose',{}).get('row'),d.get('pose',{}).get('frame')) in accepted]
        self.check(len(matching)>=2, 'Actual rendered '+action+' source is observed', {'samples':len(samples),'matching':len(matching)})
        frames = {d['pose']['frame'] for d in matching}
        if moving:
            expected_frames={cel[2] for cel in accepted}
            self.check(frames==expected_frames, 'Actual '+action+' gait visits every authored cel', {'observed':sorted(frames),'expected':sorted(expected_frames)})
            ordered=sorted(samples,key=lambda d:d['time'])
            settled=[d for d in ordered if d['time']>=ordered[0]['time']+.12 and d['grounded'] and abs(d['velocity'][0])>10]
            # A contextual strike does not stop physical movement. Its upper
            # action must preserve the same real locomotion cycle underneath.
            self.check(bool(settled) and all(d['pose'].get('body_action')==action for d in settled), 'Moving fire and contextual punches both preserve the actual gait', [{'action':d['pose'].get('body_action'),'melee':d.get('melee',0),'time':d['time']} for d in settled])
        for d in matching:
            self.checked_campaign=d
            p = d['pose']; anchor = p['anchor']
            self.check('world_time' in p,'Draw observation supplies its own simulation timestamp')
            lag=d['time']-p['world_time']
            aligned=[d['player'][i]-d['velocity'][i]*lag for i in range(2)]
            self.check(-.0001<=lag<=.0501 and math.dist(anchor,aligned)<1.1, 'Rendered anchor matches the model at the same draw timestamp', {'draw_time':p['world_time'],'model_time':d['time'],'lag':lag,'anchor':anchor,'model_at_draw':aligned})
            self.check('rendered_anchor' in p and math.dist(p['rendered_anchor'],anchor)<=.72,'Actual pixel-rounded draw anchor stays within half a pixel per axis',{'rendered':p.get('rendered_anchor'),'physical_at_draw':anchor})
            # floor_at alone excludes raised one-way platforms. A grounded
            # actor's observed platform top is equally valid physical support.
            supports=[p['floor']]+[r[1] for r in d.get('platforms',[]) if r[0]-9<=anchor[0]<=r[0]+r[2]+9]
            support=min(supports,key=lambda y:abs(y-anchor[1]))
            grounded=p.get('grounded_at_draw',False)
            if grounded:
                self.check(abs(anchor[1]-support)<1.1, 'Grounded rendered anchor stays on actual floor/platform support', {'anchor':anchor,'support':support})
            if grounded and p.get('ground_contact') and 'visible_bottom_y' in p:
                gap=p['visible_bottom_y']-support
                self.check(-8.<=gap<=6., 'Contact cel opaque edge stays near support; this is not an anatomical sole measurement', {'opaque_edge_gap_px':gap,'source':p['source'],'frame':p['frame']})
            elif grounded and p.get('ground_contact'):
                self.limitations.add('No independent opaque-contact-edge observation was exported; source cels, render anchors and video remain available.')
            if side is not None:
                self.check(d['aim'][0]*side>.8, 'Aim remains on the target side during '+action, d['aim'])
                self.check(p.get('body_mirror')==side, 'Actual rendered body faces the target side', p.get('body_mirror'))
            rendered = p.get('rendered_muzzle')
            if p.get('weapon_visible'):
                self.check(rendered is not None and math.dist(rendered,p['muzzle'])<1.1, 'Independently reconstructed visible bore and logical muzzle agree', {'rendered':rendered,'logical':p['muzzle']})
        return matching

    def shot_check(self, samples):
        self.checked_campaign=samples[-1] if samples else None
        self.check(bool(samples),'Fresh projectile observation contains actual campaign packets')
        # Held fire occurs after movement, then the SAME world step immediately
        # advances each new bullet and its age. Therefore time-age precedes the
        # emission pose by one integration step. Match the acknowledged shot's
        # model timestamp to the actual subsequent draw at that exact timestamp;
        # never choose the spatially closest cel or extrapolate accelerating air.
        timeline=self.page.evaluate('sixProbe.packets.filter(p=>p.campaign).map(p=>p.campaign)')
        begin=samples[0]['time']+(.12 if all(d['grounded'] for d in samples) else -.0001)
        end=samples[-1]['time']+.0001
        matches=[];unobservable=[];actual_projectiles=[]
        for previous,d in zip(timeline,timeline[1:]):
            if not begin<=d['time']<=end or d['shots']<=previous['shots']:continue
            actual_projectiles.extend(b for b in d.get('hero_projectiles',[]) if b['kind']=='pistol' and b['age']<.16)
            step=d['time']-d.get('pose',{}).get('world_time',d['time'])
            newborn=[b for b in d.get('hero_projectiles',[]) if b['kind']=='pistol' and abs(b['age']-step)<.0001 and step>0.]
            if not newborn:
                unobservable.append({'reason':'The first integrated projectile was not observed','campaign':d});continue
            draws=[x for x in timeline if abs(x.get('pose',{}).get('world_time',-1)-d['time'])<.0001 and x.get('pose',{}).get('gun_visible',False)]
            if not draws:
                unobservable.append({'reason':'No visible gun draw at the exact acknowledged shot timestamp','campaign':d});continue
            draw=draws[0];bore=draw['pose'].get('rendered_muzzle')
            if bore is None:
                unobservable.append({'reason':'The exact draw has no independently reconstructed gun bore','campaign':d});continue
            for bullet in newborn:
                origin=[bullet['p'][i]-bullet['v'][i]*bullet['age'] for i in range(2)]
                matches.append({'error_px':math.dist(origin,bore),'origin':origin,'rendered_muzzle':bore,'emission_model_time':d['time'],'matched_draw_time':draw['pose']['world_time'],'bullet':bullet,'emission_packet':d,'draw_packet':draw})
        (self.out/('shot-origin-'+self.stage+'.json')).write_text(json.dumps({'matches':matches,'not_verified':unobservable},ensure_ascii=False)+'\n')
        self.check(bool(actual_projectiles),'A newly acknowledged real gunshot has an actual fresh pistol projectile')
        if unobservable:
            self.limitations.add('Exact shot-origin comparison covers only emission timestamps retained by passive throttled telemetry; skipped births are explicitly NOT_VERIFIED.')
            self.results.append({'label':'Some shot births lacked an exact observable render timestamp','status':'NOT_VERIFIED','stage':self.stage,'evidence_count':len(unobservable)})
        if not matches:return  # The per-gesture NOT_VERIFIED record above is authoritative.
        self.check(True,'Real fresh pistol shot births match an actual independent gun draw at the same simulation timestamp')
        worst=max(matches,key=lambda item:item['error_px']);self.checked_campaign=worst['emission_packet']
        self.check(worst['error_px']<1.1,'Every observable shot origin agrees with the exact emission-time visible bore',{'max_error_px':worst['error_px'],'samples':len(matches),'emission_model_time':worst['emission_model_time'],'matched_draw_time':worst['matched_draw_time'],'bullet':worst['bullet']})

    def start(self):
        self.stage='menu-selection'
        self.wait(lambda p:p['front'] is not None, 'opening metadata', timeout=120)
        if self.read()['front'].get('intro'):
            self.event('opening_skip_key','Enter');self.page.keyboard.press('Enter')
        self.wait(lambda p:p['front'] and not p['front']['intro'] and p['dataset'].get('uiReady')=='true', 'actionable main menu', timeout=30)
        self.front_button('ChooseHero')
        self.wait(lambda p:p['dataset'].get('page')=='characters' and p['dataset'].get('uiReady')=='true', 'characters page')
        selected = self.read()['front']['selected']
        targets = ['sheep',self.hero] if selected==self.hero else [self.hero]
        for hero in targets:
            for _ in range(12):
                p=self.read(); visible={b['name'] for b in json.loads(p['dataset'].get('ui','[]'))}
                if 'Select_'+hero in visible:break
                indices=[HEROES.index(name[len('Select_'):]) for name in visible if name.startswith('Select_') and name[len('Select_'):] in HEROES]
                navigation='PreviousPage' if indices and min(indices)>HEROES.index(hero) else 'NextPage'
                old=visible;self.front_button(navigation)
                self.wait(lambda p:{b['name'] for b in json.loads(p['dataset'].get('ui','[]'))}!=old and p['dataset'].get('uiReady')=='true','fresh visible roster page after '+navigation)
            self.front_button('Select_'+hero)
            self.wait(lambda p:p['front'] and p['front']['selected']==hero and p['dataset'].get('uiReady')=='true','selection acknowledgment '+hero)
        self.front_button('ConfirmHero')
        self.wait(lambda p:p['dataset'].get('page')=='main' and p['dataset'].get('uiReady')=='true','confirmed main menu')
        self.stage='visible-launch'
        self.front_button('StartCampaign')
        self.wait(lambda p:p['campaign'] is not None,'Mission 1 scene after actual Play',timeout=30)
        packets=self.page.evaluate('sixProbe.packets')
        launch=[p['front']['previews'].get(self.hero,{}) for p in packets if not p.get('campaign') and p.get('front',{}).get('launch_pending')]
        frames={p.get('frame') for p in launch if p.get('state')=='launch' and p.get('frame',-1)>=0}
        self.check(len(frames)>=2,'Play presents multiple actual selected launch frames before the scene transition',sorted(frames))
        d=self.read()['campaign'];self.check(d['character']==self.hero,'The selected identity enters Mission 1')
        self.campaign_button('CampaignBegin')
        for _ in range(15):
            d=self.read()['campaign']
            if d['menu']!='help':break
            self.campaign_button('CampaignGo')
        self.wait(lambda p:p['campaign'] and p['campaign']['state']=='playing' and not p['campaign']['menu'] and not p['campaign'].get('presentation'), 'natural Mission Start completion',timeout=20)
        self.canvas.focus()

    def keyboard_matrix(self):
        self.stage='position-with-normal-input'
        self.keys(['d','f']);self.aim(1)
        self.wait(lambda p:p['campaign']['player'][0]>=600,'live room for both backpedal directions',alive=True)
        self.keys(['f'])
        for side,move in ((1,'a'),(-1,'d')):
            self.stage='backpedal-'+str(side)
            self.aim(side);self.wait(lambda p:p['campaign']['aim'][0]*side>.8,'pointer direction acknowledgment',alive=True)
            before=self.read()['campaign']['shots'];self.keys([move,'f'])
            samples=self.sample(1.20,side);self.keys(['f']);self.pose_check(samples,'walk_back',side);self.shot_check(samples)
            self.check(samples[-1]['shots']>before,'Fire continues while backpedalling')
            self.stage='reverse-to-forward-'+str(side)
            self.keys(['d' if side==1 else 'a','f'])
            forward=self.sample(.90,side);self.keys(['f']);self.pose_check(forward,'walk',side);self.shot_check(forward)
            self.keys(['f']);stopped=self.sample(.20,side)
            self.check(abs(stopped[-1]['velocity'][0])<1. and stopped[-1]['aim'][0]*side>.8,'Release stops physical locomotion without losing aim')
            if stopped[-1]['grounded']:self.check(stopped[-1]['pose'].get('body_action')=='idle_fire','Stopped firing returns to the actual idle-fire body clip')
            self.stage='crouch-backpedal-'+str(side)
            self.keys([move,'s','f']);samples=self.sample(1.25,side);self.keys(['f'])
            self.pose_check([d for d in samples if d.get('crouching')],'crouch_walk_back',side)
            self.shot_check(samples);self.keys(['f'])
        self.stage='fresh-airborne-fire'
        self.keys(['f'])
        self.wait(lambda p:p['campaign']['grounded'],'grounded before a fresh jump',alive=True)
        self.aim(1,distance=800)
        air_mark=self.mark();self.event('key_press','Space');self.page.keyboard.press('Space')
        self.sample(1.40)
        gesture=self.observed_since(air_mark)
        (self.out/'air-gesture.json').write_text(json.dumps(gesture,ensure_ascii=False)+'\n')
        air=[d for d in gesture if not d['grounded']]
        self.checked_campaign=air[-1] if air else gesture[-1]
        self.check(bool(air) and any(d['velocity'][1]<-10 for d in air),'A fresh ordinary Space press causes actual ascent')
        fresh=[d for previous,d in zip(gesture,gesture[1:]) if not previous['grounded'] and not d['grounded'] and d['shots']>previous['shots']]
        self.check(bool(fresh),'A new gunshot is acknowledged between two consecutive airborne observations')
        self.pose_check(air,'air_fire',1,moving=False);self.shot_check(fresh)
        self.wait(lambda p:p['campaign']['grounded'],'real landing',alive=True)
        self.stage='moving-grenade'
        count=self.read()['campaign']['grenades'];self.keys(['d','f']);throw_mark=self.mark();self.page.keyboard.press('g');self.event('key_press','g')
        self.sample(.65,1);self.keys(['f']);self.sample(1.25,1)
        samples=self.observed_since(throw_mark)
        (self.out/'grenade-gesture.json').write_text(json.dumps(samples,ensure_ascii=False)+'\n')
        self.checked_campaign=samples[-1]
        self.check(samples[-1]['grenades']==count-1,'One ordinary throw consumes exactly one grenade')
        self.check(any(d.get('grenade_throw',{}).get('phase')=='windup' for d in samples),'Actual grenade anticipation is observed')
        self.check(any(d.get('grenade_throw',{}).get('released') for d in samples),'Actual release follows anticipation')
        self.check(max(len(d.get('bombs',[])) for d in samples)==1,'Exactly one physical bomb exists during this throw')
        self.check(any(d.get('grenade_blasts') for d in samples),'The real fuse produces a visible grenade blast')
        self.check(max(len(d.get('grenade_blasts',[])) for d in samples)==1,'The throw does not duplicate the blast')
        self.pose_check(samples,'grenade_throw',moving=False)
        self.keys([])

    def skill(self, method='keyboard'):
        if self.hero not in ('armadillo','frog'):return
        self.stage='native-skill-'+method
        self.wait(lambda p:p['campaign']['grounded'] and not p['campaign'].get('hero_skill',{}).get('phase'),'ready grounded skill',alive=True)
        self.aim(1)
        touch_session=None;stick_point=None
        if self.hero=='armadillo':
            if method=='touch':
                if self.page.context.browser.browser_type.name!='chromium':
                    self.results.append({'label':'Touch-only crouch plus contextual skill','status':'NOT_TESTED','reason':'This harness uses Chromium CDP for simultaneous physical touch points; no keyboard substitute is reported as touch-only.'})
                    return
                d=self.read()['campaign'];stick=d['stick']
                stick_point=self.ui_xy(stick[0]+stick[2]*.5,stick[1]+stick[3]*.9)
                touch_session=self.page.context.new_cdp_session(self.page)
                touch_session.send('Input.dispatchTouchEvent',{'type':'touchStart','touchPoints':[{'id':1,'x':stick_point[0],'y':stick_point[1]}]})
            elif method=='pad':self.page.evaluate('sixPad([0,1,1,0],[])')
            else:self.keys(['s'])
            self.wait(lambda p:p['campaign'].get('crouching'),'actual crouch requirement',alive=True)
        before=self.read()['campaign'];self.check(not before.get('weapon_offer') and not before['mounted'],'The contextual action is free for the native skill')
        skill_mark=self.mark()
        if method=='pad':
            axes=[0,1 if self.hero=='armadillo' else 0,1,0]
            self.page.evaluate('axes=>sixPad(axes,[3])',axes)
            self.wait(lambda p:bool(p['campaign'].get('hero_skill',{}).get('phase')),'ordinary virtual Y starts the native skill',alive=True)
            self.page.evaluate('axes=>sixPad(axes,[])',axes)
        elif method=='touch':
            context=before.get('context_action',{})
            self.check(context.get('visible') and not context.get('disabled'),'The real Ride/Swap/Skill context control is visible and enabled',context)
            r=context['rect'];point=self.ui_xy(r[0]+r[2]/2,r[1]+r[3]/2)
            if touch_session:
                touch_session.send('Input.dispatchTouchEvent',{'type':'touchStart','touchPoints':[{'id':1,'x':stick_point[0],'y':stick_point[1]},{'id':2,'x':point[0],'y':point[1]}]})
                self.wait(lambda p:bool(p['campaign'].get('hero_skill',{}).get('phase')),'two real touch points start the crouched skill',alive=True)
                touch_session.send('Input.dispatchTouchEvent',{'type':'touchEnd','touchPoints':[{'id':1,'x':stick_point[0],'y':stick_point[1]}]})
            else:self.page.touchscreen.tap(*point)
        else:self.event('key_press','e');self.page.keyboard.press('e')
        self.sample(1.35)
        samples=self.observed_since(skill_mark)
        (self.out/('skill-gesture-'+method+'.json')).write_text(json.dumps(samples,ensure_ascii=False)+'\n')
        self.checked_campaign=samples[-1]
        self.pose_check(samples,'skill',moving=False)
        events=[]
        for d in samples:
            events.append((d['time'],d.get('hero_skill',{}).get('phase',''),'model'))
            p=d.get('pose',{})
            if 'skill_phase_at_draw' in p:events.append((p['world_time'],p['skill_phase_at_draw'],'actual_draw'))
        events.sort(key=lambda item:item[0])
        expected=['windup','roll','brake','recover'] if self.hero=='armadillo' else ['windup','extend','retract','recover']
        self.check(all(any(event[1]==phase for event in events) for phase in expected),'Actual model/draw clocks observe preparation, active and recovery phases',events)
        positions=[next(event[0] for event in events if event[1]==phase) for phase in expected]
        self.check(positions==sorted(positions),'Skill recovery begins after the active phase on the real simulation clock',positions)
        if self.hero=='armadillo':self.check(max(d['player'][0] for d in samples)>before['player'][0]+40,'The shell rush causes actual world movement')
        else:
            extended=[d for d in samples if d.get('hero_skill',{}).get('extent',0)>1]
            self.check(bool(extended),'The natural tongue extends from the attached mouth')
            self.check(all(abs(math.dist(d['hero_skill']['mouth'],d['hero_skill']['tongue_tip'])-d['hero_skill']['extent'])<1.1 for d in extended),'Tongue tip, mouth and real extent stay connected')
        self.keys([])
        if touch_session:
            touch_session.send('Input.dispatchTouchEvent',{'type':'touchCancel','touchPoints':[]});touch_session.detach()
        if method=='pad':self.page.evaluate('sixPad([0,0,0,0],[],false)')

    def moving_tongue(self):
        if self.hero!='frog':return
        self.stage='moving-natural-tongue'
        self.wait(lambda p:p['campaign']['grounded'] and not p['campaign'].get('hero_skill',{}).get('phase'),'fresh moving-tongue precondition',alive=True)
        self.keys([]);self.aim(1)
        self.wait(lambda p:p['campaign']['aim'][0]>.8,'right target before moving tongue',alive=True)
        self.keys(['a']);mark=self.mark();self.event('key_press','e');self.page.keyboard.press('e')
        self.sample(1.35);self.keys([])
        gesture=self.observed_since(mark)
        (self.out/'moving-tongue-gesture.json').write_text(json.dumps(gesture,ensure_ascii=False)+'\n')
        open_motion=[d for d in gesture if d.get('pose',{}).get('skill_phase_at_draw') in ('extend','retract') and d['pose'].get('physics_velocity',[0])[0]<-10]
        self.checked_campaign=open_motion[-1] if open_motion else gesture[-1]
        self.check(len(open_motion)>=2,'Normal E plus actual opposite movement opens the tongue during locomotion')
        self.pose_check(open_motion,'tongue_walk_back',1,moving=False)
        frames={d['pose']['body_frame'] for d in open_motion}
        self.check(len(frames)>=2,'Moving tongue preserves distinct real gait phases instead of a sliding static attack',sorted(frames))
        self.check(all(d['pose']['body_action']=='tongue_walk_back' for d in open_motion),'Actual open-mouth body source preserves the aimed backward gait')
        self.check(any(d['hero_skill'].get('extent',0)>0 for d in gesture),'Moving tongue retains its real mouth-attached reach')

    def extra_inputs(self, modes):
        if 'touch' in modes:
            self.stage='actual-touch-fire';d=self.read()['campaign'];r=d['actions']['attack'];shots=d['shots']
            self.page.touchscreen.tap(*self.ui_xy(r[0]+r[2]/2,r[1]+r[3]/2))
            self.wait(lambda p:p['campaign']['shots']>shots or p['campaign']['melee']>0,'actual Fire touch result',alive=True)
            self.check(True,'Actual touch Fire reaches the same gameplay action')
            self.skill('touch')
        if 'pad' in modes:
            self.stage='virtual-pad-fire';d=self.read()['campaign'];shots=d['shots']
            self.page.evaluate('sixPad([0,0,1,0],[5])')
            self.wait(lambda p:p['campaign']['shots']>shots,'virtual standard RB gunshot',alive=True)
            self.page.evaluate('sixPad([0,0,1,0],[])');self.check(True,'Virtual standard pad fires through the real browser Gamepad API')
            self.skill('pad');self.page.evaluate('sixPad([0,0,0,0],[],false)')


def video_probe(path):
    if not shutil.which('ffprobe'):return {'status':'NOT_TESTED','reason':'ffprobe is unavailable; original stream and browser timestamps retained'}
    result=subprocess.run(['ffprobe','-v','error','-select_streams','v:0','-show_frames','-show_entries','frame=best_effort_timestamp_time','-of','json',str(path)],text=True,capture_output=True,timeout=60)
    if result.returncode:return {'status':'BLOCKED','reason':result.stderr}
    times=[float(f['best_effort_timestamp_time']) for f in json.loads(result.stdout).get('frames',[]) if 'best_effort_timestamp_time' in f]
    fps=(len(times)-1)/(times[-1]-times[0]) if len(times)>1 and times[-1]>times[0] else 0
    return {'status':'PASS' if fps>=55 else 'BELOW_60_FPS_TARGET','actual_encoded_fps':fps,'frames':len(times),'timestamps_seconds':times,'retimed':False}


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--url',required=True);parser.add_argument('--evidence',type=Path,required=True)
    parser.add_argument('--heroes',nargs='+',choices=HEROES,default=list(HEROES))
    parser.add_argument('--browser',choices=['chromium','firefox'],default='chromium')
    parser.add_argument('--inputs',nargs='+',choices=['keyboard','touch','pad'],default=['keyboard'],help='Additional activation probes; the complete keyboard/mouse matrix always runs')
    parser.add_argument('--expected-version',help='Reject a different actual front-menu build version')
    parser.add_argument('--headed',action='store_true');parser.add_argument('--angle-gl',action='store_true')
    parser.add_argument('--no-video',action='store_true');parser.add_argument('--require-60fps',action='store_true')
    parser.add_argument('--continue-on-failure',action='store_true',help='Continue only when independent hero failures are intentionally being compared; the default stops after the first failed case')
    args=parser.parse_args()
    if args.require_60fps and args.no_video:parser.error('--require-60fps cannot be combined with --no-video')
    args.heroes=list(dict.fromkeys(args.heroes))
    args.evidence.mkdir(parents=True,exist_ok=True)
    if any((args.evidence/hero/'results.json').exists() for hero in args.heroes):
        parser.error('Use a fresh --evidence directory: existing first-run observations must remain intact.')
    parsed=urlsplit(args.url);query=dict(parse_qsl(parsed.query));query['aion-qa']='1'
    url=urlunsplit((parsed.scheme,parsed.netloc,parsed.path,urlencode(query),parsed.fragment))
    registry=PoseRegistry();summary=[]
    with sync_playwright() as pw:
        # Chromium's Unix SingletonSocket has a short path limit. Keep the
        # disposable browser runtime outside long evidence-directory names.
        runtime=Path(tempfile.mkdtemp(prefix='aion6-'));env=dict(os.environ)
        for key,name in [('TMPDIR','tmp'),('XDG_CONFIG_HOME','config'),('XDG_DATA_HOME','data'),('XDG_CACHE_HOME','cache')]:
            folder=runtime/name;folder.mkdir(parents=True,exist_ok=True);env[key]=str(folder.resolve())
        if args.browser=='firefox':
            env.update(MOZ_DISABLE_CONTENT_SANDBOX='1',LIBGL_ALWAYS_SOFTWARE='1')
            browser=pw.firefox.launch(headless=not args.headed,env=env,firefox_user_prefs={'webgl.force-enabled':True,'dom.w3c_touch_events.enabled':1})
        else:
            browser=pw.chromium.launch(executable_path=shutil.which('chromium'),headless=not args.headed,env=env,args=['--no-sandbox','--enable-unsafe-swiftshader']+(['--use-angle=gl'] if args.angle_gl else []))
        for hero_index,hero in enumerate(args.heroes):
            out=args.evidence/hero;out.mkdir(exist_ok=True)
            context=browser.new_context(viewport={'width':1280,'height':720},locale='tr-TR',has_touch=True,reduced_motion='no-preference',accept_downloads=True)
            context.add_init_script(OBSERVER);page=context.new_page();errors=[];console=[]
            page.on('pageerror',lambda error:errors.append(str(error)))
            def message(item):
                console.append({'wall_monotonic':time.monotonic(),'type':item.type,'text':item.text})
                if item.type=='error' or 'SCRIPT ERROR' in item.text or 'ERROR:' in item.text:errors.append(item.text)
            page.on('console',message)
            probe=Probe(page,hero,out,registry);report={'hero':hero,'browser':args.browser,'version':browser.version,'url':url,'status':'FAIL','video':{'status':'NOT_TESTED'},'physical_device':'NOT_TESTED','physical_gamepad':'NOT_TESTED','authored_source_sha256':registry.source_hashes}
            recording=False
            try:
                page.goto(url,timeout=120000);page.wait_for_selector('canvas[data-front]',timeout=120000)
                report['build']=page.evaluate("fetch('build.json',{cache:'no-store'}).then(r=>r.ok?r.json():null).catch(()=>null)")
                report['front_version']=probe.read()['dataset'].get('version')
                if args.expected_version:probe.check(report['front_version']==args.expected_version,'Actual menu build matches the requested version',report['front_version'])
                if not args.no_video:
                    report['capture']=page.evaluate(START_VIDEO);recording=report['capture'].get('supported',False)
                    probe.check(recording,'Original real-time canvas capture starts with a requested 60 fps track')
                probe.start();probe.keyboard_matrix();probe.skill();probe.moving_tongue();probe.extra_inputs(args.inputs)
                probe.check(not errors,'No browser/Godot errors during the complete hero matrix',errors)
                report['status']='PASS'
            except Exception as error:
                report['error']=str(error);report['failed_stage']=probe.stage
                # Save the first failure BEFORE cleanup releases input or navigation.
                if probe.first_failure and probe.first_failure.get('campaign'):
                    report['failure_packet']={'campaign':probe.first_failure['campaign']};report['failure_packet_source']='immutable-first-checked-observation'
                try:
                    live=probe.read();report['live_before_cleanup']=live
                    if 'failure_packet' not in report:report['failure_packet']=live;report['failure_packet_source']='live-before-cleanup'
                    page.screenshot(path=str(out/'failure.png'))
                except Exception:
                    if 'failure_packet' not in report:report['failure_packet']=probe.last_packet;report['failure_packet_source']='last-successful-read'
                print('FAIL',hero,probe.stage,str(error),flush=True)
            finally:
                try:
                    evidence=page.evaluate('({origin:sixProbe.origin,packets:sixProbe.packets,raf:sixProbe.raf,events:sixProbe.events})')
                    (out/'timeline.json').write_text(json.dumps(evidence,ensure_ascii=False)+'\n')
                    if recording:
                        with page.expect_download(timeout=20000) as download:report['capture']=page.evaluate(STOP_VIDEO)
                        video=out/'normal-input-original.webm';download.value.save_as(str(video));report['video']=video_probe(video)
                        (out/'capture-timestamps.json').write_text(json.dumps(report['capture'],indent=2)+'\n')
                        if args.require_60fps and report['video']['status']!='PASS':report['status']='FAIL';report['capture_requirement']='Actual capture cadence did not meet the requested 60 fps target; no frames were fabricated.'
                except Exception as error:report['recording_error']=str(error);report['status']='FAIL'
                # Cleanup affects only input devices owned by this probe.
                try:probe.keys([]);page.evaluate('sixPad([0,0,0,0],[],false)')
                except Exception:pass
                report.update(checks=probe.results,inputs=probe.inputs,console_errors=errors,limitations=sorted(probe.limitations),game_state_mutations=False,simulation_retimed=False,contexts_at_once=1)
                (out/'console.json').write_text(json.dumps(console,ensure_ascii=False,indent=2)+'\n')
                (out/'results.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
                context.close();summary.append({'hero':hero,'status':report['status'],'checks':len(probe.results),'failed_stage':report.get('failed_stage'),'video_status':report['video']['status']})
                (args.evidence/'summary.json').write_text(json.dumps(summary,indent=2)+'\n')
            if report['status']!='PASS' and not args.continue_on_failure:
                summary.extend({'hero':remaining,'status':'NOT_TESTED','reason':'Stopped after the first failed case; no common-cause repetition or hidden automatic retry.'} for remaining in args.heroes[hero_index+1:])
                (args.evidence/'summary.json').write_text(json.dumps(summary,indent=2)+'\n')
                break
        browser.close()
    print(json.dumps(summary,indent=2));return 0 if all(row['status']=='PASS' for row in summary) else 1


if __name__=='__main__':raise SystemExit(main())
