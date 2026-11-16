# PHASE 3 BACKLOG — CURSED DICE ("make it compete")

Scoped from FULL_RELEASE_SPEC.md + the converged advice (seq 925-942): CI first,
then synergy depth, then meta-progression. Paper standard: concrete numbers,
headless-checkable acceptance criteria, S/M/L per task. Rules unchanged: commit
per task; exact numbers only; a seed outside 35-55% is reported plainly; spec
vs code conflicts are reported, never improvised. When all tasks are green:
export fresh macOS + Windows builds, push, report, STOP. No Steam/store work.

Shipped baseline (HEAD 3dee15c): 41 faces (4 starter / 32 draft / 4 corrupt /
1 curse), 20 trinkets, 3 acts x 12 nodes (6 fight / 1 elite / 1 boss / 2 event /
1 shop / 1 rest), 8 regular enemies + 3 two-phase bosses, player_hp 52, heal 9,
dice 5, corruption thresholds 3/6/9 (+0.15 boss buff each), 2 event types
(hollow_dealer, shrine_melting). Gates at baseline: tests 59/59 PASS; sim
1000 runs x seeds 12345/777/2024/99999/31337 = 51.0/51.6/51.6/51.3/50.2%,
all in the 35-55% band.

## CD3-1 — CI on the pushed private repo (S)
Add `.github/workflows/ci.yml` to the CursedDice repo: on push/PR to main,
download Godot 4.7.2 Linux headless, run `tools/test_state.gd` and
`tools/balance_sim.gd` (1000 runs x 5 seeds, exit 0 only if every seed in
35-55%). Acceptance (headless): workflow file valid YAML; the exact two
commands it runs pass locally at HEAD; after push, the Actions run for the
push commit is green (checked via GitHub API). Report the run id + conclusion.

## CD3-2 — Trinkets 20 -> 40 with synergy tags (M)
Add a `tags` array to every trinket; add 20 new trinkets in 4 synergy clusters
of 5 (war / ward / blood / greed), each trinket carrying 1-2 cluster tags plus
rarity common/uncommon/rare split 8/8/4. New engine hooks in run_state.gd:
`trinket_tag_count(tag)` and effect `tag_bonus_damage` (value = damage per
other trinket sharing the tag, applied to sword/wild faces in _face_damage
and play_die). Acceptance: 40 trinkets load; every trinket has >=1 tag; 4
clusters x 5 members verify in test; damage math check: 3 war-tag trinkets
with tag_bonus_damage 1 -> sword deals +2 (self excluded); sim gate still
35-55% per seed, exact numbers reported.

## CD3-3 — Events: 2 types -> 6 types with real choices (M)
Keep node counts per act (2 event nodes x 3 acts); rotate 4 new event ids
across act2/act3 event nodes so all 6 types appear. New engine:
`event_choices(event_id)` returns options; `choose_event_option(index)`
applies the chosen effect. New events (deterministic, headless-testable):
- `grave_market`: choice A pay 5 HP -> gain 2 draft faces next draft;
  choice B gain 3 gold-less heal 6 HP.
- `cursed_idol`: choice A +1 corruption (Desperation threshold check runs)
  -> gain a corrupt face; choice B remove a curse face if any, else +4 HP.
- `mirror_pool`: choice A reroll all dice faces to random draft faces;
  choice B +2 max HP.
- `wandering_curse`: choice A take 1 curse face on a die, heal 10;
  choice B nothing.
Acceptance: all 6 event ids resolve via both paths in tests with exact HP /
corruption / die-face assertions; map flow still advances; sim gate 35-55%.

## CD3-4 — Meta progression: soul shards + starting-dice unlocks (M)
New `scripts/meta.gd` (RefCounted, static): save/load `user://cursed_meta.json`
{soul_shards, unlocked_dice:[ids], selected_dice}. Shards earned in
`summary()`: +1 per fight won, +5 on victory. 3 unlockable starter dice sets
in data/run.json `meta_dice` (cost 10/25/50 shards; each a 5-die x 6-face
layout with distinct shape). `meta.purchase(id)`, `meta.select(id)`,
`meta.can_afford`. run_state.start_run uses the selected meta die when set
(headless: `RunState.meta_dice_id`). Acceptance: save/load roundtrip;
purchase fails without shards, succeeds with, persists; start_run with a
selected meta die builds dice from it; unselected default unchanged;
tests + sim gate green.

## CD3-5 — Gates, exports, push, STOP (S)
Extend tools/test_state.gd with CD3-2/3/4 checks (target 75+ checks, all PASS).
Re-run full sim 1000 x 5 seeds, band 35-55% per seed, exit 0; report exact
per-seed numbers. Export fresh macOS (.app) + Windows (.exe) builds, smoke
boot the .app headless, push main to genckazo/cursed-dice, post channel
result with exact numbers, STOP.
