# Advanced Design Ideas — Grave Spin & Cursed Dice (full-game vision)

Goal: turn the two verified demo slices into Steam-sellable full games at the
brief's prices (Grave Spin $6.99, Cursed Dice $5.99), advanced in every aspect:
design, gameplay, depth, and store presence. Ideas only — nothing here is built
yet. Everything stays inside the brief's guardrails: simulated gambling only
(declared as such in Steam's content survey), no real-money wagering, CC0/CC BY
assets with credits kept, Steam Direct fee is g's to pay.

---

## 1. GRAVE SPIN — full-game vision ($6.99)

### 1.1 Design / presentation
- **Art direction**: "haunted casino in a dungeon." Every screen keeps the
  torch-lit dungeon backdrop + the slot machine as the hero prop. Palette:
  deep purple/black stone, torch orange, gold coins, one accent per floor
  (green = crypt, red = hell, blue = flooded catacombs). Pixel art at 640x360
  internal resolution, integer-scaled, with a CRT-ish scanline option (toggle)
  for the slot-machine fantasy.
- **Juice everywhere** (this is the marketing): screen shake on skulls, coin
  bursts on payout, lever pull animation with weight, staggered reel stops with
  tick SFX, near-miss slow-mo when the last reel can still complete a jackpot,
  damage numbers that pop, enemy hit-flash, death sting + run summary card that
  is screenshot-ready. Every big moment must be clip-worthy for TikTok/Shorts.
- **UI/UX**: one-handed play — big lever button, Space also works. All
  screens readable at 123x58 capsule scale logic: big icons, short text.
  Controller support (Steam Deck verified layout) — d-pad moves, A = pull,
  B = back. Full keyboard+mouse first.
- **Audio**: per-floor music loop (Kevin MacLeod CC BY + more CC0), layered
  slot SFX (spin loop, per-reel stop click, win/lose stingers), UI clicks.
  Volume sliders + mute per bus. Voice-less design keeps localization cheap.
- **Accessibility**: colorblind-safe symbol shapes (each reel symbol also has
  a distinct shape, not just color), adjustable text size, reduced shake/flash
  toggle, remappable keys.

### 1.2 Gameplay depth (combat)
- **Reels grow**: start 3x3. Relics/items can add a 4th row, a 4th reel, or
  diagonal paylines — the machine visibly changes per run (the "no two runs
  pull the same machine" promise).
- **Symbol ecosystem**: sword / shield / potion / coin / skull base five, plus
  floor-specific invaders: enemy symbols that land on YOUR reels (e.g. "rot"
  that eats a random symbol, "curse" that doubles skulls). Each of the 6 enemy
  types invades differently.
- **Bet system**: before each pull you can raise/lower the bet (1-5 coins).
  Higher bet multiplies payouts AND skull penalties — a real risk knob that
  makes every spin a decision, not a foregone conclusion.
- **Enemy telegraphing**: intents stay visible ("hits for 6", "buffs itself",
  "curses a reel"), but elites add multi-part intents you must read two turns
  ahead.
- **Status effects**: block, burn, poison, vulnerable, "lucky" (next spin
  rigged), "cursed" (skulls doubled). Shown as icons with tooltips.

### 1.3 Game depth (roguelite structure)
- **3 floors x 5 fights + floor boss** (the brief's 15-25 min run becomes
  3 floors = ~30-45 min; add an endless mode after floor 3 for depth).
- **30+ relics**, data-driven as already built, in rarities (common/rare/epic/
  cursed). Cursed relics are powerful but add a permanent downside. Synergy
  tags (e.g. "reel", "skull", "coin") make builds identifiable.
- **Meta-progression (Bone Coins)**: unlock tree with real choices — new
  starting relics, extra starting HP, a starting 4th row unlock, machine
  skins (cosmetic), new enemy types in future runs. Persistent save via the
  existing meta_save system, plus Steam Cloud.
- **Daily seed + leaderboards** (Steam leaderboards, free via Steamworks):
  same machine for everyone, highest floor reached. Drives replay without
  any store feature.
- **Difficulty modes**: Normal / "High Roller" (enemies +25%, rewards +50%).

### 1.4 Steam sellability
- Tags already chosen in the brief (Roguelite, Slot Machine, Gambling
  simulated descriptor declared honestly). Add: Steam Achievements (30+),
  Trading Cards (5-8, cheap to make from existing art), Steam Cloud saves,
  controller glyphs, Steam Deck "Verified" target, 10+ languages (text-only,
  cheap), a 90-second trailer built from the clip-worthy moments, Next Fest
  demo = the existing demo slice.
- Pricing: $6.99 with 10-20% launch discount; regional pricing via Steam's
  recommended matrix. No MTX, no battle pass — a clean premium roguelite.
- Post-launch: free content updates (new floor, new relics) to keep wishlist
  conversion and reviews coming; one cosmetic DLC pack later if it sells.

---

## 2. CURSED DICE — full-game vision ($5.99)

### 2.1 Design / presentation
- **Art direction**: "carved stone dice on a dark battlefield map." Hand-drawn
  ink style (the brief allows Hand-Drawn or Pixel — pick one and commit;
  recommend ink + pixel hybrid: pixel dice faces, inked battlefield). Purple
  = curse accent everywhere.
- **Juice**: dice roll physics (tumbling dice with clatter SFX), face-pop
  animations when assigning, screen punch on big hits, corruption aura when a
  die gains a curse face, boss intro stingers. Same clip-worthy standard.
- **UI/UX**: mouse-first as built; drag dice to assign or click in order; clear
  intent icons on enemies; run map screen showing the act path (Slay-the-Spire
  style node map) instead of a linear ladder — bigger depth win.
- **Audio**: dice roll/shake/throw + impact set already pulled; per-act music
  (boss loop exists); corruption whisper SFX on cursed drafts.
- **Accessibility**: same toggles as Grave Spin; dice faces get shape+color
  coding; text size option.

### 2.2 Gameplay depth (combat)
- **Face pool to 40+ faces** with keywords: pierce (ignores block), thorns
  (attacker takes damage), lifesteal, multi-hit, "reroll this die once",
  stance faces that persist. Combos: playing 3 swords triggers "Blade Flurry".
- **Dice as items**: beyond faces, dice themselves get modifiers (weighted die,
  glass die that breaks after 3 uses, golden die). Drafting replaces faces OR
  whole dice at choice nodes.
- **Corruption deepened**: the corruption bargain stays central — corrupted
  faces are double strength but add a curse; at high corruption the run gains
  a "Corrupted" tag with perks AND a final boss change. Risk/reward visible
  on the die.
- **Relics-equivalent "trinkets"**: 20+ passive trinkets (start-of-turn block,
  heal on curse, etc.) drafted at elite nodes.

### 2.3 Game depth (structure)
- **3 acts x (6 fights + elite + boss)** with a node map per act; 8 enemy
  types + 3 bosses (act bosses with 2 phases). 20-30 min runs as briefed.
- **Meta-unlocks**: new starting dice that change the build space (the brief's
  promise) — e.g. a "chaos die" with random faces each run, a "curse-heavy"
  die for high-risk players. Persistent via Steam Cloud.
- **Balance harness stays**: the 200-run sim (already built) becomes a
  1000-run CI check on every data change; target band 35-55% stays. Add an
  endless mode + daily seed + Steam leaderboards like Grave Spin.

### 2.4 Steam sellability
- Same store package pattern: achievements, cards, cloud, Deck verified,
  languages, trailer. $5.99 with launch discount; premium, no MTX.
- Positioning: "deckbuilder meets dice" — the corruption bargain is the hook
  for clips.

---

## 3. Shared engineering plan (how we build this, not just what)

- **Content pipeline**: all balance/content stays in JSON data files (the
  pattern both demos already use) + a small in-editor tool to validate relics/
  faces/enemies. Designers tweak numbers without touching code.
- **Balance**: keep headless sims as CI gates (Grave Spin: win-rate + avg
  spins; Cursed Dice: the 35-55% band). Tune data, never code, to hit bands.
- **Tech**: Godot 4 GDScript (as built), GL Compatibility renderer for Deck,
  Steamworks SDK for achievements/leaderboards/cloud (g owns the Steamworks
  account; we integrate via the GodotSteam-style plugin or raw SDK).
- **Scope gates**: ship full games only after the demo shows wishlist velocity
  (per the brief). Phase 1 = floors 1-2 + 20 relics; Phase 2 = floor 3 +
  endless; Phase 3 = meta tree polish + DLC cosmetics.
- **Quality bars**: 60 fps on Steam Deck, <2s load times, no crashes in 100
  sim runs, all Steam achievements fire in a scripted test run.

## 4. What makes these sellable (honest checklist)
- One-sentence hook that fits a Steam capsule: "Every fight is a pull of the
  lever" / "Build the randomizer."
- Clip-worthy moments by design (near-miss jackpots, corruption gambles).
- 15-45 min runs fit modern play patterns; meta-progression gives return
  reasons; daily seed + leaderboards give free retention.
- Honest gambling-simulated declaration keeps the store page safe.
- Price points ($6.99/$5.99) match the scope; no predatory MTX.
