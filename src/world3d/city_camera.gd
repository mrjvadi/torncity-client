class_name CityCamera
extends Camera3D
## The city camera: orthographic, fixed isometric angle. Touch: one finger
## pans (with inertia), two fingers pinch-zoom about their midpoint, a short
## touch is a tap. Mouse: drag pans, the wheel zooms at the cursor, a click is
## a tap. The target stays inside `bounds`; the zoom inside min/max.
##
## Feed it the viewport's input with handle(event) (positions in the
## SubViewport's pixels).

signal tapped(screen_pos: Vector2)

const PITCH := -30.0
const YAW := 45.0
const TAP_SLOP := 14.0
const TAP_TIME := 0.35
const FRICTION := 5.5

var target := Vector3.ZERO
var zoom := 12.0              # orthographic size (world units tall)
var min_zoom := 4.0
var max_zoom := 24.0
var bounds := Rect2(-8, -8, 16, 16)   # x/z

var _touches := {}            # index -> position
var _vel := Vector2.ZERO      # world units / s on the ground plane (x, z)
var _dragging := false
var _press_pos := Vector2.ZERO
var _press_t := 0.0
var _moved := false
var _pinch_d0 := 0.0
var _pinch_z0 := 0.0
var _last_move_t := 0.0
var _mouse_down := false


func _ready() -> void:
	projection = PROJECTION_ORTHOGONAL
	rotation_degrees = Vector3(PITCH, YAW, 0)
	near = 0.1
	far = 600.0
	_apply()


func look_at_point(p: Vector3, z := -1.0, animate := true) -> void:
	var t := _clamp(p)
	var nz := clampf(z if z > 0 else zoom, min_zoom, max_zoom)
	if animate and not Config.headless_capture and is_inside_tree():
		_vel = Vector2.ZERO
		var tw := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_method(func(v): target = v; _apply(), target, t, 0.5)
		tw.tween_method(func(v): zoom = v; _apply(), zoom, nz, 0.5)
	else:
		target = t
		zoom = nz
		_apply()


func _apply() -> void:
	size = zoom
	# sit far back along the view direction; orthographic, so distance only matters for clipping
	position = target + Basis.from_euler(rotation).z * 200.0


func _clamp(p: Vector3) -> Vector3:
	return Vector3(clampf(p.x, bounds.position.x, bounds.end.x), 0.0, clampf(p.z, bounds.position.y, bounds.end.y))


## World units per screen pixel on the ground, and the screen axes on the ground.
func _ground_axes() -> Array:
	var vp_h := float(get_viewport().get_visible_rect().size.y)
	var upp := zoom / maxf(1.0, vp_h)
	var b := global_transform.basis
	var right := Vector3(b.x.x, 0, b.x.z).normalized()
	var fwd := Vector3(-b.z.x, 0, -b.z.z).normalized()
	return [upp, right, fwd]


func pan_pixels(d: Vector2) -> Vector3:
	var a := _ground_axes()
	var upp: float = a[0]
	var move: Vector3 = -a[1] * d.x * upp + a[2] * d.y * upp / sin(deg_to_rad(-PITCH))
	target = _clamp(target + move)
	_apply()
	return move


## The ground point under a screen position.
func ground_at(screen: Vector2) -> Vector3:
	var o := project_ray_origin(screen)
	var n := project_ray_normal(screen)
	if absf(n.y) < 1e-4:
		return target
	var t := -o.y / n.y
	return o + n * t


func zoom_at(screen: Vector2, factor: float) -> void:
	var before := ground_at(screen)
	zoom = clampf(zoom * factor, min_zoom, max_zoom)
	_apply()
	var after := ground_at(screen)
	target = _clamp(target + (before - after))
	_apply()


func handle(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var e := event as InputEventScreenTouch
		if e.pressed:
			_touches[e.index] = e.position
			if _touches.size() == 1:
				_begin(e.position)
			elif _touches.size() == 2:
				var ps: Array = _touches.values()
				_pinch_d0 = (ps[0] as Vector2).distance_to(ps[1])
				_pinch_z0 = zoom
				_moved = true
		else:
			_touches.erase(e.index)
			if _touches.is_empty():
				_end(e.position)
			elif _touches.size() == 1:
				_press_pos = _touches.values()[0]
	elif event is InputEventScreenDrag:
		var e := event as InputEventScreenDrag
		_touches[e.index] = e.position
		if _touches.size() >= 2:
			var ps: Array = _touches.values()
			var d := (ps[0] as Vector2).distance_to(ps[1])
			if _pinch_d0 > 1.0 and d > 1.0:
				var mid: Vector2 = ((ps[0] as Vector2) + (ps[1] as Vector2)) / 2.0
				var before := ground_at(mid)
				zoom = clampf(_pinch_z0 * _pinch_d0 / d, min_zoom, max_zoom)
				_apply()
				target = _clamp(target + (before - ground_at(mid)))
				_apply()
		else:
			_drag(e.position, e.relative)
	elif event is InputEventMouseButton:
		var e := event as InputEventMouseButton
		if e.button_index == MOUSE_BUTTON_WHEEL_UP and e.pressed:
			zoom_at(e.position, 0.9)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN and e.pressed:
			zoom_at(e.position, 1.0 / 0.9)
		elif e.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			if e.pressed:
				_mouse_down = true
				_begin(e.position)
			elif _mouse_down:
				_mouse_down = false
				_end(e.position)
	elif event is InputEventMouseMotion and _mouse_down:
		var e := event as InputEventMouseMotion
		_drag(e.position, e.relative)
	elif event is InputEventMagnifyGesture:
		zoom_at((event as InputEventMagnifyGesture).position, 1.0 / (event as InputEventMagnifyGesture).factor)
	elif event is InputEventPanGesture:
		pan_pixels(-(event as InputEventPanGesture).delta * 12.0)


func _begin(pos: Vector2) -> void:
	_dragging = true
	_moved = false
	_press_pos = pos
	_press_t = Time.get_ticks_msec() / 1000.0
	_vel = Vector2.ZERO


func _drag(pos: Vector2, rel: Vector2) -> void:
	if not _dragging:
		return
	if not _moved and pos.distance_to(_press_pos) < TAP_SLOP:
		return
	_moved = true
	var now := Time.get_ticks_msec() / 1000.0
	var dt := maxf(now - _last_move_t, 1.0 / 240.0)
	_last_move_t = now
	var m := pan_pixels(rel)
	# smoothed release velocity
	var v := Vector2(m.x, m.z) / dt
	_vel = _vel.lerp(v, 0.35)


func _end(pos: Vector2) -> void:
	_dragging = false
	var held := Time.get_ticks_msec() / 1000.0 - _press_t
	if not _moved and held < TAP_TIME and pos.distance_to(_press_pos) < TAP_SLOP:
		_vel = Vector2.ZERO
		tapped.emit(pos)
	elif Time.get_ticks_msec() / 1000.0 - _last_move_t > 0.08:
		_vel = Vector2.ZERO   # the finger stopped before lifting: no fling


func _process(delta: float) -> void:
	if _dragging or _vel.length() < 0.02:
		return
	target = _clamp(target + Vector3(_vel.x, 0, _vel.y) * delta)
	_vel *= exp(-FRICTION * delta)
	# stop at the bounds instead of sliding along them forever
	if target.x <= bounds.position.x or target.x >= bounds.end.x:
		_vel.x = 0
	if target.z <= bounds.position.y or target.z >= bounds.end.y:
		_vel.y = 0
	_apply()
