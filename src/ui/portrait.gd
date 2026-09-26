class_name Portrait
extends Control
## A square portrait in a rounded frame with a blue rim. The player's chosen
## avatar (life.yml presets) when they have one; otherwise a person glyph.

var code := ""
var _tex: Texture2D
var _glyph := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func set_avatar(c: String) -> void:
	code = c
	_tex = null
	_glyph = false
	if c != "" and c != "photo" and c != "none":
		_tex = AppTheme.tex("avatar/" + c)
	if _tex == null:
		_tex = AssetLib.icon("action:player")
		_glyph = true
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var rad := minf(size.x, size.y) * 0.18
	var outer := GlowPanel.rounded_rect(r, rad, 6)
	draw_colored_polygon(outer, Color("#2F80ED"))
	var inner_r := r.grow(-3)
	var pts := GlowPanel.rounded_rect(inner_r, rad - 2, 6)
	var cols := PackedColorArray()
	for p in pts:
		cols.append(Color("#24406B").lerp(Color("#132139"), p.y / maxf(1.0, size.y)))
	draw_polygon(pts, cols)
	if _tex:
		var pad := size.x * (0.2 if _glyph else 0.06)
		draw_texture_rect(_tex, inner_r.grow(-pad), false, Color("#CFE2FF") if _glyph else Color.WHITE)
