extends RefCounted
## A small kit of procedural buildings for the city prototype: what the
## Kenney starter models do not cover (a Persian city hall, towers with lit
## windows, a domed bazaar, villas with pools, factories, barracks, a radar,
## launchers, an airport). Each builder takes a parent and returns the node.
## In the game these would become real models; the shapes and sizes here are
## what those models need to fit (1 unit = one road tile).

const WINDOWS := preload("res://proto/city/windows.gdshader")
const WATER := preload("res://proto/city/water.gdshader")

var _mats := {}


func mat(c: Color, metal := 0.0, rough := 0.8, emit := 0.0) -> StandardMaterial3D:
	var key := "%s/%s/%s/%s" % [c.to_html(), metal, rough, emit]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = metal
	m.roughness = rough
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emit
	_mats[key] = m
	return m


func _mesh(parent: Node3D, mesh: Mesh, pos: Vector3, m: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.rotation_degrees = rot
	mi.material_override = m
	parent.add_child(mi)
	return mi


func box(parent: Node3D, size: Vector3, pos: Vector3, m: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var b := BoxMesh.new()
	b.size = size
	return _mesh(parent, b, pos + Vector3(0, size.y / 2.0, 0), m, rot)


func cyl(parent: Node3D, r: float, h: float, pos: Vector3, m: Material, top := -1.0, rot := Vector3.ZERO) -> MeshInstance3D:
	var c := CylinderMesh.new()
	c.bottom_radius = r
	c.top_radius = r if top < 0.0 else top
	c.height = h
	c.radial_segments = 20
	return _mesh(parent, c, pos + Vector3(0, h / 2.0, 0), m, rot)


func dome(parent: Node3D, r: float, pos: Vector3, m: Material, stretch := 1.0) -> MeshInstance3D:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r
	s.is_hemisphere = true
	s.radial_segments = 24
	s.rings = 10
	var mi := _mesh(parent, s, pos, m)
	mi.scale = Vector3(1, stretch, 1)
	return mi


func roof(parent: Node3D, size: Vector3, pos: Vector3, m: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var p := PrismMesh.new()
	p.size = size
	return _mesh(parent, p, pos + Vector3(0, size.y / 2.0, 0), m, rot)


func node(parent: Node3D, at: Vector3, rot := 0.0) -> Node3D:
	var n := Node3D.new()
	n.position = at
	n.rotation_degrees.y = rot
	parent.add_child(n)
	return n


# -- civic ----------------------------------------------------------------------------------------
## The city hall: a civic palace, not a place of worship. A long stone
## front with two wings, a colonnaded portico over broad steps, a band of
## tilework under the cornice, and a clock tower rising over the entrance
## with a clock on every side; three flags on the forecourt.
func city_hall(parent: Node3D, at: Vector3) -> Node3D:
	var n := node(parent, at)
	var stone := mat(Color("#EFE6D2"))
	var trim := mat(Color("#D7CAB0"))
	var roof_c := mat(Color("#5B6478"))
	var tile := mat(Color("#1FA8A0"), 0.1, 0.35)
	var lapis := mat(Color("#3552C8"), 0.1, 0.35)
	var lit := mat(Color("#FFD9A0"), 0.0, 0.4, 0.9)
	# forecourt and steps
	box(n, Vector3(7.4, 0.12, 5.4), Vector3(0, 0, 0.3), mat(Color("#D9D2C2")))
	for k in 3:
		box(n, Vector3(2.6 - k * 0.3, 0.1, 0.5), Vector3(0, 0.12 + k * 0.1, 1.55 - k * 0.22), trim)
	# the main front and its two wings
	box(n, Vector3(6.4, 1.5, 2.0), Vector3(0, 0.12, -0.4), stone)
	box(n, Vector3(1.6, 1.2, 1.4), Vector3(-2.6, 0.12, 1.0), stone)
	box(n, Vector3(1.6, 1.2, 1.4), Vector3(2.6, 0.12, 1.0), stone)
	for x in [-2.6, 2.6]:
		box(n, Vector3(1.7, 0.08, 1.5), Vector3(x, 1.32, 1.0), trim)
		for k in 3:
			box(n, Vector3(0.22, 0.5, 0.03), Vector3(x - 0.5 + k * 0.5, 0.45, 1.71), lit)
	# windows along the front, two floors
	for k in 8:
		var x := -2.9 + k * 0.83
		if abs(x) < 0.9:
			continue
		for f in 2:
			box(n, Vector3(0.24, 0.42, 0.03), Vector3(x, 0.35 + f * 0.62, 0.61), lit)
	# tile frieze under the cornice, then the cornice and a low roof
	box(n, Vector3(6.44, 0.16, 2.04), Vector3(0, 1.36, -0.4), tile)
	box(n, Vector3(6.44, 0.04, 2.04), Vector3(0, 1.44, -0.4), lapis)
	box(n, Vector3(6.6, 0.1, 2.2), Vector3(0, 1.62, -0.4), trim)
	box(n, Vector3(6.2, 0.18, 1.8), Vector3(0, 1.72, -0.4), roof_c)
	# the portico: six columns, an entablature, a pediment
	box(n, Vector3(2.4, 0.08, 1.1), Vector3(0, 0.42, 1.05), trim)
	for k in 6:
		cyl(n, 0.09, 1.1, Vector3(-1.0 + k * 0.4, 0.5, 1.45), stone)
	box(n, Vector3(2.5, 0.2, 1.2), Vector3(0, 1.6, 1.05), trim)
	box(n, Vector3(2.5, 0.08, 0.04), Vector3(0, 1.66, 1.66), tile)
	roof(n, Vector3(2.5, 0.45, 1.2), Vector3(0, 1.8, 1.05), stone)
	box(n, Vector3(1.0, 0.8, 0.04), Vector3(0, 0.5, 0.6), mat(Color("#6B4A2A")))
	# the clock tower
	box(n, Vector3(1.0, 2.2, 1.0), Vector3(0, 1.8, -0.4), stone)
	box(n, Vector3(1.1, 0.1, 1.1), Vector3(0, 3.0, -0.4), trim)
	box(n, Vector3(1.04, 0.14, 1.04), Vector3(0, 2.85, -0.4), tile)
	var face := mat(Color("#FFF6DC"), 0.0, 0.4, 0.8)
	var ink := mat(Color("#1E2233"))
	for side in [[Vector3(0, 0, 0.53), Vector3(90, 0, 0)], [Vector3(0, 0, -0.53), Vector3(90, 0, 0)],
			[Vector3(0.53, 0, 0), Vector3(0, 0, 90)], [Vector3(-0.53, 0, 0), Vector3(0, 0, 90)]]:
		var c: Vector3 = Vector3(0, 3.35, -0.4) + side[0]
		cyl(n, 0.32, 0.04, c - Vector3(0, 0.02, 0), face, -1.0, side[1])
		var out: Vector3 = side[0].normalized() * 0.03
		var along := Vector3(0, 0, 1) if side[0].x != 0.0 else Vector3(1, 0, 0)
		box(n, Vector3(0.03, 0.22, 0.03), c + out + Vector3(0, -0.02, 0), ink)
		box(n, (Vector3(0.16, 0.03, 0.03) if side[0].x == 0.0 else Vector3(0.03, 0.03, 0.16)), c + out + along * 0.06 - Vector3(0, 0.015, 0), ink)
	box(n, Vector3(1.0, 0.7, 1.0), Vector3(0, 3.1, -0.4), stone)
	roof(n, Vector3(1.1, 0.7, 1.1), Vector3(0, 3.8, -0.4), mat(Color("#2E7F7A"), 0.2, 0.4))
	cyl(n, 0.03, 0.5, Vector3(0, 4.5, -0.4), mat(Color("#F2C255"), 0.9, 0.25))
	# flags on the forecourt
	for x in [-1.8, 0.0, 1.8]:
		cyl(n, 0.035, 2.4, Vector3(x, 0.12, 2.6), mat(Color("#D8DCE6"), 0.6, 0.3))
		box(n, Vector3(0.62, 0.36, 0.02), Vector3(x + 0.32, 2.05, 2.6), mat(Color("#2BC4B2") if x == 0.0 else Color("#F2C255")))
	return n


func bank(parent: Node3D, at: Vector3) -> Node3D:
	var n := node(parent, at)
	var stone := mat(Color("#EDE6D6"))
	box(n, Vector3(4.2, 0.3, 3.2), Vector3.ZERO, mat(Color("#BFB6A2")))
	box(n, Vector3(3.6, 1.6, 2.2), Vector3(0, 0.3, -0.3), stone)
	for i in 6:
		cyl(n, 0.13, 1.3, Vector3(-1.5 + i * 0.6, 0.3, 1.1), stone)
	box(n, Vector3(3.8, 0.25, 0.8), Vector3(0, 1.6, 0.95), stone)
	roof(n, Vector3(3.8, 0.5, 0.8), Vector3(0, 1.85, 0.95), stone)
	box(n, Vector3(1.4, 0.3, 0.05), Vector3(0, 1.65, 1.36), mat(Color("#F2C255"), 0.9, 0.3, 0.4))
	return n


func tower(parent: Node3D, at: Vector3, h: float, w: float, d: float, wall: Color, seed: float) -> Node3D:
	var n := node(parent, at)
	var m := ShaderMaterial.new()
	m.shader = WINDOWS
	m.set_shader_parameter("wall", wall)
	m.set_shader_parameter("seed", seed)
	box(n, Vector3(w, h, d), Vector3.ZERO, m)
	box(n, Vector3(w + 0.1, 0.12, d + 0.1), Vector3(0, h, 0), mat(wall.lightened(0.25)))
	box(n, Vector3(w * 0.4, 0.3, d * 0.4), Vector3(0, h + 0.12, 0), mat(Color("#8A93AE")))
	cyl(n, 0.03, 0.9, Vector3(w * 0.2, h + 0.4, 0), mat(Color("#C0C6D6")))
	var beacon := SphereMesh.new()
	beacon.radius = 0.06
	beacon.height = 0.12
	_mesh(n, beacon, Vector3(w * 0.2, h + 1.3, 0), mat(Color("#FF4A4A"), 0.0, 0.5, 3.0))
	return n


func bazaar(parent: Node3D, at: Vector3, length: float, rot := 0.0) -> Node3D:
	var n := node(parent, at, rot)
	var brick := mat(Color("#D9A66B"))
	var tile := mat(Color("#2BC4B2"), 0.1, 0.35)
	box(n, Vector3(length, 0.9, 1.3), Vector3.ZERO, brick)
	var k := int(length / 1.2)
	for i in k:
		var x := -length / 2.0 + 0.6 + i * (length / k)
		cyl(n, 0.42, 0.18, Vector3(x, 0.9, 0), brick)
		dome(n, 0.46, Vector3(x, 1.08, 0), tile, 1.2)
		box(n, Vector3(0.5, 0.6, 0.06), Vector3(x, 0.0, 0.66), mat(Color("#3A2A1A")))
	return n


func shop(parent: Node3D, at: Vector3, stripe: Color) -> Node3D:
	var n := node(parent, at)
	box(n, Vector3(1.9, 1.1, 1.5), Vector3.ZERO, mat(Color("#F1E4CC")))
	box(n, Vector3(1.9, 0.12, 1.55), Vector3(0, 1.1, 0), mat(Color("#C9B58F")))
	# a striped awning over a lit shopfront
	for i in 6:
		box(n, Vector3(0.32, 0.06, 0.55), Vector3(-0.8 + i * 0.32, 0.78, 0.98), mat(stripe if i % 2 == 0 else Color("#FFF6E6")), Vector3(-18, 0, 0))
	box(n, Vector3(1.5, 0.6, 0.05), Vector3(0, 0.08, 0.76), mat(Color("#FFD89A"), 0.0, 0.4, 1.2))
	box(n, Vector3(1.2, 0.26, 0.06), Vector3(0, 0.9, 0.78), mat(Color("#20264A")))
	return n


# -- homes ------------------------------------------------------------------------------------------
func tree(parent: Node3D, at: Vector3, s := 1.0) -> void:
	cyl(parent, 0.05 * s, 0.35 * s, at, mat(Color("#7A5230")))
	var f := SphereMesh.new()
	f.radius = 0.28 * s
	f.height = 0.5 * s
	_mesh(parent, f, at + Vector3(0, 0.55 * s, 0), mat(Color("#3F9E5A")))


func villa(parent: Node3D, at: Vector3, rot: float, wall: Color) -> Node3D:
	var n := node(parent, at, rot)
	box(n, Vector3(3.0, 0.06, 3.0), Vector3.ZERO, mat(Color("#5DB36A")))
	var w := mat(wall)
	box(n, Vector3(1.9, 0.75, 1.2), Vector3(-0.3, 0.06, -0.55), w)
	box(n, Vector3(1.2, 0.6, 1.0), Vector3(-0.6, 0.81, -0.6), w)
	box(n, Vector3(2.0, 0.07, 1.3), Vector3(-0.3, 0.81, -0.55), mat(Color("#4A4F63")))
	box(n, Vector3(1.3, 0.07, 1.1), Vector3(-0.6, 1.41, -0.6), mat(Color("#4A4F63")))
	# a glass band on each floor, lit from inside
	box(n, Vector3(1.4, 0.35, 0.04), Vector3(-0.3, 0.25, 0.06), mat(Color("#FFD9A0"), 0.0, 0.3, 0.9))
	box(n, Vector3(0.9, 0.3, 0.04), Vector3(-0.6, 0.95, -0.09), mat(Color("#9FD8FF"), 0.0, 0.2, 0.6))
	var pool := BoxMesh.new()
	pool.size = Vector3(1.1, 0.05, 0.65)
	var wm := ShaderMaterial.new()
	wm.shader = WATER
	_mesh(n, pool, Vector3(0.55, 0.07, 0.7), wm)
	box(n, Vector3(1.25, 0.04, 0.8), Vector3(0.55, 0.04, 0.7), mat(Color("#EDE6D6")))
	for p in [Vector3(-1.4, 0, -1.4), Vector3(1.3, 0, -1.3), Vector3(-1.3, 0, 1.3)]:
		tree(n, p, 1.1)
	# a low hedge around the lot
	var hedge := mat(Color("#2F7A45"))
	box(n, Vector3(3.0, 0.18, 0.1), Vector3(0, 0.06, 1.45), hedge)
	box(n, Vector3(3.0, 0.18, 0.1), Vector3(0, 0.06, -1.45), hedge)
	box(n, Vector3(0.1, 0.18, 3.0), Vector3(1.45, 0.06, 0), hedge)
	box(n, Vector3(0.1, 0.18, 3.0), Vector3(-1.45, 0.06, 0), hedge)
	return n


# -- industry -------------------------------------------------------------------------------------
func factory(parent: Node3D, at: Vector3, accent: Color, rot := 0.0) -> Node3D:
	var n := node(parent, at, rot)
	box(n, Vector3(3.4, 0.05, 2.8), Vector3.ZERO, mat(Color("#8C8F9C")))
	var wall := mat(Color("#AEB6C8"))
	box(n, Vector3(2.6, 1.0, 1.8), Vector3(-0.2, 0.05, -0.2), wall)
	for i in 4:
		roof(n, Vector3(0.65, 0.42, 1.8), Vector3(-1.2 + i * 0.65, 1.05, -0.2), mat(Color("#6B7488")), Vector3(0, 0, 0))
		box(n, Vector3(0.05, 0.4, 1.7), Vector3(-0.9 + i * 0.65, 1.05, -0.2), mat(Color("#BFE3FF"), 0.0, 0.3, 0.8))
	box(n, Vector3(2.62, 0.18, 0.05), Vector3(-0.2, 0.75, 0.71), mat(accent, 0.2, 0.4, 0.5))
	var red := mat(Color("#C8453C"))
	var white := mat(Color("#EEEEEE"))
	for c in [Vector3(1.25, 0.05, -0.8), Vector3(1.25, 0.05, 0.1)]:
		cyl(n, 0.16, 2.2, c, red, 0.12)
		cyl(n, 0.165, 0.25, c + Vector3(0, 1.6, 0), white, 0.13)
		var smoke := CPUParticles3D.new()
		smoke.position = c + Vector3(0, 2.25, 0)
		smoke.amount = 14
		smoke.lifetime = 3.0
		smoke.direction = Vector3(0.3, 1, 0.2)
		smoke.spread = 12.0
		smoke.initial_velocity_min = 0.25
		smoke.initial_velocity_max = 0.45
		smoke.gravity = Vector3(0.12, 0.05, 0)
		smoke.scale_amount_min = 0.35
		smoke.scale_amount_max = 0.7
		var sm := SphereMesh.new()
		sm.radius = 0.25
		sm.height = 0.5
		var smm := StandardMaterial3D.new()
		smm.albedo_color = Color(0.85, 0.85, 0.9, 0.45)
		smm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		smm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.material = smm
		smoke.mesh = sm
		n.add_child(smoke)
	for i in 2:
		cyl(n, 0.3, 0.7, Vector3(-1.3 + i * 0.7, 0.05, 1.0), mat(Color("#D8DCE6"), 0.4, 0.4))
	return n


# -- the military -----------------------------------------------------------------------------------
func barracks(parent: Node3D, at: Vector3, rot := 0.0) -> Node3D:
	var n := node(parent, at, rot)
	box(n, Vector3(3.6, 0.6, 1.0), Vector3.ZERO, mat(Color("#8A8F6A")))
	roof(n, Vector3(3.7, 0.4, 1.15), Vector3(0, 0.6, 0), mat(Color("#4E5A3A")), Vector3(0, 90, 0) * 0.0)
	for i in 7:
		box(n, Vector3(0.22, 0.24, 0.04), Vector3(-1.5 + i * 0.5, 0.22, 0.51), mat(Color("#FFE0A0"), 0.0, 0.4, 0.8))
	return n


func watchtower(parent: Node3D, at: Vector3) -> Node3D:
	var n := node(parent, at)
	var wood := mat(Color("#5B4A3A"))
	for x in [-0.25, 0.25]:
		for z in [-0.25, 0.25]:
			box(n, Vector3(0.06, 1.4, 0.06), Vector3(x, 0, z), wood)
	box(n, Vector3(0.75, 0.4, 0.75), Vector3(0, 1.4, 0), mat(Color("#6E6450")))
	roof(n, Vector3(0.9, 0.3, 0.9), Vector3(0, 1.8, 0), mat(Color("#3E4632")))
	var lamp := SpotLight3D.new()
	lamp.position = Vector3(0, 1.6, 0.3)
	lamp.rotation_degrees = Vector3(-50, 20, 0)
	lamp.light_color = Color("#FFF2C8")
	lamp.light_energy = 3.0
	lamp.spot_range = 7.0
	lamp.spot_angle = 18.0
	n.add_child(lamp)
	return n


func flag(parent: Node3D, at: Vector3, c: Color) -> void:
	cyl(parent, 0.03, 2.4, at, mat(Color("#D8DCE6"), 0.6, 0.3))
	box(parent, Vector3(0.7, 0.42, 0.02), at + Vector3(0.36, 1.9, 0), mat(c))


func radar(parent: Node3D, at: Vector3) -> Node3D:
	var n := node(parent, at)
	box(n, Vector3(1.2, 0.3, 1.2), Vector3.ZERO, mat(Color("#6B7058")))
	cyl(n, 0.14, 0.8, Vector3(0, 0.3, 0), mat(Color("#B8BDC8"), 0.5, 0.4))
	var head := Node3D.new()
	head.name = "Spin"
	head.position = Vector3(0, 1.1, 0)
	n.add_child(head)
	var dish := dome(head, 0.62, Vector3(0, 0, 0.1), mat(Color("#E8ECF4"), 0.3, 0.3), 0.45)
	dish.rotation_degrees = Vector3(-70, 0, 0)
	box(head, Vector3(0.04, 0.5, 0.04), Vector3(0, -0.1, 0.35), mat(Color("#B8BDC8")), Vector3(35, 0, 0))
	return n


func launcher(parent: Node3D, at: Vector3, rot: float) -> Node3D:
	var n := node(parent, at, rot)
	var olive := mat(Color("#5E6A44"))
	box(n, Vector3(0.7, 0.25, 1.6), Vector3(0, 0.12, 0), olive)
	box(n, Vector3(0.66, 0.35, 0.45), Vector3(0, 0.37, 0.55), olive)
	for w in [-0.5, 0.0, 0.5]:
		for s in [-0.36, 0.36]:
			cyl(n, 0.13, 0.1, Vector3(s, 0.0, w), mat(Color("#1E1E22")), -1.0, Vector3(0, 0, 90))
	var rack := Node3D.new()
	rack.position = Vector3(0, 0.5, -0.25)
	rack.rotation_degrees = Vector3(38, 0, 0)
	n.add_child(rack)
	for i in 2:
		for j in 2:
			cyl(rack, 0.1, 1.3, Vector3(-0.12 + i * 0.24, 0.0, -0.1 + j * 0.2), mat(Color("#7A8560")), -1.0, Vector3(90, 0, 0))
	return n


func helipad(parent: Node3D, at: Vector3) -> void:
	var d := CylinderMesh.new()
	d.top_radius = 0.9
	d.bottom_radius = 0.9
	d.height = 0.04
	_mesh(parent, d, at + Vector3(0, 0.02, 0), mat(Color("#2E3238")))
	var white := mat(Color("#F0F0F0"), 0.0, 0.6, 0.3)
	box(parent, Vector3(0.1, 0.02, 0.8), at + Vector3(-0.22, 0.04, 0), white)
	box(parent, Vector3(0.1, 0.02, 0.8), at + Vector3(0.22, 0.04, 0), white)
	box(parent, Vector3(0.44, 0.02, 0.1), at + Vector3(0, 0.04, 0), white)


# -- the airport ----------------------------------------------------------------------------------
func runway(parent: Node3D, at: Vector3, length: float, rot := 0.0) -> Node3D:
	var n := node(parent, at, rot)
	box(n, Vector3(2.2, 0.03, length), Vector3.ZERO, mat(Color("#2A2C33")))
	var white := mat(Color("#F4F4F4"), 0.0, 0.6, 0.35)
	var k := int(length / 1.6)
	for i in k:
		box(n, Vector3(0.08, 0.02, 0.7), Vector3(0, 0.03, -length / 2.0 + 0.8 + i * 1.6), white)
	for s in [-1, 1]:
		for i in 6:
			box(n, Vector3(0.12, 0.02, 0.9), Vector3(-0.75 + i * 0.3, 0.03, s * (length / 2.0 - 0.8)), white)
		# edge lights
	for i in int(length / 1.2):
		for x in [-1.12, 1.12]:
			box(n, Vector3(0.06, 0.05, 0.06), Vector3(x, 0.03, -length / 2.0 + i * 1.2), mat(Color("#9FD1FF"), 0.0, 0.3, 3.0))
	return n


func terminal(parent: Node3D, at: Vector3, rot := 0.0) -> Node3D:
	var n := node(parent, at, rot)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.45, 0.75, 1.0, 0.75)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.metallic = 0.3
	glass.roughness = 0.1
	glass.emission_enabled = true
	glass.emission = Color("#6FB8FF")
	glass.emission_energy_multiplier = 0.35
	box(n, Vector3(5.0, 0.2, 2.0), Vector3.ZERO, mat(Color("#C9CED8")))
	box(n, Vector3(4.6, 0.9, 1.6), Vector3(0, 0.2, 0), glass)
	var r := CylinderMesh.new()
	r.top_radius = 1.2
	r.bottom_radius = 1.2
	r.height = 4.8
	var roof_mi := _mesh(n, r, Vector3(0, 1.05, 0), mat(Color("#EDF1F7"), 0.3, 0.3), Vector3(0, 0, 90))
	roof_mi.scale = Vector3(1, 1, 0.35)
	# the control tower
	cyl(n, 0.22, 2.6, Vector3(2.9, 0, -0.4), mat(Color("#E4E7EE")))
	cyl(n, 0.45, 0.4, Vector3(2.9, 2.6, -0.4), glass)
	cyl(n, 0.5, 0.08, Vector3(2.9, 3.0, -0.4), mat(Color("#C9CED8")))
	return n


func plane(parent: Node3D, at: Vector3, rot: float, livery: Color) -> Node3D:
	var n := node(parent, at, rot)
	var white := mat(Color("#F4F6FA"), 0.2, 0.35)
	var cap := CapsuleMesh.new()
	cap.radius = 0.2
	cap.height = 2.4
	_mesh(n, cap, Vector3(0, 0.35, 0), white, Vector3(90, 0, 0))
	box(n, Vector3(2.4, 0.04, 0.5), Vector3(0, 0.28, 0.05), white)
	box(n, Vector3(0.9, 0.03, 0.3), Vector3(0, 0.42, -1.05), white)
	box(n, Vector3(0.04, 0.5, 0.4), Vector3(0, 0.45, -1.05), mat(livery))
	box(n, Vector3(0.42, 0.06, 1.6), Vector3(0, 0.46, 0.1), mat(livery))
	for x in [-0.6, 0.6]:
		cyl(n, 0.09, 0.35, Vector3(x, 0.14, 0.2), mat(Color("#B8BDC8"), 0.6, 0.3), -1.0, Vector3(90, 0, 0))
	return n


func hangar(parent: Node3D, at: Vector3, rot := 0.0) -> Node3D:
	var n := node(parent, at, rot)
	var r := CylinderMesh.new()
	r.top_radius = 1.2
	r.bottom_radius = 1.2
	r.height = 2.6
	_mesh(n, r, Vector3(0, 0, 0), mat(Color("#9AA3B4"), 0.4, 0.4), Vector3(90, 0, 0))
	box(n, Vector3(1.6, 0.9, 0.05), Vector3(0, 0.0, 1.3), mat(Color("#2A2E38")))
	return n
