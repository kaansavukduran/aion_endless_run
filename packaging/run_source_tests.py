"""Run the real engine suites; never accept Godot exit0 after SCRIPT ERROR."""
from pathlib import Path
import argparse,json,os,re,subprocess,tempfile
p=argparse.ArgumentParser();p.add_argument('--output',type=Path,default=Path('build/test-results'));p.add_argument('--suites',nargs='*');a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
suites=a.suites or ['game','adventure','localization','evolution','frontier','motion','encounters','fidelity','agility','runner_ux','boss_hud','aionia','variety','visual_polish','orchard','firearm','charge_roll_ui','unslop_quality','pixel_heroes','boss_story','polish']
results=[]
for name in suites:
 env=dict(os.environ);env['XDG_DATA_HOME']=tempfile.mkdtemp(prefix='aion-test-'+name+'-')
 try:
  run=subprocess.run([env.get('GODOT_BIN','godot'),'--headless','--script',f'tests/test_{name}.gd'],env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=150)
  log=run.stdout;code=run.returncode
 except subprocess.TimeoutExpired as error:
  log=(error.stdout or b'').decode() if isinstance(error.stdout,bytes) else (error.stdout or '');code=124
 (a.output/(name+'.log')).write_text(log)
 lines=re.findall(r'RESULT: (\d+) (.*?), (\d+) failures',log)
 script_error=bool(re.search(r'SCRIPT ERROR:|Parse Error:',log))
 assertion_error=bool(re.search(r'^FAIL:',log,re.M))
 passed=code==0 and bool(lines) and all(int(x[2])==0 for x in lines) and not script_error and not assertion_error
 row={'suite':name,'exit_code':code,'passed':passed,'script_error':script_error,'assertion_error':assertion_error,'checks':sum(int(x[0]) for x in lines),'results':lines};results.append(row)
 print(json.dumps(row),flush=True)
(a.output/'source-results.json').write_text(json.dumps(results,indent=2)+'\n')
if not all(x['passed'] for x in results):raise SystemExit(1)
print('ALL SOURCE SUITES PASS:',sum(x['checks'] for x in results),'checks')
