extends "res://proto/city/builders.gd"
## Procedural models of military equipment for the prototype's showroom: a
## fighter and a tank, built from primitives and extruded outlines. The game
## would use real models; these show the size, the stance and where the
## generation's colour goes (the fin band on a fighter, the turret band on a
## tank).


## An outline in a plane, extruded `t` thick. `to3` maps (u, v, w) — the
## outline's two coordinates and the depth — into the model's space.
func slab(parent: Node3D, outline: PackedVector2Array, t: float, to3: Callable, m: Material) -> MeshInstance3D:
	var tris := Geometry2D.triangulate_polygon(outline)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side in [-1.0, 1.0]:
		for i in range(0, tris.size(), 3):
			var idx := [tris[i], tris[i + 1], tris[i + 2]]
			if side < 0.0:
				idx.reverse()
			for k in idx:
				var p := outline[k]
				st.add_vertex(to3.call(p.x, p.y, side * t / 2.0))
	var n := outline.size()
	for i in n:
		var a := outline[i]
		var b := outline[(i + 1) % n]
		var q := [to3.call(a.x, a.y, -t / 2.0), to3.call(b.x, b.y, -t / 2.0), to3.call(b.x, b.y, t / 2.0), to3.call(a.x, a.y, t / 2.0)]
		for k in [0, 1, 2, 0, 2, 3]:
			st.add_vertex(q[k])
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = m
	parent.add_child(mi)
	return mi


## Centred primitives: box() and cyl() stand their shape on `pos`, which a
## rotated part cannot use.
func cbox(parent: Node3D, size: Vector3, pos: Vector3, m: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var b := BoxMesh.new()
	b.size = size
	return _mesh(parent, b, pos, m, rot)


func ccyl(parent: Node3D, r: float, h: float, pos: Vector3, m: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var c := CylinderMesh.new()
	c.bottom_radius = r
	c.top_radius = r
	c.height = h
	c.radial_segments = 24
	return _mesh(parent, c, pos, m, rot)


func _two_sided(m: StandardMaterial3D) -> StandardMaterial3D:
	var d := m.duplicate() as StandardMaterial3D
	d.cull_mode = BaseMaterial3D.CULL_DISABLED
	return d


## A twin-engine fighter, nose along +Z, about 4.4 long. `band` is its
## generation's colour.
func fighter(parent: Node3D, band: Color) -> Node3D:
	var n := Node3D.new()
	parent.add_child(n)
	var body := mat(Color("#7D8AA0"), 0.55, 0.42)
	var panel := _two_sided(mat(Color("#5E6B80"), 0.5, 0.5))
	var dark := mat(Color("#2A2F3A"), 0.6, 0.5)
	var glass := mat(Color("#1B2A4A"), 0.9, 0.08)
	var hot := mat(Color("#FF8A3A"), 0.0, 0.6, 4.0)
	var stripe := _two_sided(mat(band, 0.3, 0.4, 1.2))
	# fuselage, nose, spine
	ccyl(n, 0.24, 2.8, Vector3(0, 0, -0.1), body, Vector3(90, 0, 0))
	var nose := CylinderMesh.new()
	nose.top_radius = 0.0
	nose.bottom_radius = 0.24
	nose.height = 1.2
	_mesh(n, nose, Vector3(0, 0, 1.9), body, Vector3(90, 0, 0))
	cbox(n, Vector3(0.62, 0.2, 1.8), Vector3(0, 0.02, -0.5), body)
	# intakes
	for s in [-1.0, 1.0]:
		cbox(n, Vector3(0.18, 0.3, 0.9), Vector3(s * 0.36, -0.05, 0.1), panel)
		cbox(n, Vector3(0.14, 0.24, 0.05), Vector3(s * 0.36, -0.05, 0.56), dark)
	# canopy
	var can := SphereMesh.new()
	can.radius = 0.2
	can.height = 0.34
	var ci := _mesh(n, can, Vector3(0, 0.2, 0.95), glass)
	ci.scale = Vector3(1.0, 1.0, 2.6)
	# wings and tailplanes, mirrored
	var flat := func(u: float, v: float, w: float) -> Vector3: return Vector3(u, w - 0.02, v)
	var flat_l := func(u: float, v: float, w: float) -> Vector3: return Vector3(-u, w - 0.02, v)
	var wing := PackedVector2Array([Vector2(0.25, 0.75), Vector2(2.05, -0.55), Vector2(2.05, -0.9), Vector2(0.25, -1.05)])
	var tail := PackedVector2Array([Vector2(0.25, -1.1), Vector2(1.0, -1.55), Vector2(1.0, -1.78), Vector2(0.25, -1.75)])
	for f in [flat, flat_l]:
		slab(n, wing, 0.06, f, panel)
		slab(n, tail, 0.05, f, panel)
	# twin fins, canted out, with the generation's band
	var fin := PackedVector2Array([Vector2(0.15, -0.85), Vector2(1.05, -1.42), Vector2(1.05, -1.72), Vector2(0.15, -1.62)])
	var band_o := PackedVector2Array([Vector2(0.78, -1.25), Vector2(1.05, -1.42), Vector2(1.05, -1.72), Vector2(0.78, -1.68)])
	for s in [-1.0, 1.0]:
		var hold := Node3D.new()
		hold.position = Vector3(s * 0.26, 0.1, 0)
		hold.rotation_degrees = Vector3(0, 0, -s * 16.0)
		n.add_child(hold)
		var up := func(u: float, v: float, w: float) -> Vector3: return Vector3(w, u, v)
		slab(hold, fin, 0.05, up, panel)
		slab(hold, band_o, 0.07, up, stripe)
	# engines
	for s in [-1.0, 1.0]:
		ccyl(n, 0.15, 0.4, Vector3(s * 0.14, 0, -1.62), dark, Vector3(90, 0, 0))
		ccyl(n, 0.11, 0.05, Vector3(s * 0.14, 0, -1.83), hot, Vector3(90, 0, 0))
	# missiles on the wingtips and under the wings
	var white := mat(Color("#E8ECF2"), 0.2, 0.5)
	for s in [-1.0, 1.0]:
		ccyl(n, 0.04, 0.9, Vector3(s * 2.07, -0.02, -0.55), white, Vector3(90, 0, 0))
		ccyl(n, 0.055, 1.0, Vector3(s * 1.15, -0.16, -0.25), white, Vector3(90, 0, 0))
		cbox(n, Vector3(0.03, 0.12, 0.3), Vector3(s * 1.15, -0.08, -0.25), dark)
	return n


## A main battle tank, gun along +Z, about 4 long. `band` rings its turret.
func tank(parent: Node3D, band: Color) -> Node3D:
	var n := Node3D.new()
	parent.add_child(n)
	var hull := mat(Color("#4A5236"), 0.35, 0.6)
	var dark := mat(Color("#1C1E18"), 0.3, 0.8)
	cbox(n, Vector3(1.8, 0.45, 3.4), Vector3(0, 0.45, 0), hull)
	cbox(n, Vector3(1.8, 0.3, 0.6), Vector3(0, 0.55, 1.75), hull, Vector3(-25, 0, 0))
	for s in [-1.0, 1.0]:
		cbox(n, Vector3(0.5, 0.5, 3.6), Vector3(s * 1.05, 0.3, 0), dark)
		for i in 6:
			ccyl(n, 0.2, 0.42, Vector3(s * 1.05, 0.25, -1.4 + i * 0.56), mat(Color("#3A3D33"), 0.3, 0.8), Vector3(0, 0, 90))
	var tur := Node3D.new()
	tur.position = Vector3(0, 0.9, -0.2)
	n.add_child(tur)
	cbox(tur, Vector3(1.3, 0.45, 1.7), Vector3.ZERO, hull)
	cbox(tur, Vector3(1.34, 0.12, 1.74), Vector3(0, -0.1, 0), mat(band, 0.3, 0.4, 1.2))
	ccyl(tur, 0.08, 2.4, Vector3(0, 0.05, 1.9), hull, Vector3(90, 0, 0))
	cbox(tur, Vector3(0.3, 0.2, 0.4), Vector3(0.35, 0.3, -0.2), dark)
	return n
