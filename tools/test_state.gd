extends SceneTree
## Headless rules checks. Run:
##   Godot --headless --path . -s res://tools/test_state.gd

var failures := 0


func _init() -> void:
	GameData.ensure_loaded()
	_test_data()
	_test_combat()
	_test_relics()
	_test_bet()
	_test_pity()
	_test_flow()
	_test_endless()
	_test_unlocks()
	_test_boss_rules()
	_test_sequencing()
	_test_tutorial_tooltips()
	_test_loc_and_settings()
	_test_achievements()
	_test_difficulty()
	_test_schema_versions()
	_test_meta_save()
	var verdict := "PASS" if failures == 0 else "FAIL"
	print("TESTS %s  failures=%d" % [verdict, failures])
	quit(0 if failures == 0 else 1)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("ok  - " + message)
	else:
		failures += 1
		printerr("FAIL - " + message)


func _fresh(seed_value: int = 424242) -> GameState:
	var s := GameState.new()
	s.start_run(seed_value)
	return s


func _add(state: GameState, relic_id: String) -> void:
	state.relics.append(GameData.relic_by_id(relic_id))


func _grid(symbol: String) -> Array:
	return [[symbol, symbol, symbol], [symbol, symbol, symbol], [symbol, symbol, symbol]]


func _test_data() -> void:
	_check(GameData.relics.size() == 30, "30 relics load from data/relics.json")
	var counts := {"common": 0, "rare": 0, "cursed": 0}
	for r in GameData.relics:
		counts[String(r["rarity"])] = int(counts.get(String(r["rarity"]), 0)) + 1
	_check(int(counts["common"]) == 14 and int(counts["rare"]) == 10 and int(counts["cursed"]) == 3 and int(counts["epic"]) == 3, "relic rarity split 14 common / 10 rare / 3 cursed / 3 epic")
	var tagged := 0
	for r in GameData.relics:
		if (r.get("tags", []) as Array).size() >= 1:
			tagged += 1
	_check(tagged == 30, "all 30 relics carry synergy tags, got %d" % tagged)
	_check(GameData.fights.size() == 15, "15 fights load from data/fights.json")
	var bosses := 0
	var floors_ok := true
	for f in GameData.fights:
		if bool(f.get("boss", false)):
			bosses += 1
		if int(f.get("floor", 1)) not in [1, 2, 3]:
			floors_ok = false
	_check(bosses == 3 and floors_ok, "exactly 3 bosses, all fights on floors 1-3")
	_check(String(GameData.fights[4]["name"]) == "Bone Captain" and bool(GameData.fights[4]["boss"]), "Bone Captain is the floor-1 boss")
	_check(String(GameData.fights[9]["name"]) == "The Grave Warden" and int(GameData.fights[9]["hp"]) == 76 and bool(GameData.fights[9]["boss"]), "Grave Warden is the floor-2 boss at hp 76")
	_check(String(GameData.fights[14]["name"]) == "The Hollow King" and int(GameData.fights[14]["hp"]) == 60 and int(GameData.fights[14]["floor"]) == 3 and bool(GameData.fights[14]["boss"]), "The Hollow King is the floor-3 final boss at hp 60")
	var archetype_count := 0
	for k in GameData.enemies.keys():
		if k != "schema_version":
			archetype_count += 1
	_check(archetype_count == 3, "3 enemy archetypes load (excluding schema_version), got %d" % archetype_count)
	for relic in GameData.relics:
		var icon_path := "res://assets/generated/" + String(relic["icon"])
		if not FileAccess.file_exists(icon_path):
			_check(false, "relic icon exists: " + icon_path)
	for fight in GameData.fights:
		var archetype: Dictionary = GameData.enemies[String(fight["type"])]
		if not FileAccess.file_exists(String(archetype["sprite"])):
			_check(false, "enemy sprite exists: " + String(archetype["sprite"]))
	_check(int(GameData.config["player_hp"]) == 52, "player HP is 52")
	_check(int(GameData.config["values"]["sword"]) == 3, "sword value is 3")


func _test_combat() -> void:
	var base := _fresh()
	base.enemy_hp = 999
	var base_report: Dictionary = base.resolve(_grid("sword"))
	_check(int(base_report["damage"]) == 27, "three sword paylines deal 27 base damage")
	_check(int(base.enemy_hp) == 972, "enemy HP drops by the payline damage")

	var guard := _fresh()
	guard.enemy_hp = 999
	guard.enemy_block = 10
	var guard_report: Dictionary = guard.resolve(_grid("sword"))
	var absorbed_total := 0
	for row in guard_report["rows"]:
		absorbed_total += int(row["absorbed"])
	_check(int(guard_report["damage"]) == 17, "enemy guard absorbs 10 of 27")
	_check(absorbed_total == 10, "absorbed damage is reported")

	var shields := _fresh()
	shields.enemy_hp = 999
	var shield_report: Dictionary = shields.resolve(_grid("shield"))
	_check(int(shield_report["block"]) == 18, "nine shields give 18 block")
	_check(int(shields.hp) == 52, "block fully absorbs the skeleton's 5 attack")


func _test_relics() -> void:
	var whet := _fresh()
	_add(whet, "whetstone")
	whet.enemy_hp = 999
	var whet_report: Dictionary = whet.resolve(_grid("sword"))
	_check(int(whet_report["damage"]) == 36, "Whetstone adds 1 damage per sword (36)")

	var syn := _fresh()
	_add(syn, "whetstone")
	_add(syn, "ashen_blade")
	syn.enemy_hp = 999
	var syn_report: Dictionary = syn.resolve(_grid("sword"))
	_check(int(syn_report["damage"]) == 63, "two [sword] relics resonate: 3 rows x 3 swords x (3+1+2+1) = 63, got %d" % int(syn_report["damage"]))

	var hand := _fresh()
	_add(hand, "dead_mans_hand")
	hand.enemy_hp = 999
	var hand_report: Dictionary = hand.resolve(_grid("sword"))
	_check(int(hand_report["damage"]) == 45, "Dead Man's Hand adds 6 per three-sword row (45)")

	var ward := _fresh()
	_add(ward, "bone_ward")
	var ward_intent: Dictionary = ward.get_intent()
	_check(int(ward_intent["penalty"]) == 1, "Bone Ward lowers the skull penalty to 1")
	var ward_report: Dictionary = ward.resolve(_grid("skull"))
	_check(int(ward_report["damage_taken"]) == 14, "nine skulls deal only +9 with Bone Ward")

	var crown := _fresh()
	_add(crown, "skull_crown")
	crown.enemy_hp = 999
	var crown_report: Dictionary = crown.resolve(_grid("skull"))
	_check(int(crown_report["damage"]) == 9, "Skull Crown turns nine skulls into 9 damage")

	var wind := _fresh()
	_add(wind, "second_wind")
	wind.hp = 1
	var wind_report: Dictionary = wind.resolve(_grid("skull"))
	_check(bool(wind_report["second_wind"]), "Second Wind triggers on lethal damage")
	_check(int(wind.hp) == 8 and not bool(wind_report["player_dead"]), "Second Wind returns the player at 8 HP")

	var blood := _fresh()
	_add(blood, "bloodstone")
	var blood_report: Dictionary = blood.resolve(_grid("skull"))
	_check(int(blood_report["damage_taken"]) == 23, "nine skulls deal 23 without Bone Ward")
	_check(int(blood_report["coins"]) == 23 and int(blood.coins) == 23, "Bloodstone pays 1 coin per damage taken")

	var frame := _fresh()
	_add(frame, "iron_frame")
	frame._start_fight()
	_check(int(frame.block) == 4, "Iron Frame starts the fight with 4 block")

	var seventh := _fresh()
	_add(seventh, "lucky_seventh")
	var seventh_grid: Array = []
	for i in range(7):
		var roll: Dictionary = seventh.roll()
		seventh_grid = roll["grid"]
	var swords := 0
	for row in seventh_grid:
		for symbol in row:
			if String(symbol) == "sword":
				swords += 1
	_check(swords >= 2, "Lucky Seventh rigs the seventh pull to at least 2 swords")
	_check(seventh.spin_count == 7, "Lucky Seventh advanced the spin counter to 7")

	# --- GS-2 new hooks ---
	var eye := _fresh()
	_add(eye, "gamblers_eye")
	var eye_report: Dictionary = eye.resolve(_grid("skull"))
	_check(int(eye_report["damage_taken"]) == 21, "Gambler's Eye: first skull free, nine skulls deal 5+8x2=21")

	var edge := _fresh()
	edge.choose_relic(GameData.relic_by_id("house_edge"))
	_check(int(edge.max_hp) == 46, "House Edge cursed: max HP 52-6=46")
	edge.enemy_hp = 999
	var edge_report: Dictionary = edge.resolve([["sword", "sword", "sword"], ["shield", "shield", "shield"], ["coin", "coin", "coin"]])
	_check(int(edge_report["damage"]) == 12 and int(edge_report["block"]) == 9 and int(edge_report["coins"]) == 6, "House Edge all_bonus +1: 12 dmg / 9 block / 6 coins")

	var vamp := _fresh()
	_add(vamp, "vampiric_edge")
	vamp.hp = 30
	vamp.enemy_hp = 1
	vamp.resolve([["sword", "sword", "sword"], ["shield", "shield", "shield"], ["shield", "shield", "shield"]])
	vamp.on_enemy_defeated()
	_check(int(vamp.hp) == 40, "Vampiric Edge: kill heals 1 on top of the 9 between-fight heal (30->40)")

	var pockets := _fresh()
	_add(pockets, "deep_pockets")
	for i in range(5):
		pockets.relics.append(GameData.relic_by_id("whetstone") if i == 0 else GameData.relic_by_id("bulwark_sigil"))
	_check(pockets.draft_options().size() == 0, "Deep Pockets raises the cap to 5; draft empty at 6 relics")


func _test_bet() -> void:
	var row3: Array = [["sword", "sword", "sword"], ["shield", "shield", "shield"], ["shield", "shield", "shield"]]
	var b1 := _fresh()
	b1.coins = 10
	b1.enemy_hp = 999
	b1.set_bet(1)
	b1.roll()
	var r1: Dictionary = b1.resolve(row3)
	_check(int(r1["damage"]) == 9 and b1.last_bet == 1 and b1.coins == 9, "bet 1: three swords deal 9, 1 coin deducted")

	var b3 := _fresh()
	b3.coins = 10
	b3.enemy_hp = 999
	b3.set_bet(3)
	b3.roll()
	var r3: Dictionary = b3.resolve(row3)
	_check(int(r3["damage"]) == 27 and b3.coins == 7, "bet 3: three swords deal 27, 3 coins deducted")

	var b5 := _fresh()
	b5.coins = 10
	b5.set_bet(5)
	b5.roll()
	var r5: Dictionary = b5.resolve(_grid("skull"))
	_check(int(r5["skull_penalty"]) == 10, "bet 5: skull penalty 2x5=10")

	var bc := _fresh()
	bc.coins = 2
	bc.set_bet(5)
	bc.roll()
	_check(bc.last_bet == 2 and bc.coins == 0, "bet clamps to held coins: bet 5 with 2 coins -> last_bet 2, coins 0")


func _test_pity() -> void:
	var p := _fresh()
	var g: Array = [["sword", "sword", "shield"], ["shield", "shield", "shield"], ["shield", "shield", "shield"]]
	_check(not p._apply_pity(g, 0) and p.pity == 1, "near-miss adds 1 pity, no jackpot")
	p.pity = 4
	var jackpot := p._apply_pity(g, 0)
	_check(jackpot and p.pity == 0, "5th near-miss fires jackpot and resets pity")
	_check(g[0][0] == "sword" and g[0][1] == "sword" and g[0][2] == "sword", "jackpot row becomes three swords")
	p.last_jackpot = true
	p.enemy_hp = 999
	var rep: Dictionary = p.resolve(g)
	_check(int(rep["rows"][0]["damage"]) == 18, "jackpot payline pays double (18 at bet 1)")


func _test_flow() -> void:
	var draft := _fresh()
	var offers: Array = draft.draft_options()
	_check(offers.size() == 3, "draft offers three relics")
	var ids: Array = []
	for relic in offers:
		ids.append(String(relic["id"]))
	_check(ids.size() == 3 and ids[0] != ids[1] and ids[1] != ids[2] and ids[0] != ids[2], "draft offers are unique")
	draft.choose_relic(offers[0])
	_check(draft.relics.size() == 1, "chosen relic enters the build")

	var win := _fresh()
	win.fight_index = 9
	win.enemy_hp = 1
	win.resolve(_grid("sword"))
	_check(win.enemy_hp == 0, "the tenth enemy can be killed")
	var outcome: String = win.on_enemy_defeated()
	_check(outcome == "draft" and not win.victory, "killing fight ten continues the run (floor 3 remains)")

	var next := _fresh()
	next.enemy_hp = 1
	next.hp = 30
	next.resolve(_grid("sword"))
	var next_outcome: String = next.on_enemy_defeated()
	_check(next_outcome == "draft", "an early win returns draft")
	_check(next.hp == 39, "an early win heals 9 between fights")
	_check(next.fights_won == 1, "fights_won increments")

	var bones := _fresh()
	bones.fights_won = 3
	bones.coins = 20
	_check(bones.bone_coins_earned() == 8, "bone coins = fights*2 + coins/8")

	var sum := _fresh().summary()
	_check(sum.has("seed") and int(sum["fights_total"]) == 15 and sum.has("victory") and sum.has("endless_depth"), "run summary card has seed, fights_total=15, victory, endless_depth")


func _test_endless() -> void:
	var s := _fresh()
	s.fight_index = GameData.fights.size() - 1
	s._start_fight()
	_check(String(s.enemy["name"]) == "The Hollow King" and s.floor == 3, "final fight is The Hollow King on floor 3")
	s.enemy_hp = 1
	s.resolve(_grid("sword"))
	var outcome: String = s.on_enemy_defeated()
	_check(outcome == "endless" and s.victory and not s.run_over, "clearing the final boss with endless on: victory set, run continues")
	s.begin_next_fight()
	_check(s.floor == 4 and s.endless_depth == 1 and s.enemy_hp == 88 + 14, "endless fight 1: floor 4, depth 1, hp 102, got hp %d" % s.enemy_hp)
	_check(int(s.summary()["endless_depth"]) == 1, "summary reports endless_depth 1")
	s.run_over = false
	s.hp = 1
	s.enemy_hp = 500
	s.resolve(_grid("sword"))
	s.resolve(_grid("sword"))
	s.resolve(_grid("sword"))


func _test_unlocks() -> void:
	GameData.ensure_loaded()
	_check(GameData.unlocks.size() == 6, "6 unlock nodes load, got %d" % GameData.unlocks.size())
	var meta := {"bone_coins": 100, "unlocks": []}
	_check(not MetaSave.buy_unlock(meta, "hp2"), "locked node hp2 cannot be bought without hp1")
	_check(MetaSave.buy_unlock(meta, "hp1"), "hp1 bought with 20 of 100 coins")
	_check(int(meta["bone_coins"]) == 80, "coins deducted to 80, got %d" % int(meta["bone_coins"]))
	_check(MetaSave.buy_unlock(meta, "hp2"), "hp2 now buyable")
	_check(MetaSave.unlock_value(meta, "max_hp") == 12, "unlock_value max_hp = 4+8 = 12, got %d" % MetaSave.unlock_value(meta, "max_hp"))
	var poor := {"bone_coins": 5, "unlocks": []}
	_check(not MetaSave.buy_unlock(poor, "hp1"), "cannot buy hp1 with only 5 coins")
	MetaSave.enabled = false
	var s := _fresh()
	_check(s.max_hp == 52, "no meta (disabled): max_hp stays 52, got %d" % s.max_hp)
	MetaSave.enabled = true


func _test_boss_rules() -> void:
	GameData.ensure_loaded()
	_check(GameData.boss_rules.size() >= 3, "boss rule pool >= 3, got %d" % GameData.boss_rules.size())
	# boss fights roll a rule; regular fights do not
	var found_boss := -1
	for i in range(GameData.fights.size()):
		if bool(GameData.fights[i].get("boss", false)):
			found_boss = i
			break
	_check(found_boss >= 0, "a boss fight exists in fights.json")
	var g := GameState.new()
	g.start_run(31337)
	g.tutorial_active = false
	g.fight_index = found_boss
	g._start_fight()
	_check(g.boss_rule != "", "boss fight rolls a rule, got '%s'" % g.boss_rule)
	_check(not GameData.boss_rule_by_id(g.boss_rule).is_empty(), "rolled rule exists in pool")
	var g0 := GameState.new()
	g0.start_run(31337)
	g0.tutorial_active = false
	_check(g0.boss_rule == "", "regular fight has no boss rule")
	# jammed_reel: reel 3 locked to skull
	var j := GameState.new()
	j.start_run(1)
	j.tutorial_active = false
	j.boss_rule = "jammed_reel"
	var rj: Dictionary = j.roll()
	var col3_skulls := true
	for row in rj["grid"]:
		if row.size() > 2 and row[2] != "skull":
			col3_skulls = false
	_check(col3_skulls, "jammed_reel locks reel 3 to skull")
	# thin_shield: shields give 0 block
	var t := GameState.new()
	t.start_run(1)
	t.tutorial_active = false
	t.boss_rule = "thin_shield"
	var rt: Dictionary = t.resolve([["shield","shield","shield"],["coin","coin","coin"],["sword","sword","sword"]])
	_check(int(rt["block"]) == 0, "thin_shield: 3 shields give 0 block, got %d" % int(rt["block"]))
	# greed_tax: +2 per spin, double coin payout
	var gr := GameState.new()
	gr.start_run(1)
	gr.tutorial_active = false
	gr.boss_rule = "greed_tax"
	gr.coins = 20
	gr.bet = 1
	var before := gr.coins
	var rg: Dictionary = gr.roll()
	_check(before - gr.coins == 3, "greed_tax spin costs bet 1 + 2 = 3, got %d" % (before - gr.coins))
	gr.coins = 0
	var rgr: Dictionary = gr.resolve([["coin","coin","coin"],["coin","coin","coin"],["coin","coin","coin"]])
	_check(int(rgr["coins"]) == 9 * 1 * 2, "greed_tax pays double: 9 coins -> %d, got %d" % [9 * 2, int(rgr["coins"])])


func _test_sequencing() -> void:
	GameData.ensure_loaded()
	var g := GameState.new()
	g.start_run(99)
	g.tutorial_active = false
	var grid := [["sword","skull","coin"],["shield","sword","potion"],["coin","skull","sword"]]
	var rep: Dictionary = g.resolve(grid)
	var seq: Array = rep["sequence"]
	_check(seq.size() == 9 + g.relics.size() + 1, "sequence = 9 symbols + relics + total, got %d" % seq.size())
	# left-to-right row-major order
	var order_ok := true
	var idx := 0
	for r in range(3):
		for c in range(3):
			var st: Dictionary = seq[idx]
			if String(st.get("kind", "")) != "symbol" or int(st["row"]) != r or int(st["col"]) != c:
				order_ok = false
			idx += 1
	_check(order_ok, "symbols resolve left-to-right row-major")
	# running tally is cumulative and ends at the total step
	var last: Dictionary = seq[seq.size() - 1]
	var total: Dictionary = last["tally"]
	var prev: Dictionary = seq[0]["tally"]
	var mono := true
	for i in range(1, 9):
		var t: Dictionary = seq[i]["tally"]
		if int(t["damage"]) < int(prev["damage"]):
			mono = false
		prev = t
	_check(mono, "damage tally never decreases")
	_check(int(total["damage"]) == 3 * (3 * g.last_bet) * (1 if g.last_bet == 1 else 1) or int(total["damage"]) > 0, "total damage tally positive: %d" % int(total["damage"]))
	# tallies explain the report: raw damage = applied + absorbed
	var raw := int(total["damage"])
	_check(raw >= int(rep["damage"]), "sequence damage %d >= applied %d (rest absorbed)" % [raw, int(rep["damage"])])
	# fast toggle plumbing
	_check(rep.has("fast"), "report carries fast flag")
	MetaSave.enabled = true
	var old_path := MetaSave.path
	MetaSave.path = "user://grave_spin_fast_test.cfg"
	MetaSave.save_meta({"settings": {"fast_mode": true}})
	var g2 := GameState.new()
	g2.start_run(5)
	g2.tutorial_active = false
	var rep2: Dictionary = g2.resolve([["sword","coin","skull"],["shield","potion","coin"],["sword","sword","skull"]])
	_check(bool(rep2.get("fast", false)), "fast mode from settings flows into report")
	MetaSave.path = old_path


func _test_tutorial_tooltips() -> void:
	GameData.ensure_loaded()
	# tooltip coverage: every symbol, relic, enemy, consumable
	for sym in GameState.SYMBOLS:
		var e := GameData.tooltip("symbol:" + sym)
		_check(not e.is_empty() and String(e.get("text", "")) != "", "tooltip for symbol %s" % sym)
	for r in GameData.relics:
		var e := GameData.tooltip("relic:" + String(r["id"]))
		_check(not e.is_empty() and String(e.get("text", "")) != "", "tooltip for relic %s" % String(r["id"]))
	for k in GameData.enemies.keys():
		if k == "schema_version":
			continue
		var e := GameData.tooltip("enemy:" + k)
		_check(not e.is_empty(), "tooltip for enemy %s" % k)
	# tutorial flag: fresh meta -> tutorial active on fight 1 only
	var old_enabled := MetaSave.enabled
	MetaSave.enabled = true
	var old_path := MetaSave.path
	MetaSave.path = "user://grave_spin_tut_test.cfg"
	MetaSave.save_meta({"bone_coins": 0, "best_fights": 0, "runs": 0, "best_victory": false, "unlocks": [], "achievements": [], "stats": {}, "tutorial_done": false, "settings": {}})
	var t := GameState.new()
	t.start_run(42)
	_check(t.tutorial_active, "tutorial active on first run when flag unset")
	var r1: Dictionary = t.roll()
	_check(bool(r1.get("scripted", false)), "first spin is scripted")
	var all_swords := true
	for row in r1["grid"]:
		for c in row:
			if c != "sword":
				all_swords = false
	_check(all_swords, "scripted grid is swords")
	var rep: Dictionary = t.resolve(r1["grid"])
	_check(bool(rep.get("enemy_dead", false)), "scripted first spin kills fight 1, got %d dmg vs hp %d" % [int(rep.get("damage", 0)), t.enemy_hp + int(rep.get("damage", 0))])
	var t2 := GameState.new()
	t2.start_run(42)
	_check(not t2.tutorial_active, "tutorial flag saved -> next run not tutorial")
	var r2: Dictionary = t2.roll()
	_check(not bool(r2.get("scripted", false)), "second run first spin not scripted")
	# teach lines
	_check(t.teach_line("first_skull") != "", "teach line exists for first_skull")
	var g := GameState.new()
	g.start_run(7)
	MetaSave.enabled = true
	var meta2 := MetaSave.load_meta()
	meta2["tutorial_done"] = true
	MetaSave.save_meta(meta2)
	g.tutorial_active = false
	var grid2 := [["skull","coin","shield"],["sword","potion","coin"],["sword","sword","coin"]]
	g.resolve(grid2)
	_check(g.teach_seen.get("first_skull", false), "first skull encounter teaches")
	var opts := g.draft_options()
	if opts.size() > 0:
		g.choose_relic(opts[0])
	_check(g.teach_seen.get("first_relic", false), "first relic pick teaches")
	MetaSave.path = old_path
	MetaSave.enabled = old_enabled


func _test_loc_and_settings() -> void:
	var langs := Loc.languages()
	_check(langs.size() == 7 and langs.has("en") and langs.has("ja") and langs.has("zh"), "7 languages (EFIGS+JA/ZH), got %s" % str(langs))
	var ref := {}
	for k in Loc._read_csv("res://data/loc/en.csv").keys():
		ref[k] = true
	for lang in langs:
		var keys := Loc._read_csv("res://data/loc/%s.csv" % lang).keys()
		_check(keys.size() == ref.size(), "loc %s has %d keys == en %d" % [lang, keys.size(), ref.size()])
		for k in ref.keys():
			_check(keys.has(k), "loc %s missing key %s" % [lang, k])
	Loc.load("ja")
	_check(Loc.language == "ja" and Loc.t("menu_start") != "menu_start", "ja loads and translates")
	Loc.load("xx")
	_check(Loc.language == "en", "unknown language falls back to en")
	Loc.load("en")
	var meta := MetaSave.load_meta()
	var settings: Dictionary = meta.get("settings", {})
	settings["language"] = "de"
	settings["colorblind_symbols"] = true
	settings["reduced_motion"] = true
	meta["settings"] = settings
	MetaSave.save_meta(meta)
	var loaded := MetaSave.load_meta()
	_check(str(loaded["settings"]["language"]) == "de" and bool(loaded["settings"]["colorblind_symbols"]) and bool(loaded["settings"]["reduced_motion"]), "settings persist across save/load")


func _test_achievements() -> void:
	GameData.ensure_loaded()
	_check(GameData.achievements.size() == 25, "25 achievements load, got %d" % GameData.achievements.size())
	var meta := MetaSave.load_meta()
	meta["achievements"] = []
	meta["stats"] = {}
	_check(MetaSave.unlock_achievement(meta, "test_grant"), "first unlock grants")
	_check(not MetaSave.unlock_achievement(meta, "test_grant"), "achievement unlock is idempotent")
	var granted: Array = MetaSave.report_run(meta, {"victory": true, "difficulty": "normal", "fights_won": 15, "endless_depth": 2, "spins": 120, "coins": 600, "relics": 4, "floor": 3, "jackpots": 12, "perfect_fights": 3, "bet5_wins": 1, "cursed_relics": 0, "no_heal": false, "daily": false})
	_check(granted.has("first_victory"), "victory run grants first_victory")
	_check(granted.has("first_blood") and granted.has("endless_1") and granted.has("spins_100") and granted.has("coins_500"), "stat-threshold achievements granted")
	_check(int(meta["stats"]["victories"]) == 1 and int(meta["stats"]["runs"]) == 1, "stats accumulate runs/victories")
	var granted2: Array = MetaSave.report_run(meta, {"victory": true, "difficulty": "high_roller", "fights_won": 15, "endless_depth": 0, "spins": 60, "coins": 100, "relics": 2, "floor": 3, "jackpots": 0, "perfect_fights": 0, "bet5_wins": 0, "cursed_relics": 3, "no_heal": true, "daily": false})
	_check(granted2.has("high_roller_win") and granted2.has("cursed_relics_3") and granted2.has("no_heal_win"), "mode/cursed/no-heal achievements granted")
	_check(not granted2.has("first_victory"), "already-owned achievement not re-granted")


func _test_difficulty() -> void:
	GameData.ensure_loaded()
	var s := _fresh()
	_check(s.difficulty == "normal" and s.diff_hp == 1.0 and s.diff_atk == 1.0 and s.diff_reward == 1.0, "default mode normal, multipliers 1.0")
	var h := GameState.new()
	h.start_run(1, "high_roller")
	_check(h.difficulty == "high_roller", "high_roller mode accepted")
	_check(h.diff_hp == 1.10 and h.diff_atk == 1.10 and h.diff_reward == 1.5, "high_roller multipliers 1.10/1.10/1.5, got %s/%s/%s" % [str(h.diff_hp), str(h.diff_atk), str(h.diff_reward)])
	_check(h.enemy_hp == int(round(36 * 1.10)), "first fight hp 36 scaled to %d, got %d" % [int(round(36 * 1.10)), h.enemy_hp])
	var bad := GameState.new()
	bad.start_run(1, "nightmare")
	_check(bad.difficulty == "normal", "unknown mode falls back to normal")
	var n := GameState.new()
	n.start_run(1, "normal")
	_check(n.enemy_hp == 36, "normal mode first fight hp 36, got %d" % n.enemy_hp)
	n.fights_won = 3
	n.coins = 16
	_check(n.bone_coins_earned() == 3 * 2 + 2, "normal bone coins = 8, got %d" % n.bone_coins_earned())
	h.fights_won = 3
	h.coins = 16
	_check(h.bone_coins_earned() == int(round((3 * 2 + 2) * 1.5)), "high_roller bone coins = 12, got %d" % h.bone_coins_earned())


func _test_schema_versions() -> void:
	GameData.ensure_loaded()
	_check(int(GameData.config.get("schema_version", 0)) == 1, "config schema_version 1")
	_check(int(GameData.enemies.get("schema_version", 0)) == 1, "enemies schema_version 1")
	_check(int(GameData.fights[0].get("schema_version", 0)) == 1, "fights schema_version 1")
	_check(int(GameData.relics[0].get("schema_version", 0)) == 1, "relics schema_version 1")
	_check(int(GameData.unlocks[0].get("schema_version", 0)) == 1, "unlocks schema_version 1")


func _test_meta_save() -> void:
	var old_path := MetaSave.path
	MetaSave.path = "user://grave_spin_test.cfg"
	MetaSave.enabled = true
	var payload := {"bone_coins": 17, "best_fights": 4, "runs": 6, "best_victory": false}
	MetaSave.save_meta(payload)
	var loaded: Dictionary = MetaSave.load_meta()
	_check(int(loaded["bone_coins"]) == 17, "meta save persists bone coins")
	_check(int(loaded["best_fights"]) == 4, "meta save persists best fight")
	_check(int(loaded["runs"]) == 6, "meta save persists run count")
	var full_path := ProjectSettings.globalize_path(MetaSave.path)
	if FileAccess.file_exists(MetaSave.path):
		DirAccess.remove_absolute(full_path)
	MetaSave.path = old_path
