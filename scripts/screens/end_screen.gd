class_name EndScreen
extends Control
## The ledger after the last pull.

var main
var state: GameState
var earned := 0
var total_bones := 0
var screen_id := "end"

var again_button: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	screen_id = "end"

	var victory := state != null and state.victory
	var summary: Dictionary = state.summary() if state != null else {}

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.015, 0.03, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var tint := ColorRect.new()
	tint.color = Color(0.85, 0.62, 0.18, 0.035) if victory else Color(0.55, 0.06, 0.05, 0.05)
	tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tint)

	var title_text := "THE MACHINE RESTS" if victory else "YOU DIED"
	var title_color := UI.GOLD if victory else UI.RED
	var title := UI.centered(UI.shadowed(UI.label(title_text, 34 if victory else 48, title_color, "title")))
	title.position = Vector2(0, 26 if victory else 20)
	title.size = Vector2(640, 50)
	add_child(title)

	var sub_text := "Five graves. One survivor." if victory else "The machine keeps what it takes."
	var sub := UI.centered(UI.label(sub_text, 8, UI.MUTED, "body"))
	sub.position = Vector2(0, 82)
	sub.size = Vector2(640, 14)
	add_child(sub)
	UI.separator(self, 220, 100, 200)

	var panel := UI.panel()
	panel.position = Vector2(146, 100)
	panel.size = Vector2(348, 174)
	add_child(panel)

	var ledger := UI.label("THE LEDGER", 6, UI.DIM, "header")
	ledger.position = Vector2(14, 7)
	ledger.size = Vector2(160, 10)
	panel.add_child(ledger)

	var rows := [
		["FIGHTS WON", "%d / %d" % [int(summary.get("fights_won", 0)), int(summary.get("fights_total", 5))]],
		["LIVES SPENT", "%d / %d" % [int(summary.get("lives_spent", 0)), int(summary.get("lives_spent", 0)) + int(summary.get("lives", 0))]],
		["SPINS", str(int(summary.get("spins", 0)))],
		["COINS COLLECTED", str(int(summary.get("coins", 0)))],
		["DAMAGE DEALT", str(int(summary.get("damage_dealt", 0)))],
		["DAMAGE TAKEN", str(int(summary.get("damage_taken", 0)))],
		["RELICS TAKEN", str(int(summary.get("relics", 0)))],
		["SEED", str(int(summary.get("seed", 0)))],
	]
	for i in range(rows.size()):
		var row: Array = rows[i]
		var y := 22.0 + i * 18.0
		var key := UI.label(String(row[0]), 7, UI.MUTED, "header")
		key.position = Vector2(14, y)
		key.size = Vector2(200, 12)
		panel.add_child(key)
		var value := UI.label(String(row[1]), 9, UI.BONE, "body")
		value.position = Vector2(202, y - 1)
		value.size = Vector2(132, 14)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		panel.add_child(value)
		if i < rows.size() - 1:
			UI.separator(panel, 14, y + 15, 320)

	var skull := UI.icon("res://assets/generated/skull_icon.png", 20)
	skull.position = Vector2(238, 286)
	add_child(skull)

	var bone_line := UI.shadowed(UI.label("BONE COINS   +%d" % earned, 10, UI.GOLD, "header"))
	bone_line.position = Vector2(264, 284)
	bone_line.size = Vector2(220, 14)
	add_child(bone_line)

	var total_line := UI.label("VAULT TOTAL   %d" % total_bones, 7, UI.MUTED, "header")
	total_line.position = Vector2(264, 299)
	total_line.size = Vector2(220, 12)
	add_child(total_line)

	again_button = UI.button("RUN AGAIN", 9, 180, 34)
	again_button.position = Vector2(152, 316)
	again_button.pressed.connect(_again)
	add_child(again_button)

	var title_button := UI.button("TITLE", 9, 140, 34)
	title_button.position = Vector2(348, 316)
	title_button.pressed.connect(_to_title)
	add_child(title_button)

	again_button.grab_focus()
	_celebrate(victory)

	if not main.fast:
		title.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(title, "modulate:a", 1.0, 0.25)


func _celebrate(victory: bool) -> void:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.explosiveness = 0.9
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(250, 4)
	p.direction = Vector2(0, 1)
	p.spread = 22.0
	p.lifetime = 1.5
	p.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if victory:
		p.position = Vector2(320, 100)
		p.amount = 26
		p.gravity = Vector2(0, 130)
		p.initial_velocity_min = 14.0
		p.initial_velocity_max = 60.0
		p.scale_amount_min = 0.25
		p.scale_amount_max = 0.55
		p.texture = load("res://assets/generated/coin_particle.png")
		p.color = Color(1.0, 0.9, 0.6, 0.95)
		add_child(p)
		p.restart()
		Sfx.play("bell", 0.72, -2.0)
		Sfx.play("coin", 0.8, -5.0)
	else:
		p.position = Vector2(320, 340)
		p.amount = 14
		p.direction = Vector2(0, -1)
		p.spread = 38.0
		p.gravity = Vector2(0, -6)
		p.initial_velocity_min = 8.0
		p.initial_velocity_max = 32.0
		p.scale_amount_min = 0.4
		p.scale_amount_max = 1.1
		p.lifetime = 1.2
		p.texture = load("res://assets/generated/spark.png")
		p.color = Color(0.75, 0.12, 0.1, 0.8)
		add_child(p)
		p.restart()
		Sfx.play("boom", 0.62, -5.0)


func _again() -> void:
	Sfx.play("click")
	main.start_run()


func _to_title() -> void:
	Sfx.play("click")
	main.show_title()


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.is_pressed() or event.is_echo():
		return
	var key := (event as InputEventKey).keycode
	if key == KEY_R:
		_again()
		get_viewport().set_input_as_handled()
	elif key == KEY_ESCAPE:
		_to_title()
		get_viewport().set_input_as_handled()
