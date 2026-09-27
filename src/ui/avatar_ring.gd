class_name AvatarRing
extends Control
## The player's avatar in a circle, with the XP to the next level as a ring
## around it and the level in a badge at the bottom. The ring animates when
## XP changes. The avatar comes from the CDN (avatar:<code>); until then, or
## without one, a person glyph.

var code := ""
var level := 0
var xp := 0.0          # 0..1 of the way to the next level
var _shown := 0.0
var _tex: Texture2D
var _glyph := true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	AssetService.loaded.connect(func(k): if k == "avatar:" + code: set_avatar(code, level, xp))


func set_avatar(c: String, lvl: int, frac: float) -> void:
	code = c
	level = lvl
	_tex = null
	_glyph = true
	if c != "" and c != "photo" and c != "none":
		var t = AssetService.get_asset("avatar:" + c)
		if t is Texture2D:
			_tex = t
			_glyph = false
	if _tex == null:
		_tex = AssetLib.icon("action:player")
	if Config.headless_capture or not is_inside_tree():
		xp = frac
		_shown = frac
		queue_redraw()
		return
	var from := _shown
	xp = frac
	create_tween().tween_method(func(v): _shown = v; queue_redraw(), from, frac, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	var d := minf(size.x, size.y)
	var c := Vector2(size.x / 2.0, d / 2.0)
	var r := d / 2.0
	var ring_w := maxf(4.0, d * 0.075)
	# track + progress
	draw_arc(c, r - ring_w / 2.0, 0, TAU, 64, Color("#0A0F1E"), ring_w, true)
	if _shown > 0.001:
		var start := -PI / 2.0
		draw_arc(c, r - ring_w / 2.0, start, start + TAU * clampf(_shown, 0, 1), 64, Color("#2EC4B6"), ring_w, true)
	# the face
	var inner := r - ring_w - 3.0
	var pts := PackedVector2Array()
	var uvs := PackedVector2Array()
	for i in 48:
		var a := TAU * i / 48.0
		var v := Vector2(cos(a), sin(a))
		pts.append(c + v * inner)
		uvs.append(Vector2(0.5, 0.5) + v * (0.5 if not _glyph else 0.78))
	draw_colored_polygon(pts, Color("#1A2340"))
	if _tex:
		if _glyph:
			var g := inner * 1.1
			draw_texture_rect(_tex, Rect2(c - Vector2(g, g) / 2.0, Vector2(g, g)), false, Color("#CFE2FF"))
		else:
			draw_colored_polygon(pts, Color.WHITE, uvs, _tex)
	# level badge
	if level > 0:
		var font := AppTheme.font_black
		var txt := I18n.num(level)
		var fs := int(d * 0.2)
		var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var bw := maxf(tw + fs * 0.9, fs * 1.6)
		var br := Rect2(Vector2(c.x - bw / 2.0, d - fs * 1.15), Vector2(bw, fs * 1.3))
		draw_colored_polygon(GlowPanel.rounded_rect(br.grow(2), br.size.y / 2.0 + 2, 6), Color("#0A0F1E"))
		draw_colored_polygon(GlowPanel.rounded_rect(br, br.size.y / 2.0, 6), Color("#F6B93B"))
		draw_string(font, Vector2(c.x - tw / 2.0, br.position.y + br.size.y * 0.78), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#1B1400"))
