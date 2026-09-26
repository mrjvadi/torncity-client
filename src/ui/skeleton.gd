class_name Skeleton
extends Control
## A loading placeholder: rounded bars in the shape of a card, with a light
## band sweeping across (shimmer). `rows` sets how many lines it shows.

@export var rows := 3
@export var with_badge := true
var _t := 0.0


static func card(n_rows := 3, badge := true, h := 150.0) -> Skeleton:
	var s := Skeleton.new()
	s.rows = n_rows
	s.with_badge = badge
	s.custom_minimum_size = Vector2(0, h)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return s


func _process(delta: float) -> void:
	_t = fmod(_t + delta, 1.6)
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_colored_polygon(GlowPanel.rounded_rect(r, 22, 6), Color("#16243A"))
	var bone := Color("#22375A")
	var x0 := 20.0
	var rtl := I18n.is_rtl()
	if with_badge:
		var b := Rect2(Vector2(size.x - 20 - 72 if rtl else 20.0, 20), Vector2(72, 72))
		draw_colored_polygon(GlowPanel.rounded_rect(b, 16, 6), bone)
		x0 = 110.0
	for i in rows:
		var w := (size.x - x0 - 24) * (0.9 if i == 0 else (0.62 if i % 2 else 0.78))
		var y := 26.0 + i * 34.0
		var hh := 18.0 if i == 0 else 13.0
		var bar := Rect2(Vector2(size.x - x0 - w if rtl else x0, y), Vector2(w, hh))
		draw_colored_polygon(GlowPanel.rounded_rect(bar, hh / 2.0, 4), bone)
	# the shimmer band
	var x := (_t - 0.3) * size.x
	var band := PackedVector2Array([Vector2(x, 0), Vector2(x + size.x * 0.18, 0), Vector2(x + size.x * 0.08, size.y), Vector2(x - size.x * 0.1, size.y)])
	var clipped := Geometry2D.intersect_polygons(band, GlowPanel.rounded_rect(r, 22, 6))
	for poly in clipped:
		draw_colored_polygon(poly, Color(1, 1, 1, 0.05))
