"""Original additive-synthesis loops; no samples or commercial-game melodies."""
from pathlib import Path
import wave,json,hashlib
import numpy as np
root=Path(__file__).resolve().parents[1];out=root/'assets/audio';out.mkdir(exist_ok=True)
rate=22050;duration=24
scores={'shore':[0,7,12,9,4,7,2,9],'water':[0,3,7,10,14,7,3,10],'garden':[0,4,9,12,16,9,7,4],'roots':[0,3,5,10,7,3,12,5],'boss':[0,7,3,10,0,5,7,3]}
records=[]
for name,steps in scores.items():
 t=np.arange(rate*duration)/rate;signal=np.zeros(len(t));base=110 if name in ['roots','boss'] else 164.8138
 for i in range(32):
  start=i*.75;local=t-start;mask=(local>=0)&(local<1.9);u=local[mask];freq=base*2**(steps[i%8]/12)
  note=(np.sin(2*np.pi*freq*u)+.26*np.sin(2*np.pi*freq*2*u)+.08*np.sin(2*np.pi*freq*3*u))*(1-np.exp(-u*30))*np.exp(-u*3.2)
  signal[mask]+=.10*note
 # Low, slow ambience and gentle rhythmic root pulses; seamless end fades.
 signal+=.018*np.sin(2*np.pi*base*.5*t)*(1+.3*np.sin(2*np.pi*t/6))
 signal*=np.minimum(1,t/.1)*np.minimum(1,(duration-t)/.15)
 data=(np.clip(signal,-1,1)*32767).astype('<i2').tobytes();p=out/('campaign-'+name+'.wav')
 with wave.open(str(p),'wb') as w:w.setnchannels(1);w.setsampwidth(2);w.setframerate(rate);w.writeframes(data)
 records.append({'path':str(p.relative_to(root)),'seconds':duration,'sample_rate':rate,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
(out/'CAMPAIGN-AUDIO.json').write_text(json.dumps({'authoring':'Original code-authored additive synthesis, pentatonic/modal steps; no external samples or SNK audio. Runtime existing procedural sound effects complement these ambient music loops.','files':records},indent=2)+'\n')
print('Wrote five original 24-second ambient loops.')
