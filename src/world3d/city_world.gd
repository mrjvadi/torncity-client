class_name CityWorld3D
extends Node3D
## The 3D city, built from a WorldModel (schema v2) with models from the
## AssetLib. Layers:
##   ground   districts, water and shore, fields, runways, rails (procedural, batched)
##   roads    carriageways by class, sidewalks, medians, barriers, markings, crossings
##   dressing trees, street lamps (Kenney meshes as MultiMeshes), planes, ships
##   plots    a base and a model per plot, name tags, smoke
##   life     traffic, the player's marker, the selection
## Picking is a ray against each plot's bounds (no physics).

signal plot_tapped(plot: Dictionary)

const LABEL_KINDS := ["place", "company"]
const DISTRICT_COLOR := {
	"cbd": Color("#C3C8CF"), "commercial": Color("#B4BAC2"), "residential": Color("#8FC06A"), "campus": Color("#95C774"),
	"industrial": Color("#A4A7AB"), "park": Color("#7DB85C"), "port": Color("#A7ACB1"), "farmland": Color("#A9C074"),
	"military": Color("#B9B08F"), "airport": Color("#A2BD80")}
const LABEL_ZOOM := 30.0     # closer than this: place tags; farther: district names

var model := WorldModel.new()
var cam: CityCamera
var selected_id := ""
var here_id := ""
var show_labels := true

var _layers := {}
var _plots := {}        # id -> Node3D
var _bounds := {}       # id -> AABB
var _district_labels: Array = []
var _selector: MeshInstance3D
var _pin: Node3D
var _cars := []
var _walk := {}
var _t := 0.0
var _mats := {}
var _pending := {}      # asset key -> ["#dressing" | "#traffic" | plot id]
var _dirty := {}
var _world_desc := {}
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_environment()
	cam = CityCamera.new()
	add_child(cam)
	cam.tapped.connect(_on_tap)
	for n in ["ground", "roads", "dressing", "plots", "life"]:
		var l := Node3D.new()
		l.name = n
		add_child(l)
		_layers[n] = l
	_selector = MeshInstance3D.new()
	_selector.visible = false
	_layers.life.add_child(_selector)
	_pin = _make_pin()
	_layers.life.add_child(_pin)
	AssetService.loaded.connect(_on_asset)
	AssetLib.changed.connect(func(): if not _world_desc.is_empty(): build(_world_desc))


func _environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#1E4B66")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#A4B6DA")
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 1.6
	env.tonemap_exposure = 0.92
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.06
	env.adjustment_saturation = 1.1
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -28, 0)
	sun.light_energy = 1.0
	sun.light_color = Color("#FFF1DC")
	# Shadow maps are the city's largest GPU allocation; an iPhone's web view
	# reloads the page when WebGL runs out, so the web build draws without.
	sun.shadow_enabled = not OS.has_feature("web")
	sun.shadow_bias = 0.03
	sun.directional_shadow_max_distance = 90.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	add_child(sun)


func _mat(key: String, c: Color, rough := 0.9, metal := 0.0) -> StandardMaterial3D:
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = rough
		m.metallic = metal
		_mats[key] = m
	return _mats[key]


# -- build ------------------------------------------------------------------------------------------
func build(world: Dictionary) -> void:
	_world_desc = world
	_pending.clear()
	model.load_world(world)
	for k in ["ground", "roads", "dressing", "plots"]:
		for c in _layers[k].get_children():
			c.queue_free()
	_plots.clear()
	_bounds.clear()
	_district_labels.clear()
	_rng.seed = hash(model.city)
	_build_ground()
	_build_roads()
	for p in model.plots.values():
		_build_plot(p)
	_build_dressing()
	_spawn_traffic()
	var b := model.bounds
	cam.bounds = Rect2(b.position + Vector2(6, 6), b.size - Vector2(12, 12))
	cam.max_zoom = maxf(b.size.x, b.size.y) * 0.5
	cam.min_zoom = 4.0


func _build_ground() -> void:
	var g: Node3D = _layers.ground
	var b := model.bounds
	var outskirts := BoxBatch.new()
	outskirts.add(Vector3(b.get_center().x, -0.37, b.get_center().y), Vector3(b.size.x + 200, 0.5, b.size.y + 200))
	outskirts.build(_mat("outskirts", Color("#6FA152")), g)
	# districts, biggest first so the smaller ones sit on top
	var ds := model.districts.duplicate()
	ds.sort_custom(func(a, c): return WorldModel.district_rect(a).get_area() > WorldModel.district_rect(c).get_area())
	var by_kind := {}
	for i in ds.size():
		var r := WorldModel.district_rect(ds[i])
		var k := str(ds[i].get("kind", ""))
		by_kind.get_or_add(k, BoxBatch.new()).add(Vector3(r.get_center().x, -0.04 + i * 0.002, r.get_center().y), Vector3(r.size.x, 0.02, r.size.y), 0.0, true)
		# a district name tag, shown when zoomed out
		var lbl := _make_label(str(ds[i].get("name", {}).get(I18n.lang, ds[i].get("name", {}).get("en", ""))), "district")
		lbl.position = Vector3(r.get_center().x, 3.0, r.get_center().y)
		lbl.font_size = 40
		lbl.visible = false
		g.add_child(lbl)
		_district_labels.append(lbl)
	for k in by_kind:
		by_kind[k].build(_mat("d_" + k, DISTRICT_COLOR.get(k, Color("#8FA37A"))), g)
	# water and its shore
	var sea := BoxBatch.new()
	var sand := BoxBatch.new()
	for w in model.water:
		var r: Array = w.get("rect", [0, 0, 0, 0])
		sea.add(Vector3(r[0] + r[2] / 2.0, -0.16, r[1] + r[3] / 2.0), Vector3(r[2], 0.16, r[3]))
		sand.add(Vector3(r[0] + r[2] / 2.0, -0.07, r[1] - 0.3), Vector3(r[2], 0.1, 1.2))
	sand.build(_mat("sand", Color("#CDBB8A")), g)
	var sm := _mat("sea", Color("#3B8DB5"), 0.08, 0.15)
	sea.build(sm, g)
	# features
	var dark := BoxBatch.new()
	var concrete := BoxBatch.new()
	var paint := BoxBatch.new()
	var wood := BoxBatch.new()
	var crops := {"a": BoxBatch.new(), "b": BoxBatch.new()}
	for f in model.features:
		match str(f.get("type", "")):
			"runway":
				var a := Vector2(f.from[0], f.from[1])
				var c := Vector2(f.to[0], f.to[1])
				var wdt := float(f.get("width", 3))
				dark.strip(a, c, wdt, 0.0, 0.04)
				var d := (c - a).normalized()
				var L := a.distance_to(c)
				var s := 2.0
				while s < L - 2.0:
					paint.strip(a + d * s, a + d * (s + 1.0), 0.12, 0.03, 0.01, true)
					s += 2.2
				for end in [a + d * 0.6, c - d * 0.6]:
					for k in 6:
						var off := Vector2(-d.y, d.x) * ((k - 2.5) * 0.4)
						paint.strip(end + off - d * 0.4, end + off + d * 0.4, 0.18, 0.03, 0.01, true)
			"apron":
				var r: Array = f.rect
				concrete.add(Vector3(r[0] + r[2] / 2.0, 0.0, r[1] + r[3] / 2.0), Vector3(r[2], 0.04, r[3]))
			"pier":
				var r: Array = f.rect
				wood.add(Vector3(r[0] + r[2] / 2.0, 0.05, r[1] + r[3] / 2.0), Vector3(r[2], 0.18, r[3]))
			"field":
				var r: Array = f.rect
				var y := float(r[1])
				var i := 0
				while y < float(r[1]) + float(r[3]) - 0.5:
					crops["a" if i % 2 == 0 else "b"].add(Vector3(r[0] + r[2] / 2.0, 0.02, y + 0.5), Vector3(r[2], 0.1, 0.8))
					y += 1.0
					i += 1
			"plane":
				_plane(Vector3(f.at[0], 0.0, f.at[1]), float(f.get("rot", 0)))
			"ship":
				_ship(Vector3(f.at[0], -0.1, f.at[1]), float(f.get("rot", 0)))
	dark.build(_mat("runway", Color("#4A4F57")), g)
	concrete.build(_mat("apron", Color("#B3B7BD")), g)
	paint.build(_mat("paint", Color("#F2F2F2"), 0.6), g)
	wood.build(_mat("wood", Color("#8A6440")), g, true)
	crops.a.build(_mat("crop_a", Color("#C9B25A")), g)
	crops.b.build(_mat("crop_b", Color("#6E9B40")), g)
	# rails
	var ballast := BoxBatch.new()
	var sleepers := BoxBatch.new()
	var steel := BoxBatch.new()
	for r in model.rails:
		var pts: PackedVector2Array = r.pts
		for i in pts.size() - 1:
			var a := pts[i]
			var c := pts[i + 1]
			ballast.strip(a, c, 1.0, 0.02, 0.08)
			var d := (c - a).normalized()
			var n := Vector2(-d.y, d.x)
			for side in [-0.24, 0.24]:
				steel.strip(a + n * side, c + n * side, 0.06, 0.12, 0.05)
			var L := a.distance_to(c)
			var s := 0.2
			while s < L:
				var p := a + d * s
				sleepers.strip(p - n * 0.4, p + n * 0.4, 0.14, 0.08, 0.04)
				s += 0.45
	ballast.build(_mat("ballast", Color("#7D756B")), g)
	sleepers.build(_mat("sleeper", Color("#5B4636")), g)
	steel.build(_mat("rail", Color("#AEB6C0"), 0.35, 0.8), g)


func _build_roads() -> void:
	var g: Node3D = _layers.roads
	var asphalt := BoxBatch.new()
	var highway := BoxBatch.new()
	var walk := BoxBatch.new()
	var median := BoxBatch.new()
	var barrier := BoxBatch.new()
	var marks := BoxBatch.new()
	var yellow := BoxBatch.new()
	var crossing_r := {}   # node index -> half-size of its crossing patch
	for i in model.nodes.size():
		if model.edges.get(i, []).size() >= 3:
			crossing_r[i] = WorldModel.WIDTH.get(model.node_class.get(i, "street"), 1.3) / 2.0 + WorldModel.SIDEWALK.get(model.node_class.get(i, "street"), 0.4)
	for e in model.edge_list():
		var a: Vector2 = model.nodes[e[0]]
		var b: Vector2 = model.nodes[e[1]]
		var cls := str(e[2])
		var w: float = WorldModel.WIDTH.get(cls, 1.3)
		var sw: float = WorldModel.SIDEWALK.get(cls, 0.4)
		var d := (b - a).normalized()
		var n := Vector2(-d.y, d.x)
		var ta: float = crossing_r.get(e[0], 0.0)
		var tb: float = crossing_r.get(e[1], 0.0)
		var a2 := a + d * ta
		var b2 := b - d * tb
		if a2.distance_to(a) + b2.distance_to(b) >= a.distance_to(b):
			continue
		(highway if cls == "highway" else asphalt).strip(a, b, w, 0.0, 0.04)
		if sw > 0:
			for s in [-1, 1]:
				walk.strip(a2 + n * s * (w / 2.0 + sw / 2.0), b2 + n * s * (w / 2.0 + sw / 2.0), sw, 0.04, 0.1)
		match cls:
			"boulevard":
				median.strip(a2, b2, 0.8, 0.06, 0.12)
				_dashes(marks, a2, b2, n * 1.25, 0.08)
				_dashes(marks, a2, b2, -n * 1.25, 0.08)
			"highway":
				for s in [-1, 1]:
					barrier.strip(a + n * s * (w / 2.0 - 0.05), b + n * s * (w / 2.0 - 0.05), 0.08, 0.1, 0.2)
				yellow.strip(a, b, 0.07, 0.025, 0.01, true)
				_dashes(marks, a, b, n * 0.65, 0.07)
				_dashes(marks, a, b, -n * 0.65, 0.07)
			_:
				_dashes(marks, a2, b2, Vector2.ZERO, 0.07)
	# crossings: a square of asphalt and zebra stripes on each arm
	var zebra := BoxBatch.new()
	for i in crossing_r:
		var p: Vector2 = model.nodes[i]
		var cls := str(model.node_class.get(i, "street"))
		var hs: float = crossing_r[i]
		(highway if cls == "highway" else asphalt).add(Vector3(p.x, 0.0, p.y), Vector3(hs * 2, 0.04, hs * 2))
		if cls == "highway":
			continue
		for e in model.edges.get(i, []):
			var d := ((model.nodes[e[0]] as Vector2) - p).normalized()
			var n := Vector2(-d.y, d.x)
			var ecls := _edge_class(i, e[0])
			if ecls == "highway":
				continue
			var ew: float = WorldModel.WIDTH.get(ecls, 1.3)
			var k := -ew / 2.0 + 0.12
			while k < ew / 2.0 - 0.05:
				var c := p + d * (hs + 0.3) + n * k
				zebra.strip(c - d * 0.25, c + d * 0.25, 0.12, 0.03, 0.01, true)
				k += 0.26
	asphalt.build(_mat("asphalt", Color("#555B64")), g)
	highway.build(_mat("highway", Color("#4A4F57")), g)
	walk.build(_mat("sidewalk", Color("#B6BAC1")), g, true)
	median.build(_mat("median", Color("#6FA652")), g)
	barrier.build(_mat("barrier", Color("#D5D8DD")), g, true)
	marks.build(_mat("marks", Color("#F2F2F2"), 0.6), g)
	yellow.build(_mat("yellow", Color("#F2C94C"), 0.6), g)
	zebra.build(_mat("zebra", Color("#EDEDED"), 0.6), g)


func _edge_class(a: int, b: int) -> String:
	for e in model.edge_list():
		if (e[0] == a and e[1] == b) or (e[0] == b and e[1] == a):
			return str(e[2])
	return "street"


func _dashes(bb: BoxBatch, a: Vector2, b: Vector2, off: Vector2, wdt: float) -> void:
	var d := (b - a)
	var L := d.length()
	if L < 0.8:
		return
	d /= L
	var s := 0.3
	while s + 0.5 < L - 0.3:
		bb.strip(a + off + d * s, a + off + d * (s + 0.5), wdt, 0.025, 0.01, true)
		s += 1.0


func _plane(at: Vector3, rot: float) -> void:
	var root := Node3D.new()
	root.position = at
	root.rotation_degrees.y = rot
	_layers.ground.add_child(root)
	var white := _mat("plane", Color("#F4F6F8"), 0.35)
	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.32
	cap.height = 3.4
	body.mesh = cap
	body.rotation_degrees.x = 90
	body.position.y = 0.45
	body.material_override = white
	root.add_child(body)
	var wings := BoxBatch.new()
	wings.add(Vector3(0, 0.4, 0.1), Vector3(3.4, 0.06, 0.7))
	wings.add(Vector3(0, 0.55, -1.45), Vector3(1.2, 0.05, 0.35))
	wings.build(white, root, true)
	var tail := BoxBatch.new()
	tail.add(Vector3(0, 0.9, -1.45), Vector3(0.06, 0.7, 0.5))
	tail.build(_mat("tail", Color("#2F80ED"), 0.4), root, true)


func _ship(at: Vector3, rot: float) -> void:
	var root := Node3D.new()
	root.position = at
	root.rotation_degrees.y = rot
	_layers.ground.add_child(root)
	var hull := BoxBatch.new()
	hull.add(Vector3(0, 0.2, 0), Vector3(1.6, 0.5, 6.0))
	hull.build(_mat("hull", Color("#7A2E2E")), root, true)
	var bridge := BoxBatch.new()
	bridge.add(Vector3(0, 0.8, -2.3), Vector3(1.3, 0.9, 0.8))
	bridge.build(_mat("plane", Color("#F4F6F8"), 0.35), root, true)
	var cols := [Color("#C0392B"), Color("#2E86C1"), Color("#27AE60"), Color("#E0A63A")]
	for ci in cols.size():
		var bb := BoxBatch.new()
		for k in 4:
			for j in 2:
				if (k + j + ci) % 4 == ci:
					bb.add(Vector3(-0.35 + j * 0.7, 0.62 + (k % 2) * 0.3, -1.3 + k * 0.9), Vector3(0.65, 0.28, 0.85))
		bb.build(_mat("cont%d" % ci, cols[ci], 0.6), root, true)


# -- plots ------------------------------------------------------------------------------------------
func _build_plot(p: Dictionary) -> void:
	var id := str(p["id"])
	var root := Node3D.new()
	root.position = model.plot_center(p)
	_layers.plots.add_child(root)
	var r := WorldModel.plot_rect(p)
	var kind := str(p.get("kind", ""))
	var base := BoxBatch.new()
	var kerb := BoxBatch.new()
	match kind:
		"place", "company", "decor":
			kerb.add(Vector3(0, 0.02, 0), Vector3(r.size.x, 0.1, r.size.y))
			base.add(Vector3(0, 0.03, 0), Vector3(r.size.x - 0.14, 0.1, r.size.y - 0.14))
		"home":
			base.add(Vector3(0, 0.0, 0), Vector3(r.size.x - 0.1, 0.06, r.size.y - 0.1))
		"green":
			base.add(Vector3(0, -0.01, 0), Vector3(r.size.x, 0.04, r.size.y), 0.0, true)
	kerb.build(_mat("kerb", Color("#6F7680")), root)
	base.build(_mat("garden" if kind == "home" else ("lawn" if kind == "green" else "pave"),
		Color("#9BCC74") if kind == "home" else (Color("#8BC265") if kind == "green" else Color("#A3A9B2"))), root)
	var key := str(p.get("model", ""))
	if key != "":
		var m := AssetLib.instantiate(key)
		for k in m.get_meta("pending", []):
			_wait(k, id)
		var s := clampf(minf(r.size.x, r.size.y) / 2.0, 0.8, 1.35)
		m.scale = Vector3(s, s, s)
		m.position.y = 0.08 if kind in ["place", "company", "decor"] else 0.03
		m.rotation_degrees.y = float(p.get("rot", 0))
		root.add_child(m)
		root.set_meta("model", m)
		_add_fx(root, key, s)
	_plots[id] = root
	_bounds[id] = _aabb_of(root, r)
	if kind in LABEL_KINDS:
		var lbl := _make_label(_plot_name(p), kind)
		lbl.position = Vector3(0, maxf(_bounds[id].end.y, 1.0) + 0.3, 0)
		root.add_child(lbl)
		root.set_meta("label", lbl)


func _add_fx(root: Node3D, key: String, s: float) -> void:
	for fx in AssetLib.model(key).get("fx", []):
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
	l.modulate = Color.WHITE if kind != "district" else Color(1, 1, 1, 0.92)
	l.outline_modulate = {"place": Color("#0F1A2BE6"), "company": Color("#1C5FC0F0"), "district": Color("#0F1A2BB0")}.get(kind, Color("#0F1A2BE6"))
	l.pixel_size = 0.0011 if kind != "district" else 0.0015
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.render_priority = 5
	# the same size on screen at any zoom
	l.fixed_size = true
	return l


func _aabb_of(n: Node, r: Rect2) -> AABB:
	var acc: Array = [null]
	_collect(n, acc)
	var foot := AABB(Vector3(r.position.x, 0, r.position.y), Vector3(r.size.x, 0.5, r.size.y))
	return foot.merge(acc[0]) if acc[0] != null else foot


func _collect(n: Node, acc: Array) -> void:
	if n is MeshInstance3D and (n as MeshInstance3D).mesh and n.is_inside_tree() and not n.has_meta("stand_in_skip"):
		var a: AABB = (n as MeshInstance3D).global_transform * (n as MeshInstance3D).mesh.get_aabb()
		acc[0] = a if acc[0] == null else acc[0].merge(a)
	for c in n.get_children():
		if not (c is Label3D):
			_collect(c, acc)


# -- dressing: trees and lamps as MultiMeshes of the Kenney meshes ----------------------------------------
func _build_dressing() -> void:
	var g: Node3D = _layers.dressing
	for c in g.get_children():
		c.queue_free()
	var trees: Array = []
	var small: Array = []
	var lamps: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(model.city) + 7
	# boulevard medians and avenue sidewalks
	for e in model.edge_list():
		var a: Vector2 = model.nodes[e[0]]
		var b: Vector2 = model.nodes[e[1]]
		var cls := str(e[2])
		var d := (b - a)
		var L := d.length()
		if L < 2.0:
			continue
		d /= L
		var n := Vector2(-d.y, d.x)
		var w: float = WorldModel.WIDTH.get(cls, 1.3)
		var sw: float = WorldModel.SIDEWALK.get(cls, 0.4)
		var s := 1.4
		while s < L - 1.4:
			var p := a + d * s
			match cls:
				"boulevard":
					trees.append(_xf(p, 0.9 + rng.randf() * 0.2, rng.randf() * TAU, 0.12))
				"avenue":
					lamps.append(_xf(p + n * (w / 2.0 + sw * 0.7), 1.2, atan2(n.x, n.y) + PI, 0.1))
					if int(s) % 3 == 0:
						small.append(_xf(p - n * (w / 2.0 + sw * 0.5), 0.8, rng.randf() * TAU, 0.1))
				"street":
					if int(s * 10) % 37 < 6:
						lamps.append(_xf(p + n * (w / 2.0 + sw * 0.6), 1.0, atan2(n.x, n.y) + PI, 0.1))
			s += 1.6 if cls == "boulevard" else 2.6
	# gardens, parks and lawns
	for p in model.plots.values():
		var r := WorldModel.plot_rect(p)
		match str(p.get("kind", "")):
			"home":
				trees.append(_xf(r.position + Vector2(0.3, 0.3), 0.7 + rng.randf() * 0.3, rng.randf() * TAU, 0.03))
				if rng.randf() < 0.6:
					small.append(_xf(r.end - Vector2(0.3, 0.3), 0.8, rng.randf() * TAU, 0.03))
			"green":
				var count := int(r.get_area() / 3.0)
				for i in count:
					var q := r.position + Vector2(rng.randf() * r.size.x, rng.randf() * r.size.y)
					(trees if rng.randf() < 0.7 else small).append(_xf(q, 0.8 + rng.randf() * 0.5, rng.randf() * TAU, 0.0))
			"place", "company":
				trees.append(_xf(r.position + Vector2(0.25, r.size.y - 0.25), 0.7, 0.0, 0.1))
	# clumps of woodland in the outskirts, away from districts and roads
	var tries := 0
	while tries < 400:
		tries += 1
		var q := model.bounds.position + Vector2(rng.randf() * model.bounds.size.x, rng.randf() * model.bounds.size.y)
		if not model.district_at(q).is_empty() or _near_road(q, 2.0) or _in_water(q):
			continue
		for k in 3:
			(trees if k != 2 else small).append(_xf(q + Vector2(rng.randf_range(-1.2, 1.2), rng.randf_range(-1.2, 1.2)), 0.9 + rng.randf() * 0.6, rng.randf() * TAU, 0.0))
	_scatter("tree", trees, 2.2)
	_scatter("tree_small", small, 2.2)
	_scatter("lamp", lamps, 1.6)


func _near_road(q: Vector2, dist: float) -> bool:
	for e in model.edge_list():
		if Geometry2D.get_closest_point_to_segment(q, model.nodes[e[0]], model.nodes[e[1]]).distance_to(q) < dist:
			return true
	return false


func _in_water(q: Vector2) -> bool:
	for w in model.water:
		var r: Array = w.get("rect", [0, 0, 0, 0])
		if Rect2(r[0], r[1] - 1.5, r[2], r[3] + 1.5).has_point(q):
			return true
	return false


func _xf(p: Vector2, s: float, yaw: float, y: float) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(s, s, s)), Vector3(p.x, y, p.y))


## A MultiMesh of a dressing mesh (Kenney), scaled so it reads at city scale.
func _scatter(key: String, xfs: Array, scale_k: float) -> void:
	if xfs.is_empty():
		return
	var mesh_key := str(AssetLib.dressing.get(key, ""))
	var ps := AssetLib.mesh_scene(mesh_key)
	var mesh: Mesh = null
	if ps:
		var n := ps.instantiate()
		var mis := n.find_children("*", "MeshInstance3D", true, false)
		if not mis.is_empty():
			mesh = (mis[0] as MeshInstance3D).mesh
		n.free()
	if mesh == null:
		_wait("mesh:" + mesh_key, "#dressing")
		if key == "lamp":
			return
		# a stand-in tree while the Kenney one downloads
		var sph := SphereMesh.new()
		sph.radius = 0.12
		sph.height = 0.34
		sph.material = _mat("tree_standin", Color("#4E8F4A"))
		mesh = sph
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	for i in xfs.size():
		var t: Transform3D = xfs[i]
		mm.set_instance_transform(i, Transform3D(t.basis.scaled(Vector3(scale_k, scale_k, scale_k)), t.origin))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	_layers.dressing.add_child(mmi)


# -- live updates -------------------------------------------------------------------------------------
func apply_update(update: Dictionary) -> void:
	var old_ids := _plots.keys()
	var id := model.apply(update)
	if id == "":
		return
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


# -- picking and selection ---------------------------------------------------------------------------
func pick(screen: Vector2) -> Dictionary:
	var o := cam.project_ray_origin(screen)
	var d := cam.project_ray_normal(screen)
	var best := ""
	var best_t := INF
	for id in _bounds:
		var kind := str(model.plots.get(id, {}).get("kind", ""))
		if kind in ["green", "home", "decor"]:
			continue
		var hit = (_bounds[id] as AABB).intersects_ray(o, d)
		if hit != null:
			var t: float = (hit - o).length()
			if t < best_t:
				best_t = t
				best = id
	if best != "":
		return model.plots.get(best, {})
	var g := cam.ground_at(screen)
	return model.plot_at(Vector2(g.x, g.z))


func _on_tap(pos: Vector2) -> void:
	var p := pick(pos)
	if not p.is_empty() and str(p.get("kind", "")) in LABEL_KINDS:
		select(str(p["id"]))
		plot_tapped.emit(p)


func select(id: String) -> void:
	selected_id = id
	if not _plots.has(id):
		_selector.visible = false
		return
	var r := WorldModel.plot_rect(model.plots[id])
	var bm := BoxMesh.new()
	bm.size = Vector3(r.size.x + 0.16, 0.05, r.size.y + 0.16)
	_selector.mesh = bm
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color("#2F80ED")
	sm.emission_enabled = true
	sm.emission = Color("#2F80ED")
	sm.emission_energy_multiplier = 1.4
	_selector.material_override = sm
	_selector.position = model.plot_center(model.plots[id]) + Vector3(0, 0.01, 0)
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


# -- the player's marker -------------------------------------------------------------------------------
func _make_pin() -> Node3D:
	var root := Node3D.new()
	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.11
	cap.height = 0.42
	body.mesh = cap
	body.position.y = 0.21
	body.material_override = _mat("pin_body", Color("#2F80ED"), 0.4)
	root.add_child(body)
	var head := MeshInstance3D.new()
	var sp := SphereMesh.new()
	sp.radius = 0.09
	sp.height = 0.18
	head.mesh = sp
	head.position.y = 0.52
	head.material_override = _mat("pin_head", Color("#F2C9A8"), 0.6)
	root.add_child(head)
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.22
	tm.outer_radius = 0.3
	ring.mesh = tm
	ring.position.y = 0.03
	var rm := StandardMaterial3D.new()
	rm.albedo_color = Color("#56CCF2")
	rm.emission_enabled = true
	rm.emission = Color("#56CCF2")
	ring.material_override = rm
	root.add_child(ring)
	root.set_meta("ring", ring)
	root.visible = false
	return root


func place_player(plot_id: String) -> void:
	here_id = plot_id
	_walk.clear()
	if not model.plots.has(plot_id):
		_pin.visible = false
		return
	var e := model.entrance(model.plots[plot_id])
	_pin.position = Vector3(e.x, 0.06, e.y)
	_pin.visible = true


func walk(from_id: String, to_id: String, left: float, total: float) -> void:
	if not model.plots.has(from_id) or not model.plots.has(to_id):
		place_player(to_id)
		return
	var path := model.route(model.entrance(model.plots[from_id]), model.entrance(model.plots[to_id]))
	var pts: Array = []
	for p in path:
		pts.append(Vector3(p.x, 0.06, p.y))
	_walk = {"path": pts, "total": maxf(total, 0.5), "left": clampf(left, 0.0, total)}
	_pin.visible = true


func arrive(to_id: String) -> void:
	place_player(to_id)
	bounce(to_id)
	if not Config.headless_capture:
		var tw := _pin.create_tween()
		tw.tween_property(_pin, "position:y", 0.4, 0.18).set_ease(Tween.EASE_OUT)
		tw.tween_property(_pin, "position:y", 0.06, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func walk_progress_to(f: float) -> void:
	if not _walk.is_empty():
		_walk["left"] = float(_walk["total"]) * (1.0 - f)


static func _pos_along(pts: Array, f: float) -> Array:
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
	for c in _cars:
		c.node.queue_free()
	_cars.clear()
	if model.edge_list().is_empty():
		return
	var keys := ["vehicle:sedan", "vehicle:taxi", "vehicle:van", "vehicle:police", "vehicle:truck", "vehicle:sedan", "vehicle:bus"]
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in (6 if Config.phone_web() else 16):
		var n := AssetLib.instantiate(keys[i % keys.size()], AssetService.PREFETCH)
		for k in n.get_meta("pending", []):
			_wait(k, "#traffic")
		n.scale = Vector3.ONE * 0.3
		var holder := Node3D.new()
		holder.add_child(n)
		_layers.life.add_child(holder)
		var start: int = rng.randi() % model.nodes.size()
		var car := {"node": holder, "a": start, "b": start, "f": 1.0, "len": 1.0, "speed": rng.randf_range(1.6, 2.6), "rng": rng}
		_next_leg(car)
		car.f = rng.randf()
		_cars.append(car)


func _next_leg(car: Dictionary) -> void:
	var from: int = car.b
	var opts: Array = model.edges.get(from, [])
	if opts.is_empty():
		return
	var rng: RandomNumberGenerator = car.rng
	var pick_e: Array = opts[rng.randi() % opts.size()]
	# avoid U-turns when there is a choice
	if opts.size() > 1 and pick_e[0] == car.a:
		pick_e = opts[(opts.find(pick_e) + 1) % opts.size()]
	car.a = from
	car.b = pick_e[0]
	car.len = maxf(float(pick_e[1]), 0.1)
	car.f = 0.0
	car.cls = _edge_class(car.a, car.b)


func _process(delta: float) -> void:
	_t += delta
	for car in _cars:
		car.f += delta * float(car.speed) / float(car.len)
		if car.f >= 1.0:
			_next_leg(car)
		var a: Vector2 = model.nodes[car.a]
		var b: Vector2 = model.nodes[car.b]
		var d := (b - a).normalized()
		var lane: float = {"boulevard": 1.25, "highway": 0.65, "avenue": 0.45}.get(car.get("cls", "street"), 0.3)
		var p := a.lerp(b, clampf(car.f, 0, 1)) + Vector2(-d.y, d.x) * -lane
		var holder: Node3D = car.node
		holder.position = Vector3(p.x, 0.02, p.y)
		holder.rotation.y = atan2(d.x, d.y)
	if not _walk.is_empty():
		_walk["left"] = maxf(0.0, float(_walk["left"]) - delta)
		var f := 1.0 - float(_walk["left"]) / float(_walk["total"])
		var at := _pos_along(_walk["path"], f)
		_pin.position = at[0]
		_pin.position.y = 0.06 + absf(sin(_t * 9.0)) * 0.05
		var dd: Vector3 = at[1]
		if dd.length() > 0.1:
			_pin.rotation.y = atan2(dd.x, dd.z)
	if _pin.has_meta("ring"):
		var ring: Node3D = _pin.get_meta("ring")
		var k := 1.0 + 0.25 * sin(_t * 3.0)
		ring.scale = Vector3(k, 1, k)
	if selected_id != "" and _selector.visible and _selector.material_override:
		(_selector.material_override as StandardMaterial3D).emission_energy_multiplier = 1.0 + 0.6 * sin(_t * 4.0)
	# tags: places up close, district names from afar
	var near := cam.zoom < LABEL_ZOOM
	for id in _plots:
		if _plots[id].has_meta("label"):
			(_plots[id].get_meta("label") as Label3D).visible = show_labels and near
	for l in _district_labels:
		l.visible = show_labels and not near


# -- assets arriving from the CDN -----------------------------------------------------------------------
func _wait(key: String, what: String) -> void:
	if key == "mesh:" or key == "":
		return
	var l: Array = _pending.get_or_add(key, [])
	if not l.has(what):
		l.append(what)


func _on_asset(key: String) -> void:
	if not _pending.has(key):
		return
	for what in _pending[key]:
		_dirty[what] = true
	_pending.erase(key)
	if not _dirty.is_empty() and not is_queued_for_deletion():
		_flush.call_deferred()


func _flush() -> void:
	if _dirty.is_empty():
		return
	var d := _dirty
	_dirty = {}
	if d.has("#dressing"):
		_build_dressing()
	if d.has("#traffic"):
		_spawn_traffic()
	for id in d:
		if str(id).begins_with("#") or not model.plots.has(id):
			continue
		if _plots.has(id):
			_plots[id].queue_free()
		_build_plot(model.plots[id])
	if selected_id != "":
		select(selected_id)
