class_name ActionTile
extends Button
## A square action tile: a badge icon over a short label, on a raised navy
## card (the reference kit's Attack / Travel / Work grid). Spring press,
## hover lift, dimmed when disabled.

var action := {}
var _badge: IconBadge
var _host: Node


static func make(a: Dictionary, host: Node) -> ActionTile:
	var t := ActionTile.new()
	t.action = a
	t._host = host
	return t


func _init() -> void:
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(0, 150)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	flat = true
	for st in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		add_theme_stylebox_override(st, StyleBoxEmpty.new())


func _ready() -> void:
	var box := UI.vbox(8)
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	_badge = IconBadge.make(ActionKit.glyph_of(action), 64)
	_badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(_badge)
	var l := UI.label(ActionKit.label_of(action), "SmallLabel", HORIZONTAL_ALIGNMENT_CENTER)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.max_lines_visible = 2
	l.add_theme_font_size_override("font_size", 20)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.custom_minimum_size.x = 60
	box.add_child(l)
	disabled = bool(action.get("disabled", false))
	pressed.connect(func(): ActionKit.run(action, _host))
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	Fx.press_feedback(self)


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var hover := is_hovered() and not disabled
	var down := is_pressed() or button_pressed
	var danger := ActionKit.kind_of(action) in ["danger", "confirm"]
	var top := Color("#1F3150") if not hover else Color("#26406A")
	var bottom := Color("#132139")
	# shadow
	var sh := GlowPanel.rounded_rect(Rect2(r.position + Vector2(0, 5 if not down else 2), r.size), 12, 6)
	draw_colored_polygon(sh, Color(0, 0, 0, 0.32))
	var pts := GlowPanel.rounded_rect(r, 12, 6)
	var cols := PackedColorArray()
	for p in pts:
		cols.append(top.lerp(bottom, p.y / maxf(1.0, size.y)))
	draw_polygon(pts, cols)
	var border := pts.duplicate()
	border.append(pts[0])
	var bc := Color("#EB5757", 0.7) if danger else (Color("#5B9CF2", 0.9) if hover else Color("#2B4468"))
	draw_polyline(border, bc, 1.2, true)
	draw_line(Vector2(12, 2), Vector2(size.x - 12, 2), Color(1, 1, 1, 0.07 if not hover else 0.12), 1.5)
	modulate = Color(1, 1, 1, 0.45) if disabled else Color.WHITE
