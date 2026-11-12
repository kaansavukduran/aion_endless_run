import base64,json,sys,unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'packaging'))
from android_packets import decode_packets

class PacketTests(unittest.TestCase):
 def lines(self,payload,seq=1):
  encoded=base64.b64encode(json.dumps(payload,ensure_ascii=False).encode()).decode();parts=[encoded[n:n+700] for n in range(0,len(encoded),700)]
  return [f'godot: AION_CHUNK AION_UI {seq} {n} {len(parts)} {p}' for n,p in enumerate(parts)]
 def test_large_multilingual_menu(self):
  p={'language':'ja','buttons':[{'text':'日本語 / 한국어 / Azərbaycanca / 中文','point':[100,n]} for n in range(60)]}
  lines=self.lines(p);self.assertTrue(all(len(s.encode())<1024 for s in lines));self.assertEqual(decode_packets('\n'.join(lines),'AION_UI '),[p])
 def test_partial_record_is_never_a_result(self):
  lines=self.lines({'text':'日本語'*2000});self.assertEqual(decode_packets('\n'.join(lines[:-1]),'AION_UI '),[])
 def test_states_and_completed_order(self):
  lines=self.lines({'page':'main'},1)+['godot: AION_STATE {"state":"running"}']+self.lines({'page':'paused'},2)
  self.assertEqual(decode_packets('\n'.join(lines),'AION_UI '),[{'page':'main'},{'page':'paused'}]);self.assertEqual(decode_packets('\n'.join(lines),'AION_STATE '),[{'state':'running'}])
 def test_corruption_fails(self):
  with self.assertRaises(Exception):decode_packets('godot: AION_CHUNK AION_UI 1 0 1 !bad!','AION_UI ')
if __name__=='__main__':unittest.main()
