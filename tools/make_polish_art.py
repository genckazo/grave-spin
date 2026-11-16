"""Generate Grave Spin's original graveyard-at-dusk parallax background layers.

Run from the project root:
    /Users/kazo/OpenBot/tools/venv/bin/python tools/make_polish_art.py

All art is drawn here from primitives (original, CC0-equivalent for this
project). Output goes to assets/generated/:
    bg_sky.png  - opaque dusk sky, moon, stars, far hills
    bg_mid.png  - transparent mid layer: gravestones, crosses, dead tree, fog
    bg_near.png - transparent near layer: foreground ground and fence posts
"""
from __future__ import annotations

import math
import os
import random
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "generated")
os.makedirs(OUT, exist_ok=True)

W, H = 640, 360
random.seed(11)


def save(img: Image.Image, name: str) -> None:
    img.save(os.path.join(OUT, name))
    print("wrote", name, img.size)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def make_sky() -> Image.Image:
    img = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    top = (16, 10, 32)
    mid = (74, 34, 66)
    horizon = (179, 84, 46)
    horizon_y = 268
    for y in range(H):
        if y < horizon_y:
            t = y / horizon_y
            c = lerp(top, mid, t ** 1.6)
        else:
            t = (y - horizon_y) / (H - horizon_y)
            c = lerp(horizon, (30, 18, 34), t)
        ImageDraw.Draw(img).line((0, y, W, y), fill=c + (255,))

    # stars in the upper sky
    d = ImageDraw.Draw(img)
    for _ in range(70):
        x, y = random.randint(0, W - 1), random.randint(0, horizon_y - 60)
        a = random.randint(60, 200) if y < 120 else random.randint(20, 90)
        r = random.choice((1, 1, 1, 2))
        d.ellipse((x, y, x + r, y + r), fill=(232, 221, 194, a))

    # moon with a soft glow
    mx, my, mr = 512, 74, 30
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    for r in range(mr + 26, mr, -2):
        a = int(26 * (1 - (r - mr) / 26.0))
        gd.ellipse((mx - r, my - r, mx + r, my + r), fill=(246, 210, 122, a))
    img.alpha_composite(glow.filter(ImageFilter.GaussianBlur(6)))
    d = ImageDraw.Draw(img)
    d.ellipse((mx - mr, my - mr, mx + mr, my + mr), fill=(246, 210, 122, 255))
    # maria
    for (cx, cy, cr) in [(502, 66, 7), (522, 84, 5), (512, 62, 4), (526, 68, 3)]:
        d.ellipse((cx - cr, cy - cr, cx + cr, cy + cr), fill=(214, 178, 104, 255))

    # far hills
    d = ImageDraw.Draw(img)
    for layer, col, base in [((0, 0), (42, 28, 56, 255), 250), ((0, 0), (30, 20, 44, 255), 282)]:
        pts = [(0, base)]
        x = 0
        while x < W:
            x += random.randint(60, 130)
            pts.append((min(x, W), base - random.randint(8, 34)))
        pts.append((W, H))
        pts.append((0, H))
        d.polygon(pts, fill=col)
    return img


def make_mid() -> Image.Image:
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    stone = (46, 38, 62, 255)
    stone_hi = (66, 55, 84, 255)
    ink = (20, 15, 30, 255)

    # rolling ground line for the mid layer
    d.polygon([(0, 316), (120, 306), (260, 314), (420, 304), (560, 312), (W, 306), (W, H), (0, H)], fill=(36, 28, 50, 255))

    # gravestones: rounded tops and crosses
    stones = [(40, 288, 16), (86, 296, 12), (150, 284, 18), (210, 298, 11), (268, 290, 14),
              (360, 286, 15), (430, 296, 12), (500, 288, 17), (580, 296, 12)]
    for (x, y, w) in stones:
        h = w + random.randint(10, 18)
        d.rounded_rectangle((x, y, x + w, y + h), radius=w // 2, fill=stone)
        d.rounded_rectangle((x + 2, y + 2, x + w - 2, y + h - 2), radius=max(1, w // 2 - 2), outline=stone_hi)
        d.line((x + w // 2, y + 6, x + w // 2, y + h - 6), fill=stone_hi, width=1)
        d.line((x + 4, y + h // 2, x + w - 4, y + h // 2), fill=stone_hi, width=1)
    for (x, y) in [(118, 282), (330, 280), (548, 284)]:
        d.rectangle((x + 4, y, x + 8, y + 34), fill=ink)
        d.rectangle((x, y + 7, x + 16, y + 11), fill=ink)

    # dead tree on the left
    tx, ty = 596, 300
    d.line((tx, ty, tx - 4, ty - 46), fill=ink, width=5)
    d.line((tx - 4, ty - 46, tx - 26, ty - 66), fill=ink, width=3)
    d.line((tx - 4, ty - 46, tx + 14, ty - 70), fill=ink, width=3)
    d.line((tx - 4, ty - 30, tx - 20, ty - 44), fill=ink, width=2)
    d.line((tx + 2, ty - 40, tx + 20, ty - 52), fill=ink, width=2)

    # low fog band
    fog = Image.new("RGBA", (W, 40), (0, 0, 0, 0))
    fd = ImageDraw.Draw(fog)
    for x in range(0, W, 24):
        fd.ellipse((x, 8, x + 60, 34), fill=(122, 102, 148, 34))
    img.alpha_composite(fog.filter(ImageFilter.GaussianBlur(7)), (0, 282))
    return img


def make_near() -> Image.Image:
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    ink = (14, 10, 22, 255)
    # foreground ground
    d.polygon([(0, 336), (160, 330), (340, 338), (520, 330), (W, 336), (W, H), (0, H)], fill=ink)
    # fence posts peeking up
    for x in range(8, W, 46):
        h = random.randint(10, 16)
        d.rectangle((x, 336 - h, x + 5, 336), fill=ink)
        d.polygon([(x - 1, 336 - h), (x + 2, 336 - h - 4), (x + 6, 336 - h)], fill=ink)
    # scattered foreground stones
    for (x, y, w) in [(60, 342, 14), (240, 346, 10), (450, 344, 12), (600, 348, 9)]:
        d.rounded_rectangle((x, y, x + w, y + w // 2 + 4), radius=w // 3, fill=(26, 20, 38, 255))
    return img


save(make_sky(), "bg_sky.png")
save(make_mid(), "bg_mid.png")
save(make_near(), "bg_near.png")
