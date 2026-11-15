"""Author the small timber atlas locally; no downloaded art or image transforms.

One source pixel is one world pixel. Plank joins share the same load-bearing
top edge; crate feet are the final row. Re-running produces identical PNGs.
"""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
COLORS = {
    'ink': '#302d30', 'deep': '#433638', 'shade': '#5b4140',
    'wood': '#825b48', 'grain': '#a17653', 'lit': '#bc9467',
    'edge': '#d5b381', 'end': '#6c4d40', 'iron': '#44494a',
    'steel': '#687473', 'glint': '#a9ae91', 'rust': '#8b684b',
    'moss': '#596749', 'leaf': '#829259',
}
atlas = Image.new('RGBA', (192, 96))


def tile(size):
    im = Image.new('RGBA', size)
    return im, ImageDraw.Draw(im)


def rect(d, bounds, color):
    d.rectangle(bounds, fill=COLORS[color])


def line(d, points, color, width=1):
    d.line(points, fill=COLORS[color], width=width)


def nail(d, x, y):
    rect(d, (x, y, x+1, y+1), 'ink')
    d.point((x, y), fill=COLORS['glint'])


def crate():
    im, d = tile((44, 42))
    d.polygon([(2, 0), (40, 0), (43, 3), (43, 39), (41, 41),
               (1, 41), (0, 39), (0, 3)], fill=COLORS['ink'])
    rect(d, (2, 3, 40, 38), 'shade')
    # Recessed vertical boards. Grain follows the individual board, with
    # shaped knots and wear marks instead of uncorrelated random noise.
    for i, (x, width) in enumerate([(4, 8), (13, 8), (22, 8), (31, 8)]):
        rect(d, (x, 6, x+width-1, 36), 'wood' if i % 2 else 'end')
        line(d, [(x, 7), (x, 35)], 'grain')
        line(d, [(x+width-1, 7), (x+width-1, 35)], 'deep')
        y = 12+i*4
        line(d, [(x+3, 7), (x+2, y-2), (x+3, y+3), (x+3, 34)], 'shade')
        line(d, [(x+5, y+6), (x+4, y+9), (x+5, y+12)], 'grain')
    d.ellipse((15, 14, 19, 19), fill=COLORS['shade'])
    line(d, [(16, 15), (18, 16), (18, 18)], 'grain')
    # A single diagonal timber brace stays readable at actual play scale.
    line(d, [(6, 34), (36, 9)], 'deep', 7)
    line(d, [(6, 32), (35, 8)], 'grain', 5)
    line(d, [(6, 30), (34, 7)], 'lit', 1)
    line(d, [(9, 33), (36, 11)], 'wood', 1)
    # Thick mortised frame and a shallow lid bevel.
    rect(d, (2, 2, 40, 5), 'grain')
    line(d, [(3, 1), (39, 1), (41, 3)], 'edge')
    line(d, [(3, 3), (39, 3)], 'lit')
    rect(d, (2, 5, 5, 37), 'grain')
    line(d, [(2, 6), (2, 37)], 'lit')
    rect(d, (38, 5, 41, 38), 'end')
    line(d, [(38, 6), (38, 36)], 'grain')
    rect(d, (3, 37, 40, 39), 'wood')
    line(d, [(4, 37), (38, 37)], 'lit')
    line(d, [(3, 40), (40, 40)], 'deep')
    # Riveted corner straps: dull iron with a single upper-left highlight.
    for x in [2, 35]:
        for y in [4, 31]:
            rect(d, (x, y, x+6, y+6), 'iron')
            line(d, [(x, y+5), (x, y), (x+5, y)], 'steel')
            rect(d, (x+5, y+1, x+6, y+5), 'deep')
            nail(d, x+2, y+2)
    rect(d, (19, 3, 24, 10), 'deep')
    rect(d, (20, 3, 23, 8), 'steel')
    line(d, [(20, 3), (23, 3)], 'glint')
    rect(d, (21, 6, 22, 8), 'ink')
    return im


def deck(variant):
    im, d = tile((32, 24))
    rect(d, (0, 0, 31, 22), 'ink')
    rect(d, (0, 1, 31, 4), 'grain')
    line(d, [(0, 0), (31, 0)], 'edge')
    line(d, [(0, 1), (31, 1)], 'lit')
    # The top row is continuous at every join; only the side grain varies.
    for x in [0, 16]:
        line(d, [(x+1, 2), (x+1, 4)], 'shade')
        line(d, [(x+3, 3), (x+12, 3)], 'wood')
        d.point((x+14, 2), fill=COLORS['deep'])
    rect(d, (0, 6, 31, 18), 'wood')
    line(d, [(0, 6), (31, 6)], 'grain')
    line(d, [(0, 19), (31, 19)], 'deep')
    rect(d, (0, 20, 31, 21), 'end')
    line(d, [(0, 20), (31, 20)], 'grain')
    offset = variant*3
    line(d, [(0, 10), (7, 10), (11, 9), (21, 9), (27, 10), (31, 10)], 'end')
    line(d, [(0, 16), (5+offset, 16), (9+offset, 14), (22+offset, 14)], 'shade')
    line(d, [(3+offset, 8), (9+offset, 8)], 'lit')
    line(d, [(15-offset, 17), (24-offset, 17)], 'grain')
    d.ellipse((10+offset, 10, 16+offset, 14), fill=COLORS['end'])
    line(d, [(11+offset, 11), (14+offset, 11), (15+offset, 12)], 'grain')
    # Lichen is on the underside, away from the traversable top silhouette.
    if variant == 1:
        line(d, [(4, 21), (10, 21), (12, 22), (15, 22)], 'moss')
        d.point((7, 21), fill=COLORS['leaf'])
    return im


def collar():
    im, d = tile((8, 24))
    rect(d, (1, 2, 6, 22), 'ink')
    rect(d, (2, 3, 5, 21), 'iron')
    line(d, [(2, 20), (2, 3), (5, 3)], 'steel')
    rect(d, (5, 5, 6, 20), 'deep')
    nail(d, 3, 6)
    nail(d, 3, 17)
    return im


def post():
    im, d = tile((12, 32))
    rect(d, (0, 0, 11, 31), 'ink')
    rect(d, (1, 0, 9, 31), 'end')
    rect(d, (2, 0, 6, 31), 'wood')
    line(d, [(2, 0), (2, 31)], 'grain')
    line(d, [(9, 0), (9, 31)], 'deep')
    line(d, [(5, 0), (5, 7), (4, 12), (5, 17), (5, 31)], 'shade')
    line(d, [(7, 4), (7, 14), (6, 18), (7, 27)], 'grain')
    line(d, [(3, 22), (3, 28)], 'lit')
    return im


def foot():
    im, d = tile((20, 8))
    d.polygon([(3, 0), (16, 0), (19, 3), (19, 7), (0, 7), (0, 3)], fill=COLORS['ink'])
    rect(d, (2, 3, 17, 6), 'iron')
    line(d, [(3, 2), (16, 2)], 'steel')
    line(d, [(2, 3), (2, 5)], 'glint')
    line(d, [(11, 6), (17, 6)], 'deep')
    nail(d, 4, 4)
    nail(d, 14, 4)
    return im


def brace():
    im, d = tile((32, 32))
    line(d, [(2, 29), (28, 3)], 'ink', 7)
    line(d, [(2, 27), (26, 3)], 'wood', 5)
    line(d, [(1, 25), (24, 2)], 'lit')
    line(d, [(5, 28), (28, 5)], 'shade')
    nail(d, 3, 24)
    nail(d, 24, 3)
    return im


atlas.paste(crate(), (0, 0))
for i in range(3):
    atlas.paste(deck(i), (48+i*32, 0))
atlas.paste(collar(), (144, 0))
atlas.paste(post(), (152, 0))
atlas.paste(foot(), (164, 0))
atlas.paste(brace(), (48, 32))
atlas.paste(brace().transpose(Image.Transpose.FLIP_LEFT_RIGHT), (80, 32))
destination = ROOT/'assets/campaign-timber.png'
atlas.save(destination, optimize=True)
print(destination)
