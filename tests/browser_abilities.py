"""Real input tests for the 0.2 character abilities. Reads state, never injects it."""
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
    page.screenshot(path=str(out / 'aion-double-jump.png'))
    page.keyboard.press('Space')
    page.wait_for_timeout(150)
    check(canvas.get_attribute('data-jumps') == '2', 'Third press does not grant a third jump')
    page.wait_for_selector('canvas[data-airborne="false"]')
    page.keyboard.press('Space')
    page.wait_for_selector('canvas[data-jumps="1"]')
    check(True, 'Landing replenishes the double jump')

    canvas = game('owl')
    page.keyboard.down('Space')
    page.wait_for_selector('canvas[data-gliding="true"]')
    check(canvas.get_attribute('data-jumps') == '1' and canvas.get_attribute('data-sprite-row') == '5', 'Owl uses one jump and the new wing/glide frames')
    page.screenshot(path=str(out / 'owl-glide.png'))
    page.keyboard.up('Space')
    page.wait_for_selector('canvas[data-gliding="false"]')
    check(True, 'Releasing the key exits glide')

    canvas = game('wolf')
    page.keyboard.down('Shift')
    page.wait_for_selector('canvas[data-boosting="true"]')
    check(canvas.get_attribute('data-sprite-row') == '0', 'Shift boosts the wolf with actual right-facing run frames')
    page.screenshot(path=str(out / 'wolf-boost.png'))
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
