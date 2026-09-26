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

## Type scale, in design pixels (720 x 1280 portrait). See docs/design-system.md.
const SIZE_CAPTION := 18
const SIZE_SMALL := 21
const SIZE_BODY := 25
const SIZE_HEAD := 28
const SIZE_TITLE := 34
const SIZE_HUGE := 50

## Corner radii: cards, controls (buttons, inputs), small pieces (chips, badges).
const R_CARD := 24
const R_CONTROL := 18
const R_SMALL := 12

## Spacing: the screen gutter and the gap between cards.
const GUTTER := 24
const GAP := 16

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
		# the interface's tokens win over the art's colours of the same name
		for k in data.get("ui", {}):
			C[k] = Color(data["ui"][k])
	# older interface names, kept so nothing asks for a colour that is gone
	for pair in [["night", "bg"], ["panel", "surface"], ["panel_hi", "surface_2"], ["line", "stroke"], ["text_dim", "text_2"]]:
		if C.has(pair[1]):
			C[pair[0]] = C[pair[1]]


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


## The app's background: a quiet vertical gradient, lighter at the top.
func backdrop() -> TextureRect:
	var g := Gradient.new()
	g.set_color(0, col("bg_top"))
	g.set_color(1, col("bg"))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0.5, 0.0)
	gt.fill_to = Vector2(0.5, 0.6)
	gt.width = 8
	gt.height = 256
	var r := TextureRect.new()
	r.texture = gt
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


# -- style boxes ----------------------------------------------------------------------------
func box(bg: Color, radius := R_CARD, border := Color(0, 0, 0, 0), border_w := 0, shadow := 0, pad := 18) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.corner_detail = 12
	sb.anti_aliasing = true
	sb.anti_aliasing_size = 1.0
	if border_w > 0:
		sb.border_color = border
		sb.set_border_width_all(border_w)
	if shadow > 0:
		sb.shadow_color = Color(0, 0, 0, 0.35)
		sb.shadow_size = shadow
		sb.shadow_offset = Vector2(0, shadow * 0.4)
	sb.set_content_margin_all(pad)
	return sb


## A button face: flat, with a faint lighter top edge; pressed it darkens and
## the edge goes. `face` is the fill, `edge` an optional 1 px border.
func button_box(face: Color, pressed := false, radius := R_CONTROL, edge := Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var sb := box(face, radius)
	if edge.a > 0:
		sb.border_color = edge
		sb.set_border_width_all(1)
	elif not pressed:
		sb.border_color = face.lightened(0.18)
		sb.border_width_top = 1
	sb.border_blend = false
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	return sb


func _build_theme() -> Theme:
	var t := Theme.new()
	t.default_font = font_regular
	t.default_font_size = SIZE_BODY

	var text := col("text")
	var dim := col("text_2")

	# Label and its variations
	t.set_color("font_color", "Label", text)
	t.set_constant("line_spacing", "Label", 6)
	for v in [["TitleLabel", font_black, SIZE_TITLE, text], ["HeadLabel", font_bold, SIZE_HEAD, text],
			["DimLabel", font_regular, SIZE_SMALL, dim], ["SmallLabel", font_medium, SIZE_SMALL, text],
			["CaptionLabel", font_medium, SIZE_CAPTION, col("text_3")],
			["HugeLabel", font_black, SIZE_HUGE, text], ["MoneyLabel", font_black, 30, col("gold")]]:
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

	# Buttons. Primary: turquoise with dark text, the one thing to do. Ghost
	# (and Action): a tonal surface. Gold: buying, paying, rewards. Danger:
	# what cannot be undone.
	_button_style(t, "Button", col("primary"), col("primary_hi"), col("primary_lo"), col("on_primary"))
	_button_style(t, "GhostButton", col("surface_2"), col("surface_3"), col("surface"), text, col("stroke_hi"))
	_button_style(t, "ActionButton", col("surface_2"), col("surface_3"), col("surface"), text, col("stroke_hi"))
	_button_style(t, "GoldButton", col("gold"), col("gold").lightened(0.15), col("gold_lo"), col("on_gold"))
	_button_style(t, "DangerButton", col("danger"), col("danger").lightened(0.12), col("danger_lo"), col("white"))
	# Tonal buttons: a colour's tint on the surface, for the small buttons that
	# repeat down a list (Buy, Sell, Enrol...) - quiet until you look for them.
	for v in [["TonalPrimary", "primary"], ["TonalGold", "gold"], ["TonalDanger", "danger"]]:
		var c := col(v[1])
		_button_style(t, v[0], col("surface").lerp(c, 0.16), col("surface").lerp(c, 0.26), col("surface").lerp(c, 0.10), c.lightened(0.1), Color(c, 0.45))
	# The selected segment of a segmented control.
	_button_style(t, "SegmentButton", col("surface_3"), col("surface_3"), col("surface_3"), text, col("stroke_hi"))
	t.set_font("font", "Button", font_bold)
	t.set_font_size("font_size", "Button", SIZE_BODY)
	t.set_constant("h_separation", "Button", 12)
	t.set_constant("icon_max_width", "Button", 40)

	# Nav button: flat, the shell draws the highlight
	t.set_type_variation("NavButton", "Button")
	for st in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		t.set_stylebox(st, "NavButton", StyleBoxEmpty.new())
	t.set_font("font", "NavButton", font_medium)
	t.set_font_size("font_size", "NavButton", 19)
	for k in ["font_color", "font_focus_color"]:
		t.set_color(k, "NavButton", dim)
	for k in ["font_pressed_color", "font_hover_pressed_color"]:
		t.set_color(k, "NavButton", col("primary"))
	t.set_color("font_hover_color", "NavButton", text)
	for k in ["icon_normal_color", "icon_pressed_color", "icon_hover_color", "icon_focus_color"]:
		t.set_color(k, "NavButton", Color.WHITE)

	# Panels
	t.set_stylebox("panel", "PanelContainer", box(col("surface"), R_CARD, col("stroke"), 1, 0, 20))
	for v in [["CardPanel", col("surface"), R_CARD, 22, col("stroke")],
			["InsetPanel", col("bg"), R_CONTROL, 6, col("stroke")],
			["ChipPanel", col("surface_2"), 999, 8, col("stroke")],
			["ToastPanel", col("surface_2"), 20, 18, col("stroke_hi")],
			["SlotPanel", col("surface_2"), R_SMALL, 10, col("stroke")],
			["HeaderPanel", col("surface"), R_CONTROL, 14, col("stroke")]]:
		t.set_type_variation(v[0], "PanelContainer")
		var sb := box(v[1], v[2], v[4], 1, 0, v[3])
		if v[0] == "ChipPanel":
			sb.content_margin_left = 14
			sb.content_margin_right = 14
			sb.content_margin_top = 6
			sb.content_margin_bottom = 6
		t.set_stylebox("panel", v[0], sb)

	# LineEdit
	var le := box(col("bg"), R_CONTROL, col("stroke_hi"), 1, 0, 18)
	le.content_margin_top = 14
	le.content_margin_bottom = 14
	var le_focus := box(col("bg"), R_CONTROL, col("primary"), 2, 0, 18)
	le_focus.content_margin_top = 14
	le_focus.content_margin_bottom = 14
	t.set_stylebox("normal", "LineEdit", le)
	t.set_stylebox("focus", "LineEdit", le_focus)
	t.set_stylebox("read_only", "LineEdit", le)
	t.set_font("font", "LineEdit", font_bold)
	t.set_font_size("font_size", "LineEdit", 34)
	t.set_color("font_color", "LineEdit", text)
	t.set_color("font_placeholder_color", "LineEdit", col("text_3"))
	t.set_color("caret_color", "LineEdit", col("primary"))
	t.set_color("selection_color", "LineEdit", col("primary", 0.3))

	# ProgressBar (vitals)
	t.set_stylebox("background", "ProgressBar", box(col("bg"), 999, Color(0, 0, 0, 0), 0, 0, 0))
	t.set_stylebox("fill", "ProgressBar", box(col("primary"), 999, Color(0, 0, 0, 0), 0, 0, 0))
	t.set_constant("outline_size", "ProgressBar", 0)

	# Scrolling: a thin, quiet grabber
	var grab := box(col("stroke_hi", 0.8), 4, Color(0, 0, 0, 0), 0, 0, 0)
	t.set_stylebox("grabber", "VScrollBar", grab)
	t.set_stylebox("grabber_highlight", "VScrollBar", grab)
	t.set_stylebox("grabber_pressed", "VScrollBar", grab)
	var sc := StyleBoxFlat.new()
	sc.bg_color = Color(0, 0, 0, 0)
	sc.content_margin_left = 4
	t.set_stylebox("scroll", "VScrollBar", sc)

	t.set_constant("separation", "VBoxContainer", 14)
	t.set_constant("separation", "HBoxContainer", 12)
	return t


func _button_style(t: Theme, type: String, face: Color, hover: Color, pressed: Color, fg: Color, edge := Color(0, 0, 0, 0)) -> void:
	if type != "Button":
		t.set_type_variation(type, "Button")
	t.set_stylebox("normal", type, button_box(face, false, R_CONTROL, edge))
	t.set_stylebox("hover", type, button_box(hover, false, R_CONTROL, edge))
	t.set_stylebox("pressed", type, button_box(pressed, true, R_CONTROL, edge))
	t.set_stylebox("hover_pressed", type, button_box(pressed, true, R_CONTROL, edge))
	var dis := button_box(col("surface_2"), false, R_CONTROL, col("stroke"))
	t.set_stylebox("disabled", type, dis)
	t.set_stylebox("focus", type, StyleBoxEmpty.new())
	for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(k, type, fg)
	t.set_color("font_disabled_color", type, col("text_3"))
	t.set_constant("outline_size", type, 0)
	# icons take the label's colour, so a line icon on turquoise reads dark
	var ic := fg if fg.get_luminance() < 0.5 else Color.WHITE
	for k in ["icon_normal_color", "icon_pressed_color", "icon_hover_color", "icon_focus_color", "icon_hover_pressed_color"]:
		t.set_color(k, type, ic)
	t.set_color("icon_disabled_color", type, Color(1, 1, 1, 0.4))
