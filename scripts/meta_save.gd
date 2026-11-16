class_name MetaSave
extends RefCounted
## Bone Coins live between runs in the user folder.

static var path := "user://grave_spin_save.cfg"
static var enabled := true


static func load_meta() -> Dictionary:
	var defaults := {"bone_coins": 0, "best_fights": 0, "runs": 0, "best_victory": false, "unlocks": [], "achievements": [], "stats": {}, "tutorial_done": false, "settings": {"language": "en", "colorblind_symbols": false, "reduced_motion": false}}
	if not enabled:
		return defaults
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return defaults
	return {
		"bone_coins": int(cfg.get_value("meta", "bone_coins", 0)),
		"best_fights": int(cfg.get_value("meta", "best_fights", 0)),
		"runs": int(cfg.get_value("meta", "runs", 0)),
		"best_victory": bool(cfg.get_value("meta", "best_victory", false)),
		"unlocks": cfg.get_value("meta", "unlocks", []),
		"achievements": cfg.get_value("meta", "achievements", []),
		"stats": cfg.get_value("meta", "stats", {}),
		"tutorial_done": bool(cfg.get_value("meta", "tutorial_done", false)),
		"settings": cfg.get_value("meta", "settings", {"language": "en", "colorblind_symbols": false, "reduced_motion": false}),
	}


static func save_meta(meta: Dictionary) -> void:
	if not enabled:
		return
	var cfg := ConfigFile.new()
	for key in meta.keys():
		cfg.set_value("meta", String(key), meta[key])
	cfg.save(path)

static func buy_unlock(meta: Dictionary, id: String) -> bool:
	var node := GameData.unlock_by_id(id)
	if node.is_empty():
		return false
	var owned: Array = meta.get("unlocks", [])
	if owned.has(id):
		return false
	for req in node.get("requires", []):
		if not owned.has(req):
			return false
	if int(meta.get("bone_coins", 0)) < int(node.get("cost", 0)):
		return false
	meta["bone_coins"] = int(meta.get("bone_coins", 0)) - int(node.get("cost", 0))
	owned.append(id)
	meta["unlocks"] = owned
	return true


static func unlock_value(meta: Dictionary, effect: String) -> Variant:
	var total := 0
	var found := false
	for id in meta.get("unlocks", []):
		var node := GameData.unlock_by_id(str(id))
		if str(node.get("effect", "")) == effect:
			var v = node.get("value")
			if v is String:
				return v
			total += int(v)
			found = true
	if found:
		return total
	return 0

static func unlock_achievement(meta: Dictionary, id: String) -> bool:
	var owned: Array = meta.get("achievements", [])
	if owned.has(id):
		return false
	owned.append(id)
	meta["achievements"] = owned
	return true


static func report_run(meta: Dictionary, run: Dictionary) -> Array:
	GameData.ensure_loaded()
	var stats: Dictionary = meta.get("stats", {})
	stats["runs"] = int(stats.get("runs", 0)) + 1
	if bool(run.get("victory", false)):
		stats["victories"] = int(stats.get("victories", 0)) + 1
		if str(run.get("difficulty", "normal")) == "high_roller":
			stats["hr_victories"] = int(stats.get("hr_victories", 0)) + 1
	stats["best_fights"] = maxi(int(stats.get("best_fights", 0)), int(run.get("fights_won", 0)))
	stats["best_endless"] = maxi(int(stats.get("best_endless", 0)), int(run.get("endless_depth", 0)))
	stats["best_spins"] = maxi(int(stats.get("best_spins", 0)), int(run.get("spins", 0)))
	stats["best_coins"] = maxi(int(stats.get("best_coins", 0)), int(run.get("coins", 0)))
	stats["best_relics"] = maxi(int(stats.get("best_relics", 0)), int(run.get("relics", 0)))
	stats["best_floor"] = maxi(int(stats.get("best_floor", 0)), int(run.get("floor", 1)))
	stats["jackpots"] = int(stats.get("jackpots", 0)) + int(run.get("jackpots", 0))
	stats["perfect_fights"] = int(stats.get("perfect_fights", 0)) + int(run.get("perfect_fights", 0))
	stats["bet5_wins"] = int(stats.get("bet5_wins", 0)) + int(run.get("bet5_wins", 0))
	stats["cursed_win"] = maxi(int(stats.get("cursed_win", 0)), int(run.get("cursed_relics", 0)) if bool(run.get("victory", false)) else 0)
	stats["no_heal_wins"] = int(stats.get("no_heal_wins", 0)) + (1 if bool(run.get("victory", false)) and bool(run.get("no_heal", false)) else 0)
	stats["dailies"] = int(stats.get("dailies", 0)) + (1 if bool(run.get("daily", false)) else 0)
	stats["unlocks"] = int(meta.get("unlocks", []).size())
	meta["stats"] = stats
	meta["best_victory"] = meta.get("best_victory", false) or bool(run.get("victory", false))
	var granted := []
	for a in GameData.achievements:
		if not meta["achievements"].has(a["id"]) and int(stats.get(a["stat"], 0)) >= int(a["threshold"]):
			unlock_achievement(meta, a["id"])
			granted.append(a["id"])
	return granted
