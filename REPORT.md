# Grave Spin — SYS1–SYS5 + JOB 1–3 (fix / lives / polish) Final Report

## JOB 1 — Shop wired into the game — commit eee6e3c — WORKS
- `open_shop()` had zero callers and no shop screen existed. Now the grave
  market opens after boss fights 5 and 10 (data-driven:
  `config.shop_after_boss_fights = [5, 10]`). Flow: boss win -> relic draft
  -> shop -> LEAVE starts the next fight.
- New `scripts/screens/shop_screen.gd` presents the existing SYS4 economy
  unchanged: coins, interest earned on entry, reroll price, the 3 permanent
  upgrades (max 1 per visit), the consumable slot with prices; buttons
  disabled when unaffordable; first-visit teach line shown once.
- Engine additions: `shop_pending`, `leave_shop()`, `shop_relic_stock()`,
  `buy_shop_consumable()`; `main.gd` routes the flow and autoplay handles
  the shop screen.
- Headless test `_test_shop_flow`: shop pending exactly after boss fights
  5/10 (not on regular fights, not on the final boss), interest paid once
  per visit (reroll never re-pays), reroll price resets next visit,
  consumable buy/sold-out, leave clears pending.

## JOB 2 — Lives: 3 per run — commit 6b6f19b — WORKS
- Run starts with 3 lives (`config.lives = 3`), heart icons in the fight HUD
  bottom bar, always visible.
- On death: lose 1 life, retry the SAME fight — player HP restored to the
  value held when the fight was entered (`fight_entry_hp`), enemy restored
  to its starting HP, boss rule stays exactly as announced. At 0 lives the
  existing `finish_run(false)` flow runs; the end screen shows LIVES SPENT.
- Meta progress (bone coins, unlocks) and the pity system unchanged; Second
  Wind still takes precedence over losing a life.
- `balance_sim.gd` models lives (retry with entry HP). Before/after bands:
  without lives normal was 45.9/40.8/46.3/40.7/41.4%; with lives and no
  retune it rose to 61.2/58.1/62.6/59.9/59.7% (seeds 12345/2024 OUT above
  60, stated plainly). Retune `heal_between_fights` 16->10: final normal
  49.2/42.6/47.1/43.1/45.4% — ALL IN 40-60%, SIM PASS. High Roller final
  numbers in the Gates section below.
- Headless test `_test_lives`: life decrement on death, retry restores entry
  HP + fresh enemy + keeps boss rule, run ends at 0 lives, summary carries
  lives/lives_spent, Second Wind precedence.

## JOB 3 — Visual polish — commit 51ebf7d — WORKS (look & feel only)
- Graveyard-at-dusk parallax background behind all screens: three original
  layers drawn by `tools/make_polish_art.py` (`bg_sky` moon/stars/hills,
  `bg_mid` gravestones/dead tree/fog, `bg_near` foreground fence), drifting
  at different speeds; drift disabled when `reduced_motion` is set.
- Slot-machine cabinet frame around the reels drawn in-engine
  (`CabinetFrame._draw`: wood body, brass trim, marquee bulbs, reel window,
  rivets) — original art, no new runtime dependencies.
- Juice: red edge vignette flash on player hits (plus existing screen shake
  and flash), settle bounce when each reel stops, coin bursts on wins, enemy
  idle bob. One palette and three fonts shared across menu/fight/shop/draft/
  end screens via the UI helper.
- Also carries the JOB 2 HUD wiring (lives icons, LIFE LOST -> retry flow).

## Gates (final, at JOB 3 HEAD)
- Tests: `tools/test_state.gd` TESTS PASS failures=0 (all pre-existing plus
  `_test_shop_flow` and `_test_lives`).
- Sim, 1,000 runs x 5 seeds (12345 / 777 / 2024 / 99999 / 31337), lives
  modelled, every seed reported exactly:
  - Normal, band 40–60%: 49.2% (492/1000), 42.6% (426/1000), 47.1% (471/1000),
    43.1% (431/1000), 45.4% (454/1000) — ALL IN, SIM PASS.
  - High Roller, band 15–35%: 23.1% (231/1000), 21.1% (211/1000), 19.4% (194/1000),
    22.0% (220/1000), 20.1% (201/1000) — ALL IN, SIM PASS.
- Autoplay (`--autoplay --fast`) completes a full run through the real game
  loop including the shop screen, reaches the end screen, 0 script errors.
- Exports (fresh, local-only in gitignored `build/`): macOS
  `build/macos/GraveSpin.app`, Windows `build/windows/GraveSpin.exe`
  115,688,048 bytes, PE32+ x86-64.

## Per system

### 1. Tutorial + tooltips — WORKS (engine+data+tests) — commit 0490fab
- `data/tutorial.json`: first run only (`tutorial_done` flag in MetaSave,
  skippable); scripted first spin rigged to 3 Swords which kills fight 1;
  4 teach-on-first-encounter lines (first Skull, first relic pick, first shop
  visit, first consumable).
- `data/tooltips.json`: 38 entries covering every symbol, relic, and enemy.
- Headless test `_test_tutorial_tooltips`.
- UI note: teach lines and tooltips are exposed via `teach_line()` /
  `GameData.tooltip()`; the on-screen hover/click wiring in the UI screens is
  stub-level (data and API complete, presentation not re-animated).

### 2. Trigger sequencing — WORKS (engine+data+tests) — commit b381aba
- `resolve()` report gains `sequence`: 9 symbol steps row-major with running
  {damage, block, self_damage, heal, coins} tallies, then relic steps in slot
  order, then a total step; `fast` flag from the persisted `fast_mode` setting
  (hold-click / Fast toggle skips to final result).
- Headless test `_test_sequencing` asserts order and cumulative tallies.
- UI note: step list is produced for the UI to animate within the 2.5s budget;
  the actual per-step pop/scale/pitch animation in the fight screen is
  stub-level.

### 3. Boss rules — WORKS — commits 38ce5ce + 6e1db2c
- `data/boss_rules.json` pool of 3, one rolled per boss fight and announced
  before the fight: Jammed Reel (reel 3 locked to Skull), Thin Shield
  (Shields give 0 block), Greed Tax (every spin costs 2 coins, coin payout x2).
- Boss HP unchanged from the existing ladder; the rule is the difficulty.
- Headless tests cover the pool, the per-boss roll, and each rule's effect.
- Balance: boss rules dropped normal sim to 29.0–30.9% (OUT of 40–60%,
  reported plainly, never rounded in). Fixed by `heal_between_fights` 9→15
  (6e1db2c), later 15→16 in SYS5; high_roller re-banded to 15–35%.

### 4. Shop economy — WORKS — commit e9548a6
- Reroll: starts at 2 coins, +1 per reroll in the visit, resets next shop.
- Interest on shop entry: +1 per 10 coins held, capped at +5.
- Permanent upgrades (`data/upgrades.json`, max 1 per shop): Extra Relic Slot
  15c, Reroll Discount 12c, Marrow Tonic +8 max HP 10c. Prices in DECISIONS.md.
- Headless test `_test_shop` covers interest cap, reroll scaling/reset, and
  upgrade purchase rules.

### 5. Reel editing + consumables — WORKS — commit 48ffeac
- `data/consumables.json`, 4 consumables: Gilded Chisel (replace one symbol on
  one reel, 8c), Bone Saw (remove one Skull -> Blank, 6c), Whetstone Oil (level
  a symbol type for the rest of the run, 10c), Loaded Spring (free mid-fight
  reroll, 7c).
- Inventory cap 2; sold in shop (1 random per visit) and 50% boss drop.
- Reel-edit flow: `begin_consumable(id, target)` -> `cancel_consumable()`
  (undo) -> `confirm_consumable()`; invalid target refused at confirm and the
  consumable is returned. Symbol levels apply in `resolve()` and in the SYS2
  sequence tallies.
- Headless test `_test_consumables` covers cap, each consumable, invalid-target
  undo, boss drop, shop stock.
- Balance: SYS5 shifted the RNG stream and seed 777 fell to 39.2% (OUT, stated
  plainly); `heal_between_fights` 16 fixed it — final 5-seed numbers above.

## Gates (final)
- Tests: `tools/test_state.gd` TESTS PASS failures=0 (all pre-existing tests
  plus one new test per system).
- Sim: 1,000 runs x 5 seeds, exact numbers above; normal SIM PASS (40–60%),
  high_roller SIM PASS (15–35%).
- Exports (fresh, local-only in gitignored `build/`): macOS
  `build/macos/GraveSpin.app` (quarantine xattr cleared), Windows
  `build/windows/GraveSpin.exe` 115,658,536 bytes, PE32+ x86-64.

## Commits
0490fab (SYS1), b381aba (SYS2), 38ce5ce (SYS3), 6e1db2c (SYS3 retune),
e9548a6 (SYS4), 48ffeac (SYS5), bdd4033 + 0fd7ba6 (SYS gates + crash fix),
eee6e3c (JOB 1 shop wiring), 6b6f19b (JOB 2 lives), 51ebf7d (JOB 3 polish),
plus this final gate commit (REPORT.md + fresh exports).

## Not tested / stub-level
- Real Windows GPU run, gamepad, human playtest (headless macOS only).
- The SYS2 per-step pop/scale animation and the SYS5 click-target consumable
  flow remain stub-level in the UI screens; engine, data, and headless tests
  are complete. The new shop screen is fully wired (buy/reroll/leave).
- Visual polish was verified by code path + autoplay, not by eye: headless
  rendering produces no frames, so no screenshot check was possible here.
- Known reported conflict unchanged: relic rarity split backlog 10/6/2/2 vs
  shipped 14/10/3/3.
