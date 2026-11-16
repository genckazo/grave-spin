# PHASE-1 BACKLOG — CURSED DICE (paper spec for the build, then execute in order)

Scoped from FULL_RELEASE_SPEC.md. Baseline exact numbers from `data/*.json` at
the demo commit: 29 faces (4 starter / 20 draft / 4 corrupt / 1 curse), 5
enemies (Bone Rat 18, Wraith 23, Hollow Knight 25, Stone Golem 32, Cursed Warden
65 boss), player_hp 49 (shipped; demo said 52), heal_between_fights 7, dice_count 5,
7-fight linear ladder, 0 trinkets, no node map, no corruption track, no outcome prediction.
Demo sim: 200 runs/seed, win rates 54.0/38.0/52.5/56.0% on seeds 12345/777/2024/999
(seed 999 is 1 point OVER the 55% edge — reported plainly, not rounded in).

## Tasks

### CD-1. Act-1 node map replaces the linear ladder — effort L
- **Content numbers:** `data/act1.json` — act 1 "The Burrow", 4 rows of nodes
  (fight / elite-fight / event / shop / rest), ending in the boss node
  (Cursed Warden, hp 65). Fights reference `data/enemies.json` with optional
  hp_bonus/atk_bonus (same schema as the old run.json ladder). Node count:
  12 nodes total across 5 rows, boss at row 4 (n12). `data/run.json` keeps
  player_hp 49, heal_between_fights 7, dice_count 5; the linear `fights`
  array is retired from play (kept in file for reference).
- **Acceptance (headless):** map loads with 12 nodes; `available_nodes()`
  returns row-0 nodes at start; `choose_node()` advances exactly one row per
  pick; after 4 picks the boss node is the only option; beating the boss sets
  act complete / victory. Test asserts each.

### CD-2. Corruption track live (power now, stronger final boss) — effort M
- **Content numbers:** every corrupt-face pick adds +1 corruption (4 corrupt
  faces exist: Cursed Edge 12 dmg, Cursed Bulwark 10 block, Cursed Blood heal 8,
  Cursed Twin 6+6). Thresholds at corruption 3/6/9 (shipped in code): at 3 the
  player gains Desperation +5 max HP, at 6 all damage +1, at 9 heal 10; EACH
  threshold adds boss_buff +0.15, so the final boss hp and attack are
  multiplied by (1 + 0.15 x thresholds crossed). Track persists for the run
  and is shown in combat UI.
- **Acceptance (headless):** scripted run — corruption 2 -> no buff; corruption 3
  -> +5 max HP and boss_buff 0.15; boss fight at buff 0.15 has hp 65 x 1.15 = 74;
  corruption resets on new run.

### CD-3. Predicted-outcome display — effort M
- **Content numbers:** `predict_outcome()` returns the exact end-turn result
  for the CURRENT rolled dice: {damage_to_enemy, block_gained, heal, self_damage,
  lethal} assuming all dice are played optimally-ordered. Displayed as a ghost
  line on the combat screen.
- **Acceptance (headless):** for a fixed rolled state, predict_outcome()
  damage/block equal the actual resolve() report for the same dice; test
  asserts equality on 3 fixed grids.

### CD-4. Face pool and trinkets at spec numbers — effort M
- **Content numbers:** faces 29 -> 41 = 32 draft + 4 starter + 4 corrupt +
  1 curse (12 new draft faces with keywords: pierce, thorns, lifesteal, reroll,
  multi). Trinkets: `data/trinkets.json` with exactly 20 trinkets, drafted at
  elite/shop nodes (choose 1 of 3). Each trinket = data entry with an effect
  hook resolved in run_state (trinket_total).
- **Acceptance (headless):** loader returns 41 faces with pool counts
  32/4/4/1; trinkets.json loads 20; each new face keyword resolves in a scripted
  combat; trinket effects apply via trinket_total.

### CD-5. Real 1,000-run sim, 35-55% band as CI gate — effort M
- **Content:** `tools/balance_sim.gd` extended to 1,000 runs x seeds
  12345/777/2024, auto-player drives the node map (fight nodes, pick first
  available; shop/elite take a trinket; events resolved simply). **Band:
  win rate 35-55% on EVERY seed** (act-1 completion counts as a win).
- **Acceptance (headless):** sim prints exact per-seed win rate; PASS requires
  all three seeds inside 35-55%. A seed outside the band is reported plainly
  and the task is NOT done.

### CD-6. Test-suite extension — effort S
- **Acceptance:** `tools/test_state.gd` extended to cover CD-1..CD-4;
  headless run prints "TESTS PASS failures=0".

## Out of Phase-1 scope
Acts 2-3, 8th enemy types, whole-dice drafting shapes, meta starting-dice
unlocks, achievements, localization, Workshop. Cursed Dice Phase 1 ends at a
green sim + green tests + fresh macOS/Windows exports.
