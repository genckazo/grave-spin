class_name FightScreen
extends Control
## The table. Reels, intent, paylines and a great deal of falling coin.

const CELL := 56
const REELS_X := 30
const REELS_Y := 90
const STRIP_ROWS := 9
const STRIP_TRAVEL := 336.0

var main
var state: GameState
var screen_id := "fight"

var busy := false
var paused := false

var shake_root: Control
var fx_layer: Control
var flash: ColorRect
var _flash_tween: Tween
var _shake_id := 0

var hp_text: Label
var hp_bar: Dictionary
var block_text: Label
var coin_text: Label
var fight_text: Label
var pips: Array = []
var relic_icons: Array = []

var enemy_art: Control
var enemy_sprite: TextureRect
var enemy_name: Label
var enemy_type: Label
var enemy_blurb: Label
var enemy_hp_text: Label
var enemy_hp_bar: Dictionary
var enemy_block_label: Label
var enemy_intent_icon: TextureRect
var intent_title: Label
var intent_sub: Label
var intent_panel: Panel
var enemy_max_hp := 1

var log_body: RichTextLabel
var lever: TextureRect
var reels: Array = []
var pull_button: Button
var pull_hint: Label
var pause_button: Button
var pause_overlay: Control
var resume_button: Button

var _shown_hp := 0
var _shown_enemy_hp := 0
var _shown_coins := 0
var _shown_block := 0
var _shown_enemy_block := 0
var _symbol_tex: Dictionary = {}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	screen_id = "fight"
	enemy_max_hp = max(1, state.enemy_hp)

	shake_root = Control.new()
	shake_root.size = Vector2(640, 360)
	shake_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shake_root)

	_build_top_bar()
	_build_machine()
	_build_enemy_panel()
	_build_log_panel()
	_build_bottom()
	_build_flash()

	fx_layer = Control.new()
	fx_layer.size = Vector2(640, 360)
	fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shake_root.add_child(fx_layer)

	_build_pause_overlay()
	_refresh_all()
	pull_button.grab_focus()


func _exit_tree() -> void:
	Engine.time_scale = 1.0


# ---------------------------------------------------------------- construction

func _build_top_bar() -> void:
	var bar := ColorRect.new()
	bar.color = Color(0.025, 0.017, 0.035, 0.94)
	bar.size = Vector2(640, 34)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shake_root.add_child(bar)
	UI.separator(shake_root, 0, 33, 640)

	var potion := UI.icon("res://assets/generated/potion_icon.png", 20)
	potion.position = Vector2(8, 7)
	shake_root.add_child(potion)
	hp_text = UI.shadowed(UI.label("HP 52 / 52", 8, UI.BONE, "header"))
	hp_text.position = Vector2(32, 5)
	hp_text.size = Vector2(108, 14)
	shake_root.add_child(hp_text)
	hp_bar = UI.hp_bar(32, 21, 104, 6, UI.RED)
	shake_root.add_child(hp_bar["frame"])

	var shield := UI.icon("res://assets/generated/shield_icon.png", 20)
	shield.position = Vector2(146, 7)
	shake_root.add_child(shield)
	block_text = UI.shadowed(UI.label("0", 8, UI.BLUE, "header"))
	block_text.position = Vector2(170, 11)
	block_text.size = Vector2(32, 14)
	shake_root.add_child(block_text)

	var coin := UI.icon("res://assets/generated/coin_icon.png", 20)
	coin.position = Vector2(210, 7)
	shake_root.add_child(coin)
	coin_text = UI.shadowed(UI.label("0", 8, UI.GOLD, "header"))
	coin_text.position = Vector2(234, 11)
	coin_text.size = Vector2(48, 14)
	shake_root.add_child(coin_text)

	fight_text = UI.shadowed(UI.label("FIGHT 1 / 5", 8, UI.BONE, "header"))
	fight_text.position = Vector2(294, 5)
	fight_text.size = Vector2(150, 14)
	shake_root.add_child(fight_text)
	for i in range(state.fights.size()):
		var pip := ColorRect.new()
		pip.position = Vector2(296 + i * 14, 23)
		pip.size = Vector2(10, 3)
		pip.color = UI.DIM
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shake_root.add_child(pip)
		pips.append(pip)

	pause_button = UI.button("II", 8, 28, 24)
	pause_button.position = Vector2(604, 5)
	pause_button.focus_mode = Control.FOCUS_NONE
	pause_button.tooltip_text = "Pause (Esc)"
	pause_button.pressed.connect(_toggle_pause)
	shake_root.add_child(pause_button)


func _build_machine() -> void:
	var frame := UI.texture("res://assets/generated/machine_frame.png", 200, 260)
	frame.position = Vector2(14, 34)
	shake_root.add_child(frame)

	for c in range(3):
		var col := Control.new()
		col.position = Vector2(REELS_X + c * CELL, REELS_Y)
		col.size = Vector2(CELL, CELL * 3)
		col.clip_contents = true
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shake_root.add_child(col)

		var strip := Control.new()
		strip.size = Vector2(CELL, CELL * STRIP_ROWS)
		strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(strip)

		var icons: Array = []
		for i in range(STRIP_ROWS):
			var tr := UI.texture("res://assets/generated/sword_icon.png", 48, 48)
			tr.position = Vector2(4, i * CELL + 4)
			strip.add_child(tr)
			tr.texture = _symbol_texture(_random_symbol())
			icons.append(tr)

		reels.append({"col": col, "strip": strip, "icons": icons})

	# Grid lines sit above the scrolling strips so the glass reads as solid.
	for x in [86, 142]:
		var vline := ColorRect.new()
		vline.position = Vector2(x, REELS_Y - 2)
		vline.size = Vector2(2, CELL * 3 + 4)
		vline.color = Color("5f4312")
		vline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shake_root.add_child(vline)
	for y in [146, 202]:
		var hline := ColorRect.new()
		hline.position = Vector2(28, y)
		hline.size = Vector2(174, 2)
		hline.color = Color("5f4312")
		hline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shake_root.add_child(hline)

	var marquee := UI.centered(UI.shadowed(UI.label("GRAVE SPIN", 11, UI.GOLD_HI, "header_bold")))
	marquee.position = Vector2(14, 46)
	marquee.size = Vector2(200, 15)
	shake_root.add_child(marquee)
	var sub := UI.centered(UI.label("ONE PULL  ·  ONE GRAVE", 5, UI.DIM, "header"))
	sub.position = Vector2(14, 62)
	sub.size = Vector2(200, 9)
	shake_root.add_child(sub)

	var mount := ColorRect.new()
	mount.position = Vector2(216, 212)
	mount.size = Vector2(40, 14)
	mount.color = Color(0.10, 0.07, 0.13, 0.9)
	mount.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shake_root.add_child(mount)
	var mount_trim := ColorRect.new()
	mount_trim.position = Vector2(220, 214)
	mount_trim.size = Vector2(32, 3)
	mount_trim.color = Color("5f4312")
	mount_trim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shake_root.add_child(mount_trim)

	lever = UI.texture("res://assets/generated/lever.png", 28, 128)
	lever.modulate = Color(1.12, 1.06, 1.15)
	lever.position = Vector2(222, 92)
	lever.pivot_offset = Vector2(14, 124)
	shake_root.add_child(lever)

	var lever_hit := Button.new()
	lever_hit.flat = true
	lever_hit.focus_mode = Control.FOCUS_NONE
	lever_hit.position = Vector2(214, 84)
	lever_hit.size = Vector2(48, 144)
	lever_hit.tooltip_text = "Pull the lever (Space)"
	lever_hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	lever_hit.pressed.connect(_on_pull)
	shake_root.add_child(lever_hit)


func _build_enemy_panel() -> void:
	var panel := UI.panel()
	panel.position = Vector2(282, 34)
	panel.size = Vector2(344, 152)
	shake_root.add_child(panel)

	var tag := UI.label("ENEMY", 6, UI.DIM, "header")
	tag.position = Vector2(12, 6)
	tag.size = Vector2(60, 10)
	panel.add_child(tag)

	var shadow := UI.texture("res://assets/generated/shadow.png", 104, 20)
	shadow.position = Vector2(8, 108)
	panel.add_child(shadow)

	enemy_art = Control.new()
	enemy_art.position = Vector2(12, 10)
	enemy_art.size = Vector2(96, 96)
	enemy_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(enemy_art)

	enemy_sprite = UI.texture(String(state.enemy["sprite"]), 96, 96)
	enemy_sprite.pivot_offset = Vector2(48, 48)
	enemy_art.add_child(enemy_sprite)

	var bob := create_tween().set_loops()
	bob.tween_property(enemy_sprite, "position:y", -3.0, 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob.tween_property(enemy_sprite, "position:y", 0.0, 1.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var skull_tag := UI.centered(UI.label("SKULLS +%d" % int(state.enemy.get("skull_extra", 0)), 6, UI.RED, "header"))
	skull_tag.position = Vector2(6, 128)
	skull_tag.size = Vector2(108, 10)
	panel.add_child(skull_tag)

	enemy_name = UI.shadowed(UI.label("", 8, UI.GOLD, "header"))
	enemy_name.position = Vector2(118, 8)
	enemy_name.size = Vector2(214, 14)
	panel.add_child(enemy_name)

	enemy_type = UI.label("", 6, UI.DIM, "header")
	enemy_type.position = Vector2(118, 22)
	enemy_type.size = Vector2(214, 10)
	panel.add_child(enemy_type)

	enemy_blurb = UI.label("", 8, UI.MUTED, "body")
	enemy_blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	enemy_blurb.position = Vector2(118, 35)
	enemy_blurb.size = Vector2(216, 26)
	panel.add_child(enemy_blurb)

	enemy_hp_text = UI.label("", 7, UI.BONE, "header")
	enemy_hp_text.position = Vector2(118, 62)
	enemy_hp_text.size = Vector2(214, 12)
	panel.add_child(enemy_hp_text)

	enemy_hp_bar = UI.hp_bar(118, 77, 212, 9, UI.RED)
	panel.add_child(enemy_hp_bar["frame"])

	enemy_block_label = UI.label("", 7, UI.BLUE, "header")
	enemy_block_label.position = Vector2(118, 89)
	enemy_block_label.size = Vector2(214, 10)
	panel.add_child(enemy_block_label)

	intent_panel = UI.panel()
	intent_panel.position = Vector2(112, 99)
	intent_panel.size = Vector2(222, 46)
	panel.add_child(intent_panel)

	enemy_intent_icon = UI.icon("res://assets/generated/skull_icon.png", 20)
	enemy_intent_icon.position = Vector2(6, 13)
	intent_panel.add_child(enemy_intent_icon)

	intent_title = UI.shadowed(UI.label("", 8, UI.RED, "header"))
	intent_title.position = Vector2(32, 6)
	intent_title.size = Vector2(184, 12)
	intent_panel.add_child(intent_title)

	intent_sub = UI.label("", 6, UI.MUTED, "body")
	intent_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intent_sub.position = Vector2(32, 20)
	intent_sub.size = Vector2(184, 20)
	intent_panel.add_child(intent_sub)


func _build_log_panel() -> void:
	var panel := UI.panel()
	panel.position = Vector2(282, 194)
	panel.size = Vector2(344, 88)
	shake_root.add_child(panel)

	var tag := UI.label("THE MACHINE SPEAKS", 6, UI.DIM, "header")
	tag.position = Vector2(8, 4)
	tag.size = Vector2(200, 10)
	panel.add_child(tag)

	log_body = RichTextLabel.new()
	log_body.bbcode_enabled = true
	log_body.position = Vector2(10, 16)
	log_body.size = Vector2(324, 66)
	log_body.scroll_active = false
	log_body.scroll_following = false
	log_body.add_theme_font_override("normal_font", UI.font("body"))
	log_body.add_theme_font_size_override("normal_font_size", 8)
	log_body.add_theme_color_override("default_color", UI.BONE)
	log_body.add_theme_constant_override("line_separation", 1)
	log_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(log_body)


func _build_bottom() -> void:
	var bottom := ColorRect.new()
	bottom.color = Color(0.025, 0.017, 0.035, 0.8)
	bottom.position = Vector2(0, 332)
	bottom.size = Vector2(640, 28)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shake_root.add_child(bottom)
	UI.separator(shake_root, 0, 332, 640)

	pull_button = UI.button("PULL THE LEVER", 10, 196, 38)
	pull_button.position = Vector2(430, 290)
	pull_button.add_theme_color_override("font_color", UI.GOLD_HI)
	pull_button.pressed.connect(_on_pull)
	shake_root.add_child(pull_button)

	pull_hint = UI.label("SPACE  /  CLICK", 6, UI.DIM, "header")
	pull_hint.position = Vector2(14, 341)
	pull_hint.size = Vector2(180, 10)
	shake_root.add_child(pull_hint)

	var pause_hint := UI.label("ESC  PAUSE", 6, UI.DIM, "header")
	pause_hint.position = Vector2(526, 341)
	pause_hint.size = Vector2(100, 10)
	pause_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	shake_root.add_child(pause_hint)


func _build_flash() -> void:
	flash = ColorRect.new()
	flash.color = Color(0, 0, 0, 0)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shake_root.add_child(flash)


func _build_pause_overlay() -> void:
	pause_overlay = Control.new()
	pause_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_overlay.visible = false
	add_child(pause_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.015, 0.03, 0.84)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_overlay.add_child(dim)

	var backing := ColorRect.new()
	backing.position = Vector2(178, 82)
	backing.size = Vector2(284, 194)
	backing.color = Color(0.02, 0.015, 0.03, 0.98)
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_overlay.add_child(backing)

	var panel := UI.panel()
	panel.position = Vector2(180, 84)
	panel.size = Vector2(280, 190)
	pause_overlay.add_child(panel)

	var title := UI.centered(UI.shadowed(UI.label("PAUSED", 32, UI.GOLD, "title")))
	title.position = Vector2(0, 8)
	title.size = Vector2(280, 42)
	panel.add_child(title)

	var sub := UI.centered(UI.label("The house can wait.", 8, UI.MUTED, "body"))
	sub.position = Vector2(0, 50)
	sub.size = Vector2(280, 14)
	panel.add_child(sub)

	resume_button = UI.button("RESUME", 9, 200, 32)
	resume_button.position = Vector2(40, 84)
	resume_button.pressed.connect(_resume)
	panel.add_child(resume_button)

	var title_btn := UI.button("TITLE SCREEN", 9, 200, 32)
	title_btn.position = Vector2(40, 126)
	title_btn.pressed.connect(_to_title)
	panel.add_child(title_btn)


# --------------------------------------------------------------------- refresh

func _refresh_all() -> void:
	_shown_hp = state.hp
	_shown_enemy_hp = state.enemy_hp
	_shown_coins = state.coins
	_shown_block = state.block
	_shown_enemy_block = state.enemy_block

	hp_text.text = "HP %d / %d" % [state.hp, state.max_hp]
	UI.set_bar(hp_bar, float(state.hp) / float(max(1, state.max_hp)))
	block_text.text = str(state.block)
	coin_text.text = str(state.coins)
	fight_text.text = "FLOOR %d · FIGHT %d / %d" % [int(state.enemy.get("floor", 1)), state.fight_index + 1, state.fights.size()]
	for i in range(pips.size()):
		pips[i].color = UI.GOLD if i <= state.fight_index else Color("3a3244")

	enemy_name.text = String(state.enemy["name"])
	enemy_type.text = String(state.enemy["label"])
	enemy_blurb.text = "%s\n%s" % [String(state.enemy["blurb"]), String(state.enemy["curse"])]
	enemy_hp_text.text = "HP %d / %d" % [state.enemy_hp, enemy_max_hp]
	UI.set_bar(enemy_hp_bar, float(state.enemy_hp) / float(enemy_max_hp))
	_refresh_enemy_block()
	_refresh_intent()
	_refresh_relics()
	_refresh_log()


func _refresh_intent() -> void:
	if state.enemy_hp <= 0:
		intent_title.text = "SLAIN"
		intent_sub.text = "The machine pays out."
		intent_title.add_theme_color_override("font_color", UI.GOLD)
		enemy_intent_icon.texture = load("res://assets/generated/coin_icon.png")
		return
	var it := state.get_intent()
	intent_title.text = String(it["title"])
	intent_sub.text = String(it["sub"])
	var kind := String(it["type"])
	match kind:
		"attack", "heavy":
			intent_title.add_theme_color_override("font_color", UI.RED)
			enemy_intent_icon.texture = load("res://assets/generated/skull_icon.png")
		"defend":
			intent_title.add_theme_color_override("font_color", UI.BLUE)
			enemy_intent_icon.texture = load("res://assets/generated/shield_icon.png")
		_:
			intent_title.add_theme_color_override("font_color", UI.PURPLE)
			enemy_intent_icon.texture = load("res://assets/generated/dice_skull_icon.png")


func _refresh_enemy_block() -> void:
	if _shown_enemy_block > 0:
		enemy_block_label.text = "GUARD %d" % _shown_enemy_block
	else:
		enemy_block_label.text = ""


func _refresh_relics() -> void:
	for icon in relic_icons:
		icon.queue_free()
	relic_icons.clear()
	var n := state.relics.size()
	if n == 0:
		var none := UI.label("NO RELICS", 6, UI.DIM, "header")
		none.position = Vector2(516, 13)
		none.size = Vector2(76, 10)
		none.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		shake_root.add_child(none)
		relic_icons.append(none)
		return
	var total := n * 22 - 4
	var start_x := 592 - total
	for i in range(n):
		var relic: Dictionary = state.relics[i]
		var icon := UI.icon("res://assets/generated/" + String(relic["icon"]), 18)
		icon.position = Vector2(start_x + i * 22, 8)
		icon.mouse_filter = Control.MOUSE_FILTER_PASS
		icon.tooltip_text = "%s — %s" % [String(relic["name"]), String(relic["desc"])]
		shake_root.add_child(icon)
		relic_icons.append(icon)


func _refresh_log() -> void:
	var start := maxi(0, state.logs.size() - 5)
	var text := ""
	for i in range(start, state.logs.size()):
		var entry: Dictionary = state.logs[i]
		var c := UI.kind_color(String(entry["kind"]))
		var line := String(entry["text"]).replace("[", "[lb]")
		text += "[color=#%s]%s[/color]\n" % [c.to_html(false).substr(0, 6), line]
	log_body.text = text


func _display_hp(value: int, animate: bool = true) -> void:
	var from := float(_shown_hp) / float(max(1, state.max_hp))
	_shown_hp = value
	hp_text.text = "HP %d / %d" % [value, state.max_hp]
	var to := float(value) / float(max(1, state.max_hp))
	if animate and not main.fast:
		var tw := create_tween()
		tw.tween_method(func(v): UI.set_bar(hp_bar, v), from, to, 0.24)
	else:
		UI.set_bar(hp_bar, to)


func _display_enemy_hp(value: int, animate: bool = true) -> void:
	var from := float(_shown_enemy_hp) / float(enemy_max_hp)
	_shown_enemy_hp = value
	enemy_hp_text.text = "HP %d / %d" % [value, enemy_max_hp]
	var to := float(value) / float(enemy_max_hp)
	if animate and not main.fast:
		var tw := create_tween()
		tw.tween_method(func(v): UI.set_bar(enemy_hp_bar, v), from, to, 0.24)
	else:
		UI.set_bar(enemy_hp_bar, to)


func _display_coins(value: int) -> void:
	_shown_coins = value
	coin_text.text = str(value)


func _display_block(value: int) -> void:
	_shown_block = value
	block_text.text = str(value)


# ------------------------------------------------------------------------- turn

func _on_pull() -> void:
	if busy or paused or state == null or state.run_over:
		return
	_do_pull()


func debug_pull() -> void:
	if busy or state == null or state.run_over:
		return
	await _do_pull()


func _do_pull() -> void:
	busy = true
	pull_button.disabled = true
	pull_button.text = "THE WHEEL TURNS"
	pull_hint.text = "THE REELS ARE MOVING"

	var roll: Dictionary = state.roll()
	var grid: Array = roll["grid"]
	var near_row := int(roll["near_miss"])

	Sfx.play("lever", 1.0, -2.0)
	_animate_lever()
	_spin_ticks()
	if near_row >= 0:
		_near_miss(near_row)

	await _spin_reels(grid)

	var acting_intent := state.get_intent()
	var report: Dictionary = state.resolve(grid)
	await _reveal_rows(report)
	if not is_inside_tree():
		return

	if bool(report.get("enemy_dead", false)):
		_refresh_log()
		await _enemy_death()
		return

	await _enemy_turn(report, acting_intent)
	if not is_inside_tree():
		return

	_refresh_log()
	_refresh_top_after_turn()

	if bool(report.get("player_dead", false)):
		busy = true
		await _wait(0.7)
		if is_inside_tree():
			main.finish_run(false)
		return

	busy = false
	pull_button.disabled = false
	pull_button.text = "PULL THE LEVER"
	pull_hint.text = "SPACE  /  CLICK"
	pull_button.grab_focus()


func _refresh_top_after_turn() -> void:
	_display_hp(state.hp, false)
	_display_enemy_hp(state.enemy_hp, false)
	_display_coins(state.coins)
	_display_block(state.block)
	_shown_enemy_block = state.enemy_block
	_refresh_enemy_block()
	_refresh_intent()


func _spin_reels(grid: Array) -> void:
	if main.fast:
		for c in range(3):
			_set_strip_final(c, grid)
		return

	var last_tw: Tween = null
	for c in range(3):
		var reel: Dictionary = reels[c]
		var icons: Array = reel["icons"]
		for i in range(STRIP_ROWS):
			icons[i].texture = _symbol_texture(_random_symbol())
		for r in range(3):
			icons[6 + r].texture = _symbol_texture(String(grid[r][c]))
		reel["strip"].position.y = 0.0

		var delay := c * 0.07
		var duration := 0.60 + c * 0.15
		var tw := create_tween()
		tw.tween_interval(delay)
		tw.tween_property(reel["strip"], "position:y", -STRIP_TRAVEL, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_callback(_on_reel_stop.bind(c, grid))
		last_tw = tw

	if last_tw != null:
		await last_tw.finished
	await _wait(0.05)


func _on_reel_stop(c: int, grid: Array) -> void:
	if not is_inside_tree():
		return
	var reel: Dictionary = reels[c]
	var icons: Array = reel["icons"]
	reel["strip"].position.y = 0.0
	for i in range(STRIP_ROWS):
		icons[i].texture = _symbol_texture(_random_symbol())
	for r in range(3):
		icons[r].texture = _symbol_texture(String(grid[r][c]))
	Sfx.play("reelstop", 0.9 + c * 0.08, -4.0)
	_dust_puff(Vector2(REELS_X + c * CELL + 28, REELS_Y + 166))


func _set_strip_final(c: int, grid: Array) -> void:
	var reel: Dictionary = reels[c]
	var icons: Array = reel["icons"]
	for i in range(STRIP_ROWS):
		icons[i].texture = _symbol_texture(_random_symbol())
	for r in range(3):
		icons[r].texture = _symbol_texture(String(grid[r][c]))
	reel["strip"].position.y = 0.0


func _animate_lever() -> void:
	if main.fast:
		lever.rotation = 0.0
		return
	var tw := create_tween()
	tw.tween_property(lever, "rotation", 1.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(lever, "rotation", 0.0, 0.46).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _spin_ticks() -> void:
	if main.fast:
		return
	for i in range(16):
		if not is_inside_tree():
			return
		Sfx.tick(randf_range(0.35, 0.9))
		await get_tree().create_timer(0.055).timeout


func _near_miss(row: int) -> void:
	if main.fast:
		return
	await _wait(0.5)
	if not is_inside_tree():
		return
	Sfx.play("bell", 0.62, -9.0)
	_float_text("TWO SWORDS...", Vector2(14, 184), UI.GOLD_HI, 8, 200)
	var l := UI.centered(UI.shadowed(UI.label("SO CLOSE", 14, UI.RED, "title")))
	l.position = Vector2(14, 158)
	l.size = Vector2(200, 22)
	shake_root.add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "modulate:a", 0.0, 0.45).set_delay(0.18)
	tw.tween_callback(l.queue_free)
	Engine.time_scale = 0.35
	_flash(Color(0.9, 0.6, 0.2, 0.10), 0.35)
	await get_tree().create_timer(0.42, true, false, true).timeout
	Engine.time_scale = 1.0


func _reveal_rows(report: Dictionary) -> void:
	var rows: Array = report.get("rows", [])
	for row_data in rows:
		if not is_inside_tree():
			return
		var r := int(row_data["row"])
		_display_enemy_hp(max(0, _shown_enemy_hp - int(row_data["damage"])))
		_display_hp(min(state.max_hp, _shown_hp + int(row_data["heal"])))
		_display_coins(_shown_coins + int(row_data["coins_gain"]))
		_display_block(_shown_block + int(row_data["block"]))

		var highlight := _row_highlight(r)
		if highlight != null:
			highlight.modulate.a = 0.0
			var in_tw := create_tween()
			in_tw.tween_property(highlight, "modulate:a", 1.0, 0.08)

		var summary := _row_summary(row_data)
		if summary != "":
			var col := UI.GOLD_HI
			if int(row_data["skulls"]) > 0 and int(row_data["swords"]) == 0:
				col = UI.PURPLE
			elif int(row_data["heal"]) > 0:
				col = UI.GREEN
			_float_text(summary, Vector2(24, REELS_Y + r * CELL + 18), col, 7, 180)

		var sound := _row_sound(row_data)
		if sound != "":
			Sfx.play(sound, 1.0, -3.0)
		if int(row_data["skulls"]) > 0:
			_shake(1.2 + 0.3 * int(row_data["skulls"]), 0.12)
			if not main.fast:
				Sfx.play("skull", 0.8, -10.0)
		if int(row_data["coins_gain"]) > 0:
			_coin_burst(Vector2(114, 278), mini(6 + int(row_data["coins_gain"]) * 2, 22))

		await _wait(0.34)
		if highlight != null:
			var out_tw := create_tween()
			out_tw.tween_property(highlight, "modulate:a", 0.0, 0.18)
			out_tw.tween_callback(highlight.queue_free)

	_shown_enemy_block = 0
	_refresh_enemy_block()
	await _wait(0.15)


func _row_highlight(row: int) -> Panel:
	if main.fast:
		return null
	var p := Panel.new()
	p.position = Vector2(REELS_X, REELS_Y + row * CELL)
	p.size = Vector2(CELL * 3, CELL)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.95, 0.72, 0.25, 0.10)
	sb.border_color = Color(0.95, 0.72, 0.25, 0.72)
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	p.add_theme_stylebox_override("panel", sb)
	shake_root.add_child(p)
	return p


func _row_summary(row_data: Dictionary) -> String:
	var bits: Array = []
	var dmg := int(row_data["damage"])
	var absorbed := int(row_data["absorbed"])
	if dmg > 0:
		bits.append("-%d HP" % dmg)
	if absorbed > 0:
		bits.append("%d ABSORBED" % absorbed)
	if int(row_data["block"]) > 0:
		bits.append("+%d BLOCK" % int(row_data["block"]))
	if int(row_data["heal"]) > 0:
		bits.append("+%d HP" % int(row_data["heal"]))
	if int(row_data["coins_gain"]) > 0:
		bits.append("+%d COINS" % int(row_data["coins_gain"]))
	if int(row_data["skulls"]) > 0:
		bits.append("%d SKULL%s" % [int(row_data["skulls"]), "" if int(row_data["skulls"]) == 1 else "S"])
	return "  ".join(bits)


func _row_sound(row_data: Dictionary) -> String:
	if int(row_data["skulls"]) > 0:
		return "skull"
	if int(row_data["swords"]) > 0:
		return "sword"
	if int(row_data["coins_gain"]) > 0:
		return "coin"
	if int(row_data["shields"]) > 0:
		return "block"
	if int(row_data["potions"]) > 0:
		return "bell"
	return ""


func _enemy_turn(report: Dictionary, intent: Dictionary) -> void:
	var kind := String(intent["type"])
	if kind == "attack" or kind == "heavy":
		var incoming := int(intent["value"]) + int(report["skulls"]) * int(report["skull_penalty"])
		var blocked := mini(_shown_block, incoming)
		var taken := maxi(0, incoming - blocked)

		Sfx.play("hurt", 1.0, -3.0)
		_flash(Color(0.75, 0.08, 0.06, 0.22), 0.28)
		_shake(2.8 + float(report["skulls"]), 0.26)
		if blocked > 0:
			Sfx.play("block", 0.9, -2.0)
			_float_text("BLOCK %d" % blocked, Vector2(142, 4), UI.BLUE, 8, 80)
		await _enemy_lunge()
		if not is_inside_tree():
			return

		var after := maxi(0, _shown_hp - taken)
		_display_hp(after)
		_float_text("-%d" % taken, Vector2(42, 2), UI.RED, 11, 100)
		await _wait(0.2)
		if bool(report.get("second_wind", false)):
			Sfx.play("bell", 0.8, -1.0)
			_flash(Color(0.95, 0.75, 0.25, 0.28), 0.4)
			_float_text("SECOND WIND", Vector2(200, 70), UI.GOLD_HI, 12, 240)
			_display_hp(state.hp)
			await _wait(0.5)
		_display_block(0)
		await _wait(0.15)
	elif kind == "defend":
		Sfx.play("block", 0.8, -2.0)
		_enemy_pulse(UI.BLUE)
		_shown_enemy_block = int(intent["value"])
		_refresh_enemy_block()
		_float_text("+%d GUARD" % int(intent["value"]), Vector2(390, 78), UI.BLUE, 8, 100)
		await _wait(0.42)
	else:
		Sfx.play("skull", 0.65, -6.0)
		_enemy_pulse(UI.PURPLE)
		_float_text("+%d POWER" % int(intent["value"]), Vector2(390, 70), UI.PURPLE, 8, 110)
		_flash(Color(0.45, 0.2, 0.65, 0.16), 0.3)
		await _wait(0.42)


func _enemy_lunge() -> void:
	if main.fast:
		return
	var base := Vector2(12, 10)
	var tw := create_tween()
	tw.tween_property(enemy_art, "position", base + Vector2(-16, 0), 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(enemy_art, "position", base, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw.finished


func _enemy_pulse(color: Color) -> void:
	if main.fast:
		return
	enemy_sprite.modulate = Color(1.35, 1.2, 1.4)
	var tw := create_tween()
	tw.tween_property(enemy_sprite, "modulate", Color.WHITE, 0.4)
	_spark_burst(Vector2(342, 100), 12, color)


func _enemy_death() -> void:
	Sfx.play("boom", 0.9, -2.0)
	_shake(3.0, 0.36)
	_spark_burst(Vector2(342, 100), 26, UI.GOLD)
	_float_text("SLAIN", Vector2(290, 56), UI.GOLD_HI, 14, 104)
	_display_enemy_hp(0, false)
	if not main.fast:
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(enemy_sprite, "modulate:a", 0.0, 0.5).set_delay(0.25)
		tw.tween_property(enemy_sprite, "rotation", 0.5, 0.5).set_delay(0.25)
		await tw.finished
	await _wait(0.55 if not main.fast else 0.02)
	if is_inside_tree():
		main.on_fight_won()


# ---------------------------------------------------------------------- effects

func _wait(seconds: float) -> void:
	var t := 0.012 if main.fast else seconds
	await get_tree().create_timer(t).timeout


func _shake(strength: float, duration: float) -> void:
	if main.fast:
		return
	_shake_id += 1
	var my_id := _shake_id
	var end := Time.get_ticks_msec() + int(duration * 1000.0)
	while Time.get_ticks_msec() < end:
		if my_id != _shake_id:
			return
		shake_root.position = Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
		await get_tree().process_frame
	if my_id == _shake_id:
		shake_root.position = Vector2.ZERO


func _flash(color: Color, duration: float) -> void:
	if main.fast:
		return
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	flash.color = color
	_flash_tween = create_tween()
	_flash_tween.tween_property(flash, "color:a", 0.0, duration)


func _float_text(text: String, pos: Vector2, color: Color, size: int, width: float) -> void:
	if main.fast:
		return
	var l := UI.centered(UI.shadowed(UI.label(text, size, color, "header_bold")))
	l.position = pos
	l.size = Vector2(width, 14)
	fx_layer.add_child(l)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", pos.y - 16.0, 0.7)
	tw.tween_property(l, "modulate:a", 0.0, 0.5).set_delay(0.25)
	tw.finished.connect(l.queue_free)


func _coin_burst(pos: Vector2, amount: int) -> void:
	if main.fast:
		return
	var p := CPUParticles2D.new()
	p.position = pos
	p.amount = amount
	p.lifetime = 0.85
	p.one_shot = true
	p.explosiveness = 0.92
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(38, 3)
	p.direction = Vector2(0, -1)
	p.spread = 58.0
	p.gravity = Vector2(0, 240)
	p.initial_velocity_min = 42.0
	p.initial_velocity_max = 118.0
	p.scale_amount_min = 0.55
	p.scale_amount_max = 1.15
	p.texture = load("res://assets/generated/coin_particle.png")
	p.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	shake_root.add_child(p)
	p.restart()
	get_tree().create_timer(1.3).timeout.connect(p.queue_free)


func _spark_burst(pos: Vector2, amount: int, color: Color) -> void:
	if main.fast:
		return
	var p := CPUParticles2D.new()
	p.position = pos
	p.amount = amount
	p.lifetime = 0.6
	p.one_shot = true
	p.explosiveness = 0.95
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.gravity = Vector2(0, 80)
	p.initial_velocity_min = 28.0
	p.initial_velocity_max = 135.0
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.6
	p.color = color
	p.texture = load("res://assets/generated/spark.png")
	p.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	shake_root.add_child(p)
	p.restart()
	get_tree().create_timer(1.0).timeout.connect(p.queue_free)


func _dust_puff(pos: Vector2) -> void:
	if main.fast:
		return
	var p := CPUParticles2D.new()
	p.position = pos
	p.amount = 8
	p.lifetime = 0.45
	p.one_shot = true
	p.explosiveness = 0.9
	p.direction = Vector2(0, -1)
	p.spread = 35.0
	p.gravity = Vector2(0, -12)
	p.initial_velocity_min = 8.0
	p.initial_velocity_max = 34.0
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.4
	p.texture = load("res://assets/generated/dust.png")
	p.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	shake_root.add_child(p)
	p.restart()
	get_tree().create_timer(0.8).timeout.connect(p.queue_free)


func _symbol_texture(symbol: String) -> Texture2D:
	if _symbol_tex.has(symbol):
		return _symbol_tex[symbol]
	var tex: Texture2D = load("res://assets/generated/%s_icon.png" % symbol)
	_symbol_tex[symbol] = tex
	return tex


func _random_symbol() -> String:
	var bag := ["sword", "sword", "shield", "shield", "coin", "potion", "skull"]
	return String(bag.pick_random())


# ------------------------------------------------------------------------- pause

func _toggle_pause() -> void:
	if paused:
		_resume()
	elif not busy:
		_pause()


func _pause() -> void:
	paused = true
	pause_overlay.visible = true
	Sfx.play("click")
	pull_button.disabled = true
	resume_button.grab_focus()


func _resume() -> void:
	paused = false
	pause_overlay.visible = false
	Sfx.play("click")
	pull_button.disabled = busy
	if not busy:
		pull_button.grab_focus()


func debug_pause() -> void:
	if not paused:
		_pause()


func debug_resume() -> void:
	if paused:
		_resume()


func _to_title() -> void:
	Engine.time_scale = 1.0
	Sfx.play("click")
	main.show_title()


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.is_pressed() or event.is_echo():
		return
	var key := (event as InputEventKey).keycode
	if key == KEY_ESCAPE:
		if paused:
			_resume()
		else:
			_toggle_pause()
		get_viewport().set_input_as_handled()
	elif (key == KEY_SPACE or key == KEY_ENTER) and not paused:
		if not busy:
			_on_pull()
			get_viewport().set_input_as_handled()
