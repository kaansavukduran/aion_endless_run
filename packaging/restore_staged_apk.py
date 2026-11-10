"""Restore a signed APK from hash-verified same-repository staging parts.

GitHub's 100 MiB blob limit must not cause oversized APKs to be committed.
This script reads data only; it neither has nor needs signing credentials.
"""
import argparse,hashlib,json,re,subprocess
from pathlib import Path
p=argparse.ArgumentParser()
p.add_argument('--ref',default='FETCH_HEAD')
p.add_argument('--version',required=True)
p.add_argument('--sha256',required=True)
p.add_argument('--output',required=True,type=Path)
a=p.parse_args()
assert re.fullmatch(r'[0-9]+\.[0-9]+\.[0-9]+',a.version)
assert re.fullmatch(r'[a-f0-9]{64}',a.sha256)
def read(name):return subprocess.check_output(['git','show',a.ref+':'+name])
m=json.loads(read('APK-PARTS.json'))
assert m['version']==a.version and m['sha256']==a.sha256
assert m['name']==f'AionEndlessRun-{a.version}-android-arm64-x64.apk'
a.output.parent.mkdir(parents=True,exist_ok=True)
digest=hashlib.sha256();total=0
with a.output.open('wb') as target:
 for part in m['parts']:
  assert re.fullmatch(r'apk-part-[0-9]{3}',part['name'])
  data=read(part['name'])
  assert len(data)==part['bytes'] and hashlib.sha256(data).hexdigest()==part['sha256']
  target.write(data);digest.update(data);total+=len(data)
assert total==m['bytes'] and digest.hexdigest()==a.sha256
print(f'Verified {len(m["parts"])} parts, {total} bytes, SHA-256 {digest.hexdigest()}')
