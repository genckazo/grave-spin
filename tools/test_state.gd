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
	_check(GameData.relics.size() == 20, "20 relics load from data/relics.json")
	var counts := {"common": 0, "rare": 0, "cursed": 0}
	for r in GameData.relics:
		counts[String(r["rarity"])] = int(counts.get(String(r["rarity"]), 0)) + 1
	_check(int(counts["common"]) == 10 and int(counts["rare"]) == 7 and int(counts["cursed"]) == 3, "relic rarity split 10 common / 7 rare / 3 cursed")
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
	_check(String(GameData.fights[9]["name"]) == "The Grave Warden" and int(GameData.fights[9]["hp"]) == 70 and bool(GameData.fights[9]["boss"]), "Grave Warden is the floor-2 boss at hp 70")
	_check(String(GameData.fights[14]["name"]) == "The Hollow King" and int(GameData.fights[14]["hp"]) == 54 and int(GameData.fights[14]["floor"]) == 3 and bool(GameData.fights[14]["boss"]), "The Hollow King is the floor-3 final boss at hp 54")
	_check(GameData.enemies.size() == 3, "3 enemy archetypes load")
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
	_check(int(vamp.hp) == 42, "Vampiric Edge: kill heals 1 on top of the 11 between-fight heal (30->42)")

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
	_check(next.hp == 41, "an early win heals 11 between fights")
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
