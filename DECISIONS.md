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
