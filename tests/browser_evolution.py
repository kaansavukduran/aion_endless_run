"""Compatibility entry point for the current normal-input evolution suite.
The 0.7 tutorial/progression driver is preserved in history/.
"""
from pathlib import Path
import runpy
runpy.run_path(str(Path(__file__).with_name('browser_frontier.py')),run_name='__main__')
