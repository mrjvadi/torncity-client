@tool
class_name IconBadge
extends Control
## A game-icons.net glyph on a badge: a rounded square with a subtle vertical
## gradient of the icon's tint over the navy panel, a 1 px lighter border, a
## soft top highlight, and the glyph in a light tint. One look for every icon
## (resources, stats, actions, items, places...), so glyphs from many authors
## read as one set.
##
##   IconBadge.make(AssetLib.glyph("item:pistol"), 72)
##   IconBadge.make(AssetLib.glyph_for("item", code), 96)

@export var texture: Texture2D:
	set(v):
		texture = v
		queue_redraw()
@export var tint := Color("#2F80ED"):
	set(v):
		tint = v
		queue_redraw()
@export var radius := 10.0
## false: no badge, just the tinted glyph (for inline use in text rows)
@export var framed := true
## The CDN key of the glyph still downloading ("" when the texture is final):
## a shimmer runs over the fallback glyph until it arrives.
var pending_key := ""
var _shine := 0.0


static func make(g: Dictionary, px := 72.0, is_framed := true) -> IconBadge:
	var b := IconBadge.new()
	b.texture = g.get("texture")
	b.tint = g.get("tint", Color("#2F80ED"))
	if g.get("pending", false):
		b.pending_key = str(g.get("key", ""))
	b.framed = is_framed
	b.custom_minimum_size = Vector2(px, px)
	b.radius = maxf(6.0, px * 0.16)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


func _ready() -> void:
	if pending_key != "" and not Engine.is_editor_hint():
		AssetService.loaded.connect(_on_asset)
		set_process(true)
	else:
		set_process(false)


func _on_asset(k: String) -> void:
	if k != pending_key:
		return
	var t = AssetService.get_asset(k)
	if t is Texture2D:
		texture = t
	pending_key = ""
	set_process(false)
	if not Config.headless_capture:
		modulate.a = 0.4
		create_tween().tween_property(self, "modulate:a", 1.0, 0.2)
	queue_redraw()


func _process(delta: float) -> void:
	_shine = fmod(_shine + delta * 0.9, 1.6)
	queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var s := minf(size.x, size.y)
	if framed:
		var navy := Color("#16243A")
		var top := navy.lerp(tint, 0.34)
		var bottom := navy.lerp(tint, 0.12)
		var pts := GlowPanel.rounded_rect(r, radius, 6)
		var cols := PackedColorArray()
		for p in pts:
			cols.append(top.lerp(bottom, p.y / maxf(1.0, size.y)))
		draw_polygon(pts, cols)
		var border := pts.duplicate()
		border.append(pts[0])
		draw_polyline(border, Color(tint.lightened(0.2), 0.55), 1.2, true)
		# top highlight
		var hl := Rect2(r.position + Vector2(radius * 0.8, 2.5), Vector2(r.size.x - radius * 1.6, 1.6))
		draw_rect(hl, Color(1, 1, 1, 0.16))
	if texture:
		var g := s * (0.62 if framed else 1.0)
		var at := Rect2((size - Vector2(g, g)) / 2.0, Vector2(g, g))
		if framed:
			# a faint drop shadow under the glyph
			draw_texture_rect(texture, Rect2(at.position + Vector2(0, s * 0.03), at.size), false, Color(0, 0, 0, 0.35))
		draw_texture_rect(texture, at, false, tint.lerp(Color.WHITE, 0.72) if framed else tint.lightened(0.15))
	if pending_key != "" and framed:
		# shimmer: a soft diagonal band sweeping across while the real glyph loads
		var x := (_shine - 0.3) * size.x
		var band := PackedVector2Array([Vector2(x, 0), Vector2(x + size.x * 0.25, 0),
			Vector2(x + size.x * 0.05, size.y), Vector2(x - size.x * 0.2, size.y)])
		var clip := Rect2(Vector2.ZERO, size)
		var pts := PackedVector2Array()
		for p in band:
			pts.append(Vector2(clampf(p.x, clip.position.x, clip.end.x), p.y))
		draw_colored_polygon(pts, Color(1, 1, 1, 0.08))
