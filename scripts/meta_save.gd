class_name MetaSave
extends RefCounted
## Bone Coins live between runs in the user folder.

static var path := "user://grave_spin_save.cfg"
static var enabled := true


static func load_meta() -> Dictionary:
	var defaults := {"bone_coins": 0, "best_fights": 0, "runs": 0, "best_victory": false}
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
	}


static func save_meta(meta: Dictionary) -> void:
	if not enabled:
		return
	var cfg := ConfigFile.new()
	for key in meta.keys():
		cfg.set_value("meta", String(key), meta[key])
	cfg.save(path)
