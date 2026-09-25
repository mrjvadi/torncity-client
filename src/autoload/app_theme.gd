extends Node
## The look: palette (assets/art/palette.json — the same file the art generator
## reads), fonts (Vazirmatn, OFL), the Godot Theme for every Control, and the
## art resolver.
##
## Art is looked up through assets/art/manifest.json ("slot" -> file), so an
## artist's replacement is a file drop plus, at most, a one-line manifest edit —
## never a code change. Missing art falls back to a neutral placeholder.

const PALETTE_PATH := "res://assets/art/palette.json"
const MANIFEST_PATH := "res://assets/art/manifest.json"
const FONT_DIR := "res://assets/fonts/vazirmatn/"

## Base font sizes, in design pixels (720 x 1280 portrait).
const SIZE_BODY := 26
const SIZE_SMALL := 21
const SIZE_TITLE := 34
const SIZE_HUGE := 52

var C := {}               # colour name -> Color
var font_regular: Font
var font_medium: Font
var font_bold: Font
var font_black: Font
var theme: Theme
var manifest := {}
var _tex_cache := {}


func _ready() -> void:
	_load_palette()
	_load_fonts()
	_load_manifest()
	theme = _build_theme()
	get_tree().root.theme = theme


func col(name: String, alpha := 1.0) -> Color:
	var c: Color = C.get(name, Color.MAGENTA)
	c.a = alpha
	return c


# -- palette & fonts ----------------------------------------------------------------------
func _load_palette() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string(PALETTE_PATH))
	if data is Dictionary:
		for k in data.get("colors", {}):
			C[k] = Color(data["colors"][k])


func _font(file: String) -> Font:
	var f: FontFile = load(FONT_DIR + file)
	if f == null:
		return ThemeDB.fallback_font
	# Persian needs the advanced text server's shaping (HarfBuzz); it is the
	# default on every platform we export to. Keep hinting light for crisp
	# glyphs when the canvas is scaled.
	f.hinting = TextServer.HINTING_LIGHT
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
	f.generate_mipmaps = true
	return f


func _load_fonts() -> void:
	font_regular = _font("Vazirmatn-Regular.woff2")
	font_medium = _font("Vazirmatn-Medium.woff2")
	font_bold = _font("Vazirmatn-Bold.woff2")
	font_black = _font("Vazirmatn-Black.woff2")


# -- art ----------------------------------------------------------------------------------
func _load_manifest() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	manifest = data if data is Dictionary else {}


## The file for an art slot like "icon/energy", "place/bazaar", "avatar/fox".
func art_path(slot: String) -> String:
	var parts := slot.split("/", true, 1)
	var group: Dictionary = manifest.get(parts[0], {})
	if parts.size() > 1:
		var direct = group.get(parts[1])
		if direct is String and ResourceLoader.exists(direct):
			return direct
		# "*" is a pattern or a list of patterns tried in order (e.g. a rendered
		# PNG first, the vector original second).
		var patterns = group.get("*", [])
		if patterns is String:
			patterns = [patterns]
		for pattern in patterns:
			var p := str(pattern).replace("{code}", parts[1])
			if ResourceLoader.exists(p):
				return p
		var fb = group.get("_fallback")
		if fb is String and ResourceLoader.exists(fb):
			return fb
	return ""


func tex(slot: String) -> Texture2D:
	if _tex_cache.has(slot):
		return _tex_cache[slot]
	var p := art_path(slot)
	var t: Texture2D = load(p) if p != "" else null
	_tex_cache[slot] = t
	return t


func icon(name: String) -> Texture2D:
	return tex("icon/" + name)


func icon_path(name: String) -> String:
	return art_path("icon/" + name)


# -- style boxes ----------------------------------------------------------------------------
func box(bg: Color, radius := 22, border := Color(0, 0, 0, 0), border_w := 0, shadow := 0, pad := 18) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.corner_detail = 10
	sb.anti_aliasing = true
	sb.anti_aliasing_size = 1.0
	if border_w > 0:
		sb.border_color = border
		sb.set_border_width_all(border_w)
	if shadow > 0:
		sb.shadow_color = Color(C.get("ink", Color.BLACK), 0.45)
		sb.shadow_size = shadow
		sb.shadow_offset = Vector2(0, shadow * 0.45)
	sb.set_content_margin_all(pad)
	return sb


## A raised button face: a darker lip underneath gives it depth; pressed, the lip goes.
func button_box(face: Color, pressed := false, radius := 20) -> StyleBoxFlat:
	var sb := box(face, radius)
	sb.border_color = face.darkened(0.32)
	sb.border_width_bottom = 2 if pressed else 6
	sb.border_width_top = 4 if pressed else 0
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	sb.shadow_color = Color(C.get("ink", Color.BLACK), 0.35 if not pressed else 0.2)
	sb.shadow_size = 6 if not pressed else 2
	sb.shadow_offset = Vector2(0, 3 if not pressed else 1)
	return sb


func _build_theme() -> Theme:
	var t := Theme.new()
	t.default_font = font_regular
	t.default_font_size = SIZE_BODY

	var text := col("text")
	var dim := col("text_dim")

	# Label and its variations
	t.set_color("font_color", "Label", text)
	t.set_constant("line_spacing", "Label", 6)
	for v in [["TitleLabel", font_black, SIZE_TITLE, text], ["HeadLabel", font_bold, 28, text],
			["DimLabel", font_regular, SIZE_SMALL, dim], ["SmallLabel", font_medium, SIZE_SMALL, text],
			["HugeLabel", font_black, SIZE_HUGE, text], ["MoneyLabel", font_bold, 30, col("saffron")]]:
		t.set_type_variation(v[0], "Label")
		t.set_font(&"font", v[0], v[1])
		t.set_font_size(&"font_size", v[0], v[2])
		t.set_color(&"font_color", v[0], v[3])

	# RichTextLabel (server text)
	t.set_font("normal_font", "RichTextLabel", font_regular)
	t.set_font("bold_font", "RichTextLabel", font_bold)
	t.set_font_size("normal_font_size", "RichTextLabel", SIZE_BODY)
	t.set_font_size("bold_font_size", "RichTextLabel", SIZE_BODY)
	t.set_color("default_color", "RichTextLabel", text)
	t.set_constant("line_separation", "RichTextLabel", 10)

	# Buttons: primary (turquoise), and variations
	_button_style(t, "Button", col("turquoise"), col("ink"))
	_button_style(t, "GhostButton", col("panel_hi"), text)
	_button_style(t, "GoldButton", col("saffron"), col("ink"))
	_button_style(t, "DangerButton", col("pomegranate"), col("white"))
	_button_style(t, "ActionButton", col("panel_hi"), text)
	t.set_font("font", "Button", font_bold)
	t.set_font_size("font_size", "Button", SIZE_BODY)
	t.set_constant("h_separation", "Button", 12)
	t.set_constant("icon_max_width", "Button", 40)

	# Nav button: flat, the shell draws the highlight
	t.set_type_variation("NavButton", "Button")
	for st in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		var e := StyleBoxEmpty.new()
		t.set_stylebox(st, "NavButton", e)
	t.set_font("font", "NavButton", font_medium)
	t.set_font_size("font_size", "NavButton", 19)
	t.set_color("font_color", "NavButton", dim)
	t.set_color("font_pressed_color", "NavButton", col("turquoise"))
	t.set_color("font_hover_color", "NavButton", text)
	t.set_color("font_focus_color", "NavButton", dim)
	t.set_color("font_hover_pressed_color", "NavButton", col("turquoise"))

	# Panels
	t.set_stylebox("panel", "PanelContainer", box(col("panel"), 26, col("line"), 1, 14, 22))
	t.set_type_variation("CardPanel", "PanelContainer")
	t.set_stylebox("panel", "CardPanel", box(col("panel"), 26, col("line", 0.8), 1, 16, 24))
	t.set_type_variation("InsetPanel", "PanelContainer")
	t.set_stylebox("panel", "InsetPanel", box(col("night"), 18, col("line", 0.6), 1, 0, 16))
	t.set_type_variation("ChipPanel", "PanelContainer")
	t.set_stylebox("panel", "ChipPanel", box(col("panel_hi"), 40, Color(0, 0, 0, 0), 0, 0, 10))
	t.set_type_variation("ToastPanel", "PanelContainer")
	t.set_stylebox("panel", "ToastPanel", box(col("panel_hi"), 22, col("turquoise", 0.8), 2, 18, 18))

	# LineEdit
	var le := box(col("night"), 18, col("line"), 2, 0, 18)
	var le_focus := box(col("night"), 18, col("turquoise"), 2, 0, 18)
	t.set_stylebox("normal", "LineEdit", le)
	t.set_stylebox("focus", "LineEdit", le_focus)
	t.set_stylebox("read_only", "LineEdit", le)
	t.set_font("font", "LineEdit", font_bold)
	t.set_font_size("font_size", "LineEdit", 34)
	t.set_color("font_color", "LineEdit", text)
	t.set_color("font_placeholder_color", "LineEdit", Color(dim, 0.6))
	t.set_color("caret_color", "LineEdit", col("turquoise"))
	t.set_color("selection_color", "LineEdit", col("turquoise", 0.35))

	# ProgressBar (vitals)
	var pb_bg := box(col("ink", 0.7), 10, Color(0, 0, 0, 0), 0, 0, 0)
	var pb_fill := box(col("turquoise"), 10, Color(0, 0, 0, 0), 0, 0, 0)
	t.set_stylebox("background", "ProgressBar", pb_bg)
	t.set_stylebox("fill", "ProgressBar", pb_fill)
	t.set_constant("outline_size", "ProgressBar", 0)

	# Scrolling
	var grab := box(col("line"), 6, Color(0, 0, 0, 0), 0, 0, 0)
	t.set_stylebox("grabber", "VScrollBar", grab)
	t.set_stylebox("grabber_highlight", "VScrollBar", grab)
	t.set_stylebox("grabber_pressed", "VScrollBar", grab)
	var sc := StyleBoxFlat.new()
	sc.bg_color = Color(0, 0, 0, 0)
	sc.content_margin_left = 6
	t.set_stylebox("scroll", "VScrollBar", sc)

	t.set_constant("separation", "VBoxContainer", 14)
	t.set_constant("separation", "HBoxContainer", 12)
	return t


func _button_style(t: Theme, type: String, face: Color, fg: Color) -> void:
	if type != "Button":
		t.set_type_variation(type, "Button")
	t.set_stylebox("normal", type, button_box(face))
	t.set_stylebox("hover", type, button_box(face.lightened(0.07)))
	t.set_stylebox("pressed", type, button_box(face.darkened(0.06), true))
	t.set_stylebox("hover_pressed", type, button_box(face.darkened(0.06), true))
	t.set_stylebox("focus", type, StyleBoxEmpty.new())
	var dis := button_box(face.darkened(0.45))
	t.set_stylebox("disabled", type, dis)
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(k, type, fg)
	t.set_color("font_disabled_color", type, Color(fg, 0.45))
	t.set_color("icon_normal_color", type, Color.WHITE)
	t.set_color("icon_pressed_color", type, Color.WHITE)
	t.set_color("icon_hover_color", type, Color.WHITE)
	t.set_color("icon_focus_color", type, Color.WHITE)
