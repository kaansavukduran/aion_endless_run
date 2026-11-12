"""Exercise real previous-release -> current PWA migration and a subsequent hot update.

Uses a real HTTP server, CacheStorage, ServiceWorker and IndexedDB. No mocked
network, state injection, cache bypass, unregister or storage clearing.
"""
import argparse
import hashlib
import re
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
current_meta = json.loads((args.current/'build.json').read_text())
version = current_meta['version']

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
        def ui_click(name=None,text=None):
            page.wait_for_selector('canvas[data-ui-ready="true"]')
            v=page.locator('canvas').evaluate('c=>({...c.dataset})');b=next(b for b in json.loads(v['ui']) if (b['name']==name if name else text in b['text']))
            t=json.loads(v['screenTransform']);r=page.locator('canvas').bounding_box();x=b['x']+b['w']/2;y=b['y']+b['h']/2
            page.mouse.click(r['x']+(t[0]*x+t[2]*y+t[4])/float(v['rawWidth'])*r['width'],r['y']+(t[1]*x+t[3]*y+t[5])/float(v['rawHeight'])*r['height'])
        # Since 0.6 selection is deliberately locked after starting a run.
        ui_click(name='StartSelect_owl')
        page.wait_for_selector('canvas[data-character="owl"]')
        ui_click(name='LanguageMenu')
        page.wait_for_selector('canvas[data-language-picker="true"]')
        ui_click(name='Language_en')
        page.wait_for_selector('canvas[lang="en"]')
        page.keyboard.press('Space')
        page.wait_for_selector('canvas[data-state="running"]')
        page.wait_for_timeout(1000)
        page.keyboard.press('Escape')
        page.wait_for_selector('canvas[data-state="paused"]')
        saved_score = int(page.locator('canvas').get_attribute('data-score'))
        page.wait_for_timeout(2200)  # Real Godot IDBFS sync, not a test fixture.
        context.set_offline(True)
        page.reload()
        ready()
        check(page.locator('canvas').get_attribute('data-character') == 'owl', 'Legacy PWA really opens offline with its saved owl')
        legacy_version = page.locator('canvas').get_attribute('data-version')
        legacy_build = page.evaluate('window.AION_BUILD?.build')
        check(legacy_version != version or legacy_build != current_meta['build'], 'Reproduced the previous export before migration')
        page.screenshot(path=str(args.evidence/'legacy-offline.png'))
        context.set_offline(False)
        server_root[0] = args.current.resolve()
        # What the browser's native registration update check does on revisit.
        # This updates the real old registration, without unregistering it.
        page.evaluate('navigator.serviceWorker.getRegistration().then(r => r.update())')
        if legacy_version is not None:
            page.wait_for_selector('#aion-update', timeout=90000)
            page.locator('#aion-update').click()
        # Web-only fixes keep the game version; wait for the new shell identity.
        page.wait_for_function('(build) => window.AION_BUILD?.build === build', arg=current_meta['build'], timeout=90000)
        page.wait_for_selector(f'canvas[data-version="{version}"][data-state="ready"]', timeout=90000)
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
        check(canvas.get_attribute('data-version') == version, 'New full export reloads offline after migration')
        page.screenshot(path=str(args.evidence/'upgraded-offline.png'))
        context.set_offline(False)
        # Simulate the next deployment with identical game bytes but a new shell
        # identity; this exercises update UX without a test API inside the game.
        future = tmp / 'future'
        shutil.copytree(args.current, future)
        original_build = json.loads((future/'build.json').read_text())['build']
        for name in ['index.html','index.service.worker.js']:
            text = (future/name).read_text().replace("const BUILD = '"+original_build+"'", "const BUILD = 'test-next-build'").replace("const VERSION = '"+version+"'", "const VERSION = '"+version+"-next-test'")
            (future/name).write_text(text)
        # The future shell is a self-consistent deploy, including its HTML hash.
        worker = future/'index.service.worker.js'
        text = worker.read_text()
        if 'const INFO = ' in text:
            info = json.loads(re.search(r'const INFO = (\{.*?\});',text)[1])
            info['index.html'] = {'bytes':(future/'index.html').stat().st_size,'sha256':hashlib.sha256((future/'index.html').read_bytes()).hexdigest()}
            text = re.sub(r'const INFO = \{.*?\};','const INFO = '+json.dumps(info)+';',text)
            worker.write_text(text)
        server_root[0] = future
        page.keyboard.press('Space')
        page.wait_for_selector('canvas[data-state="running"]')
        current_url = page.url
        page.evaluate('navigator.serviceWorker.getRegistration().then(r => r.update())')
        page.wait_for_selector('#aion-update', timeout=90000)
        check(page.url == current_url and canvas.get_attribute('data-state') == 'running', 'Subsequent update offers a button without interrupting an active run')
        page.screenshot(path=str(args.evidence/'update-available.png'))
        page.evaluate("""()=>{sessionStorage.removeItem('aion-test-paused');new MutationObserver(()=>{if(document.querySelector('canvas').dataset.state==='paused')sessionStorage.setItem('aion-test-paused','yes')}).observe(document.querySelector('canvas'),{attributes:true})}""")
        page.locator('#aion-update').click()
        ready()
        print('UPDATE_READBACK',{'paused_observed':page.evaluate("sessionStorage.getItem('aion-test-paused')"),'url':page.url,'character':canvas.get_attribute('data-character'),'build':page.evaluate('window.AION_BUILD')},flush=True)
        check(page.evaluate("sessionStorage.getItem('aion-test-paused')")=='yes' and 'test-next-build' in page.url and canvas.get_attribute('data-character') == 'owl', 'Update button saves, pauses and opens the new shell with preferences intact')
        check(not errors, 'No uncaught browser errors during legacy migration or offline updates')
        browser.close()
    server.shutdown()
(args.evidence/'upgrade-results.json').write_text(json.dumps(results, indent=2)+'\n')
print(f'{len(results)} real PWA upgrade checks passed')
