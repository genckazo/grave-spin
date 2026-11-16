class_name ShopScreen
extends Control
## The grave market. Opens after boss fights 5 and 10. Driven entirely by
## GameState's shop engine — this screen only presents it.

const CARD_W := 120
const CARD_H := 150
const CARD_Y := 88
const CARD_X := [16, 148, 280]

var main
var state: GameState
var screen_id := "shop"
var first_visit := false

var relic_stock: Array = []
var relic_cards: Array = []
var coin_label: Label
var interest_label: Label
var reroll_button: Button
var leave_button: Button
var upgrade_buttons: Dictionary = {}
var consumable_button: Button
var consumable_row: Control
var tip_label: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	screen_id = "shop"

	first_visit = not bool(state.teach_seen.get("first_shop", false))
	var stock: Dictionary = state.open_shop()
	relic_stock = stock.get("relics", [])

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.015, 0.03, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var kicker := UI.label("FIGHT %d CLEARED  ·  THE GRAVE MARKET OPENS" % state.fights_won, 7, UI.GOLD, "header")
	kicker.position = Vector2(16, 10)
	kicker.size = Vector2(430, 10)
	add_child(kicker)

	var title := UI.shadowed(UI.label("THE GRAVE MARKET", 30, UI.GOLD, "title"))
	title.position = Vector2(16, 20)
	title.size = Vector2(470, 40)
	add_child(title)

	coin_label = UI.label("COINS  %d" % state.coins, 8, UI.GOLD, "header")
	coin_label.position = Vector2(420, 12)
	coin_label.size = Vector2(204, 12)
	coin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(coin_label)

	interest_label = UI.label("INTEREST ON ENTRY  +%d" % int(stock.get("interest", 0)), 7, UI.GREEN, "header")
	interest_label.position = Vector2(420, 28)
	interest_label.size = Vector2(204, 12)
	interest_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(interest_label)

	tip_label = UI.label(state.teach_line("first_shop"), 7, UI.GOLD_HI, "body")
	tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip_label.position = Vector2(16, 62)
	tip_label.size = Vector2(608, 20)
	tip_label.visible = first_visit and state.teach_line("first_shop") != ""
	add_child(tip_label)

	UI.separator(self, 16, 82, 608)

	_build_relics()
	_build_right_column(stock)
	_build_footer()


func _build_relics() -> void:
	for card in relic_cards:
		card["root"].queue_free()
	relic_cards.clear()

	var label := UI.label("RELICS — TAKE ANY", 6, UI.DIM, "header")
	label.position = Vector2(16, CARD_Y - 10)
	label.size = Vector2(380, 10)
	add_child(label)

	for i in range(relic_stock.size()):
		if i >= CARD_X.size():
			break
		_build_relic_card(i, relic_stock[i])


func _build_relic_card(index: int, relic: Dictionary) -> void:
	var root := Control.new()
	root.position = Vector2(CARD_X[index], CARD_Y)
	root.size = Vector2(CARD_W, CARD_H)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var panel := UI.panel("res://assets/generated/ui_card.png", 0)
	panel.position = Vector2.ZERO
	panel.size = Vector2(CARD_W, CARD_H)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(panel)

	var rarity_col := UI.rarity_color(String(relic.get("rarity", "common")))
	var icon := UI.icon("res://assets/generated/" + String(relic["icon"]), 34)
	icon.position = Vector2(43, 8)
	panel.add_child(icon)

	var name_label := UI.centered(UI.shadowed(UI.label(String(relic["name"]), 7, UI.GOLD, "header")))
	name_label.position = Vector2(4, 46)
	name_label.size = Vector2(CARD_W - 8, 12)
	name_label.clip_text = true
	panel.add_child(name_label)

	var rarity_label := UI.centered(UI.label(String(relic.get("rarity", "common")).to_upper(), 6, rarity_col, "header"))
	rarity_label.position = Vector2(4, 58)
	rarity_label.size = Vector2(CARD_W - 8, 9)
	panel.add_child(rarity_label)

	var desc := UI.label(String(relic["desc"]), 7, UI.BONE, "body")
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_constant_override("line_spacing", 1)
	desc.position = Vector2(8, 70)
	desc.size = Vector2(CARD_W - 16, 48)
	panel.add_child(desc)

	var strip := ColorRect.new()
	strip.position = Vector2(8, CARD_H - 26)
	strip.size = Vector2(CARD_W - 16, 2)
	strip.color = Color(rarity_col.r, rarity_col.g, rarity_col.b, 0.7)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(strip)

	var button := UI.button("TAKE", 8, CARD_W - 16, 20)
	button.position = Vector2(8, CARD_H - 22)
	button.pressed.connect(_on_take_relic.bind(index))
	panel.add_child(button)

	relic_cards.append({"root": root, "button": button, "relic": relic})


func _build_right_column(stock: Dictionary) -> void:
	var col_x := 412.0
	var col_w := 212.0

	var up_label := UI.label("PERMANENT UPGRADES  (MAX 1 EACH PER VISIT)", 6, UI.DIM, "header")
	up_label.position = Vector2(col_x, CARD_Y - 10)
	up_label.size = Vector2(col_w, 10)
	add_child(up_label)

	var upgrades: Array = stock.get("upgrades", [])
	for i in range(upgrades.size()):
		var u: Dictionary = upgrades[i]
		var y := CARD_Y + i * 32.0
		var row := Control.new()
		row.position = Vector2(col_x, y)
		row.size = Vector2(col_w, 28)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(row)

		var name_l := UI.label("%s  —  %dc" % [String(u["name"]), int(u["price"])], 7, UI.BONE, "header")
		name_l.position = Vector2(0, 0)
		name_l.size = Vector2(col_w - 62, 10)
		name_l.clip_text = true
		row.add_child(name_l)

		var desc := UI.label(String(u["desc"]), 6, UI.MUTED, "body")
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.position = Vector2(0, 11)
		desc.size = Vector2(col_w - 62, 16)
		row.add_child(desc)

		var b := UI.button("BUY", 7, 54, 22)
		b.position = Vector2(col_w - 56, 3)
		b.pressed.connect(_on_buy_upgrade.bind(String(u["id"])))
		row.add_child(b)
		upgrade_buttons[String(u["id"])] = b

	var con_label := UI.label("CONSUMABLE  (HOLD MAX 2)", 6, UI.DIM, "header")
	con_label.position = Vector2(col_x, CARD_Y + 100)
	con_label.size = Vector2(col_w, 10)
	add_child(con_label)

	consumable_row = Control.new()
	consumable_row.position = Vector2(col_x, CARD_Y + 112)
	consumable_row.size = Vector2(col_w, 40)
	consumable_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(consumable_row)
	_refresh_consumable()

	reroll_button = UI.button("", 8, col_w, 30)
	reroll_button.position = Vector2(col_x, CARD_Y + 158)
	reroll_button.pressed.connect(_on_reroll)
	add_child(reroll_button)

	leave_button = UI.button("", 9, col_w, 34)
	leave_button.position = Vector2(col_x, CARD_Y + 196)
	leave_button.add_theme_color_override("font_color", UI.GOLD_HI)
	leave_button.pressed.connect(_on_leave)
	add_child(leave_button)

	_refresh_dynamic()


func _refresh_consumable() -> void:
	for child in consumable_row.get_children():
		child.queue_free()
	var id := state.shop_consumable
	if id == "":
		var sold := UI.label("SOLD OUT", 7, UI.DIM, "header")
		sold.position = Vector2(0, 4)
		sold.size = Vector2(150, 10)
		consumable_row.add_child(sold)
		consumable_button = null
		return
	var c := GameData.consumable_by_id(id)
	var name_l := UI.label("%s  —  %dc" % [String(c["name"]), int(c.get("price", 0))], 7, UI.BONE, "header")
	name_l.position = Vector2(0, 0)
	name_l.size = Vector2(150, 10)
	name_l.clip_text = true
	consumable_row.add_child(name_l)
	var desc := UI.label(String(c["desc"]), 6, UI.MUTED, "body")
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.position = Vector2(0, 11)
	desc.size = Vector2(150, 28)
	consumable_row.add_child(desc)
	consumable_button = UI.button("BUY", 7, 54, 22)
	consumable_button.position = Vector2(156, 8)
	consumable_button.pressed.connect(_on_buy_consumable)
	consumable_row.add_child(consumable_button)


func _build_footer() -> void:
	var hint := UI.label("BUY, REROLL, THEN LEAVE — LEAVING STARTS THE NEXT FIGHT", 6, UI.DIM, "header")
	hint.position = Vector2(16, 330)
	hint.size = Vector2(608, 10)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(hint)


func _refresh_dynamic() -> void:
	coin_label.text = "COINS  %d" % state.coins
	reroll_button.text = "REROLL RELICS  —  %dc" % state.shop_reroll_cost()
	reroll_button.disabled = state.coins < state.shop_reroll_cost()
	leave_button.text = "LEAVE  —  FIGHT %d" % (state.fight_index + 2)
	for id in upgrade_buttons:
		var b: Button = upgrade_buttons[id]
		var u := GameData.upgrade_by_id(id)
		b.disabled = state.shop_upgrades_bought.has(id) or state.coins < int(u.get("price", 0))
	if consumable_button != null:
		consumable_button.disabled = state.shop_consumable == "" or state.coins < int(GameData.consumable_by_id(state.shop_consumable).get("price", 0)) or state.consumables.size() >= 2
	for card in relic_cards:
		card["button"].disabled = state.relics.size() >= state.shop_relic_cap()


func _on_take_relic(index: int) -> void:
	if index < 0 or index >= relic_stock.size():
		return
	var relic: Dictionary = relic_stock[index]
	if state.relics.size() >= state.shop_relic_cap():
		return
	state.choose_relic(relic)
	relic_stock.remove_at(index)
	Sfx.play("card", 1.0, -2.0)
	_build_relics()
	_refresh_dynamic()


func _on_reroll() -> void:
	if not state.reroll_shop():
		return
	relic_stock = state.shop_relic_stock()
	Sfx.play("coin", 0.9, -4.0)
	_build_relics()
	_refresh_dynamic()


func _on_buy_upgrade(id: String) -> void:
	if not state.buy_upgrade(id):
		return
	Sfx.play("coin", 1.0, -2.0)
	_refresh_dynamic()


func _on_buy_consumable() -> void:
	if not state.buy_shop_consumable():
		return
	Sfx.play("coin", 1.0, -2.0)
	_refresh_consumable()
	_refresh_dynamic()


func _on_leave() -> void:
	_leave()


func debug_leave() -> void:
	_leave()


func _leave() -> void:
	Sfx.play("click")
	state.leave_shop()
	state.begin_next_fight()
	main.show_fight()
