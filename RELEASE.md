# GRAVE SPIN — RELEASE PACKAGE (full release readiness)

Price: $6.99 USD, premium one-time purchase, no MTX. Simulated gambling only —
declared exactly that way in Steam's content survey. No real-money wagering.

## Store copy
- Short: "A haunted slot machine in a dungeon. Every spin is a bet; every floor
  a gamble. 3 floors, endless mode, 30 synergy relics, High Roller difficulty."
- Long: see docs/FULL_RELEASE_SPEC.md section 1. Signature system: the machine
  (bet knob 1-5, near-miss pity timer, growable reels, tag synergies).

## Press kit notes
- Clip-worthy moment: the near-miss slow-mo into a pity-timer jackpot.
- Screenshots: run-summary card, floor 3 "Hell" palette, High Roller mode select.
- Demo (Steam Next Fest) = current verified slice: 3 floors + endless, all green
  headless gates.

## Launch checklist
- [ ] Steam content survey: simulated gambling declaration (Grave Spin)
- [ ] CC0/CC BY credits intact (Kenney sprites/SFX, Kevin MacLeod music, OFL fonts)
- [ ] Achievements (25, data/achievements.json), trading cards, Steam Cloud saves
- [ ] Localization at launch: EFIGS + JA/ZH (data/loc/*.csv); 10+ post-launch
- [ ] Controller support + Steam Deck verified target, 60 fps, <2 s loads
- [ ] Regional pricing + launch discount
- [ ] Steam Direct fee ($100) — owner's cost

## Export matrix
- Windows: build/windows/GraveSpin.exe (PE32+)
- macOS: build/macos/GraveSpin.app (universal)
- Linux: build/linux/GraveSpin.x86_64 (Proton-compatible)

## Gates (headless, CI-enforced on every push)
- tools/test_state.gd — TESTS PASS, failures=0
- tools/balance_sim.gd — 1000 runs x seeds 12345/777/2024, normal 40-60%,
  high_roller 25-45%; any seed outside its band fails the build

## Known open items
- Spec-vs-shipped relic rarity split (backlog 10/6/2/2 vs shipped 14/10/3/3) —
  reported, shipped data is source of truth.
- Steam-side integration (Steamworks achievements sync, store page, payments)
  needs the owner's Steam account — parked.
