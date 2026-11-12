"""Fingerprint engine assets and replace Godot's cache-first legacy updater.

The worker keeps its historical URL so installed 0.1/0.2 PWAs can migrate.
It never deletes IndexedDB, where Godot stores the user's records/settings.
"""
import hashlib
import json
from pathlib import Path
import re
import shutil


def prepare_web_export(root: Path) -> None:
    output = root / 'build/web'
    version = re.search(r'config/version="([^"]+)"', (root / 'project.godot').read_text())[1]
    source = Path(__file__).read_bytes() + (root / 'packaging/web_update.js').read_bytes() + (root / 'packaging/web_worker.js').read_bytes() + (root / 'packaging/web_boot.js').read_bytes()
    source += (root/'packaging/web_splash.html').read_bytes() + (root/'packaging/web_accessibility.js').read_bytes()
    digest = hashlib.sha256(source)
    for name in ['fragaria-strawberry.png','PixelifySans.ttf']:
        digest.update((root/'assets'/name).read_bytes())
    for name in ['index.js', 'index.wasm', 'index.pck']:
        digest.update((output / name).read_bytes())
    build = digest.hexdigest()[:16]
    executable = 'aion-' + build
    names = {}
    for path in list(output.glob('index.*')):
        if path.name in ['index.html', 'index.offline.html', 'index.service.worker.js', 'index.manifest.json']:
            continue
        names[path.name] = executable + path.name[len('index'):]
        path.rename(output / names[path.name])
    logo = 'fragaria-'+build+'.png'
    font = 'pixel-font-'+build+'.ttf'
    shutil.copy2(root/'assets/fragaria-strawberry.png',output/logo)
    shutil.copy2(root/'assets/PixelifySans.ttf',output/font)
    names['fragaria.png']=logo
    names['pixel-font.ttf']=font
    html = (output / 'index.html').read_text()
    for before, after in names.items():
        html = html.replace(before, after)
    html = html.replace('"executable":"index"', '"executable":' + json.dumps(executable))
    assets = {name:{'bytes':(output/name).stat().st_size,'sha256':hashlib.sha256((output/name).read_bytes()).hexdigest()} for name in names.values()}
    # The updater initializes before Godot. It marks modern clients so a new
    # worker never interrupts their active runs, and exposes an explicit button.
    script = (root / 'packaging/web_accessibility.js').read_text() + '\n' + (root / 'packaging/web_update.js').read_text().replace('__BUILD__', build).replace('__VERSION__', version)
    html = html.replace('"serviceWorker":"index.service.worker.js"', '"serviceWorker":""')
    # Rewrite the exported call before injecting the loader's own engine call.
    if html.count('engine.startGame({') != 1:
        raise RuntimeError('Unexpected Godot startup template')
    html = html.replace('engine.startGame({','window.AION_BOOT.start(engine,GODOT_CONFIG,{')
    html = html.replace('function displayFailureNotice(err) {','function displayFailureNotice(err) {\n        if (window.AION_BOOT && window.AION_BOOT.state.phase !== "waiting") { window.AION_BOOT.failure(err); return; }')
    boot = (root / 'packaging/web_boot.js').read_text().replace('__BUILD__',build).replace('__ASSETS__',json.dumps(assets))
    html = html.replace('<head>', '<head>\n<script>\n' + script + '\n' + boot + '\n</script>', 1)
    splash = (root/'packaging/web_splash.html').read_text().replace('__FRAGARIA__',logo).replace('__PIXEL_FONT__',font).replace('__VERSION__',version)
    html = re.sub(r'<div id="status">.*?<div id="status-notice"></div>\s*</div>',lambda _:splash,html,count=1,flags=re.S)
    html = html.replace('width=device-width,', 'viewport-fit=cover,width=device-width,')
    (output / 'index.html').write_text(html)
    manifest = output / 'index.manifest.json'
    if manifest.exists():
        text = manifest.read_text()
        for before, after in names.items():
            text = text.replace(before, after)
        manifest.write_text(text)
    manifest_data = {'version':version,'build':build,'loader':2,'assets':assets}
    (output / 'build.json').write_text(json.dumps(manifest_data) + '\n')
    (output / 'aion-latest.json').write_text(json.dumps(manifest_data) + '\n')
    files = sorted(p.name for p in output.iterdir() if p.is_file() and p.name != 'index.service.worker.js')
    info = {name:{'bytes':(output/name).stat().st_size,'sha256':hashlib.sha256((output/name).read_bytes()).hexdigest()} for name in files}
    worker = (root / 'packaging/web_worker.js').read_text().replace('__BUILD__', build).replace('__VERSION__', version).replace('__FILES__', json.dumps(files)).replace('__FILE_INFO__',json.dumps(info))
    (output / 'index.service.worker.js').write_text(worker)
    print(f'Offline export v{version}, immutable build {build}', flush=True)


if __name__ == '__main__':
    prepare_web_export(Path(__file__).resolve().parents[1])
