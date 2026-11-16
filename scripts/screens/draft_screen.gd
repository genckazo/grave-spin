class_name DraftScreen
extends Control
## Three relics face up. One comes with you.

const CARD_W := 160
const CARD_H := 210
const CARD_Y := 92
const CARD_X := [48, 240, 432]

var main
var state: GameState
var screen_id := "draft"

var options: Array = []
var cards: Array = []
var chosen := false
var flash: ColorRect


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	screen_id = "draft"
	options = state.draft_options()

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.015, 0.03, 0.52)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var kicker := UI.label("FIGHT %d CLEARED  ·  THE MACHINE PAYS OUT" % state.fights_won, 7, UI.GOLD, "header")
	kicker.position = Vector2(16, 10)
	kicker.size = Vector2(430, 10)
	add_child(kicker)

	var title := UI.shadowed(UI.label("CHOOSE A RELIC", 32, UI.GOLD, "title"))
	title.position = Vector2(16, 20)
	title.size = Vector2(470, 42)
	add_child(title)

	var sub := UI.label("Take one. The other two stay in the dark.", 8, UI.MUTED, "body")
	sub.position = Vector2(17, 62)
	sub.size = Vector2(420, 14)
	add_child(sub)

	var hp := UI.label("HP  %d / %d" % [state.hp, state.max_hp], 8, UI.BONE, "header")
	hp.position = Vector2(430, 12)
	hp.size = Vector2(194, 12)
	hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(hp)

	var coins := UI.label("COINS  %d" % state.coins, 8, UI.GOLD, "header")
	coins.position = Vector2(430, 28)
	coins.size = Vector2(194, 12)
	coins.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(coins)

	UI.separator(self, 16, 82, 608)

	for i in range(options.size()):
		_build_card(i, options[i])

	_build_footer()

	if not cards.is_empty():
		cards[0]["button"].grab_focus()




func _build_card(index: int, relic: Dictionary) -> void:
	var x: float = CARD_X[index]
	var root := Control.new()
	root.position = Vector2(x, CARD_Y)
	root.size = Vector2(CARD_W, CARD_H)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var shadow := ColorRect.new()
	shadow.position = Vector2(5, 7)
	shadow.size = Vector2(CARD_W, CARD_H)
	shadow.color = Color(0.0, 0.0, 0.0, 0.46)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shadow)

	var panel := UI.panel("res://assets/generated/ui_card.png", 0)
	panel.position = Vector2.ZERO
	panel.size = Vector2(CARD_W, CARD_H)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(panel)

	var rarity := String(relic.get("rarity", "common"))
	var rarity_col := UI.rarity_color(rarity)

	var icon := UI.icon("res://assets/generated/" + String(relic["icon"]), 48)
	icon.position = Vector2(56, 14)
	panel.add_child(icon)

	var title_label := UI.centered(UI.shadowed(UI.label(String(relic["name"]), 8, UI.GOLD, "header")))
	title_label.position = Vector2(8, 69)
	title_label.size = Vector2(CARD_W - 16, 14)
	title_label.clip_text = true
	panel.add_child(title_label)

	var rarity_label := UI.centered(UI.label(rarity.to_upper(), 6, rarity_col, "header"))
	rarity_label.position = Vector2(8, 84)
	rarity_label.size = Vector2(CARD_W - 16, 10)
	panel.add_child(rarity_label)

	var desc := UI.label(String(relic["desc"]), 9, UI.BONE, "body")
	desc.name = "Desc"
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_constant_override("line_spacing", 1)
	desc.position = Vector2(14, 103)
	desc.size = Vector2(CARD_W - 28, 52)
	panel.add_child(desc)

	var flavor := UI.label(String(relic.get("flavor", "")), 7, UI.MUTED, "body")
	flavor.name = "Flavor"
	flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	flavor.add_theme_constant_override("line_spacing", 1)
	flavor.position = Vector2(14, 156)
	flavor.size = Vector2(CARD_W - 28, 30)
	panel.add_child(flavor)

	var footer := UI.centered(UI.label("%d   ·   CLICK TO TAKE" % (index + 1), 6, UI.MUTED, "header"))
	footer.position = Vector2(8, 189)
	footer.size = Vector2(CARD_W - 16, 10)
	panel.add_child(footer)

	var strip := ColorRect.new()
	strip.position = Vector2(10, 205)
	strip.size = Vector2(CARD_W - 20, 2)
	strip.color = Color(rarity_col.r, rarity_col.g, rarity_col.b, 0.7)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(strip)

	var button := Button.new()
	button.position = Vector2.ZERO
	button.size = Vector2(CARD_W, CARD_H)
	button.text = ""
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.tooltip_text = "%s\n%s" % [String(relic["desc"]), String(relic.get("flavor", ""))]
	var empty := StyleBoxEmpty.new()
	for state_name in ["normal", "hover", "pressed", "disabled"]:
		button.add_theme_stylebox_override(state_name, empty)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color(0, 0, 0, 0)
	focus.border_color = UI.GOLD_HI
	focus.border_width_left = 2
	focus.border_width_right = 2
	focus.border_width_top = 2
	focus.border_width_bottom = 2
	button.add_theme_stylebox_override("focus", focus)
	button.pressed.connect(_on_card_pressed.bind(index))
	button.mouse_entered.connect(_lift.bind(index, true))
	button.mouse_exited.connect(_lift.bind(index, false))
	button.focus_entered.connect(_lift.bind(index, true))
	button.focus_exited.connect(_lift.bind(index, false))
	root.add_child(button)

	cards.append({
		"root": root,
		"panel": panel,
		"button": button,
		"base_y": float(CARD_Y),
		"tween": null,
	})


func _build_footer() -> void:
	var label := UI.label("YOUR RELICS", 6, UI.MUTED, "header")
	label.position = Vector2(16, 321)
	label.size = Vector2(80, 10)
	add_child(label)

	if state.relics.is_empty():
		var none := UI.label("NONE YET", 6, UI.MUTED, "header")
		none.position = Vector2(96, 321)
		none.size = Vector2(160, 10)
		add_child(none)
	else:
		for i in range(state.relics.size()):
			var relic: Dictionary = state.relics[i]
			var icon := UI.icon("res://assets/generated/" + String(relic["icon"]), 18)
			icon.position = Vector2(96 + i * 22, 316)
			icon.mouse_filter = Control.MOUSE_FILTER_PASS
			icon.tooltip_text = "%s — %s" % [String(relic["name"]), String(relic["desc"])]
			add_child(icon)

	var hint := UI.label("1  ·  2  ·  3    OR CLICK", 6, UI.MUTED, "header")
	hint.position = Vector2(380, 321)
	hint.size = Vector2(244, 10)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(hint)


func _lift(index: int, up: bool) -> void:
	if chosen or index < 0 or index >= cards.size():
		return
	var card: Dictionary = cards[index]
	var tw: Tween = card["tween"]
	if tw != null and tw.is_valid():
		tw.kill()
	var target_y: float = float(card["base_y"]) - (8.0 if up else 0.0)
	tw = create_tween()
	tw.tween_property(card["root"], "position:y", target_y, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	card["tween"] = tw
	var panel: Panel = card["panel"]
	panel.modulate = Color(1.14, 1.08, 1.0) if up else Color.WHITE


func _on_card_pressed(index: int) -> void:
	_choose(index)


func debug_pick(index: int) -> void:
	_choose(index)


func _choose(index: int) -> void:
	if chosen or index < 0 or index >= options.size():
		return
	chosen = true
	Sfx.play("card", 1.0, -2.0)
	for card in cards:
		var b: Button = card["button"]
		b.disabled = true
		if b.has_focus():
			b.release_focus()

	var relic: Dictionary = options[index]
	if main.fast:
		main.on_relic_chosen(relic)
		return

	for i in range(cards.size()):
		var card: Dictionary = cards[i]
		if i == index:
			var root: Control = card["root"]
			root.pivot_offset = Vector2(CARD_W, CARD_H) * 0.5
			var tw := create_tween()
			tw.set_parallel(true)
			tw.tween_property(root, "scale", Vector2(1.04, 1.04), 0.2)
			tw.tween_property(root, "position:y", CARD_Y - 12.0, 0.2)
		else:
			var tw2 := create_tween()
			tw2.tween_property(card["root"], "modulate:a", 0.15, 0.2)

	flash = ColorRect.new()
	flash.color = Color(0.95, 0.76, 0.3, 0.0)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	var ftw := create_tween()
	ftw.tween_property(flash, "color:a", 0.13, 0.08)
	ftw.tween_property(flash, "color:a", 0.0, 0.24)

	await get_tree().create_timer(0.36).timeout
	if is_inside_tree():
		main.on_relic_chosen(relic)


func _unhandled_key_input(event: InputEvent) -> void:
	if chosen or not (event is InputEventKey) or not event.is_pressed() or event.is_echo():
		return
	var key := (event as InputEventKey).keycode
	match key:
		KEY_1, KEY_KP_1:
			_choose(0)
		KEY_2, KEY_KP_2:
			_choose(1)
		KEY_3, KEY_KP_3:
			_choose(2)
		KEY_LEFT, KEY_RIGHT:
			_move_focus(-1 if key == KEY_LEFT else 1)
		_:
			return
	get_viewport().set_input_as_handled()


func _move_focus(direction: int) -> void:
	if cards.is_empty():
		return
	var focus_owner := get_viewport().gui_get_focus_owner()
	var current := 0
	for i in range(cards.size()):
		if cards[i]["button"] == focus_owner:
			current = i
	var next := (current + direction + cards.size()) % cards.size()
	cards[next]["button"].grab_focus()
