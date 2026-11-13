"""Record the exact, complete platform set before a tag release becomes public."""
import argparse, hashlib, json, os, subprocess
from pathlib import Path

p = argparse.ArgumentParser()
p.add_argument('--directory', type=Path, default=Path('release'))
p.add_argument('--version', required=True)
a = p.parse_args()
suffixes = [
    'android-arm64-x64.apk', 'linux-x64-portable.tar.gz', 'linux-x64.AppImage',
    'linux-x64.deb', 'macos-universal-portable.zip', 'macos-universal.dmg',
    'web-offline.tar.gz', 'windows-x64-portable.zip', 'windows-x64-Setup.exe',
]
expected = {f'AionEndlessRun-{a.version}-{suffix}' for suffix in suffixes}
actual = {f.name for f in a.directory.glob('AionEndlessRun-*') if f.is_file()}
assert actual == expected, {'missing': sorted(expected-actual), 'unexpected': sorted(actual-expected)}
proof = json.loads(Path('docs/evidence-v'+a.version.replace('.', '')+'/verification.json').read_text())
files = {}
for name in sorted(expected):
    f = a.directory/name
    with f.open('rb') as stream:
        digest = hashlib.file_digest(stream, 'sha256').hexdigest()
    files[name] = {'bytes': f.stat().st_size, 'sha256': digest}
source = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
receipt = {
    'version': a.version, 'source_commit': source, 'verified_application_commit': source,
    'verification_run': f'https://github.com/{os.environ["GITHUB_REPOSITORY"]}/actions/runs/{os.environ["GITHUB_RUN_ID"]}',
    'source_and_scene_checks': proof['source_and_scene_checks'], 'browser_checks': proof['browser_checks'],
    'android_native': 'API30 offline emulator: real Jump/glide, Fire, one-second Reload, Roll, Emre charge/release, paused resize and actual menu-region separation. No physical phone claim.',
    'android_signer_sha256': '50a9ebeabb42d34a1397fade51c1aae2ebf446f4fe77a45f200c54e4e372ed36',
    'apple_status': 'macOS ad-hoc only; no Developer ID/notarization. Native iOS awaits owner signing.',
    'files': files,
}
(a.directory/'BUILD-RECEIPT.json').write_text(json.dumps(receipt, indent=2)+'\n')
with (a.directory/'SHA256SUMS').open('w') as out:
    for name in sorted([*expected, 'BUILD-RECEIPT.json']):
        with (a.directory/name).open('rb') as stream:
            digest = hashlib.file_digest(stream, 'sha256').hexdigest()
        out.write(digest+'  '+name+'\n')
