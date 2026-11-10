"""Install the pinned official engine and templates in a reusable CI cache."""
import hashlib
import os
import platform
import shutil
import stat
import subprocess
import urllib.request
import zipfile
from pathlib import Path

VERSION = "4.6.3"
root = Path('.ci-godot').resolve()
root.mkdir(exist_ok=True)
system = platform.system()
suffix = {"Linux": "linux.x86_64.zip", "Windows": "win64.exe.zip", "Darwin": "macos.universal.zip"}[system]
base = f'https://github.com/godotengine/godot/releases/download/{VERSION}-stable/'
names = [f'Godot_v{VERSION}-stable_{suffix}', f'Godot_v{VERSION}-stable_export_templates.tpz']
with urllib.request.urlopen(base + 'SHA512-SUMS.txt') as response:
    sums = response.read().decode()
checksums = {}
for line in sums.splitlines():
    parts = line.split()
    if len(parts) >= 2:
        checksums[parts[1].lstrip('*')] = parts[0]
for name in names:
    target = root / name
    if not target.exists():
        urllib.request.urlretrieve(base + name, target)
    with target.open('rb') as stream:
        actual = hashlib.file_digest(stream, 'sha512').hexdigest()
    if actual != checksums[name]:
        raise RuntimeError('Checksum mismatch: ' + name)
    with zipfile.ZipFile(target) as archive:
        directory = root / ('engine' if name.endswith('.zip') else 'templates')
        archive.extractall(directory)
        if system != 'Windows':
            for info in archive.infolist():
                mode = (info.external_attr >> 16) & 0o777
                if mode and not info.is_dir():
                    (directory / info.filename).chmod(mode)
bin_dir = root / 'bin'
bin_dir.mkdir(exist_ok=True)
if system == 'Darwin':
    executable = root / 'engine/Godot.app/Contents/MacOS/Godot'
elif system == 'Windows':
    executable = next((root / 'engine').glob('*console.exe'))
else:
    executable = next((root / 'engine').glob('Godot*'))
dest = bin_dir / ('godot.exe' if system == 'Windows' else 'godot')
# The Windows console launcher needs its GUI engine next to it.
if system == 'Windows':
    for p in (root / 'engine').glob('*.exe'):
        shutil.copy2(p, bin_dir / p.name)
if system == 'Darwin':
    executable.chmod(executable.stat().st_mode | stat.S_IEXEC)
    subprocess.run(['codesign', '--force', '--deep', '--sign', '-', str(root / 'engine/Godot.app')], check=True)
    dest.unlink(missing_ok=True)
    dest.symlink_to(executable)
else:
    shutil.copy2(executable, dest)
    dest.chmod(dest.stat().st_mode | stat.S_IEXEC)
if system == 'Windows':
    # Use the real executable directly instead of renaming its console launcher.
    gui = next(p for p in (root / 'engine').glob('*.exe') if 'console' not in p.name)
    shutil.copy2(gui, dest)
    template_dir = Path(os.environ['APPDATA']) / 'Godot/export_templates'
elif system == 'Darwin':
    template_dir = Path.home() / 'Library/Application Support/Godot/export_templates'
else:
    template_dir = Path(os.environ.get('XDG_DATA_HOME', str(Path.home() / '.local/share'))) / 'godot/export_templates'
shutil.copytree(root / 'templates/templates', template_dir / f'{VERSION}.stable', dirs_exist_ok=True)
print('Official Godot and templates verified with upstream SHA-512.')
