extends Control
## The first frame: the city skyline at dusk, the emblem and the name.

var _dots: Label
var _t := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var art := TextureRect.new()
	art.texture = AppTheme.tex("brand/splash")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(art)
	var col := UI.vbox(10)
	col.set_anchors_preset(Control.PRESET_CENTER_TOP)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(col)
	var logo := UI.tex(AppTheme.tex("brand/logo"), Vector2(260, 260))
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(logo)
	var name := UI.label(I18n.t("app.name"), "HugeLabel", HORIZONTAL_ALIGNMENT_CENTER)
	name.add_theme_font_size_override("font_size", 76)
	name.add_theme_constant_override("outline_size", 14)
	name.add_theme_color_override("font_outline_color", Color(0.05, 0.06, 0.13, 0.55))
	col.add_child(name)
	var tag := UI.label(I18n.t("app.tagline"), "SmallLabel", HORIZONTAL_ALIGNMENT_CENTER)
	tag.add_theme_color_override("font_color", AppTheme.col("sand"))
	col.add_child(tag)
	_dots = UI.label("", "HeadLabel", HORIZONTAL_ALIGNMENT_CENTER)
	_dots.add_theme_color_override("font_color", AppTheme.col("saffron"))
	col.add_child(_dots)
	await get_tree().process_frame
	col.position = Vector2((size.x - col.size.x) / 2.0, size.y * 0.16)
	Fx.pop(logo, 0.5)
	Fx.fade_in(name, 0.6)


func _process(delta: float) -> void:
	_t += delta
	var n := int(_t * 3.0) % 4
	_dots.text = "•".repeat(n) if not Config.headless_capture else "•••"
