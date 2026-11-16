extends SceneTree
## Headless rules checks for the demo slice. Run:
##   Godot --headless --path . -s res://tools/test_state.gd

var failures := 0


func _init() -> void:
	GameData.ensure_loaded()
	_test_data()
	_test_combat()
	_test_relics()
	_test_flow()
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
	_check(GameData.relics.size() == 12, "12 relics load from data/relics.json")
	_check(GameData.fights.size() == 10, "10 fights load from data/fights.json (floors 1-2)")
	_check(GameData.enemies.size() == 3, "3 enemy archetypes load")
	var floors_ok := true
	var bosses := 0
	for f in GameData.fights:
		if not f.has("floor") or int(f["floor"]) < 1 or int(f["floor"]) > 2:
			floors_ok = false
		if not f.has("hp") or not (f["intents"] is Array) or (f["intents"] as Array).size() != 3:
			floors_ok = false
		if not GameData.enemies.has(String(f["type"])):
			floors_ok = false
		if bool(f.get("boss", false)):
			bosses += 1
	_check(floors_ok, "every fight has floor 1-2, hp, 3 intents, valid enemy type")
	_check(bosses == 2, "two floor bosses (floor 1 + floor 2)")
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
	_check(outcome == "victory" and win.victory, "killing fight ten returns victory")

	var next := _fresh()
	next.enemy_hp = 1
	next.hp = 30
	next.resolve(_grid("sword"))
	var next_outcome: String = next.on_enemy_defeated()
	_check(next_outcome == "draft", "an early win returns draft")
	_check(next.hp == 38, "an early win heals 8 between fights")
	_check(next.fights_won == 1, "fights_won increments")

	var bones := _fresh()
	bones.fights_won = 3
	bones.coins = 20
	_check(bones.bone_coins_earned() == 8, "bone coins = fights*2 + coins/8")


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
