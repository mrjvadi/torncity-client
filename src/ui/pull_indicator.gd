class_name PullIndicator
extends Control
## The pull-to-refresh bubble: a circle with an arrow that turns as the list is
## pulled, turning blue when a release would refresh, spinning while it does.

var pull := 0.0          # 0..1 of the threshold
var spinning := false
var _a := 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(64, 64)
	size = Vector2(64, 64)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	if spinning:
		_a += delta * 8.0
		queue_redraw()


func _draw() -> void:
	var c := size / 2.0
	var ready := pull >= 1.0 or spinning
	draw_circle(c + Vector2(0, 3), 30, Color(0, 0, 0, 0.3))
	draw_circle(c, 30, Color("#2F80ED") if ready else Color("#1C2F4C"))
	var start := _a if spinning else pull * PI * 1.5
	draw_arc(c, 17, start, start + PI * 1.4 * (1.0 if spinning else clampf(pull, 0.1, 1.0)), 32, Color.WHITE, 4.0, true)
	var tip := start + PI * 1.4 * (1.0 if spinning else clampf(pull, 0.1, 1.0))
	var p := c + Vector2(cos(tip), sin(tip)) * 17
	var d := Vector2(cos(tip + PI / 2), sin(tip + PI / 2))
	draw_colored_polygon(PackedVector2Array([p + d * 7, p + Vector2(cos(tip), sin(tip)) * 6, p - Vector2(cos(tip), sin(tip)) * 6]), Color.WHITE)
