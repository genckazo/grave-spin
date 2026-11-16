class_name ShopScreen
extends Control
## The shop between boss fights. Relics, consumables, one permanent upgrade,
## and a reroll button whose price climbs per visit.

var main
var state: GameState
var screen_id := "shop"

var item_buttons: Array = []
var reroll_button: Button
var coin_label: Label
var interest_label: Label
var done := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	screen_id = "shop"

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.015, 0.03, 0.52)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var kicker := UI.label("BOSS FELLED  ·  THE HOUSE SELLS", 7, UI.GOLD, "header")
	kicker.position = Vector2(16, 10)
	kicker.size = Vector2(430, 10)
	add_child(kicker)

	var title := UI.shadowed(UI.label("THE SHOP", 32, UI.GOLD, "title"))
	title.position = Vector2(16, 20)
	title.size = Vector2(470, 42)
	add_child(title)

	coin_label = UI.label("COINS  %d" % state.coins, 8, UI.GOLD, "header")
	coin_label.position = Vector2(430, 12)
	coin_label.size = Vector2(194, 12)
	coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(coin_label)

	interest_label = UI.label("", 7, UI.MUTED, "body")
	interest_label.position = Vector2(430, 28)
	interest_label.size = Vector2(194, 10)
	interest_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(interest_label)

	UI.separator(self, 16, 82, 608)

	_build_items()
	_build_footer()


func _item_tooltip(item: Dictionary) -> String:
	var kind := String(item.get("kind", ""))
	if kind == "relic":
		var tt := GameData.tooltip("relic:" + String(item["id"]))
		if not tt.is_empty():
			return "%s\n%s" % [String(tt.get("name", item["name"])), String(tt.get("text", item["desc"]))]
		return "%s — %s" % [String(item["name"]), String(item["desc"])]
	if kind == "consumable":
		var tt := GameData.tooltip("consumable:" + String(item["id"]))
		if not tt.is_empty():
			return "%s\n%s" % [String(tt.get("name", item["name"])), String(tt.get("text", item["desc"]))]
		return "%s — %s" % [String(item["name"]), String(item["desc"])]
	return "%s — %s" % [String(item["name"]), String(item.get("desc", ""))]


func _build_items() -> void:
	for b in item_buttons:
		b.queue_free()
	item_buttons.clear()
	var items: Array = state.shop_stock
	var n := items.size()
	if n == 0:
		var none := UI.label("SOLD OUT", 8, UI.MUTED, "body")
		none.position = Vector2(16, 120)
		none.size = Vector2(300, 12)
		add_child(none)
		return
	var card_w := 96.0
	var gap := 8.0
	var total_w := n * card_w + (n - 1) * gap
	var x0 := (640.0 - total_w) / 2.0
	for i in range(n):
		var item: Dictionary = items[i]
		var x := x0 + i * (card_w + gap)
		var panel := UI.panel()
		panel.position = Vector2(x, 96)
		panel.size = Vector2(card_w, 168)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(panel)

		var icon_name := "potion_icon.png"
		if String(item.get("kind", "")) == "relic" and item.get("icon", "") != "":
			icon_name = String(item["icon"])
		var icon := UI.icon("res://assets/generated/" + icon_name, 40)
		icon.position = Vector2((card_w - 40) / 2.0, 10)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(icon)

		var name_label := UI.centered(UI.label(String(item["name"]), 7, UI.GOLD, "header"))
		name_label.position = Vector2(4, 56)
		name_label.size = Vector2(card_w - 8, 20)
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.clip_text = true
		panel.add_child(name_label)

		var kind_label := UI.centered(UI.label(String(item.get("kind", "")).to_upper(), 6, UI.DIM, "header"))
		kind_label.position = Vector2(4, 76)
		kind_label.size = Vector2(card_w - 8, 10)
		panel.add_child(kind_label)

		var price_label := UI.centered(UI.shadowed(UI.label("%d COINS" % int(item.get("price", 0)), 8, UI.GOLD_HI, "header")))
		price_label.position = Vector2(4, 96)
		price_label.size = Vector2(card_w - 8, 12)
		panel.add_child(price_label)

		var desc := UI.label(String(item.get("desc", "")), 6, UI.BONE, "body")
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.add_theme_constant_override("line_spacing", 1)
		desc.position = Vector2(6, 112)
		desc.size = Vector2(card_w - 12, 52)
		panel.add_child(desc)

		var button := Button.new()
		button.position = Vector2(x, 96)
		button.size = Vector2(card_w, 168)
		button.flat = true
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.tooltip_text = _item_tooltip(item)
		button.pressed.connect(_on_buy.bind(i))
		add_child(button)
		item_buttons.append(button)


func _build_footer() -> void:
	reroll_button = UI.button("REROLL  (%d)" % state.shop_reroll_cost(), 9, 150, 30)
	reroll_button.position = Vector2(150, 286)
	reroll_button.tooltip_text = "Reroll the shop stock. Costs more each time this visit; resets next shop."
	reroll_button.pressed.connect(_on_reroll)
	add_child(reroll_button)

	var leave := UI.button("CONTINUE", 9, 150, 30)
	leave.position = Vector2(340, 286)
	leave.pressed.connect(_on_done)
	add_child(leave)

	interest_label.text = "interest paid on entry: +%d" % state.shop_interest
	coin_label.text = "COINS  %d" % state.coins


func _on_buy(index: int) -> void:
	if done:
		return
	if state.buy_shop_item(index):
		Sfx.play("coin", 1.0, -2.0)
	else:
		Sfx.play("click", 0.7, -6.0)
	_build_items()
	_build_footer()


func _on_reroll() -> void:
	if done:
		return
	if state.reroll_shop():
		Sfx.play("card", 0.9, -3.0)
	else:
		Sfx.play("click", 0.7, -6.0)
	_build_items()
	_build_footer()


func _on_done() -> void:
	if done:
		return
	done = true
	Sfx.play("click")
	main.on_shop_done()


func debug_continue() -> void:
	_on_done()
