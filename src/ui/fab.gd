class_name Fab
extends RoundIconButton
## The floating action button: a big blue glowing circle with a white glyph.


func _draw() -> void:
	var d := minf(size.x, size.y)
	var c := size / 2.0
	for i in 5:
		draw_circle(c + Vector2(0, 5), d / 2.0 + i * 2.5, Color(0.18, 0.5, 0.93, 0.07))
	draw_circle(c + Vector2(0, 4), d / 2.0, Color(0, 0, 0, 0.3))
	draw_circle(c, d / 2.0, Color("#2F80ED") if not is_hovered() else Color("#4A93F0"))
	draw_arc(c, d / 2.0 - 1.0, PI * 1.1, PI * 1.9, 24, Color(1, 1, 1, 0.35), 2.0, true)
	if tex:
		var g := d * 0.46
		draw_texture_rect(tex, Rect2(c - Vector2(g, g) / 2.0, Vector2(g, g)), false, Color.WHITE)
