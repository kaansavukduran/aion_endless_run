"""Exercise real 0.1 -> current PWA migration and a subsequent hot update.

Uses a real HTTP server, CacheStorage, ServiceWorker and IndexedDB. No mocked
network, state injection, cache bypass, unregister or storage clearing.
"""
import argparse
from functools import partial
import http.server
import json
from pathlib import Path
import shutil
import tarfile
import tempfile
import threading
from playwright.sync_api import sync_playwright

parser = argparse.ArgumentParser()
parser.add_argument('--legacy', required=True, type=Path)
parser.add_argument('--current', default='build/web', type=Path)
parser.add_argument('--evidence', default='work/upgrade-evidence', type=Path)
args = parser.parse_args()
args.evidence.mkdir(parents=True, exist_ok=True)
results = []

def check(value, message):
    assert value, message
    results.append(message)

with tempfile.TemporaryDirectory(prefix='aion-upgrade-') as tmp:
    tmp = Path(tmp)
    legacy = tmp / 'legacy'
    legacy.mkdir()
    with tarfile.open(args.legacy) as archive:
        archive.extractall(legacy, filter='data')
    server_root = [legacy]
    class Handler(http.server.SimpleHTTPRequestHandler):
        def __init__(self, *a, **kw):
            super().__init__(*a, directory=str(server_root[0]), **kw)
        def end_headers(self):
            self.send_header('Cache-Control', 'no-cache')
            super().end_headers()
        def log_message(self, *a): pass
    server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), Handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    url = 'http://127.0.0.1:' + str(server.server_port) + '/index.html'
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True, args=['--no-sandbox', '--enable-unsafe-swiftshader'])
        context = browser.new_context(viewport={'width':1152, 'height':648}, locale='tr-TR')
        page = context.new_page()
        errors = []
        page.on('pageerror', lambda e: errors.append(str(e)))
        def ready(): page.wait_for_selector('canvas[data-state="ready"]', timeout=90000)
        page.goto(url)
        ready()
        page.evaluate('navigator.serviceWorker.ready.then(() => true)')
        page.reload()  # Populate the legacy worker's large engine/PCK cache.
        ready()
        page.keyboard.press('Space')
        page.wait_for_selector('canvas[data-state="running"]')
        page.wait_for_timeout(1000)
        page.keyboard.press('Escape')
        page.wait_for_selector('canvas[data-state="paused"]')
        saved_score = int(page.locator('canvas').get_attribute('data-score'))
        page.mouse.click(560,325)
        page.wait_for_selector('canvas[data-page="characters"]')
        page.mouse.click(820,360)
        page.wait_for_selector('canvas[data-character="owl"]')
        page.keyboard.press('Escape')
        page.mouse.click(560,445)
        page.wait_for_selector('canvas[data-page="settings"]')
        page.mouse.click(695,265)
        page.wait_for_selector('canvas[lang="en"]')
        page.wait_for_timeout(2200)  # Real Godot IDBFS sync, not a test fixture.
        context.set_offline(True)
        page.reload()
        ready()
        check(page.locator('canvas').get_attribute('data-character') == 'owl', 'Legacy PWA really opens offline with its saved owl')
        check(page.locator('canvas').get_attribute('data-version') is None, 'Reproduced the legacy export before migration')
        page.screenshot(path=str(args.evidence/'legacy-offline.png'))
        context.set_offline(False)
        server_root[0] = args.current.resolve()
        # What the browser's native registration update check does on revisit.
        # This updates the real old registration, without unregistering it.
        page.evaluate('navigator.serviceWorker.getRegistration().then(r => r.update())')
        page.wait_for_selector('canvas[data-version="0.3.0"]', timeout=90000)
        check('build=' in page.url, 'Old cached shell migrates to the current build automatically')
        canvas = page.locator('canvas')
        check(canvas.get_attribute('data-character') == 'owl' and canvas.get_attribute('lang') == 'en', 'Migration preserves character and language in IndexedDB')
        check(int(canvas.get_attribute('data-best')) >= saved_score > 0, 'Migration preserves the earned best score')
        page.keyboard.press('Space')
        page.wait_for_selector('canvas[data-sprite-row="1"]')
        check(canvas.get_attribute('data-character') == 'owl', 'Migrated owl uses the actual running sprite row')
        page.keyboard.down('Space')
        page.wait_for_selector('canvas[data-gliding="true"][data-sprite-row="6"]')
        page.keyboard.up('Space')
        check(True, 'Migrated build supports the requested hold-to-glide input')
        page.keyboard.press('Escape')
        page.wait_for_selector('canvas[data-state="paused"]')
        page.wait_for_timeout(2200)
        context.set_offline(True)
        page.reload()
        ready()
        check(canvas.get_attribute('data-version') == '0.3.0', 'New full export reloads offline after migration')
        page.screenshot(path=str(args.evidence/'upgraded-offline.png'))
        context.set_offline(False)
        # Simulate the next deployment with identical game bytes but a new shell
        # identity; this exercises update UX without a test API inside the game.
        future = tmp / 'future'
        shutil.copytree(args.current, future)
        original_build = json.loads((future/'build.json').read_text())['build']
        for name in ['index.html','index.service.worker.js']:
            text = (future/name).read_text().replace("const BUILD = '"+original_build+"'", "const BUILD = 'test-next-build'").replace("const VERSION = '0.3.0'", "const VERSION = '0.3.1-test'")
            (future/name).write_text(text)
        server_root[0] = future
        page.keyboard.press('Space')
        page.wait_for_selector('canvas[data-state="running"]')
        current_url = page.url
        page.evaluate('navigator.serviceWorker.getRegistration().then(r => r.update())')
        page.wait_for_selector('#aion-update', timeout=90000)
        check(page.url == current_url and canvas.get_attribute('data-state') == 'running', 'Subsequent update offers a button without interrupting an active run')
        page.screenshot(path=str(args.evidence/'update-available.png'))
        page.locator('#aion-update').click()
        page.wait_for_selector('canvas[data-state="paused"]')
        ready()
        check('test-next-build' in page.url and canvas.get_attribute('data-character') == 'owl', 'Update button saves, pauses and opens the new shell with preferences intact')
        check(not errors, 'No uncaught browser errors during legacy migration or offline updates')
        browser.close()
    server.shutdown()
(args.evidence/'upgrade-results.json').write_text(json.dumps(results, indent=2)+'\n')
print(f'{len(results)} real PWA upgrade checks passed')
