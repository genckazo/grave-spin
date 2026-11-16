class_name ShopScreen
extends Control
## The Bone Market. Opens after boss fights 5 and 10. Presents the SYS4
## economy from GameState.open_shop() — nothing is re-implemented here.

var main
var state: GameState
var screen_id := "shop"

var stock: Dictionary = {}
var bought: Dictionary = {}
var coin_label: Label
var reroll_button: Button
var relic_buttons: Array = []
var upgrade_buttons: Array = []
var consumable_button: Button
var content: Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	screen_id = "shop"

	var first_visit: bool = not bool(state.teach_seen.get("first_shop", false))
	stock = state.open_shop()

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.015, 0.03, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	content = Control.new()
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)

	_build_content(first_visit)


func _build_content(first_visit: bool) -> void:
	coin_label = UI.shadowed(UI.label("COINS  %d" % state.coins, 9, UI.GOLD, "header"))
	coin_label.position = Vector2(430, 12)
	coin_label.size = Vector2(194, 12)
	coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	content.add_child(coin_label)

	var interest_label := UI.label("interest on entry: +%d" % int(stock.get("interest", 0)), 7, UI.GREEN, "body")
	interest_label.position = Vector2(430, 28)
	interest_label.size = Vector2(194, 10)
	interest_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	content.add_child(interest_label)

	var kicker := UI.label("BOSS FELLED  ·  THE MARKET OPENS", 7, UI.GOLD, "header")
	kicker.position = Vector2(16, 10)
	kicker.size = Vector2(410, 10)
	content.add_child(kicker)

	var title := UI.shadowed(UI.label("THE BONE MARKET", 30, UI.GOLD, "title"))
	title.position = Vector2(16, 20)
	title.size = Vector2(470, 40)
	content.add_child(title)

	if first_visit:
		var teach_label := UI.shadowed(UI.label(state.teach_line("first_shop"), 8, UI.BONE, "body"))
		teach_label.position = Vector2(17, 60)
		teach_label.size = Vector2(606, 12)
		content.add_child(teach_label)

	UI.separator(content, 16, 76, 608)

	_build_relics()
	_build_upgrades_and_consumable()
	_build_footer()
	_refresh_buttons()


func _build_relics() -> void:
	var head := UI.label("RELICS", 7, UI.MUTED, "header")
	head.position = Vector2(16, 84)
	head.size = Vector2(200, 10)
	content.add_child(head)
	var relics: Array = stock.get("relics", [])
	for i in range(relics.size()):
		var relic: Dictionary = relics[i]
		var x := 16.0 + i * 204.0
		var root := Control.new()
		root.position = Vector2(x, 98)
		root.size = Vector2(192, 108)
		root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(root)

		var panel := UI.panel("res://assets/generated/ui_card.png", 0)
		panel.size = Vector2(192, 108)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(panel)

		var icon := UI.icon("res://assets/generated/" + String(relic["icon"]), 34)
		icon.position = Vector2(10, 10)
		panel.add_child(icon)

		var name_l := UI.shadowed(UI.label(String(relic["name"]), 8, UI.GOLD, "header"))
		name_l.position = Vector2(50, 10)
		name_l.size = Vector2(136, 12)
		name_l.clip_text = true
		panel.add_child(name_l)

		var desc := UI.label(String(relic["desc"]), 8, UI.BONE, "body")
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.position = Vector2(10, 48)
		desc.size = Vector2(172, 34)
		panel.add_child(desc)

		var price := state.relic_price(relic)
		var b := UI.button("BUY  %dc" % price, 8, 172, 22)
		b.position = Vector2(10, 82)
		b.tooltip_text = "%s — %s" % [String(relic["name"]), String(relic["desc"])]
		b.pressed.connect(_on_buy_relic.bind(String(relic["id"]), b))
		panel.add_child(b)
		relic_buttons.append({"id": String(relic["id"]), "button": b, "price": price})


func _build_upgrades_and_consumable() -> void:
	var head := UI.label("PERMANENT UPGRADES  ·  CONSUMABLE", 7, UI.MUTED, "header")
	head.position = Vector2(16, 216)
	head.size = Vector2(400, 10)
	content.add_child(head)

	var upgrades: Array = stock.get("upgrades", [])
	for i in range(upgrades.size()):
		var u: Dictionary = upgrades[i]
		var b := UI.button("%s  %dc" % [String(u["name"]), int(u.get("price", 0))], 8, 196, 40)
		b.position = Vector2(16.0 + i * 202.0, 230)
		b.tooltip_text = String(u["desc"])
		b.pressed.connect(_on_buy_upgrade.bind(String(u["id"]), b))
		content.add_child(b)
		upgrade_buttons.append({"id": String(u["id"]), "button": b, "price": int(u.get("price", 0))})

	var con_id := String(stock.get("consumable", ""))
	if con_id != "":
		var c := GameData.consumable_by_id(con_id)
		var b := UI.button("%s  %dc" % [String(c.get("name", con_id)), int(c.get("price", 0))], 8, 196, 40)
		b.position = Vector2(16.0 + upgrades.size() * 202.0, 230)
		b.tooltip_text = String(c.get("desc", ""))
		b.pressed.connect(_on_buy_consumable.bind(con_id, b))
		content.add_child(b)
		consumable_button = b


func _build_footer() -> void:
	reroll_button = UI.button("REROLL  %dc" % int(stock.get("reroll_cost", 2)), 9, 150, 30)
	reroll_button.position = Vector2(16, 316)
	reroll_button.tooltip_text = "Re-deal relics and the consumable. Price rises each reroll this visit."
	reroll_button.pressed.connect(_on_reroll)
	content.add_child(reroll_button)

	var leave := UI.button("LEAVE  ->", 10, 120, 30)
	leave.position = Vector2(504, 316)
	leave.pressed.connect(_on_leave)
	content.add_child(leave)


func _refresh_buttons() -> void:
	if coin_label != null:
		coin_label.text = "COINS  %d" % state.coins
	for entry in relic_buttons:
		var b: Button = entry["button"]
		b.disabled = state.coins < int(entry["price"]) or state.has_relic(String(entry["id"])) or state.relics.size() >= state.shop_relic_cap() or bought.get(String(entry["id"]), false)
		if bought.get(String(entry["id"]), false):
			b.text = "TAKEN"
	for entry in upgrade_buttons:
		var b: Button = entry["button"]
		b.disabled = state.coins < int(entry["price"]) or bought.get(String(entry["id"]), false)
		if bought.get(String(entry["id"]), false):
			b.text = "OWNED"
	if consumable_button != null:
		var c := GameData.consumable_by_id(String(stock.get("consumable", "")))
		consumable_button.disabled = state.coins < int(c.get("price", 0)) or state.consumables.size() >= 2 or bought.get("consumable", false)
		if bought.get("consumable", false):
			consumable_button.text = "TAKEN"
	if reroll_button != null:
		reroll_button.text = "REROLL  %dc" % state.shop_reroll_cost()
		reroll_button.disabled = state.coins < state.shop_reroll_cost()


func _on_buy_relic(id: String, b: Button) -> void:
	if state.buy_relic(id):
		bought[id] = true
		Sfx.play("coin", 1.0, -3.0)
	_refresh_buttons()


func _on_buy_upgrade(id: String, b: Button) -> void:
	if state.buy_upgrade(id):
		bought[id] = true
		Sfx.play("coin", 1.0, -3.0)
		_refresh_buttons()


func _on_buy_consumable(id: String, b: Button) -> void:
	if state.buy_consumable(id):
		bought["consumable"] = true
		Sfx.play("coin", 1.0, -3.0)
		_refresh_buttons()


func _on_reroll() -> void:
	if not state.reroll_shop():
		return
	Sfx.play("card", 0.9, 2.0)
	stock = state.shop_stock
	for child in content.get_children():
		child.queue_free()
	relic_buttons.clear()
	upgrade_buttons.clear()
	consumable_button = null
	coin_label = null
	reroll_button = null
	_build_content(false)


func _on_leave() -> void:
	main.on_shop_done()


func debug_leave() -> void:
	_on_leave()
