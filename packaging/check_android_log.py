"""Fail CI on actual Android/Godot startup exceptions."""
import sys
from pathlib import Path

log = Path(sys.argv[1]).read_text(errors='replace')
bad = [line for line in log.splitlines() if any(marker in line for marker in (
    'FATAL EXCEPTION', 'SCRIPT ERROR:', 'Failed to load script', 'INSTALL_FAILED',
))]
if bad:
    print('\n'.join(bad))
    raise SystemExit(1)
print('Android process remained alive; no Java or GDScript startup exception.')
