# DECISIONS.md — Grave Spin demo slice

Choices made where the brief left room; simpler option taken on ambiguity.

- **Rules data lives in JSON, not GDScript resources.** Relics, enemies, the
  fight ladder and tuning constants are in `data/*.json`, loaded by
  `scripts/game_data.gd`. A relic is a JSON entry with an effect hook resolved
  by `scripts/relic_engine.gd`, so the full game can scale to 30+ relics without
  touching code.
- **Paylines are the 3 rows only** (brief said "the 3 paylines (rows)"), not
  columns/diagonals. Chosen because the brief named rows explicitly.
- **Skull penalty resolves with the enemy's intent** (+2 per skull on the
  incoming attack), per the brief; enemy guard/armor absorbs sword damage
  before HP.
- **Reel spin is cosmetic-timed** (0.9 s total, staggered stops) while the
  outcome grid is decided at pull time; near-miss slow-down on the last reel
  when 2 swords show is visual only.
- **Draft = choose 1 of 3 relics**, max 4 relics per run (`data/config.json`),
  unique offers per draft.
- **Meta-progression is a stub as scoped**: Bone Coins persist in a save file
  (`scripts/meta_save.gd`), shown on the title screen; the unlock tree is out of
  scope.
- **Screens**: title, fight, draft, death/victory, credits — all in
  `scripts/screens/`, orchestrated by `scripts/main.gd`.
- **Balance**: `tools/balance_tune.py` is a standalone Python approximation used
  for tuning only (its constants are a rough copy, not the shipped numbers). The
  shipped numbers live in `data/config.json` and the rules are verified by the
  headless suite `tools/test_state.gd` (36 checks: data loading, payline math,
  relic hooks, draft, full run to victory, meta save). With relic drafting the
  run is winnable; without relics the standalone sim shows ~0%, i.e. relics are
  the power curve as designed.
- **Windows export** via `export_presets.cfg` → `build/windows/GraveSpin.exe`;
  screenshots of all screens in `build/shots/`.
- **Not tested**: real GPU rendering on Windows, gamepad input, and long
  playtest feel (timing/juice judged from screenshots only, since this
  environment is headless macOS).

## Shop economy prices (SYS4)
- Reroll: starts at 2 coins, +1 per reroll within a shop visit, resets next visit.
- Interest: +1 coin per 10 held at shop entry, capped at +5.
- Permanent upgrades (max 1 per shop): Extra Relic Slot 15c, Reroll Discount 12c, Marrow Tonic (+8 max HP) 10c.
- Tuned against the 1000-run sim gate (40-60% normal band): heal_between_fights 15 after boss rules (see SYS3 retune).

## Consumable prices (SYS5)
- Inventory cap 2; sold in shop (1 random per visit) and 50% boss drop.
- Gilded Chisel (replace one symbol) 8c, Bone Saw (remove one Skull -> Blank) 6c, Whetstone Oil (level a symbol type for the run) 10c, Loaded Spring (free reroll mid-fight) 7c.
- Tuned against the 1000-run sim gate: heal_between_fights 16 (was 15) to keep seed 777 in the 40-60% band after SYS5 RNG-stream shifts; normal 45.9/40.8/46.3% IN, high_roller 22.0/23.9/23.0% in 15-35% IN.

## Shop wiring + relic prices (JOB 1)
- Shop screen (scripts/screens/shop_screen.gd) opens after boss fights 5 and 10 (fight index 4 / 9) via GameState.shop_pending; leaving starts the next fight.
- Shop relic prices by rarity (relics had no price field; draft stays free): common 10c, rare 16c, cursed 8c, epic 22c.
- Reroll re-deals relics + consumable stock; price resets on the next visit.
