"""Contract tests for the generated boot boundary, independent of the engine."""
import hashlib,importlib.util,json,re,shutil,tempfile,unittest,subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('aion_web_updates',ROOT/'packaging/web_updates.py');web=importlib.util.module_from_spec(spec);spec.loader.exec_module(web)
class ExportContract(unittest.TestCase):
 def setUp(self):
  self.temp=tempfile.TemporaryDirectory();self.root=Path(self.temp.name);(self.root/'build/web').mkdir(parents=True);(self.root/'packaging').mkdir();self.out=self.root/'build/web'
  (self.root/'project.godot').write_text('config/version="0.12.0"')
  for name in ['web_update.js','web_worker.js','web_boot.js','web_splash.html','web_accessibility.js','web_storage.js']:shutil.copy2(ROOT/'packaging'/name,self.root/'packaging'/name)
  (self.root/'assets').mkdir()
  for name in ['fragaria-strawberry.png','PixelifySans.ttf']:(self.root/'assets'/name).write_bytes(b'brand fixture')
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
  self.assertEqual(s.count('engine.startGame({...options,onProgress:()=>{},mainPack:PACK_PATH})'),1)
 def test_worker_has_hash_for_final_html_and_latest_endpoint(self):
  web.prepare_web_export(self.root);s=(self.out/'index.service.worker.js').read_text();info=json.loads(re.search(r'const INFO = (\{.*?\});',s)[1]);files=json.loads(re.search(r'const FILES = (\[.*?\]);',s)[1]);self.assertIn('aion-latest.json',files)
  self.assertEqual(info['index.html']['sha256'],hashlib.sha256((self.out/'index.html').read_bytes()).hexdigest())
 def test_engine_cannot_register_a_parallel_worker(self):
  web.prepare_web_export(self.root);s=(self.out/'index.html').read_text();self.assertIn('"serviceWorker":""',s);self.assertIn("addEventListener('aion-game-started',registerOffline,{once:true})",s)
 @unittest.skipUnless(shutil.which('node'), 'Node is used only for the isolated browser-storage contract')
 def test_synchronous_recovery_copy_rejects_corruption_and_denied_storage(self):
  code=(ROOT/'packaging/web_storage.js').read_text()
  script="""const vm=require('node:vm'),assert=require('node:assert/strict');let saved=null;
  const box={window:{},localStorage:{getItem:()=>saved,setItem:(_,v)=>{saved=v}}};vm.runInNewContext(SOURCE,box);
  const api=box.window.AionStorage;assert.equal(api.read(),'');assert.equal(api.write('[prefs]\\ntheme_mode=\\"light\\"',1234),true);
  assert.equal(api.read(),'[prefs]\\ntheme_mode=\\"light\\"');saved='{bad json';assert.equal(api.read(),'');
  saved=JSON.stringify({schema:2,revision:4,config:'x'});assert.equal(api.read(),'');
  box.localStorage.getItem=()=>{throw Error('denied')};box.localStorage.setItem=()=>{throw Error('quota')};
  assert.equal(api.read(),'');assert.equal(api.write('x',3),false);assert.equal(api.write('x',NaN),false);
  """.replace('SOURCE',json.dumps(code))
  subprocess.run(['node','-e',script],check=True)
 def test_unknown_engine_template_fails_build(self):
  (self.out/'index.html').write_text(self.html.replace('engine.startGame({','engine.otherStart({'))
  with self.assertRaises(RuntimeError):web.prepare_web_export(self.root)
class PackageVersionContract(unittest.TestCase):
 def test_native_package_names_match_the_actual_project(self):
  version=re.search(r'config/version="([^"]+)"',(ROOT/'project.godot').read_text())[1]
  linux=(ROOT/'packaging/linux.sh').read_text();windows=(ROOT/'packaging/windows.nsi').read_text()
  self.assertEqual(re.search(r'^version=([^\n]+)',linux,re.M)[1],version)
  self.assertIn('AionEndlessRun-'+version+'-windows-x64-Setup.exe',windows)
  self.assertIn('"DisplayVersion" "'+version+'"',windows)
  self.assertIn('const GAME_VERSION = "'+version+'"',(ROOT/'scripts/game.gd').read_text())
if __name__=='__main__':unittest.main()
