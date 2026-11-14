"""Use real ADB gestures and passive Godot layout/state logs; no state injection."""
import argparse,json,re,subprocess,time,os
from android_packets import decode_packets
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--output',type=Path,default=Path('build'));a=p.parse_args();a.output.mkdir(exist_ok=True,parents=True)
results=[]
def adb(*args,**kwargs):return subprocess.check_output(['adb',*map(str,args)],**kwargs)
def packets(prefix):
 text=adb('logcat','-d','-s','godot',text=True)
 return decode_packets(text,prefix)
def latest(prefix,predicate=lambda x:True,timeout=15):
 until=time.monotonic()+timeout
 while time.monotonic()<until:
  values=packets(prefix)
  if values and predicate(values[-1]):return values[-1]
  time.sleep(.1)
 raise AssertionError(f'Timed out waiting for actual {prefix}: {values[-3:] if values else []}')
def check(ok,message):
 assert ok,message
 results.append(message);print('PASS',message,flush=True)
def tap(point):adb('shell','input','tap',*point)
def menu_button(name=None,text=None):
 state=latest('AION_UI ')
 matches=[b for b in state['buttons'] if b['name']==name or (text and re.search(text,b['text']))]
 assert matches,(name,text,state)
 tap(matches[0]['point'])
def capture(name):
 (a.output/('android-'+name+'.png')).write_bytes(adb('exec-out','screencap','-p'))
def hold(action,duration=1200):
 layout=latest('AION_UI ',lambda s:action in s['actions']);x,y=layout['actions'][action]
 return subprocess.Popen(['adb','shell','input','swipe',str(x),str(y),str(x),str(y),str(duration)],stdout=subprocess.DEVNULL)
def pause():
 menu_button(text=r'^(Pause|Duraklat|Pozastavit)$')
 latest('AION_STATE ',lambda s:s['page']=='paused')
 # State changes before the deferred menu rebuild. Wait for the actual
 # paused layout as well, otherwise main() can read the old Pause button.
 latest('AION_UI ',lambda s:s['page']=='paused')
def main():
 menu_button(text=r'^(Main menu|Ana menü|Hlavní nabídka)$');latest('AION_UI ',lambda s:s['page']=='main')
initial=latest('AION_UI ',lambda s:s['page']=='main',timeout=25);capture('first-launch')
for code in ['tr','cs','en']:
 menu_button(name='LanguageMenu')
 latest('AION_UI ',lambda s:any(b['name']=='Language_'+code for b in s['buttons']))
 menu_button(name='Language_'+code)
 layout=latest('AION_UI ',lambda s:s['page']=='main' and s['language']==code)
 panel=layout['regions']['PagePanel'];chooser=layout['regions']['StartChooser']
 check(panel[1]+panel[3]<=chooser[1] and chooser[3]<100, 'Native system-font menu and heading/roster stay separated: '+code)
 capture('main-'+code)
menu_button(name='StartSelect_owl');latest('AION_UI ',lambda s:s['character']=='owl' and s['page']=='main')
menu_button(name='StartRun');latest('AION_UI ',lambda s:s['page']=='')
# Complete touch pairs share one Android input VM. Starting a new VM for
# every contact adds device-dependent gaps and may land between real presses.
# This input-only driver calls the SAME standard Android input command; it has
# no access to game internals. Preserve the actual state history for review.
sdk=Path(os.environ.get('ANDROID_HOME') or os.environ['ANDROID_SDK_ROOT'])
android_jar=sdk/'platforms/android-35/android.jar'
if not android_jar.is_file():android_jar=max(sdk.glob('platforms/android-*/android.jar'),key=lambda p:tuple(int(n) for n in re.findall(r'\d+',p.parent.name)))
d8=sdk/'build-tools/35.0.0/d8'
if not d8.is_file():d8=max(sdk.glob('build-tools/*/d8'),key=lambda p:tuple(int(n) for n in re.findall(r'\d+',p.parent.name)))
classes=a.output/'adb-flight';classes.mkdir(exist_ok=True)
source=Path(__file__).resolve().parents[1]/'tests/native/AionTouchFlight.java'
subprocess.run(['java','-m','jdk.compiler/com.sun.tools.javac.Main','-source','8','-target','8','-bootclasspath',str(android_jar),'-d',str(classes),str(source)],check=True)
subprocess.run([str(d8),'--min-api','26','--lib',str(android_jar),'--output',str(classes/'driver.zip'),str(classes/'AionTouchFlight.class')],check=True)
adb('push',classes/'driver.zip','/data/local/tmp/aion-touch-driver.zip')
layout=latest('AION_UI ',lambda s:'jump' in s['actions']);x,y=layout['actions']['jump']
before_flight=len(packets('AION_STATE '))
started=time.monotonic()
output=adb('shell','CLASSPATH=/data/local/tmp/aion-touch-driver.zip:/system/framework/input.jar','app_process','/system/bin','AionTouchFlight',x,y,text=True)
(a.output/'android-touch-driver.txt').write_text(output+'\nwall_seconds='+str(time.monotonic()-started)+'\n')
print(output,flush=True)
adb('shell','screencap','-p','/data/local/tmp/aion-owl-flight.png')
flight=packets('AION_STATE ')[before_flight:]
(a.output/'android-owl-glide.png').write_bytes(adb('exec-out','cat','/data/local/tmp/aion-owl-flight.png'))
(a.output/'android-owl-flight-states.json').write_text(json.dumps(flight,indent=2)+'\n')
check(any(s['airborne'] and s['gliding'] for s in flight),'Real native Jump hold reaches an airborne owl glide')
for flap in range(1,4):
 check(any(s['airborne'] and s['owl_flaps_used']==flap for s in flight),'Real native Jump repress consumes airborne flap '+str(flap))
pause();capture('paused');main()
menu_button(name='StartSelect_aion');latest('AION_UI ',lambda s:s['character']=='aion' and s['page']=='main');menu_button(name='StartRun');latest('AION_UI ',lambda s:s['page']=='')
gesture=hold('shoot',700)
try:latest('AION_STATE ',lambda s:s['shooting'] and s['shots']>0);capture('normal-fire');check(True,'Real native Fire touch emits a normal-run bullet')
finally:gesture.wait(timeout=5)
pause();main();menu_button(text=r'^Boss training$');latest('AION_UI ',lambda s:s['page']=='bosses');menu_button(name='PracticeBoss_0');latest('AION_STATE ',lambda s:s['practice'] and s['boss_phase']=='fight',timeout=25)
# A slow software-rendered emulator advances less active game time per wall
# second. Use the real training arena (3HP, no parkour) to observe a full hold;
# normal-run input is checked above. Never remove the six-shot assertion.
gesture=hold('shoot',5200)
try:latest('AION_STATE ',lambda s:s['shots']>=6);capture('held-fire');check(True,'Real native held Fire continues beyond five bullets without reload in the training arena')
finally:gesture.wait(timeout=8)
pause();main();menu_button(name='StartRun');latest('AION_UI ',lambda s:s['page']=='')
gesture=hold('duck',600)
try:latest('AION_STATE ',lambda s:s['rolling']);capture('duck');check(True,'Real native Roll touch reaches the actual roll state')
finally:gesture.wait(timeout=5)
pause();main();menu_button(name='StartSelect_eren');latest('AION_UI ',lambda s:s['character']=='eren' and s['page']=='main');menu_button(name='StartRun');latest('AION_UI ',lambda s:s['page']=='')
gesture=hold('jump',500)
try:latest('AION_STATE ',lambda s:s['charging'] and not s['airborne']);check(True,'Native Eren independently charges while grounded')
finally:gesture.wait(timeout=5)
latest('AION_STATE ',lambda s:s['airborne'] and not s['charging']);capture('eren');check(True,'Native Eren releases his own charged leap')
pause();main();menu_button(name='StartSelect_rabbit');latest('AION_UI ',lambda s:s['character']=='rabbit' and s['page']=='main');menu_button(name='StartRun');latest('AION_UI ',lambda s:s['page']=='')
gesture=hold('jump',1000)
try:
 latest('AION_STATE ',lambda s:s['charging'] and not s['airborne'] and s['charge_ratio']>.1);capture('rabbit-charge');check(True,'Native Emre holds on the ground and accumulates charge')
finally:gesture.wait(timeout=5)
latest('AION_STATE ',lambda s:s['airborne'] and not s['charging']);capture('rabbit-leap');check(True,'Native Emre releases a real charged leap')
pause();old=latest('AION_UI ',lambda s:s['page']=='paused');adb('shell','wm','size','2560x1440')
try:
 rotated=latest('AION_UI ',lambda s:s['page']=='paused' and s['orientation']=='landscape');capture('landscape-paused')
 check(rotated['character']==old['character'] and rotated['score']==old['score'] and rotated['level']==old['level'],'Native landscape resize preserves the paused character, score and level')
finally:adb('shell','wm','size','reset')
(a.output/'android-input-results.json').write_text(json.dumps({'checks':results,'scope':'API30 emulator, real ADB touches, offline and display resize; no physical phone/gamepad claim.'},indent=2)+'\n')
