class_name MetaSave
extends RefCounted
## Bone Coins live between runs in the user folder.

static var path := "user://grave_spin_save.cfg"
static var enabled := true


static func load_meta() -> Dictionary:
	var defaults := {"bone_coins": 0, "best_fights": 0, "runs": 0, "best_victory": false, "unlocks": []}
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
