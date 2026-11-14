"""A transient image lock may retry; permanent failures must remain failures."""
import runpy,sys,tempfile,subprocess,unittest
from pathlib import Path
from unittest.mock import patch
SCRIPT=Path(__file__).resolve().parents[1]/'packaging/macos_dmg.py'
class DmgFailureContract(unittest.TestCase):
 def exercise(self,outputs):
  tmp=tempfile.TemporaryDirectory();self.addCleanup(tmp.cleanup);root=Path(tmp.name);source=root/'app';source.mkdir();destination=root/'game.dmg';calls=[]
  def run(args,**kwargs):
   calls.append(args)
   if args[0]=='hdiutil' and args[1]=='create':
    code,text=outputs.pop(0);result=subprocess.CompletedProcess(args,code,stdout=text)
   else:result=subprocess.CompletedProcess(args,0,stdout='')
   if kwargs.get('check'):result.check_returncode()
   return result
  with patch.object(sys,'argv',[str(SCRIPT),str(source),str(destination)]),patch('subprocess.check_output',return_value='1024 app'),patch('subprocess.run',side_effect=run),patch('time.sleep') as sleep:
   try:runpy.run_path(str(SCRIPT),run_name='__main__')
   except subprocess.CalledProcessError:raise
  return calls,sleep.call_count
 def test_lock_recovers_then_verifies(self):
  calls,waits=self.exercise([(1,'hdiutil: create failed - Resource busy\n'),(0,'done\n')]);self.assertEqual(waits,1);self.assertEqual(sum(a[:2]==['hdiutil','create'] for a in calls),2);self.assertEqual(calls[-1][:2],['hdiutil','verify'])
 def test_permanent_error_is_not_retried(self):
  with self.assertRaises(subprocess.CalledProcessError):self.exercise([(1,'No space left on device\n')])
 def test_lock_retries_are_bounded(self):
  with self.assertRaises(subprocess.CalledProcessError):self.exercise([(1,'Resource busy\n')]*3)
if __name__=='__main__':unittest.main()
