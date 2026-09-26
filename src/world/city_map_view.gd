class_name CityMapView
extends Control
## The player's city as an isometric diorama: a parallax sky and mountains, an
## island of lots joined by roads with a little traffic, the place buildings,
## the walking player, name tags, and a day/night tint on Tehran time.
## Drag to pan, pinch or wheel to zoom, tap a building to select it.

signal place_tapped(code: String)

const TEHRAN_UTC_OFFSET := 3.5 * 3600.0
## The place art's world origin, in 256-px-wide art space: (128, 150) on the
## 256 x 256 vector canvas, (128, 214) on the taller 256 x 352 render canvas.
const ART_ANCHOR := Vector2(128, 150)
const ART_ANCHOR_TALL := Vector2(128, 214)
## Scenery for lots no game place uses (not tappable).
const FILLERS := ["_hq", "_hotel", "_warehouse", "_mall", "_lab"]


static func art_anchor(tex: Texture2D) -> Vector2:
	if tex and float(tex.get_height()) / float(tex.get_width()) > 1.2:
		return ART_ANCHOR_TALL
	return ART_ANCHOR
const HIT_HEIGHT := 120.0

## Screenshot/test hook: a fixed hour of the day (-1 = the real Tehran clock).
static var force_hour := -1.0

var places: Array = []
var slots := {}
var here := ""
var selected := ""
var zoom := 0.7
var pan := Vector2.ZERO
var night := 0.0

var world: Node2D
var ground: Node2D
var buildings: Node2D
var glow: Node2D
var walker: Walker
var labels: Control
var _sprites := {}
var _chips := {}
var _route := PackedVector2Array()
var _walk_from := 0.0
var _walk_left := 0.0
var _walk_total := 1.0
var _walk_to := ""
var _touches := {}
var _press_pos := Vector2.ZERO
var _dragging := false
var _pinch_d := 0.0
var _time := 0.0
var _cars: Array = []
var _clouds: Array = []
var _fitted := false
var _pulse := {}


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	world = Node2D.new()
	add_child(world)
	ground = Node2D.new()
	ground.draw.connect(_draw_ground)
	world.add_child(ground)
	buildings = Node2D.new()
	buildings.y_sort_enabled = false
	world.add_child(buildings)
	glow = Node2D.new()
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = mat
	glow.draw.connect(_draw_glow)
	world.add_child(glow)
	walker = Walker.new()
	labels = Control.new()
	labels.mouse_filter = Control.MOUSE_FILTER_IGNORE
	labels.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(labels)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 9:
		var horizontal := i % 2 == 0
		_cars.append({"line": rng.randi_range(0, CityLayout.N - 1), "x": horizontal, "t": rng.randf(),
			"speed": rng.randf_range(0.025, 0.05) * (1 if rng.randf() > 0.5 else -1),
			"color": AppTheme.col(["pomegranate", "saffron", "sky", "white", "turquoise", "leaf"][i % 6])})
	for i in 5:
		_clouds.append({"x": rng.randf(), "y": rng.randf_range(0.02, 0.26), "s": rng.randf_range(0.7, 1.4), "v": rng.randf_range(0.004, 0.012)})
	resized.connect(_fit)


# -- data ------------------------------------------------------------------------------------
func set_view(v: Dictionary) -> void:
	places = v.get("places", []) if v.get("places") is Array else []
	var codes := []
	here = ""
	for p in places:
		var code := str(p.get("place", {}).get("code", ""))
		codes.append(code)
		if p.get("here", false):
			here = code
	if here == "" and v.get("here") is Dictionary:
		here = str(v["here"].get("code", ""))
	slots = CityLayout.assign(codes)
	_build_buildings()
	# walking?
	var w = v.get("walking")
	if w is Dictionary and w.get("to") is Dictionary:
		var to := str(w["to"].get("code", ""))
		var total := 0.0
		for p in places:
			if str(p.get("place", {}).get("code", "")) == to:
				total = float(p.get("walk_seconds", 0))
		var left := float(w.get("remaining_seconds", 0))
		var from := here if here != "" and here != to else _nearest_other(to)
		start_walk(from, to, left, maxf(total, left))
	else:
		_walk_to = ""
		_place_walker_at(here)
	if selected == "" or not slots.has(selected):
		selected = here
	_build_labels()
	_fit()
	queue_redraw()


func _nearest_other(to: String) -> String:
	for c in slots:
		if c != to:
			return c
	return to


func _build_buildings() -> void:
	if walker.get_parent() == buildings:
		buildings.remove_child(walker)
	for c in buildings.get_children():
		buildings.remove_child(c)
		c.queue_free()
	_sprites.clear()
	# empty lots get a plaza or a green lot so the island is never gappy
	var taken := {}
	for c in slots:
		taken[slots[c]] = true
	var entries := []
	for c in slots:
		entries.append([c, slots[c]])
	for j in CityLayout.N:
		for i in CityLayout.N:
			var s := Vector2i(i, j)
			if not taken.has(s):
				entries.append([FILLERS[(i * 3 + j) % FILLERS.size()], s])
	entries.sort_custom(func(a, b): return (a[1].x + a[1].y) < (b[1].x + b[1].y) or ((a[1].x + a[1].y) == (b[1].x + b[1].y) and a[1].x < b[1].x))
	for e in entries:
		var code: String = e[0]
		var tex := AppTheme.tex("place/" + code)
		if tex == null:
			tex = AppTheme.tex("place/_empty")
		var sp := Sprite2D.new()
		sp.texture = tex
		sp.centered = false
		sp.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		var k := 256.0 / float(tex.get_width()) if tex else 1.0
		sp.scale = Vector2(k, k)
		sp.offset = -art_anchor(tex) / k
		sp.position = CityLayout.project(CityLayout.lot_origin(e[1]))
		sp.set_meta("code", code)
		buildings.add_child(sp)
		if not code.begins_with("_"):
			_sprites[code] = sp
		# the walker is drawn right after the lot row it stands in front of
	buildings.add_child(walker)


func _place_walker_at(code: String) -> void:
	if not slots.has(code):
		walker.visible = false
		return
	walker.visible = true
	walker.position = CityLayout.project(CityLayout.door(slots[code]))
	walker.set_walking(false, "sw")
	_sort_walker()


## Start (or resume) the walk animation: `left` seconds to go of `total`.
func start_walk(from: String, to: String, left: float, total: float) -> void:
	if not slots.has(from) or not slots.has(to):
		_place_walker_at(to)
		return
	_route = CityLayout.route(slots[from], slots[to])
	_walk_to = to
	_walk_total = maxf(total, 0.5)
	_walk_left = clampf(left, 0.0, _walk_total)
	_walk_from = 1.0 - _walk_left / _walk_total
	walker.visible = true
	_update_walker()


## The walk is over: snap to the door and celebrate.
func arrive(code: String) -> void:
	_walk_to = ""
	here = code
	selected = code
	_place_walker_at(code)
	walker.celebrate()
	pulse_place(code)
	Fx.sparkle(self, to_screen(CityLayout.project(CityLayout.door(slots.get(code, Vector2i.ZERO)))) + Vector2(0, -40))
	_build_labels()


func pulse_place(code: String) -> void:
	if not _sprites.has(code) or Config.headless_capture:
		return
	var sp: Sprite2D = _sprites[code]
	var base := sp.scale
	var t := sp.create_tween()
	t.tween_property(sp, "scale", base * Vector2(1.04, 0.97), 0.12)
	t.tween_property(sp, "scale", base, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _update_walker() -> void:
	if _walk_to == "" or _route.is_empty():
		return
	var t := 1.0 - _walk_left / _walk_total
	var p := CityLayout.along(_route, t)
	var ahead := CityLayout.along(_route, minf(1.0, t + 0.02))
	walker.position = CityLayout.project(p)
	walker.set_walking(_walk_left > 0.0, CityLayout.facing(ahead - p) if ahead.distance_to(p) > 0.01 else walker.facing)
	_sort_walker()


## Keep the walker between the lots behind and in front of it. Lots never
## overlap, so both row-major and column-major are valid painter's orders; on
## a road along x the walker splits the rows, on a road along y the columns.
func _sort_walker() -> void:
	var w := CityLayout.unproject(walker.position)
	var st := CityLayout.step()
	var on_row := fposmod(w.y, st) > CityLayout.LOT - 0.5
	var lots := []
	for c in buildings.get_children():
		if c != walker:
			lots.append(c)
	var key := func(n: Node) -> Vector2i:
		var s := Vector2i((CityLayout.unproject(n.position) / st).round())
		return Vector2i(s.y, s.x) if on_row else Vector2i(s.x, s.y)
	lots.sort_custom(func(a, b): return key.call(a) < key.call(b))
	var split := int(floor(w.y / st)) if on_row else int(floor(w.x / st))
	var i := 0
	var placed := false
	for n in lots:
		if not placed and key.call(n).x > split:
			buildings.move_child(walker, i)
			i += 1
			placed = true
		buildings.move_child(n, i)
		i += 1
	if not placed:
		buildings.move_child(walker, i)


# -- labels --------------------------------------------------------------------------------------
func _build_labels() -> void:
	for c in labels.get_children():
		c.queue_free()
	_chips.clear()
	for p in places:
		var code := str(p.get("place", {}).get("code", ""))
		if not slots.has(code):
			continue
		var name := I18n.name_of("place", code, str(p["place"].get("name", code)))
		var chip := PanelContainer.new()
		var sb := AppTheme.box(AppTheme.col("ink", 0.78), 16, AppTheme.col("turquoise") if code == here else AppTheme.col("saffron") if code == selected else AppTheme.col("line", 0.0), 2 if (code == here or code == selected) else 0, 0, 0)
		sb.content_margin_left = 12
		sb.content_margin_right = 12
		sb.content_margin_top = 4
		sb.content_margin_bottom = 4
		chip.add_theme_stylebox_override("panel", sb)
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var row := UI.hbox(6)
		if code == here:
			row.add_child(UI.icon("pin", 24))
		var l := UI.label(name, "SmallLabel")
		l.add_theme_font_size_override("font_size", 18)
		row.add_child(l)
		if code != here and code == selected:
			row.add_child(UI.icon("walk", 20))
			var t := UI.label(I18n.dur(int(p.get("walk_seconds", 0))), "DimLabel")
			t.add_theme_font_size_override("font_size", 17)
			row.add_child(t)
		chip.add_child(row)
		labels.add_child(chip)
		_chips[code] = chip
	_position_labels()


func _position_labels() -> void:
	for code in _chips:
		var chip: Control = _chips[code]
		# on the ground at the front of the lot, so tags never pile up over the towers
		var anchor := CityLayout.project(CityLayout.lot_origin(slots[code]) + Vector2(CityLayout.LOT, CityLayout.LOT) * 0.86)
		var p := to_screen(anchor)
		chip.reset_size()
		var pos := p - Vector2(chip.size.x / 2.0, chip.size.y * 0.5)
		# keep tags readable at the edges of the view
		pos.x = clampf(pos.x, 6.0, maxf(6.0, size.x - chip.size.x - 6.0))
		chip.position = pos
		chip.visible = Rect2(Vector2(-40, -30), size + Vector2(80, 60)).has_point(p)


func select(code: String) -> void:
	selected = code
	_build_labels()


# -- camera ---------------------------------------------------------------------------------------
func to_screen(map_px: Vector2) -> Vector2:
	return pan + map_px * zoom


func _map_bounds() -> Rect2:
	var s := CityLayout.size()
	var pts := [CityLayout.project(Vector2(-40, -40)), CityLayout.project(Vector2(s + 40, -40)),
		CityLayout.project(Vector2(s + 40, s + 40)), CityLayout.project(Vector2(-40, s + 40))]
	var r := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		r = r.expand(p)
	r.position.y -= 150  # the tallest towers
	r.size.y += 150 + 30
	return r


func _fit() -> void:
	if size.x < 10:
		return
	var b := _map_bounds()
	if not _fitted:
		# big enough to read the buildings on a phone; pan for the edges
		zoom = clampf(size.x / (b.size.x * 0.78), 0.45, 1.4)
		_fitted = true
	var focus := b.get_center()
	if slots.has(here):
		focus = focus.lerp(CityLayout.project(CityLayout.lot_center(slots[here])), 0.6)
	pan = size / 2.0 - focus * zoom
	pan.y += size.y * 0.04
	_clamp_pan()
	_apply_camera()


func _clamp_pan() -> void:
	var b := _map_bounds()
	var lo := size - (b.end * zoom) - Vector2(80, 80)
	var hi := -b.position * zoom + Vector2(80, 80)
	if lo.x > hi.x:
		pan.x = (lo.x + hi.x) / 2.0
	else:
		pan.x = clampf(pan.x, lo.x, hi.x)
	if lo.y > hi.y:
		pan.y = (lo.y + hi.y) / 2.0
	else:
		pan.y = clampf(pan.y, lo.y, hi.y)


func _apply_camera() -> void:
	world.position = pan
	world.scale = Vector2(zoom, zoom)
	_position_labels()
	queue_redraw()


func _zoom_at(point: Vector2, factor: float) -> void:
	var nz := clampf(zoom * factor, 0.45, 1.8)
	var map_pt := (point - pan) / zoom
	zoom = nz
	pan = point - map_pt * zoom
	_clamp_pan()
	_apply_camera()


func _gui_input(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		if e.pressed:
			_touches[e.index] = e.position
			if _touches.size() == 1:
				_press_pos = e.position
				_dragging = false
			elif _touches.size() == 2:
				var v := _touches.values()
				_pinch_d = v[0].distance_to(v[1])
		else:
			_touches.erase(e.index)
			if _touches.is_empty() and not _dragging:
				_tap(e.position)
		accept_event()
	elif e is InputEventScreenDrag:
		_touches[e.index] = e.position
		if _touches.size() >= 2:
			var v := _touches.values()
			var d: float = v[0].distance_to(v[1])
			if _pinch_d > 0:
				_zoom_at((v[0] + v[1]) / 2.0, d / _pinch_d)
			_pinch_d = d
			_dragging = true
		else:
			if e.position.distance_to(_press_pos) > 14:
				_dragging = true
			pan += e.relative
			_clamp_pan()
			_apply_camera()
		accept_event()
	elif e is InputEventMouseButton and e.pressed:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_at(e.position, 1.1)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_at(e.position, 1.0 / 1.1)
	elif e is InputEventMagnifyGesture:
		_zoom_at(e.position, e.factor)
	elif e is InputEventPanGesture:
		pan -= e.delta * 8.0
		_clamp_pan()
		_apply_camera()


func _tap(p: Vector2) -> void:
	# front-most lot first: its building may cover lots behind it
	var order := slots.keys()
	order.sort_custom(func(a, b): return (slots[a].x + slots[a].y) > (slots[b].x + slots[b].y))
	for code in order:
		var o := CityLayout.lot_origin(slots[code])
		var L := CityLayout.LOT
		var poly := PackedVector2Array()
		for q in [Vector2(0, 0), Vector2(L, 0), Vector2(L, L), Vector2(0, L)]:
			poly.append(to_screen(CityLayout.project(o + q)))
		# extend upward to cover the building
		var hull := PackedVector2Array([poly[3], poly[2], poly[1],
			poly[1] + Vector2(0, -HIT_HEIGHT * zoom), poly[0] + Vector2(0, -HIT_HEIGHT * zoom), poly[3] + Vector2(0, -HIT_HEIGHT * zoom)])
		if Geometry2D.is_point_in_polygon(p, hull):
			select(code)
			pulse_place(code)
			place_tapped.emit(code)
			return


# -- time ------------------------------------------------------------------------------------------
func _process(delta: float) -> void:
	_time += delta
	if _walk_to != "" and _walk_left > 0.0:
		_walk_left = maxf(0.0, _walk_left - delta)
		_update_walker()
	for c in _cars:
		c["t"] = fposmod(c["t"] + c["speed"] * delta, 1.0)
	for cl in _clouds:
		cl["x"] = fposmod(cl["x"] + cl["v"] * delta, 1.3)
	_update_daylight()
	ground.queue_redraw()
	queue_redraw()


static func tehran_hour() -> float:
	if force_hour >= 0:
		return force_hour
	var t := Time.get_unix_time_from_system() + TEHRAN_UTC_OFFSET
	return fposmod(t / 3600.0, 24.0)


## 0 = full day, 1 = deep night, with dawn and dusk ramps.
static func night_amount(h: float) -> float:
	if h >= 7.0 and h < 17.5:
		return 0.0
	if h >= 17.5 and h < 20.0:
		return (h - 17.5) / 2.5
	if h >= 5.0 and h < 7.0:
		return 1.0 - (h - 5.0) / 2.0
	return 1.0


func _update_daylight() -> void:
	var h := tehran_hour()
	night = night_amount(h)
	var dusk := 0.0
	if h >= 16.5 and h < 20.5:
		dusk = 1.0 - absf(h - 18.5) / 2.0
	elif h >= 4.5 and h < 7.5:
		dusk = 1.0 - absf(h - 6.0) / 1.5
	var tint := Color.WHITE.lerp(Color(1.0, 0.84, 0.72), clampf(dusk, 0, 1) * 0.8)
	tint = tint.lerp(Color(0.5, 0.58, 0.9), night * 0.85)
	world.modulate = tint
	glow.modulate.a = night
	glow.queue_redraw()


# -- drawing ----------------------------------------------------------------------------------------
func _draw() -> void:
	# sky: a vertical gradient that follows the time of day
	var day_top := Color("#7FC8F0")
	var day_bot := Color("#DDF1F7")
	var dusk_top := Color("#5B4E9A")
	var dusk_bot := Color("#F7A86B")
	var night_top := Color("#0D1330")
	var night_bot := Color("#2A3563")
	var h := tehran_hour()
	var dusk := 0.0
	if h >= 16.5 and h < 20.5:
		dusk = 1.0 - absf(h - 18.5) / 2.0
	var top := day_top.lerp(dusk_top, dusk).lerp(night_top, night)
	var bot := day_bot.lerp(dusk_bot, dusk).lerp(night_bot, night)
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]),
		PackedColorArray([top, top, bot, bot]))
	# stars at night
	if night > 0.2:
		var rng := RandomNumberGenerator.new()
		rng.seed = 5
		for i in 40:
			var sp := Vector2(rng.randf() * size.x, rng.randf() * size.y * 0.45)
			var tw := 0.5 + 0.5 * sin(_time * 2.0 + i)
			draw_circle(sp, 1.2 + rng.randf(), Color(1, 1, 1, night * (0.4 + 0.5 * tw)))
	# parallax mountains (Alborz-like ridges), far then near
	var par := pan - size / 2.0
	_ridge(size.y * 0.30 + par.y * 0.08, par.x * 0.10, 90.0, 7, top.lerp(bot, 0.55).darkened(0.12), 1)
	_ridge(size.y * 0.38 + par.y * 0.16, par.x * 0.2, 70.0, 11, top.lerp(bot, 0.75).darkened(0.25), 2)
	# snow caps on the far ridge in daylight
	# clouds
	for cl in _clouds:
		var cx: float = cl["x"] * (size.x + 300) - 150 + par.x * 0.05
		var cy: float = cl["y"] * size.y + par.y * 0.05
		var s: float = cl["s"]
		var cc := Color(1, 1, 1, 0.75 - night * 0.55)
		for b in [[0, 0, 26], [28, -10, 32], [60, 0, 24], [30, 8, 26]]:
			draw_circle(Vector2(cx + b[0] * s, cy + b[1] * s), b[2] * s, cc)


func _ridge(base_y: float, shift: float, amp: float, peaks: int, c: Color, seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var pts := PackedVector2Array([Vector2(0, size.y)])
	var n := peaks * 2 + 2
	var w := size.x + 400
	for i in n + 1:
		var x := -200 + w * i / n + fposmod(shift, w / n) - w / n
		var y := base_y - (amp * rng.randf_range(0.55, 1.0) if i % 2 == 1 else amp * rng.randf_range(0.0, 0.35))
		pts.append(Vector2(x, y))
	pts.append(Vector2(size.x + 400, size.y))
	draw_colored_polygon(pts, c)


func _island_poly(margin: float, z := 0.0) -> PackedVector2Array:
	var s := CityLayout.size()
	return PackedVector2Array([CityLayout.project(Vector2(-margin, -margin), z), CityLayout.project(Vector2(s + margin, -margin), z),
		CityLayout.project(Vector2(s + margin, s + margin), z), CityLayout.project(Vector2(-margin, s + margin), z)])


func _draw_ground() -> void:
	var s := CityLayout.size()
	var m := 34.0
	var P := AppTheme.C
	# water around the island, with a shimmer
	var water := _island_poly(m + 70)
	ground.draw_colored_polygon(water, Color(P["water"]).darkened(0.12))
	for i in 7:
		var k := fposmod(_time * 0.12 + i / 7.0, 1.0)
		var ring := _island_poly(m + 12 + k * 60)
		ring.append(ring[0])
		ground.draw_polyline(ring, Color(1, 1, 1, 0.22 * (1.0 - k)), 2.0, true)
	# island slab: two visible sides then the top
	var top := _island_poly(m)
	var depth := 26.0
	ground.draw_colored_polygon(PackedVector2Array([top[3], top[2], top[2] + Vector2(0, depth), top[3] + Vector2(0, depth)]), Color(P["earth"]))
	ground.draw_colored_polygon(PackedVector2Array([top[2], top[1], top[1] + Vector2(0, depth), top[2] + Vector2(0, depth)]), Color(P["earth_dk"]))
	ground.draw_colored_polygon(PackedVector2Array([top[3] + Vector2(0, depth * 0.35), top[2] + Vector2(0, depth * 0.35), top[2] + Vector2(0, depth * 0.5), top[3] + Vector2(0, depth * 0.5)]), Color(P["earth_dk"]).darkened(0.1))
	ground.draw_colored_polygon(top, Color(P["grass"]))
	ground.draw_colored_polygon(_island_poly(m - 8), Color(P["grass_dk"]).lerp(Color(P["grass"]), 0.5))
	# roads: the grid between lots, plus the ring road
	var asphalt := Color(P["asphalt"])
	var R := CityLayout.ROAD
	var st := CityLayout.step()
	var L := CityLayout.LOT
	for k in range(-1, CityLayout.N):
		var c0 := k * st + L if k >= 0 else -R
		# along x (rows)
		_road_quad(Vector2(-R, c0), Vector2(s + R, c0 + R), asphalt)
		# along y (columns)
		_road_quad(Vector2(c0, -R), Vector2(c0 + R, s + R), asphalt)
	# centre dashes
	for k in range(-1, CityLayout.N):
		var c := (k * st + L if k >= 0 else -R) + R / 2.0
		var x := -R
		while x < s + R:
			_road_quad(Vector2(x, c - 0.9), Vector2(x + 9, c + 0.9), Color(1, 1, 1, 0.55))
			_road_quad(Vector2(c - 0.9, x), Vector2(c + 0.9, x + 9), Color(1, 1, 1, 0.55))
			x += 22
	# traffic
	for car in _cars:
		var lane: int = car["line"]
		var c := lane * st + L + R * (0.3 if car["speed"] > 0 else 0.7)
		var along: float = -R + car["t"] * (s + 2 * R)
		var w := Vector2(along, c) if car["x"] else Vector2(c, along)
		var dirv := Vector2(1, 0) if car["x"] else Vector2(0, 1)
		_car(w, dirv, car["color"])


func _road_quad(a: Vector2, b: Vector2, c: Color) -> void:
	ground.draw_colored_polygon(PackedVector2Array([CityLayout.project(a), CityLayout.project(Vector2(b.x, a.y)),
		CityLayout.project(b), CityLayout.project(Vector2(a.x, b.y))]), c)


func _car(w: Vector2, d: Vector2, c: Color) -> void:
	var side := Vector2(-d.y, d.x)
	var l := 9.0
	var wd := 5.0
	var h := 5.0
	var base := [w - d * l / 2 - side * wd / 2, w + d * l / 2 - side * wd / 2, w + d * l / 2 + side * wd / 2, w - d * l / 2 + side * wd / 2]
	var bot := PackedVector2Array()
	var topp := PackedVector2Array()
	for q in base:
		bot.append(CityLayout.project(q))
		topp.append(CityLayout.project(q, h))
	ground.draw_colored_polygon(PackedVector2Array([bot[0] + Vector2(3, 2), bot[1] + Vector2(3, 2), bot[2] + Vector2(3, 2), bot[3] + Vector2(3, 2)]), Color(0, 0, 0, 0.18))
	ground.draw_colored_polygon(PackedVector2Array([bot[2], bot[3], topp[3], topp[2]]), c.darkened(0.15))
	ground.draw_colored_polygon(PackedVector2Array([bot[1], bot[2], topp[2], topp[1]]), c.darkened(0.3))
	ground.draw_colored_polygon(topp, c.lightened(0.2))


func _draw_glow() -> void:
	if night <= 0.01:
		return
	for code in _sprites:
		var p := CityLayout.project(CityLayout.lot_center(slots[code]), 20)
		for i in 4:
			glow.draw_circle(p, 70.0 - i * 15.0, Color(1.0, 0.7, 0.3, 0.05 + i * 0.02))
	# street lamps along the roads
	var st := CityLayout.step()
	for i in CityLayout.N:
		for j in CityLayout.N:
			var p := CityLayout.project(Vector2(i * st + CityLayout.LOT + 15, j * st + CityLayout.LOT + 15))
			glow.draw_circle(p, 16, Color(1.0, 0.8, 0.45, 0.12))
			glow.draw_circle(p, 5, Color(1.0, 0.85, 0.5, 0.35))
