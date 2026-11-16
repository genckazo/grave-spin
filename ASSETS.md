# ASSETS.md — Grave Spin demo slice

All external assets were pulled from Patch.gg via `pch assets add`, which wrote
the credit lines into `assets/raw/CREDITS.md` and `assets/raw/audio/CREDITS.md`
(those files are kept unmodified). Licence texts are in `LICENSES/` and
`assets/raw/LICENSES/`, `assets/raw/audio/LICENSES/`.

## Sprites / icons (all Kenney, CC0 1.0 Universal)

| Asset | Source pack | Files |
|---|---|---|
| Sword, Dice sword, Shield, Dice shield, Skull, Dice skull, Suit hearts, Crown a, Campfire, Bow, Card, Award | Kenney Board Game Icons (https://kenney.nl/assets/board-game-icons) | `assets/raw/sword.png`, `dice_sword.png`, `shield.png`, `dice_shield.png`, `skull.png`, `dice_skull.png`, `suit_hearts.png`, `crown_a.png`, `campfire.png`, `bow.png`, `card.png`, `award.png` |
| Coin | Kenney Game Icons Expansion (https://kenney.nl/assets/game-icons-expansion) | `assets/raw/coin.png` |
| Tiny Dungeon tiles: stone brick wall x2, anvil, wizard, knight with visor, ghost, green slime, blue/red/green potions, round metal shield, short sword, axe | Kenney Tiny Dungeon (https://kenney.nl/assets/tiny-dungeon) | `assets/raw/tile_0014.png`, `tile_0040.png`, `tile_0074.png`, `tile_0084.png`, `tile_0097.png`, `tile_0108.png`, `tile_0114.png`, `tile_0115.png`, `tile_0116.png`, `tile_0102.png`, `tile_0104.png`, `tile_0119.png`, `tile_0121.png` |

Credit line for all of the above: "by Kenney (Kenney, https://kenney.nl), licensed CC0 1.0 Universal (https://creativecommons.org/publicdomain/zero/1.0/)".

## Audio (Kenney, CC0 1.0 Universal, except where noted)

| Sound | Source pack | File |
|---|---|---|
| Click 001 | Kenney Interface Sounds | `assets/raw/audio/click_001.ogg` |
| Metal click, Handle coins, Knife slice | Kenney RPG Audio | `metalClick.ogg`, `handleCoins.ogg`, `knifeSlice2.ogg` |
| Punch / metal light / metal heavy / bell heavy / generic impacts | Kenney Impact Sounds | `impactPunch_medium_000.ogg`, `impactMetal_light_000.ogg`, `impactMetal_heavy_000.ogg`, `impactBell_heavy_000.ogg`, `impactGeneric_light_000.ogg` |
| Chips handle 1, Chips stack 1, Card slide 1 | Kenney Casino Audio | `chips-handle-1.ogg`, `chips-stack-1.ogg`, `card-slide-1.ogg` |
| Low frequency explosion 1 | Kenney Sci-Fi Sounds | `lowFrequency_explosion_000.ogg` |
| 8bit Dungeon Level (music loop) | Kevin MacLeod, incompetech.com — **CC BY 4.0** | `assets/raw/audio/8bit_dungeon_level.ogg` (converted MP3→Ogg by Patch) |

Credit lines: Kenney sounds — "by Kenney (Kenney, https://kenney.nl), licensed CC0 1.0 Universal". Music — "8bit Dungeon Level" by Kevin MacLeod (incompetech.com), licensed CC BY 4.0 International (https://creativecommons.org/licenses/by/4.0/).

## Fonts (SIL Open Font License 1.1)

- Pirata One — `assets/fonts/PirataOne-Regular.ttf`
- Pixelify Sans — `assets/fonts/PixelifySans-Variable.ttf`
- Silkscreen (Regular + Bold) — `assets/fonts/Silkscreen-Regular.ttf`, `Silkscreen-Bold.ttf`

Licence texts: `assets/fonts/OFL-*.txt`, `LICENSES/OFL-1.1.txt`.

## Generated art

Everything under `assets/generated/` was produced locally by
`tools/make_art.py` from the CC0 raw assets above (tinted Kenney icons, composed
machine frame, background, particles, UI panels, enemy sprites). No additional
external source or licence applies.
