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
            for hero in ['aion', 'sheep', 'rabbit', 'eren']:
                tap('ChooseHero')
                for _ in range(12):
                    if any(button['name'] == 'Select_'+hero for button in front_buttons()):
                        break
                    tap('NextPage')
                tap('Select_'+hero)
                check(not any(button['name'] in ['Select_owl', 'Select_wolf'] for button in front_buttons()), 'Retired owl/wolf are not offered as playable choices')
                # Selection may rebuild and repaginate the current card.
                for _ in range(12):
                    if any(button['name'] == 'ConfirmHero' for button in front_buttons()):
                        break
                    tap('NextPage')
                tap('ConfirmHero')
                ready()
                check(raw()['character'] == hero, 'Real character selection and confirmation: '+hero)
            if args.large_text:
                for _ in range(4):
                    if any(button['name'] == 'StartSelect_aion' for button in front_buttons()):
                        break
                    tap('RosterPrevious')
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
            page.evaluate('qaPadConnect(true)')
            page.wait_for_timeout(200)
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

            aim_samples = []
            directions = [(['d'], [1, 0]), (['d', 'w'], [1, -1]), (['w'], [0, -1]), (['a', 'w'], [-1, -1]), (['a'], [-1, 0]), (['a', 's'], [-1, 1]), (['s'], [0, 1]), (['d', 's'], [1, 1])]
            for index, (inputs, target) in enumerate(directions):
                # Down while grounded now means crouch. Exercise downward aim
                # during real airborne movement instead of accepting a changed
                # horizontal crouch shot as the old downward-aim assertion.
                if index in [0, 3, 6] or (target[1] > 0 and campaign().get('grounded')):
                    page.keyboard.press('Space')
                    if target[1] > 0:
                        page.wait_for_function("JSON.parse(document.querySelector('canvas').dataset.campaign).player[1]<-10", timeout=5000)
                shots = campaign()['shots']
                keys(inputs)
                page.wait_for_timeout(100)
                page.keyboard.down('f')
                page.wait_for_function("shots=>JSON.parse(document.querySelector('canvas').dataset.campaign).shots>shots", arg=shots, timeout=5000)
                data = campaign()
                length = math.hypot(*target)
                expected = [target[0]/length, target[1]/length]
                check(math.dist(data['aim'], expected) < .03, 'Actual keyboard aim and gun action: '+str(target))
                aim_samples.append({'keys': inputs, 'aim': data['aim'], 'shots': data['shots']})
                page.keyboard.up('f')
                keys([])
                page.wait_for_timeout(360)
            observations['keyboard_aim'] = aim_samples

            keys([])
            # Eight real combat aim checks leave the actor exposed to enemies.
            # A dead actor cannot satisfy an independent posture test. Retain
            # that state, then use the actual checkpoint action, without a
            # world setter, immunity or a hidden debug restart.
            precondition = campaign()
            observations['before_crouch_checkpoint'] = precondition
            if precondition['state'] == 'dying':
                page.wait_for_function("JSON.parse(document.querySelector('canvas').dataset.campaign).menu==='dead'", timeout=10000)
            if campaign().get('menu') == 'dead':
                tap('CampaignRetry', in_campaign=True)
            else:
                canvas.focus()
                page.keyboard.press('Escape')
                page.wait_for_function("JSON.parse(document.querySelector('canvas').dataset.campaign).menu==='paused'", timeout=10000)
                tap(text='Kontrol noktasından dene' if args.locale.startswith('tr') else 'Retry checkpoint', in_campaign=True)
            presentation_done()
            page.wait_for_function("()=>{const d=JSON.parse(document.querySelector('canvas').dataset.campaign);return d.state==='playing' && d.hp>0 && d.grounded && d.ui_ready}", timeout=15000)
            canvas.focus()
            check(True, 'Actual checkpoint UI supplies a living, actionable actor before the independent crouch test')
            before = campaign()
            keys(['s', 'd', 'f'])
            page.wait_for_function("before=>{const d=JSON.parse(document.querySelector('canvas').dataset.campaign);return d.crouching && d.player[0]>before.x+12 && d.shots>before.shots}", arg={'x': before['player'][0], 'shots': before['shots']}, timeout=10000)
            check(True, 'Down + movement + Fire reaches real crouch locomotion and a shot together')
            page.screenshot(path=str(args.evidence/'crouch-moving-fire.png'))
            keys([])
            page.wait_for_function("!JSON.parse(document.querySelector('canvas').dataset.campaign).crouching", timeout=5000)
            check(True, 'Releasing Down exits crouch without a stuck posture')

            if args.rescue:
                # Keep Fire held while approaching: no new contextual knife press
                # is issued near the target. Only an actual projectile can free it.
                keys(['f', 'd'])
                deadline = time.monotonic()+150
                target = None
                last_jump = 0.
                retries = 0
                while time.monotonic() < deadline:
                    data = campaign()
                    if data['menu'] == 'dead':
                        keys([])
                        assert retries < 3, ('Rescue approach exceeded ordinary checkpoint retries', data)
                        tap('CampaignRetry', in_campaign=True)
                        retries += 1
                        keys(['f', 'd'])
                        continue
                    x, y = data['player']
                    gap = any(0 < pit[0]-x < 160 for pit in data['pits'])
                    danger = any(math.hypot(bullet[0]-x, bullet[1]-(y-37)) < 120 for bullet in data.get('bullets', []))
                    if data.get('grounded') and (gap or danger) and time.monotonic()-last_jump > .75:
                        page.keyboard.press('Space')
                        last_jump = time.monotonic()
                    candidate = next((npc for npc in data['npcs'] if npc['freed'] and not npc['secret'] and not data['awarded'].get(npc['id']+':gift') and abs(npc['y']-y) < 25 and 95 < npc['x']-x < 500), None)
                    if candidate:
                        target = candidate
                        keys([])
                        break
                    page.wait_for_timeout(60)
                assert target, 'No projectile-freed captive was reached by ordinary controls'
                check(campaign()['rescue_time'] == 0, 'A held gunshot frees a real captive without starting the knife clip')
                before = campaign()
                page.wait_for_timeout(300)
                data = campaign()
                check(not data['awarded'].get(target['id']+':gift'), 'Freed NPC grants no gift before hero contact')
                moved = next(npc for npc in data['npcs'] if npc['id'] == target['id'])
                check(moved['x'] != target['x'], 'The freed NPC actually walks before the hero approaches')
                page.screenshot(path=str(args.evidence/'projectile-freed-walking.png'))
                deadline = time.monotonic()+15
                while time.monotonic() < deadline:
                    data = campaign()
                    npc = next(npc for npc in data['npcs'] if npc['id'] == target['id'])
                    if npc['phase'] == 'thanks' or data['awarded'].get(target['id']+':gift'):
                        keys([])
                        break
                    keys(['d'] if npc['x'] > data['player'][0] else ['a'])
                    if data.get('grounded') and any(0 < pit[0]-data['player'][0] < 160 for pit in data['pits']):
                        page.keyboard.press('Space')
                    page.wait_for_timeout(40)
                # The NPC now takes an item from her bag. Crossing to her other
                # side keeps the hero away from the thrown item's side, so this
                # explicitly proves that the thank-you timer itself pays nothing.
                npc = next(npc for npc in campaign()['npcs'] if npc['id'] == target['id'])
                cross = 'd' if int(npc['facing']) < 0 else 'a'
                keys([cross])
                page.wait_for_function("([id,side])=>{const d=JSON.parse(document.querySelector('canvas').dataset.campaign),n=d.npcs.find(n=>n.id===id);return (d.player[0]-n.x)*side>75}", arg=[target['id'], 1 if cross == 'd' else -1], timeout=8000)
                keys([])
                page.wait_for_function("id=>JSON.parse(document.querySelector('canvas').dataset.campaign).pickups.some(p=>p.rescue_id===id && p.from_bag)", arg=target['id'], timeout=15000)
                check(not campaign()['awarded'].get(target['id']+':gift'), 'The bag produces a visible world item without remotely granting its power-up')
                page.screenshot(path=str(args.evidence/'bag-item-before-contact.png'))
                deadline = time.monotonic()+15
                while time.monotonic() < deadline:
                    data = campaign()
                    if data['awarded'].get(target['id']+':gift'):
                        break
                    item = next(item for item in data['pickups'] if item.get('rescue_id') == target['id'])
                    keys(['d'] if item['x'] > data['player'][0] else ['a'])
                    page.wait_for_timeout(40)
                keys([])
                page.wait_for_function("id=>JSON.parse(document.querySelector('canvas').dataset.campaign).awarded[id+':gift']===true", arg=target['id'], timeout=5000)
                saved = page.evaluate("JSON.parse(localStorage.getItem('aion.campaign.v1'))")
                check(saved['awarded'].get(target['id']+':gift') and saved['taken'].get(target['id']+':supply'), 'Actual dropped-item contact applies the power-up and persists it once')
                observations['rescued_npc'] = target['id']
                observations['rescue_checkpoint_retries'] = retries
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
        keys([])
        try:
            page.screenshot(path=str(args.evidence/'failure.png'))
            (args.evidence/'failure.json').write_text(json.dumps({'error': str(error), 'front': front(), 'campaign': campaign(), 'canvas': raw(), 'errors': errors, 'passed_checks': checks}, ensure_ascii=False, indent=2)+'\n')
        except Exception:
            pass
        raise
    finally:
        (args.evidence/'console.json').write_text(json.dumps(console, ensure_ascii=False, indent=2)+'\n')
        context.close()
        browser.close()

print(len(checks), 'ordinary-input Forge checks passed', flush=True)
