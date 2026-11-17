"""Build Grave Spin's reel symbol icons from the owner-picked Kenney CC0
assets downloaded from Patch.gg (raw files in assets/raw/patchgg/).

Run from the project root:
    /Users/kazo/OpenBot/tools/venv/bin/python tools/make_symbol_art.py

Mapping (one Kenney icon family per reel symbol, look-only change):
    sword   <- pixel-platformer-food-expansion tile_0080 (candle, 18x18)
    shield  <- tiny-dungeon tile_0065 (tombstone, 16x16)
    potion  <- tiny-dungeon tile_0116 (blue flask, 16x16)
    coin    <- puzzle-pack-2 coin_01 (128x128)
    skull   <- mobile-controls icon_skull (48x48)
    cell    <- micro-roguelike tile_0097 (empty dark slot in stone frame, 128x128)

All scaling is NEAREST (crisp pixels). 16x16 tiles are upscaled by the
whole-number factor 3 to 48px; every icon is centred on a transparent
48x48 canvas with consistent padding. The cell frame is scaled to the
56px reel cell. Output goes to assets/generated/.
"""
from __future__ import annotations

import os
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW = os.path.join(ROOT, "assets", "raw", "patchgg")
OUT = os.path.join(ROOT, "assets", "generated")
os.makedirs(OUT, exist_ok=True)

ICON = 48          # reel symbol canvas
CONTENT = 44       # max content box inside the icon (2px padding each side)
CELL = 56          # reel cell size

# symbol -> (raw file, whole-number upscale hint)
SYMBOLS = {
    "sword": ("tile_0080.png", None),
    "shield": ("tile_0065.png", 3),
    "potion": ("tile_0116.png", 3),
    "coin": ("coin_01.png", None),
    "skull": ("icon_skull.png", None),
}


def save(img: Image.Image, name: str) -> None:
    img.save(os.path.join(OUT, name))
    print("wrote", name, img.size)


def load(name: str) -> Image.Image:
    return Image.open(os.path.join(RAW, name)).convert("RGBA")


def trim(im: Image.Image) -> Image.Image:
    bbox = im.split()[3].getbbox()
    return im.crop(bbox) if bbox else im


def make_icon(raw: str, upscale: int | None) -> Image.Image:
    im = load(raw)
    if upscale:
        im = im.resize((im.width * upscale, im.height * upscale), Image.NEAREST)
    im = trim(im)
    if im.width > CONTENT or im.height > CONTENT:
        s = CONTENT / max(im.width, im.height)
        im = im.resize((max(1, round(im.width * s)), max(1, round(im.height * s))), Image.NEAREST)
    canvas = Image.new("RGBA", (ICON, ICON), (0, 0, 0, 0))
    canvas.paste(im, ((ICON - im.width) // 2, (ICON - im.height) // 2), im)
    return canvas


for symbol, (raw, upscale) in SYMBOLS.items():
    save(make_icon(raw, upscale), f"{symbol}_icon.png")

# reel cell: stone slot frame scaled to the 56px cell
cell = load("tile_0097.png").convert("RGB")
cell = cell.resize((CELL, CELL), Image.NEAREST)
save(cell.convert("RGBA"), "cell_frame.png")
