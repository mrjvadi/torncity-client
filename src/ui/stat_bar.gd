class_name StatBar
extends Control
## A stat as a bar. Two layouts:
##  * labelled (label_text set): icon, name at the start, value at the end, and
##    a thin glossy bar underneath — the player-card look;
##  * inline: icon and a thick capsule with the value written inside.
## `invert` marks a need where more is worse: its colour warms as it fills.

@export var icon_name := "energy"
@export var color := Color("#F2C94C")
@export var max_value := 100.0
@export var invert := false
@export var show_text := true
@export var compact := false

var value := 0.0
var text := ""
var label_text := ""
var _shown := 0.0
var _icon: Texture2D


func _ready() -> void:
	_icon = AppTheme.icon(icon_name) if icon_name != "" else null
	if custom_minimum_size.y == 0:
		custom_minimum_size = Vector2(80, 14 if compact else 44)
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
		return AppTheme.col("red")
	if f >= 0.7:
		return AppTheme.col("orange")
	return color


func _bar(r: Rect2) -> void:
	var h := r.size.y
	draw_colored_polygon(GlowPanel.rounded_rect(r, h / 2, 6), Color("#08101B"))
	var f := clampf(_shown / maxf(1.0, max_value), 0, 1)
	if f <= 0.001:
		return
	var rtl := I18n.is_rtl()
	var w := maxf(h, r.size.x * f)
	var fr := Rect2(r.position.x + (r.size.x - w if rtl else 0.0), r.position.y, w, h)
	var c := _fill_color()
	var pts := GlowPanel.rounded_rect(fr, h / 2, 6)
	var cols := PackedColorArray()
	for p in pts:
		cols.append(c.lightened(0.25).lerp(c.darkened(0.15), (p.y - fr.position.y) / h))
	draw_polygon(pts, cols)
	if h >= 8:
		var gloss := Rect2(fr.position + Vector2(h * 0.4, h * 0.16), Vector2(maxf(0.0, fr.size.x - h * 0.8), h * 0.24))
		if gloss.size.x > 2:
			draw_colored_polygon(GlowPanel.rounded_rect(gloss, gloss.size.y / 2, 4), Color(1, 1, 1, 0.25))


func _draw() -> void:
	var rtl := I18n.is_rtl()
	if label_text != "":
		_draw_labelled(rtl)
		return
	var h := size.y
	if _icon == null:
		_bar(Rect2(0, (h - minf(h, 12)) / 2, size.x, minf(h, 12)))
		return
	var isz := h * 0.9
	var bar_h := h * (0.42 if compact else 0.5)
	var x0 := isz + 8.0
	var bar := Rect2(0 if rtl else x0, (h - bar_h) / 2.0, size.x - x0, bar_h)
	_bar(bar)
	draw_texture_rect(_icon, Rect2(Vector2(size.x - isz if rtl else 0.0, (h - isz) / 2.0), Vector2(isz, isz)), false)
	if show_text and text != "":
		var font := AppTheme.font_bold
		var fs := int(h * (0.5 if compact else 0.42))
		var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var pos := Vector2(bar.position.x + (bar.size.x - tw) / 2.0, bar.position.y + bar_h / 2.0 + fs * 0.36)
		draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 5, Color(0.03, 0.06, 0.1, 0.9))
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)


func _draw_labelled(rtl: bool) -> void:
	var h := size.y
	var isz := 24.0
	var fs := 20
	var font := AppTheme.font_medium
	var bold := AppTheme.font_bold
	var line_y := fs + 1.0
	var start := 0.0
	if _icon:
		draw_texture_rect(_icon, Rect2(Vector2(size.x - isz if rtl else 0.0, 0), Vector2(isz, isz)), false)
		start = isz + 8.0
	var lw := font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var vw := bold.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var lx := size.x - start - lw if rtl else start
	var vx := 0.0 if rtl else size.x - vw
	draw_string(font, Vector2(lx, line_y - 2), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, AppTheme.col("text"))
	draw_string(bold, Vector2(vx, line_y - 2), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, AppTheme.col("text_dim"))
	var bh := maxf(6.0, h - isz - 4)
	_bar(Rect2(0, h - bh, size.x, bh))
