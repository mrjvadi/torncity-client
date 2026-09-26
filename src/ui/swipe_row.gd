class_name SwipeRow
extends Control
## A list row with swipe actions: drag it toward the reading start to reveal
## action buttons on the trailing side; release past half to keep them open;
## a long swipe runs the first action. Vertical drags pass through to the
## scroll container. open_actions(true) shows them (for screenshots, hints).
##
##   SwipeRow.make(row_control, [{label, key: "action:bank", color, fn}])

const BTN_W := 118.0

var row: Control
var actions: Array = []
## 1.0 = the row's natural height; tween toward 0 to collapse it away (a
## swiped-to-dismiss row), since forcing `custom_minimum_size` down would
## just lose to `row`'s own minimum size in _get_minimum_size()'s max().
var collapse := 1.0:
	set(v): collapse = v; update_minimum_size()
var _holder: Control
var _off := 0.0
var _press := Vector2.ZERO
var _dragging := false
var _decided := false
var _horizontal := false
var _off0 := 0.0


static func make(content: Control, acts: Array) -> SwipeRow:
	var s := SwipeRow.new()
	s.row = content
	s.actions = acts
	return s


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_PASS
	_holder = Control.new()
	_holder.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_holder)
	_holder.add_child(row)
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	# `row`'s natural height (its RichTextLabel autowrap especially) is not
	# known until it has been given a width, so a one-shot read here would
	# under-report it. _get_minimum_size() below stays live instead, and we
	# forward the child's own minimum-size changes so the parent VBox re-sorts
	# once wrapped text settles.
	row.minimum_size_changed.connect(update_minimum_size)
	resized.connect(_layout)
	_layout()


func _get_minimum_size() -> Vector2:
	return Vector2(0, row.get_combined_minimum_size().y * collapse) if row else Vector2.ZERO


func _dir() -> float:
	# the row slides toward the reading start
	return 1.0 if I18n.is_rtl() else -1.0


func _reveal_w() -> float:
	return BTN_W * actions.size()


func _layout() -> void:
	_holder.size = size
	_holder.position = Vector2(_off, 0)
	queue_redraw()


func open_actions(on: bool, animate := true) -> void:
	_set_off(_dir() * _reveal_w() if on else 0.0, animate)


func _set_off(v: float, animate: bool) -> void:
	if animate and not Config.headless_capture:
		create_tween().tween_method(func(x): _off = x; _layout(), _off, v, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		_off = v
		_layout()


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			_press = e.position
			_dragging = true
			_decided = false
			_horizontal = false
			_off0 = _off
		else:
			_release(e.position)
	elif e is InputEventScreenTouch:
		if e.pressed:
			_press = e.position
			_dragging = true
			_decided = false
			_horizontal = false
			_off0 = _off
		else:
			_release(e.position)
	elif (e is InputEventMouseMotion or e is InputEventScreenDrag) and _dragging:
		var d: Vector2 = e.position - _press
		if not _decided and d.length() > 12.0:
			_decided = true
			_horizontal = absf(d.x) > absf(d.y) * 1.2
		if _horizontal:
			var v := clampf(_off0 + d.x, -size.x * 0.9, size.x * 0.9)
			if signf(v) == -_dir() and v != 0.0:
				v *= 0.25   # rubber band the wrong way
			_off = v
			_layout()
			accept_event()


func _release(pos: Vector2) -> void:
	if not _dragging:
		return
	_dragging = false
	if not _horizontal:
		# a tap on a revealed action
		if absf(_off) > 1.0:
			var i := _action_at(pos)
			if i >= 0:
				_run(i)
			else:
				open_actions(false)
		return
	var pulled := _off * _dir()
	if pulled > size.x * 0.6 and not actions.is_empty():
		_run(0)
	elif pulled > _reveal_w() * 0.5:
		TelegramApp.haptic("light")
		open_actions(true)
	else:
		open_actions(false)


func _action_at(pos: Vector2) -> int:
	for i in actions.size():
		if _btn_rect(i).has_point(pos):
			return i
	return -1


func _btn_rect(i: int) -> Rect2:
	var rtl := I18n.is_rtl()
	var x := (i * BTN_W) if rtl else (size.x - (i + 1) * BTN_W)
	return Rect2(Vector2(x, 0), Vector2(BTN_W, size.y))


func _run(i: int) -> void:
	TelegramApp.haptic("medium")
	open_actions(false)
	var fn = actions[i].get("fn")
	if fn is Callable and (fn as Callable).is_valid():
		fn.call()


func _draw() -> void:
	if absf(_off) < 0.5:
		return
	for i in actions.size():
		var r := _btn_rect(i).grow(-4)
		var c: Color = actions[i].get("color", Color("#2EC4B6"))
		draw_colored_polygon(GlowPanel.rounded_rect(r, 18, 6), c)
		var g := AssetLib.glyph(str(actions[i].get("key", "")))
		var tex: Texture2D = g.get("texture")
		var font := AppTheme.font_bold
		var label := str(actions[i].get("label", ""))
		if tex:
			draw_texture_rect(tex, Rect2(r.get_center() - Vector2(20, 34), Vector2(40, 40)), false, Color.WHITE)
		var tw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
		draw_string(font, Vector2(r.get_center().x - tw / 2.0, r.get_center().y + 30), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
