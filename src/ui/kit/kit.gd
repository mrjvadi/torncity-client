class_name Kit
extends RefCounted
## The game's chrome kit: the lit frames, bars, rings, embossed icons and
## gradient lettering the home screen was designed with (proto/), as pieces
## any screen can place. Each piece is laid out in its parent's own pixels,
## left to right: a layout that already reads right to left is built that way
## on purpose, so Godot does not mirror it a second time.

const ICONS := "res://assets/kit/icons/"

const GOLD := Color("#F2C255")
const FIROUZEH := Color("#2BC4B2")
const LAPIS := Color("#3552C8")
const SAFFRON := Color("#F5A623")
const ANAR := Color("#E5484D")
const LEAF := Color("#4CC47E")
const VIOLET := Color("#8E6CF0")
const INK := Color("#070A14")

## Emboss palettes: light, dark, outline.
const PAL := {
	"gold": ["#FFF3B0", "#D97C00", "#3A1C00"],
	"amber": ["#FFF08A", "#E07000", "#3A1600"],
	"ruby": ["#FFB0B4", "#B3121E", "#3A0006"],
	"emerald": ["#C4FFD2", "#1E8F4A", "#03250F"],
	"sapphire": ["#CFE0FF", "#2A4BC8", "#050C33"],
	"violet": ["#E6DAFF", "#6A3FD0", "#1A0A3D"],
	"steel": ["#F4F7FF", "#7C86A6", "#12161F"],
	"fox": ["#FFD9AE", "#E0561B", "#3A1200"],
	"teal": ["#E6FFFB", "#2BC4B2", "#042A26"],
	"cream": ["#FFFFFF", "#FFEFCF", "#5A2E00"],
}

static var _shaders := {}
static var display_font: Font
static var body_font: Font
static var body_bold: Font


static func fonts() -> void:
	if display_font == null:
		display_font = load("res://assets/fonts/lalezar/Lalezar-Regular.ttf")
		body_font = load("res://assets/fonts/vazirmatn/Vazirmatn-Medium.woff2")
		body_bold = load("res://assets/fonts/vazirmatn/Vazirmatn-Black.woff2")


static func mat(name: String) -> ShaderMaterial:
	if not _shaders.has(name):
		_shaders[name] = load("res://src/ui/kit/%s.gdshader" % name)
	var m := ShaderMaterial.new()
	m.shader = _shaders[name]
	return m


static func icon(name: String) -> Texture2D:
	var path := ICONS + "%s.svg" % name
	return load(path) if ResourceLoader.exists(path) else load(ICONS + "person.svg")


static func _ltr(c: Control, r: Rect2, parent: Node) -> void:
	c.layout_direction = Control.LAYOUT_DIRECTION_LTR
	c.position = r.position
	c.size = r.size
	if parent:
		parent.add_child(c)


## A lit panel: a vertical gradient, a trim line, a soft shadow around it.
## Children go in inner(frame), which spans the panel's own rect.
static func frame(parent: Node, r: Rect2, radius: float, top: Color, bottom: Color, trim: Color, pattern := 0.0, trim_w := 3.0) -> ColorRect:
	var margin := 16.0
	var c := ColorRect.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ltr(c, Rect2(r.position - Vector2(margin, margin), r.size + Vector2(margin, margin) * 2.0), parent)
	var m := mat("frame")
	m.set_shader_parameter("size", c.size)
	m.set_shader_parameter("radius", radius)
	m.set_shader_parameter("margin", margin)
	m.set_shader_parameter("fill_top", top)
	m.set_shader_parameter("fill_bottom", bottom)
	m.set_shader_parameter("trim", trim)
	m.set_shader_parameter("trim_w", trim_w)
	m.set_shader_parameter("pattern", pattern)
	c.material = m
	var box := Control.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ltr(box, Rect2(Vector2(margin, margin), r.size), c)
	c.set_meta("inner", box)
	return c


static func inner(f: ColorRect) -> Control:
	return f.get_meta("inner")


## A chunky pressable slab: a gradient face over a darker lip.
static func slab(parent: Node, r: Rect2, top: Color, bottom: Color, lip: Color, radius: float, lip_h: float) -> ColorRect:
	var c := ColorRect.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ltr(c, r, parent)
	var m := mat("button")
	m.set_shader_parameter("size", r.size)
	m.set_shader_parameter("radius", radius)
	m.set_shader_parameter("top", top)
	m.set_shader_parameter("bottom", bottom)
	m.set_shader_parameter("lip", lip)
	m.set_shader_parameter("lip_h", lip_h)
	c.material = m
	return c


## A round (or rounded-square) plate with a rim; the glyph hidden when the
## plate only backs an embossed icon.
static func plate(parent: Node, r: Rect2, tint: Color, rim: Color, square := 0.0) -> TextureRect:
	var t := TextureRect.new()
	t.texture = icon("person")
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ltr(t, r, parent)
	var m := mat("badge")
	m.set_shader_parameter("tint", tint)
	m.set_shader_parameter("rim", rim)
	m.set_shader_parameter("square", square)
	m.set_shader_parameter("glyph_color", Color(0, 0, 0, 0))
	t.material = m
	return t


## A value bar with a lit fill, filling from the right.
static func bar(parent: Node, r: Rect2, value: float, fill: Color, full := false) -> ColorRect:
	var c := ColorRect.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ltr(c, r, parent)
	var m := mat("bar")
	m.set_shader_parameter("size", r.size)
	m.set_shader_parameter("value", clampf(value, 0.0, 1.0))
	m.set_shader_parameter("fill", fill)
	m.set_shader_parameter("full", 1.0 if full else 0.0)
	m.set_shader_parameter("outline", Color(GOLD, 0.75))
	c.material = m
	return c


static func set_bar(b: ColorRect, value: float, full := false) -> void:
	var m := b.material as ShaderMaterial
	m.set_shader_parameter("value", clampf(value, 0.0, 1.0))
	m.set_shader_parameter("full", 1.0 if full else 0.0)


## A progress ring.
static func ring(parent: Node, r: Rect2, value: float, color: Color) -> ColorRect:
	var c := ColorRect.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ltr(c, r, parent)
	var m := mat("ring")
	m.set_shader_parameter("value", clampf(value, 0.0, 1.0))
	m.set_shader_parameter("color", color)
	c.material = m
	return c


## An icon struck in metal: a bevel, a highlight, an outline.
static func emboss(parent: Node, name: String, r: Rect2, pal: String) -> TextureRect:
	var t := TextureRect.new()
	t.texture = icon(name)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ltr(t, r, parent)
	var m := mat("emboss")
	var c: Array = PAL.get(pal, PAL["gold"])
	m.set_shader_parameter("light_c", Color(c[0]))
	m.set_shader_parameter("dark_c", Color(c[1]))
	m.set_shader_parameter("outline_c", Color(c[2]))
	t.material = m
	return t


static func label(parent: Node, text: String, font: Font, px: int, color: Color, r: Rect2, align: int, outline := 0) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.text_direction = Control.TEXT_DIRECTION_AUTO
	l.clip_text = true
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", px)
	l.add_theme_color_override("font_color", color)
	if outline > 0:
		l.add_theme_constant_override("outline_size", outline)
		l.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.08, 0.95))
		l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
		l.add_theme_constant_override("shadow_offset_y", 3)
		l.add_theme_constant_override("shadow_offset_x", 0)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ltr(l, r, parent)
	return l


## Lettering with a vertical gradient, in the display face.
static func glabel(parent: Node, text: String, px: int, top: String, bottom: String, r: Rect2, align: int, outline := 6) -> Label:
	fonts()
	var l := label(parent, text, display_font, px, Color.WHITE, r, align, outline)
	var m := mat("grad_text")
	m.set_shader_parameter("top_c", Color(top))
	m.set_shader_parameter("bottom_c", Color(bottom))
	m.set_shader_parameter("y0", (r.size.y - px) / 2.0)
	m.set_shader_parameter("h", px * 1.05)
	l.material = m
	return l


## A small red count on a slab.
static func count(parent: Node, r: Rect2, n: int) -> ColorRect:
	fonts()
	var b := slab(parent, r, ANAR.lightened(0.2), ANAR, ANAR.darkened(0.5), r.size.y / 2.0, 3.0)
	label(b, str(n) if n < 100 else "99+", display_font, 20, Color.WHITE, Rect2(0, -2, r.size.x, r.size.y), HORIZONTAL_ALIGNMENT_CENTER, 4)
	return b


## A vertical fade, for the shade behind the chrome.
static func fade(parent: Node, r: Rect2, a: Color, b: Color) -> TextureRect:
	var g := Gradient.new()
	g.set_color(0, a)
	g.set_color(1, b)
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0.5, 0)
	gt.fill_to = Vector2(0.5, 1)
	gt.width = 4
	gt.height = 128
	var t := TextureRect.new()
	t.texture = gt
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ltr(t, r, parent)
	return t


## An invisible hit area over a drawn piece, for a tap.
static func hit(parent: Node, r: Rect2, fn: Callable) -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	c.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_ltr(c, r, parent)
	c.gui_input.connect(func(e):
		if (e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed) or (e is InputEventScreenTouch and not e.pressed):
			if Rect2(Vector2.ZERO, c.size).has_point(e.position):
				fn.call()
	)
	return c
