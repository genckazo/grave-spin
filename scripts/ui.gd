class_name UI
extends RefCounted
## Look and feel helpers. Every pixel here is drawn at the 640x360 game scale.

const GOLD := Color("e6b34a")
const GOLD_HI := Color("f6d27a")
const BONE := Color("e8ddc2")
const MUTED := Color("9a8fa8")
const DIM := Color("6b6178")
const RED := Color("cf4b45")
const BLOOD := Color("b3392f")
const GREEN := Color("63c26e")
const BLUE := Color("6f9ed6")
const PURPLE := Color("a879d6")
const INK := Color("0a080e")

static var _fonts: Dictionary = {}


static func font(kind: String) -> Font:
	if _fonts.has(kind):
		return _fonts[kind]
	var path := "res://assets/fonts/PixelifySans-Variable.ttf"
	match kind:
		"header":
			path = "res://assets/fonts/Silkscreen-Regular.ttf"
		"header_bold":
			path = "res://assets/fonts/Silkscreen-Bold.ttf"
		"title":
			path = "res://assets/fonts/PirataOne-Regular.ttf"
	var f = load(path)
	_fonts[kind] = f
	return f


static func label(text: String, size: int = 9, color: Color = BONE, kind: String = "body") -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font(kind))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func shadowed(l: Label, color: Color = Color(0, 0, 0, 0.8), off: int = 1) -> Label:
	l.add_theme_color_override("font_shadow_color", color)
	l.add_theme_constant_override("shadow_offset_x", off)
	l.add_theme_constant_override("shadow_offset_y", off)
	return l


static func centered(l: Label) -> Label:
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


static func style(path: String, margin: int = 8, content: int = 8) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = load(path)
	sb.texture_margin_left = margin
	sb.texture_margin_right = margin
	sb.texture_margin_top = margin
	sb.texture_margin_bottom = margin
	sb.content_margin_left = content
	sb.content_margin_right = content
	sb.content_margin_top = content
	sb.content_margin_bottom = content
	return sb


static func panel(style_path: String = "res://assets/generated/ui_panel.png", content: int = 8) -> Panel:
	var p := Panel.new()
	p.add_theme_stylebox_override("panel", style(style_path, 8, content))
	return p


static func button(text: String, size: int = 10, min_width: int = 0, min_height: int = 30) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_ALL
	b.custom_minimum_size = Vector2(min_width, min_height)
	b.add_theme_font_override("font", font("header_bold"))
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", BONE)
	b.add_theme_color_override("font_hover_color", GOLD_HI)
	b.add_theme_color_override("font_focus_color", GOLD_HI)
	b.add_theme_color_override("font_pressed_color", GOLD)
	b.add_theme_color_override("font_disabled_color", DIM)
	b.add_theme_stylebox_override("normal", style("res://assets/generated/ui_button.png", 8, 5))
	b.add_theme_stylebox_override("hover", style("res://assets/generated/ui_button_hover.png", 8, 5))
	b.add_theme_stylebox_override("focus", style("res://assets/generated/ui_button_hover.png", 8, 5))
	b.add_theme_stylebox_override("pressed", style("res://assets/generated/ui_button_pressed.png", 8, 5))
	b.add_theme_stylebox_override("disabled", style("res://assets/generated/ui_button_disabled.png", 8, 5))
	return b


static func texture(path: String, w: int, h: int) -> TextureRect:
	var t := TextureRect.new()
	t.texture = load(path)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.custom_minimum_size = Vector2(w, h)
	t.size = Vector2(w, h)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


static func icon(path: String, size: int) -> TextureRect:
	return texture(path, size, size)


static func place(node: Control, x: float, y: float, w: float, h: float) -> void:
	node.position = Vector2(x, y)
	node.size = Vector2(w, h)


static func separator(parent: Control, x: float, y: float, w: float) -> void:
	var line := ColorRect.new()
	line.color = Color(0.55, 0.42, 0.22, 0.55)
	line.position = Vector2(x, y)
	line.size = Vector2(w, 1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(line)


static func hp_bar(x: float, y: float, w: float, h: float, fill_color: Color) -> Dictionary:
	var bg := Panel.new()
	bg.add_theme_stylebox_override("panel", style("res://assets/generated/ui_panel.png", 8, 0))
	bg.position = Vector2(x, y)
	bg.size = Vector2(w, h)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := ColorRect.new()
	fill.color = fill_color
	fill.position = Vector2(2, 2)
	fill.size = Vector2(w - 4, h - 4)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(fill)
	return {"frame": bg, "fill": fill, "width": w - 4}


static func set_bar(bar: Dictionary, ratio: float) -> void:
	var f: ColorRect = bar["fill"]
	f.size.x = max(0.0, float(bar["width"]) * clamp(ratio, 0.0, 1.0))


static func rarity_color(rarity: String) -> Color:
	match rarity:
		"rare": return BLUE
		"cursed": return RED
		_: return BONE


static func kind_color(kind: String) -> Color:
	match kind:
		"gold": return GOLD
		"good": return GREEN
		"red": return RED
		"cursed": return PURPLE
		"blue": return BLUE
		"muted": return MUTED
		"bone": return BONE
		_: return BONE
