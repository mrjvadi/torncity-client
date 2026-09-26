@tool
class_name GlowPanel
extends PanelContainer
## A card drawn in code, crisp at any scale: a soft drop shadow, a nearly flat
## face (a whisper of gradient), a faint top edge light and a hairline border.
## An optional accent draws a short bar on the top edge. Children are laid out
## like a PanelContainer's. Colours default to the UI tokens (palette.json "ui").

const SURFACE := Color("#131A2E")
const STROKE := Color("#243052")

@export var top_color := Color("#161E35"):
	set(v): top_color = v; queue_redraw()
@export var bottom_color := SURFACE:
	set(v): bottom_color = v; queue_redraw()
@export var border_color := STROKE:
	set(v): border_color = v; queue_redraw()
@export var highlight := Color(1, 1, 1, 0.05):
	set(v): highlight = v; queue_redraw()
@export var radius := 24.0:
	set(v): radius = v; queue_redraw()
@export var shadow := 14.0:
	set(v): shadow = v; queue_redraw()
@export var accent := Color(0, 0, 0, 0):   ## an optional accent bar on the top edge
	set(v): accent = v; queue_redraw()
@export var padding := 22:
	set(v): padding = v; _apply_padding()


## Wash the card with a colour (a place's, a domain's): the face picks up a
## little of it, the border a little more.
func tint_with(c: Color, amount := 0.16) -> void:
	top_color = SURFACE.lerp(c, amount)
	bottom_color = SURFACE.lerp(c, amount * 0.35)
	border_color = Color(c, 0.32)


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
		var layers := 4
		for i in layers:
			var grow := shadow * (i + 1) / layers
			var sr := r.grow(grow * 0.5)
			sr.position.y += shadow * 0.4
			var a := 0.12 * (1.0 - float(i) / layers)
			draw_colored_polygon(rounded_rect(sr, radius + grow * 0.5), Color(0.0, 0.01, 0.04, a))
	# face: per-vertex colours by height
	var pts := rounded_rect(r, radius)
	var cols := PackedColorArray()
	for p in pts:
		cols.append(top_color.lerp(bottom_color, clampf(p.y / maxf(1.0, size.y), 0, 1)))
	draw_polygon(pts, cols)
	# hairline border
	if border_color.a > 0:
		var closed := pts.duplicate()
		closed.append(pts[0])
		draw_polyline(closed, border_color, 1.2, true)
	# top edge light, fading towards the corners
	if highlight.a > 0 and size.x > radius * 2:
		var x0 := radius
		var x1 := size.x - radius
		var hl := PackedVector2Array([Vector2(x0, 1.0), Vector2((x0 + x1) / 2.0, 1.0), Vector2(x1, 1.0)])
		var hc := PackedColorArray([Color(highlight, 0.0), highlight, Color(highlight, 0.0)])
		draw_polyline_colors(hl, hc, 1.5, true)
	if accent.a > 0:
		var w := minf(96.0, size.x * 0.3)
		var x := size.x - radius - w if is_layout_rtl() else radius
		draw_colored_polygon(rounded_rect(Rect2(x, 0, w, 4), 2, 3), accent)
