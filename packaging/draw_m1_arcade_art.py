"""Draw the Mission 1 selection, flying enemy and terrain mechanism sheets.

On the project root, extract the source cels with m1_arcade_sprite_sources.gd
and pass that staging directory to this script. Only original game art is used.
"""
import argparse
from pathlib import Path

from PIL import Image, ImageDraw


# Face patches are in original cel pixels. Each eye has its own shape and
# palette so adjacent highlights, brow, hair and silhouette stay registered.
HEROES = {
    "aion": ((22, 0, 193, 140), [
        ((104, 54, 133, 80), "#f89cb7", "#ffd0dc", "#7a4155"),
        ((157, 55, 171, 76), "#f5a4bf", "#ffd0dc", "#7a4155"),
    ]),
    "sheep": ((0, 0, 157, 154), [
        ((71, 70, 106, 103), "#f8c9ac", "#ffe2c8", "#7b4c3a"),
        ((120, 72, 133, 96), "#f3c2a2", "#ffe2c8", "#724637"),
    ]),
    "rabbit": ((0, 0, 120, 135), [
        ((70, 62, 94, 86), "#d7956b", "#efbc8d", "#58392d"),
        ((105, 65, 115, 85), "#ca8a5e", "#e6ac82", "#58392d"),
    ]),
    "eren": ((0, 0, 143, 126), [
        ((83, 47, 106, 70), "#cc8960", "#e9ac7a", "#62392c"),
        ((119, 49, 132, 69), "#cd8960", "#ebaa7d", "#60372a"),
    ]),
    "armadillo": ((6, 0, 135, 104), [
        ((77, 30, 98, 49), "#d98648", "#f1ad67", "#643525"),
    ]),
    "frog": ((0, 0, 134, 109), [
        ((60, 10, 90, 35), "#76a53b", "#a7d454", "#33491d"),
        ((109, 9, 123, 30), "#709636", "#99bd50", "#344b24"),
    ]),
}
FOES = {
    "gnome": ((31, 58, 50, 73), "#e6ac80", "#f9d0a4", "#644235"),
    "beetle": ((51, 88, 86, 114), "#81506a", "#a16c79", "#3b293d"),
    "crow": ((26, 98, 52, 121), "#454c69", "#5a6382", "#24283d"),
    "slime": ((47, 87, 83, 117), "#7da04c", "#a3b76a", "#455b30"),
}
BAYER = ((0, 8, 2, 10), (12, 4, 14, 6), (3, 11, 1, 9), (15, 7, 13, 5))


def eyelid(image, spec, narrow=False):
    (x, y, right, bottom), base, light, dark = spec
    w, h = right - x, bottom - y
    # Scan a shaped lid. The open part remains on the source layer in the
    # middle cel. The fully shut cel has its own arched lash and light edge.
    top = [(x, y + h * .40), (x + w*.18, y + h*.15), (x + w*.32, y),
           (x + w*.70, y), (right - w*.12, y + h*.18), (right, y + h*.42)]
    low = y + h * (.61 if narrow else .94)
    lower = [(right, low - h*.10), (right - w*.12, low + h*.01),
             (x + w*.64, low + h*.06), (x + w*.30, low + h*.02),
             (x + w*.10, low - h*.06), (x, low - h*.10)]
    points = lambda values: [(round(a), round(b)) for a, b in values]
    patch = Image.new("RGBA", image.size)
    d = ImageDraw.Draw(patch)
    d.polygon(points(top + lower), base)
    d.line(points(top[1:5]), light, max(1, round(h*.13)))
    lash_y = y + h*(.54 if narrow else .63)
    lash = [(x+w*.08, lash_y+h*.10), (x+w*.25, lash_y-h*.06),
            (x+w*.55, lash_y-h*.13), (x+w*.77, lash_y-h*.05),
            (x+w*.92, lash_y+h*.06)]
    d.line(points(lash), dark, max(2, round(h*.14)))
    # The face patch cannot paint outside the source silhouette.
    image.alpha_composite(Image.composite(patch, Image.new("RGBA", image.size), image.getchannel("A")))


def portraits(source):
    cell = (136, 112)
    sheet = Image.new("RGBA", (cell[0]*3, cell[1]*len(HEROES)))
    for row, (name, (crop, eyes)) in enumerate(HEROES.items()):
        base = Image.open(source / f"body-{name}.png").convert("RGBA")
        for frame in range(3):
            pose = base.copy()
            if frame:
                for eye in eyes:
                    eyelid(pose, eye, narrow=frame == 1)
            pose = pose.crop(crop)
            # Consistent body scale through a blink. Fit faces optically,
            # keeping each pair of eyes in identical coordinates in all cels.
            pose.thumbnail((cell[0]-8, cell[1]-5), Image.Resampling.NEAREST)
            alpha = pose.getchannel("A")
            for y in range(max(0, pose.height-10), pose.height):
                keep = (pose.height-y-1)*1.6
                for x in range(pose.width):
                    if BAYER[y%4][x%4] >= keep:
                        alpha.putpixel((x, y), 0)
            pose.putalpha(alpha)
            sheet.alpha_composite(pose, (frame*cell[0]+(cell[0]-pose.width)//2,
                                         row*cell[1]+2))
    return sheet


def spit_cels(source):
    cell = 76
    sheet = Image.new("RGBA", (cell*4, cell*len(FOES)))
    for row, (name, eye) in enumerate(FOES.items()):
        pose = Image.open(source / f"foe-{name}.png").convert("RGBA")
        eyelid(pose, eye)
        pose = pose.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        pose.thumbnail((58, 48), Image.Resampling.NEAREST)
        for frame, angle in enumerate((12, -9, -30, -49)):
            spun = pose.rotate(angle, expand=True, resample=Image.Resampling.NEAREST)
            sheet.alpha_composite(spun, (frame*cell+(cell-spun.width)//2,
                                         row*cell+(cell-spun.height)//2))
    return sheet


def bolt(d, x, y, dark, light):
    d.rectangle((x-1,y-1,x+2,y+2), fill=dark)
    d.point((x,y), fill=light)


MATERIALS = (
    ("#201c23", "#443739", "#755247", "#a17652", "#d2a771", "#61c9a4"),
    ("#12252b", "#29434b", "#49737a", "#709398", "#afc5b6", "#69d9df"),
    ("#252026", "#45384b", "#715571", "#967289", "#c4a299", "#a3c46f"),
)


def gate(d, frame, mat):
    ink, shadow, mid, edge, glint, lamp = mat
    raised = (0, 17, 32, 51, 67, 72)[frame]
    # Plinth, lattice housing, and vertical metal/wood tracks stay planted.
    for x in (14, 43):
        d.polygon([(x-4,94),(x-2,88),(x+8,88),(x+11,94)], fill=ink)
        d.line((x-2,89,x+8,89), fill=edge)
        d.rectangle((x,17,x+6,89), fill=ink)
        d.rectangle((x+1,18,x+4,88), fill=mid)
        d.line((x+1,20,x+1,86), fill=glint)
        for k in range(27, 86, 14):
            d.line((x+2,k,x+4,k+2), fill=edge)
            bolt(d,x+4,k+4,shadow,edge)
    # Armoured plates retract behind the counterweight housing.
    for index in range(6):
        y = 27+index*10-raised
        if y+9<21:
            continue
        a, b = max(21,y), y+9
        d.rectangle((21,a,42,b), fill=ink)
        d.rectangle((22,a+1,41,b-1), fill=mid)
        d.line((22,a+1,41,a+1),fill=edge)
        d.line((22,b-1,41,b-1),fill=shadow)
        if y>20:
            d.polygon([(29,y+2),(33,y+2),(27,y+7),(23,y+7)], fill=shadow)
            d.polygon([(38,y+2),(41,y+2),(35,y+7),(32,y+7)], fill=edge)
            bolt(d,40,y+7,ink,glint)
    tip = max(21,89-raised)
    if tip>22:
        for x in (22,29,36):
            d.polygon([(x,tip-3),(x+4,tip-3),(x+1,tip+4)], fill=ink)
            d.point((x+1,tip), fill=glint)
    d.polygon([(11,10),(15,5),(49,5),(53,10),(53,20),(49,24),(15,24),(11,20)], fill=ink)
    d.rectangle((13,10,51,20),fill=shadow)
    d.line((16,7,48,7),fill=glint)
    d.line((15,10,16,20),fill=edge)
    d.rectangle((23,11,41,18),fill=ink)
    d.rectangle((28,13,36,16),fill=lamp if frame else "#df8751")
    for x in (17,47):
        bolt(d,x,15,ink,glint)
    d.line((0,95,63,95),fill=ink)


def trap(d, row, frame):
    ink = "#221f29"
    warning = frame == 1
    rise = (0, 0, 17, 43, 25)[frame]
    dim, mid, light = (("#334052","#5293a3","#8ee0e2"),
                       ("#353b21","#637a37","#a1bd56"),
                       ("#473036","#a16450","#dfaa72"))[row]
    d.polygon([(3,49),(8,44),(55,44),(60,49),(59,55),(4,55)],fill=ink)
    d.rectangle((7,49,56,53),fill=dim)
    d.line((9,45,54,45),fill=mid)
    for x in range(11,55,7):
        d.line((x,47,x+2,50),fill=light if warning else mid)
    for x in (8,54):
        bolt(d,x,51,ink,light)
    if rise:
        for i, x in enumerate((10,20,31,42,52)):
            top = 46-rise+(i%2)*7
            if row==0:
                path=[(x-3,46),(x+2,top+17),(x-2,top+19),(x+5,top),(x+3,top+15),(x+7,top+15),(x+1,46)]
                d.polygon(path, fill=mid)
                d.line(path[:4], fill=light, width=2)
                d.point((x+5,top-2),fill="#d1f5ea")
            else:
                lean = (i-2)*2
                path=[(x-4,46),(x-3+lean,top+10),(x+lean,top),(x+5+lean,top+7),(x+3,45)]
                d.polygon(path,fill=ink)
                d.line((x-1,44,x-1+lean,top+10,x+lean,top+3),fill=mid,width=3)
                d.line((x+lean,top+4,x+3+lean,top+8),fill=light,width=2)
                if row==1:
                    d.polygon([(x,top+13),(x-7,top+9),(x-5,top+16),(x,top+18)],fill=mid)
                    d.point((x-6,top+12),fill=light)
        d.line((9,46,55,46),fill=light,width=1)


def terrain_sheet():
    sheet = Image.new("RGBA", (6*64, 3*96+3*56))
    for row, mat in enumerate(MATERIALS):
        for f in range(6):
            image = Image.new("RGBA", (64,96))
            gate(ImageDraw.Draw(image), f, mat)
            sheet.paste(image, (f*64,row*96))
    for row in range(3):
        for f in range(5):
            image = Image.new("RGBA", (64,56))
            trap(ImageDraw.Draw(image), row, f)
            sheet.paste(image, (f*64,288+row*56))
    return sheet


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("staging", type=Path)
    parser.add_argument("--output", type=Path, default=Path("assets"))
    args = parser.parse_args()
    portraits(args.staging).save(args.output / "m1-selection-portraits.png", optimize=True)
    spit_cels(args.staging).save(args.output / "m1-frog-spit.png", optimize=True)
    terrain_sheet().save(args.output / "m1-locks-and-traps.png", optimize=True)
