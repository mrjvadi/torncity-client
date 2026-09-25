class_name BottomNav
extends GlowPanel
## Five tabs: City, Me, Work, Bank, More. The active tab lifts its icon and
## sits on a glowing pill that slides between tabs.

signal tab_pressed(tab: String)

var active := "city"
var _buttons := {}
var _pill_x := 0.0
var _row: HBoxContainer


func _init() -> void:
	super._init()
	radius = 0
	shadow = 14
	top_color = Color("#222B4D")
	bottom_color = Color("#171E36")
	border_color = Color(1, 1, 1, 0.07)
	padding = 6


func _ready() -> void:
	_row = UI.hbox(0)
	add_child(_row)
	for tab in ["city", "me", "work", "bank", "more"]:
		var info: Dictionary = ViewRouter.TABS[tab]
		var b := Button.new()
		b.theme_type_variation = "NavButton"
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.icon = AppTheme.icon(info["icon"])
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.add_theme_constant_override("icon_max_width", 50)
		b.text = I18n.t(info["label"])
		b.custom_minimum_size = Vector2(0, 104)
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
		_buttons[t].set_pressed_no_signal(t == tab)
	_move_pill(true)


func _move_pill(animate: bool) -> void:
	if not _buttons.has(active):
		return
	var b: Button = _buttons[active]
	await get_tree().process_frame
	var target := b.global_position.x - global_position.x + b.size.x / 2.0
	if animate and not Config.headless_capture and _pill_x != 0.0:
		create_tween().tween_method(func(x): _pill_x = x; queue_redraw(), _pill_x, target, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		_pill_x = target
		queue_redraw()


func _draw() -> void:
	super._draw()
	if _pill_x <= 0:
		return
	var w := 118.0
	var r := Rect2(Vector2(_pill_x - w / 2.0, 10), Vector2(w, 64))
	draw_colored_polygon(GlowPanel.rounded_rect(r.grow(6), 38, 8), AppTheme.col("turquoise", 0.08))
	draw_colored_polygon(GlowPanel.rounded_rect(r, 32, 8), AppTheme.col("turquoise", 0.18))
	draw_line(Vector2(_pill_x - 22, 3), Vector2(_pill_x + 22, 3), AppTheme.col("turquoise"), 5.0, true)
