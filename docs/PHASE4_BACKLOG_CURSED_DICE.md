# PHASE 4 BACKLOG — CURSED DICE (full release readiness)

Authorized by user msg "lets build it to full release" (task 3817c03f). Same
rules as the Grave Spin Phase 4 backlog: commit per task + push, exact numbers,
stop-and-report on conflicts, fresh exports when green, channel_result, STOP.
Steam-side submission stays parked (owner's account + fees).

## CD4-1 — Schema versions (S)
- `"schema_version": 1` in data/run.json, act1-3.json, enemies.json,
  events.json, faces.json, trinkets.json; game_data.gd warns on version
  mismatch; tests assert all files report version 1.

## CD4-2 — Ascension ladder A0-A15 (M)
- run.json gains `"ascension"` table: per level A0-A15, enemy_hp and enemy_atk
  multipliers (A0 = 1.0/1.0; A15 = 1.6/1.6, smooth steps), plus extra elite
  flag from A5 up (applied as +1 elite node weight in act maps is data-only:
  ascension adds hp/atk scaling; elite addition stays out of scope for P4 if
  it requires map surgery — report if so).
- start_run accepts `ascension` (0-15, default 0); enemy hp and intent damage
  scale in _start_fight / enemy turn; state stores ascension; sim accepts
  `--asc=`.
- Tests: A0 unchanged vs current numbers; A15 scales a known enemy by 1.6;
  invalid level clamps to [0,15].
- Gates: tests PASS; sim 1000 runs x seeds 12345/777/2024/99999/31337 at A0
  must stay in 35-55%; sim at A15 band 15-35% per seed, exact numbers
  reported, any out-of-band seed reported plainly.

## CD4-3 — Achievements (M)
- data/achievements.json: 25 achievements {id, name, desc, stat, threshold}
  (first victory, 10 victories, A15 win, corruption threshold maxed, all 6
  event types seen, etc.). meta.gd gains achievements array +
  unlock_achievement; run-end report. Tests: 25 load, idempotent unlock,
  first-victory granted once.

## CD4-4 — Localization + accessibility scaffolding (M)
- data/loc/{en,es,fr,it,de,ja,zh}.csv with identical keys; Loc helper with
  English fallback; settings (language, colorblind_symbols, reduced_motion)
  persisted in meta save; tests assert key parity across 7 languages.

## CD4-5 — Release package (S)
- RELEASE.md in repo: store copy, press kit, launch checklist (simulated-
  gambling declaration, credits, $5.99, demo slice, regional pricing); shared
  docs copied into docs/ and pushed.
- Fresh exports macOS .app + Windows .exe + Linux .x86_64.
- Final gates: tests PASS, sim bands green (A0 35-55%, A15 15-35%),
  channel_result, STOP.
