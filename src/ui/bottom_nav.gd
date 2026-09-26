class_name BottomNav
extends GlassPanel
## The tab bar, floating on glass: line icons with labels; behind the active
## tab a soft turquoise pill with a bright top bar slides (spring) from tab
## to tab, and the active icon and label turn turquoise. Tabs: the content catalogue's ui.tabs when the
## server sends them, else the client's default set (ViewRouter.TABS).

signal tab_pressed(tab: String)

var active := "map"
var _buttons := {}
var _row: HBoxContainer
var _pill: _Pill


class _Pill extends Control:
	var x := -1.0
	var w := 90.0

	func _draw() -> void:
		if x < 0:
			return
		var c := AppTheme.col("primary")
		var r := Rect2(Vector2(x - w / 2.0, 4), Vector2(w, size.y - 8))
		draw_colored_polygon(GlowPanel.rounded_rect(r, 22, 8), Color(c, 0.14))
		# a short bright bar on the top edge marks the tab
		var bw := minf(36.0, w * 0.4)
		draw_colored_polygon(GlowPanel.rounded_rect(Rect2(x - bw / 2.0, 0, bw, 5), 2.5, 3), c)


func _init() -> void:
	radius = 30
	pad = Vector4(8, 8, 8, 8)


func _ready() -> void:
	super._ready()
	var stack := Control.new()
	stack.custom_minimum_size = Vector2(0, 88)
	add_child(stack)
	_pill = _Pill.new()
	_pill.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(_pill)
	_row = UI.hbox(0)
	_row.set_anchors_preset(Control.PRESET_FULL_RECT)
	stack.add_child(_row)
	_build()
	I18n.changed.connect(func(_l): _build())
	Content.changed.connect(_build)
	resized.connect(func(): _move_pill(false))


func _tabs() -> Array:
	var out: Array = []
	var server := Content.tabs()
	if not server.is_empty():
		for t in server:
			out.append({"key": str(t.get("key", "")), "label": _loc(t.get("label", "")), "icon": str(t.get("icon", "")), "command": str(t.get("command", ""))})
		return out
	for key in ViewRouter.TAB_ORDER:
		var info: Dictionary = ViewRouter.TABS[key]
		out.append({"key": key, "label": I18n.t(info["label"]), "icon": str(info["icon"]), "command": str(info["command"])})
	return out


static func _loc(v) -> String:
	return str(v.get(I18n.lang, v.get("en", ""))) if v is Dictionary else str(v)


func _build() -> void:
	UI.clear(_row)
	_buttons.clear()
	for t in _tabs():
		var key: String = t.key
		var b := Button.new()
		b.theme_type_variation = "NavButton"
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		var icon_key: String = t.icon
		b.icon = AppTheme.icon(icon_key) if icon_key.begins_with("ln_") else AppTheme.icon("ln_" + icon_key.split(":")[-1])
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.add_theme_constant_override("icon_max_width", 34)
		b.add_theme_font_size_override("font_size", 17)
		b.text = t.label
		b.clip_text = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func(): select(key); TelegramApp.haptic("light"); tab_pressed.emit(key))
		Fx.press_feedback(b)
		_buttons[key] = b
		_row.add_child(b)
	select(active)


func select(tab: String) -> void:
	active = tab
	for t in _buttons:
		var on: bool = t == tab
		var b: Button = _buttons[t]
		b.set_pressed_no_signal(on)
		var ic := AppTheme.col("primary") if on else AppTheme.col("text_2")
		for k in ["icon_normal_color", "icon_pressed_color", "icon_hover_color", "icon_hover_pressed_color", "icon_focus_color"]:
			b.add_theme_color_override(k, ic)
		b.add_theme_color_override("font_color", ic)
		b.add_theme_color_override("font_pressed_color", ic)
		b.add_theme_color_override("font_hover_pressed_color", ic)
	_move_pill(true)


func _move_pill(animate: bool) -> void:
	if not _buttons.has(active):
		_pill.x = -1.0
		_pill.queue_redraw()
		return
	await get_tree().process_frame
	if not _buttons.has(active):
		return
	var b: Button = _buttons[active]
	var target := b.position.x + b.size.x / 2.0
	_pill.w = minf(b.size.x - 6.0, 96.0)
	if animate and not Config.headless_capture and _pill.x >= 0.0:
		create_tween().tween_method(func(x): _pill.x = x; _pill.queue_redraw(), _pill.x, target, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		_pill.x = target
		_pill.queue_redraw()
