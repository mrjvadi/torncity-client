class_name BottomNav
extends GlowPanel
## The tab bar: World, Map, Companies, Market, Inventory, Messages, Profile.
## Line icons, the active tab in blue with a glowing top bar that slides.

signal tab_pressed(tab: String)

var active := "map"
var _buttons := {}
var _pill_x := 0.0
var _row: HBoxContainer


func _init() -> void:
	super._init()
	radius = 0
	shadow = 14
	top_color = Color("#132139")
	bottom_color = Color("#0B1422")
	border_color = Color("#2B4468")
	highlight = Color(0, 0, 0, 0)
	padding = 4


func _ready() -> void:
	_row = UI.hbox(0)
	add_child(_row)
	for tab in ViewRouter.TAB_ORDER:
		var info: Dictionary = ViewRouter.TABS[tab]
		var b := Button.new()
		b.theme_type_variation = "NavButton"
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.icon = AppTheme.icon(info["icon"])
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.add_theme_constant_override("icon_max_width", 40)
		b.text = I18n.t(info["label"])
		b.clip_text = true
		b.custom_minimum_size = Vector2(0, 96)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func(): select(tab); tab_pressed.emit(tab))
		Fx.press_feedback(b)
		_buttons[tab] = b
		_row.add_child(b)
	I18n.changed.connect(func(_l):
		for t in _buttons: _buttons[t].text = I18n.t(ViewRouter.TABS[t]["label"]))
	resized.connect(func(): _move_pill(false))
	select(active)


func select(tab: String) -> void:
	active = tab
	for t in _buttons:
		var on: bool = t == tab
		_buttons[t].set_pressed_no_signal(on)
		_buttons[t].modulate = Color(1, 1, 1) if on else Color(0.62, 0.7, 0.82)
	_move_pill(true)


func _move_pill(animate: bool) -> void:
	if not _buttons.has(active):
		_pill_x = -1.0
		queue_redraw()
		return
	var b: Button = _buttons[active]
	await get_tree().process_frame
	var target := b.global_position.x - global_position.x + b.size.x / 2.0
	if animate and not Config.headless_capture and _pill_x > 0.0:
		create_tween().tween_method(func(x): _pill_x = x; queue_redraw(), _pill_x, target, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		_pill_x = target
		queue_redraw()


func _draw() -> void:
	super._draw()
	if _pill_x <= 0:
		return
	var w := 84.0
	var blue := AppTheme.col("blue")
	var r := Rect2(Vector2(_pill_x - w / 2.0, 6), Vector2(w, 84))
	draw_colored_polygon(GlowPanel.rounded_rect(r, 8, 6), Color(blue, 0.14))
	for i in 3:
		draw_line(Vector2(_pill_x - 26 - i * 3, 1.5 + i), Vector2(_pill_x + 26 + i * 3, 1.5 + i), Color(blue, 0.35 - i * 0.1), 2.0, true)
	draw_line(Vector2(_pill_x - 26, 1.5), Vector2(_pill_x + 26, 1.5), blue.lightened(0.2), 3.0, true)
