"""Build this exact checkout as a standalone Godot Web export on Vercel.

No account/token, Node dependencies, database or paid runtime is required.
Only the official Linux editor and two Web templates are retained in the cache.
"""
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import urllib.request
import zipfile

VERSION = "4.6.3"
root = Path(__file__).resolve().parents[1]
work = root / "work" / "web-build"
work.mkdir(parents=True, exist_ok=True)
(root / "work" / ".gdignore").touch()
env = dict(os.environ)
env.setdefault("ANDROID_USER_HOME", str(work / "android"))
env.setdefault("ANDROID_SDK_HOME", str(work / "android"))
for key, child in [("XDG_DATA_HOME", "data"), ("XDG_CONFIG_HOME", "config"), ("XDG_CACHE_HOME", "cache")]:
    env.setdefault(key, str(work / child))
    Path(env[key]).mkdir(parents=True, exist_ok=True)

def sha512(path):
    digest = hashlib.sha512()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()

engine = env.get("GODOT_BIN")
if not engine:
    engine = str(work / "godot")
    templates = Path(env["XDG_DATA_HOME"]) / "godot/export_templates" / f"{VERSION}.stable"
    required = [templates / f"web_nothreads_{mode}.zip" for mode in ["debug", "release"]]
    if not Path(engine).exists() or not all(p.exists() for p in required):
        base = f"https://github.com/godotengine/godot/releases/download/{VERSION}-stable/"
        with urllib.request.urlopen(base + "SHA512-SUMS.txt", timeout=60) as response:
            checksums = {parts[1].lstrip("*"): parts[0] for line in response.read().decode().splitlines() if len(parts := line.split()) >= 2}
        editor_name = f"Godot_v{VERSION}-stable_linux.x86_64.zip"
        template_name = f"Godot_v{VERSION}-stable_export_templates.tpz"
        for name in [editor_name, template_name]:
            archive = work / name
            print("Downloading official Godot:", name, flush=True)
            urllib.request.urlretrieve(base + name, archive)
            if sha512(archive) != checksums[name]:
                raise RuntimeError("Official download checksum mismatch: " + name)
            with zipfile.ZipFile(archive) as bundle:
                if name == editor_name:
                    member = next(i for i in bundle.infolist() if not i.is_dir() and i.filename.startswith("Godot"))
                    with bundle.open(member) as source, Path(engine).open("wb") as target:
                        shutil.copyfileobj(source, target)
                    Path(engine).chmod(0o755)
                else:
                    templates.mkdir(parents=True, exist_ok=True)
                    for target in required:
                        with bundle.open("templates/" + target.name) as source, target.open("wb") as output:
                            shutil.copyfileobj(source, output)
            # Do not retain the 1.2GB multi-platform archive in deployment cache.
            archive.unlink()

(root / "build" / "web").mkdir(parents=True, exist_ok=True)
(root / "build" / ".gdignore").touch()
for arguments in [["--editor", "--import", "--quit"], ["--export-release", "Web"]]:
    subprocess.run([engine, "--headless", "--path", str(root), *arguments], cwd=root, env=env, check=True)
for name in ["index.html", "index.js", "index.wasm", "index.pck"]:
    if not (root / "build/web" / name).is_file():
        raise RuntimeError("Missing Web export file: " + name)
print("Web export ready: build/web/index.html", flush=True)
