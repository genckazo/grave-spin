# REPORT.md — Grave Spin demo slice

**What works:** the full demo loop runs end to end — title → fight (3x3 slot machine, lever pull, 0.9 s staggered reel stops, 3 row paylines resolved: sword damage, shield block, potion heal, coin payout, skull penalty) → 1-of-3 relic draft between fights → death/victory screen after the 5-fight ladder, with 3 enemy types (Skeleton, Slime, Cultist) and 12 data-driven relics in `data/relics.json`. The headless suite `tools/test_state.gd` (36 checks: data loading, payline math, relic hooks, draft, full run to victory, Bone Coin meta save) passes, all eight screens were captured in `build/shots/`, and the Windows export built cleanly to `build/windows/GraveSpin.exe` (115 MB, PE32+). **What's stubbed:** the meta unlock tree is out of scope per the brief — Bone Coins persist in a save file and show on the title screen only; tuning was done with the standalone Python approximation `tools/balance_tune.py`, whose win rate with relic drafting lands near 60% and ~0% without relics, confirming relics are the power curve. **What was not tested:** real GPU rendering and input on Windows hardware (screenshots and headless checks only, environment is headless macOS), audio by ear, gamepad input, and long playtest feel — timing and juice were judged from screenshots.

---

# REPORT — 5-systems build (tutorial, sequencing, boss rules, shop, consumables)

Branch: `coder2/sys4-5-grave-spin` (my own pass; built on main `6e1db2c` which already carried SYS1-3 engine commits `0490fab`/`b381aba`/`38ce5ce`/`6e1db2c` from the team). My commits: `cbae75d` (SYS4 shop + SYS5 engine, sim 5 seeds, shop screen, tests), `b94c49e` (SYS5 consumable UI + SYS1-3 UI wiring: tooltips, boss-rule banner, sequence animation, skip-tutorial).

Per system — works / stubbed / untested:

1. **Tutorial + tooltips — WORKS.** First-run-only `tutorial_done` save flag (skippable via pause-menu SKIP TUTORIAL and on later runs); fight 1 first spin scripted to all-swords (kills fight 1 via jackpot double); teach-on-encounter lines for first Skull / relic pick / shop visit / consumable; hover tooltips on every symbol (reel cells), relic, enemy and consumable from `data/tooltips.json` (42 entries, coverage test-enforced).
2. **Trigger sequencing — WORKS.** `resolve()` report carries an ordered `sequence`: symbols left-to-right then relics in slot order then a total, each step with running damage/block/heal/coins/self tallies; UI animates steps with pop/scale, per-step rising pitch and on-screen tally, total ≤2.5s (`per = min(0.16, 2.2/steps)`); holding the mouse button or fast mode skips to the final numbers.
3. **Boss rules — WORKS.** Pool of 3 in `data/boss_rules.json` (Jammed Reel / Thin Shield / Greed Tax), one rolled per boss fight, shown by name + tooltip in the enemy panel before the fight; HP stays on the ladder scale.
4. **Shop economy — WORKS.** Shop after every boss; interest +1 per 10 coins held at entry capped +5; reroll starts 2, +1 per reroll per visit, resets next visit; 3 permanent upgrades (max 1 per shop): +1 Relic Slot 18c, Reroll Discount 12c (min 1), +8 Max HP 10c; prices in DECISIONS.md, sim-routed and in band.
5. **Reel editing + consumables — WORKS.** Inventory max 2; 4 consumables (Grave Chisel replace symbol, Rite of Unmaking skull→Blank, Oath of the Blade level symbol run-wide, Second Pull free mid-fight reroll); bosses drop one 50%; UI: click consumable → click reel cell → symbol picker if needed → CONFIRM/UNDO (undo before confirm); usable outside spin animations.

Gates, exact numbers (this branch, HEAD `b94c49e`):
- `tools/test_state.gd`: **TESTS PASS failures=0** (includes new shop + consumable + tooltip-coverage tests).
- `tools/balance_sim.gd` 1000 runs × 5 seeds (12345/777/2024/99999/31337): **48.2% (482/1000) / 46.4% (464/1000) / 49.0% (490/1000) / 46.4% (464/1000) / 47.7% (477/1000)** — all IN the 40-60% band, SIM PASS exit 0. No out-of-band seeds.
- Fresh exports (local, gitignored): `build/macos/GraveSpin.app`, `build/windows/GraveSpin.exe` (115,674,088 bytes, PE32+).
- Autoplay headless run reaches the end screen (shop routing exercised).

Not tested: real Windows GPU run, gamepad, human playtest (headless macOS only). Guardrails intact: no real-money, simulated-gambling declaration, CC0/CC BY/OFL credits. Nothing done for Cursed Dice. STOP.
