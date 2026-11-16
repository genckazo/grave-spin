class_name Loc
extends RefCounted
## Loads data/loc/<lang>.csv with English fallback. Languages at launch:
## EFIGS + JA/ZH (10+ post-launch) per FULL_RELEASE_SPEC decision 6.

static var language := "en"
static var strings: Dictionary = {}
static var loaded_lang := ""

static func languages() -> Array:
	return ["en", "es", "fr", "it", "de", "ja", "zh"]

static func load(lang: String) -> void:
	if lang == loaded_lang and not strings.is_empty():
		return
	language = lang if languages().has(lang) else "en"
	strings = _read_csv("res://data/loc/%s.csv" % language)
	if strings.is_empty():
		strings = _read_csv("res://data/loc/en.csv")
	loaded_lang = language

static func t(key: String) -> String:
	if strings.is_empty():
		load(language)
	return String(strings.get(key, key))

static func _read_csv(path: String) -> Dictionary:
	var out := {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_warning("Grave Spin: missing loc file " + path)
		return out
	f.get_line() # header
	while not f.eof_reached():
		var line := f.get_line()
		if line.is_empty():
			continue
		var parts := line.split(",", true, 1)
		if parts.size() == 2:
			out[parts[0]] = parts[1].trim_prefix('"').trim_suffix('"')
	return out
