# PHASE-3 BACKLOG — GRAVE SPIN ("best in the world" build)

Scope = agreed top priorities, non-Steam: CI + synergy relics + Bone Coin meta
tree. Baseline (origin/main 1e0184b): 15 fights / 3 floors + endless, 20 relics
(10 common/7 rare/3 cursed), bet knob, pity timer, tests 52 PASS, sim
46.9/45.3/45.0% in 40-60% band, MetaSave has bone_coins/best_fights/runs/
best_victory.

## Tasks

### GS3-1. CI workflow — effort S
- `.github/workflows/ci.yml`: on push/PR to main, download Godot 4.7.2 Linux
  headless, run `tools/test_state.gd` then `tools/balance_sim.gd` (sim exits
  non-zero outside the 40-60% band). PASS = both green.

### GS3-2. Relics 20 -> 30 with synergy tags — effort M
- **Content numbers:** `data/relics.json` gains 10 relics (30 total: 14 common
  / 10 rare / 3 cursed / 3 epic — new "epic" rarity), each with a `tags` array
  from [reel, skull, coin, sword, gamble]. New hooks where needed resolve in
  RelicEngine; at least 3 relics combo off shared tags (e.g. two "coin" relics
  multiply). Draft offers 1-of-3 as now; elites n/a (GS has no elites — boss
  drafts stay).
- **Acceptance (headless):** 30 relics load with rarity split 14/10/3/3 and
  every relic has >=1 tag; scripted combo: owning two tagged relics applies
  the combined effect; sim still in band.

### GS3-3. Bone Coin unlock tree (meta-progression) — effort M
- **Content numbers:** `data/unlocks.json` — 6 nodes: +4 max HP (cost 20),
  +8 max HP (cost 60, needs first), starting relic "whetstone" (cost 40),
  starting relic "bulwark_sigil" (cost 80, needs whetstone start), 4th-row
  unlock flag (cost 120, needs +8 HP), machine skin "gilded" cosmetic (cost
  50). MetaSave gains an `unlocks` array; spent bone coins persist; bonuses
  apply in `start_run`.
- **Acceptance (headless):** buy +4 HP with 20 coins -> start_run max_hp 56;
  unlock persists across MetaSave load/save; locked node cannot be bought.

### GS3-4. Tests + sim over Phase 3 — effort S
- `tools/test_state.gd` extended (relic count/split/tags, unlock tree,
  meta persistence); sim re-run, band 40-60% per seed, exact numbers reported.

## Rules
Commit per task and push to origin main (private repo). Exact numbers only;
spec-vs-code conflict -> stop and report. Green -> fresh macOS+Windows
exports, report, STOP.
