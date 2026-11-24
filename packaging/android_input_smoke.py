"""Use real ADB gestures and passive Godot layout/state logs; no state injection."""
import argparse,json,re,subprocess,time,os
from android_packets import decode_packets
from android_readiness import capture_main_frame, layout_matches_display
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
def record_target(record):
 tap_targets.append(record)
 (a.output/'android-tap-targets.json').write_text(json.dumps(tap_targets,indent=2)+'\n')
 print('ADB_TAP '+json.dumps(record),flush=True)
def display_bounds():
 values=re.findall(r'(Physical|Override) size:\s*(\d+)x(\d+)',adb('shell','wm','size',text=True))
 assert values,'ADB did not expose display size'
 chosen=next((item for item in reversed(values) if item[0]=='Override'),values[-1])
 return [int(chosen[1]),int(chosen[2])]
def menu_button(name=None,text=None):
 bounds=display_bounds()
 history=packets('AION_UI ')
 if history and not layout_matches_display(history[-1],bounds):
  record_target({'event':'rejected_stale_layout','wanted':name or text,'display':bounds,'layout':history[-1]})
 state=latest('AION_UI ',lambda s:layout_matches_display(s,bounds) and any(b['name']==name or (text and re.search(text,b['text'])) for b in s['buttons']))
 chosen=next(b for b in state['buttons'] if b['name']==name or (text and re.search(text,b['text'])))
 record={'event':'tap','name':chosen['name'],'text':chosen['text'],'point':chosen['point'],'orientation':state['orientation'],'page':state['page'],'display':bounds}
 record_target(record)
 tap(chosen['point'])
def capture(name):
 (a.output/('android-'+name+'.png')).write_bytes(adb('exec-out','screencap','-p'))
def capture_main():
 # Layout metadata can precede the GPU-presented frame on software Android.
 # Keep every raw attempt, including the first, and bound this render barrier.
 # Never relabel an intro/blank frame as a passing full-menu screenshot.
 capture_main_frame(lambda:packets('AION_UI '),display_bounds,
  lambda:adb('exec-out','screencap','-p'),
  lambda name,png:(a.output/name).write_bytes(png),record_target)
def arcade_ui(predicate=lambda value:True,timeout=25):
 return latest('AION_ARCADE_UI ',lambda value:value.get('ui_ready') and predicate(value),timeout=timeout)
def arcade_state(predicate=lambda value:True,timeout=25):
 return latest('AION_ARCADE_STATE ',predicate,timeout=timeout)
def arcade_button(name):
 layout=arcade_ui(lambda value:any(button['name']==name for button in value['buttons']))
 chosen=next(button for button in layout['buttons'] if button['name']==name)
 generation=layout['ui_generation'];tap(chosen['point'])
 return arcade_ui(lambda value:value['ui_generation']!=generation)
def enter(hero):
 menu_button(name='StartCampaign')
 picker=latest('AION_UI ',lambda state:state['page']=='characters' and layout_matches_display(state,display_bounds()))
 roster={button['name'] for button in picker['buttons'] if button['name'].startswith('Select_')}
 check(roster=={'Select_aion','Select_sheep','Select_rabbit','Select_eren','Select_armadillo','Select_frog'},'All six hero rectangles are reachable together')
 menu_button(name='Select_'+hero)
 latest('AION_UI ',lambda state:state['page']=='characters' and state['character']==hero)
 capture('picker-'+hero)
 menu_button(name='ConfirmHero')
 arcade_state(lambda state:state['state']=='playing' and state['character']==hero)
 check(True,'Native selection enters Mission 1 with '+hero)
def hold_action(name,duration):
 layout=arcade_ui(lambda state:name in state['actions'])
 x,y=layout['actions'][name]
 record_target({'event':'hold','action':name,'duration_ms':duration,'point':[x,y],'character':layout['character'],'orientation':layout['orientation']})
 return subprocess.Popen(['adb','shell','input','swipe',str(x),str(y),str(x),str(y),str(duration)],stdout=subprocess.DEVNULL)
def pause():
 arcade_button('CampaignPause')
 return arcade_ui(lambda state:state['menu']=='paused')
def main():
 layout=pause()
 button=next(b for b in layout['buttons'] if b['text'] in ('Ana menü','Main menu','Geri','Back'))
 tap(button['point'])
 latest('AION_UI ',lambda state:state['page']=='main' and layout_matches_display(state,display_bounds()))

initial=latest('AION_UI ',lambda state:state['page']=='main' and state.get('guide') and layout_matches_display(state,display_bounds()),timeout=40)
check(not any(button['name']=='StartRun' for button in initial['buttons']),'Cold launch exposes the control guide and a single game')
capture_main()
for code in ['tr','en']:
 menu_button(name='LanguageMenu')
 menu_button(name='Language_'+code)
 latest('AION_UI ',lambda state:state['page']=='main' and state['language']==code)
 capture('main-'+code)
enter('eren')
jump=hold_action('jump',1100)
try:
 arcade_state(lambda state:state['charging'] and state['charge_ratio']>.1 and state['grounded'])
finally:jump.wait(timeout=8)
arcade_state(lambda state:not state['grounded'] and state['player'][1]<-10)
capture('eren')
check(True,'Native Eren charges and releases a real jump')
main()
enter('rabbit')
jump=hold_action('jump',1600)
try:
 arcade_state(lambda state:state['charging'] and state['charge_ratio']>.1 and state['grounded'])
 capture('rabbit-charge')
finally:jump.wait(timeout=8)
arcade_state(lambda state:not state['grounded'] and state['player'][1]<-10)
capture('rabbit-leap')
check(True,'Native Ayça charges and releases a real jump')
main()
enter('aion')
jump=hold_action('jump',420)
jump.wait(timeout=6)
arcade_state(lambda state:not state['grounded'],timeout=10)
capture('aion-jump')
attack=hold_action('attack',4400)
try:
 arcade_state(lambda state:state['shots']>=6,timeout=12)
 capture('held-fire')
finally:attack.wait(timeout=8)
check(True,'Real native held fire issues six arcade shots and stays responsive')
old=pause()
capture('paused')
before=arcade_state(lambda state:state['state']=='paused')
adb('shell','wm','size','2560x1440')
try:
 rotated=arcade_ui(lambda state:state['menu']=='paused' and state['orientation']=='landscape')
 capture('landscape-paused')
 after=arcade_state(lambda state:state['state']=='paused')
 check(rotated['character']==old['character'] and before['score']==after['score'] and before['player']==after['player'],'Native landscape preserves the paused hero, position and score')
finally:
 adb('shell','wm','size','reset')
 arcade_ui(lambda state:state['menu']=='paused' and state['orientation']==old['orientation'])
resume=[b for b in arcade_ui()['buttons'] if b['text'] in ('Resume','Sürdür','Devam et','Continue')]
assert resume,'Missing paused Resume action'
tap(resume[0]['point'])
arcade_state(lambda state:state['state']=='playing')
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
 capture('duck')
 check(True,'Real native joystick Down+Right and second-finger Fire crawl and shoot together')
finally:
 output,_=pair.communicate(timeout=10)
 (a.output/'android-two-touch-driver.txt').write_text(output+'\n')
released=arcade_state(lambda state:not state['crouching'] and abs(state['velocity'][0])<1)
check(True,'Releasing both native fingers clears crouch and movement')
(a.output/'android-arcade-input-states.json').write_text(json.dumps(packets('AION_ARCADE_STATE '),indent=2)+'\n')
(a.output/'android-arcade-final-ui.json').write_text(json.dumps(arcade_ui(),indent=2)+'\n')

(a.output/'android-input-results.json').write_text(json.dumps({'checks':results,'scope':'API30 emulator, real ADB touches, offline and display resize; no physical phone/gamepad claim.'},indent=2)+'\n')
