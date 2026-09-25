class_name RouteView
extends Control
## Two cities joined by a dashed arc; a vehicle icon rides it at `progress`.

var from_name := ""
var to_name := ""
var vehicle_icon := ""
var progress := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _point(t: float, a: Vector2, b: Vector2, lift: float) -> Vector2:
	var mid := (a + b) / 2 - Vector2(0, lift)
	return a.lerp(mid, t).lerp(mid.lerp(b, t), t)


func _draw() -> void:
	var rtl := I18n.is_rtl()
	var a := Vector2(70, size.y - 44)
	var b := Vector2(size.x - 70, size.y - 44)
	if rtl:
		var tmp := a
		a = b
		b = tmp
	var lift := size.y * 0.55
	var steps := 40
	for i in steps:
		if i % 2 == 1:
			continue
		var p0 := _point(float(i) / steps, a, b, lift)
		var p1 := _point(float(i + 1) / steps, a, b, lift)
		var done := float(i) / steps < progress
		draw_line(p0, p1, AppTheme.col("saffron") if done else AppTheme.col("line"), 5.0, true)
	for end in [[a, from_name, "turquoise"], [b, to_name, "pomegranate"]]:
		draw_circle(end[0], 16, AppTheme.col("night"))
		draw_circle(end[0], 11, AppTheme.col(end[2]))
		var f := AppTheme.font_bold
		var w := f.get_string_size(end[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
		draw_string(f, Vector2(clampf(end[0].x - w / 2, 4, size.x - w - 4), end[0].y + 40), end[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, AppTheme.col("text"))
	if vehicle_icon != "":
		var t := AppTheme.icon(vehicle_icon)
		var p := _point(clampf(progress, 0, 1), a, b, lift)
		draw_circle(p, 34, AppTheme.col("night"))
		draw_arc(p, 34, 0, TAU, 40, AppTheme.col("saffron"), 3, true)
		if t:
			draw_texture_rect(t, Rect2(p - Vector2(24, 24), Vector2(48, 48)), false)
