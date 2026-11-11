"""Contract tests for the generated boot boundary, independent of the engine."""
import hashlib,importlib.util,json,re,shutil,tempfile,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('aion_web_updates',ROOT/'packaging/web_updates.py');web=importlib.util.module_from_spec(spec);spec.loader.exec_module(web)
class ExportContract(unittest.TestCase):
 def setUp(self):
  self.temp=tempfile.TemporaryDirectory();self.root=Path(self.temp.name);(self.root/'build/web').mkdir(parents=True);(self.root/'packaging').mkdir();self.out=self.root/'build/web'
  (self.root/'project.godot').write_text('config/version="0.12.0"')
  for name in ['web_update.js','web_worker.js','web_boot.js']:shutil.copy2(ROOT/'packaging'/name,self.root/'packaging'/name)
  for name,data in [('index.js',b'engine'),('index.wasm',b'\0asm\1\0\0\0'),('index.pck',b'GDPC'+bytes(60))]:(self.out/name).write_bytes(data)
  self.html='<html><head></head><body><script>const GODOT_CONFIG={"executable":"index","serviceWorker":"index.service.worker.js"};engine.startGame({});function displayFailureNotice(err) {console.error(err);}</script></body></html>'
  (self.out/'index.html').write_text(self.html)
 def tearDown(self):self.temp.cleanup()
 def test_integrity_manifest_matches_actual_output(self):
  web.prepare_web_export(self.root);m=json.loads((self.out/'build.json').read_text());self.assertEqual(m['loader'],2)
  for name,info in m['assets'].items():
   b=(self.out/name).read_bytes();self.assertEqual(info,{'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest()})
 def test_startup_rewrite_does_not_rewrite_loader_recursively(self):
  web.prepare_web_export(self.root);s=(self.out/'index.html').read_text()
  self.assertEqual(s.count('window.AION_BOOT.start(engine,GODOT_CONFIG,{'),1)
  self.assertEqual(s.count('engine.startGame({...options,mainPack:PACK_PATH})'),1)
 def test_worker_has_hash_for_final_html_and_latest_endpoint(self):
  web.prepare_web_export(self.root);s=(self.out/'index.service.worker.js').read_text();info=json.loads(re.search(r'const INFO = (\{.*?\});',s)[1]);files=json.loads(re.search(r'const FILES = (\[.*?\]);',s)[1]);self.assertIn('aion-latest.json',files)
  self.assertEqual(info['index.html']['sha256'],hashlib.sha256((self.out/'index.html').read_bytes()).hexdigest())
 def test_engine_cannot_register_a_parallel_worker(self):
  web.prepare_web_export(self.root);s=(self.out/'index.html').read_text();self.assertIn('"serviceWorker":""',s);self.assertIn("addEventListener('aion-game-started',registerOffline,{once:true})",s)
 def test_unknown_engine_template_fails_build(self):
  (self.out/'index.html').write_text(self.html.replace('engine.startGame({','engine.otherStart({'))
  with self.assertRaises(RuntimeError):web.prepare_web_export(self.root)
if __name__=='__main__':unittest.main()
