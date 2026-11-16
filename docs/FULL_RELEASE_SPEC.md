# FULL RELEASE SPEC — Grave Spin & Cursed Dice (canonical)

Merged from `ADVANCED_DESIGN_IDEAS.md` (coder 2) and `FULL_RELEASE_DESIGN.md`
(coder 1). Paper only: no code, no builds, no changes to either game project.
Where the two sources overlapped, the stronger version was kept; every conflict
is logged in "Decisions" below. All current-game numbers are copied exactly
from the projects' data files, not rounded.

## 0. Guardrails (apply to both games, non-negotiable)

- Simulated gambling only, declared exactly that way in Steam's content survey
  (Grave Spin). No real-money wagering anywhere.
- Assets stay CC0 / CC BY 4.0 with the Patch.gg credits files kept unmodified
  in each project (Kenney CC0 sprites/SFX, Kevin MacLeod CC BY 4.0 music, OFL
  fonts).
- Prices as briefed: Grave Spin $6.99, Cursed Dice $5.99. Premium one-time
  purchase; no MTX; cosmetic-only DLC at most. Steam Direct fees ($100 each)
  remain g's to pay.
- Data-driven content: relics/faces/enemies/fights live in JSON loaded by an
  engine script; content is added by editing data, never code. Schema-version
  field in each JSON so saves and content patches don't break old runs.
- Balance is tuned by data, never by code, and every content change re-runs the
  headless sim. Any seed missing its band is reported plainly.
- One signature system per game, pushed deep: Grave Spin = the machine (reels,
  weights, paylines, jackpots); Cursed Dice = the dice (faces, melt, corruption).
- Seeded runs + shareable seed codes; the clip-worthy near-miss / corruption
  gamble is the marketing engine.
- Steam package per game: achievements, trading cards, Steam Cloud saves,
  controller support + Steam Deck verified target, localization (EFIGS +
  JA/ZH at launch, 10+ languages post-launch), Next Fest demo = the existing
  verified slice, regional pricing, launch discount.
- Export matrix: Windows + macOS + Linux (Proton free). 60 fps on Steam Deck,
  <2 s loads.

## 1. GRAVE SPIN — full release ($6.99)

### Current demo slice (exact numbers from `GraveSpin/data/`)

- `config.json`: player_hp 52, heal_between_fights 8, max_relics 4,
  bone_coins_per_fight 2, coins_per_bone 8. Symbols: sword / shield / potion /
  coin / skull. Weights: sword 34, shield 24, potion 12, coin 18, skull 12.
  Values: sword 3 dmg, shield 2 block, potion 2 heal, coin 1, skull +2 enemy
  damage.
- `relics.json`: 12 relics — 6 common (whetstone, bulwark_sigil, leech_flask,
  gilded_reel, bone_ward, iron_frame), 4 rare (second_wind, lucky_seventh,
  bloodstone, skull_crown), 2 cursed (grave_pact, dead_mans_hand).
- `enemies.json`: 3 types — skeleton (skull_extra 2), slime (skull_extra 1),
  cultist (skull_extra 4).
- `fights.json`: 5 fights — Rattling Bones (skeleton, HP 30, intents 5/6/heavy
  9), Ooze of the Deep (slime, HP 34, 6/defend 6/8), The Whisperer (cultist,
  HP 40, 7/buff 2/heavy 12), Bone Captain (skeleton, HP 50, 8/9/heavy 13), The
  Grave Warden (cultist, HP 64, 9/buff 2/heavy 15).
- Verified: headless suite `tools/test_state.gd` — 35 checks, 0 failures
  ("TESTS PASS failures=0"); standalone tuning sim `tools/balance_tune.py`
  lands ~60% win rate with relic draft, ~0% without, ~21 spins per run.

### Full-release design

- **Structure**: 3 themed floors (Crypt / Catacombs / Hell, each reskins frame,
  backdrop, enemy set, music) x 6 fights + floor boss + final boss; endless mode
  after floor 3. Runs ~30-45 min. Difficulty modes: Normal / High Roller
  (enemies +25%, rewards +50%).
- **Signature machine systems (must survive)**:
  - **Bet knob**: before each pull, bet 1-5 coins. Payouts and skull penalties
    both scale with the bet — every spin is a decision.
  - **Growable reels**: start 3x3; relics add a 4th row, then a 4th column, then
    diagonal paylines; per-reel weights tunable (e.g. loaded top reel). The
    machine visibly changes per run.
  - **Near-miss pity timer**: near-miss slow-mo on the last reel when 2 swords
    show; a pity counter guarantees a jackpot (3-of-a-kind payline event: free
    re-spin, enemy stunned, or full heal) after a fixed number of near-misses.
  - **Symbol ecosystem**: base five plus floor invaders that land on your reels
    (rot, curse) and symbol evolutions (gold sword 2x, cursed skull +4, gem
    coins x3). Each of the 6 enemy types invades differently.
  - **Status effects**: block, burn, poison, vulnerable, lucky, cursed.
- **Relics 12 -> 30+**, rarities common / rare / epic / cursed, with synergy
  tags (reel, skull, coin, sword, gamble); cursed relics carry a permanent
  downside; elites offer a 1-of-5 draft.
- **Meta-progression (Bone Coins)**: unlock tree — new starting relics, extra
  starting HP, starting 4th row unlock, machine skins (cosmetic), new symbols;
  prestige ("Descend deeper") resets unlocks for a permanent +5% coin bonus.
  Local save + Steam Cloud.
- **Retention**: daily seed + Steam leaderboards (highest floor), shareable
  run code.
- **Presentation**: "haunted casino in a dungeon", torch-lit backdrop, per-floor
  palette accent, pixel art at 1080p windowed with integer scaling; juice =
  marketing (screen shake on skulls, coin bursts, lever weight, damage numbers,
  screenshot-ready run-summary card); CRT scanline toggle; colorblind-safe
  symbol shapes, adjustable text, reduced shake/flash toggle, remappable keys;
  per-floor music loops and layered symbol SFX with per-bus volume.

## 2. CURSED DICE — full release ($5.99)

### Current demo slice (exact numbers from `CursedDice/data/`)

- `run.json`: player_hp 52, heal_between_fights 7, dice_count 5; 7 fights —
  bone_rat (0/0), hollow_knight (0/0), wraith (+2 HP / +1 atk), bone_rat (+8/+1),
  golem (+2/+3), hollow_knight (+12/+3), warden boss (+0/+2).
- `enemies.json`: 5 entries — Bone Rat HP 18 (6/7/block 3), Hollow Knight HP 25
  (9/block 5/11), Wraith HP 23 (7/buff 2/10), Stone Golem HP 32 (11/block
  7/13), The Cursed Warden HP 65 boss (12/block 8/buff 2/14).
- `faces.json`: 29 entries — kinds: 11 sword, 9 shield, 6 heart, 1 blank,
  1 curse, 1 twin; rarities: 12 common, 8 uncommon, 4 rare, 1 curse,
  4 corrupt. (Note: BALANCE.md says "20 draftable + 4 corrupted + 1 curse"; the
  file actually holds 24 draftable + 4 corrupt + 1 curse = 29. The file is the
  source of truth.) Starter dice: 5 identical dice of
  [sword_2, sword_2, shield_2, shield_2, heart_1, blank].
- Verified sim (`tools/balance_sim.gd`, 200 runs/seed): seed 12345 = 54.0%,
  777 = 38.0%, 2024 = 52.5%, 999 = 56.0% (one seed 1 point over the 35-55%
  band, reported plainly); seed 12345 detail: 6.54/7 fights cleared, 31.4
  turns/run, boss reached 99.5%, boss win 54.3%, damage dealt 230.0 / taken
  119.6.

### Full-release design

- **Structure (must survive)**: **node map** per act (Slay-the-Spire style, not
  a linear ladder); 3 acts x (6 fights + elite + boss), 8 enemy types + 3 bosses
  with 2 phases each; 20-30 min runs. Act twists: act 2 enemies buff each
  other, act 3 enemies curse your dice on hit.
- **Signature dice systems (must survive)**:
  - **Corruption track**: every corrupt pick fills a per-run track; at
    thresholds the player gains a powerful "Desperation" reward but the final
    boss gets stronger — power now, stronger final boss, risk visible on the
    die (purple corruption spreading across the texture per curse face).
  - **Predicted-outcome display**: a ghost line shows exact damage/block if the
    turn ends now — perfect information, losses feel like the player's fault.
  - Faces 24 -> 40+ with keywords (pierce, thorns, lifesteal, multi-hit, reroll,
    multi-face, chain, wild, curse-synergy); whole-dice drafting between acts
    (d4 strong / d8 blank shapes); 20+ trinkets at elite nodes.
- **Meta-unlocks**: new starting dice that change the build space (chaos die,
  curse-heavy die); Steam Cloud save.
- **Balance harness mandatory**: the sim becomes a 1,000-run CI check on every
  data change; target band 35-55% win rate for the auto-player plus a
  "greedy player" policy for the skill ceiling.
- **Presentation**: "carved stone dice on a dark battlefield map", ink + pixel
  hybrid; forge/anvil draft screen; dice tumble physics with layered clatter;
  curse whisper SFX; per-act music + boss variant; same accessibility toggles
  as Grave Spin.

## 3. Decisions (conflicts between the two source docs, resolved)

1. **Fights per floor (Grave Spin)**: ADVANCED said 3 floors x 5 fights + boss;
   FULL_RELEASE said 3 x 6 fights + boss + final boss. **Picked FULL_RELEASE**
   (6 fights + floor boss + final boss) — matches the brief's "3 floors" with
   more meat per floor.
2. **Cursed Dice act shape**: ADVANCED said 3 acts x (6 fights + elite + boss);
   FULL_RELEASE said 3 acts x 8 fights + boss. **Picked ADVANCED** (6 fights +
   elite + boss per act = 8 nodes, keeps the elite/trinket draft meaningful).
   Both agreed on the node map; kept.
3. **Relic rarities (Grave Spin)**: demo has common/rare/cursed; ADVANCED added
   epic. **Picked common/rare/epic/cursed** — the 30+ target needs four tiers.
4. **Internal resolution**: ADVANCED said 640x360; FULL_RELEASE said 1080p
   integer-scaled. **Picked 1080p integer-scaled** (matches the shipped demo).
5. **Jackpot vs pity timer**: ADVANCED had near-miss slow-mo only; FULL_RELEASE
   had jackpots + pity timer. **Merged**: near-miss slow-mo AND a pity timer
   that guarantees jackpots. Both survive.
6. **Localization at launch**: ADVANCED said 10+ languages; FULL_RELEASE said
   EFIGS + JA/ZH. **Picked EFIGS + JA/ZH at launch, 10+ post-launch.**
7. **Achievements count**: 30+ (ADVANCED) vs ~25 (FULL_RELEASE). **Picked 25+**
   with FULL_RELEASE's concrete examples.
8. **Mod support**: only FULL_RELEASE had it. **Kept, Phase 3 only**: Steam
   Workshop for JSON content only (faces/relics), no code mods, so the balance
   harness stays valid.
9. **Difficulty modes**: only ADVANCED had Normal/High Roller. **Kept**.
10. **Export matrix**: Windows/macOS only in practice; FULL_RELEASE adds Linux.
    **Kept Linux** (Proton is free).

## 4. Phase-1 backlog — GRAVE SPIN ONLY (Cursed Dice stays spec-only until Grave Spin ships)

Scope cap: floors 1-2, 20 relics, bet knob, juice pass, real balance sim
(1,000 runs). Every task lists concrete content numbers, a headless-checkable
acceptance criterion, and effort S/M/L. Phase-1 building starts only on the
user's explicit go after playtest feedback.

Target band for the real sim (stated here, checked by the sim itself):
**win rate 45-60% per seed across 3 seeds with relic drafting, avg 18-25 spins
per run; any seed outside the band is reported plainly as a failure.**

| # | Task | Content numbers | Acceptance criterion (headless) | Effort |
|---|---|---|---|---|
| 1 | Floors 1-2 content: 2 floors x 6 fights + floor boss = 14 fights; 6 enemy types total (skeleton, slime, cultist + 3 new); enemy stats live in `data/enemies.json` (hp, intents, skull_extra) and `data/fights.json` (hp/atk scaling per fight, boss flag), same schema as the demo's 5 fights | 14 fights; HP ladder starting from demo values (30/34/40/50/64) scaled per floor; 6 enemy types with intents arrays | Headless test loads all data without error; every fight references a valid enemy type and has a non-empty intents array; a scripted run clears floors 1-2 | L |
| 2 | Relics 12 -> 20: add 8 relics to `data/relics.json` — 4 common, 2 rare, 1 epic, 1 cursed (new epic tier added to schema) | 20 relics total: 10 common, 6 rare, 1 epic, 3 cursed | Extended `test_state.gd` asserts exactly 20 relics, the rarity counts above, and that every `effect` hook resolves against `relic_engine.gd` (one test per new relic, as the existing 12 have) | M |
| 3 | Bet knob: `config.json` gains `bet_min: 1`, `bet_max: 5`; payout multiplier = bet, skull penalty = skull value x bet; bet deducted per pull | Bet 1-5 coins; at bet 5 a sword pays 15 and a skull costs 10 | Headless test: set bet 5, force a known grid, assert payout = base x 5 and skull damage = 2 x 5; assert coins deducted and bet clamps to [1,5] | M |
| 4 | Growable reels (Phase-1 = 4th row only): one new relic adds a 4th row, paylines 3 -> 4 | 3x4 grid, 4 row paylines; 4th column and diagonals are Phase 2 | Headless test: with the relic equipped, resolve a known 3x4 grid and assert 4 paylines are scored (the existing payline tests extended) | M |
| 5 | Near-miss pity timer: `config.json` gains `pity_near_misses: 10`; after 10 near-misses without a jackpot, the 11th near-miss is forced into a 3-sword jackpot payline | 10 near-misses -> guaranteed jackpot on the next near-miss | Headless sim/test: script 10 consecutive near-miss grids, assert the 11th resolves as a jackpot (3 swords on a payline) and the counter resets | M |
| 6 | Juice pass: screen shake on skulls, coin-burst particles on payout, near-miss slow-mo on last reel, screenshot-ready run-summary card (floors cleared, spins, coins, relics) | Shake magnitude scales with skull count; summary card rendered at run end | Headless: run an autoplayed full run to death/victory, assert the run-summary screen renders (screenshot capture exists in `build/shots/`) and the juice config flags are set without errors | M |
| 7 | Real balance sim replacing `tools/balance_tune.py`: GDScript headless sim sharing the game's rules engine (like Cursed Dice's `balance_sim.gd`), 1,000 runs per seed, 3 seeds (e.g. 12345, 777, 2024), auto-player = draft 1-of-3 relics, bet 1, spin until fight resolves | 1,000 runs/seed; band 45-60% win rate, 18-25 avg spins (stated above) | `Godot --headless -s tools/balance_sim.gd -- --runs=1000 --seed=<n>` prints per-seed win rate and avg spins and exits non-zero if any seed misses the band; the Python approximation is deleted from the tuning path (kept only as a historical note in DECISIONS.md) | L |

Backlog total: 2 x L + 5 x M. Nothing here is built; per the rules, building
starts only on the user's explicit go after playtest feedback.
