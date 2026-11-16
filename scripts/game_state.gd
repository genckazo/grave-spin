class_name GameState
extends RefCounted
## All run and combat rules. The UI only reads this and plays animations, which
## keeps the balance simulation and the game on exactly the same code path.

const SYMBOLS := ["sword", "shield", "potion", "coin", "skull"]
const MAX_LOG := 40
const PITY_MAX := 5

var config: Dictionary = {}
var fights: Array = []
var enemies: Dictionary = {}
var relics: Array = []

var hp: int = 52
var max_hp: int = 52
var coins: int = 0
var block: int = 0
var bet: int = 1

var fight_index: int = 0
var fights_won: int = 0
var floor: int = 1
var enemy: Dictionary = {}
var enemy_hp: int = 0
var enemy_block: int = 0
var enemy_power: int = 0
var intent_index: int = 0

var spin_count: int = 0
var last_bet := 1
var pity := 0
var last_jackpot := false
var free_spin := false
var second_wind_used: bool = false
var run_over: bool = false
var victory: bool = false
var endless_depth: int = 0
var difficulty := "normal"
var diff_hp := 1.0
var diff_atk := 1.0
var diff_reward := 1.0

var rng := RandomNumberGenerator.new()
var logs: Array = []
var stats: Dictionary = {}


func start_run(seed_value: int = 0, mode := "normal") -> void:
	GameData.ensure_loaded()
	difficulty = mode if GameData.config.get("difficulty", {}).has(mode) else "normal"
	var diff: Dictionary = GameData.config["difficulty"][difficulty]
	diff_hp = float(diff.get("enemy_hp", 1.0))
	diff_atk = float(diff.get("enemy_atk", 1.0))
	diff_reward = float(diff.get("reward", 1.0))
	config = GameData.config
	fights = GameData.fights
	enemies = GameData.enemies
	max_hp = int(config["player_hp"])
	if MetaSave.enabled:
		max_hp += int(MetaSave.unlock_value(MetaSave.load_meta(), "max_hp"))
	hp = max_hp
	coins = 0
	block = 0
	relics = []
	if MetaSave.enabled:
		var start_relic := str(MetaSave.unlock_value(MetaSave.load_meta(), "start_relic"))
		if start_relic != "" and start_relic != "0":
			relics.append(start_relic)
	fight_index = 0
	fights_won = 0
	floor = 1
	spin_count = 0
	bet = 1
	last_bet = 1
	pity = 0
	last_jackpot = false
	free_spin = false
	second_wind_used = false
	run_over = false
	victory = false
	endless_depth = 0
	logs = []
	stats = {"spins": 0, "damage_dealt": 0, "damage_taken": 0, "healed": 0, "blocked": 0}
	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	_start_fight()


func _start_fight() -> void:
	var fight: Dictionary
	if fight_index < fights.size():
		fight = fights[fight_index]
	else:
		endless_depth = fight_index - fights.size() + 1
		fight = _endless_fight(endless_depth)
	floor = int(fight.get("floor", 1))
	var archetype: Dictionary = enemies[String(fight["type"])]
	enemy = {
		"name": String(fight["name"]),
		"type": String(fight["type"]),
		"label": String(archetype.get("label", fight["type"])),
		"sprite": String(archetype.get("sprite", "")),
		"skull_extra": int(archetype.get("skull_extra", 0)),
		"blurb": String(archetype.get("blurb", "")),
		"curse": String(archetype.get("curse", "")),
		"intents": fight["intents"],
		"intro": String(fight.get("intro", "")),
		"floor": int(fight.get("floor", 1)),
		"boss": bool(fight.get("boss", false)),
	}
	enemy_hp = int(round(int(fight["hp"]) * diff_hp))
	enemy_block = 0
	enemy_power = 0
	intent_index = 0
	block = RelicEngine.total(self, "start_block")
	_log(String(enemy["intro"]), "muted")
	_log("Pull the lever. Survive the reels.", "gold")


func bet_min() -> int:
	return int(config.get("bet_min", 1)) if not config.is_empty() else 1


func bet_max() -> int:
	return int(config.get("bet_max", 5)) if not config.is_empty() else 5


func set_bet(value: int) -> bool:
	if value < bet_min() or value > bet_max():
		return false
	bet = value
	return true


func get_intent() -> Dictionary:
	var intents: Array = enemy["intents"]
	var raw: Dictionary = intents[intent_index % intents.size()]
	var kind := String(raw["type"])
	var value := int(raw["value"])
	if kind == "attack" or kind == "heavy":
		value += enemy_power
	var penalty := maxi(0, int(config["values"]["skull"]) - RelicEngine.total(self, "skull_reduction") - RelicEngine.synergy_bonus(self, "skull"))
	var title := ""
	var sub := ""
	match kind:
		"attack":
			title = "ATTACK %d" % value
			sub = "Skulls add +%d each" % penalty
		"heavy":
			title = "HEAVY %d" % value
			sub = "Skulls add +%d each" % penalty
		"defend":
			title = "GUARD %d" % value
			sub = "It braces for your next pull"
		"buff":
			title = "EMPOWER +%d" % value
			sub = "Its attacks grow stronger"
	return {"type": kind, "value": value, "title": title, "sub": sub, "penalty": penalty}


func roll() -> Dictionary:
	spin_count += 1
	var free := free_spin
	free_spin = false
	last_jackpot = false
	last_bet = clamp(bet, 1, maxi(1, coins))
	if not free:
		coins = maxi(0, coins - last_bet)
	var weights: Dictionary = (config["weights"] as Dictionary).duplicate()
	weights["skull"] = int(weights.get("skull", 0)) + int(enemy.get("skull_extra", 0))
	var grid: Array = []
	for r in range(3):
		var row: Array = []
		for c in range(3):
			row.append(_pick_symbol(weights))
		grid.append(row)

	var rigged := false
	var seventh := RelicEngine.total(self, "lucky_seventh")
	if seventh > 0 and spin_count % seventh == 0:
		var cells: Array = []
		for r in range(3):
			for c in range(3):
				cells.append([r, c])
		_shuffle(cells)
		var need: int = max(2, int(_relic_value("lucky_seventh", "value2", 2)))
		for i in range(min(need, cells.size())):
			grid[int(cells[i][0])][int(cells[i][1])] = "sword"
		rigged = true
		_log("Lucky Seventh: the reels are rigged to swords.", "good")

	var near_miss := -1
	if not rigged:
		for r in range(3):
			if grid[r][0] == "sword" and grid[r][1] == "sword" and grid[r][2] != "sword":
				near_miss = r
	var jackpot := _apply_pity(grid, near_miss)
	if jackpot:
		last_jackpot = true
		free_spin = true
		_log("JACKPOT! The pity timer pays out — free re-spin.", "gold")
	return {"grid": grid, "near_miss": near_miss, "jackpot": jackpot, "rigged": rigged}


func _apply_pity(grid: Array, near_row: int) -> bool:
	if near_row < 0:
		return false
	pity += 1
	if pity >= PITY_MAX:
		grid[near_row] = ["sword", "sword", "sword"]
		pity = 0
		return true
	return false


func resolve(grid: Array) -> Dictionary:
	if run_over:
		return {}
	stats["spins"] += 1
	var values: Dictionary = config["values"]
	var sword_bonus := RelicEngine.total(self, "sword_bonus")
	var block_bonus := RelicEngine.total(self, "block_bonus")
	var heal_bonus := RelicEngine.total(self, "heal_bonus")
	var coin_bonus := RelicEngine.total(self, "coin_bonus")
	var skull_damage := RelicEngine.total(self, "skull_damage")
	var triple_bonus := RelicEngine.total(self, "triple_sword_bonus")
	var blood_coin := RelicEngine.total(self, "blood_coin")
	var all_bonus := RelicEngine.total(self, "all_bonus")
	sword_bonus += all_bonus
	block_bonus += all_bonus
	heal_bonus += all_bonus
	coin_bonus += all_bonus
	sword_bonus += RelicEngine.synergy_bonus(self, "sword")
	coin_bonus += RelicEngine.synergy_bonus(self, "coin")

	var report := {
		"rows": [],
		"damage": 0,
		"block": 0,
		"heal": 0,
		"coins": 0,
		"skulls": 0,
		"skull_penalty": 0,
		"damage_taken": 0,
		"enemy_dead": false,
		"player_dead": false,
		"enemy_action": "",
		"intent": get_intent(),
		"second_wind": false,
	}

	var total_skulls := 0
	for r in range(3):
		if enemy_hp <= 0:
			break
		var row: Array = grid[r]
		var sw := 0
		var sh := 0
		var po := 0
		var co := 0
		var sk := 0
		for sym in row:
			match String(sym):
				"sword": sw += 1
				"shield": sh += 1
				"potion": po += 1
				"coin": co += 1
				"skull": sk += 1

		var dmg := sw * (int(values["sword"]) + sword_bonus) * last_bet
		if last_jackpot and sw == 3:
			dmg *= 2
			_log("Jackpot: the payline pays double.", "gold")
		if sw == 3 and triple_bonus > 0:
			dmg += triple_bonus * last_bet
			_log("Dead Man's Hand: three swords. +%d." % (triple_bonus * last_bet), "cursed")
		if skull_damage > 0 and sk > 0:
			dmg += sk * skull_damage

		var absorbed := mini(enemy_block, dmg)
		enemy_block -= absorbed
		var applied := dmg - absorbed
		enemy_hp = max(0, enemy_hp - applied)
		report["damage"] += applied
		stats["damage_dealt"] += applied

		var heal_amount := po * (int(values["potion"]) + heal_bonus)
		var before_hp := hp
		hp = min(max_hp, hp + heal_amount)
		var healed := hp - before_hp
		report["heal"] += healed
		stats["healed"] += healed

		var coin_gain := co * (int(values["coin"]) + coin_bonus) * last_bet
		coins += coin_gain
		report["coins"] += coin_gain

		var block_gain := sh * (int(values["shield"]) + block_bonus)
		block += block_gain
		report["block"] += block_gain

		total_skulls += sk
		report["skulls"] += sk

		var bits: Array = []
		if sw > 0:
			bits.append("%d sword%s" % [sw, "" if sw == 1 else "s"])
		if sh > 0:
			bits.append("%d shield%s" % [sh, "" if sh == 1 else "s"])
		if po > 0:
			bits.append("%d potion%s" % [po, "" if po == 1 else "s"])
		if co > 0:
			bits.append("%d coin%s" % [co, "" if co == 1 else "s"])
		if sk > 0:
			bits.append("%d skull%s" % [sk, "" if sk == 1 else "s"])
		if not bits.is_empty():
			_log("Payline %d: %s." % [r + 1, ", ".join(bits)], "bone")
		if applied > 0:
			_log("  %d damage to %s." % [applied, enemy["name"]], "gold")
		if absorbed > 0:
			_log("  %d absorbed by its guard." % absorbed, "muted")

		report["rows"].append({
			"row": r,
			"swords": sw, "shields": sh, "potions": po, "coins": co, "skulls": sk,
			"damage": applied, "absorbed": absorbed, "block": block_gain,
			"heal": healed, "coins_gain": coin_gain,
		})

	enemy_block = 0

	if enemy_hp <= 0:
		report["enemy_dead"] = true
		_log("%s falls. The machine pays out." % enemy["name"], "good")
		return report

	var intent := get_intent()
	report["intent"] = intent
	var penalty := maxi(0, int(values["skull"]) - RelicEngine.total(self, "skull_reduction") - RelicEngine.synergy_bonus(self, "skull")) * last_bet
	report["skull_penalty"] = penalty

	var skull_count := total_skulls
	if RelicEngine.has_effect(self, "first_skull_free"):
		skull_count = maxi(0, total_skulls - 1)

	match String(intent["type"]):
		"attack", "heavy":
			var incoming := int(round(int(intent["value"]) * diff_atk)) + skull_count * penalty
			var blocked := mini(block, incoming)
			var taken := incoming - blocked
			hp -= taken
			report["damage_taken"] = taken
			stats["damage_taken"] += taken
			stats["blocked"] += blocked
			if total_skulls > 0:
				_log("Skulls bite: +%d incoming." % (skull_count * penalty), "cursed")
			if blocked > 0:
				_log("%d blocked. %d gets through." % [blocked, taken], "blue")
			else:
				_log("%s hits for %d." % [enemy["name"], taken], "red")
			if blood_coin > 0 and taken > 0:
				coins += taken * blood_coin
				report["coins"] += taken * blood_coin
				_log("Bloodstone: +%d coins." % (taken * blood_coin), "gold")
			if hp <= 0:
				var wind := RelicEngine.total(self, "second_wind")
				if wind > 0 and not second_wind_used:
					second_wind_used = true
					hp = wind
					report["second_wind"] = true
					_log("SECOND WIND. You claw back with %d HP." % wind, "good")
				else:
					hp = 0
					report["player_dead"] = true
					run_over = true
					_log("The machine takes you.", "red")
		"defend":
			enemy_block += int(intent["value"])
			report["enemy_action"] = "defend"
			_log("%s guards (+%d)." % [enemy["name"], int(intent["value"])], "blue")
		"buff":
			enemy_power += int(intent["value"])
			report["enemy_action"] = "buff"
			_log("%s empowers itself (+%d attack)." % [enemy["name"], int(intent["value"])], "cursed")

	intent_index += 1
	block = 0
	return report


func on_enemy_defeated() -> String:
	fights_won += 1
	if fight_index >= fights.size() - 1:
		victory = true
		if _endless_enabled():
			_log("The Hollow King falls. Below, something else wakes.", "gold")
			return "endless"
		run_over = true
		return "victory"
	hp = min(max_hp, hp + int(config["heal_between_fights"]))
	_log("You bind your wounds (+%d HP)." % int(config["heal_between_fights"]), "good")
	var kill_heal := RelicEngine.total(self, "kill_heal")
	if kill_heal > 0:
		hp = min(max_hp, hp + kill_heal)
		_log("Vampiric Edge: +%d HP." % kill_heal, "good")
	return "draft"


func begin_next_fight() -> void:
	fight_index += 1
	_start_fight()


func _endless_enabled() -> bool:
	return not config.is_empty() and bool(config.get("endless", false))


func _endless_fight(depth: int) -> Dictionary:
	var names := ["Endless Echo", "The Deep Hungers", "What Walks Below"]
	var types := ["skeleton", "slime", "cultist"]
	var scale := mini(6, (depth - 1) / 2)
	return {
		"name": names[(depth - 1) % names.size()],
		"type": types[(depth - 1) % types.size()],
		"floor": 3 + depth,
		"hp": 88 + 14 * depth,
		"intents": [
			{"type": "attack", "value": 12 + scale},
			{"type": "attack", "value": 12 + scale},
			{"type": "heavy", "value": 19 + scale},
		],
		"intro": "The dark below does not end.",
	}


func draft_options() -> Array:
	var cap := int(config["max_relics"]) + RelicEngine.total(self, "max_relics_bonus")
	if relics.size() >= cap:
		return []
	var owned := relic_ids()
	var pool: Array = []
	for r in GameData.relics:
		if not owned.has(String(r["id"])):
			pool.append(r)
	_shuffle(pool)
	return pool.slice(0, min(3, pool.size()))


func choose_relic(relic: Dictionary) -> void:
	if relic.is_empty():
		return
	relics.append(relic)
	var hp_cost := int(relic.get("value2", 0))
	if String(relic.get("rarity", "")) == "cursed" and hp_cost > 0:
		max_hp = max(20, max_hp - hp_cost)
		hp = min(hp, max_hp)


func relic_ids() -> Array:
	var ids: Array = []
	for r in relics:
		ids.append(String(r["id"]))
	return ids


func has_relic(id: String) -> bool:
	return relic_ids().has(id)


func bone_coins_earned() -> int:
	var per_fight := int(config["bone_coins_per_fight"])
	var per_coin := maxi(1, int(config["coins_per_bone"]))
	return int(round((fights_won * per_fight + int(floor(float(coins) / float(per_coin)))) * diff_reward))


func summary() -> Dictionary:
	return {
		"fights_won": fights_won,
		"fights_total": fights.size(),
		"floor": floor,
		"spins": int(stats.get("spins", 0)),
		"coins": coins,
		"relics": relics.size(),
		"damage_dealt": int(stats.get("damage_dealt", 0)),
		"damage_taken": int(stats.get("damage_taken", 0)),
		"victory": victory,
		"endless_depth": endless_depth,
		"bone_coins": bone_coins_earned(),
		"seed": int(rng.seed),
	}


func _pick_symbol(weights: Dictionary) -> String:
	var total := 0
	for s in SYMBOLS:
		total += int(weights.get(s, 0))
	if total <= 0:
		return "skull"
	var x := rng.randi_range(1, total)
	for s in SYMBOLS:
		x -= int(weights.get(s, 0))
		if x <= 0:
			return s
	return "skull"


func _relic_value(effect: String, field: String, fallback: int) -> int:
	for r in relics:
		if String(r.get("effect", "")) == effect:
			return int(r.get(field, fallback))
	return fallback


func _shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


func _log(text: String, kind: String = "bone") -> void:
	logs.append({"text": text, "kind": kind})
	if logs.size() > MAX_LOG:
		logs.pop_front()
