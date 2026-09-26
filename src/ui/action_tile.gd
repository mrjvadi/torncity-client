class_name ActionTile
extends Button
## A square action tile: a badge icon over a short label, on a flat
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
	var face := Color("#1A2340") if hover or down else Color("#131A2E")
	var pts := GlowPanel.rounded_rect(r, AppTheme.R_CARD - 4, 8)
	draw_colored_polygon(pts, face)
	var border := pts.duplicate()
	border.append(pts[0])
	var bc := Color("#EF5A5F", 0.6) if danger else (Color("#2EC4B6", 0.7) if hover else Color("#243052"))
	draw_polyline(border, bc, 1.2, true)
	modulate = Color(1, 1, 1, 0.45) if disabled else Color.WHITE
