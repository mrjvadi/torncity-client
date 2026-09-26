class_name Illustration
extends Control
## A small drawn illustration for empty, error and offline states: soft
## concentric halos, a floating ring of dots, a big tinted glyph badge in the
## middle, and a gentle float animation.

var glyph := {}
var tint := Color("#2F80ED")
var _t := 0.0


static func make(kind: String, px := 240.0) -> Illustration:
	var i := Illustration.new()
	var key: String = {"empty": "state:empty", "error": "state:error", "offline": "state:offline", "done": "state:done",
		"search": "state:search"}.get(kind, "state:empty")
	i.glyph = AssetLib.glyph(key)
	i.tint = i.glyph.get("tint", Color("#2F80ED"))
	i.custom_minimum_size = Vector2(px, px)
	i.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	i.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return i


func _process(delta: float) -> void:
	if Config.headless_capture:
		return
	_t += delta
	queue_redraw()


func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) / 2.0
	for k in 4:
		draw_circle(c, r * (1.0 - k * 0.17), Color(tint, 0.05 + k * 0.025))
	# a ring of dots, slowly turning
	for k in 12:
		var a := TAU * k / 12.0 + _t * 0.25
		var p := c + Vector2(cos(a), sin(a)) * r * 0.86
		draw_circle(p, 3.0 + (k % 3), Color(tint.lightened(0.3), 0.35 if k % 2 else 0.18))
	# the badge, floating
	var bob := sin(_t * 1.6) * 5.0
	var bs := r * 0.95
	var rect := Rect2(c - Vector2(bs, bs) / 2.0 + Vector2(0, bob), Vector2(bs, bs))
	draw_colored_polygon(GlowPanel.rounded_rect(Rect2(rect.position + Vector2(0, 10), rect.size), bs * 0.24, 8), Color(0, 0, 0, 0.3))
	var pts := GlowPanel.rounded_rect(rect, bs * 0.24, 8)
	var cols := PackedColorArray()
	for p in pts:
		cols.append(Color("#1F3150").lerp(tint, 0.45).lerp(Color("#16243A").lerp(tint, 0.15), (p.y - rect.position.y) / rect.size.y))
	draw_polygon(pts, cols)
	var tex: Texture2D = glyph.get("texture")
	if tex:
		var g := bs * 0.58
		draw_texture_rect(tex, Rect2(rect.get_center() - Vector2(g, g) / 2.0, Vector2(g, g)), false, tint.lerp(Color.WHITE, 0.75))
	# sparkles
	for k in 3:
		var a := TAU * (k / 3.0) + 0.6
		var p := c + Vector2(cos(a), sin(a)) * r * 0.62 + Vector2(0, -bob * 0.5)
		var s := 6.0 + 3.0 * sin(_t * 2.0 + k)
		draw_line(p - Vector2(s, 0), p + Vector2(s, 0), Color(1, 1, 1, 0.5), 2.0, true)
		draw_line(p - Vector2(0, s), p + Vector2(0, s), Color(1, 1, 1, 0.5), 2.0, true)
