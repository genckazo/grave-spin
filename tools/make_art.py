"""Generate Grave Spin's original art (CC0) and prepare Patch asset derivatives.

Run from the project root:
    /Users/kazo/OpenBot/tools/venv/bin/python tools/make_art.py

All output goes to assets/generated/. Source credits are in CREDITS.md.
"""
from __future__ import annotations

import math
import os
import random
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW = os.path.join(ROOT, "assets", "raw")
OUT = os.path.join(ROOT, "assets", "generated")
os.makedirs(OUT, exist_ok=True)

INK = (10, 8, 14, 255)
DEEP = (22, 17, 30, 255)
STONE = (43, 36, 56, 255)
GOLD = (201, 150, 63, 255)
GOLD_HI = (244, 210, 122, 255)
GOLD_DK = (120, 82, 30, 255)
BONE = (232, 221, 194, 255)
BLOOD = (179, 57, 47, 255)

random.seed(7)


def load(name: str) -> Image.Image:
    return Image.open(os.path.join(RAW, name)).convert("RGBA")


def save(img: Image.Image, name: str):
    img.save(os.path.join(OUT, name))
    print("wrote", name, img.size)


# ---------------------------------------------------------------- reel icons
def trim(im: Image.Image) -> Image.Image:
    bbox = im.split()[3].getbbox()
    return im.crop(bbox) if bbox else im


def tinted_icon(src: str, color, size=48, outline=(14, 10, 19, 255), shadow=True):
    im = trim(load(src))
    # scale to fit size-4 box
    box = size - 4
    scale = min(box / im.width, box / im.height)
    im = im.resize((max(1, int(im.width * scale)), max(1, int(im.height * scale))), Image.LANCZOS)
    alpha = im.split()[3].point(lambda a: 255 if a > 90 else 0)
    body = Image.new("RGBA", im.size, color)
    body.putalpha(alpha)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ox = (size - im.width) // 2
    oy = (size - im.height) // 2
    # outline from alpha dilation
    dil = alpha.filter(ImageFilter.MaxFilter(3))
    edge = Image.new("RGBA", im.size, outline)
    edge.putalpha(dil)
    canvas.alpha_composite(edge, (ox, oy))
    if shadow:
        sh = Image.new("RGBA", im.size, (0, 0, 0, 120))
        sh.putalpha(alpha.point(lambda a: int(a * 0.45)))
        canvas.alpha_composite(sh, (ox + 1, oy + 2))
    canvas.alpha_composite(body, (ox, oy))
    return canvas


def potion_icon(size=48):
    s = size
    im = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # cork
    d.rectangle((s * 0.40, s * 0.06, s * 0.60, s * 0.18), fill=(166, 128, 80, 255), outline=INK)
    # neck
    d.rectangle((s * 0.42, s * 0.17, s * 0.58, s * 0.34), fill=(210, 235, 225, 255), outline=INK)
    # body
    d.ellipse((s * 0.14, s * 0.28, s * 0.86, s * 0.94), fill=(96, 194, 110, 255), outline=INK, width=2)
    # glass highlight
    d.arc((s * 0.20, s * 0.34, s * 0.52, s * 0.72), 150, 260, fill=(220, 255, 220, 255), width=2)
    # liquid surface line
    d.line((s * 0.26, s * 0.50, s * 0.74, s * 0.50), fill=(40, 120, 60, 255), width=2)
    # bubbles
    for x, y, r in [(0.62, 0.62, 2), (0.45, 0.72, 1), (0.55, 0.80, 1)]:
        d.ellipse((s * x - r, s * y - r, s * x + r, s * y + r), fill=(200, 255, 200, 255))
    return im


def gem_icon(size=48):
    s = size
    im = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    pts = [(s * 0.5, s * 0.06), (s * 0.92, s * 0.36), (s * 0.72, s * 0.92), (s * 0.28, s * 0.92), (s * 0.08, s * 0.36)]
    d.polygon(pts, fill=(198, 69, 62, 255), outline=INK)
    d.line((s * 0.5, s * 0.06, s * 0.5, s * 0.92), fill=(120, 30, 36, 255), width=2)
    d.line((s * 0.08, s * 0.36, s * 0.92, s * 0.36), fill=(120, 30, 36, 255), width=2)
    d.polygon([(s * 0.5, s * 0.06), (s * 0.5, s * 0.36), (s * 0.26, s * 0.36)], fill=(240, 130, 120, 255))
    d.polygon([(s * 0.08, s * 0.36), (s * 0.28, s * 0.92), (s * 0.14, s * 0.50)], fill=(160, 44, 44, 255))
    return im


def coin_icon(size=48):
    s = size
    im = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.ellipse((2, 2, s - 3, s - 3), fill=(230, 179, 74, 255), outline=INK, width=2)
    d.ellipse((7, 7, s - 8, s - 8), outline=(140, 94, 28, 255), width=2)
    # skull stamp
    d.ellipse((s * 0.32, s * 0.30, s * 0.68, s * 0.58), fill=(250, 226, 160, 255))
    d.rectangle((s * 0.40, s * 0.53, s * 0.60, s * 0.64), fill=(250, 226, 160, 255))
    d.rectangle((s * 0.40, s * 0.40, s * 0.46, s * 0.47), fill=(120, 80, 20, 255))
    d.rectangle((s * 0.54, s * 0.40, s * 0.60, s * 0.47), fill=(120, 80, 20, 255))
    d.rectangle((s * 0.45, s * 0.55, s * 0.48, s * 0.62), fill=(120, 80, 20, 255))
    d.rectangle((s * 0.52, s * 0.55, s * 0.55, s * 0.62), fill=(120, 80, 20, 255))
    return im


white_icons = {
    "sword.png": (215, 222, 240, 255),
    "shield.png": (111, 158, 214, 255),
    "skull.png": (232, 221, 194, 255),
    "suit_hearts.png": (207, 75, 69, 255),
    "crown_a.png": (230, 179, 74, 255),
    "bow.png": (154, 111, 84, 255),
    "award.png": (230, 179, 74, 255),
    "card.png": (150, 110, 200, 255),
    "dice_sword.png": (222, 190, 110, 255),
    "dice_shield.png": (111, 158, 214, 255),
    "dice_skull.png": (232, 221, 194, 255),
    "campfire.png": (226, 120, 60, 255),
}
for fname, col in white_icons.items():
    out = fname.replace(".png", "_icon.png")
    save(tinted_icon(fname, col), out)
save(potion_icon(), "potion_icon.png")
save(gem_icon(), "gem_icon.png")
save(coin_icon(), "coin_icon.png")

# small coin for particles
save(coin_icon(20), "coin_particle.png")

# ---------------------------------------------------------------- skeleton
def make_skeleton():
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    bone = BONE
    shade = (181, 170, 141, 255)
    eye = (198, 64, 54, 255)
    rust = (138, 90, 58, 255)
    steel = (150, 150, 165, 255)

    d.ellipse((9, 1, 23, 13), fill=bone)
    d.rectangle((12, 11, 20, 14), fill=bone)
    d.rectangle((12, 11, 20, 12), fill=shade)
    for x in range(12, 21, 2):
        d.line((x, 12, x, 14), fill=INK)
    d.rectangle((11, 4, 14, 8), fill=INK)
    d.rectangle((18, 4, 21, 8), fill=INK)
    for px_, py_ in ((12, 5), (13, 6), (19, 5), (20, 6)):
        d.point((px_, py_), fill=eye)
    d.rectangle((15, 7, 17, 9), fill=INK)

    d.rectangle((15, 14, 17, 17), fill=bone)
    d.rectangle((8, 16, 24, 18), fill=bone)
    d.rectangle((10, 18, 12, 19), fill=shade)
    d.rectangle((20, 18, 22, 19), fill=shade)
    d.rectangle((6, 17, 9, 26), fill=bone)
    d.rectangle((23, 17, 26, 26), fill=bone)
    d.rectangle((6, 24, 9, 26), fill=shade)
    d.rectangle((23, 24, 26, 26), fill=shade)

    d.rectangle((15, 18, 17, 28), fill=bone)
    for y in (19, 21, 23, 25):
        d.rectangle((10, y, 14, y), fill=bone)
        d.rectangle((18, y, 22, y), fill=bone)
        d.point((10, y), fill=shade)
        d.point((22, y), fill=shade)

    d.rectangle((11, 27, 21, 29), fill=bone)
    d.rectangle((14, 28, 18, 29), fill=INK)
    d.rectangle((11, 29, 14, 31), fill=bone)
    d.rectangle((18, 29, 21, 31), fill=bone)
    d.rectangle((10, 30, 15, 31), fill=bone)
    d.rectangle((17, 30, 22, 31), fill=bone)

    # rusted sword in the right hand
    d.rectangle((27, 15, 28, 27), fill=steel)
    d.rectangle((27, 15, 27, 27), fill=(210, 210, 220, 255))
    d.rectangle((25, 20, 30, 21), fill=rust)

    alpha = im.split()[3].point(lambda v: 255 if v > 60 else 0)
    outline = Image.new("RGBA", (32, 32), INK)
    outline.putalpha(alpha.filter(ImageFilter.MaxFilter(3)))
    final = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    final.alpha_composite(outline)
    final.alpha_composite(im)
    return final.resize((96, 96), Image.NEAREST)


save(make_skeleton(), "skeleton.png")

# a more hunched cultist silhouette is not needed: Tiny Dungeon wizard is used.

# ---------------------------------------------------------------- flames
def flame_frame(seed):
    rnd = random.Random(seed)
    w, h = 16, 24
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    base_y = 22
    for i in range(9):
        t = i / 8
        x = 8 + rnd.uniform(-1.5, 1.5)
        y = base_y - t * 18
        r = 40 - t * 6
        a = int(230 * (1 - t * 0.4))
        col = (255, 210, 90, a) if t < 0.45 else (255, 140, 50, a) if t < 0.8 else (220, 80, 40, a)
        d.ellipse((x - r / 4, y - r / 4, x + r / 4, y + r / 4), fill=col)
    d.ellipse((2, 18, 14, 25), fill=(255, 170, 60, 140))
    return im


for i, seed in enumerate((3, 8, 13)):
    save(flame_frame(seed), f"flame_{i}.png")

# dust mote
im = Image.new("RGBA", (4, 4), (0, 0, 0, 0))
ImageDraw.Draw(im).rectangle((1, 1, 2, 2), fill=(220, 200, 170, 160))
save(im, "dust.png")

# ---------------------------------------------------------------- background
def vignette(size, strength=210):
    w, h = size
    mask = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(mask)
    cx, cy = w / 2, h / 2
    maxd = math.hypot(cx, cy)
    for y in range(h):
        for x in range(w):
            dist = math.hypot(x - cx, y - cy) / maxd
            mask.putpixel((x, y), int(min(strength, max(0, (dist ** 2.2) * strength))))
    return mask


def make_background():
    W, H = 640, 360
    bg = Image.new("RGBA", (W, H), (12, 10, 18, 255))

    wall = load("tile_0040.png").resize((64, 64), Image.NEAREST)
    floor_tile = load("tile_0014.png").resize((64, 64), Image.NEAREST)

    # wall field
    for y in range(0, 300, 64):
        for x in range(0, W, 64):
            bg.alpha_composite(wall, (x, y))

    # tint and darken the wall
    tint = Image.new("RGBA", (W, 300), (34, 26, 52, 255))
    bg.paste(Image.blend(bg.crop((0, 0, W, 300)), tint, 0.55), (0, 0))

    # floor
    floor = Image.new("RGBA", (W, H - 296), (0, 0, 0, 0))
    for y in range(0, H - 296, 64):
        for x in range(-32, W, 64):
            floor.alpha_composite(floor_tile, (x, y))
    floor = Image.blend(floor, Image.new("RGBA", floor.size, (20, 15, 28, 255)), 0.35)
    # perspective slabs
    fd = ImageDraw.Draw(floor)
    for i, y in enumerate((0, 12, 28, 48)):
        fd.line((0, y, W, y), fill=(78, 62, 92, 255), width=1)
        step = 40 + i * 26
        for x in range(-((i * 17) % step), W, step):
            fd.line((x, y, x - 24, min(floor.height, y + 20)), fill=(30, 24, 40, 255), width=1)
    bg.alpha_composite(floor, (0, 296))

    # gothic arch behind the enemy
    arch = Image.new("RGBA", (220, 260), (0, 0, 0, 0))
    ad = ImageDraw.Draw(arch)
    ad.pieslice((6, 6, 214, 170), 180, 360, fill=(58, 48, 74, 255))
    ad.rectangle((6, 88, 214, 258), fill=(58, 48, 74, 255))
    ad.pieslice((22, 22, 198, 154), 180, 360, fill=(8, 7, 12, 255))
    ad.rectangle((22, 88, 198, 258), fill=(8, 7, 12, 255))
    # arch stones
    for i in range(7):
        a0 = 180 + i * 25.7
        ad.arc((6, 6, 214, 170), a0, a0 + 24, fill=(30, 25, 40, 255), width=3)
    # inner green mist
    mist = Image.new("RGBA", arch.size, (0, 0, 0, 0))
    md = ImageDraw.Draw(mist)
    md.ellipse((40, 120, 190, 260), fill=(60, 120, 90, 40))
    mist = mist.filter(ImageFilter.GaussianBlur(10))
    arch.alpha_composite(mist)
    bg.alpha_composite(arch, (420, 66))

    d = ImageDraw.Draw(bg)

    # chains
    for cx in (268, 372):
        for i in range(11):
            y = 0 + i * 15
            d.ellipse((cx - 3, y, cx + 3, y + 9), outline=(96, 86, 104, 255), width=1)
            d.ellipse((cx - 2, y + 5, cx + 2, y + 10), outline=(62, 54, 70, 255), width=1)

    # torch brackets
    for tx, ty in ((246, 118), (596, 96)):
        d.rectangle((tx - 3, ty, tx + 3, ty + 20), fill=(58, 48, 40, 255))
        d.polygon([(tx - 10, ty + 20), (tx + 10, ty + 20), (tx + 6, ty + 26), (tx - 6, ty + 26)], fill=(44, 36, 30, 255))
        d.rectangle((tx - 6, ty + 26, tx + 6, ty + 30), fill=(28, 22, 20, 255))

    # floor grime and cracks
    for _ in range(80):
        x = random.randint(0, W - 1)
        y = random.randint(300, H - 1)
        d.point((x, y), fill=(70, 56, 82, 255))
    for x0, y0, x1, y1 in [(90, 120, 130, 180), (520, 250, 560, 300), (360, 70, 380, 130)]:
        d.line((x0, y0, x1, y1), fill=(18, 14, 24, 255), width=1)

    # drips from top
    for x in (150, 330, 470, 610):
        d.line((x, 0, x, random.randint(10, 40)), fill=(48, 30, 42, 255), width=2)

    # vignette
    bg.putalpha(255)
    v = vignette((W, H), 190)
    black = Image.new("RGBA", (W, H), (3, 2, 6, 255))
    black.putalpha(v)
    bg.alpha_composite(black)
    return bg


save(make_background(), "background.png")

# ---------------------------------------------------------------- slot machine
def make_machine():
    W, H = 200, 260
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)

    # drop shadow
    sh = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle((6, 10, W - 3, H - 3), radius=9, fill=(0, 0, 0, 150))
    sh = sh.filter(ImageFilter.GaussianBlur(4))
    im.alpha_composite(sh)

    # body
    d.rounded_rectangle((2, 2, W - 8, H - 8), radius=8, fill=(38, 31, 49, 255), outline=INK, width=2)
    # metal gradient bands
    for y in range(6, H - 12, 6):
        shade = 8 if (y // 6) % 2 else 0
        d.line((4, y, W - 11, y), fill=(46 + shade, 38 + shade, 59 + shade, 255))
    d.rounded_rectangle((6, 6, W - 12, H - 12), radius=6, outline=GOLD_DK, width=1)
    d.rounded_rectangle((9, 9, W - 15, H - 15), radius=5, outline=(16, 12, 22, 255), width=1)

    # marquee plate
    d.rounded_rectangle((16, 12, W - 22, 46), radius=3, fill=(15, 12, 22, 255), outline=GOLD, width=2)
    d.line((20, 16, W - 26, 16), fill=(83, 60, 90, 255))
    for cx in (24, W - 30):
        d.rectangle((cx - 2, 40, cx + 2, 44), fill=GOLD_DK)
        d.point((cx, 42), fill=GOLD_HI)

    # reel window
    wx0, wy0, wx1, wy1 = 16, 56, 184, 224
    d.rectangle((wx0 - 4, wy0 - 4, wx1 + 4, wy1 + 4), fill=(13, 10, 18, 255), outline=GOLD_DK, width=2)
    d.rectangle((wx0, wy0, wx1, wy1), fill=(8, 6, 12, 255))
    # cell bevels + grid
    cell = 56
    for r in range(3):
        for c in range(3):
            x = wx0 + c * cell
            y = wy0 + r * cell
            d.rectangle((x + 2, y + 2, x + cell - 3, y + cell - 3), fill=(17, 13, 24, 255))
            d.rectangle((x + 2, y + 2, x + cell - 3, y + cell - 3), outline=(58, 44, 74, 255))
            d.line((x + 3, y + 3, x + cell - 4, y + 3), fill=(28, 21, 38, 255))
    for i in range(1, 3):
        d.line((wx0 + i * cell, wy0, wx0 + i * cell, wy1), fill=(96, 70, 38, 255), width=2)
        d.line((wx0, wy0 + i * cell, wx1, wy0 + i * cell), fill=(96, 70, 38, 255), width=2)
    d.rectangle((wx0 - 1, wy0 - 1, wx1 + 1, wy1 + 1), outline=(6, 5, 9, 255), width=2)

    # payline arrows
    for r in range(3):
        y = wy0 + r * cell + cell // 2
        d.polygon([(6, y), (12, y - 4), (12, y + 4)], fill=GOLD)
        d.polygon([(W - 14, y), (W - 8, y - 4), (W - 8, y + 4)], fill=GOLD)

    # base / coin tray
    d.rounded_rectangle((16, 232, W - 22, 250), radius=2, fill=(20, 16, 28, 255), outline=GOLD_DK, width=1)
    d.rectangle((16, 232, W - 22, 236), fill=(6, 5, 9, 255))
    for i, cx in enumerate(range(28, W - 32, 18)):
        cy = 246 - (i % 2) * 3
        d.ellipse((cx - 4, cy - 4, cx + 4, cy + 4), fill=(214, 164, 62, 255), outline=(108, 72, 20, 255))
    # feet
    d.rectangle((14, 250, 38, 256), fill=(24, 19, 32, 255), outline=INK)
    d.rectangle((W - 44, 250, W - 20, 256), fill=(24, 19, 32, 255), outline=INK)

    # rivets
    for rx, ry in [(12, 12), (W - 18, 12), (12, 230), (W - 18, 230), (12, 52), (W - 18, 52)]:
        d.ellipse((rx - 2, ry - 2, rx + 2, ry + 2), fill=(120, 98, 66, 255), outline=INK)

    # side lever bracket
    d.rectangle((W - 9, 120, W - 3, 150), fill=(30, 24, 40, 255), outline=INK)
    return im


save(make_machine(), "machine_frame.png")


def make_lever():
    W, H = 28, 128
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # pivot bracket at bottom
    d.rectangle((4, 112, 24, 126), fill=(30, 24, 40, 255), outline=INK, width=2)
    d.ellipse((10, 116, 18, 124), fill=(90, 74, 58, 255), outline=INK)
    # shaft
    d.rectangle((11, 24, 17, 118), fill=(74, 62, 92, 255), outline=INK, width=1)
    d.line((13, 26, 13, 116), fill=(120, 104, 140, 255))
    # sword-hilt handle
    d.rectangle((8, 10, 20, 26), fill=(120, 84, 40, 255), outline=INK, width=1)
    for y in range(12, 25, 4):
        d.line((9, y, 19, y + 2), fill=(84, 56, 26, 255))
    # crossguard
    d.polygon([(2, 4), (26, 4), (23, 10), (5, 10)], fill=GOLD, outline=INK)
    # pommel
    d.ellipse((10, 0, 18, 7), fill=GOLD_HI, outline=INK)
    return im


save(make_lever(), "lever.png")

# ---------------------------------------------------------------- title emblem / icon
def make_icon(size=128):
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((2, 2, size - 3, size - 3), radius=18, fill=(18, 14, 26, 255), outline=GOLD, width=3)
    d.rounded_rectangle((10, 10, size - 11, size - 11), radius=12, outline=(86, 62, 34, 255), width=2)
    skull = tinted_icon("skull.png", (232, 221, 194, 255), size=86, shadow=False)
    im.alpha_composite(skull, (21, 20))
    d.line((26, 104, size - 26, 104), fill=GOLD_DK, width=2)
    return im


save(make_icon(), "icon.png")
icon = Image.open(os.path.join(OUT, "icon.png"))
# Windows needs a 256px entry in the .ico or Godot's rcedit export step warns.
icon = icon.resize((256, 256), Image.NEAREST)
icon.save(os.path.join(ROOT, "icon.png"))
icon.save(os.path.join(ROOT, "icon.ico"), sizes=[(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])

# ---------------------------------------------------------------- UI 9-slices
def make_panel(fill, border, inner, name, studs=True):
    im = Image.new("RGBA", (24, 24), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 23, 23), fill=border)
    d.rectangle((1, 1, 22, 22), fill=fill)
    d.rectangle((2, 2, 21, 21), outline=inner)
    if studs:
        for x, y in ((3, 3), (20, 3), (3, 20), (20, 20)):
            d.point((x, y), fill=GOLD_HI)
    return im


save(make_panel((18, 13, 27, 242), (98, 72, 38, 255), (52, 39, 66, 255), "ui_panel.png"), "ui_panel.png")
save(make_panel((24, 17, 32, 248), (150, 108, 44, 255), (64, 46, 78, 255), "ui_card.png"), "ui_card.png")
save(make_panel((40, 31, 50, 255), (130, 94, 40, 255), (66, 52, 82, 255), "ui_button.png"), "ui_button.png")
save(make_panel((56, 42, 70, 255), (244, 210, 122, 255), (92, 70, 110, 255), "ui_button_hover.png"), "ui_button_hover.png")
save(make_panel((30, 24, 38, 255), (98, 74, 38, 255), (48, 38, 58, 255), "ui_button_pressed.png"), "ui_button_pressed.png")
save(make_panel((28, 25, 32, 230), (58, 52, 62, 255), (44, 38, 50, 255), "ui_button_disabled.png"), "ui_button_disabled.png")

# soft shadow under characters
sh = Image.new("RGBA", (96, 28), (0, 0, 0, 0))
ImageDraw.Draw(sh).ellipse((6, 6, 90, 24), fill=(0, 0, 0, 120))
sh = sh.filter(ImageFilter.GaussianBlur(4))
save(sh, "shadow.png")

# spark
sp = Image.new("RGBA", (5, 5), (0, 0, 0, 0))
sd = ImageDraw.Draw(sp)
sd.rectangle((2, 0, 2, 4), fill=(255, 236, 180, 255))
sd.rectangle((0, 2, 4, 2), fill=(255, 220, 140, 255))
sd.point((2, 2), fill=(255, 255, 255, 255))
save(sp, "spark.png")

# ---------------------------------------------------------------- logo
def make_logo():
    font = ImageFont.truetype(os.path.join(ROOT, "assets", "fonts", "PirataOne-Regular.ttf"), 88)
    text = "GRAVE SPIN"
    W, H = 620, 132
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    bbox = d.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    x = (W - tw) // 2 - bbox[0]
    y = 14 - bbox[1]

    # red underglow
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(glow).text((x, y), text, font=font, fill=(150, 30, 34, 255), stroke_width=5, stroke_fill=(120, 20, 26, 255))
    glow = glow.filter(ImageFilter.GaussianBlur(9))
    im.alpha_composite(glow)

    # black shadow
    sh = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(sh).text((x + 4, y + 5), text, font=font, fill=(0, 0, 0, 220), stroke_width=3, stroke_fill=(0, 0, 0, 220))
    im.alpha_composite(sh.filter(ImageFilter.GaussianBlur(1)))

    # gold gradient fill mask
    mask = Image.new("L", (W, H), 0)
    ImageDraw.Draw(mask).text((x, y), text, font=font, fill=255, stroke_width=3, stroke_fill=255)
    grad = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(grad)
    for yy in range(H):
        t = max(0.0, min(1.0, (yy - 10) / 90))
        col = (int(246 - 60 * t), int(210 - 80 * t), int(122 - 60 * t), 255)
        gd.line((0, yy, W, yy), fill=col)
    grad.putalpha(mask)

    # dark rim
    rim = Image.new("RGBA", (W, H), (10, 8, 14, 255))
    rim.putalpha(mask.filter(ImageFilter.MaxFilter(3)))
    im.alpha_composite(rim)
    im.alpha_composite(grad)

    # skull ornaments
    skull_l = tinted_icon("skull.png", (232, 221, 194, 255), size=40, shadow=False)
    im.alpha_composite(skull_l, (6, 56))
    im.alpha_composite(skull_l, (W - 46, 56))
    return im


save(make_logo(), "logo.png")

print("art done")
