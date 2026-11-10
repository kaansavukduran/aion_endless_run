"""Reject blank emulator screenshots even when the process remains alive."""
import sys
from PIL import Image

for path in sys.argv[1:]:
    image = Image.open(path).convert('RGB').resize((256, 144))
    count = len(set(image.getdata()))
    if count < 200:
        raise SystemExit(f'Blank or incomplete Android render: {path}, {count} colors')
    print(f'Android screen rendered content: {path}, {count} colors')
