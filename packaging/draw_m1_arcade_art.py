"""Pack the Mission 1 portraits, flying enemies and terrain mechanisms.

The staging directory holds cels extracted by m1_arcade_sprite_sources.gd.
To rebuild the portraits, also pass the three 2×3 portrait source illustrations
(open, half, closed) with --portraits. Only the registered eye windows move.
"""
import argparse
from math import sin, tau
from pathlib import Path

from PIL import Image, ImageDraw


# Face patches are in original cel pixels. Each eye has its own shape and
# palette so adjacent highlights, brow, hair and silhouette stay registered.
PORTRAIT_EYES = (
    ((151, 197, 293, 310), (341, 263, 445, 355)),  # Aion
    ((675, 239, 813, 333), (851, 205, 925, 302)),  # Kutsanmış
    ((190, 722, 335, 839), (379, 724, 457, 839)),  # Ayça
    ((737, 718, 862, 826), (896, 778, 982, 866)),  # Eren
    ((181, 1195, 325, 1300),),                  # Armadillo
    ((604, 1064, 800, 1239), (835, 1072, 970, 1224)),  # Kurbağa
)
FOES = {
    "gnome": ((31, 58, 50, 73), "#e6ac80", "#f9d0a4", "#644235"),
    "beetle": ((51, 88, 86, 114), "#81506a", "#a16c79", "#3b293d"),
    "crow": ((26, 98, 52, 121), "#454c69", "#5a6382", "#24283d"),
    "slime": ((47, 87, 83, 117), "#7da04c", "#a3b76a", "#455b30"),
}


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


def portraits(sources):
    cell = 256
    open_eyes, half, closed = [Image.open(path).convert("RGB") for path in sources]
    assert all(image.size == (1024, 1536) for image in (open_eyes, half, closed))
    sheet = Image.new("RGB", (cell * 3, cell * len(PORTRAIT_EYES)))
    for row, eyes in enumerate(PORTRAIT_EYES):
        x, y = (row % 2) * 512, (row // 2) * 512
        tile = (x, y, x + 512, y + 512)
        original = open_eyes.crop(tile)
        for frame, image in enumerate((open_eyes, half, closed)):
            pose = original.copy()
            if frame:
                for left, top, right, bottom in eyes:
                    region = (left, top, right, bottom)
                    pose.paste(image.crop(region), (left - x, top - y))
            sheet.paste(pose.resize((cell, cell), Image.Resampling.NEAREST),
                        (frame * cell, row * cell))
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
    ("#211c24", "#493641", "#805448", "#bf885a", "#efd29a", "#a5e7a3"),
    ("#152631", "#31404b", "#5a7879", "#88a5a3", "#d6dcc0", "#82dfdb"),
    ("#241c2a", "#4c384e", "#805b68", "#ac7c76", "#d7b48d", "#c3d883"),
)


def gate(image, frame, mat):
    d = ImageDraw.Draw(image)
    ink, shade, base, bright, rim, signal = mat
    travel = (0, 14, 29, 45, 57, 76)[frame]
    for side in (0, 1):
        def xy(x, y):
            return (63-x if side else x, y)

        def piece(points, color):
            d.polygon([xy(*point) for point in points], fill=color)

        piece([(3,95),(3,89),(7,86),(7,28),(10,21),(16,21),
               (19,27),(19,88),(23,91),(23,95)], ink)
        piece([(6,93),(6,90),(10,87),(10,28),(12,24),(16,27),
               (16,86),(20,90),(20,93)], shade)
        piece([(8,91),(11,87),(11,30),(13,27),(15,30),(15,87),(18,91)], base)
        d.line([xy(11,31),xy(11,86),xy(8,90)], fill=bright)
        d.line([xy(12,31),xy(12,64)], fill=rim)
        d.line([xy(14,35),xy(14,81)], fill=shade)
        for y in (32, 56, 81, 90):
            d.line([xy(7,y),xy(18,y)], fill=ink, width=4)
            d.line([xy(8,y-1),xy(17,y-1)], fill=base)
            d.point(xy(15,y-1),fill=rim)
        # Coiled conduit on the stationary feet.
        d.line([xy(5,85),xy(5,72),xy(8,69),xy(9,62)], fill=ink, width=3)
        d.line([xy(5,85),xy(5,73),xy(7,71),xy(9,64)], fill=shade)
        d.point(xy(5,77),fill=bright)

    leaf = Image.new("RGBA", (64,96))
    a = ImageDraw.Draw(leaf)
    a.polygon([(17,24),(46,24),(46,87),(42,92),(38,90),(35,93),
               (28,93),(25,90),(21,92),(17,87)], fill=ink)
    a.rectangle((19,25,44,87),fill=shade)
    for index in range(5):
        y=26+index*12
        a.polygon([(19,y+3),(22,y),(41,y),(44,y+3),(44,y+10),
                   (41,y+11),(22,y+11),(19,y+9)],fill=base)
        a.line((22,y+1,40,y+1),fill=bright)
        a.line((22,y+10,41,y+10),fill=shade)
        a.polygon([(24,y+3),(31,y+3),(37,y+8),(31,y+8)],fill=shade)
        a.line((34,y+3,40,y+7),fill=bright)
        a.point((40,y+7),fill=rim)
    for x in (20,43):
        a.line((x,26,x,86),fill=bright)
        for y in (28,54,78):a.point((x,y),fill=rim)
    a.line((21,89,42,89),fill=bright,width=2)
    # The ribbed leaf slides behind the same opaque counterweight crown.
    if travel<69:
        cropped=leaf.crop((17,25+travel,47,94))
        image.alpha_composite(cropped, (17,25))
    d.polygon([(4,18),(4,13),(12,5),(21,5),(26,2),(37,2),(42,5),(51,5),(59,13),
               (59,18),(53,23),(47,27),(16,27),(10,23)],fill=ink)
    d.polygon([(6,14),(13,7),(22,7),(27,4),(36,4),(41,7),(50,7),(57,14),
               (56,17),(51,22),(45,24),(18,24),(12,22),(7,17)],fill=shade)
    d.line([(7,14),(14,8),(23,8),(28,5),(35,5),(40,8),(49,8),(56,14)],fill=rim)
    d.line((14,22,49,22),fill=base,width=2)
    for x in (14,48):
        d.rectangle((x,12,x+2,18),fill=ink)
        d.point((x+1,13),fill=bright)
        d.point((x+1,17),fill=rim)
    d.polygon([(25,13),(29,9),(34,9),(38,13),(38,17),(34,21),(29,21),(25,17)],fill=ink)
    d.line([(26,13),(30,10),(33,10),(37,13)],fill=bright)
    d.polygon([(28,14),(31,11),(33,11),(36,14),(36,16),(33,19),(31,19),(28,16)],
              fill=signal if frame else "#de8553")
    d.line((30,14,33,12),fill="#ffdab0")

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
            gate(image, f, mat)
            sheet.paste(image, (f*64,row*96))
    for row in range(3):
        for f in range(5):
            image = Image.new("RGBA", (64,56))
            trap(ImageDraw.Draw(image), row, f)
            sheet.paste(image, (f*64,288+row*56))
    return sheet


def hatch_sheet():
    sheet = Image.new("RGBA", (192, 80))
    d = ImageDraw.Draw(sheet)
    ink, rain, wood, grain, trim = "#27202a", "#4a3c40", "#9c6445", "#c98d56", "#ebbb78"
    # A 64px tile with an exact, level top and a repeated iron seam.
    d.polygon([(0,0),(63,0),(63,11),(59,13),(5,13),(0,11)], fill=ink)
    d.rectangle((0,1,63,9),fill=rain)
    d.rectangle((4,1,60,7),fill=wood)
    d.line((4,1,60,1),fill=trim)
    for x, width in ((8,9),(21,13),(39,8),(51,7)):
        d.line((x,4,x+width,4),fill=grain)
        d.line((x+2,6,x+width,6),fill=rain)
    for x in (0,31,62):
        d.line((x,0,x,11),fill=ink,width=2)
        d.point((x,2),fill=trim)
        d.point((x,7),fill=grain)
    d.line((3,10,60,10),fill=grain)
    # Fixed cut edge with torn timber and roots over the exposed lower lane.
    d.polygon([(64,0),(100,0),(107,3),(100,6),(92,5),(89,12),(83,10),(80,21),
               (76,24),(76,14),(70,17),(68,9),(64,8)],fill=ink)
    d.polygon([(64,1),(100,1),(103,3),(93,4),(87,10),(82,9),(78,18),(77,11),
               (71,14),(68,8),(64,7)],fill=wood)
    d.line([(64,1),(99,1),(103,3)],fill=trim)
    d.line([(67,6),(82,6),(89,4)],fill=grain)
    d.line([(73,3),(69,10),(73,16),(69,25),(72,28)],fill="#44402d",width=3)
    d.line([(73,3),(70,9),(74,15),(70,25)],fill="#9ca258")
    # A capped root-and-iron fence post, foot registered at row 79.
    d.polygon([(137,79),(137,75),(142,72),(143,10),(140,8),(140,5),(143,2),
               (150,2),(154,6),(152,11),(151,70),(154,75),(157,77),(157,79)],fill=ink)
    d.polygon([(140,77),(145,73),(145,11),(149,10),(149,72),(154,77)],fill=wood)
    d.line((145,12,145,71),fill=trim)
    d.line((147,15,147,68),fill=rain)
    for y in (15,35,55,70):
        d.rectangle((140,y,152,y+4),fill=ink)
        d.line((141,y+1,151,y+1),fill="#748181")
        d.point((144,y+2),fill=trim)
    d.line([(141,78),(139,69),(142,63),(142,50),(145,46)],fill="#6f8051",width=2)
    return sheet


def ribbon_flame(d, points, widths, edge, body, core):
    # All cross-sections are quantized onto the same cel pixel grid.
    upper, lower = [], []
    for (x, y), width in zip(points, widths):
        upper.append((round(x),round(y-width)))
        lower.append((round(x),round(y+width)))
    d.polygon(upper+lower[::-1],fill=edge)
    upper = [(round(x),round(y-max(0,w-1.2))) for (x,y),w in zip(points,widths)]
    lower = [(round(x),round(y+max(0,w-1.2))) for (x,y),w in zip(points,widths)]
    d.polygon(upper+lower[::-1],fill=body)
    hot_upper = [(round(x),round(y-.4-w*.43)) for (x,y),w in zip(points[2:],widths[2:])]
    hot_lower = [(round(x),round(y+.1+w*.22)) for (x,y),w in zip(points[2:],widths[2:])]
    d.polygon(hot_upper+hot_lower[::-1],fill=core)


def sprint_fire_sheet():
    width, height = 64, 36
    sheet = Image.new("RGBA", (width*8,height*2))
    for frame in range(8):
        angle = tau*frame/8
        for layer in range(2):
            image = Image.new("RGBA", (width,height))
            d = ImageDraw.Draw(image)
            if layer == 0:
                # The far ribbon climbs and tapers over the runner's wake.
                xs = [3,8,15,21,27,32,37,42,47,50]
                ys = [11,15,17,15,13,13,16,21,23,22]
                widths = [.1,.8,2.2,3.3,4.3,5.3,5.7,5.5,4.2,.2]
                wave = [3.0,3.7,4.0,4.4,4.5,3.5,3.4,2.0,1.,.5]
                colors = ("#7d3137","#d95838","#ffbe63")
            else:
                # Near side hooks around the shins, with a hotter inner seam.
                xs = [10,17,23,29,36,42,48,53,57,58]
                ys = [29,26,27,29,30,30,28,25,22,19]
                widths = [.1,.6,1.3,2.1,2.6,3.1,3.1,2.6,1.6,.15]
                wave = [2.6,3.1,2.3,1.6,1.3,1.1,1.4,1.7,1.7,1.5]
                colors = ("#923839","#f8823d","#ffe59b")
            points=[(x,y+amplitude*sin(angle+i*.54+layer*.8)) for i,(x,y,amplitude) in enumerate(zip(xs,ys,wave))]
            ribbon_flame(d,points,widths,*colors)
            for i in range(4):
                x = (44-((frame*5+i*11)%40)) if layer==0 else (46-((frame*4+i*9)%34))
                y = round((12 if layer==0 else 31)+sin(i+angle)*2-(4 if i==3 else 0))
                d.line((x,y,x+(2 if i%2 else 1),y),fill=colors[1])
                if i%2: d.point((x+1,y),fill=colors[2])
            sheet.paste(image, (frame*width,layer*height))
    return sheet


def route_hazard_sheet():
    sheet = Image.new("RGBA", (320,144))
    for frame in range(5):
        for row in range(2):
            image = Image.new("RGBA", (64,72))
            d = ImageDraw.Draw(image)
            ink = "#1b2731" if row==0 else "#282334"
            d.polygon([(8,71),(6,67),(12,62),(24,61),(40,61),(51,62),(57,67),(55,71)],fill=ink)
            d.polygon([(9,68),(14,64),(49,64),(54,68),(52,70),(11,70)],fill="#4c5d5d")
            d.line((13,65,50,65),fill="#819879")
            if row==0:
                # Wind grate with left-facing flow and a readable amber warning bank.
                for x in range(16,52,8):
                    d.line((x,66,x-4,69),fill=ink,width=2)
                    if frame==1:d.point((x-1,63),fill="#efba6f")
                if frame>=2:
                    drift=(frame-2)*3
                    for strip in range(3):
                        y=48-strip*12+drift
                        start=50-strip*3
                        d.line([(start,y+3),(start-7,y-4),(28,y-4),(20,y),
                                (7+drift,y),(4+drift,y-3)],fill="#34515c",width=4)
                        d.line([(start-3,y+1),(start-8,y-4),(29,y-4),(21,y-1),(9+drift,y-1)],
                               fill="#72b9bb",width=2)
                        d.line((22,y-1,13+drift,y-1),fill="#d1e9cb")
                        d.point((5+drift,y+2),fill="#c8deb3")
            else:
                # A grounded crystal column rises to the real projectile socket.
                d.polygon([(19,66),(20,47),(22,38),(22,25),(27,11),(33,8),(40,14),(42,27),
                           (41,41),(45,55),(44,65),(39,69),(26,69)],fill=ink)
                d.polygon([(22,64),(23,48),(25,37),(25,25),(30,14),(35,12),(38,16),
                           (39,29),(37,43),(41,55),(41,65),(37,67),(27,67)],
                          fill="#675777")
                d.polygon([(25,51),(30,44),(35,28),(36,17),(31,13),(26,24),(26,39)],fill="#9b7799")
                d.polygon([(27,36),(31,37),(35,31),(38,20),(35,14),(31,13),(27,24)],fill="#b883bd")
                d.line([(27,26),(32,17),(34,16),(32,24)],fill="#e2b9d6")
                d.polygon([(29,55),(31,40),(34,34),(38,30),(37,43),(40,56),(39,60)],fill="#49465f")
                d.line([(29,54),(32,43),(35,36),(37,35)],fill="#a87eb4")
                d.line([(24,50),(25,42),(26,37),(29,35)],fill="#c194bf")
                d.polygon([(12,62),(14,50),(18,43),(23,44),(27,55),(27,63),(22,68),(16,68)],fill=ink)
                d.polygon([(15,60),(16,51),(19,46),(22,48),(24,55),(24,63),(21,65),(17,64)],fill="#806b92")
                d.polygon([(16,59),(18,49),(20,47),(21,52),(20,61)],fill="#c094c7")
                d.line((17,56,18,51),fill="#edbedc")
                d.polygon([(39,66),(41,56),(46,48),(51,49),(54,58),(53,65),(48,69)],fill=ink)
                d.polygon([(42,65),(44,56),(47,51),(50,53),(51,58),(49,65)],fill="#8f639d")
                d.line([(43,62),(45,55),(47,52),(49,54)],fill="#d8a5c8")
                d.line([(21,62),(27,56),(33,60),(38,59),(44,64)],fill="#b18091",width=2)
                light = "#7e689a" if frame==0 else ("#efb18b" if frame==1 else "#edc2f2")
                d.polygon([(26,16),(30,12),(35,12),(39,16),(35,20),(30,20)],fill=light)
                if frame:
                    for side in (-1,1):
                        for offset in range(8,24,7):
                            x=32+side*(offset+frame)
                            d.line((x,14,x+2,14),fill=light)
            sheet.paste(image,(frame*64,row*72))
    return sheet


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("staging", type=Path)
    parser.add_argument("--output", type=Path, default=Path("assets"))
    parser.add_argument("--portraits", nargs=3, type=Path, metavar=("OPEN", "HALF", "CLOSED"))
    args = parser.parse_args()
    if args.portraits:
        portraits(args.portraits).save(args.output / "m1-selection-portraits.png", optimize=True)
    spit_cels(args.staging).save(args.output / "m1-frog-spit.png", optimize=True)
    terrain_sheet().save(args.output / "m1-locks-and-traps.png", optimize=True)
    hatch_sheet().save(args.output / "m1-root-hatch.png", optimize=True)
    sprint_fire_sheet().save(args.output / "m1-sprint-fire.png", optimize=True)
    route_hazard_sheet().save(args.output / "m1-route-hazards.png", optimize=True)
