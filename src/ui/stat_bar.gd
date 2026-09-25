class_name StatBar
extends Control
## A vital as a glossy bar: icon, gradient fill, value text. `invert` marks a
## need where more is worse (hunger, sleep, stress): its colour warms as it fills.

@export var icon_name := "energy"
@export var color := Color("#F6B93B")
@export var max_value := 100.0
@export var invert := false
@export var show_text := true
@export var compact := false

var value := 0.0
var text := ""
var _shown := 0.0
var _icon: Texture2D


func _ready() -> void:
	_icon = AppTheme.icon(icon_name)
	custom_minimum_size = Vector2(80, 30 if compact else 44)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_value(v: float, m := -1.0, label := "") -> void:
	if m > 0:
		max_value = m
	value = v
	text = label
	if Config.headless_capture or not is_inside_tree():
		_shown = v
		queue_redraw()
		return
	var t := create_tween()
	t.tween_method(func(x): _shown = x; queue_redraw(), _shown, v, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _fill_color() -> Color:
	if not invert:
		return color
	var f := clampf(value / maxf(1.0, max_value), 0, 1)
	if f >= 0.9:
		return AppTheme.col("pomegranate")
	if f >= 0.7:
		return AppTheme.col("brick")
	return color


func _draw() -> void:
	var h := size.y
	var isz := h * (0.95 if compact else 0.9)
	var rtl := I18n.is_rtl()
	var bar_h := h * (0.42 if compact else 0.5)
	var x0 := isz + 8.0
	var bar := Rect2(0 if rtl else x0, (h - bar_h) / 2.0, size.x - x0, bar_h)
	var icon_pos := Vector2(size.x - isz if rtl else 0.0, (h - isz) / 2.0)
	# track
	draw_colored_polygon(GlowPanel.rounded_rect(bar, bar_h / 2, 6), AppTheme.col("ink", 0.75))
	# fill
	var f := clampf(_shown / maxf(1.0, max_value), 0, 1)
	if f > 0.001:
		var w := maxf(bar_h, bar.size.x * f)
		var fr := Rect2(bar.position.x + (bar.size.x - w if rtl else 0.0), bar.position.y, w, bar_h)
		var c := _fill_color()
		var pts := GlowPanel.rounded_rect(fr, bar_h / 2, 6)
		var cols := PackedColorArray()
		for p in pts:
			var t := (p.y - fr.position.y) / bar_h
			cols.append(c.lightened(0.28).lerp(c.darkened(0.12), t))
		draw_polygon(pts, cols)
		# gloss
		var gloss := Rect2(fr.position + Vector2(bar_h * 0.35, bar_h * 0.14), Vector2(maxf(0.0, fr.size.x - bar_h * 0.7), bar_h * 0.22))
		if gloss.size.x > 2:
			draw_colored_polygon(GlowPanel.rounded_rect(gloss, gloss.size.y / 2, 4), Color(1, 1, 1, 0.28))
	if _icon:
		draw_texture_rect(_icon, Rect2(icon_pos, Vector2(isz, isz)), false)
	if show_text and text != "":
		var font := AppTheme.font_bold
		var fs := int(h * (0.5 if compact else 0.42))
		var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var pos := Vector2(bar.position.x + (bar.size.x - tw) / 2.0, bar.position.y + bar_h / 2.0 + fs * 0.36)
		draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 5, AppTheme.col("ink", 0.85))
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
