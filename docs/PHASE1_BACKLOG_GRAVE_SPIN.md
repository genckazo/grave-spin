# PHASE-1 BACKLOG — GRAVE SPIN ONLY (paper only; Cursed Dice stays spec-only until Grave Spin ships)

Scope cap: floors 1-2, 20 relics, bet knob, juice pass, real balance sim.
No building until explicit go after playtest feedback.

Baseline numbers are exact from `GraveSpin/data/*.json` (see FULL_RELEASE_SPEC.md §2).

## Content numbers for Phase 1

- **Floors/fights**: floor 1 = existing 4 fights (Rattling Bones hp 30, Ooze of
  the Deep hp 34, The Whisperer hp 40, Bone Captain hp 50) + floor-1 boss.
  Floor 2 = 4 new fights + floor-2 boss (The Grave Warden, hp 64, currently the
  demo's fight 5, becomes the floor-2 boss). Total Phase-1 ladder: 10 fights.
- **Floor-2 scaling**: new fights reuse the 3 existing enemy types
  (skeleton skull_extra 2, slime 1, cultist 4) with an hp/atk bonus pattern
  like Cursed Dice's `run.json`: proposed hp 42 / 46 / 54 / 60, intents scaled
  +2 per step from the floor-1 equivalents. Enemy stats live in
  `data/fights.json` (per-fight hp + intents) and `data/enemies.json`
  (skull_extra curse); floor-2 entries are new rows in those files.
- **Relics: 20 total by rarity** = current 12 (6 common / 4 rare / 2 cursed) +
  8 new → **10 common / 6 rare / 2 epic / 2 cursed**. New rares/epics are the
  growable-reel relics (4th row, 4th reel, diagonal payline) + bet-synergy
  relic. Rarity drives draft weights in the 1-of-3 offer.
- **Bet knob**: 1-5 coins per pull; bet multiplies sword damage, coin payout,
  and skull penalty by the bet amount. Config keys added to `config.json`
  (`bet_min: 1`, `bet_max: 5`).
- **Pity timer**: `near_miss_pity: N` (propose 5) consecutive near-miss jackpots
  → next jackpot guaranteed.

## Tasks

| # | Task | Acceptance criteria (headless-checkable) | Effort |
|---|---|---|---|
| 1 | Floor-2 content: 4 fights + boss rows in `data/fights.json`, floor tagging | `test_state.gd` loads data; 10-fight ladder validates; every fight has hp + 3 intents + enemy type present in `enemies.json` | S |
| 2 | Bet knob (1-5 coins) in rules + UI | Headless: for bet b in 1..5, sword damage = base x b, coin payout = base x b, skull penalty = base x b; out-of-range bets rejected | M |
| 3 | 8 new relics (20 total: 10 common/6 rare/2 epic/2 cursed) incl. 3 growable-reel relics | Headless: each relic hook fires (extend the 36-check suite); draft offers only valid rarities; 4th row/reel/diagonal actually add paylines in resolution | M |
| 4 | Near-miss pity timer | Headless: force N=5 consecutive near-misses with seeded RNG → 6th spin guarantees jackpot; counter resets after a jackpot | S |
| 5 | Juice pass: screen shake on skulls, coin-burst particles, near-miss slow-mo, run-summary card | Autoplay run (`--autoplay --fast` pattern) exits 0 and captures screenshots of all screens incl. run-summary card on both death and victory; no errors in log | M |
| 6 | REAL balance sim replacing `tools/balance_tune.py`: GDScript headless, shares RunState, 1,000 runs/seed | Sim runs 1,000 runs on each of 5 fixed seeds (e.g. 12345/777/2024/999/424242), prints win rate + avg spins per seed; **target band: 40-60% win rate per seed with relic draft** (demo Python approx showed ~60% with relics, ~0% without — the sim must reproduce both policies); any seed outside the band is reported plainly, not rounded | L |
| 7 | Phase-1 test-suite extension (bet knob, pity, new relics, floor-2 ladder) | `Godot --headless --path . -s res://tools/test_state.gd` exits 0 with all checks ok, count reported | S |

## Notes
- Target band for task 6 is stated here per the assignment: **40-60% per seed**,
  1,000 runs, 5 seeds. Rationale: demo auto-play with relics landed ~60%; the
  floor-2 addition should pull it into the band, and ~0% without relics must
  still hold (relics are the power curve).
- Effort: S < 1 day, M = 1-3 days, L = 3-5 days of focused building.
- Everything stays data-driven; no engine-code changes except where a task
  says "rules" (bet knob, pity counter) — those are RunState fields, sim-visible.
