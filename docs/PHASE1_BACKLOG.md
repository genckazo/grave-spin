# PHASE-1 BACKLOG — GRAVE SPIN ONLY (paper only; build starts only on explicit go)

Scope cap (hard): **floors 1–2, 20 relics, bet knob, juice pass, real balance sim.**
Cursed Dice stays spec-only until Grave Spin ships.

**Enemy stats source:** every fight's numbers come from `GraveSpin/data/enemies.json`
(per-type `skull_extra`: skeleton 2, slime 1, cultist 4) + `GraveSpin/data/fights.json`
(per-fight `hp` and `intents`). New floor content = new entries in those files, plus
`config.json` for global knobs (player_hp 52, heal_between_fights 8, symbol
weights 34/24/12/18/12, values 3/2/2/1/2, max_relics 4, bone_coins_per_fight 2,
coins_per_bone 8). Tuning changes data files, never code.

**Real balance sim target band (stated here, per the cap):** 1,000 headless runs per
seed across seeds 12345 / 777 / 2024 / 99999 / 31337 — **win rate must land in
35–55% on every seed**; any seed outside the band is reported plainly, not averaged away.
Secondary metrics reported: avg spins/run, avg coins earned, avg floor reached.

---

## Tasks

### GS-1. Real balance sim replacing `tools/balance_tune.py`
- **Content numbers:** GDScript `tools/balance_sim.gd` driving the same run-state the
  game uses (not a re-implementation); 1,000 runs/seed; seeds 12345, 777, 2024, 99999,
  31337; auto-player policy: always pull, take the 1-of-3 relic draft by highest
  expected value, bet 1 (knob default).
- **Acceptance (headless-checkable):** `godot --headless --path . --script tools/balance_sim.gd`
  prints win rate per seed; every seed in 35–55%; avg spins/run printed; exit code 0
  only if all seeds in band, 1 otherwise.
- **Effort:** M

### GS-2. Floor structure: floors 1–2
- **Content numbers:** new `data/floors.json` — floor 1 = 4 fights + floor boss,
  floor 2 = 4 fights + floor boss (8 fight entries total, bosses reuse existing types
  with scaled hp: floor-1 boss = Bone Captain 50 HP, floor-2 boss = The Grave Warden
  64 HP; regular fights reuse skeleton/slime/cultist with hp from the 30/34/40 range
  plus +5 per floor). Run ends at floor-2 boss for Phase 1 (victory screen), floor 3
  is Phase 2.
- **Acceptance:** sim summary reports floor reached; headless test asserts exactly 8
  fights per full run and victory only after the floor-2 boss.
- **Effort:** M

### GS-3. Relics: 12 → 20 (incl. growable-reel relics)
- **Content numbers:** add 8 relics to `data/relics.json` to reach **20 total:
  12 common, 5 rare, 3 cursed** (current: 6 common / 4 rare / 2 cursed; add 6 common,
  1 rare, 1 cursed... final split must be exactly 12/5/3). At least 2 of the new ones
  grow the machine: one adds a 4th row (paylines become 4 rows), one adds diagonal
  paylines. Rarity drives draft odds in the 1-of-3 offer.
- **Acceptance:** headless test instantiates all 20 relics and fires each effect hook;
  4-row relic produces 4 paylines in a test spin; diagonal relic resolves both
  diagonals; count check asserts 20 relics with the 12/5/3 split.
- **Effort:** M

### GS-4. Bet knob (1–5 coins)
- **Content numbers:** bet `b` ∈ {1,2,3,4,5} chosen before each pull; coin payout per
  coin symbol = `values.coin` (1) × b; skull damage per skull = `values.skull` (2) × b;
  pulling costs b coins (can't pull if coins < b; minimum bet 1 always allowed).
- **Acceptance:** headless test: at bet 3, a coin payline of 3 pays 9 coins and 3
  skulls deal 18 damage; bet selector rejects b when coins < b; sim's default policy
  (bet 1) still lands in the 35–55% band.
- **Effort:** S

### GS-5. Juice pass
- **Content numbers:** screen shake on skull resolution (existing shake hook), coin-burst
  particles on coin paylines, near-miss slow-mo on the last reel when 2 jackpot
  symbols show, run-summary card at death/victory (floor reached, spins, coins earned,
  bone coins earned = fights × 2, relics taken). No new balance impact.
- **Acceptance:** headless `--autoplay` run completes and the summary card's fields are
  all populated; screenshot capture mode produces one PNG per screen (title, fight,
  draft, death, victory) — the capture path already exists.
- **Effort:** M

### GS-6. Near-miss pity timer
- **Content numbers:** near-miss = a payline showing exactly 2 of 3 jackpot symbols
  (3 swords); counter increments per near-miss, resets on jackpot; at **3 near-misses**
  the next spin is rigged so at least one payline completes the jackpot (3-of-a-kind
  event: free re-spin). Pity counter shown on the machine UI.
- **Acceptance:** headless test with a rigged RNG asserts a jackpot occurs on the spin
  immediately after the 3rd near-miss and never earlier than the 3rd; sim reports avg
  pity-triggered jackpots per run.
- **Effort:** S

### GS-7. Phase-1 regression gate
- **Content numbers:** extend `tools/test_state.gd` (currently 36 checks) with GS-2
  through GS-6 assertions; total check count grows accordingly.
- **Acceptance:** all headless checks pass; GS-1 sim green on all 5 seeds in one CI-style
  invocation; both reported in the Phase-1 report.
- **Effort:** S

---

## Out of Phase-1 scope (Phase 2+): floor 3 + endless, 30+ relics, High Roller mode,
prestige, achievements/cards/cloud, localization, Workshop JSON, controller polish.
