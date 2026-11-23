"""Normal-entry AIONIA presentation and rescue checks against a real Web export.

Only user input is written. Canvas telemetry, storage and build metadata are read
without world setters, save injection, teleportation or direct damage. The
optional Gamepad API object is explicitly synthetic, not a physical controller.
"""
import argparse
import json
import math
import os
from pathlib import Path
import shutil
import time

from playwright.sync_api import sync_playwright


parser = argparse.ArgumentParser()
parser.add_argument('--url', required=True)
parser.add_argument('--evidence', required=True, type=Path)
parser.add_argument('--browser', choices=['chromium', 'firefox'], default='chromium')
parser.add_argument('--locale', choices=['tr-TR', 'en-US'], default='tr-TR')
parser.add_argument('--scenario', choices=['front', 'campaign', 'all'], default='all')
parser.add_argument('--rescue', action='store_true', help='Reach a real captive using ordinary play; fire ropes, then approach for gift.')
parser.add_argument('--idle-attract', action='store_true', help='Also wait for the actual 30-second inactivity trigger.')
parser.add_argument('--large-text', action='store_true', help='Use the actual settings control for 200%% text during the presentation flow.')
args = parser.parse_args()
args.evidence.mkdir(parents=True, exist_ok=True)
checks = []
errors = []
console = []
observations = {}


def check(value, label):
    assert value, label
    checks.append(label)
    print('PASS', label, flush=True)


with sync_playwright() as playwright:
    if args.browser == 'firefox':
        browser = playwright.firefox.launch(
            headless=False,
            env=dict(os.environ, MOZ_DISABLE_CONTENT_SANDBOX='1', LIBGL_ALWAYS_SOFTWARE='1'),
            firefox_user_prefs={'webgl.force-enabled': True, 'dom.w3c_touch_events.enabled': 1},
        )
    else:
        browser = playwright.chromium.launch(
            executable_path=shutil.which('chromium'),
            args=['--no-sandbox', '--enable-unsafe-swiftshader'],
        )
    context = browser.new_context(
        viewport={'width': 1280, 'height': 720}, locale=args.locale, has_touch=True,
    )
    context.add_init_script("""(() => {
      const pad={id:'Xbox Controller (QA virtual input)',index:0,connected:false,
        mapping:'standard',timestamp:0,axes:[0,0,0,0],
        buttons:Array.from({length:17},()=>({pressed:false,touched:false,value:0}))};
      Object.defineProperty(navigator,'getGamepads',{value:()=>pad.connected?[pad]:[]});
      window.qaPad=pad;
      window.qaPadConnect=value=>{
        pad.connected=value;
        const event=new Event(value?'gamepadconnected':'gamepaddisconnected');
        Object.defineProperty(event,'gamepad',{value:pad});
        window.dispatchEvent(event);
      };
      window.qaPadButton=(i,value)=>{
        pad.buttons[i]={pressed:value,touched:value,value:value?1:0};
        pad.timestamp=performance.now();
      };
    })();""")
    page = context.new_page()
    page.on('pageerror', lambda error: errors.append(str(error)))

    def log(message):
        console.append({'type': message.type, 'text': message.text})
        if 'SCRIPT ERROR' in message.text or 'ERROR:' in message.text:
            errors.append(message.text)
    page.on('console', log)
    canvas = page.locator('canvas')

    def raw():
        return canvas.evaluate('canvas => ({...canvas.dataset})')

    def front():
        return json.loads(canvas.get_attribute('data-front') or '{}')

    def campaign():
        return json.loads(canvas.get_attribute('data-campaign') or '{}')

    def ready():
        page.wait_for_selector('canvas[data-state="ready"][data-ui-ready="true"]', timeout=150000)

    def campaign_ready():
        page.wait_for_function("""() => {
          const value=document.querySelector('canvas')?.dataset.campaign;
          return value && JSON.parse(value).ui_ready;
        }""", timeout=30000)

    def coords(x, y, in_campaign=False):
        bounds = canvas.bounding_box()
        if in_campaign:
            data = campaign()
            transform = data['transform']
            width, height = data['raw']
            xx, yy = x*transform[0]+transform[1], y*transform[0]+transform[2]
        else:
            data = raw()
            transform = json.loads(data['screenTransform'])
            width, height = float(data['rawWidth']), float(data['rawHeight'])
            xx = transform[0]*x+transform[2]*y+transform[4]
            yy = transform[1]*x+transform[3]*y+transform[5]
        return bounds['x']+xx/width*bounds['width'], bounds['y']+yy/height*bounds['height']

    def front_buttons():
        return json.loads(raw().get('ui', '[]'))

    def tap(name=None, text=None, in_campaign=False):
        if in_campaign:
            campaign_ready()
            buttons = [{'name': key, 'x': value[0], 'y': value[1], 'w': value[2], 'h': value[3], 'text': value[4]}
                       for key, value in campaign()['buttons'].items()]
        else:
            page.wait_for_selector('canvas[data-ui-ready="true"]', timeout=30000)
            # Browser rAF is not Godot's container-sort acknowledgment. Let the
            # event reach the engine, then require its actual readiness again.
            page.evaluate('() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve)))')
            page.wait_for_selector('canvas[data-ui-ready="true"]', timeout=30000)
            buttons = front_buttons()
        button = next((button for button in buttons if button['name'] == name), None) if name else next((button for button in buttons if button['text'] == text), None)
        if not button and not in_campaign and name and name.startswith('StartSelect_'):
            roster = ['aion', 'sheep', 'rabbit', 'eren', 'armadillo', 'frog']
            target = roster.index(name[len('StartSelect_'):])
            visited_rosters = set()
            for _ in roster:
                names = frozenset(b['name'] for b in buttons if b['name'].startswith('StartSelect_'))
                if not names or names in visited_rosters:
                    break
                visited_rosters.add(names)
                indices = [roster.index(value[len('StartSelect_'):]) for value in names]
                tap('RosterPrevious' if target < min(indices) else 'RosterNext')
                buttons = front_buttons()
                button = next((value for value in buttons if value['name'] == name), None)
                if button:
                    break
        if not button and not in_campaign and name not in ['NextPage', 'PreviousPage', 'RosterNext', 'RosterPrevious']:
            # Use the real visible pager, never reveal hidden controls via JS.
            visited = set()
            for _ in range(30):
                data = raw()
                position = int(data.get('menuPage', 0))
                total = int(data.get('menuPages', 0))
                if total <= 1 or (position, total) in visited:
                    break
                visited.add((position, total))
                if position+1 < total:
                    tap('NextPage')
                else:
                    for _ in range(position):
                        tap('PreviousPage')
                buttons = front_buttons()
                button = next((value for value in buttons if value['name'] == name), None) if name else next((value for value in buttons if value['text'] == text), None)
                if button:
                    break
        assert button, ('Visible action not found', name, text, [button['name'] for button in buttons])
        before_page = int(raw().get('menuPage', 0)) if not in_campaign else None
        before_roster = [b['name'] for b in buttons if b['name'].startswith('StartSelect_')]
        before_campaign_generation = campaign().get('ui_generation', 0) if in_campaign else None
        page.touchscreen.tap(*coords(button['x']+button['w']/2, button['y']+button['h']/2, in_campaign))
        if in_campaign:
            page.wait_for_function("old=>{const value=document.querySelector('canvas')?.dataset.campaign;if(!value)return false;const d=JSON.parse(value);return d.ui_generation!==old && d.ui_ready}", arg=before_campaign_generation, timeout=15000)
        if not in_campaign:
            destination = {'OpenSettings': 'settings', 'ChooseHero': 'characters', 'HowToPlay': 'help', 'ConfirmHero': 'main', 'FrontHelpBack': 'main', 'PageBack': 'main'}.get(name)
            if destination:
                page.wait_for_function("page=>{const d=document.querySelector('canvas').dataset;return d.page===page && d.uiReady==='true'}", arg=destination, timeout=15000)
            if name in ['NextPage', 'PreviousPage']:
                expected = before_page+(1 if name == 'NextPage' else -1)
                page.wait_for_function("expected=>{const d=document.querySelector('canvas').dataset;return Number(d.menuPage)===expected && d.uiReady==='true'}", arg=expected, timeout=15000)
            if name in ['RosterNext', 'RosterPrevious']:
                page.wait_for_function("old=>{const d=document.querySelector('canvas').dataset;const names=JSON.parse(d.ui).filter(b=>b.name.startsWith('StartSelect_')).map(b=>b.name);return d.uiReady==='true' && JSON.stringify(names)!==JSON.stringify(old)}", arg=before_roster, timeout=15000)
        page.wait_for_timeout(180)

    def fit(label, in_campaign=False):
        if in_campaign:
            campaign_ready()
            data = campaign()
            buttons = [{'name': name, 'x': value[0], 'y': value[1], 'w': value[2], 'h': value[3]}
                       for name, value in data['buttons'].items()]
            width, height = data['view']
        else:
            data = raw()
            buttons = front_buttons()
            width, height = float(data['viewWidth']), float(data['viewHeight'])
        assert buttons, ('No visible actions', label)
        for button in buttons:
            assert button['w'] > 0 and button['h'] > 0, (label, button)
            assert button['x'] >= -1 and button['y'] >= -1, (label, button)
            assert button['x']+button['w'] <= width+1 and button['y']+button['h'] <= height+1, (label, button, width, height)
        check(True, label+': all current actions fit and have positive hit areas')

    def storage():
        return page.evaluate("""() => Object.fromEntries(
          ['aion.campaign.v1','aion-runner-save-v1'].map(key=>[key,localStorage.getItem(key)]))""")

    def skip_opening():
        page.wait_for_function("document.querySelector('canvas')?.dataset.front", timeout=150000)
        if front().get('intro'):
            canvas.focus()
            page.keyboard.press('Enter')
        ready()

    def presentation_done():
        deadline = time.monotonic()+15
        while time.monotonic() < deadline:
            data = campaign()
            if not data.get('presentation', data.get('presentation_stage')):
                return
            # This intentionally short scene can finish between the telemetry
            # read and a pointer tap. Use its actual Enter skip input; a stale
            # metadata button disappearing is not a gameplay failure.
            canvas.focus()
            page.keyboard.press('Enter')
            page.wait_for_timeout(200)
        raise AssertionError(('Presentation did not finish', campaign()))

    held = set()

    def keys(wanted):
        global held
        wanted = set(wanted)
        for key in held-wanted:
            page.keyboard.up(key)
        for key in wanted-held:
            page.keyboard.down(key)
        held = wanted

    try:
        page.goto(args.url, timeout=150000)
        page.wait_for_function("document.querySelector('canvas')?.dataset.front", timeout=150000)
        if args.scenario in ['front', 'all']:
            initial = front()
            if initial.get('intro'):
                page.screenshot(path=str(args.evidence/'opening.png'))
                page.wait_for_function("!JSON.parse(document.querySelector('canvas').dataset.front).intro", timeout=20000)
                check(True, 'Cold-launch opening completes naturally without a forced extra wait')
            ready()
            fit('Desktop main')
            check(raw()['theme'] == 'dark' and raw()['fontMode'] == 'system', 'Fresh UI uses dark theme and system body font')
            if args.large_text:
                tap('OpenSettings')
                tap('Option_text_size_2_0')
                page.wait_for_selector('canvas[data-text-scale="2.0"][data-ui-ready="true"]')
                tap('PageBack')
                ready()
                check(raw()['textScale'] == '2.0', 'Actual settings apply 200% text without changing the selected font')
                fit('Desktop 200% main')
            page.screenshot(path=str(args.evidence/'main.png'))
            for hero in ['aion', 'sheep', 'rabbit', 'eren', 'armadillo', 'frog']:
                tap('ChooseHero')
                tap('Select_'+hero)
                check(not any(button['name'] in ['Select_owl', 'Select_wolf'] for button in front_buttons()), 'Retired owl/wolf are not offered as playable choices')
                # Selection may rebuild and repaginate the current card.
                tap('ConfirmHero')
                ready()
                check(raw()['character'] == hero, 'Real character selection and confirmation: '+hero)
                if args.large_text:page.screenshot(path=str(args.evidence/('main-200-'+hero+'.png')))
            tap('StartSelect_aion')
            tap('HowToPlay')
            fit('Interactive help')
            tap('ReplayOpening')
            page.wait_for_function("JSON.parse(document.querySelector('canvas').dataset.front).intro")
            canvas.focus()
            page.keyboard.press('Enter')
            ready()
            check(not front()['intro'], 'Replayed opening skips through a normal Enter input')
            tap('HowToPlay')
            tap('FrontHelpNext')
            check(front()['help_step'] > 0, 'Help Next advances a real tutorial page')
            tap('FrontHelpPrevious')
            check(front()['help_step'] == 0, 'Help Previous returns without entering live gameplay')
            tap('FrontHelpBack')
            ready()
            for size, label in [({'width': 393, 'height': 873}, 'portrait'), ({'width': 873, 'height': 393}, 'landscape')]:
                page.set_viewport_size(size)
                page.wait_for_timeout(500)
                ready()
                fit('Rotated '+label+' main')
                check(raw()['character'] == 'aion', 'Rotation preserves selected hero: '+label)
                page.screenshot(path=str(args.evidence/('main-'+label+'.png')))
            page.set_viewport_size({'width': 1280, 'height': 720})
            page.wait_for_timeout(450)
            tap('HowToPlay')
            before = storage()
            tap('StartAttract')
            page.wait_for_function("JSON.parse(document.querySelector('canvas').dataset.front).demo")
            start = front()
            page.wait_for_timeout(1800)
            end = front()
            check(end['demo_player'][0] != start['demo_player'][0] and end['demo_shots'] > start['demo_shots'], 'Attract scene actually moves and fires through its isolated game model')
            check(storage() == before, 'Attract gameplay leaves campaign Continue and Endless saved data unchanged')
            page.screenshot(path=str(args.evidence/'attract.png'))
            canvas.focus()
            page.keyboard.press('Escape')
            ready()
            check(not front()['demo'], 'An ordinary input leaves Attract Mode immediately')
            check(storage() == before, 'Leaving Attract Mode also preserves both save stores')
            if args.idle_attract:
                page.wait_for_function("JSON.parse(document.querySelector('canvas').dataset.front).demo", timeout=45000)
                check(True, 'Actual inactivity trigger starts Attract Mode')
                canvas.focus()
                page.keyboard.press('Enter')
                ready()
            tap('StartRun')
            page.wait_for_selector('canvas[data-state="running"]', timeout=15000)
            check(True, 'Endless starts through its actual main-menu action')
            canvas.focus()
            page.keyboard.press('Escape')
            page.wait_for_selector('canvas[data-state="paused"][data-ui-ready="true"]')
            if args.large_text:
                fit('200% Endless pause first page')
                names = {button['name'] for button in front_buttons()}
                check({'PauseResume', 'PauseMainMenu'}.issubset(names), '200% pause exposes Resume and Main menu on the first page, without a pager detour')
            # Optional explanatory/settings items may remain paginated, while
            # the short pause panel keeps these essential actions visible.
            tap(text='Main menu' if args.locale == 'en-US' else 'Ana menü')
            ready()
            check(raw()['page'] == 'main', 'Endless pause returns to the same main menu')
            if args.large_text and args.scenario == 'all':
                # Keep the separately scoped campaign input probe readable at
                # its normal scale; larger campaign layouts have a source suite.
                tap('OpenSettings')
                tap('Option_text_size_1_0')
                page.wait_for_selector('canvas[data-text-scale="1.0"][data-ui-ready="true"]')
                tap('PageBack')
                ready()
        else:
            skip_opening()

        if args.scenario in ['campaign', 'all']:
            tap('StartSelect_aion')
            tap('StartCampaign')
            page.wait_for_function("document.querySelector('canvas')?.dataset.campaign", timeout=45000)
            campaign_ready()
            fit('Campaign briefing', True)
            tap('CampaignBegin', in_campaign=True)
            for _ in range(15):
                if campaign().get('menu') != 'help':
                    break
                tap('CampaignGo', in_campaign=True)
            presentation_done()
            page.wait_for_function("JSON.parse(document.querySelector('canvas').dataset.campaign).state==='playing'", timeout=15000)
            check(True, 'Actual Arcade briefing/help/start presentation reaches playable Mission 1')
            canvas.focus()
            def restart_for_probe():
                page.wait_for_function("['playing','continue_offer','continue_pick','dead'].includes(JSON.parse(document.querySelector('canvas').dataset.campaign).state)",timeout=15000)
                if campaign()['menu'] in ['continue_offer','continue_pick']:
                    if campaign()['menu']=='continue_pick':tap('ArcadeBackToCountdown',in_campaign=True)
                    page.wait_for_function("JSON.parse(document.querySelector('canvas').dataset.campaign).menu==='dead'",timeout=30000)
                if campaign()['menu']!='dead':
                    canvas.focus();page.keyboard.press('Escape')
                    page.wait_for_function("JSON.parse(document.querySelector('canvas').dataset.campaign).menu==='paused'",timeout=10000)
                tap('CampaignRestart',in_campaign=True)
                presentation_done()
                page.wait_for_function("()=>{const d=JSON.parse(document.querySelector('canvas').dataset.campaign);return d.state==='playing' && d.hp===1 && d.ui_ready}",timeout=15000)
                canvas.focus()

            initial_x = campaign()['player'][0]
            page.keyboard.down('d')
            page.wait_for_function("x=>JSON.parse(document.querySelector('canvas').dataset.campaign).player[0]>x+35", arg=initial_x)
            page.keyboard.up('d')
            check(campaign()['player'][0] > initial_x+30, 'Normal D input moves the Arcade hero')
            before = campaign()
            rectangle = before['actions']['grenade']
            page.touchscreen.tap(*coords(rectangle[0]+rectangle[2]/2, rectangle[1]+rectangle[3]/2, True))
            page.wait_for_function("count=>JSON.parse(document.querySelector('canvas').dataset.campaign).grenades===count-1", arg=before['grenades'])
            check(True, 'Actual touch Bomb spends one grenade')
            before = campaign()
            rectangle = before['actions']['jump']
            page.touchscreen.tap(*coords(rectangle[0]+rectangle[2]/2, rectangle[1]+rectangle[3]/2, True))
            page.wait_for_function("JSON.parse(document.querySelector('canvas').dataset.campaign).player[1]<-15")
            check(True, 'Actual touch Jump reaches the same physics action')

            # The previous movement/jump probe can leave the first threat in
            # range. Use a normal new mission for the independent Start probe.
            restart_for_probe()
            page.evaluate('qaPadConnect(true)')
            page.wait_for_timeout(200)
            observations['pad_pause_precondition'] = campaign()
            check(observations['pad_pause_precondition']['state'] == 'playing', 'Virtual Start is sent during an active run')
            page.evaluate('qaPadButton(9,true)')
            page.wait_for_function("JSON.parse(document.querySelector('canvas').dataset.campaign).menu==='paused'")
            page.evaluate('qaPadButton(9,false)')
            frozen = campaign()
            page.wait_for_timeout(250)
            check(campaign()['time'] == frozen['time'], 'Virtual Gamepad API Start pauses the actual world')
            page.set_viewport_size({'width': 393, 'height': 873})
            page.wait_for_timeout(500)
            fit('Campaign portrait pause', True)
            check(campaign()['score'] == frozen['score'] and campaign()['section'] == frozen['section'], 'Paused rotation preserves campaign progress')
            page.screenshot(path=str(args.evidence/'campaign-portrait-paused.png'))
            page.evaluate('qaPadButton(0,true)')
            page.wait_for_function("JSON.parse(document.querySelector('canvas').dataset.campaign).menu===''")
            page.evaluate('qaPadButton(0,false)')
            check(campaign()['state'] == 'playing', 'Virtual Gamepad API confirm activates the selected Resume action')
            page.evaluate('qaPadConnect(false)')
            page.set_viewport_size({'width': 1280, 'height': 720})
            page.wait_for_timeout(500)
            canvas.focus()
            class AimActorDied(Exception):
                pass
            aim_retries = 0
            observations['aim_deaths'] = []
            observations['aim_attempts'] = []
            def alive_aim_wait(expression, arg=None, timeout=10000):
                script = "args=>{const d=JSON.parse(document.querySelector('canvas').dataset.campaign);if(d.hp<=0 || ['dying','dead'].includes(d.state))return {actor_dead:d};return ("+expression+");}"
                handle=page.wait_for_function(script,arg=arg,timeout=timeout)
                packet=handle.json_value();handle.dispose()
                if 'actor_dead' in packet:raise AimActorDied(packet['actor_dead'])
                return packet
            aim_samples = []
            directions = [(['d'], [1, 0]), (['d', 'w'], [1, -1]), (['w'], [0, -1]), (['a', 'w'], [-1, -1]), (['a'], [-1, 0]), (['a', 's'], [-1, 1]), (['s'], [0, 1]), (['d', 's'], [1, 1])]
            for index, (inputs, target) in enumerate(directions):
                while True:
                    try:
                        current=campaign()
                        if current['hp']<=0 or current['state'] in ['dying','dead']:raise AimActorDied(current)
                        length = math.hypot(*target)
                        expected = [target[0]/length, target[1]/length]
                        attempt = {'case': index, 'keys': inputs, 'expected': expected, 'stage': 'neutralizing', 'initial': current}
                        observations['aim_attempts'].append(attempt)
                        # Grounded Down is intentionally a horizontal crouch shot.
                        # Every downward test must use its own real jump, rather than
                        # the descending tail of the preceding case's flight.
                        keys([])
                        downward = target[1] > 0
                        ground_packet = None
                        direction_armed = False
                        if downward:
                            ground_packet = alive_aim_wait("d.state==='playing' && d.hp>0 && d.grounded && !d.crouching && Math.abs(d.velocity[0])<1 ? d : false")
                            attempt.update(stage='grounded', ground_before_jump=ground_packet)
                            # Settle direction input BEFORE takeoff on the base
                            # floor. Slow CDP key calls must not consume the short
                            # rising/downward-aim window we are about to test.
                            # On a raised one-way platform Down+Jump means drop;
                            # retain jump-before-Down there instead.
                            if abs(ground_packet['player'][1]-ground_packet['pose']['floor'])<1:
                                keys(inputs)
                                direction_armed = True
                                armed = alive_aim_wait("d.state==='playing' && d.hp>0 && d.grounded && d.crouching && Math.abs(d.player[1]-d.pose.floor)<1 && (args===0 || Math.sign(d.aim[0])===args) ? d : false", target[0])
                                attempt.update(stage='direction_armed_before_jump', armed=armed)
                            (args.evidence/('aim-case-%d-attempt-%d.json' % (index, len(observations['aim_attempts'])))).write_text(json.dumps(attempt, ensure_ascii=False, indent=2)+'\n')
                            page.keyboard.press('Space')
                            attempt['stage'] = 'jump_sent'
                        elif index in [0, 3]:
                            page.keyboard.press('Space')
                        if not direction_armed:
                            keys(inputs)
                        prepared = alive_aim_wait("d.state==='playing' && d.hp>0 && Math.hypot(d.aim[0]-args[0][0],d.aim[1]-args[0][1])<.03 && (!args[1] || (!d.grounded && d.player[1]<-20 && d.velocity[1]<0)) ? d : false", [expected, downward])
                        attempt.update(stage='prepared', prepared=prepared)
                        shots = prepared['shots']
                        page.keyboard.down('f')
                        # Return the actual packet that first observes this shot. Do
                        # not re-read after landing and label its grounded aim as the
                        # direction of an earlier airborne shot.
                        data = alive_aim_wait("d.shots>args ? d : false", shots, timeout=5000)
                        attempt.update(stage='shot_observed', observed_shot=data)
                        packet = {'case': index, 'keys': inputs, 'expected': expected, 'downward_air_required': downward, 'ground_before_jump': ground_packet, 'prepared': prepared, 'shots_before_fire': shots, 'observed_shot': data}
                        aim_samples.append(packet)
                        observations['keyboard_aim'] = aim_samples
                        (args.evidence/'keyboard-aim-packets.json').write_text(json.dumps(aim_samples, ensure_ascii=False, indent=2)+'\n')
                        check(data['shots'] > shots and math.dist(data['aim'], expected) < .03 and (not downward or not data['grounded']), 'Actual keyboard aim and gun action: '+str(target))
                        page.keyboard.up('f')
                        keys([])
                        page.wait_for_timeout(360)

                        break
                    except AimActorDied as death:
                        dead=death.args[0]
                        observations['aim_deaths'].append({'case':index,'state':dead})
                        (args.evidence/('aim-case-%d-death-%d.json'%(index,aim_retries))).write_text(json.dumps(dead,indent=2)+'\n')
                        page.screenshot(path=str(args.evidence/('aim-case-%d-death-%d.png'%(index,aim_retries))))
                        keys([]);page.keyboard.up('f')
                        assert aim_retries<3, ('Aim cases exceeded three fresh runs',dead)
                        restart_for_probe();aim_retries+=1
            observations['aim_new_runs']=aim_retries

            keys([])
            observations['before_crouch_restart'] = campaign()
            restart_for_probe()
            check(campaign()['grounded'], 'An explicit new run starts the independent crouch test on real ground')
            before = campaign()
            keys(['s', 'd', 'f'])
            page.wait_for_function("before=>{const d=JSON.parse(document.querySelector('canvas').dataset.campaign);return d.crouching && d.player[0]>before.x+12 && d.shots>before.shots}", arg={'x': before['player'][0], 'shots': before['shots']}, timeout=10000)
            check(True, 'Down + movement + Fire reaches real crouch locomotion and a shot together')
            page.screenshot(path=str(args.evidence/'crouch-moving-fire.png'))
            keys([])
            page.wait_for_function("!JSON.parse(document.querySelector('canvas').dataset.campaign).crouching", timeout=5000)
            check(True, 'Releasing Down exits crouch without a stuck posture')

            if args.rescue:
                class PrecontactDeath(Exception):
                    pass

                retries = 0
                last_jump = 0.
                attempt = 0
                rescue_attempts = []
                observations['rescue_attempts'] = rescue_attempts

                def rescue_trace(stage, current, selected=None, requested=()):
                    npc = next((n for n in current['npcs'] if selected and n['id'] == selected['id']), None)
                    packet = {'attempt': attempt, 'stage': stage, 'wall_time': time.monotonic(), 'world_time': current['time'], 'state': current['state'], 'hp': current['hp'], 'player': current['player'], 'requested_keys': list(requested), 'npc': npc, 'greeted': bool(npc and current['greeted'].get(npc['id'])), 'bag_items': [item for item in current['pickups'] if npc and item.get('rescue_id') == npc['id']]}
                    with (args.evidence/'rescue-attempts.jsonl').open('a') as log:
                        log.write(json.dumps(packet, ensure_ascii=False)+'\n')
                    return packet

                def require_live(current, stage, selected=None, recover=False):
                    rescue_trace(stage, current, selected)
                    if current['hp'] <= 0 or current['state'] in ['dying', 'dead']:
                        npc = next((n for n in current['npcs'] if selected and n['id'] == selected['id']), None)
                        contact_known = bool(npc and (current['greeted'].get(npc['id']) or npc['phase'] in ['thanks', 'departed']))
                        if recover and not contact_known:
                            raise PrecontactDeath(stage, current, selected)
                        raise AssertionError(('Live hero required after confirmed NPC contact', stage, current))
                    assert current['state'] == 'playing' and not current['menu'], ('Rescue action is not available', stage, current)

                def rescue_check(condition, label):
                    # Retries keep their full attempt trace. Rechecking an
                    # already-proved contract must still fail if it regresses,
                    # without counting the same product assertion twice.
                    assert condition, label
                    if label not in checks:
                        check(condition, label)

                def move_and_defend(current, direction, allow_grenade):
                    global last_jump
                    x, y = current['player']
                    aim_high = [e for e in current['enemies'] if
                                abs(e['x'] - x) < 290 and e['y'] < y - 42]
                    nearest = min(aim_high, key=lambda e: abs(e['x'] - x), default=None)
                    if nearest:
                        dx = nearest['x'] - x
                        commands = ['f', 'w'] if abs(dx) < 85 else ['f', 'w', 'd' if dx > 0 else 'a']
                    else:
                        commands = ['f', direction]
                    keys(commands)
                    gap = any(0 < pit[0] - x < 160 for pit in current['pits'])
                    danger = any(math.hypot(b[0] - x, b[1] - (y - 37)) < 95 for b in current['bullets'])
                    if current['grounded'] and (gap or danger) and current['time'] - last_jump > .70:
                        page.keyboard.press('Space')
                        last_jump = current['time']
                    if allow_grenade and current['grenades'] and not current['grenade_throw']['phase'] and nearest and abs(nearest['x'] - x) < 125:
                        page.keyboard.press('g')
                    return commands

                while True:
                    target = None
                    try:
                        # Held Fire actually frees ropes, then keeps the hero
                        # defended while reaching a new, uncontacted free NPC.
                        keys(['f', 'd'])
                        deadline = time.monotonic()+90
                        while time.monotonic() < deadline:
                            current = campaign()
                            require_live(current, 'search', recover=True)
                            x, y = current['player']
                            move_and_defend(current, 'd', allow_grenade=x<2750.)
                            free = [n for n in current['npcs'] if n['freed'] and n['phase'] == 'free' and not n['secret']
                                    and not current['awarded'].get(n['id']+':gift') and abs(n['y']-y) < 70 and abs(n['x']-x)<500]
                            target = min(free, key=lambda n: abs(n['x']-x), default=None)
                            if target:
                                keys([]); rescue_trace('free_candidate', current, target); break
                            page.wait_for_timeout(60)
                        assert target, 'No projectile-freed captive was reached by ordinary controls'
                        require_live(campaign(), 'freed_before_contact', target, recover=True)
                        rescue_check(campaign()['rescue_time'] == 0, 'A held gunshot frees a real captive without starting the knife clip')
                        page.wait_for_timeout(300)
                        current = campaign()
                        require_live(current, 'walking_before_contact', target, recover=True)
                        rescue_check(not current['awarded'].get(target['id']+':gift'), 'Freed NPC grants no gift before hero contact')
                        moved = next(n for n in current['npcs'] if n['id'] == target['id'])
                        rescue_check(moved['x'] != target['x'], 'The freed NPC actually walks before the hero approaches')
                        page.screenshot(path=str(args.evidence/'projectile-freed-walking.png'))
                        deadline = time.monotonic()+15
                        contacted = None
                        while time.monotonic() < deadline:
                            current = campaign()
                            require_live(current, 'approach_contact', target, recover=True)
                            npc = next(n for n in current['npcs'] if n['id'] == target['id'])
                            if npc['phase'] == 'thanks' and current['greeted'].get(target['id']):
                                contacted = current; keys([]); break
                            assert npc['phase'] == 'free', ('Expected a newly freed, uncontacted NPC', npc)
                            x, y = current['player']
                            wanted = move_and_defend(current, 'd' if npc['x'] > x else 'a', allow_grenade=False)
                            rescue_trace('approach_input', current, target, wanted)
                            page.wait_for_timeout(40)
                        current = campaign()
                        require_live(current, 'contact_deadline', target, recover=contacted is None)
                        assert contacted, ('Actual live NPC contact was not acknowledged; no bag wait is valid', current)
                        (args.evidence/'rescue-live-contact.json').write_text(json.dumps(contacted, ensure_ascii=False, indent=2)+'\n')
                        rescue_attempts.append({'attempt': attempt, 'outcome': 'live_contact', 'npc': target['id'], 'hp': contacted['hp'], 'world_time': contacted['time']})
                        break
                    except PrecontactDeath as death:
                        stage, dead, failed_target = death.args
                        # Only a proven death BEFORE valid contact is retried.
                        # Preserve it before releasing input or using real UI.
                        event = {'attempt': attempt, 'stage': stage, 'outcome': 'proven_death_before_contact', 'json_phase': 'before-input-cleanup', 'screenshot_phase': 'after-input-cleanup', 'state': dead, 'target': failed_target}
                        (args.evidence/('rescue-attempt-%d-death.json' % attempt)).write_text(json.dumps(event, ensure_ascii=False, indent=2)+'\n')
                        rescue_attempts.append({'attempt': attempt, 'outcome': event['outcome'], 'stage': stage, 'hp': dead['hp']})
                        keys([])
                        page.screenshot(path=str(args.evidence/('rescue-attempt-%d-death.png' % attempt)))
                        assert retries < 8, ('Rescue approach exceeded the bounded lives budget', dead)
                        resumed = page.wait_for_function("""() => {
                            const d = JSON.parse(document.querySelector('canvas').dataset.campaign);
                            return (d.menu === 'continue_offer' || (d.state === 'playing' && d.hp === 1)) && d.ui_ready ? d : false;
                        }""", timeout=15000).json_value()
                        if resumed['menu'] == 'continue_offer':
                            tap('ArcadeContinue', in_campaign=True)
                            page.wait_for_timeout(415)
                            tap('ArcadeConfirmHero', in_campaign=True)
                            page.wait_for_function("()=>{const d=JSON.parse(document.querySelector('canvas').dataset.campaign);return d.state==='playing' && d.hp===1 && d.ui_ready}",timeout=15000)
                        retries += 1; attempt += 1
                        canvas.focus()


                # Only this same living hero's confirmed THANKS phase permits
                # crossing away and waiting for the physical bag item. Missing
                # handoff while alive stays a failure, never a retry.
                npc = next(n for n in contacted['npcs'] if n['id'] == target['id'])
                cross = 'd' if int(npc['facing']) < 0 else 'a'
                side = 1 if cross == 'd' else -1
                keys([cross])
                deadline = time.monotonic()+8
                crossed = False
                while time.monotonic() < deadline:
                    current = campaign(); require_live(current, 'cross_after_contact', target)
                    npc = next(n for n in current['npcs'] if n['id'] == target['id'])
                    assert npc['phase'] in ['thanks', 'departed'] and current['greeted'].get(target['id']), ('Contact acknowledgment was lost', npc)
                    if (current['player'][0]-npc['x'])*side > 75:
                        crossed = True; break
                    page.wait_for_timeout(40)
                assert crossed, 'Live hero did not cross away from the acknowledged NPC'
                keys([])
                deadline = time.monotonic()+15
                dropped = None
                while time.monotonic() < deadline:
                    current = campaign(); require_live(current, 'await_actual_bag', target)
                    dropped = next((item for item in current['pickups'] if item.get('rescue_id') == target['id'] and item.get('from_bag')), None)
                    if dropped: break
                    page.wait_for_timeout(50)
                assert dropped, ('Alive, contacted NPC did not produce its actual bag item', current)
                check(not current['awarded'].get(target['id']+':gift'), 'The bag produces a visible world item without remotely granting its power-up')
                page.screenshot(path=str(args.evidence/'bag-item-before-contact.png'))
                deadline = time.monotonic()+15
                while time.monotonic() < deadline:
                    current = campaign(); require_live(current, 'approach_dropped_item', target)
                    if current['awarded'].get(target['id']+':gift'): break
                    item = next(item for item in current['pickups'] if item.get('rescue_id') == target['id'])
                    if current.get('weapon_offer',{}).get('id') == item['id']:
                        keys([]);page.keyboard.press('e');page.wait_for_timeout(150);continue
                    keys(['d'] if item['x'] > current['player'][0] else ['a'])
                    page.wait_for_timeout(40)
                keys([])
                page.wait_for_function("id=>JSON.parse(document.querySelector('canvas').dataset.campaign).awarded[id+':gift']===true", arg=target['id'], timeout=5000)
                saved = page.evaluate("JSON.parse(localStorage.getItem('aion.campaign.v1'))")
                check(saved['awarded'].get(target['id']+':gift') and saved['taken'].get(target['id']+':supply'), 'Actual dropped-item contact applies the power-up and persists it once')
                observations['rescued_npc'] = target['id']
                observations['rescue_reentries'] = retries
                page.screenshot(path=str(args.evidence/'contact-thanks-gift.png'))
            observations['campaign_final'] = campaign()
            page.screenshot(path=str(args.evidence/'campaign-final.png'))

        check(not errors, 'No uncaught browser or Godot script errors in the tested ordinary-input flow')
        report = {
            'checks': checks, 'errors': errors, 'browser': args.browser, 'locale': args.locale,
            'scenario': args.scenario, 'large_text': args.large_text, 'scope': 'Real exported game with ordinary user input; emulated viewports/touch and synthetic Gamepad API, not physical hardware.',
            'build': page.evaluate("fetch('build.json').then(response=>response.json()).then(value=>value.build)"),
            'observations': observations,
        }
        (args.evidence/'forge-results.json').write_text(json.dumps(report, ensure_ascii=False, indent=2)+'\n')
    except Exception as error:
        # Preserve the checked packet and live state before releasing keys.
        # Cleanup may change grounded/aim state and is recorded separately.
        try:
            failure = {'error': str(error), 'phase': 'before-input-cleanup', 'front': front(), 'campaign': campaign(), 'canvas': raw(), 'errors': errors, 'passed_checks': checks, 'observations': observations}
            (args.evidence/'failure.json').write_text(json.dumps(failure, ensure_ascii=False, indent=2)+'\n')
            page.screenshot(path=str(args.evidence/'failure.png'))
        except Exception:
            pass
        keys([])
        try:
            (args.evidence/'failure-after-cleanup.json').write_text(json.dumps({'phase': 'after-input-cleanup', 'campaign': campaign(), 'canvas': raw()}, ensure_ascii=False, indent=2)+'\n')
        except Exception:
            pass
        raise
    finally:
        keys([])
        (args.evidence/'console.json').write_text(json.dumps(console, ensure_ascii=False, indent=2)+'\n')
        context.close()
        browser.close()

print(len(checks), 'ordinary-input Forge checks passed', flush=True)
