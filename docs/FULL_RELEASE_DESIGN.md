# Full-release design — Grave Spin & Cursed Dice
Grounded in the current demo slices (`GraveSpin/`, `CursedDice/`). Ideas only — nothing here is built yet.

---

## 0. Shared principles (both games)

1. **Data-driven everything.** Relics/faces/enemies/floors stay JSON loaded by an engine script (already the pattern in both demos). Full-game content is added by editing data, never code.
2. **One signature system per game, pushed deep.** Grave Spin = the machine (reels, weights, paylines, jackpots). Cursed Dice = the dice (faces, melt, corruption). Everything else supports the signature.
3. **Runs are stories.** Seeded runs + shareable seed codes ("daily run" style) make clips and watercooler moments — the brief's clip-worthy near-miss is the marketing engine.
4. **Steam-sellability checklist per game:** wishlist-driving hook (one sentence), 20–40 min runs, 3+ hours of mastery, achievements, trading-card-ready art, cloud saves, controller support, localization (start with EFIGS + Japanese/Chinese), content survey declared correctly (simulated gambling for Grave Spin), price $6.99 / $5.99 as briefed, regional pricing, demo = the slice already built.

---

## 1. GRAVE SPIN — from 1 floor / 5 fights / 12 relics to full release

### Design (look & feel)
- **Art direction:** torch-lit dungeon slot machine as the hub. Each floor has a theme (Crypt, Catacombs, Hell) that reskins machine frame, backdrop, enemy set, and music stem. Pixel art at integer scaling, 1080p, with a palette shift per floor (already have Tiny Dungeon + icon set to extend).
- **UI:** the machine IS the UI — lever, reels, paytable as an in-world plaque. HUD minimal: HP as heart containers, coins as a physical pile counter. Damage numbers pop off the enemy. Screen shake on skulls, coin-burst particles on jackpots (pixelfx).
- **Audio:** layered slot SFX per symbol (sword = steel, skull = low bell), music that intensifies per floor (stems: ambient → percussion → lead). Lever pull has a physical clunk + spring sound.

### Gameplay systems (the depth)
- **Reels grow:** start 3x3; relics add a 4th row, then a 4th column, then diagonals as paylines. Weights per symbol become tunable per reel (e.g., "loaded top reel" relic).
- **Symbol evolutions:** gold sword (2x damage), cursed skull (enemy intent +4), gem (coins x3). Enemy-specific symbols that invade your reels mid-fight (already in brief, now real: e.g., Slime adds blank faces for 2 spins).
- **Jackpots:** 3-of-a-kind on a payline triggers a jackpot event (free re-spin, enemy stunned, or full heal) — the near-miss slow-mo already built becomes a meter that builds toward guaranteed jackpots ("pity timer").
- **Fight structure:** 3 floors x 6 fights + floor boss + final boss. Bosses have multi-phase intents and reel-invasion patterns. Elite fights (harder, better relic draft of 1-of-5).
- **Relics 12 → 30+:** synergy clusters (Sword cluster, Shield cluster, Economy cluster, Gamble cluster). Cross-cluster relics are the build-defining moments ("every skull also heals you 1").
- **Meta-progression (Bone Coins):** unlock tree with 3 branches — new starting relics, new machine skins (cosmetic), new symbols in the pool. Prestige: "Descend deeper" resets unlocks for a permanent +5% coin bonus.

### Steam features
- Achievements (~25): first jackpot, win with only skulls showing, 100 jackpots, beat floor 3 boss without taking damage, etc.
- Daily seed + leaderboard (Steam Leaderboards, free), shareable run code.
- Cloud save, controller support, 10 languages at launch (text is cheap, do it), Steam Deck verified target.
- Trading cards via the icon/art set; capsule art per the existing brief.

---

## 2. CURSED DICE — from 1 act / 7 fights / 24 faces to full release

### Design (look & feel)
- **Art direction:** dark battlefield map as the board; dice are carved stone with rune-glow faces. Curse = purple corruption spreading across the die texture the more curse faces it holds — visualizes the central bargain.
- **UI:** enemy intent shown as a large telegraphed icon with numbers (perfect information is the selling point). Draft screen styled as a forge/anvil where you melt and carve faces.
- **Audio:** dice clatter layered by count rolled, curse whisper on corrupt picks, dark tactical loop per act with boss variant.

### Gameplay systems (the depth)
- **3 acts x 8 fights + act boss (3 bosses total), 8 enemy types.** Each act adds a twist: act 2 enemies buff each other, act 3 enemies curse your dice on hit.
- **Faces 24 → 40+:** new kinds — multi-face (sword+shield), chain (play adjacent dice), wild, curse-synergy faces. Data-driven already, so this is content work.
- **Dice beyond the starter five:** draft whole dice between acts (different shapes: d4 with strong faces, d8 with blanks), meta-unlocks add new starting dice (already scoped as meta-unlocks — now real).
- **Corruption deepened:** a corruption track per run — every corrupt pick fills it; at thresholds you get a powerful "Desperation" reward but the final boss gets stronger. Risk/reward dial the player turns themselves.
- **Perfect-information mastery:** because there's no hidden info, skill expression = build + sequencing. Add a "predicted outcome" ghost line showing exact damage/block if you end turn now — makes losses feel like your fault (the brief's promise), which drives retries.
- **Balance harness stays mandatory:** every content patch runs the 200-run sim across seeds; win-rate band 35–55% for the auto-player, plus a "greedy player" policy to check skill ceiling.

### Steam features
- Achievements (~25): win without blocking, win with 5 curse faces, beat act 3 with no corrupted faces, etc.
- Daily seed + leaderboards, shareable dice builds (export build code string).
- Cloud save, controller, EFIGS+JA/ZH localization, Deck verified, trading cards.

---

## 3. Technical architecture (both)
- **Shared patterns:** JSON data + engine script (already in place). Add: schema version field in each JSON so save files and content patches don't break old runs.
- **Save system:** encrypted-ish local save + Steam Cloud sync; run seed stored for replay/verification.
- **Mod support (cheap, big goodwill):** expose the data folder + a Steam Workshop "custom faces/relics" pipeline for JSON content only. No code mods — keeps balance harness valid.
- **Analytics:** lightweight event log (runs started, fights won, relic picks) to local file, opt-in upload — used to tune the 35–55% band post-launch.
- **Export matrix:** Windows + macOS + Linux + Steam Deck; Proton is free on Linux target.

## 4. Monetization & release plan
- Base games at $6.99 / $5.99 (per brief). No real-money gambling anywhere — declare "simulated gambling" in Steam's content survey for Grave Spin.
- Cosmetic-only DLC later (machine skins / dice skins) — no gameplay DLC to keep the fairness promise.
- Marketing hooks: daily seeds, clip-worthy near-misses/jackpots, shareable build/seed codes, Next Fest demo (the slices already built).
- Roadmap: (1) full content pass on Grave Spin (floors 2–3, 30+ relics, bosses) → (2) polish/juice/achievements/localization → (3) Next Fest demo → (4) Cursed Dice same pipeline behind it. Sequence matches the brief: Grave Spin first, Cursed Dice one step behind.
