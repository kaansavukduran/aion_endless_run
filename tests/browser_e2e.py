"""Exercise the exported game through the canvas and real keyboard/pointer input.

Serve build/web on localhost:8765 first. Screenshots go to a caller-owned folder.
Requires Playwright Chromium. No game state is mutated through JavaScript.
"""
import argparse
import json
from pathlib import Path
from playwright.sync_api import sync_playwright

parser = argparse.ArgumentParser()
parser.add_argument('--url', default='http://127.0.0.1:8765')
parser.add_argument('--evidence', default='work/evidence')
args = parser.parse_args()
evidence = Path(args.evidence)
evidence.mkdir(parents=True, exist_ok=True)
results = []

with sync_playwright() as playwright:
    browser = playwright.chromium.launch(headless=True, args=['--no-sandbox', '--enable-unsafe-swiftshader'])
    context = browser.new_context(viewport={'width': 1152, 'height': 648}, locale='tr-TR')
    page = context.new_page()
    errors = []
    page.on('pageerror', lambda error: errors.append(str(error)))
    page.goto(args.url)
    page.wait_for_selector('canvas[data-state="ready"]', timeout=60000)
    canvas = page.locator('canvas')

    def check(value, message):
        assert value, message
        results.append(message)

    def wait_state(value):
        page.wait_for_selector(f'canvas[data-state="{value}"]')

    check(canvas.get_attribute('data-page') == 'main', 'Actual exported entry opens main menu')
    check(canvas.get_attribute('lang') == 'tr', 'Device language chooses Turkish')
    page.screenshot(path=str(evidence / '01-menu-tr.png'))
    page.keyboard.press('Space')
    wait_state('running')
    page.keyboard.press('Space')
    page.wait_for_selector('canvas[data-airborne="true"]')
    check(True, 'Space starts and jumps in the real exported game')
    page.wait_for_timeout(120)
    page.screenshot(path=str(evidence / '02-jump.png'))
    page.keyboard.press('Escape')
    wait_state('paused')
    score = canvas.get_attribute('data-score')
    page.wait_for_timeout(400)
    check(canvas.get_attribute('data-score') == score, 'Esc freezes score and opens pause menu')
    page.mouse.click(560, 325)
    page.wait_for_selector('canvas[data-page="characters"]')
    page.screenshot(path=str(evidence / '03-characters.png'))
    # Companion choice uses actual visible select buttons; no test-only state API.
    page.mouse.click(820, 360)
    page.wait_for_selector('canvas[data-character="owl"]')
    check(True, 'Owl is selectable through the character menu')
    page.keyboard.press('Escape')
    page.wait_for_selector('canvas[data-page="paused"]')
    page.keyboard.press('Escape')
    wait_state('running')
    check(canvas.get_attribute('data-character') == 'owl', 'Resume retains chosen character and open run')
    page.wait_for_timeout(850)
    page.mouse.click(250, 250)
    page.wait_for_selector('canvas[data-airborne="true"]')
    check(True, 'Pointer/tap control jumps')
    page.keyboard.press('Escape')
    wait_state('paused')
    page.mouse.click(560, 445)
    page.wait_for_selector('canvas[data-page="settings"]')
    page.screenshot(path=str(evidence / '04-settings-tr.png'))
    page.mouse.click(695, 265)
    page.wait_for_selector('canvas[lang="en"]')
    check(canvas.get_attribute('data-page') == 'settings', 'Language applies immediately without leaving settings')
    page.screenshot(path=str(evidence / '05-settings-en.png'))
    page.keyboard.press('Escape')
    page.keyboard.press('Escape')
    wait_state('running')
    context.set_offline(True)
    before = int(canvas.get_attribute('data-score'))
    page.wait_for_timeout(500)
    check(int(canvas.get_attribute('data-score')) >= before, 'Running game continues with network disabled')
    page.wait_for_selector('canvas[data-page="finished"]', timeout=15000)
    check(canvas.get_attribute('data-state') in ['ice', 'fire'], 'Real collision reaches animated result screen offline')
    page.screenshot(path=str(evidence / '06-result-offline.png'))
    context.set_offline(False)
    page.reload()
    page.wait_for_selector('canvas[data-state="ready"]', timeout=60000)
    check(canvas.get_attribute('lang') == 'en' and canvas.get_attribute('data-character') == 'owl', 'Preferences persist across reload')
    page.set_viewport_size({'width': 390, 'height': 844})
    page.wait_for_timeout(800)
    page.screenshot(path=str(evidence / '07-phone-portrait.png'))
    page.set_viewport_size({'width': 844, 'height': 390})
    page.wait_for_timeout(500)
    page.screenshot(path=str(evidence / '08-phone-landscape.png'))
    check(not errors, 'No uncaught browser errors')
    browser.close()

(evidence / 'browser-results.json').write_text(json.dumps(results, indent=2, ensure_ascii=False))
print(f'{len(results)} browser checks passed')
