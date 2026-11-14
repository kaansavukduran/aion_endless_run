"""Give the HFS+ staging volume explicit free space for the large universal PCK.

hdiutil's automatic srcfolder capacity can run out *inside the mounted image*
while copying the PCK. Reserve at least 128 MiB beyond actual allocated source
size, also allowing 25% overhead for larger future exports. No sudo or host
cleanup is required; only the output requested by the build is overwritten.
"""
import argparse,subprocess,time
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('source',type=Path);p.add_argument('output',type=Path);a=p.parse_args()
assert a.source.is_dir()
allocated_kib=int(subprocess.check_output(['du','-sk',str(a.source)],text=True).split()[0])
capacity_kib=max(384*1024,allocated_kib+max(128*1024,allocated_kib//4))
print('DMG source allocated KiB:',allocated_kib,'capacity KiB:',capacity_kib,flush=True)
subprocess.run(['df','-h',str(a.source)],check=True)
command=['hdiutil','create','-size',str(capacity_kib)+'k','-volname','Aion Endless Run','-srcfolder',str(a.source),'-ov','-format','UDZO',str(a.output)]
for attempt in range(3):
 result=subprocess.run(command,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
 print(result.stdout,end='',flush=True)
 if result.returncode==0:break
 if 'resource busy' not in result.stdout.lower() or attempt==2:result.check_returncode()
 # Retry only the observed transient hdiutil lock; never hide other failures
 # or alter host mounts. Remove only this build's explicitly requested output.
 a.output.unlink(missing_ok=True)
 time.sleep(2*(attempt+1))
subprocess.run(['hdiutil','verify',str(a.output)],check=True)
