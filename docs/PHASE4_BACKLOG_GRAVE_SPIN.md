# PHASE 4 BACKLOG — GRAVE SPIN (full release readiness)

Authorized by user msg "lets build it to full release" (task 3817c03f). Scope: the
buildable remainder of FULL_RELEASE_SPEC.md. Steam-side submission (Steamworks
achievements sync, store page, payments) needs the owner's Steam account and
stays parked; everything data/engine/docs below is built and gated headless.

Rules: commit per task and push to origin main (private repo, user-authorized);
exact numbers only, never round a seed into its band; stop-and-report on
spec-vs-code conflicts; fresh macOS + Windows + Linux exports when green, then
channel_result and STOP.

## GS4-1 — Schema versions (S)
- Add `"schema_version": 1` to data/config.json, enemies.json, fights.json,
  relics.json, unlocks.json.
- `GameData.ensure_loaded()` warns (push_warning) if a file's schema_version
  differs from the loader's expected version; loads anyway (forward-compatible
  default), tests assert all five files report version 1.

## GS4-2 — Difficulty modes: Normal / High Roller (M)
- config.json gains `"difficulty"`: normal {enemy_hp 1.0, enemy_atk 1.0,
  reward 1.0}, high_roller {enemy_hp 1.25, enemy_atk 1.25, reward 1.5}
  (per FULL_RELEASE_SPEC decision 9: enemies +25%, rewards +50%).
- `start_run(seed, mode)` applies enemy hp multiplier in `_start_fight` and
  intent damage multiplier in the enemy-turn path; bone coin rewards scale by
  reward multiplier. Mode stored on state; sim accepts `--mode=`.
- Tests: mode defaults to normal; high_roller scales a known fight's hp by 1.25
  and a known intent by 1.25; rewards x1.5.
- Gates: tests PASS; sim 1000 runs x seeds 12345/777/2024 in normal mode must
  stay in 40-60%; high_roller mode band 25-45% per seed (harder mode, exact
  numbers reported; any seed outside its band reported plainly, not rounded).

## GS4-3 — Achievements (M)
- data/achievements.json: 25 achievements (spec decision 7: 25+), each
  {id, name, desc, stat, threshold} — e.g. first victory, 10 victories, endless
  depth 5, 100 spins in one run, win on high_roller, all-cursed run, etc.
- MetaSave gains `achievements` array + `unlock_achievement(id)`; game_state
  reports stats (runs, victories, endless_depth, spins, difficulty) to
  MetaSave at run end; achievements never affect balance.
- Tests: 25 achievements load; unlock_achievement is idempotent; run-end
  report grants first-victory achievement exactly once.

## GS4-4 — Localization + accessibility scaffolding (M)
- data/loc/en.csv, es.csv, fr.csv, it.csv, de.csv, ja.csv, zh.csv — same keys
  in every file (EFIGS + JA/ZH at launch per spec decision 6); a `Loc` helper
  loads the CSV for the chosen language with English fallback.
- config.json gains accessibility defaults: `colorblind_symbols` (bool),
  `reduced_motion` (bool), persisted in MetaSave settings; tests assert CSV
  key parity across all 7 languages and toggle persistence.

## GS4-5 — Release package (S)
- RELEASE.md in the repo: store copy (short/long description), press-kit
  notes, launch checklist (simulated-gambling declaration, CC0/CC BY credits,
  $6.99, Next Fest demo = current verified slice, regional pricing, launch
  discount), export matrix Windows/macOS/Linux.
- Copy shared docs (FULL_RELEASE_SPEC.md, PHASE1-4 backlogs) into docs/ of the
  repo and push.
- Fresh exports macOS .app + Windows .exe + Linux .x86_64; quarantine cleared.
- Final gates: tests PASS, sim bands green, channel_result, STOP.
