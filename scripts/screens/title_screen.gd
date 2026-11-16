class_name TitleScreen
extends Control

var main
var meta: Dictionary = {}
var overlay: Control
var start_button: Button
var screen_id := "title"


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_id = "title"
	mouse_filter = Control.MOUSE_FILTER_STOP

	var logo := UI.texture("res://assets/generated/logo.png", 620, 132)
	logo.position = Vector2(10, 8)
	add_child(logo)

	var tag := UI.centered(UI.label("PULL. DIE. PULL AGAIN.", 8, UI.MUTED, "header"))
	tag.position = Vector2(0, 146)
	tag.size = Vector2(640, 14)
	add_child(tag)

	UI.separator(self, 200, 168, 240)

	start_button = UI.button("START RUN", 10, 200, 32)
	start_button.position = Vector2(220, 182)
	start_button.pressed.connect(_on_start)
	add_child(start_button)

	var how := UI.button("HOW TO PLAY", 10, 200, 32)
	how.position = Vector2(220, 222)
	how.pressed.connect(_show_how)
	add_child(how)

	var credits := UI.button("CREDITS", 10, 200, 32)
	credits.position = Vector2(220, 262)
	credits.pressed.connect(_on_credits)
	add_child(credits)

	var quit := UI.button("QUIT", 10, 200, 32)
	quit.position = Vector2(220, 302)
	quit.pressed.connect(func(): get_tree().quit())
	add_child(quit)

	var skull := UI.icon("res://assets/generated/skull_icon.png", 18)
	skull.position = Vector2(16, 330)
	add_child(skull)
	var bones := UI.label("BONE COINS  %d" % int(meta.get("bone_coins", 0)), 8, UI.GOLD, "header")
	bones.position = Vector2(38, 331)
	add_child(bones)

	var best_text := "BEST RUN  %d/5" % int(meta.get("best_fights", 0))
	if bool(meta.get("best_victory", false)):
		best_text = "BEST RUN  CLEARED"
	var best := UI.label(best_text, 7, UI.DIM, "header")
	best.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	best.position = Vector2(430, 332)
	best.size = Vector2(194, 12)
	add_child(best)

	var v := UI.centered(UI.label("DEMO SLICE  ·  v0.1", 6, UI.DIM, "header"))
	v.position = Vector2(0, 346)
	v.size = Vector2(640, 10)
	add_child(v)

	start_button.grab_focus()


func _on_start() -> void:
	Sfx.play("click")
	main.start_run()


func _on_credits() -> void:
	Sfx.play("click")
	main.show_credits()


func _show_how() -> void:
	if overlay != null:
		return
	Sfx.play("card")
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.015, 0.03, 0.84)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)

	var panel := UI.panel()
	panel.position = Vector2(90, 42)
	panel.size = Vector2(460, 278)
	overlay.add_child(panel)

	var heading := UI.centered(UI.shadowed(UI.label("HOW TO PLAY", 30, UI.GOLD, "title")))
	heading.position = Vector2(0, 10)
	heading.size = Vector2(460, 36)
	panel.add_child(heading)

	var body := RichTextLabel.new()
	body.bbcode_enabled = true
	body.fit_content = false
	body.scroll_active = false
	body.position = Vector2(26, 52)
	body.size = Vector2(408, 172)
	body.add_theme_font_override("normal_font", UI.font("body"))
	body.add_theme_font_size_override("normal_font_size", 9)
	body.add_theme_font_override("bold_font", UI.font("header_bold"))
	body.add_theme_font_size_override("bold_font_size", 8)
	body.add_theme_color_override("default_color", UI.BONE)
	body.add_theme_constant_override("line_separation", 4)
	var gold := UI.GOLD.to_html(false).substr(0, 6)
	var muted := UI.MUTED.to_html(false).substr(0, 6)
	var red := UI.RED.to_html(false).substr(0, 6)
	var blue := UI.BLUE.to_html(false).substr(0, 6)
	var green := UI.GREEN.to_html(false).substr(0, 6)
	body.text = (
		"[b]The reels are your sword.[/b]\n"
		+ "[color=#%s]Press SPACE or click the lever.[/color] Every pull spins 3 rows.\n\n" % gold
		+ "[color=#%s]Swords[/color] strike. [color=#%s]Shields[/color] block. [color=#%s]Potions[/color] heal.\n" % [BONE_HEX(), blue, green]
		+ "[color=#%s]Coins[/color] pay out. [color=#%s]Skulls[/color] add +2 to the enemy's attack.\n\n" % [gold, red]
		+ "Win a fight and take 1 of 3 relics. Draft them into a build.\n"
		+ "Survive 5 fights. Die and bank Bone Coins for the next run.\n\n"
		+ "[color=#%s]The house is patient. The machine is not.[/color]" % muted
	)
	panel.add_child(body)

	var close := UI.button("BACK", 9, 140, 30)
	close.position = Vector2(160, 232)
	close.pressed.connect(_close_how)
	panel.add_child(close)
	close.grab_focus()


func BONE_HEX() -> String:
	return UI.BONE.to_html(false).substr(0, 6)


func _close_how() -> void:
	if overlay != null:
		overlay.queue_free()
		overlay = null
		start_button.grab_focus()


func _unhandled_key_input(event: InputEvent) -> void:
	if overlay != null and event.is_pressed() and not event.is_echo():
		if event is InputEventKey and (event.keycode == KEY_ESCAPE or event.keycode == KEY_ENTER or event.keycode == KEY_SPACE):
			_close_how()
			get_viewport().set_input_as_handled()
