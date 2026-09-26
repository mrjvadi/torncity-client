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


static func make(g: Dictionary, px := 72.0, is_framed := true) -> IconBadge:
	var b := IconBadge.new()
	b.texture = g.get("texture")
	b.tint = g.get("tint", Color("#2F80ED"))
	b.framed = is_framed
	b.custom_minimum_size = Vector2(px, px)
	b.radius = maxf(6.0, px * 0.16)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


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
