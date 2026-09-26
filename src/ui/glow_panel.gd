@tool
class_name GlowPanel
extends PanelContainer
## A premium panel drawn in code, crisp at any scale: a soft layered drop
## shadow, a vertical gradient face, a 1 px inner highlight along the top edge
## and a hairline border. Children are laid out like a PanelContainer's.

@export var top_color := Color("#1A2A43"):
	set(v): top_color = v; queue_redraw()
@export var bottom_color := Color("#0F1A2B"):
	set(v): bottom_color = v; queue_redraw()
@export var border_color := Color("#2B4468"):
	set(v): border_color = v; queue_redraw()
@export var highlight := Color(0.42, 0.6, 0.9, 0.35):
	set(v): highlight = v; queue_redraw()
@export var radius := 10.0:
	set(v): radius = v; queue_redraw()
@export var shadow := 16.0:
	set(v): shadow = v; queue_redraw()
@export var accent := Color(0, 0, 0, 0):   ## an optional glow line along the top
	set(v): accent = v; queue_redraw()
@export var padding := 22:
	set(v): padding = v; _apply_padding()


func _init() -> void:
	_apply_padding()


func _apply_padding() -> void:
	var sb := StyleBoxEmpty.new()
	sb.set_content_margin_all(padding)
	add_theme_stylebox_override("panel", sb)


static func rounded_rect(r: Rect2, rad: float, seg := 8) -> PackedVector2Array:
	rad = maxf(0.0, minf(rad, minf(r.size.x, r.size.y) / 2.0 - 0.01))
	var pts := PackedVector2Array()
	if r.size.x < 0.5 or r.size.y < 0.5:
		return pts
	var corners := [
		[Vector2(r.end.x - rad, r.position.y + rad), -90.0],
		[Vector2(r.end.x - rad, r.end.y - rad), 0.0],
		[Vector2(r.position.x + rad, r.end.y - rad), 90.0],
		[Vector2(r.position.x + rad, r.position.y + rad), 180.0],
	]
	for c in corners:
		for i in seg + 1:
			var a := deg_to_rad(c[1] + 90.0 * i / seg)
			var p: Vector2 = c[0] + Vector2(cos(a), sin(a)) * rad
			if pts.is_empty() or pts[pts.size() - 1].distance_squared_to(p) > 0.0001:
				pts.append(p)
	if pts.size() > 2 and pts[0].distance_squared_to(pts[pts.size() - 1]) < 0.0001:
		pts.resize(pts.size() - 1)
	return pts


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if size.x < 2 or size.y < 2:
		return
	# shadow: a few expanding translucent layers, offset downwards
	if shadow > 0:
		var layers := 5
		for i in layers:
			var grow := shadow * (i + 1) / layers
			var sr := r.grow(grow * 0.6)
			sr.position.y += shadow * 0.35
			var a := 0.16 * (1.0 - float(i) / layers)
			draw_colored_polygon(rounded_rect(sr, radius + grow * 0.6), Color(0.02, 0.03, 0.08, a))
	# gradient face: per-vertex colours by height
	var pts := rounded_rect(r, radius)
	var cols := PackedColorArray()
	for p in pts:
		cols.append(top_color.lerp(bottom_color, clampf(p.y / maxf(1.0, size.y), 0, 1)))
	draw_polygon(pts, cols)
	# inner top highlight
	if highlight.a > 0 and size.x > radius * 2:
		var rr := maxf(radius - 1.5, 0.0)
		var hl := PackedVector2Array()
		for i in 9:
			var a := deg_to_rad(200.0 + 70.0 * i / 8.0)
			hl.append(Vector2(1.5 + rr, 1.5 + rr) + Vector2(cos(a), sin(a)) * rr)
		for i in 9:
			var a := deg_to_rad(270.0 + 70.0 * i / 8.0)
			hl.append(Vector2(size.x - 1.5 - rr, 1.5 + rr) + Vector2(cos(a), sin(a)) * rr)
		draw_polyline(hl, highlight, 2.0, true)
	if accent.a > 0:
		draw_line(Vector2(radius, 1.5), Vector2(size.x - radius, 1.5), accent, 3.0, true)
	# hairline border
	if border_color.a > 0:
		var closed := pts.duplicate()
		closed.append(pts[0])
		draw_polyline(closed, border_color, 1.5, true)
