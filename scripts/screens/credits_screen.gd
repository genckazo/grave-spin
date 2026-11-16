class_name CreditsScreen
extends Control

var main
var back_button: Button
var screen_id := "credits"


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	screen_id = "credits"

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.015, 0.03, 0.88)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var panel := UI.panel()
	panel.position = Vector2(36, 10)
	panel.size = Vector2(568, 340)
	add_child(panel)

	var heading := UI.centered(UI.shadowed(UI.label("CREDITS", 34, UI.GOLD, "title")))
	heading.position = Vector2(0, 4)
	heading.size = Vector2(568, 38)
	panel.add_child(heading)

	var body := RichTextLabel.new()
	body.bbcode_enabled = true
	body.scroll_active = true
	body.scroll_following = false
	body.position = Vector2(20, 44)
	body.size = Vector2(528, 252)
	body.add_theme_font_override("normal_font", UI.font("body"))
	body.add_theme_font_size_override("normal_font_size", 8)
	body.add_theme_font_override("bold_font", UI.font("header_bold"))
	body.add_theme_font_size_override("bold_font_size", 8)
	body.add_theme_color_override("default_color", UI.BONE)
	body.add_theme_constant_override("line_separation", 3)
	var gold := UI.GOLD.to_html(false).substr(0, 6)
	var muted := UI.MUTED.to_html(false).substr(0, 6)
	body.text = (
		"[b]GRAVE SPIN[/b] — demo slice, built November 2026.\n"
		+ "[color=#%s]Design, code, slot machine art, skeleton and UI frames:[/color] original work for this project, released CC0 1.0.\n\n" % muted
		+ "[b]ART (CC0 1.0)[/b]\n"
		+ "Kenney — Tiny Dungeon, Board Game Icons. kenney.nl\n"
		+ "The slime and cultist sprites, wall tiles and several icon shapes are Kenney assets, recoloured or recomposed.\n\n"
		+ "[b]SOUND (CC0 1.0)[/b]\n"
		+ "Kenney — Casino Audio, RPG Audio, Interface Sounds, Impact Sounds, Sci-Fi Sounds. kenney.nl\n\n"
		+ "[b]MUSIC (CC BY 4.0)[/b]\n"
		+ "“8bit Dungeon Level” by Kevin MacLeod (incompetech.com), licensed CC BY 4.0. Loop edited for this game.\n\n"
		+ "[b]FONTS (SIL OPEN FONT LICENSE 1.1)[/b]\n"
		+ "Pirata One (Rodrigo Fuenzalida), Silkscreen (Jason Kottke), Pixelify Sans (Stefie Justprince). Via Google Fonts.\n\n"
		+ "[color=#%s]Full licence texts ship in LICENSES/ and assets/fonts/.[/color]" % muted
	)
	panel.add_child(body)

	back_button = UI.button("BACK", 9, 140, 28)
	back_button.position = Vector2(214, 304)
	back_button.pressed.connect(_back)
	panel.add_child(back_button)
	back_button.grab_focus()


func _back() -> void:
	Sfx.play("click")
	main.show_title()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_pressed() and not event.is_echo():
		if event is InputEventKey and (event.keycode == KEY_ESCAPE or event.keycode == KEY_ENTER or event.keycode == KEY_SPACE):
			_back()
			get_viewport().set_input_as_handled()
