"""One dated, verifiable source snapshot. Never copies caches or credentials."""
import argparse,hashlib,json,subprocess,tarfile,io
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo
p=argparse.ArgumentParser();p.add_argument('--destination',type=Path,required=True);p.add_argument('--ref',default='HEAD');a=p.parse_args()
root=Path(__file__).resolve().parents[1];sha=subprocess.check_output(['git','rev-parse',a.ref],cwd=root,text=True).strip();branch=subprocess.check_output(['git','branch','--show-current'],cwd=root,text=True).strip();now=datetime.now(ZoneInfo('Europe/Istanbul'));folder=a.destination/(now.strftime('%Y%m%d-%H%M%S')+'_'+sha[:7]);project=folder/'proje';
for prior in a.destination.glob('*_'+sha[:7]):
 info_path=prior/'KAYNAK_BILGISI.json'
 if info_path.exists() and json.loads(info_path.read_text()).get('commit')==sha:
  entries=json.loads((prior/'DOSYA_ENVANTERI.json').read_text())
  if all((prior/'proje'/e['path']).is_file() and hashlib.sha256((prior/'proje'/e['path']).read_bytes()).hexdigest()==e['sha256'] for e in entries):
   print(prior);raise SystemExit(0)
project.mkdir(parents=True)
# Archive the named immutable tree, never the uncommitted working directory.
raw=subprocess.check_output(['git','archive',sha],cwd=root)
with tarfile.open(fileobj=io.BytesIO(raw)) as archive:archive.extractall(project,filter='data')
entries=[]
for f in sorted(project.rglob('*')):
 if f.is_file():
  data=f.read_bytes()
  if data.startswith(b'version https://git-lfs.github.com/spec/v1'):raise RuntimeError('Unresolved LFS pointer: '+str(f))
  entries.append({'path':f.relative_to(project).as_posix(),'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()})
submodules=subprocess.check_output(['git','ls-tree','-r',sha],cwd=root,text=True)
if any(line.startswith('160000 ') for line in submodules.splitlines()):raise RuntimeError('Submodule contents require materialization before archival')
(folder/'DOSYA_ENVANTERI.json').write_text(json.dumps(entries,ensure_ascii=False,indent=2)+'\n')
info={'repository':'https://github.com/kaansavukduran/aion_endless_run','branch':branch,'commit':sha,'saved_at':now.isoformat(),'timezone':'Europe/Istanbul','file_count':len(entries),'scope':'All version-controlled project files, original relative paths; no Git history/issues/PR backup, no continuous sync','missing':[],'working_tree_included':False}
(folder/'KAYNAK_BILGISI.json').write_text(json.dumps(info,ensure_ascii=False,indent=2)+'\n');print(folder)
