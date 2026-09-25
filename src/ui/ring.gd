class_name Ring
extends Control
## A radial gauge: a track, a gradient-ish progress arc with round caps, an
## icon in the middle and a caption underneath.

@export var color := Color("#2EC4B6")
@export var thickness := 14.0
@export var icon_name := ""
var value := 0.0          # 0..1
var caption := ""
var center_text := ""
var _shown := 0.0
var _icon: Texture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if icon_name != "":
		_icon = AppTheme.icon(icon_name)


func set_value(v: float, center := "", cap := "") -> void:
	value = clampf(v, 0, 1)
	center_text = center
	caption = cap
	if Config.headless_capture or not is_inside_tree():
		_shown = value
		queue_redraw()
		return
	create_tween().tween_method(func(x): _shown = x; queue_redraw(), _shown, value, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	var cap_h := 34.0 if caption != "" else 0.0
	var d := minf(size.x, size.y - cap_h)
	var c := Vector2(size.x / 2.0, d / 2.0)
	var r := d / 2.0 - thickness / 2.0 - 2
	draw_circle(c, r + thickness / 2.0 + 2, AppTheme.col("ink", 0.55))
	draw_arc(c, r, 0, TAU, 72, AppTheme.col("line", 0.8), thickness, true)
	if _shown > 0.001:
		var a0 := -PI / 2
		var a1 := a0 + TAU * _shown
		var steps := 24
		for i in steps:
			var t0 := a0 + (a1 - a0) * i / steps
			var t1 := a0 + (a1 - a0) * (i + 1) / steps
			draw_arc(c, r, t0, t1 + 0.01, 6, color.lightened(0.25 * (1.0 - float(i) / steps)), thickness, true)
		draw_circle(c + Vector2(cos(a0), sin(a0)) * r, thickness / 2.0, color.lightened(0.25))
		draw_circle(c + Vector2(cos(a1), sin(a1)) * r, thickness / 2.0, color)
	if _icon:
		var isz := r * 0.8
		var off := Vector2(0, -r * 0.18) if center_text != "" else Vector2.ZERO
		draw_texture_rect(_icon, Rect2(c - Vector2(isz, isz) / 2 + off, Vector2(isz, isz)), false)
	var f := AppTheme.font_bold
	if center_text != "":
		var fs := int(r * (0.36 if _icon else 0.55))
		var w := f.get_string_size(center_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var y := c.y + (r * 0.5 if _icon else fs * 0.36)
		draw_string(f, Vector2(c.x - w / 2, y), center_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, AppTheme.col("text"))
	if caption != "":
		var fs2 := 21
		var f2 := AppTheme.font_medium
		var w2 := f2.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2).x
		draw_string(f2, Vector2(c.x - w2 / 2, d + 26), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, fs2, AppTheme.col("text_dim"))
