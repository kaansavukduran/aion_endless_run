"""Use real ADB gestures and passive Godot layout/state logs; no state injection."""
import argparse,json,re,subprocess,time
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
gesture=hold('jump',2200)
try:
 latest('AION_STATE ',lambda s:s['gliding'] and s['airborne']);capture('owl-glide');check(True,'Real native Jump hold reaches an airborne owl glide')
finally:gesture.wait(timeout=5)
pause();capture('paused');main()
menu_button(name='StartSelect_aion');latest('AION_UI ',lambda s:s['character']=='aion' and s['page']=='main');menu_button(name='StartRun');latest('AION_UI ',lambda s:s['page']=='')
gesture=hold('shoot',2300)
try:latest('AION_STATE ',lambda s:s['shooting'] and s['shots']>=6);capture('held-fire');check(True,'Real native Fire continues beyond five bullets without reload')
finally:gesture.wait(timeout=6)
pause();main();menu_button(name='StartRun');latest('AION_UI ',lambda s:s['page']=='')
gesture=hold('duck',600)
try:latest('AION_STATE ',lambda s:s['rolling']);capture('duck');check(True,'Real native Roll touch reaches the actual roll state')
finally:gesture.wait(timeout=5)
pause();main();menu_button(name='StartSelect_eren');latest('AION_UI ',lambda s:s['character']=='eren' and s['page']=='main');menu_button(name='StartRun');latest('AION_UI ',lambda s:s['page']=='')
gesture=hold('jump',500)
try:latest('AION_STATE ',lambda s:s['airborne'] and not s['charging']);capture('eren');check(True,'Eren is independently selectable and jumps without Emre charge')
finally:gesture.wait(timeout=5)
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
