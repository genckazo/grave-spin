# PHASE-2 BACKLOG — GRAVE SPIN ("lets do it": more levels, compete with top roguelites)

Scoped from FULL_RELEASE_SPEC.md §1 full-release design, limited to the "more
levels" core: floor 3 + endless mode. Ascension/dailies/Steam stay out of
scope. Baseline (shipped Phase 1, exact from data files): fights.json = 10
fights on floors 1-2 (5 per floor: 4 fights + boss; Bone Captain hp 50 floor-1
boss, The Grave Warden hp 70 floor-2 boss), config.json player_hp 52,
heal_between_fights 8, weights 34/24/12/18/12, values 3/2/2/1/2, 20 relics
(10 common/7 rare/3 cursed), bet knob 1-5, pity 5 near-misses -> jackpot.
Tests 48/48 PASS; sim 1000 runs x seeds 12345/777/2024 = 42.7/41.4/40.2% in
the 40-60% band. NOTE: spec says "6 fights + floor boss" per floor; shipped
floors 1-2 use 4 fights + boss (5 entries) — floor 3 follows the shipped
pattern (5 entries), logged here as an aligned-to-code decision.

## Tasks

### GS2-1. Floor 3 "Hell" content — effort M
- **Content numbers:** 5 new entries in `data/fights.json`, all `"floor": 3`:
  - "Ash Revenant" (skeleton, hp 66, intents attack 10 / attack 11 / heavy 15)
  - "Cinder Slime" (slime, hp 70, attack 11 / defend 8 / attack 12)
  - "Hell Zealot" (cultist, hp 74, attack 11 / buff 4 / heavy 17)
  - "Grave Titan" (skeleton, hp 78, attack 12 / attack 12 / heavy 17)
  - "The Hollow King" (cultist, `"boss": true`, hp 88, attack 12 / buff 4 / heavy 19) — final boss
  - Total fights: 15. Enemy stats come from `data/enemies.json` archetypes
    (skull_extra skeleton 2 / slime 1 / cultist 4), same schema as floors 1-2.
- **Acceptance (headless):** fights load = 15; exactly 3 bosses; floor-3
  entries all floor 3; last fight is The Hollow King hp 88 boss; test asserts
  each. Sim still green (see GS2-3) — tune hp if a seed leaves 40-60%.

### GS2-2. Endless mode after floor 3 — effort M
- **Content numbers:** config.json gains `"endless": true`. After The Hollow
  King falls, `on_enemy_defeated()` no longer sets run_over; instead
  `begin_next_fight()` generates an endless fight: floor = 4, 5, 6..., hp =
  88 + 14 x depth, intents scale +1 per 2 depth (heavy cap +6), name cycles
  ["Endless Echo", "The Deep Hungers", "What Walks Below"]. `victory` is set
  when the floor-3 boss dies (full clear); the run then continues until death.
  Summary gains `endless_depth` (extra floors cleared past 3).
- **Acceptance (headless):** scripted run — clearing fight 15 sets victory
  and fight 16 is generated with floor 4 and hp 102; endless_depth counted in
  summary; death in endless ends the run with victory still true.

### GS2-3. Real sim over the full 3-floor run + endless — effort M
- **Content:** `tools/balance_sim.gd` drives all 15 fights then endless until
  death; win rate = full-clear (victory) share; band stays 40-60% per seed,
  1000 runs x seeds 12345/777/2024. Report avg endless depth per seed too.
- **Acceptance (headless):** sim prints exact per-seed win rate and endless
  depth; PASS requires all 3 seeds in 40-60%; a seed outside is reported
  plainly, never rounded in.

### GS2-4. Test-suite extension — effort S
- **Acceptance:** `tools/test_state.gd` extended to the GS2-1..GS2-3 checks
  (15 fights, 3 bosses, endless generation, summary fields); headless run
  prints "TESTS PASS failures=0".

## Rules
Commit per task. Exact numbers only. If a spec number and the code disagree,
stop and report. When green: fresh macOS + Windows exports, report, STOP.
