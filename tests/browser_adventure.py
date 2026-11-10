"""Current adventure regression entry point.

The tutorial-mushroom/held-autofire driver is preserved under history/ for
0.5/0.6. Current gameplay is verified by the real-input evolution suite.
"""
from pathlib import Path
import runpy
runpy.run_path(str(Path(__file__).with_name('browser_evolution.py')),run_name='__main__')
