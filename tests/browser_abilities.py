"""Real input tests for the character abilities. Reads state, never injects it."""
import argparse
import json
import time
from pathlib import Path
from playwright.sync_api import sync_playwright

parser = argparse.ArgumentParser()
parser.add_argument('--url', default='http://127.0.0.1:8766')
parser.add_argument('--evidence', default='work/ability-evidence')
args = parser.parse_args()
out = Path(args.evidence)
out.mkdir(parents=True, exist_ok=True)
results = []

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True, args=['--no-sandbox', '--enable-unsafe-swiftshader'])
    context = browser.new_context(viewport={'width': 1152, 'height': 648}, locale='tr-TR')
    page = None

    def check(value, message):
        assert value, message
        results.append(message)

    def game(character):
        global page
        if page:
            page.close()
        page = context.new_page()
        page.goto(args.url)
        page.wait_for_selector('canvas[data-state="ready"]', timeout=60000)
        canvas = page.locator('canvas')
        if canvas.get_attribute('data-character') != character:
            page.mouse.click(850, 425)
            page.wait_for_selector('canvas[data-page="characters"]')
            x, y = {'aion': (420, 350), 'owl': (820, 350), 'wolf': (420, 500), 'sheep': (820, 500)}[character]
            page.mouse.click(x, y)
            page.wait_for_selector(f'canvas[data-character="{character}"]')
            page.keyboard.press('Escape')
        page.keyboard.press('Space')
        page.wait_for_selector('canvas[data-state="running"]')
        return canvas

    canvas = game('aion')
    page.keyboard.press('Space')
    page.wait_for_selector('canvas[data-jumps="1"]')
    page.wait_for_timeout(120)
    page.keyboard.press('Space')
    page.wait_for_selector('canvas[data-jumps="2"]')
    check(canvas.get_attribute('data-airborne') == 'true', 'Aion performs the second jump in mid-air')
    page.keyboard.press('Space')
    page.wait_for_timeout(60)
    check(canvas.get_attribute('data-jumps') == '2', 'Third press does not grant a third jump')
    page.screenshot(path=str(out / 'aion-double-jump.png'))
    page.wait_for_selector('canvas[data-airborne="false"]')
    page.keyboard.press('Space')
    page.wait_for_selector('canvas[data-jumps="1"]')
    check(True, 'Landing replenishes the double jump')

    canvas = game('owl')
    page.keyboard.down('Space')
    page.wait_for_selector('canvas[data-gliding="true"]')
    check(canvas.get_attribute('data-jumps') == '1' and canvas.get_attribute('data-sprite-row') == '6', 'Owl uses one jump and the new wing/glide frames')
    page.screenshot(path=str(out / 'owl-glide.png'))
    page.keyboard.up('Space')
    page.wait_for_selector('canvas[data-gliding="false"]')
    check(True, 'Releasing the key exits glide')

    # Catch an actual spawned updraft using only the game's normal controls.
    caught = False
    started = time.monotonic()
    while time.monotonic() - started < 22:
        if canvas.get_attribute('data-state') != 'running':
            break
        if canvas.get_attribute('data-riding-gust') == 'true':
            caught = True
            break
        gust = float(canvas.get_attribute('data-next-gust'))
        width = float(canvas.get_attribute('data-gust-width'))
        obstacle = float(canvas.get_attribute('data-next-obstacle'))
        if canvas.get_attribute('data-airborne') == 'false':
            page.keyboard.up('Space')
            if (gust > 0 and abs(gust - 196) < width / 2 + 155) or 35 < obstacle - 196 < 180:
                page.keyboard.down('Space')
        page.wait_for_timeout(20)
    check(caught, 'A naturally spawned visible updraft catches the held owl glide')
    catch_y = float(canvas.get_attribute('data-player-y'))
    page.wait_for_function("limit => Number(document.querySelector('canvas').dataset.playerY) < limit", arg=catch_y-8, timeout=3000)
    check(canvas.get_attribute('data-action-sheet') == 'true' and canvas.get_attribute('data-sprite-row') == '6', 'Wind gives real upward travel and uses the new wingstroke atlas')
    page.screenshot(path=str(out / 'owl-updraft-rise.png'))
    page.keyboard.up('Space')
    page.wait_for_selector('canvas[data-riding-gust="false"][data-gliding="false"]')
    check(True, 'Releasing held glide also releases updraft lift')

    canvas = game('wolf')
    page.keyboard.down('Shift')
    page.wait_for_selector('canvas[data-boosting="true"]')
    check(canvas.get_attribute('data-sprite-row') == '6', 'Shift boosts the wolf with actual right-facing run frames')
    wind_before = canvas.get_attribute('data-wind-head')
    page.screenshot(path=str(out / 'wolf-boost.png'))
    page.wait_for_function("before => document.querySelector('canvas').dataset.windHead !== before", arg=wind_before)
    check(canvas.get_attribute('data-action-sheet') == 'true', 'Wolf uses new dash poses with moving wind geometry')
    page.screenshot(path=str(out / 'wolf-wind-flow.png'))
    page.keyboard.up('Shift')
    page.wait_for_selector('canvas[data-boosting="false"]')
    check(True, 'Releasing Shift stops boost')
    page.mouse.move(196, 480)
    page.mouse.down()
    page.wait_for_selector('canvas[data-boosting="true"]')
    page.mouse.move(700, 200)
    page.mouse.up()
    page.wait_for_selector('canvas[data-boosting="false"]')
    check(True, 'Pointer hold on the wolf releases correctly away from the character')

    canvas = game('sheep')
    found = False
    for attempt in range(3):
        if attempt:
            page.wait_for_selector('canvas[data-page="finished"]', timeout=10000)
            page.mouse.click(560, 375)
            page.wait_for_selector('canvas[data-state="running"]')
        started = time.monotonic()
        while time.monotonic() - started < 45:
            if canvas.get_attribute('data-state') != 'running':
                break
            if int(canvas.get_attribute('data-flock')) == 3:
                found = True
                page.screenshot(path=str(out / 'sheep-flock-three.png'))
                break
            obstacle = float(canvas.get_attribute('data-next-obstacle'))
            if canvas.get_attribute('data-airborne') == 'false' and 35 < obstacle - 196 < 165:
                page.keyboard.press('Space')
            page.wait_for_timeout(30)
        if found: break
        print('Flock attempt', attempt + 1, 'state', canvas.get_attribute('data-state'), 'flock', canvas.get_attribute('data-flock'), 'score', canvas.get_attribute('data-score'), flush=True)
        page.screenshot(path=str(out / f'flock-attempt-{attempt+1}.png'))
    check(found, 'Real ground pickups build a visible flock of three')
    # Recruitment may happen near the end of a jump. Wait for that whole wave
    # to settle before measuring a new Space press, while still dodging hazards.
    settled = False
    started = time.monotonic()
    while time.monotonic() - started < 12:
        obstacle = float(canvas.get_attribute('data-next-obstacle'))
        if canvas.get_attribute('data-airborne') == 'false':
            if float(canvas.get_attribute('data-follower-1-y')) > -0.01 and float(canvas.get_attribute('data-follower-2-y')) > -0.01 and (obstacle < 0 or obstacle - 196 > 240):
                settled = True
                break
            if 35 < obstacle - 196 < 165: page.keyboard.press('Space')
        page.wait_for_timeout(15)
    assert settled, 'Could not find a settled flock for the staggered-jump check'
    # Observe complete render updates, avoiding several protocol round-trips
    # that can outlast the 0.2-second spatial gap on a software GPU.
    page.evaluate("""() => {
      window.flockTimeline = [];
      window.flockObserver = new MutationObserver(() => {
        const c = document.querySelector('canvas');
        window.flockTimeline.push({y:Number(c.getAttribute('data-player-y')), second:Number(c.getAttribute('data-follower-1-y')), third:Number(c.getAttribute('data-follower-2-y')), count:Number(c.getAttribute('data-flock'))});
      });
      window.flockObserver.observe(document.querySelector('canvas'), {attributes:true, attributeFilter:['data-player-y','data-follower-1-y','data-follower-2-y']});
    }""")
    page.keyboard.press('Space')
    page.wait_for_function("() => Number(document.querySelector('canvas').getAttribute('data-follower-2-y')) < -3")
    timeline = page.evaluate('window.flockObserver.disconnect(); window.flockTimeline')
    (out/'flock-timeline.json').write_text(json.dumps(timeline, indent=2))
    check(any(p['y'] < -3 and p['second'] > -1 and p['third'] > -1 and p['count'] == 3 for p in timeline), 'Space launches only the leading sheep')
    check(any(p['second'] < -3 and p['third'] > -1 and p['count'] == 3 for p in timeline), 'Second sheep takes off while the third is still running on the ground')
    check(any(p['third'] < -3 and p['count'] == 3 for p in timeline), 'Third sheep takes off last along the same world path')
    page.screenshot(path=str(out / 'sheep-delayed-jump.png'))
    page.wait_for_selector('canvas[data-flock="2"]', timeout=10000)
    check(canvas.get_attribute('data-state') == 'running', 'One sheep absorbs a real obstacle hit and the run continues')
    page.screenshot(path=str(out / 'sheep-life-used.png'))
    page.close()
    page = None
    context.close()

    # Real Chromium touch events, including two simultaneously held contacts.
    mobile = browser.new_context(viewport={'width': 844, 'height': 390}, has_touch=True, is_mobile=True, locale='tr-TR')
    page = mobile.new_page()
    page.goto(args.url)
    page.wait_for_selector('canvas[data-state="ready"]', timeout=60000)
    canvas = page.locator('canvas')
    page.mouse.click(675, 256)
    page.wait_for_selector('canvas[data-page="characters"]')
    page.mouse.click(328, 301)
    page.wait_for_selector('canvas[data-character="wolf"]')
    page.keyboard.press('Escape')
    page.keyboard.press('Space')
    cdp = mobile.new_cdp_session(page)
    first = {'x': 118, 'y': 288, 'id': 0}
    second = {'x': 440, 'y': 280, 'id': 1}
    cdp.send('Input.dispatchTouchEvent', {'type': 'touchStart', 'touchPoints': [first]})
    page.wait_for_selector('canvas[data-boosting="true"]')
    cdp.send('Input.dispatchTouchEvent', {'type': 'touchStart', 'touchPoints': [first, second]})
    page.wait_for_selector('canvas[data-airborne="true"]')
    check(canvas.get_attribute('data-boosting') == 'true', 'Two mobile fingers can boost on the wolf and jump elsewhere')
    page.screenshot(path=str(out / 'mobile-wolf-boost-jump.png'))
    cdp.send('Input.dispatchTouchEvent', {'type': 'touchEnd', 'touchPoints': []})
    page.wait_for_selector('canvas[data-boosting="false"]')
    check(True, 'Ending native touch contacts clears boost')
    browser.close()

(out / 'ability-results.json').write_text(json.dumps(results, indent=2, ensure_ascii=False))
print(f'{len(results)} ability browser checks passed')
