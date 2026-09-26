extends "res://proto/home_proto.gd"
## A design prototype of a large city: districts laid out on a grid of
## blocks (centre, bazaar, industry, houses, villas, park, a military zone,
## an airport), player companies on their own lots with their names, homes
## and villas for sale with their prices, and a tap on any building bringing
## up its own menu. Placeholder data throughout.
##   godot --path . res://proto/city_proto.tscn -- --view=overview|shop|villa|company|military [--shot=out.png]
## Drag to pan, wheel to zoom, click a building to open its menu.

const Builders := preload("res://proto/city/builders.gd")
const ROAD := preload("res://proto/city/road.gdshader")
const OUTLINE := preload("res://proto/city/outline.gdshader")

const P := 11.0                 # block pitch: a roomy lot and a wide road
const ROAD_W := 1.8
const F := P / 7.4              # how much bigger the big sites are than the first draft
## One letter per block: Military, Airport, Residential, Industrial, Park,
## Centre, Bazaar, Villas. Rows run north to south.
const LAYOUT := ["MMRRRRAA", "MMRRRRAA", "IIPCCBAA", "IICCCBAA", "IICCCBAA", "RRPPVVVV", "RRRPVVVV", "RRRPVVVV"]
const HOUSES := ["building-small-a", "building-small-b", "building-small-c", "building-small-d", "building-garage"]

var kit: Builders
var sites := {}                 # id -> {node, pos, kind, ...}
var markers: Array = []         # [control, world pos, min zoom, max zoom]
var anchors: Array = []         # [control, world pos, screen offset]
var _view := "overview"
var _target := Vector3.ZERO
var _zoom := 70.0
var _selected := ""
var _drag := false
var _spin: Array = []
var _overlay: Control


func _build_world() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--view="):
			_view = a.substr(7)
	kit = Builders.new()
	world = Node3D.new()
	add_child(world)
	_environment()
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.far = 400.0
	world.add_child(cam)
	_ground()
	_roads()
	for j in LAYOUT.size():
		for i in LAYOUT[j].length():
			_block(i, j, LAYOUT[j][i])
	_military()
	_airport()
	_flush_trees()
	_frame_view()


func _environment() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color("#16224F")
	sm.sky_horizon_color = Color("#E08A66")
	sm.ground_bottom_color = Color("#101530")
	sm.ground_horizon_color = Color("#5A4C70")
	sky.sky_material = sm
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("#8090D8")
	e.ambient_light_energy = 0.6
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.glow_enabled = true
	e.glow_intensity = 0.7
	e.glow_bloom = 0.05
	env.environment = e
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color("#FFB07A")
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 260.0
	sun.rotation_degrees = Vector3(-35, -60, 0)
	world.add_child(sun)


func _block_center(i: int, j: int) -> Vector3:
	return Vector3((i - 3.5) * P, 0, (j - 3.5) * P)


func _ground() -> void:
	var g := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(400, 400)
	g.mesh = pm
	g.material_override = kit.mat(Color("#355E44"))
	g.position.y = -0.03
	world.add_child(g)


# -- roads ----------------------------------------------------------------------------------------
func _roads() -> void:
	var rm := ShaderMaterial.new()
	rm.shader = ROAD
	rm.set_shader_parameter("width", ROAD_W)
	var half := 4.0 * P
	for k in 9:
		var line := (k - 4) * P
		for seg in 8:
			var a := (seg - 4) * P
			# vertical: x = line, z from a to a + P
			if not _inside_site(k, seg, true):
				_road_strip(Vector3(line, 0, a + P / 2.0), P, 0.0, rm)
			if not _inside_site(k, seg, false):
				_road_strip(Vector3(a + P / 2.0, 0, line), P, 90.0, rm)
	var asphalt := kit.mat(Color("#33353E"))
	for kx in 9:
		for kz in 9:
			kit.box(world, Vector3(ROAD_W, 0.012, ROAD_W), Vector3((kx - 4) * P, 0.0, (kz - 4) * P), asphalt)
	# a wide boulevard frame around the city
	kit.box(world, Vector3(2 * half + 6, 0.005, 2 * half + 6), Vector3(0, -0.02, 0), kit.mat(Color("#2B4C38")))


## Lines inside the merged sites (the military zone, the airport) have no road.
func _inside_site(k: int, seg: int, vertical: bool) -> bool:
	if vertical:
		return (k == 1 and seg <= 1) or (k == 7 and seg <= 4)
	return (k == 1 and seg <= 1) or (k >= 1 and k <= 4 and seg >= 6)


func _road_strip(at: Vector3, length: float, rot: float, m: Material) -> void:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(ROAD_W, length - ROAD_W)
	mi.mesh = pm
	mi.material_override = m
	mi.position = at + Vector3(0, 0.01, 0)
	mi.rotation_degrees.y = rot
	world.add_child(mi)


# -- blocks ---------------------------------------------------------------------------------------
func _block(i: int, j: int, kind: String) -> void:
	var c := _block_center(i, j)
	var rng := RandomNumberGenerator.new()
	rng.seed = i * 131 + j * 17
	if kind in ["M", "A"]:
		return
	var lot := P - ROAD_W
	var base_c := {"C": "#8E8C9A", "B": "#C8AE84", "I": "#7E828E", "P": "#4F9A5C", "R": "#6FA56A", "V": "#6FB06E"}.get(kind, "#999999")
	# a kerb and pavement around every block, trees along it
	kit.box(world, Vector3(lot, 0.08, lot), c, kit.mat(Color("#C9C4B8")))
	kit.box(world, Vector3(lot - 1.1, 0.03, lot - 1.1), c + Vector3(0, 0.08, 0), kit.mat(Color(base_c)))
	if kind != "P":
		var e := lot / 2.0 - 0.3
		for k in 5:
			var u := -e + 0.9 + k * (2.0 * e - 1.8) / 4.0
			for side in [Vector3(u, 0, -e), Vector3(u, 0, e), Vector3(-e, 0, u), Vector3(e, 0, u)]:
				_street_tree(c + side + Vector3(0, 0.08, 0), rng.randf_range(0.9, 1.2))
	var y := Vector3(0, 0.11, 0)
	match kind:
		"C":
			if i == 3 and j == 3:
				kit.city_hall(world, c + y + Vector3(0, 0, -1.4))
				_site("city_hall", c + Vector3(0, 0, -1.4), "place", {"name": "شهرداری", "icon": "rank", "pal": "gold"})
				_char_bagh(c + y + Vector3(0, 0, 2.6))
			elif i == 4 and j == 3:
				kit.bank(world, c + y)
				_site("bank", c, "place", {"name": "بانک مرکزی", "icon": "bank", "pal": "sapphire"})
				for x in [-3.0, 3.0]:
					for z in [-3.0, 3.0]:
						_street_tree(c + y + Vector3(x, 0, z), 1.4)
			else:
				var walls := [Color("#8C95B8"), Color("#A7A0C8"), Color("#7FA3B8"), Color("#B3A58E")]
				for dx in [-2.3, 2.3]:
					for dz in [-2.3, 2.3]:
						var h := rng.randf_range(3.5, 9.5) if (i + j) % 2 == 0 else rng.randf_range(2.4, 6.0)
						kit.tower(world, c + y + Vector3(dx, 0, dz), h, 2.3, 2.3, walls[rng.randi() % 4], rng.randf() * 10.0)
				# a small plaza with a fountain between the towers
				kit.cyl(world, 0.7, 0.18, c + y, kit.mat(Color("#D8D2C4")))
				var wm := ShaderMaterial.new()
				wm.shader = kit.WATER
				kit.cyl(world, 0.58, 0.2, c + y + Vector3(0, 0.02, 0), wm)
		"B":
			kit.bazaar(world, c + y + Vector3(-2.3, 0, 0), 7.6, 90.0)
			if j == 3:
				kit.shop(world, c + y + Vector3(2.5, 0, -2.4), Color("#E5484D"))
				_site("shop", c + Vector3(2.5, 0, -2.4), "shop", {})
				kit.shop(world, c + y + Vector3(2.5, 0, 2.4), Color("#2BC4B2"))
			else:
				kit.shop(world, c + y + Vector3(2.5, 0, -1.6), Color("#F5A623"))
				kit.shop(world, c + y + Vector3(2.5, 0, 2.2), Color("#8E6CF0"))
		"I":
			var names := {Vector2i(0, 2): ["فولاد البرز", "سارا", true], Vector2i(1, 2): ["پرواز نو", "مینا", false],
				Vector2i(0, 3): ["داروسازی مهر", "رضا", false], Vector2i(1, 3): ["گجت دانا", "دانا", false],
				Vector2i(0, 4): ["نان آفتاب", "علی", false], Vector2i(1, 4): ["زمین خالی", "", false]}
			var accents := [Color("#E5484D"), Color("#2BC4B2"), Color("#8E6CF0"), Color("#F5A623")]
			var info: Array = names.get(Vector2i(i, j), ["", "", false])
			for dz in [-2.3, 2.3]:
				if info[1] == "" and dz > 0:
					_empty_lot(c + y + Vector3(0, 0, dz))
					continue
				kit.box(world, Vector3(4.4, 0.02, 3.6), c + y + Vector3(0, 0, dz), kit.mat(Color("#5C606C")))
				kit.factory(world, c + y + Vector3(0, 0, dz), accents[(i + j * 2 + int(dz > 0)) % 4])
				if dz < 0 and info[1] != "":
					var id := "company" if info[2] else "company_%d_%d" % [i, j]
					_site(id, c + Vector3(0, 0, dz), "company", {"name": info[0], "owner": info[1], "mine": info[2]})
		"P":
			for n in 34:
				_street_tree(c + y + Vector3(rng.randf_range(-4.0, 4.0), 0, rng.randf_range(-4.0, 4.0)), rng.randf_range(1.3, 2.1))
			if i == 3 and j == 6:
				var lake := MeshInstance3D.new()
				var cm := CylinderMesh.new()
				cm.top_radius = 3.2
				cm.bottom_radius = 3.2
				cm.height = 0.05
				lake.mesh = cm
				var wm := ShaderMaterial.new()
				wm.shader = kit.WATER
				lake.material_override = wm
				lake.position = c + Vector3(0, 0.13, 0)
				lake.scale = Vector3(1.2, 1, 0.85)
				world.add_child(lake)
		"R":
			var sale := (i + j) % 3 == 0
			for dx in [-2.3, 2.3]:
				for dz in [-2.3, 2.3]:
					kit.box(world, Vector3(3.2, 0.02, 3.2), c + y + Vector3(dx, 0, dz), kit.mat(Color("#5DA862")))
					var h: String = HOUSES[rng.randi() % HOUSES.size()]
					var scn: PackedScene = load(ART + "models/%s.glb" % h)
					var m: Node3D = scn.instantiate()
					m.position = c + y + Vector3(dx, 0.02, dz)
					m.rotation_degrees.y = [0.0, 90.0, 180.0, 270.0][rng.randi() % 4]
					m.scale = Vector3(1.9, 1.9, 1.9)
					world.add_child(m)
					_street_tree(c + y + Vector3(dx + 1.2, 0, dz + 1.2), 1.1)
			if sale:
				_sale_marker(c + Vector3(2.3, 2.0, -2.3), "خانه", "%d,000" % rng.randi_range(180, 420))
		"V":
			var walls := [Color("#F4EFE6"), Color("#EADBC4"), Color("#DDE6EE"), Color("#F1E1D0")]
			for dx in [-2.35, 2.35]:
				for dz in [-2.35, 2.35]:
					kit.villa(world, c + y + Vector3(dx, 0, dz), [0.0, 90.0, 180.0, 270.0][rng.randi() % 4], walls[rng.randi() % 4])
			if i == 5 and j == 6:
				_site("villa", c + Vector3(2.35, 0, -2.35), "villa", {})
				_sale_marker(c + Vector3(2.35, 2.0, -2.35), "ویلا", "2.4M")
			elif (i * 3 + j) % 5 == 0:
				_sale_marker(c + Vector3(-2.35, 2.0, 2.35), "ویلا", "%.1fM" % rng.randf_range(1.6, 3.8))


## A Persian garden in front of the city hall: a long pool and a cross
## channel, four lawns, rows of trees.
func _char_bagh(at: Vector3) -> void:
	var wm := ShaderMaterial.new()
	wm.shader = kit.WATER
	kit.box(world, Vector3(0.7, 0.04, 3.6), at, kit.mat(Color("#D8D2C4")))
	kit.box(world, Vector3(0.5, 0.05, 3.4), at + Vector3(0, 0.01, 0), wm)
	kit.box(world, Vector3(6.4, 0.04, 0.5), at + Vector3(0, 0, 0.3), kit.mat(Color("#D8D2C4")))
	kit.box(world, Vector3(6.2, 0.05, 0.32), at + Vector3(0, 0.01, 0.3), wm)
	for x in [-1.9, 1.9]:
		for z in [-1.0, 1.4]:
			kit.box(world, Vector3(2.6, 0.03, 1.3), at + Vector3(x, 0, z), kit.mat(Color("#4E9C58")))
	for k in 5:
		for x in [-3.6, 3.6]:
			_street_tree(at + Vector3(x, 0, -1.8 + k * 0.9), 1.0)


var _tree_xf: Array = []


## Trees are many: collected here and drawn as two MultiMeshes at the end.
func _street_tree(at: Vector3, s: float) -> void:
	_tree_xf.append(Transform3D(Basis().scaled(Vector3(s, s, s)), at))


func _flush_trees() -> void:
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.05
	trunk.bottom_radius = 0.06
	trunk.height = 0.4
	var crown := SphereMesh.new()
	crown.radius = 0.3
	crown.height = 0.56
	for part in [[trunk, Color("#7A5230"), 0.2], [crown, Color("#3F9E5A"), 0.62]]:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = part[0]
		mm.instance_count = _tree_xf.size()
		for i in _tree_xf.size():
			var t: Transform3D = _tree_xf[i]
			mm.set_instance_transform(i, t.translated_local(Vector3(0, part[2], 0)))
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		mi.material_override = kit.mat(part[1])
		world.add_child(mi)


func _empty_lot(at: Vector3) -> void:
	kit.box(world, Vector3(3.8, 0.03, 3.2), at, kit.mat(Color("#8E7A5A")))
	var post := kit.mat(Color("#F2C255"))
	kit.box(world, Vector3(0.05, 0.7, 0.05), at + Vector3(1.4, 0, 1.2), post)
	kit.box(world, Vector3(0.7, 0.4, 0.04), at + Vector3(1.4, 0.55, 1.2), kit.mat(Color("#2BC4B2"), 0.0, 0.5, 0.6))
	_sale_marker(at + Vector3(0, 1.0, 0), "زمین", "85,000")


func _military() -> void:
	var c := (_block_center(0, 0) + _block_center(1, 1)) / 2.0
	var s := 2 * P - ROAD_W
	kit.box(world, Vector3(s, 0.06, s), c, kit.mat(Color("#6E7456")))
	var fence := kit.mat(Color("#B8BDC8"), 0.5, 0.4)
	for side in [-1, 1]:
		kit.box(world, Vector3(s, 0.35, 0.05), c + Vector3(0, 0.06, side * s / 2.0), fence)
		kit.box(world, Vector3(0.05, 0.35, s), c + Vector3(side * s / 2.0, 0.06, 0), fence)
	for k in 3:
		kit.barracks(world, c + Vector3(-3.2 * F, 0.06, (-4.2 + k * 1.9) * F))
	kit.box(world, Vector3(4.2 * F, 0.02, 4.2 * F), c + Vector3(3.0 * F, 0.06, -3.2 * F), kit.mat(Color("#C9C0A2")))
	kit.flag(world, c + Vector3(3.0 * F, 0.08, -3.2 * F), Color("#2BC4B2"))
	for corner in [Vector3(-1, 0, -1), Vector3(1, 0, -1), Vector3(-1, 0, 1), Vector3(1, 0, 1)]:
		kit.watchtower(world, c + corner * (s / 2.0 - 0.6) + Vector3(0, 0.06, 0))
	var r := kit.radar(world, c + Vector3(3.2 * F, 0.06, 3.0 * F))
	_spin.append(r.get_node("Spin"))
	for k in 3:
		kit.launcher(world, c + Vector3((0.4 + k * 1.2) * F, 0.06, 1.6 * F), 20.0 - k * 20.0)
	kit.helipad(world, c + Vector3(-3.2 * F, 0.06, 3.6 * F))
	for k in 6:
		_street_tree(c + Vector3(-s / 2.0 + 1.0, 0.06, -s / 2.0 + 2.0 + k * 3.0), 1.2)
	_site("military", c + Vector3(-3.2 * F, 0, -2.3 * F), "military", {})
	_district_label("منطقه‌ی نظامی", c + Vector3(0, 3.0, 0))


func _airport() -> void:
	var a := _block_center(6, 0)
	var b := _block_center(7, 4)
	var c := (a + b) / 2.0
	var sx := 2 * P - ROAD_W
	var sz := 5 * P - ROAD_W
	kit.box(world, Vector3(sx, 0.06, sz), c, kit.mat(Color("#5E7A5E")))
	kit.runway(world, c + Vector3(3.6 * F, 0.06, 0), sz - 4.0)
	kit.box(world, Vector3(1.0, 0.02, sz - 8.0), c + Vector3(1.2 * F, 0.06, 0), kit.mat(Color("#3A3C44")))
	kit.box(world, Vector3(6.0, 0.02, 13.0), c + Vector3(-3.6 * F, 0.06, -6.0 * F), kit.mat(Color("#4A4C55")))
	kit.terminal(world, c + Vector3(-5.6 * F, 0.06, -6.0 * F), 90.0)
	kit.plane(world, c + Vector3(-2.6 * F, 0.08, -9.0 * F), 90.0, Color("#2BC4B2"))
	kit.plane(world, c + Vector3(-2.6 * F, 0.08, -4.5 * F), 90.0, Color("#E5484D"))
	kit.plane(world, c + Vector3(3.6 * F, 0.08, 8.0 * F), 0.0, Color("#3552C8"))
	for k in 3:
		kit.hangar(world, c + Vector3(-4.6 * F, 0.06, (5.0 + k * 3.4) * F), 90.0)
	_site("airport", c + Vector3(-5.6 * F, 0, -6.0 * F), "place", {"name": "فرودگاه", "icon": "plane", "pal": "sapphire"})
	_district_label("فرودگاه", c + Vector3(0, 3.0, 2.0))


func _site(id: String, pos: Vector3, kind: String, info: Dictionary) -> void:
	info["pos"] = pos
	info["kind"] = kind
	sites[id] = info


# -- the view -------------------------------------------------------------------------------------
func _frame_view() -> void:
	match _view:
		"shop", "villa", "company", "military":
			_zoom = {"military": 20.0, "company": 16.0}.get(_view, 15.0)
			_target = sites[_view].pos
			_place_camera()
			_center_on(sites[_view].pos, Vector2(360, 570))
		_:
			_target = Vector3(2.0, 0, 0)
			_zoom = 78.0
	_place_camera()


func _place_camera() -> void:
	var dir := Vector3(sin(deg_to_rad(45.0)) * cos(deg_to_rad(36.0)), sin(deg_to_rad(36.0)), cos(deg_to_rad(45.0)) * cos(deg_to_rad(36.0)))
	cam.size = _zoom
	cam.position = _target + dir * 120.0
	cam.look_at(_target)


## Pan so that a point of the city lands at a given spot on the screen (a
## selected building sits between its name ribbon and its details card).
func _center_on(pos: Vector3, at: Vector2) -> void:
	for i in 3:
		var vs := get_viewport().get_visible_rect().size if is_inside_tree() else Vector2(W, H)
		var k := W / vs.x
		var sp := cam.unproject_position(pos) * k
		var px_per_unit := H / _zoom
		var right := cam.global_transform.basis.x
		var up := cam.global_transform.basis.y
		_target += (right * (sp.x - at.x) - up * (sp.y - at.y)) / px_per_unit
		_place_camera()


## A short camera tour over the districts (for a recording).
func _tour(t: float) -> void:
	var mil: Vector3 = sites["military"].pos + Vector3(2.0, 0, 2.0)
	var air: Vector3 = sites["airport"].pos + Vector3(2.0, 0, 0)
	var vil: Vector3 = sites["villa"].pos
	var baz: Vector3 = sites["shop"].pos
	var pts := [[Vector3(2.0, 0, 0), 80.0], [mil, 34.0], [air, 44.0], [vil, 24.0], [baz, 20.0]]
	var seg := 2.2
	var i := mini(int(t / seg), pts.size() - 2)
	var f := clampf((t - i * seg) / seg, 0.0, 1.0)
	f = f * f * (3.0 - 2.0 * f)
	_target = (pts[i][0] as Vector3).lerp(pts[i + 1][0], f)
	_zoom = lerpf(pts[i][1], pts[i + 1][1], f)
	_place_camera()


func _process(delta: float) -> void:
	_t += delta
	if _view == "tour":
		_tour(_t)
	for s in _spin:
		(s as Node3D).rotation.y += delta * 1.4
	var vs := get_viewport().get_visible_rect().size
	var k := W / vs.x
	for m in markers:
		var c: Control = m[0]
		var sp := cam.unproject_position(m[1]) * k
		c.position = sp - Vector2(c.size.x / 2.0, c.size.y) + Vector2(0, sin(_t * 2.0 + m[1].x) * 3.0)
		# never under the chrome: the top bar and filters, the map buttons, the dock
		var mid := c.position + c.size / 2.0
		var clear := mid.y > 320.0 and mid.y < 1100.0 and not (mid.x < 110.0 and mid.y < 560.0)
		c.visible = _zoom >= m[2] and _zoom <= (m[3] if m.size() > 3 else 999.0) and _selected == "" and clear
	for a in anchors:
		var c: Control = a[0]
		c.position = cam.unproject_position(a[1]) * k + a[2]
	_frames += 1
	if _shot != "" and _frames == 150:
		get_viewport().get_texture().get_image().save_png(_shot)
		get_tree().quit()


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseButton:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom = maxf(10.0, _zoom * 0.9)
			_place_camera()
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom = minf(110.0, _zoom * 1.1)
			_place_camera()
		elif e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed:
				_drag = false
			elif not _drag:
				_pick(e.position)
	elif e is InputEventMouseMotion and e.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_drag = true
		var right := cam.global_transform.basis.x
		var fwd := Vector3(-cam.global_transform.basis.z.x, 0, -cam.global_transform.basis.z.z).normalized()
		var px := _zoom / get_viewport().get_visible_rect().size.y
		_target -= right * e.relative.x * px - fwd * e.relative.y * px * 1.7
		_place_camera()


func _pick(screen: Vector2) -> void:
	var best := ""
	var best_d := 70.0
	var vs := get_viewport().get_visible_rect().size
	for id in sites:
		var d: float = cam.unproject_position(sites[id].pos).distance_to(screen)
		if d < best_d:
			best_d = d
			best = id
	_select(best)


# -- the HUD --------------------------------------------------------------------------------------
func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	ui = Control.new()
	ui.layout_direction = Control.LAYOUT_DIRECTION_LTR
	ui.size = Vector2(W, H)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)
	var vig := ColorRect.new()
	vig.layout_direction = Control.LAYOUT_DIRECTION_LTR
	vig.size = Vector2(W, H)
	vig.material = _mat("vignette")
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(vig)
	ui.add_child(_gradient(Rect2(0, 0, W, 330), Color(INK, 0.8), Color(INK, 0.0)))
	ui.add_child(_gradient(Rect2(0, 900, W, 380), Color(INK, 0.0), Color(INK, 0.9)))
	# markers and labels sit under the chrome
	_markers_now()
	_top_bar()
	_stat_row()
	_filters()
	_map_buttons()
	_dock()
	_overlay = Control.new()
	_overlay.layout_direction = Control.LAYOUT_DIRECTION_LTR
	_overlay.size = Vector2(W, H)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_overlay)
	if _view in ["shop", "villa", "company", "military"]:
		_select(_view)


var _pending_labels: Array = []
var _pending_sales: Array = []


func _district_label(text: String, at: Vector3) -> void:
	_pending_labels.append([text, at])


func _sale_marker(at: Vector3, what: String, price: String) -> void:
	_pending_sales.append([at, what, price])


func _markers_now() -> void:
	var dl := [["مرکز شهر", _block_center(3, 3) + Vector3(0, 6, 0)], ["بازار", _block_center(5, 3) + Vector3(0, 3, 0)],
		["شهرک صنعتی", (_block_center(0, 3) + _block_center(1, 3)) / 2.0 + Vector3(0, 3, 0)],
		["باغ‌ویلاها", (_block_center(5, 6) + _block_center(6, 6)) / 2.0 + Vector3(0, 3, 0)],
		["محله‌ی شمالی", (_block_center(3, 0) + _block_center(4, 1)) / 2.0 + Vector3(0, 3, 0)],
		["پارک", _block_center(3, 6) + Vector3(0, 2, 0)]]
	for d in dl + _pending_labels:
		var box := Control.new()
		box.layout_direction = Control.LAYOUT_DIRECTION_LTR
		box.size = Vector2(240, 60)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui.add_child(box)
		box.add_child(_glabel(d[0], display_font, 34, "#FFFFFF", "#FFE2A0", Rect2(0, 0, 240, 60), HORIZONTAL_ALIGNMENT_CENTER, 9))
		markers.append([box, d[1], 30.0])
	for s in _pending_sales:
		var box := Control.new()
		box.layout_direction = Control.LAYOUT_DIRECTION_LTR
		box.size = Vector2(118, 88)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui.add_child(box)
		var pin := Polygon2D.new()
		pin.polygon = PackedVector2Array([Vector2(50, 70), Vector2(68, 70), Vector2(59, 86)])
		pin.color = GOLD
		box.add_child(pin)
		var chip := _frame(Rect2(4, 30, 110, 40), 20.0, Color("#1E7A45"), Color("#0E4527"), GOLD, 0.0, 2.5, box)
		(chip.material as ShaderMaterial).set_shader_parameter("shadow", 0.35)
		_in(chip).add_child(_label(s[2], display_font, 21, Color.WHITE, Rect2(0, 1, 78, 38), HORIZONTAL_ALIGNMENT_CENTER, 4))
		_emboss("tag", Rect2(72, 22, 54, 54), "gold", box)
		markers.append([box, s[0], 0.0])
	# companies and services, as plated icons
	for id in sites:
		var s: Dictionary = sites[id]
		var icon := {"company": "factory", "shop": "cart", "villa": "", "military": "tent"}.get(s.kind, str(s.get("icon", "")))
		if icon == "":
			continue
		var pal := {"company": "gold" if s.get("mine", false) else "steel", "shop": "gold", "military": "emerald"}.get(s.kind, str(s.get("pal", "gold")))
		var box := Control.new()
		box.layout_direction = Control.LAYOUT_DIRECTION_LTR
		box.size = Vector2(150, 118)
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui.add_child(box)
		_badge("person", Rect2(43, 0, 64, 64), Color("#18204A") if not s.get("mine", false) else Color("#0E5E58"), GOLD, 0.0, box)
		var plate: TextureRect = box.get_child(box.get_child_count() - 1)
		(plate.material as ShaderMaterial).set_shader_parameter("glyph_color", Color(0, 0, 0, 0))
		_emboss(icon, Rect2(45, -2, 60, 60), pal, box)
		var name := str(s.get("name", {"shop": "فروشگاه آفتاب", "military": "پادگان"}.get(s.kind, "")))
		if s.kind == "company":
			name = s.name + ("  · مال تو" if s.get("mine", false) else "")
		var chip := _frame(Rect2(0, 64, 150, 32), 16.0, Color(0.06, 0.07, 0.16, 0.92), Color(0.02, 0.03, 0.08, 0.92), Color(GOLD, 0.8), 0.0, 1.5, box)
		(chip.material as ShaderMaterial).set_shader_parameter("shadow", 0.3)
		_in(chip).add_child(_label(name, display_font, 17, Color("#FFE9B0") if s.get("mine", false) else Color.WHITE, Rect2(0, 0, 150, 32), HORIZONTAL_ALIGNMENT_CENTER, 4))
		markers.append([box, s.pos + Vector3(0, 2.6, 0), 0.0, 62.0])


var _filter_nodes: Array = []


func _filters() -> void:
	var chips := [["همه", true], ["فروشی", false], ["شرکت‌ها", false], ["خدمات", false], ["نظامی", false]]
	var x := 596.0
	for c in chips:
		var w := 112.0 if c[0].length() > 4 else 96.0
		var f := _frame(Rect2(x + 110 - w, 256, w, 42), 21.0, Color(FIROUZEH, 0.9) if c[1] else Color(0.05, 0.06, 0.14, 0.88), Color(FIROUZEH.darkened(0.4), 0.9) if c[1] else Color(0.02, 0.03, 0.08, 0.88), Color(GOLD, 0.9) if c[1] else Color(GOLD, 0.45), 0.0, 2.0)
		(f.material as ShaderMaterial).set_shader_parameter("shadow", 0.3)
		_in(f).add_child(_label(c[0], display_font, 19, Color.WHITE, Rect2(0, 0, w, 42), HORIZONTAL_ALIGNMENT_CENTER, 4))
		_filter_nodes.append(f)
		x -= w + 10.0


func _map_buttons() -> void:
	var y := 330.0
	for b in [["+", 0], ["−", 1]]:
		var btn := _button(Rect2(20, y, 60, 60), Color("#2A3570"), Color("#141B45"), Color("#070A20"), 18.0, 6.0)
		btn.add_child(_label(b[0], display_font, 38, Color.WHITE, Rect2(0, -6, 60, 64), HORIZONTAL_ALIGNMENT_CENTER, 5))
		y += 74.0
	_badge("person", Rect2(20, y + 4, 60, 60), Color("#18204A"), GOLD)
	var plate: TextureRect = ui.get_child(ui.get_child_count() - 1)
	(plate.material as ShaderMaterial).set_shader_parameter("glyph_color", Color(0, 0, 0, 0))
	_emboss("walk", Rect2(22, y + 4, 56, 56), "teal")


# -- a building's menu --------------------------------------------------------------------------------
const MENUS := {
	"shop": {"title": "فروشگاه آفتاب", "sub": "بازار  ·  صاحب: رضا", "tint": "#B8452A",
		"actions": [["cart", "خرید", "gold"], ["coins", "فروش", "emerald"], ["eye", "کالاها", "sapphire"], ["walk", "برو اونجا", "teal"]],
		"rows": [["box", "42 کالا در قفسه، 6 تخفیف امروز"], ["rank", "امتیاز 4.6 از 318 خرید"], ["clock", "باز تا 23:00  ·  4 دقیقه پیاده"]],
		"cta": "ورود به فروشگاه", "price": ""},
	"villa": {"title": "ویلای استخردار", "sub": "باغ‌ویلاها  ·  برای فروش", "tint": "#1E7A45",
		"actions": [["eye", "بازدید", "sapphire"], ["keys", "خرید", "gold"], ["house", "اجاره", "teal"], ["walk", "مسیر", "steel"]],
		"rows": [["house", "420 متر  ·  4 خواب  ·  استخر"], ["energy", "استراحت در خانه: +80 انرژی"], ["coins", "نگهداری 1,200 در روز  ·  اجاره 18,000"]],
		"cta": "خرید", "price": "2,400,000"},
	"company": {"title": "فولاد البرز", "sub": "کارخانه  ·  مال تو  ·  سطح 3", "tint": "#8A5A10",
		"actions": [["gears", "مدیریت", "steel"], ["arm", "تولید", "gold"], ["box", "انبار", "sapphire"], ["society", "استخدام", "teal"]],
		"rows": [["arm", "در حال تولید ابزار × 24  ·  14:02"], ["society", "8 کارمند  ·  2 جای خالی"], ["coins", "صندوق شرکت 159,000  ·  سود دیروز +12,400"]],
		"cta": "مدیریت شرکت", "price": ""},
	"military": {"title": "پادگان فنویک", "sub": "نیروی زمینی  ·  وزارت دفاع", "tint": "#4E5A2A",
		"actions": [["rifle", "ثبت‌نام", "steel"], ["tank", "نیروها", "emerald"], ["missile", "پدافند", "ruby"], ["shield", "مأموریت", "gold"]],
		"rows": [["shield", "آماده‌باش: عادی"], ["tank", "3 گردان  ·  120 نیرو  ·  8 تانک"], ["radar", "پدافند هوایی: 2 سامانه فعال، رادار روشن"]],
		"cta": "ثبت‌نام در ارتش", "price": ""},
}


func _select(id: String) -> void:
	for c in _overlay.get_children():
		c.queue_free()
	anchors.clear()
	_selected = id
	if id == "" or not MENUS.has(id):
		_selected = ""
		return
	var m: Dictionary = MENUS[id]
	var s: Dictionary = sites[id]
	# browsing controls give way to the building's own menu
	for f in _filter_nodes:
		(f as Control).visible = false
	_outline_near(s.pos)
	var tint := Color(m.tint)
	# the name, on a ribbon over the building
	var head := Control.new()
	head.layout_direction = Control.LAYOUT_DIRECTION_LTR
	head.size = Vector2(440, 130)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(head)
	var rib := ColorRect.new()
	rib.layout_direction = Control.LAYOUT_DIRECTION_LTR
	rib.size = Vector2(440, 92)
	var rm := _mat("ribbon")
	rm.set_shader_parameter("size", rib.size)
	rm.set_shader_parameter("face_top", tint.lightened(0.25))
	rm.set_shader_parameter("face_bottom", tint.darkened(0.3))
	rib.material = rm
	head.add_child(rib)
	head.add_child(_glabel(m.title, display_font, 34, "#FFFFFF", "#FFE6B8", Rect2(60, 6, 320, 60), HORIZONTAL_ALIGNMENT_CENTER, 7))
	var sub := _frame(Rect2(90, 78, 260, 36), 18.0, Color(0.05, 0.06, 0.14, 0.95), Color(0.02, 0.03, 0.08, 0.95), Color(GOLD, 0.8), 0.0, 1.5, head)
	(sub.material as ShaderMaterial).set_shader_parameter("shadow", 0.3)
	_in(sub).add_child(_label(m.sub, body_bold, 16, Color("#E6ECFA"), Rect2(0, 0, 260, 36), HORIZONTAL_ALIGNMENT_CENTER, 0))
	anchors.append([head, s.pos, Vector2(-220, -300)])
	# the actions, in an arc under it
	var offs := [Vector2(170, 60), Vector2(58, 118), Vector2(-58, 118), Vector2(-170, 60)]
	for i in m.actions.size():
		var a: Array = m.actions[i]
		var btn := Control.new()
		btn.layout_direction = Control.LAYOUT_DIRECTION_LTR
		btn.size = Vector2(120, 120)
		btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_overlay.add_child(btn)
		_ring(Rect2(14, 0, 92, 92), 1.0, Color(GOLD, 0.6), btn)
		_badge("person", Rect2(20, 6, 80, 80), Color("#18204A"), GOLD, 0.0, btn)
		var plate: TextureRect = btn.get_child(btn.get_child_count() - 1)
		(plate.material as ShaderMaterial).set_shader_parameter("glyph_color", Color(0, 0, 0, 0))
		_emboss(a[0], Rect2(20, 2, 80, 80), a[2], btn)
		var cap := _frame(Rect2(4, 82, 112, 32), 16.0, Color(0.05, 0.06, 0.14, 0.95), Color(0.02, 0.03, 0.08, 0.95), Color(GOLD, 0.8), 0.0, 1.5, btn)
		(cap.material as ShaderMaterial).set_shader_parameter("shadow", 0.3)
		_in(cap).add_child(_label(a[1], display_font, 18, Color.WHITE, Rect2(0, 0, 112, 32), HORIZONTAL_ALIGNMENT_CENTER, 4))
		anchors.append([btn, s.pos, offs[i] - Vector2(60, 0)])
	# details and the one main action, on a card above the dock
	var card := _frame(Rect2(14, 842, 692, 262), 30.0, Color(0.10, 0.12, 0.27, 0.97), Color(0.04, 0.05, 0.13, 0.97), GOLD, 0.06, 3.0, _overlay)
	(card.material as ShaderMaterial).set_shader_parameter("glow", Color(tint, 0.5))
	var y := 862.0
	for r in m.rows:
		_emboss(r[0], Rect2(632, y - 4, 50, 50), "gold", _overlay)
		_overlay.add_child(_label(r[1], body_bold, 18, Color("#E6ECFA"), Rect2(210, y, 416, 40), HORIZONTAL_ALIGNMENT_RIGHT, 0))
		y += 50.0
	var go := _button(Rect2(36, 1016, 648, 74), LEAF.lightened(0.3) if id != "military" else Color("#D8C06A"), LEAF.darkened(0.05) if id != "military" else Color("#9A8230"), LEAF.darkened(0.6) if id != "military" else Color("#4A3A10"), 24.0, 8.0)
	go.get_parent().remove_child(go)
	_overlay.add_child(go)
	go.add_child(_glabel(m.cta, display_font, 32, "#FFFFFF", "#E8FFEA", Rect2(0, 2, 648, 60), HORIZONTAL_ALIGNMENT_CENTER, 7))
	if m.price != "":
		var pr := _frame(Rect2(36, 866, 170, 120), 22.0, Color(0.09, 0.07, 0.02, 0.95), Color(0.03, 0.02, 0.0, 0.95), GOLD, 0.0, 2.5, _overlay)
		(pr.material as ShaderMaterial).set_shader_parameter("shadow", 0.0)
		_in(pr).add_child(_label("قیمت", body_font, 16, Color("#E8D6A8"), Rect2(0, 8, 170, 26), HORIZONTAL_ALIGNMENT_CENTER, 0))
		_in(pr).add_child(_glabel(m.price, display_font, 30, "#FFF6C8", "#FFB21F", Rect2(0, 34, 170, 50), HORIZONTAL_ALIGNMENT_CENTER, 6))
		_in(pr).add_child(_label("نیل", body_bold, 15, Color("#E8D6A8"), Rect2(0, 82, 170, 26), HORIZONTAL_ALIGNMENT_CENTER, 0))


## Outline every mesh within reach of the selected site.
func _outline_near(pos: Vector3) -> void:
	var m := ShaderMaterial.new()
	m.shader = OUTLINE
	for n in world.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		var gp := mi.global_position
		if Vector2(gp.x - pos.x, gp.z - pos.z).length() < 1.35 and gp.y < 4.0 and not (mi.mesh is PlaneMesh):
			mi.material_overlay = m
