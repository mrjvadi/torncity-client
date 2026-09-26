class_name CityWorld3D
extends Node3D
## The 3D city, built from a WorldModel with models from the AssetLib:
## ground, water, road pieces, a paved base and a model per plot, name tags,
## traffic, chimney smoke, the player's marker and the selection. Picking is a
## ray against each plot's bounds (no physics needed).

signal plot_tapped(plot: Dictionary)

const LABEL_KINDS := ["place", "company"]

var model := WorldModel.new()
var cam: CityCamera
var selected_id := ""
var here_id := ""
var show_labels := true

var _plots := {}        # id -> Node3D (base + model + label)
var _bounds := {}       # id -> AABB (world)
var _roads: Node3D
var _traffic: Node3D
var _selector: MeshInstance3D
var _pin: Node3D
var _cars := []
var _walk := {}         # {path: [Vector3], t, total}
var _t := 0.0
var _mats := {}


func _ready() -> void:
	_environment()
	cam = CityCamera.new()
	add_child(cam)
	cam.tapped.connect(_on_tap)
	_roads = Node3D.new()
	add_child(_roads)
	_traffic = Node3D.new()
	add_child(_traffic)
	_selector = MeshInstance3D.new()
	_selector.visible = false
	add_child(_selector)
	_pin = _make_pin()
	add_child(_pin)


# -- scene ----------------------------------------------------------------------------------------------
func _environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#1E4B66")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#A4B6DA")
	env.ambient_light_energy = 0.42
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.92
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 1.12
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -28, 0)
	sun.light_energy = 0.95
	sun.light_color = Color("#FFF1DC")
	sun.shadow_enabled = true
	sun.shadow_bias = 0.03
	sun.directional_shadow_max_distance = 60.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	add_child(sun)


func _mat(key: String, c: Color, rough := 0.9, metal := 0.0) -> StandardMaterial3D:
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = rough
		m.metallic = metal
		_mats[key] = m
	return _mats[key]


func _box(sz: Vector3, pos: Vector3, mat: Material, parent: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = sz
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


## (Re)build everything from a world description.
func build(world: Dictionary) -> void:
	model.load_world(world)
	for c in get_children():
		if c.has_meta("built"):
			c.queue_free()
	for c in _roads.get_children():
		c.queue_free()
	_plots.clear()
	_bounds.clear()
	_ground()
	_build_roads()
	for p in model.plots.values():
		_build_plot(p)
	_spawn_traffic()
	var half := Vector2(model.w, model.h) / 2.0
	cam.bounds = Rect2(-half + Vector2(1, 1), half * 2.0 - Vector2(2, 2))
	cam.max_zoom = maxf(model.w, model.h) * 1.1
	cam.min_zoom = 3.0


func _ground() -> void:
	var w := float(model.w)
	var h := float(model.h)
	var g := Node3D.new()
	g.set_meta("built", true)
	add_child(g)
	var margin := 40.0
	var side := str(model.water.get("side", ""))
	var shore := h / 2.0 + 0.6
	# land: the grid and a wide margin (cut at the shore if there is water)
	var land_end := shore if side == "south" else h / 2.0 + margin
	var land := _box(Vector3(w + margin * 2, 0.4, land_end + h / 2.0 + margin), Vector3(0, -0.21, (land_end - h / 2.0 - margin) / 2.0), _mat("grass", Color("#4E7C3A")), g)
	land.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# the city's own ground, a touch lighter, and a kerb
	_box(Vector3(w + 0.4, 0.06, h + 0.4), Vector3(0, -0.05, 0), _mat("citygrass", Color("#5B8B44")), g)
	if side == "south":
		_box(Vector3(w + margin * 2, 0.3, 0.9), Vector3(0, -0.12, shore + 0.3), _mat("sand", Color("#CDBB8A")), g)
		var sea := _box(Vector3(w + margin * 4, 0.2, margin * 2), Vector3(0, -0.28, shore + margin), _mat("sea", Color("#1F5E82"), 0.1, 0.15), g)
		sea.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# a pier and a few boats, as dressing
		var dock := AssetLib.scene("res://assets/kenney/pirate-kit/structure-platform-dock.glb")
		var ship := AssetLib.scene("res://assets/kenney/pirate-kit/ship-medium.glb")
		if dock and ship:
			for i in 3:
				var d := dock.instantiate() as Node3D
				d.scale = Vector3.ONE * 0.5
				d.position = Vector3(-w / 2.0 + 3 + i * 5.0, -0.1, shore + 1.2)
				g.add_child(d)
				var s := ship.instantiate() as Node3D
				s.scale = Vector3.ONE * 0.16
				s.rotation_degrees.y = 90
				s.position = Vector3(-w / 2.0 + 4.5 + i * 5.0, -0.25, shore + 2.8 + (i % 2) * 1.5)
				g.add_child(s)


func _build_roads() -> void:
	var open: Dictionary = AssetLib.road_open
	for t in model.roads:
		var piece := WorldModel.road_piece(model.road_mask(t), open)
		var ps := AssetLib.scene(str(AssetLib.roads.get(piece.kind, "")))
		if ps == null:
			continue
		var n := ps.instantiate() as Node3D
		n.position = model.tile_pos(t)
		n.rotation_degrees.y = piece.rot
		_roads.add_child(n)
	# street lights along the long roads
	var light := AssetLib.scene(str(AssetLib.roads.get("light", "")))
	if light:
		for t in model.roads:
			if (t.x + t.y) % 4 == 0 and model.road_mask(t) in [WorldModel.N | WorldModel.S, WorldModel.E | WorldModel.W]:
				var l := light.instantiate() as Node3D
				l.position = model.tile_pos(t) + Vector3(0.45, 0, 0.45)
				_roads.add_child(l)


func _build_plot(p: Dictionary) -> void:
	var id := str(p["id"])
	var root := Node3D.new()
	root.position = model.plot_center(p)
	add_child(root)
	root.set_meta("built", true)
	var pw := float(p.get("w", 1))
	var ph := float(p.get("h", 1))
	var kind := str(p.get("kind", ""))
	# the paved base: a raised square tile with a kerb, the reference's look
	if kind in ["place", "company"]:
		_box(Vector3(pw - 0.06, 0.08, ph - 0.06), Vector3(0, 0.02, 0), _mat("kerb", Color("#6F7680")), root)
		_box(Vector3(pw - 0.16, 0.08, ph - 0.16), Vector3(0, 0.03, 0), _mat("pave", Color("#99A0AA")), root)
	var m := AssetLib.instantiate(str(p.get("model", "")))
	if m:
		var s := minf(pw, ph) / 2.0
		m.scale = Vector3(s, s, s)
		m.position.y = 0.07 if kind in ["place", "company"] else 0.0
		m.rotation_degrees.y = float(p.get("rot", 0))
		root.add_child(m)
		root.set_meta("model", m)
		_add_fx(root, str(p.get("model", "")), s)
	_plots[id] = root
	_bounds[id] = _aabb_of(root)
	if kind in LABEL_KINDS:
		var lbl := _make_label(_plot_name(p), kind)
		lbl.position = Vector3(0, _bounds[id].end.y + 0.25, 0)
		root.add_child(lbl)
		root.set_meta("label", lbl)


func _add_fx(root: Node3D, key: String, s: float) -> void:
	var e := AssetLib.model(key)
	for fx in e.get("fx", []):
		if str(fx.get("type", "")) != "smoke":
			continue
		var at: Array = fx.get("at", [0, 0])
		var pt := CPUParticles3D.new()
		pt.amount = 14
		pt.lifetime = 3.2
		pt.emitting = not Config.headless_capture
		pt.preprocess = 3.0
		var q := QuadMesh.new()
		q.size = Vector2(0.35, 0.35)
		var sm := StandardMaterial3D.new()
		sm.albedo_color = Color(0.95, 0.95, 0.97, 0.55)
		sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		q.material = sm
		pt.mesh = q
		pt.direction = Vector3(0.3, 1, 0)
		pt.spread = 12.0
		pt.initial_velocity_min = 0.25
		pt.initial_velocity_max = 0.4
		pt.gravity = Vector3(0.08, 0.02, 0)
		pt.scale_amount_min = 0.6
		pt.scale_amount_max = 1.3
		var curve := Curve.new()
		curve.add_point(Vector2(0, 0.4))
		curve.add_point(Vector2(1, 1.6))
		pt.scale_amount_curve = curve
		var grad := Gradient.new()
		grad.set_color(0, Color(1, 1, 1, 0.7))
		grad.set_color(1, Color(1, 1, 1, 0))
		pt.color_ramp = grad
		pt.position = Vector3(float(at[0]) * s, float(fx.get("y", 1.5)) * s, float(at[1]) * s)
		root.add_child(pt)


func _plot_name(p: Dictionary) -> String:
	var n = p.get("name")
	if n is Dictionary:
		return str(n.get(I18n.lang, n.get("en", "")))
	var ref = p.get("ref", {})
	if ref is Dictionary and ref.has("table"):
		return Content.name_of(str(ref["table"]), str(ref.get("code", "")), I18n.name_of(str(ref["table"]), str(ref.get("code", ""))))
	return ""


func _make_label(text: String, kind: String) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font = AppTheme.font_bold
	l.font_size = 30
	l.outline_size = 10
	l.modulate = Color.WHITE
	l.outline_modulate = Color("#0F1A2BE6") if kind == "place" else Color("#1C5FC0F0")
	l.pixel_size = 0.0065
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.render_priority = 5
	l.fixed_size = false
	return l


func _aabb_of(n: Node) -> AABB:
	var acc: Array = [null]
	_collect(n, acc)
	return acc[0] if acc[0] != null else AABB((n as Node3D).global_position - Vector3(0.5, 0, 0.5), Vector3(1, 1, 1))


func _collect(n: Node, acc: Array) -> void:
	if n is MeshInstance3D and (n as MeshInstance3D).mesh and n.is_inside_tree():
		var a: AABB = (n as MeshInstance3D).global_transform * (n as MeshInstance3D).mesh.get_aabb()
		acc[0] = a if acc[0] == null else acc[0].merge(a)
	for c in n.get_children():
		_collect(c, acc)


# -- live updates -------------------------------------------------------------------------------------------
func apply_update(update: Dictionary) -> void:
	var old_ids := _plots.keys()
	var id := model.apply(update)
	if id == "":
		return
	# drop nodes whose plots were replaced or removed
	for oid in old_ids:
		if not model.plots.has(oid) or oid == id:
			if _plots.has(oid):
				_plots[oid].queue_free()
				_plots.erase(oid)
				_bounds.erase(oid)
	if model.plots.has(id):
		_build_plot(model.plots[id])
		_pop_in(_plots[id])


func _pop_in(n: Node3D) -> void:
	if Config.headless_capture:
		return
	n.scale = Vector3(1, 0.01, 1)
	n.create_tween().tween_property(n, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# -- picking and selection -------------------------------------------------------------------------------
func pick(screen: Vector2) -> Dictionary:
	var o := cam.project_ray_origin(screen)
	var d := cam.project_ray_normal(screen)
	var best := ""
	var best_t := INF
	for id in _bounds:
		var a: AABB = _bounds[id]
		var hit = a.intersects_ray(o, d)
		if hit != null:
			var t: float = (hit - o).length()
			if t < best_t:
				best_t = t
				best = id
	if best != "":
		return model.plots.get(best, {})
	return model.plot_at(model.world_to_tile(cam.ground_at(screen)))


func _on_tap(pos: Vector2) -> void:
	var p := pick(pos)
	if not p.is_empty():
		select(str(p["id"]))
		plot_tapped.emit(p)


func select(id: String) -> void:
	selected_id = id
	if not _plots.has(id):
		_selector.visible = false
		return
	var p: Dictionary = model.plots[id]
	var pw := float(p.get("w", 1))
	var ph := float(p.get("h", 1))
	var bm := BoxMesh.new()
	bm.size = Vector3(pw + 0.12, 0.05, ph + 0.12)
	_selector.mesh = bm
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color("#2F80ED")
	sm.emission_enabled = true
	sm.emission = Color("#2F80ED")
	sm.emission_energy_multiplier = 1.4
	_selector.material_override = sm
	_selector.position = model.plot_center(p) + Vector3(0, 0.01, 0)
	_selector.visible = true
	bounce(id)


func bounce(id: String) -> void:
	if not _plots.has(id) or Config.headless_capture:
		return
	var m = _plots[id].get_meta("model") if _plots[id].has_meta("model") else null
	if m is Node3D:
		var s0: Vector3 = (m as Node3D).scale
		var tw := (m as Node3D).create_tween()
		tw.tween_property(m, "scale", s0 * Vector3(1.06, 0.9, 1.06), 0.08)
		tw.tween_property(m, "scale", s0, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func focus(id: String, zoom := -1.0) -> void:
	if model.plots.has(id):
		cam.look_at_point(model.plot_center(model.plots[id]), zoom)


# -- the player's marker ----------------------------------------------------------------------------------
func _make_pin() -> Node3D:
	var root := Node3D.new()
	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.09
	cap.height = 0.34
	body.mesh = cap
	body.position.y = 0.17
	body.material_override = _mat("pin_body", Color("#2F80ED"), 0.4)
	root.add_child(body)
	var head := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = 0.075
	sp.height = 0.15
	head.mesh = sp
	head.position.y = 0.42
	head.material_override = _mat("pin_head", Color("#F2C9A8"), 0.6)
	root.add_child(head)
	var marker := Sprite3D.new()
	marker.texture = AssetLib.icon("action:player")
	marker.pixel_size = 0.0028
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.no_depth_test = true
	marker.modulate = Color("#56CCF2")
	marker.position.y = 0.75
	root.add_child(marker)
	root.visible = false
	return root


func place_player(plot_id: String) -> void:
	here_id = plot_id
	_walk.clear()
	if not model.plots.has(plot_id):
		_pin.visible = false
		return
	var e := model.entrance(model.plots[plot_id])
	_pin.position = model.tile_pos(e)
	_pin.visible = true


## Walk the marker along the roads: `left` of `total` seconds to go.
func walk(from_id: String, to_id: String, left: float, total: float) -> void:
	if not model.plots.has(from_id) or not model.plots.has(to_id):
		place_player(to_id)
		return
	var path := model.route(model.entrance(model.plots[from_id]), model.entrance(model.plots[to_id]))
	var pts: Array = []
	for t in path:
		pts.append(model.tile_pos(t))
	_walk = {"path": pts, "total": maxf(total, 0.5), "left": clampf(left, 0.0, total)}
	_pin.visible = true


func arrive(to_id: String) -> void:
	place_player(to_id)
	bounce(to_id)
	if not Config.headless_capture:
		var tw := _pin.create_tween()
		tw.tween_property(_pin, "position:y", 0.35, 0.18).set_ease(Tween.EASE_OUT)
		tw.tween_property(_pin, "position:y", 0.0, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _pos_along(pts: Array, f: float) -> Array:
	if pts.size() < 2:
		return [pts[0] if pts.size() > 0 else Vector3.ZERO, Vector3.FORWARD]
	var total := 0.0
	for i in pts.size() - 1:
		total += (pts[i] as Vector3).distance_to(pts[i + 1])
	var want := clampf(f, 0.0, 1.0) * total
	for i in pts.size() - 1:
		var seg := (pts[i] as Vector3).distance_to(pts[i + 1])
		if want <= seg or i == pts.size() - 2:
			var k := want / maxf(seg, 1e-4)
			return [(pts[i] as Vector3).lerp(pts[i + 1], clampf(k, 0, 1)), ((pts[i + 1] as Vector3) - pts[i]).normalized()]
		want -= seg
	return [pts[-1], Vector3.FORWARD]


# -- traffic ------------------------------------------------------------------------------------------------
func _spawn_traffic() -> void:
	for c in _traffic.get_children():
		c.queue_free()
	_cars.clear()
	var keys := ["vehicle:sedan", "vehicle:taxi", "vehicle:van", "vehicle:police", "vehicle:truck", "vehicle:sedan"]
	var road_tiles: Array = model.roads.keys()
	if road_tiles.size() < 4:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in mini(8, road_tiles.size() / 12):
		var n := AssetLib.instantiate(keys[i % keys.size()])
		if n == null:
			continue
		n.scale = Vector3.ONE * 0.22
		var holder := Node3D.new()
		holder.add_child(n)
		_traffic.add_child(holder)
		var car := {"node": holder, "path": [], "f": 0.0, "len": 1.0, "speed": rng.randf_range(0.9, 1.4), "rng": rng}
		_new_trip(car, road_tiles[rng.randi() % road_tiles.size()])
		car["f"] = rng.randf() * 0.8
		_cars.append(car)


func _new_trip(car: Dictionary, from: Vector2i) -> void:
	var rng: RandomNumberGenerator = car["rng"]
	var tiles: Array = model.roads.keys()
	var to: Vector2i = tiles[rng.randi() % tiles.size()]
	var path := model.route(from, to)
	var pts: Array = []
	for t in path:
		pts.append(model.tile_pos(t))
	if pts.size() < 2:
		pts = [model.tile_pos(from), model.tile_pos(from) + Vector3(0.01, 0, 0)]
	var L := 0.0
	for k in pts.size() - 1:
		L += (pts[k] as Vector3).distance_to(pts[k + 1])
	car["path"] = pts
	car["len"] = maxf(L, 0.1)
	car["f"] = 0.0
	car["to"] = to


func _process(delta: float) -> void:
	_t += delta
	for car in _cars:
		car["f"] += delta * float(car["speed"]) / float(car["len"])
		if car["f"] >= 1.0:
			_new_trip(car, car["to"])
		var at := _pos_along(car["path"], car["f"])
		var dir: Vector3 = at[1]
		var holder: Node3D = car["node"]
		# keep to the right-hand lane
		var right := Vector3(-dir.z, 0, dir.x)
		holder.position = (at[0] as Vector3) + right * 0.17
		if dir.length() > 0.1:
			holder.rotation.y = atan2(dir.x, dir.z)
	if not _walk.is_empty():
		_walk["left"] = maxf(0.0, float(_walk["left"]) - delta)
		var f := 1.0 - float(_walk["left"]) / float(_walk["total"])
		var at := _pos_along(_walk["path"], f)
		_pin.position = at[0]
		_pin.position.y = absf(sin(_t * 9.0)) * 0.04
		var d: Vector3 = at[1]
		if d.length() > 0.1:
			_pin.rotation.y = atan2(d.x, d.z)
	if selected_id != "" and _selector.visible and _selector.material_override:
		(_selector.material_override as StandardMaterial3D).emission_energy_multiplier = 1.0 + 0.6 * sin(_t * 4.0)
	# name tags only when zoomed in enough to read the city
	var want := show_labels and cam.zoom < 16.0
	for id in _plots:
		var l = _plots[id].get_meta("label") if _plots[id].has_meta("label") else null
		if l is Label3D:
			(l as Label3D).visible = want
