"""Compatibility entry point for current normal-input motion verification.
Historic 0.8 tests are preserved in history/.
"""
from pathlib import Path
import runpy
runpy.run_path(str(Path(__file__).with_name("browser_motion.py")),run_name="__main__")
