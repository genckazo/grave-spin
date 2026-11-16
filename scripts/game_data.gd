class_name GameData
extends RefCounted
## Loads the game's data files once. Everything that balances or extends the
## game lives in data/*.json so the full version can scale without code edits.

static var config: Dictionary = {}
static var relics: Array = []
static var enemies: Dictionary = {}
static var fights: Array = []

static func ensure_loaded() -> void:
	if not config.is_empty():
		return
	config = _read_json("res://data/config.json")
	var relic_data = _read_json("res://data/relics.json")
	relics = relic_data if relic_data is Array else []
	enemies = _read_json("res://data/enemies.json")
	var fight_data = _read_json("res://data/fights.json")
	fights = fight_data if fight_data is Array else []

static func _read_json(path: String) -> Variant:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Grave Spin: missing data file " + path)
		return null
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed == null:
		push_error("Grave Spin: invalid JSON in " + path)
	return parsed

static func relic_by_id(id: String) -> Dictionary:
	for r in relics:
		if String(r.get("id", "")) == id:
			return r
	return {}
