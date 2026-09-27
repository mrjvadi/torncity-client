class_name DragScroll
extends Node
## Drag-to-scroll for a ScrollContainer, by finger or mouse, over its buttons
## too. Godot's own drag scrolling only runs where the platform reports a
## touchscreen, which a web build often does not, and a press that lands on a
## button inside never reaches the container. This watches the raw input: a
## press inside the container starts tracking; once it moves past a small dead
## zone it becomes a scroll (the press is taken from the button under it) and
## carries on with momentum after release.

const DEADZONE := 12.0
const FRICTION := 5.0          # per second: how fast the fling slows
const MIN_SPEED := 30.0        # px/s below which the fling stops

var _scroll: ScrollContainer
var _start := Vector2.INF
var _last := Vector2.ZERO
var _origin := 0.0
var _dragging := false
var _velocity := 0.0
var _last_t := 0
var _cancelling := false


static func attach(s: ScrollContainer) -> DragScroll:
	var d := DragScroll.new()
	d._scroll = s
	s.add_child(d)
	return d


func _ready() -> void:
	set_process(false)


func _input(e: InputEvent) -> void:
	if _scroll == null or not _scroll.is_visible_in_tree() or _cancelling:
		return
	var press: bool = (e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT) or e is InputEventScreenTouch
	if press:
		if e.pressed:
			if _scroll.get_global_rect().has_point(e.position) and _on_top(e.position):
				_start = e.position
				_last = e.position
				_origin = _scroll.scroll_vertical
				_dragging = false
				_velocity = 0.0
				_last_t = Time.get_ticks_msec()
				set_process(false)
		elif _start != Vector2.INF:
			if _dragging:
				# the release ends a scroll, not a click on what is under it
				_scroll.get_viewport().set_input_as_handled()
				set_process(absf(_velocity) > MIN_SPEED)
			_start = Vector2.INF
			_dragging = false
	elif (e is InputEventMouseMotion or e is InputEventScreenDrag) and _start != Vector2.INF:
		var dy: float = e.position.y - _start.y
		if not _dragging:
			if absf(dy) < DEADZONE:
				return
			_dragging = true
			_cancel_press()
		var now := Time.get_ticks_msec()
		var dt := maxf(float(now - _last_t) / 1000.0, 0.001)
		var step: float = e.position.y - _last.y
		_velocity = lerpf(_velocity, -step / dt, 0.4)
		_last = e.position
		_last_t = now
		_scroll.scroll_vertical = int(_origin - dy)
		_scroll.get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_scroll.scroll_vertical = int(_scroll.scroll_vertical + _velocity * delta)
	_velocity *= maxf(0.0, 1.0 - FRICTION * delta)
	var bar := _scroll.get_v_scroll_bar()
	var at_end := _scroll.scroll_vertical <= 0 or _scroll.scroll_vertical >= int(bar.max_value - bar.page)
	if absf(_velocity) < MIN_SPEED or at_end:
		set_process(false)


## Only the topmost scroll container under the finger scrolls (a list inside a
## sheet over a screen, say).
func _on_top(p: Vector2) -> bool:
	var n: Node = _scroll.get_viewport().gui_get_hovered_control() if _scroll.get_viewport() else null
	while n != null:
		if n is ScrollContainer:
			return n == _scroll
		n = n.get_parent()
	return true


## The press went to a button under the finger; a scroll is not a click, so
## the button is told the press was released outside it.
func _cancel_press() -> void:
	var vp := _scroll.get_viewport()
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = Vector2(-10000, -10000)
	up.global_position = up.position
	_cancelling = true
	vp.push_input(up, true)
	_cancelling = false
