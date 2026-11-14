"""Verify the actual public ground pixels and ordinary controls, without world setters."""
import argparse, collections, io, json, math, os
from pathlib import Path
from PIL import Image
from playwright.sync_api import sync_playwright

p = argparse.ArgumentParser()
p.add_argument('--browser', choices=['firefox', 'chromium'], default='chromium')
p.add_argument('--url', required=True)
p.add_argument('--expected-build', required=True)
p.add_argument('--evidence', type=Path, required=True)
a = p.parse_args()
a.evidence.mkdir(parents=True, exist_ok=True)
checks = []
errors = []

def check(ok, message):
    assert ok, message
    checks.append(message)
    print('PASS', message, flush=True)

with sync_playwright() as pw:
    if a.browser == 'firefox':
        browser = pw.firefox.launch(headless=False, env=dict(os.environ, DISPLAY=os.environ.get('DISPLAY', ':102'), XDG_CACHE_HOME=str(a.evidence/'cache'), XDG_CONFIG_HOME=str(a.evidence/'config'), MOZ_DISABLE_CONTENT_SANDBOX='1', LIBGL_ALWAYS_SOFTWARE='1'), firefox_user_prefs={'webgl.force-enabled': True, 'dom.w3c_touch_events.enabled': 1})
    else:
        browser = pw.chromium.launch(args=['--no-sandbox', '--enable-unsafe-swiftshader'])
    context = browser.new_context(viewport={'width': 1280, 'height': 720}, device_scale_factor=1, has_touch=True, locale='tr-TR')
    page = context.new_page()
    page.on('pageerror', lambda e: errors.append(str(e)))
    page.on('console', lambda m: errors.append(m.text) if 'SCRIPT ERROR' in m.text else None)
    page.goto(a.url, timeout=120000)
    page.wait_for_selector('canvas[data-state="ready"][data-ui-ready="true"]', timeout=120000)

    def data():
        return page.locator('canvas').evaluate('c=>({...c.dataset})')

    def xy(x, y):
        v = data()
        t = json.loads(v['screenTransform'])
        r = page.locator('canvas').bounding_box()
        return (r['x'] + (t[0]*x+t[2]*y+t[4])/float(v['rawWidth'])*r['width'], r['y'] + (t[1]*x+t[3]*y+t[5])/float(v['rawHeight'])*r['height'])

    def ui(name=None, text=None):
        page.wait_for_selector('canvas[data-ui-ready="true"]')
        b = next(b for b in json.loads(data()['ui']) if (b['name'] == name if name else b['text'] == text))
        page.touchscreen.tap(*xy(b['x']+b['w']/2, b['y']+b['h']/2))

    build = page.evaluate("fetch('build.json',{cache:'no-store'}).then(r=>r.json()).then(v=>({version:v.version,build:v.build}))")
    check(build['build'] == a.expected_build, 'The normal entry loads the expected public build')
    ui(name='StartSelect_aion')
    ui(name='StartRun')
    page.wait_for_selector('canvas[data-state="running"]')
    if any(b['text'] == 'Anladım · Devam et' for b in json.loads(data()['ui'])):
        ui(text='Anladım · Devam et')
    page.wait_for_function('Number(document.querySelector("canvas").dataset.worldTime)>.05')
    v = data()
    ground = float(v['groundY'])
    # In landscape the scene and UI share scale. Sample inside the first source row,
    # away from the actor shadow and all control/text overlays.
    cap_point = xy(650, ground+1)
    region_a = xy(400, ground+20)
    region_b = xy(650, ground+60)
    image = Image.open(io.BytesIO(page.screenshot(path=str(a.evidence/'landscape-running.png')))).convert('RGB')
    actual = image.getpixel(tuple(map(math.floor, cap_point)))
    night = (math.cos(float(v['worldTime'])*math.tau/72)+1)/2
    cap = (225, 177, 133)
    tint = (126, 134, 164)
    expected = tuple(c*(1+night*.32*(t/255-1)) for c, t in zip(cap, tint))
    check(max(abs(c-e) for c, e in zip(actual, expected)) < 5, 'Actual screenshot has the new sandstone walking rim, not the old flat road')
    colors = collections.Counter(image.getpixel((x, y)) for x in range(math.ceil(region_a[0]), math.floor(region_b[0]), 2) for y in range(math.ceil(region_a[1]), math.floor(region_b[1]), 2))
    check(sum(n >= 10 for n in colors.values()) >= 6, 'The actual floor contains material clusters, embedded stone and soil depth')
    shots = int(data()['bossShots'])
    page.keyboard.down('f')
    page.wait_for_function('(n)=>Number(document.querySelector("canvas").dataset.bossShots)>=n+2', arg=shots)
    page.keyboard.up('f')
    check(int(data()['bossShots']) >= shots+2, 'Ordinary held Fire continues while the new ground scrolls')
    before_pause = data()
    print('PRE_PAUSE', json.dumps({k:before_pause.get(k) for k in ['state','page','worldTime','score','character']}), flush=True)
    page.locator('canvas').focus()
    page.keyboard.press('Escape')
    try:
        page.wait_for_selector('canvas[data-page="paused"]')
    except Exception:
        (a.evidence/'pause-failure-state.json').write_text(json.dumps(data(), indent=2)+'\n')
        page.screenshot(path=str(a.evidence/'pause-failure.png'))
        raise
    frozen = data()
    page.wait_for_timeout(350)
    check(data()['worldTime'] == frozen['worldTime'], 'Pause freezes the normal run and scrolling time')
    page.set_viewport_size({'width': 393, 'height': 873})
    page.wait_for_selector('canvas[data-page="paused"][data-ui-ready="true"]')
    check(data()['score'] == frozen['score'] and data()['character'] == frozen['character'], 'Portrait rotation preserves the real paused score and character')
    page.locator('canvas').focus()
    page.keyboard.press('Escape')
    page.wait_for_selector('canvas[data-state="running"][data-page=""]')
    page.screenshot(path=str(a.evidence/'portrait-running.png'))
    check(data()['state'] == 'running', 'The same run resumes in portrait with its ground and controls')
    check(not errors, 'No script or browser errors in the actual ground flow')
    report = {'url': a.url, 'browser': a.browser, 'build': build, 'checks': checks, 'rim_rgb_actual': actual, 'rim_rgb_expected': expected, 'material_colors': len(colors), 'errors': errors, 'scope': 'Normal public HTTPS entry, screenshot pixels, keyboard/touch and actual rotation. No state setters. Firefox is desktop Gecko with touch enabled, not a physical phone. CA-forwarded diagnostic wrappers block SW; offline is unchanged and was not retested in this ground-only pass.'}
    (a.evidence/'results.json').write_text(json.dumps(report, indent=2)+'\n')
    context.close()
    browser.close()
print('RESULT:', len(checks), 'actual ground flow checks', flush=True)
