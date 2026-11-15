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
tap_targets=[]
def display_bounds():
 values=re.findall(r'(Physical|Override) size:\s*(\d+)x(\d+)',adb('shell','wm','size',text=True))
 assert values,'ADB did not expose display size'
 chosen=next((item for item in reversed(values) if item[0]=='Override'),values[-1])
 return [int(chosen[1]),int(chosen[2])]
def layout_matches_display(state,bounds):
 expected='portrait' if bounds[0]<bounds[1] else 'landscape'
 return state.get('orientation')==expected and all(0<=b['point'][0]<bounds[0] and 0<=b['point'][1]<bounds[1] for b in state['buttons'])
def menu_button(name=None,text=None):
 bounds=display_bounds()
 history=packets('AION_UI ')
 if history and not layout_matches_display(history[-1],bounds):
  tap_targets.append({'event':'rejected_stale_layout','wanted':name or text,'display':bounds,'layout':history[-1]})
 state=latest('AION_UI ',lambda s:layout_matches_display(s,bounds) and any(b['name']==name or (text and re.search(text,b['text'])) for b in s['buttons']))
 chosen=next(b for b in state['buttons'] if b['name']==name or (text and re.search(text,b['text'])))
 record={'event':'tap','name':chosen['name'],'text':chosen['text'],'point':chosen['point'],'orientation':state['orientation'],'page':state['page'],'display':bounds}
 tap_targets.append(record)
 (a.output/'android-tap-targets.json').write_text(json.dumps(tap_targets,indent=2)+'\n')
 print('ADB_TAP '+json.dumps(record),flush=True)
 tap(chosen['point'])
def ready_main():
 # Every real launch may show the skippable authored opening. Use its actual
 # logged control, then await the interactive main layout rather than treating
 # the opening's page='main' label as a ready menu.
 state=latest('AION_UI ',lambda s:s['page']=='main' and any(b['name'] in ['SkipOpening','LanguageMenu'] for b in s['buttons']),timeout=25)
 skip=next((b for b in state['buttons'] if b['name']=='SkipOpening'),None)
 if skip is not None:tap(skip['point'])
 return latest('AION_UI ',lambda s:s['page']=='main' and any(b['name']=='LanguageMenu' for b in s['buttons']) and all(key in s['regions'] for key in ['PagePanel','StartChooser']),timeout=25)
def training():
 # Training is still an actual feature, now under How to play to keep the
 # primary menu compact. Follow the real UI and its pager; never set practice.
 state=ready_main()
 if not any(b['name']=='BossTraining' for b in state['buttons']):
  menu_button(name='HowToPlay');state=latest('AION_UI ',lambda s:s['page']=='help')
  for _ in range(16):
   if any(b['name']=='BossTraining' for b in state['buttons']):break
   before=[(b['name'],b['text']) for b in state['buttons']]
   menu_button(name='NextPage')
   state=latest('AION_UI ',lambda s:s['page']=='help' and [(b['name'],b['text']) for b in s['buttons']]!=before)
  assert any(b['name']=='BossTraining' for b in state['buttons']),state
 menu_button(name='BossTraining')
 latest('AION_UI ',lambda s:s['page']=='bosses')
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
 menu_button(text=r'^(Main menu|Ana menü|Hlavní nabídka)$');ready_main()
initial=latest('AION_UI ',lambda s:s['page']=='main',timeout=25)
ready_main()
# The full-scene image validator expects the interactive game, not the
# intentionally sparse dark opening. Keep its existing thresholds unchanged.
capture('first-launch')
for code in ['tr','en']:
 menu_button(name='LanguageMenu')
 latest('AION_UI ',lambda s:any(b['name']=='Language_'+code for b in s['buttons']))
 menu_button(name='Language_'+code)
 layout=latest('AION_UI ',lambda s:s['page']=='main' and s['language']==code)
 panel=layout['regions']['PagePanel'];chooser=layout['regions']['StartChooser']
 check(panel[1]+panel[3]<=chooser[1] and chooser[3]<100, 'Native system-font menu and heading/roster stay separated: '+code)
 capture('main-'+code)
layout=ready_main()
visible={button['name'] for button in layout['buttons']}
check(not ({'StartSelect_owl','StartSelect_wolf'} & visible),'Retired owl and wolf are not playable native menu choices')
check({'StartSelect_aion','StartSelect_sheep','StartSelect_rabbit','StartSelect_eren'} <= visible,'All four current playable characters are reachable on the native menu')
menu_button(name='StartSelect_aion');latest('AION_UI ',lambda s:s['character']=='aion' and s['page']=='main')
menu_button(name='StartRun');latest('AION_UI ',lambda s:s['page']=='')
before_jump=len(packets('AION_STATE '));gesture=hold('jump',350)
gesture.wait(timeout=5)
flight=packets('AION_STATE ')[before_jump:]
(a.output/'android-aion-jump-states.json').write_text(json.dumps(flight,indent=2)+'\n')
check(any(state['airborne'] for state in flight),'Real native Aion Jump touch produces an airborne state')
capture('aion-jump')
pause();capture('paused');main()
menu_button(name='StartSelect_aion');latest('AION_UI ',lambda s:s['character']=='aion' and s['page']=='main');menu_button(name='StartRun');latest('AION_UI ',lambda s:s['page']=='')
gesture=hold('shoot',700)
try:latest('AION_STATE ',lambda s:s['shooting'] and s['shots']>0);capture('normal-fire');check(True,'Real native Fire touch emits a normal-run bullet')
finally:gesture.wait(timeout=5)
pause();main();training();menu_button(name='PracticeBoss_0');latest('AION_STATE ',lambda s:s['practice'] and s['boss_phase']=='fight',timeout=25)
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
 latest('AION_STATE ',lambda s:s['charging'] and not s['airborne'] and s['charge_ratio']>.1);capture('rabbit-charge');check(True,'Native Ayça holds on the ground and accumulates charge')
finally:gesture.wait(timeout=5)
latest('AION_STATE ',lambda s:s['airborne'] and not s['charging']);capture('rabbit-leap');check(True,'Native Ayça releases a real charged leap')
pause();old=latest('AION_UI ',lambda s:s['page']=='paused');adb('shell','wm','size','2560x1440')
try:
 rotated=latest('AION_UI ',lambda s:s['page']=='paused' and s['orientation']=='landscape');capture('landscape-paused')
 check(rotated['character']==old['character'] and rotated['score']==old['score'] and rotated['level']==old['level'],'Native landscape resize preserves the paused character, score and level')
finally:
 adb('shell','wm','size','reset')
 # Window-manager completion is not Godot layout completion. The last record
 # was explicitly landscape; require the restored engine layout and bounded
 # physical targets before the first tap back into the portrait menu.
 restored_bounds=display_bounds()
 restored=latest('AION_UI ',lambda state:state['page']=='paused' and state['orientation']==old['orientation'] and layout_matches_display(state,restored_bounds),timeout=25)
 check(restored['character']==old['character'] and restored['score']==old['score'] and restored['level']==old['level'],'Native restored portrait layout is acknowledged before another menu tap')
# The changed crouch/movement mechanic belongs to Arcade, whose passive native
# records are separate from the retained Endless runner observations above.
main();menu_button(name='StartSelect_aion');ready_main();menu_button(name='StartCampaign')
def arcade_ui(predicate=lambda value:True,timeout=25):
 return latest('AION_ARCADE_UI ',lambda value:value.get('ui_ready') and predicate(value),timeout=timeout)
def arcade_state(predicate=lambda value:True,timeout=25):
 return latest('AION_ARCADE_STATE ',predicate,timeout=timeout)
def arcade_button(name):
 layout=arcade_ui(lambda value:any(button['name']==name for button in value['buttons']))
 chosen=next(button for button in layout['buttons'] if button['name']==name)
 generation=layout['ui_generation'];tap(chosen['point'])
 return arcade_ui(lambda value:value['ui_generation']!=generation)
arcade_button('CampaignBegin')
for _ in range(15):
 if arcade_ui()['menu']!='help':break
 arcade_button('CampaignGo')
arcade_state(lambda state:state['state']=='playing')
check(True,'Actual native Arcade entry reaches Mission1 through briefing and help')
# Inject two ordinary touchscreen pointers. No game handlers/state are invoked.
sdk=Path(os.environ.get('ANDROID_HOME') or os.environ['ANDROID_SDK_ROOT'])
android_jar=sdk/'platforms/android-35/android.jar'
if not android_jar.is_file():android_jar=max(sdk.glob('platforms/android-*/android.jar'),key=lambda path:tuple(int(number) for number in re.findall(r'\d+',path.parent.name)))
d8=sdk/'build-tools/35.0.0/d8'
if not d8.is_file():d8=max(sdk.glob('build-tools/*/d8'),key=lambda path:tuple(int(number) for number in re.findall(r'\d+',path.parent.name)))
classes=a.output/'adb-two-touch';classes.mkdir(exist_ok=True)
source=Path(__file__).resolve().parents[1]/'tests/native/AionTouchPair.java'
subprocess.run(['java','-m','jdk.compiler/com.sun.tools.javac.Main','-source','8','-target','8','-bootclasspath',str(android_jar),'-d',str(classes),str(source)],check=True)
subprocess.run([str(d8),'--min-api','26','--lib',str(android_jar),'--output',str(classes/'driver.zip'),str(classes/'AionTouchPair.class')],check=True)
adb('push',classes/'driver.zip','/data/local/tmp/aion-two-touch-driver.zip')
layout=arcade_ui(lambda state:'stick' in state and 'attack' in state['actions'])
stick=layout['stick'];attack=layout['actions']['attack'];before=arcade_state()
x=round(stick[0]+stick[2]*.76);y=round(stick[1]+stick[3]*.76)
command=['adb','shell','CLASSPATH=/data/local/tmp/aion-two-touch-driver.zip:/system/framework/input.jar','app_process','/system/bin','AionTouchPair',str(x),str(y),str(attack[0]),str(attack[1]),'3500']
pair=subprocess.Popen(command,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
try:
 active=arcade_state(lambda state:state['crouching'] and state['velocity'][0]>1 and state['player'][0]>before['player'][0]+8 and state['shots']>before['shots'],timeout=15)
 check(pair.poll() is None,'Native two-finger gesture remains held during crouch/fire observation')
 capture('crouch-fire')
 check(True,'Real native joystick Down+Right and second-finger Fire crawl and shoot together')
finally:
 output,_=pair.communicate(timeout=10)
 (a.output/'android-two-touch-driver.txt').write_text(output+'\n')
released=arcade_state(lambda state:not state['crouching'] and abs(state['velocity'][0])<1)
check(True,'Releasing both native fingers clears crouch and movement')
(a.output/'android-arcade-input-states.json').write_text(json.dumps(packets('AION_ARCADE_STATE '),indent=2)+'\n')
(a.output/'android-arcade-final-ui.json').write_text(json.dumps(arcade_ui(),indent=2)+'\n')

(a.output/'android-input-results.json').write_text(json.dumps({'checks':results,'scope':'API30 emulator, real ADB touches, offline and display resize; no physical phone/gamepad claim.'},indent=2)+'\n')
