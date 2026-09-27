class_name RoundIconButton
extends Button
## A round glassy icon button (bell, menu, back, refresh, map controls), with
## an optional count badge (unread notifications). Spring press.

var tex: Texture2D
var count := 0:
	set(v):
		if v > count and is_inside_tree() and not Config.headless_capture:
			Fx.pulse(self)
		count = v
		queue_redraw()
var tint := Color("#DDE5F5")


static func make(t: Texture2D, fn: Callable, px := 64.0) -> RoundIconButton:
	var b := RoundIconButton.new()
	b.tex = t
	b.custom_minimum_size = Vector2(px, px)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(fn)
	return b


func _init() -> void:
	focus_mode = Control.FOCUS_NONE
	flat = true
	for st in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		add_theme_stylebox_override(st, StyleBoxEmpty.new())


func _ready() -> void:
	Fx.press_feedback(self)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)


func _draw() -> void:
	var d := minf(size.x, size.y)
	var c := size / 2.0
	var hover := is_hovered()
	draw_circle(c, d / 2.0, Color("#232E52") if hover else Color("#1A2340"))
	draw_arc(c, d / 2.0 - 0.5, 0, TAU, 48, Color("#34426C"), 1.2, true)
	if tex:
		var g := d * 0.5
		draw_texture_rect(tex, Rect2(c - Vector2(g, g) / 2.0, Vector2(g, g)), false, tint)
	if count > 0:
		var font := AppTheme.font_bold
		var txt := I18n.num(count) if count < 100 else "99+"
		var fs := int(d * 0.3)
		var tw := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var bw := maxf(tw + fs * 0.8, fs * 1.35)
		var br := Rect2(Vector2(size.x - bw * 0.85, -fs * 0.1), Vector2(bw, fs * 1.35))
		draw_colored_polygon(GlowPanel.rounded_rect(br.grow(2.5), br.size.y / 2.0 + 2.5, 6), Color("#0A0F1E"))
		draw_colored_polygon(GlowPanel.rounded_rect(br, br.size.y / 2.0, 6), Color("#EF5A5F"))
		draw_string(font, Vector2(br.position.x + (bw - tw) / 2.0, br.position.y + br.size.y * 0.76), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
