"""Fingerprint engine assets and replace Godot's cache-first legacy updater.

The worker keeps its historical URL so installed 0.1/0.2 PWAs can migrate.
It never deletes IndexedDB, where Godot stores the user's records/settings.
"""
import hashlib
import json
from pathlib import Path
import re


def prepare_web_export(root: Path) -> None:
    output = root / 'build/web'
    version = re.search(r'config/version="([^"]+)"', (root / 'project.godot').read_text())[1]
    source = Path(__file__).read_bytes() + (root / 'packaging/web_update.js').read_bytes() + (root / 'packaging/web_worker.js').read_bytes()
    digest = hashlib.sha256(source)
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
    html = (output / 'index.html').read_text()
    for before, after in names.items():
        html = html.replace(before, after)
    html = html.replace('"executable":"index"', '"executable":' + json.dumps(executable))
    # The updater initializes before Godot. It marks modern clients so a new
    # worker never interrupts their active runs, and exposes an explicit button.
    script = (root / 'packaging/web_update.js').read_text().replace('__BUILD__', build).replace('__VERSION__', version)
    html = html.replace('"serviceWorker":"index.service.worker.js"', '"serviceWorker":""')
    html = html.replace('<head>', '<head>\n<script>\n' + script + '\n</script>', 1)
    (output / 'index.html').write_text(html)
    manifest = output / 'index.manifest.json'
    if manifest.exists():
        text = manifest.read_text()
        for before, after in names.items():
            text = text.replace(before, after)
        manifest.write_text(text)
    (output / 'build.json').write_text(json.dumps({'version': version, 'build': build}) + '\n')
    files = sorted(p.name for p in output.iterdir() if p.is_file() and p.name != 'index.service.worker.js')
    worker = (root / 'packaging/web_worker.js').read_text().replace('__BUILD__', build).replace('__VERSION__', version).replace('__FILES__', json.dumps(files))
    (output / 'index.service.worker.js').write_text(worker)
    print(f'Offline export v{version}, immutable build {build}', flush=True)
