# PHASE-2 BACKLOG — CURSED DICE ("lets do it": more levels, compete with top roguelites)

Scoped from FULL_RELEASE_SPEC.md §2 full-release design, limited to the "more
levels" core: Acts 2 and 3 on the node-map engine, 8 enemy types + 3 bosses,
act twists, 2-phase bosses. Ascension/dailies/Steam stay out of scope.
Baseline (shipped Phase 1, exact from data files): act1.json = 12 nodes over
5 rows (6 fight / 1 elite / 1 boss / 2 event / 1 shop / 1 rest), boss n12
Cursed Warden hp 65 at row 4; run.json player_hp 49, heal_between_fights 7,
dice_count 5; enemies.json 5 types (bone_rat 18, hollow_knight 25, wraith 23,
golem 32, warden 65 boss); faces.json 41; trinkets.json 20; corruption
thresholds 3/6/9 with boss_buff +0.15 each. Tests 46/46 PASS; sim 1000 runs x
5 seeds = 51.8/53.9/52.7/53.9/53.1% all in the 35-55% band.

## Tasks

### CD2-1. Act 2 "The Vault" node map — effort M
- **Content numbers:** `data/act2.json`, same schema as act1: 12 nodes over
  5 rows (6 fight / 1 elite / 1 boss / 2 event / 1 shop / 1 rest), boss at
  row 4. New act-2 boss "The Collector" hp 82. Enemies drawn from the 8-type
  pool with hp_bonus/atk_bonus on nodes (same schema as act1).
- **Act twist (spec):** act-2 enemies buff each other — implemented as
  `act_twist: "shared_power"`: all act-2 enemies start with enemy_strength 2.
- **Acceptance (headless):** act2 loads with 12 nodes / 1 elite / 1 boss;
  act-2 fight starts with enemy_strength 2; test asserts both.

### CD2-2. Act 3 "The Pit" node map — effort M
- **Content numbers:** `data/act3.json`, same 12-node shape, final boss
  "The First Curse" hp 96 at row 4. `act_twist: "curse_on_hit"`.
- **Act twist (spec):** act-3 enemies curse your dice on hit — when an act-3
  enemy lands an attack, one random die slot gains the curse face (max 1 per
  turn); corruption does NOT increment (it is a die curse, not a corrupt pick).
- **Acceptance (headless):** scripted act-3 fight — one landed enemy attack
  adds exactly 1 curse face to a die and leaves corruption unchanged.

### CD2-3. Enemy pool to 8 types + 3 bosses, 2-phase bosses — effort M
- **Content numbers:** enemies.json gains 3 types: "banshee" hp 28
  (9/buff 3/12), "mimic" hp 36 (10/block 6/13), "bone_colossus" hp 44
  (13/block 8/16). Bosses get a `"phase2"` intent list; at hp <= 50% of max,
  the boss switches to phase-2 intents (Collector: 12/buff 4/16/heavy 18;
  First Curse: 14/block 10/buff 4/heavy 20; Warden keeps 12/8/2/14 but gains
  heavy 16 as phase 2).
- **Acceptance (headless):** 8 enemy types load; each boss has phase2 intents;
  scripted boss at hp 50% uses phase-2 intents.

### CD2-4. Act progression in run_state — effort M
- **Content:** `act_index` advances on act-boss kill: act1 boss -> act2 map,
  act2 boss -> act3 map, act3 boss -> victory. `Data.act_for(n)` loads
  act1/act2/act3; corruption track persists across acts (per-run); boss_buff
  applies to the CURRENT act's boss only and resets per act.
- **Acceptance (headless):** autoplay drives act1 boss -> STATE_MAP on act2
  (available_nodes are act2 row 0); act3 boss kill -> victory.

### CD2-5. Real 1,000-run sim over the full 3-act run — effort M
- **Content:** `tools/balance_sim.gd` plays all 3 acts; win rate = act-3 boss
  kill; band 35-55% per seed, 1000 runs x seeds 12345/777/2024/99999/31337.
- **Acceptance (headless):** exact per-seed win rates printed; PASS requires
  all seeds in 35-55%; any seed outside is reported plainly, never rounded in.

### CD2-6. Test-suite extension — effort S
- **Acceptance:** `tools/test_state.gd` covers CD2-1..CD2-5 (node counts per
  act, twists, phase-2 boss, act progression); "TESTS PASS failures=0".

## Rules
Commit per task. Exact numbers only. Spec-vs-code conflict -> stop and report.
When green: fresh macOS + Windows exports, report, STOP.
